package postgres

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"log/slog"
	"net/http/httptest"
	"os"
	"regexp"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/platform/httpapi"
)

func TestMissingRuntimeReadinessIsUnavailable(t *testing.T) {
	if !errors.Is((Readiness{}).Ping(context.Background()), ErrNotReady) {
		t.Fatal("nil pool ready")
	}
}

func TestPostgresRuntimeReadiness(t *testing.T) {
	dsn := os.Getenv("TF_MEALS_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("disposable runtime readiness fixture not requested")
	}
	wc, e := pgx.ParseConfig(dsn)
	if e != nil || wc.Host != "127.0.0.1" || wc.Port != 15432 || wc.User != "trainforge_migrator" || !regexp.MustCompile(`^trainforge_v1_privacy_test_[a-f0-9]{12}$`).MatchString(wc.Database) {
		t.Fatal("unsafe writer target")
	}
	rc, e := pgx.ParseConfig(os.Getenv("TF_MEALS_TEST_RUNTIME_URL"))
	if e != nil || rc.Host != wc.Host || rc.Port != wc.Port || rc.Database != wc.Database || rc.User != "trainforge_runtime" {
		t.Fatal("unsafe runtime target")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	w, e := pgxpool.New(ctx, dsn)
	if e != nil {
		t.Fatal("writer pool")
	}
	defer w.Close()
	r, e := pgxpool.New(ctx, os.Getenv("TF_MEALS_TEST_RUNTIME_URL"))
	if e != nil {
		t.Fatal("runtime pool")
	}
	defer r.Close()
	ready := Readiness{Pool: r}
	h := httpapi.New(ready, slog.New(slog.NewTextHandler(io.Discard, nil)), time.Second, nil)
	check := func(tb *testing.T, want int) {
		tb.Helper()
		response := httptest.NewRecorder()
		h.ServeHTTP(response, httptest.NewRequest("GET", "/api/v1/health/ready", nil))
		if response.Code != want {
			tb.Fatalf("readiness status %d, want %d", response.Code, want)
		}
		if strings.Contains(response.Body.String(), "trainforge_") || strings.Contains(response.Body.String(), "permission") {
			tb.Fatal("internal schema detail leaked")
		}
	}
	check(t, 200)
	if (Readiness{Pool: w}).Ping(ctx) == nil {
		t.Fatal("migration credential accepted as runtime")
	}
	for _, tc := range []struct{ name, change, restore string }{
		{"missing read grant", "REVOKE SELECT ON trainforge_v1.meals FROM trainforge_runtime", "GRANT SELECT ON trainforge_v1.meals TO trainforge_runtime"},
		{"unexpected private write", "GRANT UPDATE ON trainforge_v1.meals TO trainforge_runtime", "REVOKE UPDATE ON trainforge_v1.meals FROM trainforge_runtime"},
		{"missing object", "ALTER TABLE trainforge_v1.meal_versions RENAME TO readiness_hidden_versions", "ALTER TABLE trainforge_v1.readiness_hidden_versions RENAME TO meal_versions"},
		{"missing function grant", "REVOKE EXECUTE ON FUNCTION trainforge_v1.delete_meal_group(uuid,uuid,bytea,uuid,integer) FROM trainforge_runtime", "GRANT EXECUTE ON FUNCTION trainforge_v1.delete_meal_group(uuid,uuid,bytea,uuid,integer) TO trainforge_runtime"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if _, e := w.Exec(ctx, tc.change); e != nil {
				t.Fatal("fixture change failed")
			}
			defer func() {
				if _, e := w.Exec(ctx, tc.restore); e != nil {
					t.Error("fixture restore failed")
				}
			}()
			check(t, 503)
		})
		check(t, 200)
	}
	canceled, stop := context.WithCancel(ctx)
	stop()
	if !errors.Is(ready.Ping(canceled), ErrNotReady) {
		t.Fatal("canceled probe accepted")
	}
}
