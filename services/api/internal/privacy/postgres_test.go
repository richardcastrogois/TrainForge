package privacy

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/trainingconfig"
)

type fixtureVerifier struct{ subject string }

func (v fixtureVerifier) Verify(context.Context, string) (auth.Identity, error) {
	return auth.Identity{Issuer: "https://accounts.google.com", Subject: v.subject, Name: "Isolated privacy fixture", Email: "fixture@example.invalid"}, nil
}
func privacyPools(t *testing.T) (context.Context, *pgxpool.Pool, *pgxpool.Pool) {
	t.Helper()
	dsn := os.Getenv("TF_PRIVACY_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("disposable privacy database not requested; not Google login")
	}
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || !strings.HasPrefix(cfg.Database, "trainforge_v1_privacy_test_") {
		t.Fatal("unsafe fixture database")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	t.Cleanup(cancel)
	writer, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal("fixture writer")
	}
	t.Cleanup(writer.Close)
	runDSN := os.Getenv("TF_PRIVACY_TEST_RUNTIME_URL")
	runtimeCfg, err := pgx.ParseConfig(runDSN)
	if err != nil || runtimeCfg.Database != cfg.Database || runtimeCfg.Host != cfg.Host || runtimeCfg.Port != cfg.Port {
		t.Fatal("unsafe fixture runtime")
	}
	runtime, err := pgxpool.New(ctx, runDSN)
	if err != nil {
		t.Fatal("fixture runtime")
	}
	t.Cleanup(runtime.Close)
	return ctx, writer, runtime
}
func fixtureLogin(t *testing.T, ctx context.Context, pool *pgxpool.Pool, subject string) (auth.Service, auth.Session, auth.Principal) {
	t.Helper()
	service := auth.Service{Repository: auth.Postgres{Pool: pool}, Verifier: fixtureVerifier{subject}}
	session, err := service.Login(ctx, "isolated-fixture-not-a-google-token")
	if err != nil {
		t.Fatalf("fixture login: %v", err)
	}
	p, err := service.Authorize(ctx, session.AccessToken)
	if err != nil {
		t.Fatal("fixture authorization")
	}
	return service, session, p
}
func execFixture(t *testing.T, ctx context.Context, pool *pgxpool.Pool, query string, args ...any) {
	t.Helper()
	if _, err := pool.Exec(ctx, query, args...); err != nil {
		t.Fatalf("fixture SQL %v", err)
	}
}
func fixtureConfiguration() trainingconfig.Configuration {
	return trainingconfig.Configuration{Environments: []string{"home"}, Context: "personal", Timezone: "UTC", Resources: trainingconfig.Resources{Status: "unknown", Items: []trainingconfig.ResourceRef{}}, Availability: []trainingconfig.Availability{{Weekday: 1, MinutesAvailable: 7}}}
}
func seedConfiguration(t *testing.T, ctx context.Context, w *pgxpool.Pool, user string) {
	t.Helper()
	var present bool
	if w.QueryRow(ctx, "SELECT to_regclass('trainforge_v1.training_configuration_versions') IS NOT NULL").Scan(&present) != nil {
		t.Fatal("configuration schema check")
	}
	if !present {
		return
	}
	raw, _ := json.Marshal(fixtureConfiguration())
	execFixture(t, ctx, w, "INSERT INTO trainforge_v1.training_configuration_versions(user_id,revision,configuration) VALUES($1,1,$2)", user, raw)
}
func seedOwned(t *testing.T, ctx context.Context, w *pgxpool.Pool, user, id, food string) {
	t.Helper()
	seedConfiguration(t, ctx, w, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.enrollments(id,user_id,program_id,program_sha,status) VALUES($1,$2,'fixture-program',repeat('a',64),'active')`, id, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.schedule_occurrences(id,user_id,enrollment_id,source_session_key,planned_for,timezone,program_id,program_sha)
 VALUES($1,$2,$1,'fixture-session',now(),'UTC','fixture-program',repeat('a',64))`, id, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.activity_sessions(id,occurrence_id,user_id,state,started_at) VALUES($1,$1,$2,'started',now())`, id, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.activity_events(id,session_id,user_id,event_type,occurred_at,payload) VALUES($1,$1,$2,'fixture-event',now(),'{}')`, id, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,owner_id,name_original,nutrients,provenance)
 VALUES($1,repeat('a',64),$2,'Private fixture '||$1,'[]','{}')`, food, user)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation)
 VALUES($1,$2,$3,repeat('a',64),12.34,'g',now(),'UTC','{}')`, id, user, food)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,response_body,expires_at)
 VALUES($1,'fixture',decode(repeat('a',64),'hex'),decode(repeat('b',64),'hex'),201,'{}',now()+interval '1 day')`, user)
}
func TestPrivacyPostgresOwnerExportConfirmedDeletionAndRollback(t *testing.T) {
	ctx, writer, runtime := privacyPools(t)
	aService, aSession, a := fixtureLogin(t, ctx, runtime, "privacy-fixture-a")
	_, bSession, b := fixtureLogin(t, ctx, runtime, "privacy-fixture-b")
	_, aSecond, aOtherFamily := fixtureLogin(t, ctx, runtime, "privacy-fixture-a")
	repo := Postgres{runtime}
	service := Service{repo}
	execFixture(t, ctx, writer, `INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('fixture-source','Isolated fixture','[]');
 INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,payload)
 VALUES('fixture-program',repeat('a',64),'program','fixture-source','{}');
 INSERT INTO trainforge_v1.program_sessions(program_id,program_sha,session_key) VALUES('fixture-program',repeat('a',64),'fixture-session');
 INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,name_original,nutrients,provenance)
 VALUES('fixture-editorial',repeat('a',64),'fixture-source','Editorial fixture','[]','{}');`)
	seedOwned(t, ctx, writer, a.User.ID, "10000000-0000-4000-8000-000000000001", "private-fixture-a")
	seedOwned(t, ctx, writer, b.User.ID, "20000000-0000-4000-8000-000000000001", "private-fixture-b")
	// Database-level ownership protects even future consumption handlers.
	_, err := runtime.Exec(ctx, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation)
 VALUES('30000000-0000-4000-8000-000000000001',$1,'private-fixture-b',repeat('a',64),1,'g',now(),'UTC','{}')`, a.User.ID)
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23514" {
		t.Fatal("foreign private food reference accepted")
	}
	for name := range sections {
		page, err := repo.Export(ctx, a, ExportFilter{Section: name, Limit: 50})
		if err != nil {
			t.Fatalf("export section %s: %v", name, err)
		}
		body, _ := json.Marshal(page)
		for _, forbidden := range []string{b.User.ID, bSession.AccessToken, aSession.AccessToken, aSecond.RefreshToken, "token_hash", "private-fixture-b"} {
			if strings.Contains(string(body), forbidden) {
				t.Fatalf("foreign/internal export in %s", name)
			}
		}
		if len(page.Items) > 0 {
			var item map[string]any
			if json.Unmarshal(page.Items[0], &item) != nil {
				t.Fatal("invalid export JSON")
			}
			for _, field := range map[string][]string{
				"enrollments": {"programKind", "programId", "programVersion"},
				"occurrences": {"programId", "programVersion", "sourceSessionKey"},
				"foods":       {"sourceId", "sourceFoodId", "sourceRowKey", "sourcePublishedVersion", "nameLocale", "allowedOperations", "nutrients"},
			}[name] {
				if _, ok := item[field]; !ok {
					t.Fatalf("export omitted %s/%s", name, field)
				}
			}
		}
		if name == "foods" && (len(page.Items) != 1 || strings.Contains(string(body), "fixture-editorial")) {
			t.Fatal("editorial food bulk-exported")
		}
	}
	page, err := repo.Export(ctx, a, ExportFilter{Section: "sessions", Limit: 1})
	if err != nil || len(page.Items) != 1 || page.NextCursor == nil {
		t.Fatal("session pagination")
	}
	q := url.Values{"section": {"sessions"}, "limit": {"1"}, "cursor": {*page.NextCursor}}
	next, err := parseExport(q, a.User.ID)
	if err != nil {
		t.Fatal("owned cursor")
	}
	second, err := repo.Export(ctx, a, next)
	if err != nil || len(second.Items) != 1 || string(second.Items[0]) == string(page.Items[0]) {
		t.Fatal("repeated session page")
	}
	intent, err := service.Intent(ctx, a, Confirmation)
	if err != nil {
		t.Fatalf("intent: %v", err)
	}
	if _, err = service.Delete(ctx, b, DeleteRequest{Confirmation, intent.Challenge}); !errors.Is(err, ErrConfirmation) {
		t.Fatal("intent crossed account")
	}
	if _, err = service.Delete(ctx, aOtherFamily, DeleteRequest{Confirmation, intent.Challenge}); !errors.Is(err, ErrConfirmation) {
		t.Fatal("intent crossed device family")
	}
	digest, _ := parseChallenge(intent.Challenge)
	execFixture(t, ctx, writer, "UPDATE trainforge_v1.account_deletion_intents SET expires_at=now()-interval '1 second' WHERE token_hash=$1", digest)
	if _, err = service.Delete(ctx, a, DeleteRequest{Confirmation, intent.Challenge}); !errors.Is(err, ErrConfirmation) {
		t.Fatal("expired intent")
	}
	execFixture(t, ctx, writer, "UPDATE trainforge_v1.auth_families SET created_at=now()-interval '16 minutes' WHERE id=$1", a.FamilyID)
	if _, err = service.Intent(ctx, a, Confirmation); !errors.Is(err, ErrReauthenticate) {
		t.Fatal("old Google session accepted for deletion")
	}
	execFixture(t, ctx, writer, "UPDATE trainforge_v1.auth_families SET created_at=now() WHERE id=$1", a.FamilyID)
	intent, err = service.Intent(ctx, a, Confirmation)
	if err != nil {
		t.Fatal("fresh intent")
	}
	// A new, unregistered private store blocks export and deletion instead of omitting it.
	execFixture(t, ctx, writer, "CREATE TABLE trainforge_v1.future_private(id uuid PRIMARY KEY,customer_id uuid REFERENCES trainforge_v1.users(id))")
	if _, err = repo.Export(ctx, a, ExportFilter{Section: "account", Limit: 20}); !errors.Is(err, ErrUnavailable) {
		t.Fatal("new private store silently omitted")
	}
	if _, err = service.Delete(ctx, a, DeleteRequest{Confirmation, intent.Challenge}); !errors.Is(err, ErrUnavailable) {
		t.Fatal("unknown private store deletion succeeded")
	}
	execFixture(t, ctx, writer, "DROP TABLE trainforge_v1.future_private")
	// Force a late SQL failure. Every earlier deletion and the erasure ledger must roll back.
	execFixture(t, ctx, writer, `CREATE FUNCTION trainforge_v1.fixture_block_user_delete() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RAISE EXCEPTION 'isolated failure';END;$$;
 CREATE TRIGGER fixture_delete_failure BEFORE DELETE ON trainforge_v1.users FOR EACH ROW EXECUTE FUNCTION trainforge_v1.fixture_block_user_delete();`)
	if _, err = service.Delete(ctx, a, DeleteRequest{Confirmation, intent.Challenge}); !errors.Is(err, ErrUnavailable) {
		t.Fatal("late failure not surfaced")
	}
	var count int
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_entries WHERE user_id=$1", a.User.ID).Scan(&count) != nil || count != 1 {
		t.Fatal("partial erasure committed")
	}
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.account_erasures WHERE user_id=$1", a.User.ID).Scan(&count) != nil || count != 0 {
		t.Fatal("failed erasure ledger committed")
	}
	execFixture(t, ctx, writer, "DROP TRIGGER fixture_delete_failure ON trainforge_v1.users;DROP FUNCTION trainforge_v1.fixture_block_user_delete()")
	// Runtime has no blanket DELETE/UPDATE permission on editorial foods or ledger reads.
	for _, query := range []string{"DELETE FROM trainforge_v1.food_versions WHERE food_id='fixture-editorial'", "SELECT user_id FROM trainforge_v1.account_erasures"} {
		_, err = runtime.Exec(ctx, query)
		if !errors.As(err, &pgErr) || pgErr.Code != "42501" {
			t.Fatal("runtime editorial/ledger privilege widened")
		}
	}
	erased, err := service.Delete(ctx, a, DeleteRequest{Confirmation, intent.Challenge})
	if err != nil || !erased.Deleted {
		t.Fatalf("confirmed deletion: %v", err)
	}
	if _, err = aService.Authorize(ctx, aSession.AccessToken); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("deleted account access active")
	}
	if _, err = aService.Authorize(ctx, aSecond.AccessToken); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("other device of deleted account active")
	}
	if _, err = aService.Refresh(ctx, aSession.RefreshToken); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("deleted refresh active")
	}
	if _, err = aService.Authorize(ctx, bSession.AccessToken); err != nil {
		t.Fatal("other account revoked")
	}
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_entries WHERE user_id=$1", b.User.ID).Scan(&count) != nil || count != 1 {
		t.Fatal("other account data erased")
	}
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_versions WHERE food_id='fixture-editorial'").Scan(&count) != nil || count != 1 {
		t.Fatal("editorial food erased")
	}
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.account_erasures WHERE user_id=$1", a.User.ID).Scan(&count) != nil || count != 1 {
		t.Fatal("restore ledger missing")
	}
	for table, owner := range map[string]string{"training_configuration_versions": "user_id", "users": "id", "auth_families": "user_id", "enrollments": "user_id", "schedule_occurrences": "user_id", "activity_sessions": "user_id", "activity_events": "user_id", "food_entries": "user_id", "food_versions": "owner_id", "idempotency_records": "user_id", "account_deletion_intents": "user_id"} {
		if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1."+table+" WHERE "+owner+"=$1", a.User.ID).Scan(&count) != nil || count != 0 {
			t.Fatalf("owned rows survived in %s", table)
		}
	}
}

func TestPrivacyRestorePrepareFixture(t *testing.T) {
	if os.Getenv("TF_PRIVACY_RESTORE_PHASE") != "prepare" {
		t.Skip("explicit restore phase not requested")
	}
	ctx, w, runtime := privacyPools(t)
	_, _, a := fixtureLogin(t, ctx, runtime, "privacy-restore-a")
	_, _, b := fixtureLogin(t, ctx, runtime, "privacy-restore-b")
	seedConfiguration(t, ctx, w, a.User.ID)
	seedConfiguration(t, ctx, w, b.User.ID)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,owner_id,name_original,nutrients,provenance)
 VALUES('restore-private-a',repeat('a',64),$1,'Restore fixture A','[]','{}'),
 ('restore-private-b',repeat('a',64),$2,'Restore fixture B','[]','{}')`, a.User.ID, b.User.ID)
	var mealsPresent bool
	if w.QueryRow(ctx, "SELECT to_regclass('trainforge_v1.meals') IS NOT NULL").Scan(&mealsPresent) != nil {
		t.Fatal("meal schema check")
	}
	if mealsPresent {
		for i, owner := range []string{a.User.ID, b.User.ID} {
			id := fmt.Sprintf("40000000-0000-4000-8000-%012d", i)
			food := []string{"restore-private-a", "restore-private-b"}[i]
			execFixture(t, ctx, w, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation)
 VALUES($1,$2,$3,repeat('a',64),1,'g',now(),'UTC','{}')`, id, owner, food)
			execFixture(t, ctx, w, `INSERT INTO trainforge_v1.meals(id,user_id,title,occurred_at,timezone,revision) VALUES($1,$2,'Restore meal fixture',now(),'UTC',1)`, id, owner)
			execFixture(t, ctx, w, `INSERT INTO trainforge_v1.meal_items(entry_id,user_id,meal_id,position) VALUES($1,$2,$1,0)`, id, owner)
			execFixture(t, ctx, w, `INSERT INTO trainforge_v1.meal_versions(meal_id,user_id,revision,title,occurred_at,timezone,entry_ids,deleted) VALUES($1,$2,1,'Restore meal fixture',now(),'UTC',ARRAY[$1::uuid],false)`, id, owner)
		}
	}
}
func TestPrivacyRestoreEraseFixture(t *testing.T) {
	if os.Getenv("TF_PRIVACY_RESTORE_PHASE") != "erase" {
		t.Skip("explicit restore phase not requested")
	}
	ctx, _, runtime := privacyPools(t)
	_, _, a := fixtureLogin(t, ctx, runtime, "privacy-restore-a")
	service := Service{Postgres{runtime}}
	intent, err := service.Intent(ctx, a, Confirmation)
	if err != nil {
		t.Fatal("restore fixture intent")
	}
	if _, err = service.Delete(ctx, a, DeleteRequest{Confirmation, intent.Challenge}); err != nil {
		t.Fatal("restore fixture erase")
	}
}

func TestPrivacyDeleteRefreshConcurrencyRevokesWinner(t *testing.T) {
	ctx, _, runtime := privacyPools(t)
	authService, session, p := fixtureLogin(t, ctx, runtime, "privacy-concurrency")
	service := Service{Postgres{runtime}}
	intent, err := service.Intent(ctx, p, Confirmation)
	if err != nil {
		t.Fatal("concurrent fixture intent")
	}
	type refreshResult struct {
		s   auth.Session
		err error
	}
	refreshed := make(chan refreshResult, 1)
	deleted := make(chan error, 1)
	start := make(chan struct{})
	go func() {
		<-start
		s, err := authService.Refresh(ctx, session.RefreshToken)
		refreshed <- refreshResult{s, err}
	}()
	go func() {
		<-start
		_, err := service.Delete(ctx, p, DeleteRequest{Confirmation, intent.Challenge})
		deleted <- err
	}()
	close(start)
	if err := <-deleted; err != nil {
		t.Fatalf("concurrent deletion: %v", err)
	}
	result := <-refreshed
	if result.err != nil && !errors.Is(result.err, auth.ErrInvalid) {
		t.Fatal("concurrent refresh unexpected error")
	}
	if result.err == nil {
		if _, err = authService.Authorize(ctx, result.s.AccessToken); !errors.Is(err, auth.ErrInvalid) {
			t.Fatal("refresh winner survived account deletion")
		}
	}
}

func TestPrivacyMaintenancePreservesActiveReplayDetection(t *testing.T) {
	ctx, w, runtime := privacyPools(t)
	authService, active, a := fixtureLogin(t, ctx, runtime, "maintenance-active")
	_, _, old := fixtureLogin(t, ctx, runtime, "maintenance-closed")
	execFixture(t, ctx, w, "UPDATE trainforge_v1.auth_families SET created_at=now()-interval '40 days' WHERE id=ANY($1::uuid[])", []string{a.FamilyID, old.FamilyID})
	execFixture(t, ctx, w, "UPDATE trainforge_v1.refresh_tokens SET consumed_at=now()-interval '1 hour' WHERE family_id=$1", a.FamilyID)
	execFixture(t, ctx, w, "UPDATE trainforge_v1.refresh_tokens SET expires_at=now()-interval '2 days' WHERE family_id=$1", old.FamilyID)
	execFixture(t, ctx, w, "UPDATE trainforge_v1.access_tokens SET expires_at=now()-interval '2 days' WHERE family_id=$1", old.FamilyID)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.account_deletion_intents(token_hash,user_id,family_id,expires_at)
 VALUES(decode(repeat('c',64),'hex'),$1,$2,now()-interval '1 hour')`, old.User.ID, old.FamilyID)
	execFixture(t, ctx, w, `INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,expires_at)
 VALUES($1,'expired-fixture',decode(repeat('c',64),'hex'),decode(repeat('d',64),'hex'),201,now()-interval '1 day')`, old.User.ID)
	preview, err := Maintain(ctx, w, false)
	if err != nil || preview.ClosedFamilies < 1 || preview.ExpiredIntents < 1 || preview.Applied {
		t.Fatalf("maintenance preview: %v", err)
	}
	var count int
	if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.auth_families WHERE id=$1", old.FamilyID).Scan(&count) != nil || count != 1 {
		t.Fatal("preview changed data")
	}
	applied, err := Maintain(ctx, w, true)
	if err != nil || !applied.Applied || applied.ClosedFamilies < 1 {
		t.Fatalf("maintenance apply: %v", err)
	}
	if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.auth_families WHERE id=$1", old.FamilyID).Scan(&count) != nil || count != 0 {
		t.Fatal("closed family retained")
	}
	if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.users WHERE id=$1", old.User.ID).Scan(&count) != nil || count != 1 {
		t.Fatal("maintenance erased account")
	}
	if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.refresh_tokens WHERE family_id=$1", a.FamilyID).Scan(&count) != nil || count != 1 {
		t.Fatal("active consumed hash removed")
	}
	if _, err = authService.Refresh(ctx, active.RefreshToken); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("consumed refresh accepted")
	}
	if _, err = authService.Authorize(ctx, active.AccessToken); !errors.Is(err, auth.ErrInvalid) {
		t.Fatal("maintenance broke family replay revocation")
	}
}
