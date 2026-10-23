package privacy

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"sort"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
)

type Postgres struct{ Pool *pgxpool.Pool }

var columns = map[string]string{
	"users":                    "id provider issuer subject display_name email created_at",
	"auth_families":            "id user_id revoked_at created_at",
	"access_tokens":            "token_hash family_id expires_at created_at",
	"refresh_tokens":           "token_hash family_id expires_at consumed_at created_at",
	"enrollments":              "id user_id program_id program_sha status options created_at program_kind",
	"schedule_occurrences":     "id user_id enrollment_id source_session_key planned_for timezone program_id program_sha",
	"activity_sessions":        "id occurrence_id user_id state started_at ended_at completed_at",
	"activity_events":          "id session_id user_id event_type occurred_at payload",
	"idempotency_records":      "user_id operation key_hash request_hash response_status response_body expires_at",
	"food_versions":            "food_id version_sha source_id source_food_id source_row_key owner_id name_original name_pt preparation basis_quantity basis_unit nutrients provenance created_at source_published_version name_locale allowed_operations",
	"food_entries":             "id user_id food_id food_sha quantity unit occurred_at timezone calculation deleted_at created_at",
	"account_deletion_intents": "token_hash user_id family_id expires_at created_at",
	"account_erasures":         "user_id erased_at",
}

// Inventory is deliberately explicit: a new private table/column must not silently
// disappear from export/deletion. Internal credentials/cache/restore ledger have
// deliberate exclusions documented in the policy.
func coverage(ctx context.Context, tx pgx.Tx) error {
	names := make([]string, 0, len(columns))
	for n := range columns {
		names = append(names, n)
	}
	rows, err := tx.Query(ctx, `SELECT table_name,column_name FROM information_schema.columns
 WHERE table_schema='trainforge_v1' AND (table_name=ANY($1) OR column_name IN('user_id','owner_id'))
 UNION SELECT c.relname,a.attname FROM pg_constraint fk JOIN pg_class c ON c.oid=fk.conrelid
 JOIN pg_namespace ns ON ns.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=ANY(fk.conkey)
 WHERE ns.nspname='trainforge_v1' AND fk.contype='f' AND fk.confrelid='trainforge_v1.users'::regclass`, names)
	if err != nil {
		return ErrUnavailable
	}
	found := map[string][]string{}
	for rows.Next() {
		var table, column string
		if rows.Scan(&table, &column) != nil {
			rows.Close()
			return ErrUnavailable
		}
		if _, ok := columns[table]; !ok {
			rows.Close()
			return ErrUnavailable
		}
		found[table] = append(found[table], column)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return ErrUnavailable
	}
	for table, expected := range columns {
		want := strings.Fields(expected)
		sort.Strings(want)
		got := found[table]
		sort.Strings(got)
		if strings.Join(want, ",") != strings.Join(got, ",") {
			return ErrUnavailable
		}
	}
	return nil
}
func owned(ctx context.Context, tx pgx.Tx, p auth.Principal, exclusive bool) error {
	lock := "FOR SHARE OF u"
	if exclusive {
		lock = "FOR UPDATE OF u"
	}
	var id string
	err := tx.QueryRow(ctx, `SELECT u.id::text FROM trainforge_v1.users u
 JOIN trainforge_v1.auth_families f ON f.user_id=u.id JOIN trainforge_v1.access_tokens a ON a.family_id=f.id
 WHERE u.id=$1 AND f.id=$2 AND a.token_hash=$3 AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL `+lock, p.User.ID, p.FamilyID, p.AccessHash).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return auth.ErrInvalid
	}
	if err != nil {
		return ErrUnavailable
	}
	return nil
}
func (p Postgres) begin(ctx context.Context, subject auth.Principal, exclusive bool) (pgx.Tx, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return nil, ErrUnavailable
	}
	if err = owned(ctx, tx, subject, exclusive); err == nil {
		err = coverage(ctx, tx)
	}
	if err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}
	return tx, nil
}

type section struct{ table, key, owner, projection string }

var sections = map[string]section{
	"account":          {"users", "v.id::text", "v.id", `jsonb_build_object('id',v.id,'provider',v.provider,'issuer',v.issuer,'subject',v.subject,'name',v.display_name,'email',v.email,'createdAt',v.created_at)`},
	"sessions":         {"auth_families", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'createdAt',v.created_at,'revokedAt',v.revoked_at)`},
	"enrollments":      {"enrollments", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'programId',v.program_id,'programVersion',v.program_sha,'programKind',v.program_kind,'status',v.status,'options',v.options,'createdAt',v.created_at)`},
	"occurrences":      {"schedule_occurrences", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'enrollmentId',v.enrollment_id,'programId',v.program_id,'programVersion',v.program_sha,'sourceSessionKey',v.source_session_key,'plannedFor',v.planned_for,'timezone',v.timezone)`},
	"activitySessions": {"activity_sessions", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'occurrenceId',v.occurrence_id,'state',v.state,'startedAt',v.started_at,'endedAt',v.ended_at,'completedAt',v.completed_at)`},
	"activityEvents":   {"activity_events", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'sessionId',v.session_id,'type',v.event_type,'occurredAt',v.occurred_at,'payload',v.payload)`},
	"foods":            {"food_versions", "v.food_id||':'||v.version_sha", "v.owner_id", `jsonb_build_object('id',v.food_id,'versionId',v.version_sha,'sourceId',v.source_id,'sourceFoodId',v.source_food_id,'sourceRowKey',v.source_row_key,'sourcePublishedVersion',v.source_published_version,'nameLocale',v.name_locale,'allowedOperations',v.allowed_operations,'nameOriginal',v.name_original,'namePt',v.name_pt,'preparation',v.preparation,'basisQuantity',v.basis_quantity::text,'basisUnit',v.basis_unit,'nutrients',v.nutrients,'provenance',v.provenance,'createdAt',v.created_at)`},
	"foodEntries":      {"food_entries", "v.id::text", "v.user_id", `jsonb_build_object('id',v.id,'foodId',v.food_id,'foodVersion',v.food_sha,'quantity',v.quantity::text,'unit',v.unit,'occurredAt',v.occurred_at,'timezone',v.timezone,'calculation',v.calculation,'deletedAt',v.deleted_at,'createdAt',v.created_at)`},
}

func (p Postgres) Export(ctx context.Context, subject auth.Principal, f ExportFilter) (ExportPage, error) {
	result := ExportPage{AccountID: subject.User.ID, Section: f.Section, Items: []json.RawMessage{}, GeneratedAt: time.Now().UTC(), Notice: "Exportação por seção no momento da solicitação; não é backup atômico. Tokens, hashes, confirmações de exclusão, caches internos e catálogo editorial são excluídos."}
	descriptor, ok := sections[f.Section]
	if !ok || f.Limit < 1 || f.Limit > 50 {
		return result, ErrQuery
	}
	tx, err := p.begin(ctx, subject, false)
	if err != nil {
		return result, err
	}
	defer tx.Rollback(ctx)
	// All SQL identifiers/projections come from the static allowlist above.
	query := "SELECT " + descriptor.key + "," + descriptor.projection + " FROM trainforge_v1." + descriptor.table + " v WHERE " + descriptor.owner + "=$1 AND ($2='' OR (" + descriptor.key + `) COLLATE "C">$2 COLLATE "C") ORDER BY (` + descriptor.key + `) COLLATE "C" LIMIT $3`
	rows, err := tx.Query(ctx, query, subject.User.ID, f.After, f.Limit+1)
	if err != nil {
		return result, ErrUnavailable
	}
	var last string
	size := 0
	for rows.Next() {
		var key string
		var raw []byte
		if rows.Scan(&key, &raw) != nil {
			rows.Close()
			return result, ErrUnavailable
		}
		if len(raw) > 1<<20 {
			rows.Close()
			return result, ErrUnavailable
		}
		if len(result.Items) >= f.Limit || size+len(raw) > 1<<20 {
			if last == "" {
				rows.Close()
				return result, ErrUnavailable
			}
			cursor := exportCursor(subject.User.ID, last, f)
			result.NextCursor = &cursor
			break
		}
		result.Items = append(result.Items, json.RawMessage(raw))
		size += len(raw)
		last = key
	}
	err = rows.Err()
	rows.Close()
	if err != nil || tx.Commit(ctx) != nil {
		return result, ErrUnavailable
	}
	return result, nil
}
func fresh(ctx context.Context, tx pgx.Tx, subject auth.Principal) error {
	var recent bool
	err := tx.QueryRow(ctx, `SELECT created_at>=clock_timestamp()-interval '15 minutes' AND created_at<=clock_timestamp()
 FROM trainforge_v1.auth_families WHERE id=$1 AND user_id=$2 AND revoked_at IS NULL`, subject.FamilyID, subject.User.ID).Scan(&recent)
	if errors.Is(err, pgx.ErrNoRows) {
		return auth.ErrInvalid
	}
	if err != nil {
		return ErrUnavailable
	}
	if !recent {
		return ErrReauthenticate
	}
	return nil
}
func (p Postgres) Intent(ctx context.Context, subject auth.Principal, hash []byte) (time.Time, error) {
	var expiry time.Time
	tx, err := p.begin(ctx, subject, true)
	if err != nil {
		return expiry, err
	}
	defer tx.Rollback(ctx)
	if err = fresh(ctx, tx, subject); err != nil {
		return expiry, err
	}
	err = tx.QueryRow(ctx, `INSERT INTO trainforge_v1.account_deletion_intents(token_hash,user_id,family_id,expires_at)
 VALUES($1,$2,$3,clock_timestamp()+$4::double precision*interval '1 second') ON CONFLICT(user_id,family_id) DO UPDATE SET token_hash=EXCLUDED.token_hash,expires_at=EXCLUDED.expires_at,created_at=clock_timestamp() RETURNING expires_at`, hash, subject.User.ID, subject.FamilyID, IntentTTL.Seconds()).Scan(&expiry)
	if err != nil {
		return expiry, ErrUnavailable
	}
	if tx.Commit(ctx) != nil {
		return expiry, ErrUnavailable
	}
	return expiry, nil
}
func purge(ctx context.Context, tx pgx.Tx, user string, foodCleanup func() error) error {
	commands := []string{
		"DELETE FROM trainforge_v1.activity_events WHERE user_id=$1",
		"DELETE FROM trainforge_v1.activity_sessions WHERE user_id=$1",
		"DELETE FROM trainforge_v1.schedule_occurrences WHERE user_id=$1",
		"DELETE FROM trainforge_v1.enrollments WHERE user_id=$1",
		"DELETE FROM trainforge_v1.food_entries WHERE user_id=$1",
		"private_food_cleanup",
		"DELETE FROM trainforge_v1.account_deletion_intents WHERE user_id=$1",
		"DELETE FROM trainforge_v1.idempotency_records WHERE user_id=$1",
		"DELETE FROM trainforge_v1.access_tokens WHERE family_id IN(SELECT id FROM trainforge_v1.auth_families WHERE user_id=$1)",
		"DELETE FROM trainforge_v1.refresh_tokens WHERE family_id IN(SELECT id FROM trainforge_v1.auth_families WHERE user_id=$1)",
		"DELETE FROM trainforge_v1.auth_families WHERE user_id=$1",
		"DELETE FROM trainforge_v1.users WHERE id=$1",
	}
	for _, command := range commands {
		if command == "private_food_cleanup" {
			if foodCleanup() == nil {
				continue
			}
			return ErrUnavailable
		}
		if _, err := tx.Exec(ctx, command, user); err != nil {
			return ErrUnavailable
		}
	}
	return nil
}
func (p Postgres) Delete(ctx context.Context, subject auth.Principal, hash []byte) (Erased, error) {
	result := Erased{}
	tx, err := p.begin(ctx, subject, true)
	if err != nil {
		return result, err
	}
	defer tx.Rollback(ctx)
	// Serialize with refresh/logout for every family of the account.
	rows, err := tx.Query(ctx, "SELECT id FROM trainforge_v1.auth_families WHERE user_id=$1 ORDER BY id FOR UPDATE", subject.User.ID)
	if err != nil {
		return result, ErrUnavailable
	}
	for rows.Next() {
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return result, ErrUnavailable
	}
	if err = owned(ctx, tx, subject, true); err != nil {
		return result, err
	}
	if err = fresh(ctx, tx, subject); err != nil {
		return result, err
	}
	var valid bool
	err = tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.account_deletion_intents
 WHERE token_hash=$1 AND user_id=$2 AND family_id=$3 AND expires_at>clock_timestamp())`, hash, subject.User.ID, subject.FamilyID).Scan(&valid)
	if err != nil {
		return result, ErrUnavailable
	}
	if !valid {
		return result, ErrConfirmation
	}
	if err = tx.QueryRow(ctx, "INSERT INTO trainforge_v1.account_erasures(user_id) VALUES($1) ON CONFLICT DO NOTHING RETURNING erased_at", subject.User.ID).Scan(&result.ErasedAt); err != nil {
		return result, ErrUnavailable
	}
	if err = purge(ctx, tx, subject.User.ID, func() error {
		_, err := tx.Exec(ctx, "SELECT trainforge_v1.erase_private_foods($1,$2,$3,$4)", subject.User.ID, subject.FamilyID, subject.AccessHash, hash)
		return err
	}); err != nil {
		return result, err
	}
	if tx.Commit(ctx) != nil {
		return result, ErrUnavailable
	}
	result.AccountID = subject.User.ID
	result.Deleted = true
	result.BackupNotice = CurrentPolicy().BackupRetention
	return result, nil
}
