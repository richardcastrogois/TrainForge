package trainingconfig

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/privacy"
)

type databaseFixtureVerifier struct{ subject string }

func (v databaseFixtureVerifier) Verify(context.Context, string) (auth.Identity, error) {
	return auth.Identity{Issuer: "https://accounts.google.com", Subject: v.subject, Name: "Isolated configuration fixture", Email: "fixture@example.invalid"}, nil
}
func TestConfigurationPostgresLifecycle(t *testing.T) {
	dsn := os.Getenv("TF_CONFIGURATION_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("disposable configuration DB not requested")
	}
	cfg, e := pgxpool.ParseConfig(dsn)
	if e != nil || cfg.ConnConfig.Host != "127.0.0.1" || cfg.ConnConfig.Port != 15432 || !strings.HasPrefix(cfg.ConnConfig.Database, "trainforge_v1_config_test_") {
		t.Fatal("unsafe test target")
	}
	rc, e := pgxpool.ParseConfig(os.Getenv("TF_CONFIGURATION_TEST_RUNTIME_URL"))
	if e != nil || rc.ConnConfig.Database != cfg.ConnConfig.Database || rc.ConnConfig.Host != cfg.ConnConfig.Host || rc.ConnConfig.Port != cfg.ConnConfig.Port || rc.ConnConfig.User != "trainforge_runtime" {
		t.Fatal("unsafe runtime target")
	}
	rc.MaxConns = 4
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	writer, e := pgxpool.NewWithConfig(ctx, cfg)
	if e != nil {
		t.Fatal(e)
	}
	defer writer.Close()
	runtime, e := pgxpool.NewWithConfig(ctx, rc)
	if e != nil {
		t.Fatal(e)
	}
	defer runtime.Close()
	login := func(subject string) (auth.Service, auth.Session, auth.Principal) {
		s := auth.Service{Verifier: databaseFixtureVerifier{subject}, Repository: auth.Postgres{Pool: runtime}}
		session, e := s.Login(ctx, "isolated-fixture-not-google")
		if e != nil {
			t.Fatal("session fixture")
		}
		p, e := s.Authorize(ctx, session.AccessToken)
		if e != nil {
			t.Fatal("principal fixture")
		}
		return s, session, p
	}
	authentication, session, a := login("config-a")
	_, otherSession, b := login("config-b")
	store := Postgres{runtime}
	service := Service{store}
	if current, e := service.Load(ctx, a); e != nil || current != nil {
		t.Fatal("unconfigured profile invented")
	}
	payload := map[string]any{"rights": map[string]any{"operationGrants": map[string]string{"catalog_metadata": "allowed"}}, "review": map[string]any{"state": "reviewed", "rightsVerified": true, "fidelityChecked": true}, "content": map[string]any{"equipment": []any{map[string]any{"id": 7, "name": "Isolated resource"}}}}
	raw, _ := json.Marshal(payload)
	if _, e := writer.Exec(ctx, "INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('config-source','Fixture source','[]');"); e != nil {
		t.Fatal(e)
	}
	if _, e := writer.Exec(ctx, "INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,payload,allowed_operations) VALUES('config-resource',repeat('a',64),'movement','config-source',$1,ARRAY['catalog_metadata'])", raw); e != nil {
		t.Fatal(e)
	}
	resources, e := store.Resources(ctx, a, ResourceFilter{Limit: 20})
	if e != nil || len(resources) != 1 || resources[0].EquipmentID != 7 {
		t.Fatal("real source resource projection", e)
	}
	resolved, e := store.ResolveResources(ctx, a, []ResourceRef{{"config-source", 7}, {"other-source", 7}})
	if e != nil || len(resolved) != 1 || resolved[0].Name != "Isolated resource" {
		t.Fatal("batch resource labels", e)
	}
	command := declared()
	command.Configuration.Resources = Resources{Status: "declared", Items: []ResourceRef{{"config-source", 7}}}
	saved, e := service.Save(ctx, a, command, fixtureKey)
	if e != nil || saved.Revision != 1 {
		t.Fatal("save configuration", e)
	}
	// Bypassing the service still cannot submit incomplete or unreviewed context.
	for _, mutate := range []func(map[string]any){
		func(doc map[string]any) { doc["reviewed"] = false },
		func(doc map[string]any) { doc["owner"] = "forged" },
		func(doc map[string]any) { doc["configuration"].(map[string]any)["height"] = 170 },
		func(doc map[string]any) { doc["configuration"].(map[string]any)["timezone"] = "Local" },
	} {
		encoded, _ := json.Marshal(command.Canonical())
		var doc map[string]any
		json.Unmarshal(encoded, &doc)
		mutate(doc)
		encoded, _ = json.Marshal(doc)
		_, err := runtime.Exec(ctx, "SELECT trainforge_v1.save_training_configuration($1,$2,$3,$4::jsonb,$5::uuid)", a.User.ID, a.FamilyID, a.AccessHash, encoded, "88888888-8888-4888-8888-888888888888")
		var pg *pgconn.PgError
		if !errors.As(err, &pg) || pg.Code != "TFQ01" {
			t.Fatal("direct SQL invalid declaration accepted")
		}
	}
	var before string
	if writer.QueryRow(ctx, "SELECT configuration::text FROM trainforge_v1.training_configuration_versions WHERE user_id=$1 AND revision=1", a.User.ID).Scan(&before) != nil {
		t.Fatal("stored version")
	}
	repeated, e := service.Save(ctx, a, command, fixtureKey)
	if e != nil || !repeated.ConfirmedAt.Equal(saved.ConfirmedAt) {
		t.Fatal("retry not stable")
	}
	changed := command
	changed.Configuration.Context = "personal"
	if _, e := service.Save(ctx, a, changed, fixtureKey); !errors.Is(e, ErrConflict) {
		t.Fatal("retry body conflict")
	}
	if current, e := service.Load(ctx, b); e != nil || current != nil {
		t.Fatal("cross owner current")
	}
	if _, e := runtime.Exec(ctx, "UPDATE trainforge_v1.training_configuration_versions SET revision=2 WHERE user_id=$1", a.User.ID); e == nil {
		t.Fatal("runtime updated immutable context")
	}
	if _, e := runtime.Exec(ctx, "DELETE FROM trainforge_v1.training_configuration_versions WHERE user_id=$1", a.User.ID); e == nil {
		t.Fatal("runtime directly deleted private context")
	}
	if _, e := runtime.Exec(ctx, "INSERT INTO trainforge_v1.training_configuration_versions(user_id,revision,configuration) SELECT $1,9,configuration FROM trainforge_v1.training_configuration_versions LIMIT 1", b.User.ID); e == nil {
		t.Fatal("runtime inserted foreign context")
	}
	if _, e := writer.Exec(ctx, "UPDATE trainforge_v1.training_configuration_versions SET configuration=configuration WHERE user_id=$1", a.User.ID); e == nil {
		t.Fatal("owner rewrote confirmed version")
	}
	next := command
	next.Revision = 1
	next.Configuration.Context = "personal"
	codes := make(chan error, 2)
	var wg sync.WaitGroup
	for _, key := range []string{"44444444-4444-4444-8444-444444444444", "55555555-5555-4555-8555-555555555555"} {
		wg.Add(1)
		go func(key string) { defer wg.Done(); _, e := service.Save(ctx, a, next, key); codes <- e }(key)
	}
	wg.Wait()
	close(codes)
	success, conflicts := 0, 0
	for e := range codes {
		if e == nil {
			success++
		} else if errors.Is(e, ErrConflict) {
			conflicts++
		} else {
			t.Fatal("concurrent error", e)
		}
	}
	if success != 1 || conflicts != 1 {
		t.Fatal("optimistic revision lost")
	}
	var after string
	writer.QueryRow(ctx, "SELECT configuration::text FROM trainforge_v1.training_configuration_versions WHERE user_id=$1 AND revision=1", a.User.ID).Scan(&after)
	if before != after {
		t.Fatal("history rewritten")
	}
	current, e := service.Load(ctx, a)
	if e != nil || current.Revision != 2 || current.Configuration.Context != "personal" {
		t.Fatal("latest context")
	}
	invalid := command
	invalid.Revision = 2
	invalid.Configuration.Resources.Items = []ResourceRef{{"other-source", 7}}
	if _, e := service.Save(ctx, a, invalid, "66666666-6666-4666-8666-666666666666"); e == nil {
		t.Fatal("resource crossed source")
	}
	if _, e := writer.Exec(ctx, "INSERT INTO trainforge_v1.content_withdrawals(asset_id,version_sha,reason) VALUES('config-resource',repeat('a',64),'isolated withdrawal')"); e != nil {
		t.Fatal(e)
	}
	if items, e := store.Resources(ctx, a, ResourceFilter{Limit: 20}); e != nil || len(items) != 0 {
		t.Fatal("withdrawn resource visible")
	}
	resolved, e = store.ResolveResources(ctx, a, []ResourceRef{{"config-source", 7}})
	if e != nil || len(resolved) != 0 {
		t.Fatal("withdrawn label projected", e)
	}
	if _, e := service.Save(ctx, a, next, "77777777-7777-4777-8777-777777777777"); e == nil {
		t.Fatal("stale revision/resource accepted")
	}
	if replay, e := service.Save(ctx, a, command, fixtureKey); e != nil || replay.Revision != 1 {
		t.Fatal("withdrawal changed prior idempotent response")
	}
	page, e := (privacy.Postgres{Pool: runtime}).Export(ctx, a, privacy.ExportFilter{Section: "trainingConfigurations", Limit: 1})
	if e != nil || len(page.Items) != 1 || page.NextCursor == nil {
		t.Fatal("configuration export pagination", e)
	}
	foreign, e := (privacy.Postgres{Pool: runtime}).Export(ctx, b, privacy.ExportFilter{Section: "trainingConfigurations", Limit: 50})
	if e != nil || len(foreign.Items) != 0 {
		t.Fatal("foreign configuration exported")
	}
	h := &Handler{Service: service, ResourceStore: store, Authorize: authentication.Authorize}
	mux := http.NewServeMux()
	h.Register(mux)
	request := func(token string) *httptest.ResponseRecorder {
		r := httptest.NewRequest("GET", "/api/v1/me/training-configuration", nil)
		r.Header.Set("Authorization", "Bearer "+token)
		out := httptest.NewRecorder()
		mux.ServeHTTP(out, r)
		return out
	}
	if out := request(session.AccessToken); out.Code != 200 || out.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("current HTTP")
	}
	out := request(session.AccessToken)
	var envelope Current
	if json.Unmarshal(out.Body.Bytes(), &envelope) != nil || envelope.Current == nil || len(envelope.UnavailableResources) != 1 || len(envelope.ResourceLabels) != 0 {
		t.Fatal("current withdrawal projection", out.Body.String())
	}
	if out := request(otherSession.AccessToken); out.Code != 200 || !strings.Contains(out.Body.String(), "null") {
		t.Fatal("foreign HTTP current")
	}
	// B saves its own unrelated context with no implied equipment.
	personal := declared()
	if _, e := service.Save(ctx, b, personal, fixtureKey); e != nil {
		t.Fatal("other own config", e)
	}
	priv := privacy.Service{Repository: privacy.Postgres{Pool: runtime}}
	intent, e := priv.Intent(ctx, a, privacy.Confirmation)
	if e != nil {
		t.Fatal("private intent", e)
	}
	if _, e := priv.Delete(ctx, a, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge}); e != nil {
		t.Fatal("private erasure", e)
	}
	if request(session.AccessToken).Code != 401 {
		t.Fatal("erased session still usable")
	}
	var count int
	writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.training_configuration_versions WHERE user_id=$1", a.User.ID).Scan(&count)
	if count != 0 {
		t.Fatal("erased configuration retained")
	}
	writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.training_configuration_versions WHERE user_id=$1", b.User.ID).Scan(&count)
	if count != 1 {
		t.Fatal("other config erased")
	}
	if _, e := writer.Exec(ctx, "UPDATE trainforge_v1.auth_families SET revoked_at=clock_timestamp() WHERE id=$1", b.FamilyID); e != nil {
		t.Fatal(e)
	}
	if _, e := store.Load(ctx, b); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("revoked credential read")
	}
	if _, e := store.Save(ctx, b, personal, fixtureKey); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("revoked retry")
	}
}
