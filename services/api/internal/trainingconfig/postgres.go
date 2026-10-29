package trainingconfig

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"trainforge.local/api/internal/auth"
)

type Postgres struct {
	Pool         *pgxpool.Pool
	CatalogGuard func(context.Context, pgx.Tx) error
}

func (p Postgres) begin(ctx context.Context, actor auth.Principal) (pgx.Tx, error) {
	if !actorValid(actor) {
		return nil, auth.ErrInvalid
	}
	if p.Pool == nil {
		return nil, ErrUnavailable
	}
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return nil, ErrUnavailable
	}
	var id string
	err = tx.QueryRow(ctx, `SELECT u.id::text FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=$1 AND f.id=$2 AND a.token_hash=$3 AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL FOR SHARE OF u,f`, actor.User.ID, actor.FamilyID, actor.AccessHash).Scan(&id)
	if err != nil {
		tx.Rollback(ctx)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, auth.ErrInvalid
		}
		return nil, ErrUnavailable
	}
	return tx, nil
}
func (p Postgres) Load(ctx context.Context, actor auth.Principal) (*Snapshot, error) {
	tx, err := p.begin(ctx, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)
	var result Snapshot
	var raw []byte
	err = tx.QueryRow(ctx, `SELECT revision,configuration,confirmed_at FROM trainforge_v1.training_configuration_versions WHERE user_id=$1 ORDER BY revision DESC LIMIT 1`, actor.User.ID).Scan(&result.Revision, &raw, &result.ConfirmedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		if tx.Commit(ctx) != nil {
			return nil, ErrUnavailable
		}
		return nil, nil
	}
	if err != nil || json.Unmarshal(raw, &result.Configuration) != nil {
		return nil, ErrUnavailable
	}
	result.Contract = Contract
	if !snapshotValid(result) || tx.Commit(ctx) != nil {
		return nil, ErrUnavailable
	}
	return &result, nil
}
func (p Postgres) Save(ctx context.Context, actor auth.Principal, command SaveCommand, key string) (Snapshot, error) {
	if !actorValid(actor) {
		return Snapshot{}, auth.ErrInvalid
	}
	if issues := command.Validate(); len(issues) != 0 {
		return Snapshot{}, issues
	}
	if !uuidPattern.MatchString(key) {
		return Snapshot{}, FieldIssues{"idempotencyKey": "invalid_idempotency_key"}
	}
	if p.Pool == nil {
		return Snapshot{}, ErrUnavailable
	}
	raw, err := json.Marshal(command.Canonical())
	if err != nil {
		return Snapshot{}, ErrUnavailable
	}
	var saved []byte
	var query interface {
		QueryRow(context.Context, string, ...any) pgx.Row
	} = p.Pool
	var guarded pgx.Tx
	if p.CatalogGuard != nil && len(command.Configuration.Resources.Items) > 0 {
		guarded, err = p.Pool.Begin(ctx)
		if err != nil {
			return Snapshot{}, ErrUnavailable
		}
		defer guarded.Rollback(ctx)
		if p.CatalogGuard(ctx, guarded) != nil {
			return Snapshot{}, ErrUnavailable
		}
		query = guarded
	}
	err = query.QueryRow(ctx, `SELECT trainforge_v1.save_training_configuration($1,$2,$3,$4::jsonb,$5::uuid)`, actor.User.ID, actor.FamilyID, actor.AccessHash, raw, key).Scan(&saved)
	if err != nil {
		var pg *pgconn.PgError
		if errors.As(err, &pg) {
			switch pg.Code {
			case "TFA01":
				return Snapshot{}, auth.ErrInvalid
			case "TFC01":
				return Snapshot{}, ErrConflict
			case "TFQ01":
				return Snapshot{}, FieldIssues{"configuration": "invalid_configuration"}
			case "TFQ02":
				if resourceFieldPattern.MatchString(pg.Detail) {
					return Snapshot{}, FieldIssues{pg.Detail: "resource_unavailable"}
				}
			}
		}
		return Snapshot{}, ErrUnavailable
	}
	var result Snapshot
	if json.Unmarshal(saved, &result) != nil || !snapshotValid(result) {
		return Snapshot{}, ErrUnavailable
	}
	if guarded != nil && guarded.Commit(ctx) != nil {
		return Snapshot{}, ErrUnavailable
	}
	return result, nil
}

func (p Postgres) Resources(ctx context.Context, actor auth.Principal, f ResourceFilter) ([]ResourceOption, error) {
	tx, err := p.begin(ctx, actor)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)
	if p.CatalogGuard != nil && p.CatalogGuard(ctx, tx) != nil {
		return nil, ErrUnavailable
	}
	rows, err := tx.Query(ctx, `SELECT source_id,equipment_id,name_original,source_name FROM trainforge_v1.training_configuration_resources WHERE ($1='' OR position(lower($1) in lower(name_original))>0) AND (source_id COLLATE "C">$2 COLLATE "C" OR (source_id=$2 AND equipment_id>$3)) ORDER BY source_id COLLATE "C",equipment_id LIMIT $4`, f.Q, f.AfterSource, f.AfterID, f.Limit+1)
	if err != nil {
		return nil, ErrUnavailable
	}
	result := []ResourceOption{}
	for rows.Next() {
		var item ResourceOption
		if rows.Scan(&item.SourceID, &item.EquipmentID, &item.Name, &item.SourceName) != nil {
			rows.Close()
			return nil, ErrUnavailable
		}
		result = append(result, item)
	}
	err = rows.Err()
	rows.Close()
	if err != nil || tx.Commit(ctx) != nil {
		return nil, ErrUnavailable
	}
	return result, nil
}

func (p Postgres) ResolveResources(ctx context.Context, actor auth.Principal, refs []ResourceRef) ([]ResourceOption, error) {
	if len(refs) > 32 {
		return nil, FieldIssues{"configuration.resources.items": "invalid_resources"}
	}
	sources := []string{}
	ids := []int{}
	for _, ref := range refs {
		sources = append(sources, ref.SourceID)
		ids = append(ids, ref.EquipmentID)
	}
	tx, e := p.begin(ctx, actor)
	if e != nil {
		return nil, e
	}
	defer tx.Rollback(ctx)
	if len(refs) > 0 && p.CatalogGuard != nil && p.CatalogGuard(ctx, tx) != nil {
		return nil, ErrUnavailable
	}
	rows, e := tx.Query(ctx, "SELECT r.source_id,r.equipment_id,r.name_original,r.source_name FROM trainforge_v1.training_configuration_resources r JOIN unnest($1::text[],$2::int[]) wanted(source_id,equipment_id) USING(source_id,equipment_id) ORDER BY r.source_id COLLATE \"C\",r.equipment_id", sources, ids)
	if e != nil {
		return nil, ErrUnavailable
	}
	result := []ResourceOption{}
	for rows.Next() {
		var item ResourceOption
		if rows.Scan(&item.SourceID, &item.EquipmentID, &item.Name, &item.SourceName) != nil {
			rows.Close()
			return nil, ErrUnavailable
		}
		result = append(result, item)
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return nil, ErrUnavailable
	}
	return result, nil
}
