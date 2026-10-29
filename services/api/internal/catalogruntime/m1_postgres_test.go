package catalogruntime

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"reflect"
	"regexp"
	"runtime"
	"strings"
	"syscall"
	"testing"
	"time"
	"trainforge.local/api/internal/catalog"
	"trainforge.local/api/internal/catalogtarget"
	"trainforge.local/api/internal/platform/httpapi"
)

func TestIsolatedCatalogM1(t *testing.T) {
	writerURL, readerURL := os.Getenv("TF_CATALOG_M1_TEST_WRITER_URL"), os.Getenv("TF_CATALOG_M1_TEST_READER_URL")
	if writerURL == "" || readerURL == "" {
		t.Skip("explicit disposable M1 fixture not requested")
	}
	if runtime.GOOS != "linux" || os.Getenv("CI") != "true" || os.Getenv("GITHUB_ACTIONS") != "true" || os.Getenv("RUNNER_ENVIRONMENT") != "github-hosted" || os.Getenv("TF_CATALOG_M1_CI") != "1" {
		t.Fatal("explicit hosted M1 fixture required")
	}

	wc, err := catalogtarget.Config(writerURL, catalogtarget.MigratorRole)
	if err != nil {
		t.Fatal("unsafe writer fixture")
	}
	rc, err := catalogtarget.Config(readerURL, catalogtarget.ReaderRole)
	if err != nil || rc.ConnConfig.Database != wc.ConnConfig.Database {
		t.Fatal("unsafe reader fixture")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	wc.MaxConns = 2
	rc.MaxConns = 2
	writer, err := pgxpool.NewWithConfig(ctx, wc)
	if err != nil {
		t.Fatal("writer unavailable")
	}
	defer writer.Close()
	reader, err := pgxpool.NewWithConfig(ctx, rc)
	if err != nil {
		t.Fatal("reader unavailable")
	}
	defer reader.Close()
	sql := func(tb testing.TB, query string, args ...any) {
		tb.Helper()
		if _, err := writer.Exec(ctx, query, args...); err != nil {
			tb.Fatal("fixture SQL failed")
		}
	}
	sql(t, `INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('m1-source','Synthetic M1 source','["https://example.invalid/m1"]')`)
	insert := func(id, kind, version, title, at string, reviewed bool) {
		t.Helper()
		payload := map[string]any{"authors": []string{}, "rights": map[string]any{"operationGrants": map[string]string{"catalog_metadata": "allowed"}}, "review": map[string]any{"state": "reviewed", "rightsVerified": reviewed, "fidelityChecked": true}, "audience": map[string]any{"population": []string{"older adult"}, "environment": []string{"home"}}, "content": map[string]any{"equipment": []any{map[string]any{"id": 7, "name": "Synthetic resource"}}, "category": map[string]any{"id": 1, "name": "Synthetic category"}, "modality": "walking", "instruction": "never-serve-fixture-instruction"}}
		raw, _ := json.Marshal(payload)
		sql(t, `INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,payload,allowed_operations,created_at) VALUES($1,$2,$3,'m1-source',$4,$5,ARRAY['catalog_metadata'],$6::timestamptz)`, id, strings.Repeat(version, 64), kind, title, raw, at)
	}
	insert("m1:movement:a", "movement", "a", "Synthetic movement A", "2000-01-01T00:00:00Z", true)
	insert("m1:movement:b", "movement", "b", "Synthetic movement B", "2000-01-01T00:00:00Z", true)
	insert("m1:movement:withdrawn", "movement", "c", "Synthetic versioned movement", "2000-01-01T00:00:00Z", true)
	insert("m1:movement:withdrawn", "movement", "d", "Synthetic versioned movement", "2001-01-01T00:00:00Z", true)
	insert("m1:movement:unreviewed", "movement", "e", "Synthetic unreviewed movement", "2000-01-01T00:00:00Z", true)
	insert("m1:movement:unreviewed", "movement", "f", "Synthetic unreviewed movement", "2001-01-01T00:00:00Z", false)
	insert("m1:program:a", "program", "1", "Synthetic program metadata only", "2000-01-01T00:00:00Z", true)
	insert("m1:collection:a", "collection", "2", "Synthetic collection metadata only", "2000-01-01T00:00:00Z", true)

	binary := os.Getenv("TF_CATALOG_M1_BINARY")
	if binary == "" {
		t.Fatal("independently built catalog binary required")
	}
	command := exec.CommandContext(ctx, binary)
	command.Env = append(os.Environ(), "TF_CATALOG_DATABASE_URL="+readerURL, "TF_CATALOG_LISTEN_ADDR=127.0.0.1:18083", "TF_CATALOG_REQUEST_TIMEOUT_SECONDS=1")
	command.Stdout = io.Discard
	command.Stderr = io.Discard
	if command.Start() != nil {
		t.Fatal("standalone process failed to start")
	}
	processDone := make(chan error, 1)
	go func() { processDone <- command.Wait() }()
	stopped := false
	t.Cleanup(func() {
		if !stopped {
			_ = command.Process.Kill()
			<-processDone
		}
	})
	client := &http.Client{Timeout: 5 * time.Second}
	const standalone = "http://127.0.0.1:18083"
	waitReady := func(tb testing.TB, want int) {
		tb.Helper()
		for i := 0; i < 50; i++ {
			resp, e := client.Get(standalone + "/api/v1/health/ready")
			if e == nil {
				io.Copy(io.Discard, resp.Body)
				resp.Body.Close()
				if resp.StatusCode == want {
					return
				}
			}
			time.Sleep(40 * time.Millisecond)
		}
		tb.Fatal("standalone readiness did not reach expected status")
	}
	waitReady(t, 200)
	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	legacyCatalog := catalog.CatalogHandler{Reader: catalog.Reader{Repository: catalog.CatalogPostgres{Pool: reader}}}
	legacy := httptest.NewServer(httpapi.New(nil, logger, time.Second, nil, legacyCatalog.Register))
	defer legacy.Close()
	request := func(tb testing.TB, base, path, tag string) (int, http.Header, []byte) {
		tb.Helper()
		r, e := http.NewRequestWithContext(ctx, "GET", base+path, nil)
		if e != nil {
			tb.Fatal("request setup")
		}
		r.Header.Set("Authorization", "Bearer synthetic-not-an-access-token")
		r.Header.Set("Cookie", "synthetic-cookie")
		if tag != "" {
			r.Header.Set("If-None-Match", tag)
		}
		resp, e := client.Do(r)
		if e != nil {
			tb.Fatal("fixture request failed")
		}
		defer resp.Body.Close()
		body, e := io.ReadAll(resp.Body)
		if e != nil {
			tb.Fatal("response read failed")
		}
		return resp.StatusCode, resp.Header, body
	}
	normalize := func(tb testing.TB, body []byte) any {
		tb.Helper()
		if len(body) == 0 {
			return nil
		}
		var value any
		if json.Unmarshal(body, &value) != nil {
			tb.Fatal("non-JSON response")
		}
		if obj, ok := value.(map[string]any); ok {
			delete(obj, "requestId")
		}
		return value
	}
	compare := func(tb testing.TB, path, tag string) {
		tb.Helper()
		a, ha, ba := request(tb, legacy.URL, path, tag)
		b, hb, bb := request(tb, standalone, path, tag)
		if a != b || !reflect.DeepEqual(normalize(tb, ba), normalize(tb, bb)) {
			tb.Fatal("public wire contract differs")
		}
		for _, key := range []string{"Content-Type", "Cache-Control", "ETag", "X-Content-Type-Options", "Allow"} {
			if ha.Get(key) != hb.Get(key) {
				tb.Fatal("public response header differs")
			}
		}
	}
	t.Run("five_routes_contract_and_versions", func(t *testing.T) {
		for _, path := range []string{"/api/v1/catalog/filters", "/api/v1/catalog/programs", "/api/v1/catalog/programs/m1:program:a", "/api/v1/catalog/programs/m1:collection:a", "/api/v1/catalog/movements", "/api/v1/catalog/movements/m1:movement:a", "/api/v1/catalog/movements?mode=practice", "/api/v1/catalog/movements?limit=1", "/api/v1/catalog/movements?q=Synthetic&environment=home&population=older%20adult&equipment=Synthetic%20resource&category=Synthetic%20category&modality=walking", "/api/v1/catalog/movements?limit=0", "/api/v1/catalog/movements?limit=1&limit=2", "/api/v1/catalog/movements?cursor=invalid", "/api/v1/catalog/movements?unexpected=x", "/api/v1/catalog/movements/missing", "/api/v1/catalog/movements/m1:movement:a?versionId=bad", "/api/v1/catalog/movements/m1:movement:unreviewed"} {
			compare(t, path, "")
		}
		code, _, body := request(t, standalone, "/api/v1/catalog/movements", "")
		var page catalog.CatalogPage
		if code != 200 || json.Unmarshal(body, &page) != nil || len(page.Items) != 3 {
			t.Fatal("authorized latest-version visibility changed")
		}
		for _, item := range page.Items {
			if item.Availability.Practice || item.Availability.Instruction || item.Availability.Media {
				t.Fatal("fixture metadata released practice")
			}
		}
		if bytes.Contains(body, []byte("never-serve-fixture-instruction")) {
			t.Fatal("unapproved payload escaped projection")
		}
		_, _, body = request(t, standalone, "/api/v1/catalog/movements?limit=1", "")
		if json.Unmarshal(body, &page) != nil || page.NextCursor == nil {
			t.Fatal("pagination cursor missing")
		}
		compare(t, "/api/v1/catalog/movements?limit=1&cursor="+url.QueryEscape(*page.NextCursor), "")
		compare(t, "/api/v1/catalog/movements?q=changed&limit=1&cursor="+url.QueryEscape(*page.NextCursor), "")
		_, headers, _ := request(t, standalone, "/api/v1/catalog/movements/m1:movement:a", "")
		compare(t, "/api/v1/catalog/movements/m1:movement:a", headers.Get("ETag"))
		status, _, _ := request(t, standalone, "/api/v1/catalog/movements/m1:movement:a", headers.Get("ETag"))
		if headers.Get("ETag") == "" || status != 304 {
			t.Fatal("conditional read not exercised")
		}
	})
	t.Run("reader_permissions_and_private_database_isolation", func(t *testing.T) {
		for _, query := range []string{`INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('forbidden','Fixture','[]')`, `UPDATE trainforge_v1.content_versions SET title=title WHERE false`, `DELETE FROM trainforge_v1.content_withdrawals WHERE false`, `TRUNCATE trainforge_v1.sources`, `CREATE TABLE public.forbidden(id int)`, `SELECT * FROM public.trainforge_catalog_schema_version`, `SET ROLE trainforge_catalog_migrator`} {
			_, err := reader.Exec(ctx, query)
			var pg *pgconn.PgError
			if !errors.As(err, &pg) || pg.Code != "42501" {
				t.Fatal("reader privilege boundary not enforced")
			}
		}
		privateURL := os.Getenv("TF_CATALOG_M1_PRIVATE_READER_URL")
		pc, e := pgxpool.ParseConfig(privateURL)
		if e != nil || pc.ConnConfig.Host != "127.0.0.1" || pc.ConnConfig.Port != 15432 || pc.ConnConfig.User != catalogtarget.ReaderRole || !regexp.MustCompile(`^trainforge_v1_private_test_[a-f0-9]{12}$`).MatchString(pc.ConnConfig.Database) {
			t.Fatal("unsafe private sentinel target")
		}
		private, e := pgxpool.NewWithConfig(ctx, pc)
		if e != nil {
			t.Fatal("sentinel connection setup")
		}
		defer private.Close()
		e = private.Ping(ctx)
		var pg *pgconn.PgError
		if !errors.As(e, &pg) || pg.Code != "42501" {
			t.Fatal("reader could connect to private sentinel or failure was not authorization")
		}
		for _, path := range []string{"/api/v1/me", "/api/v1/me/food-entries", "/api/v1/me/training-configuration", "/api/v1/auth/google", "/docs/index.html"} {
			code, _, _ := request(t, standalone, path, "")
			if code != 404 {
				t.Fatal("private or documentation route exposed")
			}
		}
	})
	t.Run("withdrawal_beats_cache_and_latest_has_no_fallback", func(t *testing.T) {
		path := "/api/v1/catalog/movements/m1:movement:withdrawn"
		_, headers, _ := request(t, standalone, path, "")
		sql(t, `INSERT INTO trainforge_v1.content_withdrawals(asset_id,version_sha,reason) VALUES('m1:movement:withdrawn',$1,'isolated M1 withdrawal')`, strings.Repeat("d", 64))
		compare(t, path, headers.Get("ETag"))
		code, _, _ := request(t, standalone, path, headers.Get("ETag"))
		if code != 404 {
			t.Fatal("withdrawn item returned cached304 or old version")
		}
		code, _, body := request(t, standalone, "/api/v1/catalog/movements", "")
		var page catalog.CatalogPage
		if code != 200 || json.Unmarshal(body, &page) != nil || len(page.Items) != 2 {
			t.Fatal("listing resurrected withdrawn or unreviewed version")
		}
		compare(t, path+"?versionId="+strings.Repeat("c", 64), "") // Explicit old-version lookup remains the existing public contract.
	})
	t.Run("readiness_negatives_and_recovery", func(t *testing.T) {
		sql(t, `REVOKE SELECT ON trainforge_v1.sources FROM trainforge_catalog_reader`)
		waitReady(t, 503)
		code, _, body := request(t, standalone, "/api/v1/catalog/movements", "")
		if code != 503 || bytes.Contains(body, []byte("permission")) {
			t.Fatal("DB permission failure leaked or changed status")
		}
		sql(t, `GRANT SELECT ON trainforge_v1.sources TO trainforge_catalog_reader`)
		waitReady(t, 200)
		sql(t, `GRANT INSERT ON trainforge_v1.content_versions TO trainforge_catalog_reader`)
		waitReady(t, 503)
		sql(t, `REVOKE INSERT ON trainforge_v1.content_versions FROM trainforge_catalog_reader`)
		waitReady(t, 200)
		sql(t, `ALTER TABLE trainforge_v1.content_withdrawals RENAME TO hidden_withdrawals`)
		waitReady(t, 503)
		sql(t, `ALTER TABLE trainforge_v1.hidden_withdrawals RENAME TO content_withdrawals`)
		waitReady(t, 200)
	})
	t.Run("query_deadline_and_client_cancellation", func(t *testing.T) {
		tx, e := writer.Begin(ctx)
		if e != nil {
			t.Fatal("lock transaction")
		}
		defer tx.Rollback(ctx)
		if _, e = tx.Exec(ctx, `LOCK TABLE trainforge_v1.content_versions IN ACCESS EXCLUSIVE MODE`); e != nil {
			t.Fatal("fixture lock")
		}
		start := time.Now()
		code, _, _ := request(t, standalone, "/api/v1/catalog/movements", "")
		if code != 503 || time.Since(start) > 4*time.Second {
			t.Fatal("query deadline not honored")
		}
		local := httptest.NewServer(Handler(reader, logger, 3*time.Second))
		defer local.Close()
		callCtx, stop := context.WithCancel(ctx)
		defer stop()
		r, _ := http.NewRequestWithContext(callCtx, "GET", local.URL+"/api/v1/catalog/movements", nil)
		ended := make(chan error, 1)
		go func() {
			resp, e := client.Do(r)
			if resp != nil {
				resp.Body.Close()
			}
			ended <- e
		}()
		for i := 0; i < 50 && reader.Stat().AcquiredConns() == 0; i++ {
			time.Sleep(20 * time.Millisecond)
		}
		if reader.Stat().AcquiredConns() == 0 {
			t.Fatal("blocked read never acquired connection")
		}
		stop()
		if e := <-ended; !errors.Is(e, context.Canceled) {
			t.Fatal("caller cancellation not propagated")
		}
		for i := 0; i < 50 && reader.Stat().AcquiredConns() != 0; i++ {
			time.Sleep(20 * time.Millisecond)
		}
		if reader.Stat().AcquiredConns() != 0 {
			t.Fatal("canceled query retained pool connection")
		}
		if tx.Rollback(ctx) != nil {
			t.Fatal("fixture unlock")
		}
		waitReady(t, 200)
	})
	if err := command.Process.Signal(syscall.SIGTERM); err != nil {
		t.Fatal("SIGTERM failed")
	}
	select {
	case err := <-processDone:
		stopped = true
		if err != nil {
			t.Fatal("standalone process did not exit gracefully")
		}
	case <-time.After(5 * time.Second):
		t.Fatal("standalone shutdown timed out")
	}
}
