package activity

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"regexp"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/privacy"
)

// Every account and prescription in this file is synthetic and exists only in a
// guarded database created specifically for these tests, never in the delivered DB.
type activityFixtureVerifier struct{ subject string }

func (v activityFixtureVerifier) Verify(context.Context, string) (auth.Identity, error) {
	return auth.Identity{Issuer: "https://accounts.google.com", Subject: v.subject,
		Name: "Disposable activity fixture", Email: "activity-fixture@example.invalid"}, nil
}

func activitySQLID(t *testing.T) string {
	t.Helper()
	var value [16]byte
	if _, err := rand.Read(value[:]); err != nil {
		t.Fatal("fixture identity generation")
	}
	value[6] = (value[6] & 15) | 64
	value[8] = (value[8] & 63) | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", value[:4], value[4:6], value[6:8], value[8:10], value[10:])
}

type activitySQLFixture struct {
	ctx                         context.Context
	writer, runtime             *pgxpool.Pool
	authentication              auth.Service
	a, b                        auth.Principal
	aSession, bSession          auth.Session
	program, movement, duration string
	enrollmentA, enrollmentB    string
	occurrenceA, occurrenceB    string
	clock                       time.Time
}

func activityPools(t *testing.T) (context.Context, *pgxpool.Pool, *pgxpool.Pool) {
	t.Helper()
	writerDSN, runtimeDSN := os.Getenv("TF_ACTIVITY_TEST_DATABASE_URL"), os.Getenv("TF_ACTIVITY_TEST_RUNTIME_URL")
	if writerDSN == "" && runtimeDSN == "" {
		t.Skip("disposable activity SQL fixture not requested")
	}
	wc, err := pgxpool.ParseConfig(writerDSN)
	if writerDSN == "" || err != nil || wc.ConnConfig.Host != "127.0.0.1" || wc.ConnConfig.Port != 15432 ||
		wc.ConnConfig.User != "trainforge_migrator" ||
		wc.ConnConfig.TLSConfig != nil || len(wc.ConnConfig.Fallbacks) != 0 ||
		!regexp.MustCompile(`^trainforge_v1_activity_test_[a-f0-9]{12}$`).MatchString(wc.ConnConfig.Database) {
		t.Fatal("unsafe activity writer target")
	}
	rc, err := pgxpool.ParseConfig(runtimeDSN)
	if runtimeDSN == "" || err != nil || rc.ConnConfig.Host != wc.ConnConfig.Host || rc.ConnConfig.Port != wc.ConnConfig.Port ||
		rc.ConnConfig.Database != wc.ConnConfig.Database || rc.ConnConfig.User != "trainforge_runtime" ||
		rc.ConnConfig.TLSConfig != nil || len(rc.ConnConfig.Fallbacks) != 0 {
		t.Fatal("unsafe activity runtime target")
	}
	wc.MaxConns, rc.MaxConns = 2, 4
	ctx, cancel := context.WithTimeout(context.Background(), 75*time.Second)
	t.Cleanup(cancel)
	writer, err := pgxpool.NewWithConfig(ctx, wc)
	if err != nil {
		t.Fatal("activity writer pool")
	}
	t.Cleanup(writer.Close)
	runtime, err := pgxpool.NewWithConfig(ctx, rc)
	if err != nil {
		t.Fatal("activity runtime pool")
	}
	t.Cleanup(runtime.Close)
	return ctx, writer, runtime
}

func newActivitySQLFixture(t *testing.T) *activitySQLFixture {
	t.Helper()
	ctx, writer, runtime := activityPools(t)
	f := &activitySQLFixture{ctx: ctx, writer: writer, runtime: runtime,
		clock: time.Now().UTC().Truncate(time.Microsecond)}
	login := func(subject string) (auth.Service, auth.Session, auth.Principal) {
		s := auth.Service{Verifier: activityFixtureVerifier{subject}, Repository: auth.Postgres{Pool: runtime}}
		session, err := s.Login(ctx, "synthetic-disposable-activity-not-google")
		if err != nil {
			t.Fatal("activity fixture login")
		}
		actor, err := s.Authorize(ctx, session.AccessToken)
		if err != nil {
			t.Fatal("activity fixture principal")
		}
		return s, session, actor
	}
	f.authentication, f.aSession, f.a = login("activity-fixture-a-" + activitySQLID(t))
	_, f.bSession, f.b = login("activity-fixture-b-" + activitySQLID(t))
	nonce := activitySQLID(t)
	f.program, f.movement, f.duration = "test:activity:program:"+nonce, "test:activity:repetitions:"+nonce, "test:activity:duration:"+nonce
	source := "test:activity:source:" + nonce
	f.exec(t, "INSERT INTO trainforge_v1.sources(id,name,urls) VALUES($1,'Synthetic isolated activity source','[]')", source)
	payload, err := json.Marshal(map[string]any{
		"fixtureOnly": true,
		"rights":      map[string]any{"operationGrants": map[string]string{"guided_practice": "allowed", "catalog_metadata": "allowed"}},
		"review": map[string]any{"state": "reviewed", "rightsVerified": true, "fidelityChecked": true,
			"instructionSufficient": true, "safetyUseReviewed": true},
	})
	if err != nil {
		t.Fatal("synthetic editorial payload")
	}
	for _, item := range []struct{ id, kind, title, version string }{
		{f.program, "program", "Synthetic SQL programme", strings.Repeat("a", 64)},
		{f.movement, "movement", "Synthetic repetition movement", strings.Repeat("b", 64)},
		{f.duration, "movement", "Synthetic timed movement", strings.Repeat("c", 64)},
	} {
		f.exec(t, `INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,payload,allowed_operations)
		 VALUES($1,$2,$3,$4,$5,$6,ARRAY['catalog_metadata','instruction_text','guided_practice'])`, item.id, item.version, item.kind, source, item.title, payload)
	}
	f.exec(t, `INSERT INTO trainforge_v1.program_sessions(program_id,program_sha,session_key,source_metadata)
	 VALUES($1,repeat('a',64),'sql-fixture','{"title":"Synthetic fixture session"}')`, f.program)
	for _, item := range []struct {
		position int
		id, sha  string
		dose     any
	}{
		{0, f.movement, strings.Repeat("b", 64), map[string]any{"contract": PrescriptionContract, "mode": "repetitions", "targets": []Target{{Repetitions: integer(10)}, {Repetitions: integer(10)}}}},
		{1, f.duration, strings.Repeat("c", 64), map[string]any{"contract": PrescriptionContract, "mode": "duration", "targets": []Target{{DurationMilliseconds: milliseconds(30000)}}}},
	} {
		dose, err := json.Marshal(item.dose)
		if err != nil {
			t.Fatal("synthetic dose encoding")
		}
		f.exec(t, `INSERT INTO trainforge_v1.program_items(program_id,program_sha,session_key,position,movement_id,movement_sha,source_dose)
		 VALUES($1,repeat('a',64),'sql-fixture',$2,$3,$4,$5)`, f.program, item.position, item.id, item.sha, dose)
	}
	f.enrollmentA, f.enrollmentB = activitySQLID(t), activitySQLID(t)
	for _, entry := range []struct{ id, owner string }{{f.enrollmentA, f.a.User.ID}, {f.enrollmentB, f.b.User.ID}} {
		f.exec(t, `INSERT INTO trainforge_v1.enrollments(id,user_id,program_id,program_sha,status)
		 VALUES($1,$2,$3,repeat('a',64),'active')`, entry.id, entry.owner, f.program)
	}
	f.occurrenceA = f.occurrence(t, f.a.User.ID, f.enrollmentA, 0)
	f.occurrenceB = f.occurrence(t, f.b.User.ID, f.enrollmentB, 0)
	return f
}

func (f *activitySQLFixture) exec(t *testing.T, statement string, args ...any) {
	t.Helper()
	if _, err := f.writer.Exec(f.ctx, statement, args...); err != nil {
		t.Fatal("isolated activity SQL fixture", err)
	}
}

func (f *activitySQLFixture) occurrence(t *testing.T, owner, enrollment string, offset time.Duration) string {
	t.Helper()
	id := activitySQLID(t)
	f.exec(t, `INSERT INTO trainforge_v1.schedule_occurrences(id,user_id,enrollment_id,source_session_key,planned_for,timezone,program_id,program_sha)
	 VALUES($1,$2,$3,'sql-fixture',$4,'UTC',$5,repeat('a',64))`, id, owner, enrollment, f.clock.Add(offset), f.program)
	return id
}

func (f *activitySQLFixture) store() ActivityStore {
	return ActivityStore{Pool: f.runtime, Now: func() time.Time { return f.clock }}
}

func (f *activitySQLFixture) start(t *testing.T, actor auth.Principal, occurrence string) MutationResult {
	t.Helper()
	got, err := f.store().Start(f.ctx, actor, StartRequest{OccurrenceID: occurrence}, activitySQLID(t))
	if err != nil {
		t.Fatal("start isolated approved occurrence", err)
	}
	return got
}

func (f *activitySQLFixture) command(t *testing.T, actor auth.Principal, id string, input CommandInput) MutationResult {
	t.Helper()
	got, err := f.store().Command(f.ctx, actor, id, input, activitySQLID(t))
	if err != nil {
		t.Fatal("persist isolated command", err)
	}
	return got
}

func activitySQLCount(t *testing.T, f *activitySQLFixture, table, owner string) int {
	t.Helper()
	allowed := map[string]bool{"activity_sessions": true, "activity_events": true, "enrollments": true,
		"schedule_occurrences": true, "idempotency_records": true}
	if !allowed[table] {
		t.Fatal("unregistered test count target")
	}
	var count int
	if err := f.writer.QueryRow(f.ctx, "SELECT count(*) FROM trainforge_v1."+table+" WHERE user_id=$1", owner).Scan(&count); err != nil {
		t.Fatal("isolated owner count")
	}
	return count
}

func TestActivityPostgresLifecycle(t *testing.T) {
	f := newActivitySQLFixture(t)
	store := f.store()
	feed, err := store.Feed(f.ctx, f.a)
	if err != nil || len(feed.Upcoming) != 1 || len(feed.Sessions) != 0 || !feed.Complete ||
		feed.Upcoming[0].ID != f.occurrenceA || !feed.Upcoming[0].PracticeAvailable {
		t.Fatal("owner feed did not use the approved occurrence", err)
	}
	startKey := activitySQLID(t)
	started, err := store.Start(f.ctx, f.a, StartRequest{OccurrenceID: f.occurrenceA}, startKey)
	if err != nil || started.Replayed || started.Snapshot.Revision != 1 || started.Snapshot.State != Started ||
		started.Snapshot.OwnerID != f.a.User.ID || len(started.Snapshot.Sets) != 0 || len(started.MovementLabels) != 2 {
		t.Fatal("prescription was not saved without inventing execution", err)
	}
	id, originalStart := started.Snapshot.ID, started.Snapshot.StartedAt
	otherOwner, err := store.Start(f.ctx, f.b, StartRequest{OccurrenceID: f.occurrenceB}, startKey)
	if err != nil || otherOwner.Snapshot.ID == id || otherOwner.Snapshot.OwnerID != f.b.User.ID {
		t.Fatal("one account's command key blocked or leaked another account's session", err)
	}
	retry, err := store.Start(f.ctx, f.a, StartRequest{OccurrenceID: f.occurrenceA}, startKey)
	if err != nil || !retry.Replayed || retry.Snapshot.ID != id || activitySQLCount(t, f, "activity_sessions", f.a.User.ID) != 1 {
		t.Fatal("start retry duplicated a session", err)
	}
	otherOccurrence := f.occurrence(t, f.a.User.ID, f.enrollmentA, 3*time.Hour)
	if _, err := store.Start(f.ctx, f.a, StartRequest{OccurrenceID: otherOccurrence}, startKey); !errors.Is(err, ErrConflict) {
		t.Fatal("same owner reused the start key for another occurrence", err)
	}
	if _, err := store.Command(f.ctx, f.a, id, CommandInput{ExpectedRevision: 1, Action: "pause"}, startKey); !errors.Is(err, ErrConflict) {
		t.Fatal("same owner reused the start key for a different operation", err)
	}
	f.clock = f.clock.Add(time.Minute)
	recordKey := activitySQLID(t)
	zero := CommandInput{ExpectedRevision: 1, Action: "record_set", Set: &Set{Position: 0, Number: 1, Repetitions: integer(0), LoadKg: kilogram("0")}}
	recorded, err := store.Command(f.ctx, f.a, id, zero, recordKey)
	if err != nil || recorded.AppliedRevision != 2 || len(recorded.Snapshot.Sets) != 1 ||
		recorded.Snapshot.Sets[0].Set.Repetitions == nil || *recorded.Snapshot.Sets[0].Set.Repetitions != 0 ||
		*recorded.Snapshot.Items[0].Targets[0].Repetitions != 10 {
		t.Fatal("measured zero, unknown and target were conflated", err)
	}
	if _, err := store.Command(f.ctx, f.a, id, CommandInput{ExpectedRevision: 2, Action: "complete", Confirmed: true}, activitySQLID(t)); !errors.Is(err, ErrConflict) {
		t.Fatal("incomplete prescription was automatically completed", err)
	}
	f.clock = f.clock.Add(time.Minute)
	paused := f.command(t, f.a, id, CommandInput{ExpectedRevision: 2, Action: "pause"})
	if paused.Snapshot.State != Paused || paused.Snapshot.Revision != 3 {
		t.Fatal("pause persistence")
	}
	// A fresh repository instance has no in-memory aggregate or retry receipts.
	reloaded, err := f.store().Detail(f.ctx, f.a, id)
	if err != nil || !reflect.DeepEqual(reloaded.Snapshot, paused.Snapshot) {
		t.Fatal("paused aggregate could not be rehydrated", err)
	}
	f.clock = f.clock.Add(3 * time.Minute)
	f.command(t, f.a, id, CommandInput{ExpectedRevision: 3, Action: "resume"})
	f.clock = f.clock.Add(time.Minute)
	f.command(t, f.a, id, CommandInput{ExpectedRevision: 4, Action: "record_set", Set: &Set{Position: 0, Number: 2, Repetitions: integer(7)}})
	f.clock = f.clock.Add(time.Minute)
	f.command(t, f.a, id, CommandInput{ExpectedRevision: 5, Action: "record_set", Set: &Set{Position: 1, Number: 1, DurationMilliseconds: milliseconds(17000)}})
	f.clock = f.clock.Add(3 * time.Minute)
	completed := f.command(t, f.a, id, CommandInput{ExpectedRevision: 6, Action: "complete", Confirmed: true})
	if completed.Snapshot.State != Completed || completed.Snapshot.Revision != 7 ||
		completed.Snapshot.ActiveMilliseconds != 7*60*1000 || !completed.Snapshot.StartedAt.Equal(originalStart) ||
		*completed.Snapshot.Sets[2].Set.DurationMilliseconds != 17000 ||
		*completed.Snapshot.Items[1].Targets[0].DurationMilliseconds != 30000 {
		t.Fatal("completion lost the real timeline or actual duration")
	}
	oldReplay, err := f.store().Command(f.ctx, f.a, id, zero, recordKey)
	if err != nil || !oldReplay.Replayed || oldReplay.AppliedRevision != 2 || !reflect.DeepEqual(oldReplay.Snapshot, completed.Snapshot) {
		t.Fatal("late retry changed terminal state or the original applied revision", err)
	}
	changed := zero
	changed.Set = &Set{Position: 0, Number: 1, Repetitions: integer(1), LoadKg: kilogram("0")}
	if _, err := f.store().Command(f.ctx, f.a, id, changed, recordKey); !errors.Is(err, ErrConflict) {
		t.Fatal("same command key accepted a different meaning after completion", err)
	}
	f.exec(t, "UPDATE trainforge_v1.idempotency_records SET expires_at=clock_timestamp()-interval '1 day' WHERE user_id=$1", f.a.User.ID)
	if replay, err := f.store().Command(f.ctx, f.a, id, zero, recordKey); err != nil || !replay.Replayed || replay.Snapshot.Revision != 7 {
		t.Fatal("expired generic cache lost the durable event replay", err)
	}
	if replay, err := f.store().Start(f.ctx, f.a, StartRequest{OccurrenceID: f.occurrenceA}, startKey); err != nil || !replay.Replayed || replay.Snapshot.ID != id {
		t.Fatal("expired start retry recreated a session", err)
	}
	if _, err := f.store().Start(f.ctx, f.a, StartRequest{OccurrenceID: f.occurrenceA}, activitySQLID(t)); !errors.Is(err, ErrConflict) {
		t.Fatal("a new key recreated a terminated occurrence", err)
	}
	feed, err = f.store().Feed(f.ctx, f.a)
	if err != nil || len(feed.Upcoming) != 1 || feed.Upcoming[0].ID != otherOccurrence || len(feed.Sessions) != 1 || feed.Sessions[0].Snapshot.State != Completed {
		t.Fatal("history or upcoming feed resurrected the occurrence", err)
	}

	t.Run("concurrent starts serialize one occurrence", func(t *testing.T) {
		occurrence := f.occurrence(t, f.a.User.ID, f.enrollmentA, time.Hour)
		keys := []string{activitySQLID(t), activitySQLID(t)}
		start := make(chan struct{})
		results := make(chan error, 2)
		var wg sync.WaitGroup
		for _, key := range keys {
			wg.Add(1)
			go func(key string) {
				defer wg.Done()
				<-start
				_, err := f.store().Start(f.ctx, f.a, StartRequest{OccurrenceID: occurrence}, key)
				results <- err
			}(key)
		}
		close(start)
		wg.Wait()
		close(results)
		successes, conflicts := 0, 0
		for err := range results {
			if err == nil {
				successes++
			} else if errors.Is(err, ErrConflict) {
				conflicts++
			} else {
				t.Fatal("concurrent occurrence error", err)
			}
		}
		if successes != 1 || conflicts != 1 || activitySQLCount(t, f, "activity_sessions", f.a.User.ID) != 2 {
			t.Fatal("concurrent start was not atomic")
		}
	})
}

func TestActivityPostgresAuthorizationWithdrawalAndErasure(t *testing.T) {
	f := newActivitySQLFixture(t)
	store := f.store()
	started := f.start(t, f.a, f.occurrenceA)
	id := started.Snapshot.ID
	input := CommandInput{ExpectedRevision: 1, Action: "record_set", Set: &Set{Position: 0, Number: 1, Repetitions: integer(3)}}
	if _, err := store.Detail(f.ctx, f.b, id); !errors.Is(err, ErrMissing) {
		t.Fatal("another account read the session", err)
	}
	if _, err := store.Command(f.ctx, f.b, id, input, activitySQLID(t)); !errors.Is(err, ErrMissing) {
		t.Fatal("another account changed the session", err)
	}
	if _, err := store.Start(f.ctx, f.b, StartRequest{OccurrenceID: f.occurrenceA}, activitySQLID(t)); !errors.Is(err, ErrMissing) {
		t.Fatal("another account started the occurrence", err)
	}
	if feed, err := store.Feed(f.ctx, f.b); err != nil || len(feed.Sessions) != 0 || len(feed.Upcoming) != 1 || feed.Upcoming[0].ID != f.occurrenceB {
		t.Fatal("another account's records leaked through the feed", err)
	}
	assertDead := func(t *testing.T, actor auth.Principal) {
		t.Helper()
		operations := []struct {
			name string
			run  func() error
		}{
			{"feed", func() error { _, err := store.Feed(f.ctx, actor); return err }},
			{"detail", func() error { _, err := store.Detail(f.ctx, actor, id); return err }},
			{"start", func() error {
				_, err := store.Start(f.ctx, actor, StartRequest{OccurrenceID: f.occurrenceA}, activitySQLID(t))
				return err
			}},
			{"command", func() error { _, err := store.Command(f.ctx, actor, id, input, activitySQLID(t)); return err }},
		}
		for _, op := range operations {
			t.Run(op.name, func(t *testing.T) {
				if err := op.run(); !errors.Is(err, auth.ErrInvalid) {
					t.Fatal("stale or forged credential used the store", err)
				}
			})
		}
	}
	t.Run("forged principal hash is not authorization", func(t *testing.T) {
		forged := f.a
		forged.AccessHash = append([]byte(nil), f.a.AccessHash...)
		forged.AccessHash[0] ^= 1
		assertDead(t, forged)
	})
	t.Run("expired credential is rechecked inside every transaction", func(t *testing.T) {
		f.exec(t, "UPDATE trainforge_v1.access_tokens SET expires_at=clock_timestamp()-interval '1 second' WHERE token_hash=$1", f.a.AccessHash)
		assertDead(t, f.a)
		f.exec(t, "UPDATE trainforge_v1.access_tokens SET expires_at=clock_timestamp()+interval '10 minutes' WHERE token_hash=$1", f.a.AccessHash)
	})
	t.Run("catalog outage prevents practice but never traps a session", func(t *testing.T) {
		blocked := f.store()
		blocked.CatalogGuard = func(context.Context, pgx.Tx) error { return errors.New("synthetic catalogue outage") }
		if detail, err := blocked.Detail(f.ctx, f.a, id); err != nil || detail.PracticeAvailable {
			t.Fatal("catalog failure hid history or approved practice", err)
		}
		if _, err := blocked.Command(f.ctx, f.a, id, input, activitySQLID(t)); !errors.Is(err, ErrPracticeUnavailable) {
			t.Fatal("catalog outage accepted a practice command", err)
		}
		other := f.occurrence(t, f.a.User.ID, f.enrollmentA, 2*time.Hour)
		if _, err := blocked.Start(f.ctx, f.a, StartRequest{OccurrenceID: other}, activitySQLID(t)); !errors.Is(err, ErrPracticeUnavailable) {
			t.Fatal("catalog outage started an occurrence", err)
		}
	})
	f.exec(t, `INSERT INTO trainforge_v1.content_withdrawals(asset_id,version_sha,reason)
	 VALUES($1,repeat('b',64),'Synthetic withdrawal in disposable activity test')`, f.movement)
	if detail, err := store.Detail(f.ctx, f.a, id); err != nil || detail.PracticeAvailable || detail.Snapshot.Revision != 1 {
		t.Fatal("withdrawal erased history or left practice approved", err)
	}
	if _, err := store.Command(f.ctx, f.a, id, input, activitySQLID(t)); !errors.Is(err, ErrPracticeUnavailable) {
		t.Fatal("withdrawn movement accepted another set", err)
	}
	if _, err := store.Start(f.ctx, f.b, StartRequest{OccurrenceID: f.occurrenceB}, activitySQLID(t)); !errors.Is(err, ErrPracticeUnavailable) {
		t.Fatal("withdrawn movement started a new occurrence", err)
	}
	f.clock = f.clock.Add(time.Minute)
	f.command(t, f.a, id, CommandInput{ExpectedRevision: 1, Action: "pause"})
	if _, err := store.Command(f.ctx, f.a, id, CommandInput{ExpectedRevision: 2, Action: "resume"}, activitySQLID(t)); !errors.Is(err, ErrPracticeUnavailable) {
		t.Fatal("withdrawn movement resumed practice", err)
	}
	partial := f.command(t, f.a, id, CommandInput{ExpectedRevision: 2, Action: "partial", Confirmed: true})
	if partial.Snapshot.State != Partial || partial.Snapshot.Revision != 3 || partial.PracticeAvailable {
		t.Fatal("withdrawal trapped the actor instead of accepting explicit partial closure")
	}
	// Restore the synthetic catalogue only inside this disposable fixture so B has its own record.
	f.exec(t, "DELETE FROM trainforge_v1.content_withdrawals WHERE asset_id=$1 AND version_sha=repeat('b',64)", f.movement)
	other := f.start(t, f.b, f.occurrenceB)
	for _, section := range []string{"activitySessions", "activityEvents"} {
		page, err := (privacy.Postgres{Pool: f.runtime}).Export(f.ctx, f.a, privacy.ExportFilter{Section: section, Limit: 50})
		if err != nil || len(page.Items) == 0 {
			t.Fatal("activity was omitted from private export", section, err)
		}
	}
	priv := privacy.Service{Repository: privacy.Postgres{Pool: f.runtime}}
	intent, err := priv.Intent(f.ctx, f.a, privacy.Confirmation)
	if err != nil {
		t.Fatal("activity erasure intent", err)
	}
	if _, err := priv.Delete(f.ctx, f.a, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge}); err != nil {
		t.Fatal("activity private erasure", err)
	}
	for _, table := range []string{"activity_sessions", "activity_events", "schedule_occurrences", "enrollments", "idempotency_records"} {
		if activitySQLCount(t, f, table, f.a.User.ID) != 0 {
			t.Fatal("private activity survived account erasure", table)
		}
	}
	if detail, err := store.Detail(f.ctx, f.b, other.Snapshot.ID); err != nil || detail.Snapshot.ID != other.Snapshot.ID {
		t.Fatal("another owner's record was erased", err)
	}
	assertDead(t, f.a)
	f.exec(t, "UPDATE trainforge_v1.auth_families SET revoked_at=clock_timestamp() WHERE id=$1", f.b.FamilyID)
	if _, err := store.Detail(f.ctx, f.b, other.Snapshot.ID); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("revoked family still read private activity", err)
	}
	if _, err := store.Command(f.ctx, f.b, other.Snapshot.ID, input, activitySQLID(t)); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("revoked family still changed private activity", err)
	}
}

func TestActivityPostgresHTTPContractAndBoundaries(t *testing.T) {
	f := newActivitySQLFixture(t)
	handler := &Handler{Store: f.store(), Authorize: f.authentication.Authorize}
	mux := http.NewServeMux()
	handler.Register(mux)
	request := func(method, path, token, key, contentType, body string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(method, path, strings.NewReader(body))
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		if key != "" {
			req.Header.Set("Idempotency-Key", key)
		}
		if contentType != "" {
			req.Header.Set("Content-Type", contentType)
		}
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, req)
		return response
	}
	if got := request("GET", "/api/v1/me/activity", f.aSession.AccessToken, "", "", ""); got.Code != 200 || got.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("private activity feed contract")
	}
	if got := request("GET", "/api/v1/me/activity", "", "", "", ""); got.Code != 401 {
		t.Fatal("anonymous activity feed")
	}
	body := `{"occurrenceId":"` + f.occurrenceA + `"}`
	for _, tc := range []struct {
		name, body, key, contentType string
		status                       int
	}{
		{"missing key", body, "", "application/json", 400},
		{"bad key", body, "not-a-uuid", "application/json", 400},
		{"unknown owner", `{"occurrenceId":"` + f.occurrenceA + `","ownerId":"` + f.b.User.ID + `"}`, activitySQLID(t), "application/json", 400},
		{"duplicate field", `{"occurrenceId":"` + f.occurrenceA + `","occurrenceId":"` + f.occurrenceB + `"}`, activitySQLID(t), "application/json", 400},
		{"trailing value", body + `{}`, activitySQLID(t), "application/json", 400},
		{"wrong media type", body, activitySQLID(t), "text/plain", 415},
		{"oversized body", `{"occurrenceId":"` + strings.Repeat("x", 70*1024) + `"}`, activitySQLID(t), "application/json", 413},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := request("POST", "/api/v1/me/activity-sessions", f.aSession.AccessToken, tc.key, tc.contentType, tc.body); got.Code != tc.status {
				t.Fatal("invalid activity request boundary", got.Code, tc.status)
			}
		})
	}
	if got := request("POST", "/api/v1/me/activity-sessions", f.bSession.AccessToken, activitySQLID(t), "application/json", body); got.Code != 404 {
		t.Fatal("HTTP start crossed account ownership", got.Code)
	}
	key := activitySQLID(t)
	got := request("POST", "/api/v1/me/activity-sessions", f.aSession.AccessToken, key, "application/json", body)
	if got.Code != 201 {
		t.Fatal("HTTP occurrence start", got.Code)
	}
	var started MutationResult
	if err := json.Unmarshal(got.Body.Bytes(), &started); err != nil || started.Snapshot.ID == "" || started.Snapshot.State != Started ||
		got.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("HTTP start response did not expose a confirmed snapshot")
	}
	startRetry := request("POST", "/api/v1/me/activity-sessions", f.aSession.AccessToken, key, "application/json", body)
	var replayedStart MutationResult
	if startRetry.Code != 200 || json.Unmarshal(startRetry.Body.Bytes(), &replayedStart) != nil ||
		!replayedStart.Replayed || replayedStart.Snapshot.ID != started.Snapshot.ID {
		t.Fatal("HTTP start retry did not retain the confirmed identity", startRetry.Code)
	}
	path := "/api/v1/me/activity-sessions/" + started.Snapshot.ID
	if got := request("GET", path, f.bSession.AccessToken, "", "", ""); got.Code != 404 {
		t.Fatal("HTTP detail crossed account ownership", got.Code)
	}
	if got := request("POST", path+"/commands", f.bSession.AccessToken, activitySQLID(t), "application/json", `{"expectedRevision":1,"action":"pause","confirmed":false,"set":null}`); got.Code != 404 {
		t.Fatal("HTTP command crossed account ownership", got.Code)
	}
	get := request("GET", path, f.aSession.AccessToken, "", "", "")
	var detail Detail
	if get.Code != 200 || json.Unmarshal(get.Body.Bytes(), &detail) != nil || detail.Snapshot.ID != started.Snapshot.ID {
		t.Fatal("HTTP detail could not rehydrate the confirmed session")
	}
	f.clock = f.clock.Add(time.Minute)
	partialKey := activitySQLID(t)
	partialBody := `{"expectedRevision":1,"action":"partial","confirmed":true,"set":null}`
	partial := request("POST", path+"/commands", f.aSession.AccessToken, partialKey, "application/json", partialBody)
	var closed MutationResult
	if partial.Code != 200 || json.Unmarshal(partial.Body.Bytes(), &closed) != nil || closed.Snapshot.State != Partial || closed.Snapshot.Revision != 2 {
		t.Fatal("HTTP explicit partial closure", partial.Code)
	}
	retry := request("POST", path+"/commands", f.aSession.AccessToken, partialKey, "application/json", partialBody)
	var repeated MutationResult
	if retry.Code != 200 || json.Unmarshal(retry.Body.Bytes(), &repeated) != nil || !repeated.Replayed || repeated.Snapshot.Revision != 2 {
		t.Fatal("HTTP retry duplicated the partial closure", retry.Code)
	}
	if got := request("POST", path+"/commands", f.aSession.AccessToken, activitySQLID(t), "application/json", `{"expectedRevision":2,"action":"resume","confirmed":false,"set":null}`); got.Code != 409 {
		t.Fatal("HTTP terminal session resumed", got.Code)
	}
	if got := request("GET", "/api/v1/me/activity", f.aSession.AccessToken, "", "", ""); got.Code != 200 || !strings.Contains(got.Body.String(), `"partial"`) {
		t.Fatal("HTTP history omitted confirmed partial activity")
	}
}
