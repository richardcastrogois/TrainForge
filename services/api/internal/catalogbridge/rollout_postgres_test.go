package catalogbridge_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"syscall"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/catalog"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/catalogbridge"
	"trainforge.local/api/internal/catalogtarget"
	"trainforge.local/api/internal/trainingconfig"
)

type fixtureVerifier struct{ subject string }

func (v fixtureVerifier) Verify(context.Context, string) (auth.Identity, error) {
	return auth.Identity{Issuer: "https://accounts.google.com", Subject: v.subject, Name: "Synthetic M3 fixture", Email: "fixture@example.invalid"}, nil
}
func TestCatalogRolloutSQL(t *testing.T) {
	if os.Getenv("TF_CATALOG_ROLLOUT_CI") == "" {
		t.Skip("explicit disposable rollout fixture not requested")
	}
	if runtime.GOOS != "linux" || os.Getenv("CI") != "true" || os.Getenv("GITHUB_ACTIONS") != "true" || os.Getenv("RUNNER_ENVIRONMENT") != "github-hosted" {
		t.Fatal("hosted fixture required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 70*time.Second)
	defer cancel()
	catConfig, e := catalogtarget.Config(os.Getenv("TF_ROLLOUT_CATALOG_WRITER"), catalogtarget.MigratorRole)
	if e != nil {
		t.Fatal("unsafe catalog target")
	}
	cat, e := pgxpool.NewWithConfig(ctx, catConfig)
	if e != nil {
		t.Fatal("catalog unavailable")
	}
	defer cat.Close()
	openCore := func(raw, role string) *pgxpool.Pool {
		t.Helper()
		c, e := pgxpool.ParseConfig(raw)
		if e != nil || c.ConnConfig.User != role || c.ConnConfig.Host != "127.0.0.1" || c.ConnConfig.Port != 15432 || !strings.HasPrefix(c.ConnConfig.Database, "trainforge_v1_config_test_") {
			t.Fatal("unsafe core target")
		}
		c.MaxConns = 4
		p, e := pgxpool.NewWithConfig(ctx, c)
		if e != nil {
			t.Fatal("core unavailable")
		}
		return p
	}
	core := openCore(os.Getenv("TF_ROLLOUT_CORE_WRITER"), "trainforge_migrator")
	defer core.Close()
	app := openCore(os.Getenv("TF_ROLLOUT_CORE_RUNTIME"), "trainforge_runtime")
	defer app.Close()
	sql := func(q string, args ...any) {
		t.Helper()
		if _, e := core.Exec(ctx, q, args...); e != nil {
			t.Fatal("core fixture SQL failed")
		}
	}
	privateHash := func() string {
		t.Helper()
		rows, e := core.Query(ctx, `SELECT tablename FROM pg_tables WHERE schemaname='trainforge_v1' AND tablename NOT IN('sources','content_versions','content_withdrawals') ORDER BY tablename`)
		if e != nil {
			t.Fatal("private inventory")
		}
		var names []string
		for rows.Next() {
			var name string
			if rows.Scan(&name) != nil {
				t.Fatal("private table")
			}
			names = append(names, name)
		}
		rows.Close()
		h := sha256.New()
		for _, name := range names {
			var raw []byte
			if core.QueryRow(ctx, `SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY to_jsonb(v)::text),'[]'::jsonb) FROM trainforge_v1.`+name+` v`).Scan(&raw) != nil {
				t.Fatal("private comparison")
			}
			h.Write([]byte(name))
			h.Write(raw)
		}
		return hex.EncodeToString(h.Sum(nil))
	}
	start := func() func() {
		t.Helper()
		cmd := exec.CommandContext(ctx, os.Getenv("TF_CATALOG_M1_BINARY"))
		cmd.Env = append(os.Environ(), "TF_CATALOG_DATABASE_URL="+os.Getenv("TF_ROLLOUT_CATALOG_READER"), "TF_CATALOG_LISTEN_ADDR=127.0.0.1:18083")
		cmd.Stdout = io.Discard
		cmd.Stderr = io.Discard
		if cmd.Start() != nil {
			t.Fatal("source process start")
		}
		done := make(chan error, 1)
		go func() { done <- cmd.Wait() }()
		stopped := false
		stop := func() {
			if !stopped {
				stopped = true
				_ = cmd.Process.Signal(syscall.SIGTERM)
				select {
				case e := <-done:
					if e != nil {
						t.Error("source shutdown")
					}
				case <-time.After(5 * time.Second):
					_ = cmd.Process.Kill()
					<-done
					t.Error("source shutdown timeout")
				}
			}
		}
		t.Cleanup(stop)
		client := &http.Client{Timeout: time.Second}
		for i := 0; i < 80; i++ {
			r, e := client.Get("http://127.0.0.1:18083/api/v1/health/ready")
			if e == nil {
				r.Body.Close()
				if r.StatusCode == 200 {
					return stop
				}
			}
			time.Sleep(25 * time.Millisecond)
		}
		t.Fatal("source not ready")
		return stop
	}
	actor := func() auth.Principal {
		t.Helper()
		var p auth.Principal
		if core.QueryRow(ctx, `SELECT u.id::text,f.id::text,a.token_hash FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.subject='m3-owner-a' ORDER BY a.created_at DESC LIMIT 1`).Scan(&p.User.ID, &p.FamilyID, &p.AccessHash) != nil {
			t.Fatal("fixture principal")
		}
		return p
	}
	bridge, e := catalogbridge.New("http://127.0.0.1:18083")
	if e != nil {
		t.Fatal(e)
	}
	store := trainingconfig.Postgres{Pool: app, CatalogGuard: bridge.CheckProjection}
	command := trainingconfig.SaveCommand{Reviewed: true, Configuration: trainingconfig.Configuration{Environments: []string{"home"}, Context: "personal", Timezone: "UTC", Availability: []trainingconfig.Availability{{Weekday: 1, MinutesAvailable: 20}}, Resources: trainingconfig.Resources{Status: "declared", Items: []trainingconfig.ResourceRef{{SourceID: "m3-source", EquipmentID: 7}}}}}
	switch os.Getenv("TF_ROLLOUT_PHASE") {
	case "prepare":
		sql(`INSERT INTO trainforge_v1.sources(id,name,urls,created_at) VALUES('m3-source','Synthetic M3 movement source','[]','2000-01-01T00:00:00Z'),('m3-food-source','Synthetic M3 food-only source','[]','2000-01-01T00:00:00Z')`)
		sql(`INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,allowed_operations,payload,created_at) VALUES('m3:movement',repeat('a',64),'movement','m3-source','Synthetic reference',ARRAY['catalog_metadata'],'{"review":{"state":"reviewed","rightsVerified":true,"fidelityChecked":true},"rights":{"operationGrants":{"catalog_metadata":"allowed"}},"content":{"equipment":[{"id":7,"name":"Synthetic M3 equipment"}]}}','2000-01-01T00:00:00Z')`)
		sql(`INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,name_original,nutrients,provenance) VALUES('m3-food',repeat('b',64),'m3-food-source','Synthetic public food fixture','[]','{}')`)
		snapshot, digest, e := catalogauthority.Read(ctx, core)
		if e != nil || len(snapshot.Sources) != 1 {
			t.Fatal("food source entered editorial migration")
		}
		if _, e = catalogauthority.Publish(ctx, cat, catalogauthority.Command{Snapshot: snapshot, PackageDigest: digest}); e != nil {
			t.Fatal("initial transfer")
		}
		for _, subject := range []string{"m3-owner-a", "m3-owner-b"} {
			a := auth.Service{Verifier: fixtureVerifier{subject}, Repository: auth.Postgres{Pool: app}}
			if _, e = a.Login(ctx, "synthetic-not-google"); e != nil {
				t.Fatal("synthetic account")
			}
		}
		stop := start()
		defer stop()
		p := actor()
		before := privateHash()
		resources, e := store.Resources(ctx, p, trainingconfig.ResourceFilter{Limit: 20})
		if e != nil || len(resources) != 1 {
			t.Fatal("047 mirror not accepted")
		}
		if privateHash() != before {
			t.Fatal("resource read changed private rows")
		}
		saved, e := (trainingconfig.Service{Repository: store}).Save(ctx, p, command, "44444444-4444-4444-8444-444444444444")
		if e != nil || saved.Revision != 1 {
			t.Fatal("guarded 047 save")
		}
		// The real HTTP bridge must preserve the same source metadata, including encoded IDs.
		mux := http.NewServeMux()
		bridge.Register(mux)
		result := httptest.NewRecorder()
		mux.ServeHTTP(result, httptest.NewRequest("GET", "/api/v1/catalog/movements/m3%3Amovement", nil))
		if result.Code != 200 || !strings.Contains(result.Body.String(), "Synthetic reference") {
			t.Fatal("real bridge contract")
		}
	case "withdraw":
		p := actor()
		before := privateHash()
		old, e := catalogauthority.Current(ctx, cat)
		if e != nil {
			t.Fatal(e)
		}
		snapshot, _, e := catalogauthority.Read(ctx, cat)
		if e != nil {
			t.Fatal(e)
		}
		snapshot.Withdrawals = append(snapshot.Withdrawals, map[string]any{"asset_id": "m3:movement", "version_sha": strings.Repeat("a", 64), "reason": "Synthetic M3 withdrawal", "withdrawn_at": "2001-01-01T00:00:00+00:00"})
		raw, _ := catalogauthority.Canonical(snapshot)
		head, e := catalogauthority.Publish(ctx, cat, catalogauthority.Command{ExpectedRevision: old.Revision, ExpectedDigest: old.Digest, PackageDigest: catalogauthority.Hash(raw), Snapshot: snapshot})
		if e != nil || head.Revision != 2 {
			t.Fatal("authoritative withdrawal")
		}
		stop := start()
		if _, e = store.Resources(ctx, p, trainingconfig.ResourceFilter{Limit: 20}); !errors.Is(e, trainingconfig.ErrUnavailable) {
			t.Fatal("stale mirror accepted")
		}
		command.Revision = 1
		if _, e = store.Save(ctx, p, command, "55555555-5555-4555-8555-555555555555"); !errors.Is(e, trainingconfig.ErrUnavailable) {
			t.Fatal("stale write accepted")
		}
		snapshot, digest, e := catalogauthority.Read(ctx, cat)
		if e != nil {
			t.Fatal(e)
		}
		tx, e := core.Begin(ctx)
		if e != nil {
			t.Fatal(e)
		}
		if catalogauthority.ApplyProjection(ctx, tx, snapshot, digest) != nil {
			t.Fatal("projection stage")
		}
		tx.Rollback(ctx)
		if _, e = store.Resources(ctx, p, trainingconfig.ResourceFilter{Limit: 20}); !errors.Is(e, trainingconfig.ErrUnavailable) {
			t.Fatal("rolled back mirror published")
		}
		tx, e = core.Begin(ctx)
		if e != nil {
			t.Fatal(e)
		}
		if catalogauthority.ApplyProjection(ctx, tx, snapshot, digest) != nil || tx.Commit(ctx) != nil {
			t.Fatal("mirror catch-up")
		}
		resources, e := store.Resources(ctx, p, trainingconfig.ResourceFilter{Limit: 20})
		if e != nil || len(resources) != 0 {
			t.Fatal("withdrawn resource revived")
		}

		local := catalog.CatalogHandler{Reader: catalog.Reader{Repository: catalog.CatalogPostgres{Pool: app}}}
		rollbackMux := http.NewServeMux()
		bridge.LocalVerified(app, local.Register)(rollbackMux)
		response := httptest.NewRecorder()
		rollbackMux.ServeHTTP(response, httptest.NewRequest("GET", "/api/v1/catalog/movements/m3%3Amovement", nil))
		if response.Code != 404 {
			t.Fatal("verified rollback revived withdrawn content")
		}
		stop()
		response = httptest.NewRecorder()
		rollbackMux.ServeHTTP(response, httptest.NewRequest("GET", "/api/v1/catalog/movements", nil))
		if response.Code != 503 {
			t.Fatal("rollback hid authority outage")
		}
		if _, e = store.Resources(ctx, p, trainingconfig.ResourceFilter{Limit: 20}); !errors.Is(e, trainingconfig.ErrUnavailable) {
			t.Fatal("network failure used stale data")
		}
		if privateHash() != before {
			t.Fatal("publication/mirror/failure changed private records")
		}
		if _, e = (auth.Postgres{Pool: app}).Authenticate(ctx, p.AccessHash); e != nil {
			t.Fatal("catalog failure destroyed session")
		}
	case "restore":
		before := privateHash()
		targetConfig, e := catalogtarget.Config(os.Getenv("TF_ROLLOUT_RESTORE_WRITER"), catalogtarget.MigratorRole)
		if e != nil || targetConfig.ConnConfig.Database == catConfig.ConnConfig.Database {
			t.Fatal("unsafe restore target")
		}
		target, e := pgxpool.NewWithConfig(ctx, targetConfig)
		if e != nil {
			t.Fatal(e)
		}
		defer target.Close()
		old, e := catalogauthority.Current(ctx, target)
		if e != nil || old.Revision != 1 {
			t.Fatal("old backup not restored")
		}
		current, e := catalogauthority.Current(ctx, cat)
		if e != nil || current.Revision != 2 {
			t.Fatal("latest authority missing")
		}
		snapshot, digest, e := catalogauthority.Read(ctx, cat)
		if e != nil {
			t.Fatal(e)
		}
		if _, e = catalogauthority.Publish(ctx, target, catalogauthority.Command{ExpectedRevision: old.Revision, ExpectedDigest: old.Digest, PackageDigest: digest, Snapshot: snapshot}); e != nil {
			t.Fatal("restore catch-up gate")
		}
		if _, e = catalogauthority.Publish(ctx, target, catalogauthority.Command{ExpectedRevision: old.Revision, ExpectedDigest: old.Digest, PackageDigest: digest, Snapshot: snapshot}); e != nil {
			t.Fatal("restore gate replay")
		}
		got, e := catalogauthority.Current(ctx, target)
		if e != nil || got != current {
			t.Fatal("restored authority differs")
		}
		_, mirror, e := catalogauthority.Read(ctx, core)
		if e != nil || mirror != digest || privateHash() != before {
			t.Fatal("restore/mirror/private mismatch")
		}
	default:
		t.Fatal("explicit phase required")
	}
}
