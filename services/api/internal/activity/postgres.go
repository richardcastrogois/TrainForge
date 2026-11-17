package activity

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"reflect"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/catalogauthority"
	"unicode"
	"unicode/utf8"
)

type ActivityStore struct {
	Pool         *pgxpool.Pool
	CatalogGuard func(context.Context, pgx.Tx) error
	Now          func() time.Time
}

func actorValid(p auth.Principal) bool {
	return uuid.MatchString(p.User.ID) && uuid.MatchString(p.FamilyID) && len(p.AccessHash) == 32
}
func (s ActivityStore) now() time.Time {
	f := time.Now
	if s.Now != nil {
		f = s.Now
	}
	return f().UTC().Truncate(time.Microsecond)
}
func hash(raw []byte) []byte     { v := sha256.Sum256(raw); return v[:] }
func hashText(raw []byte) string { return hex.EncodeToString(hash(raw)) }

// UUIDv8 from the owner's and intent's namespace. The client command UUID stays
// in the event payload; equal intent UUIDs from two owners never contend for a
// global event primary key or disclose one another's operations.
func eventID(owner, key string) string {
	b := hash([]byte("trainforge.activity-event/1\x00" + owner + "\x00" + key))[:16]
	b[6] = (b[6] & 15) | 128
	b[8] = (b[8] & 63) | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[:4], b[4:6], b[6:8], b[8:10], b[10:])
}
func newID() (string, error) {
	var b [16]byte
	if _, e := rand.Read(b[:]); e != nil {
		return "", ErrUnavailable
	}
	b[6] = (b[6] & 15) | 64
	b[8] = (b[8] & 63) | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[:4], b[4:6], b[6:8], b[8:10], b[10:]), nil
}
func storageError(e error) error {
	var p *pgconn.PgError
	if errors.As(e, &p) && (p.Code == "23505" || p.Code == "40001" || p.Code == "40P01") {
		return ErrConflict
	}
	return ErrUnavailable
}
func titleValue(title, fallback string) (string, error) {
	if title == "" {
		title = fallback
	}
	if strings.TrimSpace(title) == "" || !utf8.ValidString(title) || utf8.RuneCountInString(title) > 360 || strings.IndexFunc(title, unicode.IsControl) >= 0 {
		return "", ErrUnavailable
	}
	return title, nil
}

func (s ActivityStore) begin(ctx context.Context, p auth.Principal, write bool) (pgx.Tx, error) {
	if !actorValid(p) {
		return nil, auth.ErrInvalid
	}
	if s.Pool == nil {
		return nil, ErrUnavailable
	}
	tx, e := s.Pool.Begin(ctx)
	if e != nil {
		return nil, ErrUnavailable
	}
	// Match training configuration's projection -> owner lock order. Taking
	// these in opposite orders could deadlock with an editorial publication
	// waiting between a configuration save and an activity command.
	if _, e = tx.Exec(ctx, `SELECT pg_advisory_xact_lock_shared($1)`, catalogauthority.ProjectionLock); e != nil {
		tx.Rollback(ctx)
		return nil, ErrUnavailable
	}
	lock := " FOR SHARE OF u,f"
	if write {
		lock = " FOR UPDATE OF u FOR SHARE OF f"
	}
	var id string
	e = tx.QueryRow(ctx, `SELECT u.id::text FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=$1 AND f.id=$2 AND a.token_hash=$3 AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL`+lock, p.User.ID, p.FamilyID, p.AccessHash).Scan(&id)
	if e != nil {
		tx.Rollback(ctx)
		if errors.Is(e, pgx.ErrNoRows) {
			return nil, auth.ErrInvalid
		}
		return nil, ErrUnavailable
	}
	return tx, nil
}

// Publication and withdrawal take the exclusive projection lock. A remote
// outage disables new practice, while preserving reads and explicit closure.
func (s ActivityStore) ready(ctx context.Context, tx pgx.Tx) (bool, error) {
	if s.CatalogGuard != nil && s.CatalogGuard(ctx, tx) != nil {
		return false, nil
	}
	return true, nil
}

const permittedPractice = `('catalog_metadata'=ANY(v.allowed_operations)
 AND v.payload#>>'{rights,operationGrants,catalog_metadata}'='allowed'
 AND 'guided_practice'=ANY(v.allowed_operations)
 AND v.payload#>>'{rights,operationGrants,guided_practice}'='allowed'
 AND v.payload#>>'{review,state}'='reviewed'
 AND v.payload#>>'{review,rightsVerified}'='true'
 AND v.payload#>>'{review,fidelityChecked}'='true'
 AND v.payload#>>'{review,instructionSufficient}'='true'
 AND v.payload#>>'{review,safetyUseReviewed}'='true'
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.content_withdrawals w WHERE w.asset_id=v.asset_id AND w.version_sha=v.version_sha))`

func prescriptionFor(ctx context.Context, tx pgx.Tx, source Source) ([]Item, string, []MovementLabel, bool, error) {
	items := []Item{}
	labels := []MovementLabel{}
	var title string
	var allowed bool
	var expected int
	e := tx.QueryRow(ctx, `SELECT coalesce(v.title,''),coalesce(`+permittedPractice+`,false),(SELECT count(*) FROM trainforge_v1.program_items i WHERE i.program_id=$1 AND i.program_sha=$2 AND i.session_key=$3) FROM trainforge_v1.content_versions v WHERE v.asset_id=$1 AND v.version_sha=$2 AND v.kind='program'`, source.ProgramID, source.ProgramVersion, source.SessionKey).Scan(&title, &allowed, &expected)
	if errors.Is(e, pgx.ErrNoRows) {
		return items, source.SessionKey, labels, false, nil
	}
	if e != nil {
		return nil, "", nil, false, ErrUnavailable
	}
	allowed = allowed && title != ""
	title, e = titleValue(title, source.SessionKey)
	if e != nil {
		return nil, "", nil, false, e
	}
	rows, e := tx.Query(ctx, `SELECT i.position,i.movement_id,i.movement_sha,i.source_dose,coalesce(v.title,''),coalesce(`+permittedPractice+`,false) FROM trainforge_v1.program_items i JOIN trainforge_v1.content_versions v ON v.asset_id=i.movement_id AND v.version_sha=i.movement_sha AND v.kind='movement' WHERE i.program_id=$1 AND i.program_sha=$2 AND i.session_key=$3 ORDER BY i.position LIMIT 101`, source.ProgramID, source.ProgramVersion, source.SessionKey)
	if e != nil {
		return nil, "", nil, false, ErrUnavailable
	}
	defer rows.Close()
	total := 0
	itemRows := 0
	seen := map[string]bool{}
	for rows.Next() {
		itemRows++
		var pos int
		var id, ver, label string
		var raw []byte
		var usable bool
		if rows.Scan(&pos, &id, &ver, &raw, &label, &usable) != nil {
			return nil, "", nil, false, ErrUnavailable
		}
		item, problem := prescribedItem(pos, id, ver, raw)
		if problem != nil {
			allowed = false
		} else {
			items = append(items, item)
			total += len(item.Targets)
		}
		usable = usable && label != ""
		label, e = titleValue(label, id)
		if e != nil {
			return nil, "", nil, false, e
		}
		if !seen[id+"/"+ver] {
			labels = append(labels, MovementLabel{ID: id, VersionID: ver, Title: label})
			seen[id+"/"+ver] = true
		}
		allowed = allowed && usable
	}
	if rows.Err() != nil {
		return nil, "", nil, false, ErrUnavailable
	}
	if len(items) == 0 || len(items) > 100 || total > maxSets || itemRows != expected || expected < 1 || expected > 100 {
		allowed = false
	}
	return items, title, labels, allowed, nil
}

type loadedSession struct {
	session          Session
	title            string
	labels           []MovementLabel
	activeEnrollment bool
}

func loadSession(ctx context.Context, tx pgx.Tx, p auth.Principal, id string, write bool) (loadedSession, error) {
	var loaded loadedSession
	var state string
	var start time.Time
	var end, completed *time.Time
	var occurrence string
	var source Source
	lock := ""
	if write {
		lock = " FOR UPDATE OF o,s"
	}
	e := tx.QueryRow(ctx, `SELECT s.occurrence_id::text,s.state,s.started_at,s.ended_at,s.completed_at,e.status='active',o.program_id,o.program_sha,o.source_session_key FROM trainforge_v1.activity_sessions s JOIN trainforge_v1.schedule_occurrences o ON o.id=s.occurrence_id AND o.user_id=s.user_id JOIN trainforge_v1.enrollments e ON e.id=o.enrollment_id AND e.user_id=o.user_id WHERE s.user_id=$1 AND s.id=$2`+lock, p.User.ID, id).Scan(&occurrence, &state, &start, &end, &completed, &loaded.activeEnrollment, &source.ProgramID, &source.ProgramVersion, &source.SessionKey)
	if errors.Is(e, pgx.ErrNoRows) {
		return loaded, ErrMissing
	}
	if e != nil {
		return loaded, ErrUnavailable
	}
	rows, e := tx.Query(ctx, `SELECT id::text,event_type,occurred_at,payload FROM trainforge_v1.activity_events WHERE user_id=$1 AND session_id=$2 ORDER BY (payload->>'revision')::integer,id LIMIT 4099`, p.User.ID, id)
	if e != nil {
		return loaded, ErrUnavailable
	}
	events := []storedEvent{}
	for rows.Next() {
		var v storedEvent
		if rows.Scan(&v.ID, &v.Kind, &v.At, &v.Payload) != nil {
			rows.Close()
			return loaded, ErrUnavailable
		}
		events = append(events, v)
	}
	e = rows.Err()
	rows.Close()
	if e != nil {
		return loaded, ErrUnavailable
	}
	loaded.session, loaded.title, loaded.labels, e = restore(events)
	if e != nil {
		return loaded, e
	}
	v := loaded.session.snapshot
	if v.ID != id || v.OwnerID != p.User.ID || v.OccurrenceID != occurrence || v.Source != source || string(v.State) != state || !v.StartedAt.Equal(start) || !sameTime(v.EndedAt, end) || (v.State == Completed && !sameTime(v.EndedAt, completed)) || (v.State != Completed && completed != nil) {
		return loaded, ErrUnavailable
	}
	return loaded, nil
}
func sameTime(a, b *time.Time) bool {
	return (a == nil && b == nil) || (a != nil && b != nil && a.Equal(*b))
}
func detailFor(ctx context.Context, tx pgx.Tx, l loadedSession, remote bool) (Detail, error) {
	v := l.session.Snapshot()
	items, _, _, available, e := prescriptionFor(ctx, tx, v.Source)
	if e != nil {
		return Detail{}, e
	}
	return Detail{Snapshot: v, Title: l.title, MovementLabels: clone(l.labels), PracticeAvailable: remote && available && l.activeEnrollment && reflect.DeepEqual(items, v.Items)}, nil
}
func (s ActivityStore) Detail(ctx context.Context, p auth.Principal, id string) (Detail, error) {
	if !uuid.MatchString(id) {
		return Detail{}, ErrInvalid
	}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return Detail{}, e
	}
	defer tx.Rollback(ctx)
	l, e := loadSession(ctx, tx, p, id, false)
	if e != nil {
		return Detail{}, e
	}
	remote, e := s.ready(ctx, tx)
	if e != nil {
		return Detail{}, e
	}
	d, e := detailFor(ctx, tx, l, remote)
	if e != nil {
		return Detail{}, e
	}
	if tx.Commit(ctx) != nil {
		return Detail{}, ErrUnavailable
	}
	return d, nil
}
func (s ActivityStore) Feed(ctx context.Context, p auth.Principal) (Feed, error) {
	out := Feed{Upcoming: []Upcoming{}, Sessions: []Detail{}, Complete: true}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return out, e
	}
	defer tx.Rollback(ctx)
	remote, e := s.ready(ctx, tx)
	if e != nil {
		return out, e
	}
	rows, e := tx.Query(ctx, `SELECT o.id::text,o.planned_for,o.timezone,o.program_id,o.program_sha,o.source_session_key FROM trainforge_v1.schedule_occurrences o JOIN trainforge_v1.enrollments e ON e.id=o.enrollment_id AND e.user_id=o.user_id WHERE o.user_id=$1 AND e.status='active' AND NOT EXISTS(SELECT 1 FROM trainforge_v1.activity_sessions s WHERE s.occurrence_id=o.id AND s.user_id=o.user_id) ORDER BY o.planned_for,o.id LIMIT 33`, p.User.ID)
	if e != nil {
		return out, ErrUnavailable
	}
	for rows.Next() {
		var u Upcoming
		if rows.Scan(&u.ID, &u.PlannedFor, &u.Timezone, &u.Source.ProgramID, &u.Source.ProgramVersion, &u.Source.SessionKey) != nil {
			rows.Close()
			return out, ErrUnavailable
		}
		u.PlannedFor = u.PlannedFor.UTC()
		out.Upcoming = append(out.Upcoming, u)
	}
	e = rows.Err()
	rows.Close()
	if e != nil {
		return out, ErrUnavailable
	}
	if len(out.Upcoming) > 32 {
		out.Upcoming = out.Upcoming[:32]
		out.Complete = false
	}
	for n := range out.Upcoming {
		u := &out.Upcoming[n]
		_, title, _, ok, e := prescriptionFor(ctx, tx, u.Source)
		if e != nil {
			return out, e
		}
		u.Title = title
		u.PracticeAvailable = remote && ok
	}
	rows, e = tx.Query(ctx, `SELECT id::text FROM trainforge_v1.activity_sessions WHERE user_id=$1 ORDER BY started_at DESC,id DESC LIMIT 33`, p.User.ID)
	if e != nil {
		return out, ErrUnavailable
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if rows.Scan(&id) != nil {
			rows.Close()
			return out, ErrUnavailable
		}
		ids = append(ids, id)
	}
	e = rows.Err()
	rows.Close()
	if e != nil {
		return out, ErrUnavailable
	}
	if len(ids) > 32 {
		ids = ids[:32]
		out.Complete = false
	}
	for _, id := range ids {
		l, e := loadSession(ctx, tx, p, id, false)
		if e != nil {
			return out, e
		}
		d, e := detailFor(ctx, tx, l, remote)
		if e != nil {
			return out, e
		}
		out.Sessions = append(out.Sessions, d)
	}
	if tx.Commit(ctx) != nil {
		return out, ErrUnavailable
	}
	return out, nil
}

// Event IDs outlive the response cache: an expired retry cannot become a
// second mutation after idempotency_records are cleaned by maintenance.
func prior(ctx context.Context, tx pgx.Tx, p auth.Principal, key string, raw []byte) (string, int, bool, error) {
	var id string
	var payload []byte
	e := tx.QueryRow(ctx, `SELECT session_id::text,payload FROM trainforge_v1.activity_events WHERE user_id=$1 AND id=$2`, p.User.ID, eventID(p.User.ID, key)).Scan(&id, &payload)
	if e == nil {
		var v event
		if !strict(payload, &v) || v.Contract != eventContract || v.CommandID != key {
			return "", 0, false, ErrUnavailable
		}
		if v.RequestHash != hashText(raw) {
			return "", 0, false, ErrConflict
		}
		return id, v.Revision, true, nil
	}
	if !errors.Is(e, pgx.ErrNoRows) {
		return "", 0, false, ErrUnavailable
	}
	var exists bool
	e = tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.idempotency_records WHERE user_id=$1 AND operation='activity' AND key_hash=$2)`, p.User.ID, hash([]byte(key))).Scan(&exists)
	if e != nil {
		return "", 0, false, ErrUnavailable
	}
	if exists {
		return "", 0, false, ErrConflict
	}
	return "", 0, false, nil
}
func saveEvent(ctx context.Context, tx pgx.Tx, p auth.Principal, id, key, kind string, at time.Time, v event, raw []byte, status int) error {
	v.CommandID = key
	body, e := json.Marshal(v)
	if e != nil {
		return ErrUnavailable
	}
	if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.activity_events(id,session_id,user_id,event_type,occurred_at,payload) VALUES($1,$2,$3,$4,$5,$6)`, eventID(p.User.ID, key), id, p.User.ID, kind, at, body); e != nil {
		return storageError(e)
	}
	response, _ := json.Marshal(struct {
		SessionID       string `json:"sessionId"`
		AppliedRevision int    `json:"appliedRevision"`
	}{id, v.Revision})
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,response_body,expires_at) VALUES($1,'activity',$2,$3,$4,$5,clock_timestamp()+interval '24 hours')`, p.User.ID, hash([]byte(key)), hash(raw), status, response)
	if e != nil {
		return storageError(e)
	}
	return nil
}
func (s ActivityStore) replay(ctx context.Context, tx pgx.Tx, p auth.Principal, id string, revision int) (MutationResult, error) {
	l, e := loadSession(ctx, tx, p, id, true)
	if e != nil {
		return MutationResult{}, e
	}
	if revision < 1 || revision > l.session.snapshot.Revision {
		return MutationResult{}, ErrUnavailable
	}
	remote, e := s.ready(ctx, tx)
	if e != nil {
		return MutationResult{}, e
	}
	d, e := detailFor(ctx, tx, l, remote)
	if e != nil {
		return MutationResult{}, e
	}
	if tx.Commit(ctx) != nil {
		return MutationResult{}, ErrUnavailable
	}
	return MutationResult{Detail: d, AppliedRevision: revision, Replayed: true}, nil
}
func (s ActivityStore) Start(ctx context.Context, p auth.Principal, in StartRequest, key string) (MutationResult, error) {
	if !uuid.MatchString(in.OccurrenceID) || !uuid.MatchString(key) {
		return MutationResult{}, ErrInvalid
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return MutationResult{}, e
	}
	defer tx.Rollback(ctx)
	raw := startCanonical(in)
	if id, rev, found, e := prior(ctx, tx, p, key, raw); e != nil {
		return MutationResult{}, e
	} else if found {
		return s.replay(ctx, tx, p, id, rev)
	}
	var source Source
	var active bool
	e = tx.QueryRow(ctx, `SELECT o.program_id,o.program_sha,o.source_session_key,e.status='active' FROM trainforge_v1.schedule_occurrences o JOIN trainforge_v1.enrollments e ON e.id=o.enrollment_id AND e.user_id=o.user_id WHERE o.user_id=$1 AND o.id=$2 FOR UPDATE OF o,e`, p.User.ID, in.OccurrenceID).Scan(&source.ProgramID, &source.ProgramVersion, &source.SessionKey, &active)
	if errors.Is(e, pgx.ErrNoRows) {
		return MutationResult{}, ErrMissing
	}
	if e != nil {
		return MutationResult{}, ErrUnavailable
	}
	var used bool
	if tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.activity_sessions WHERE user_id=$1 AND occurrence_id=$2)`, p.User.ID, in.OccurrenceID).Scan(&used) != nil {
		return MutationResult{}, ErrUnavailable
	}
	if used {
		return MutationResult{}, ErrConflict
	}
	remote, e := s.ready(ctx, tx)
	if e != nil {
		return MutationResult{}, e
	}
	items, title, labels, allowed, e := prescriptionFor(ctx, tx, source)
	if e != nil {
		return MutationResult{}, e
	}
	if !remote || !active || !allowed {
		return MutationResult{}, ErrPracticeUnavailable
	}
	id, e := newID()
	if e != nil {
		return MutationResult{}, e
	}
	at := s.now()
	start := StartInput{ID: id, OwnerID: p.User.ID, OccurrenceID: in.OccurrenceID, Source: source, At: at, Items: items}
	engine, e := Start(start)
	if e != nil {
		return MutationResult{}, ErrPracticeUnavailable
	}
	if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.activity_sessions(id,occurrence_id,user_id,state,started_at) VALUES($1,$2,$3,'started',$4)`, id, in.OccurrenceID, p.User.ID, at); e != nil {
		return MutationResult{}, storageError(e)
	}
	v := event{Contract: eventContract, Revision: 1, RequestHash: hashText(raw), Start: &start, Title: title, MovementLabels: labels}
	if e = saveEvent(ctx, tx, p, id, key, "session_started", at, v, raw, 201); e != nil {
		return MutationResult{}, e
	}
	d := Detail{Snapshot: engine.Snapshot(), Title: title, MovementLabels: labels, PracticeAvailable: true}
	if tx.Commit(ctx) != nil {
		return MutationResult{}, ErrUnavailable
	}
	return MutationResult{Detail: d, AppliedRevision: 1}, nil
}
func (s ActivityStore) Command(ctx context.Context, p auth.Principal, id string, in CommandInput, key string) (MutationResult, error) {
	if !uuid.MatchString(id) || !uuid.MatchString(key) || !in.valid() {
		return MutationResult{}, ErrInvalid
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return MutationResult{}, e
	}
	defer tx.Rollback(ctx)
	raw := commandCanonical(id, in)
	if saved, rev, found, e := prior(ctx, tx, p, key, raw); e != nil {
		return MutationResult{}, e
	} else if found {
		if saved != id {
			return MutationResult{}, ErrConflict
		}
		return s.replay(ctx, tx, p, id, rev)
	}
	l, e := loadSession(ctx, tx, p, id, true)
	if e != nil {
		return MutationResult{}, e
	}
	remote, e := s.ready(ctx, tx)
	if e != nil {
		return MutationResult{}, e
	}
	d, e := detailFor(ctx, tx, l, remote)
	if e != nil {
		return MutationResult{}, e
	}
	if (in.Action == "record_set" || in.Action == "resume") && !d.PracticeAvailable {
		return MutationResult{}, ErrPracticeUnavailable
	}
	at := s.now()
	if at.Before(l.session.snapshot.LastEventAt) {
		at = l.session.snapshot.LastEventAt
	}
	c := Command{ID: key, ExpectedRevision: in.ExpectedRevision, Action: in.Action, At: at, Confirmed: in.Confirmed, Set: in.Set}
	next, result, e := l.session.Apply(c)
	if e != nil {
		return MutationResult{}, e
	}
	v := next.Snapshot()
	var completed *time.Time
	if v.State == Completed {
		completed = v.EndedAt
	}
	if _, e = tx.Exec(ctx, `UPDATE trainforge_v1.activity_sessions SET state=$3,ended_at=$4,completed_at=$5 WHERE user_id=$1 AND id=$2`, p.User.ID, id, v.State, v.EndedAt, completed); e != nil {
		return MutationResult{}, storageError(e)
	}
	envelope := event{Contract: eventContract, Revision: v.Revision, RequestHash: hashText(raw), Command: &c}
	if e = saveEvent(ctx, tx, p, id, key, "session_command", at, envelope, raw, 200); e != nil {
		return MutationResult{}, e
	}
	d.Snapshot = v
	if tx.Commit(ctx) != nil {
		return MutationResult{}, ErrUnavailable
	}
	return MutationResult{Detail: d, AppliedRevision: result.AppliedRevision}, nil
}
