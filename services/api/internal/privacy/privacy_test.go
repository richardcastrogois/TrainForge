package privacy

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
)

func TestExportCursorCannotCrossAccountSectionOrLimit(t *testing.T) {
	f := ExportFilter{Section: "foods", Limit: 1}
	cursor := exportCursor("user-a", "private-food:version", f)
	q := url.Values{"section": {"foods"}, "limit": {"1"}, "cursor": {cursor}}
	if got, err := parseExport(q, "user-a"); err != nil || got.After == "" {
		t.Fatal("valid owned cursor")
	}
	if _, err := parseExport(q, "user-b"); !errors.Is(err, ErrQuery) {
		t.Fatal("cursor crossed account")
	}
	q.Set("section", "foodEntries")
	if _, err := parseExport(q, "user-a"); !errors.Is(err, ErrQuery) {
		t.Fatal("cursor crossed section")
	}
	for _, q := range []url.Values{{"userId": {"other"}}, {"limit": {"51"}}, {"section": {"tokens"}}, {"section": {"foods", "account"}}} {
		if _, err := parseExport(q, "user-a"); !errors.Is(err, ErrQuery) {
			t.Fatal("unsafe export query")
		}
	}
}

type stubPrivacy struct{ calls int }

func (s *stubPrivacy) Export(context.Context, auth.Principal, ExportFilter) (ExportPage, error) {
	s.calls++
	return ExportPage{Items: []json.RawMessage{}}, nil
}
func (s *stubPrivacy) Intent(context.Context, auth.Principal, []byte) (time.Time, error) {
	s.calls++
	return time.Now().Add(IntentTTL), nil
}
func (s *stubPrivacy) Delete(context.Context, auth.Principal, []byte) (Erased, error) {
	s.calls++
	return Erased{Deleted: true}, nil
}
func TestPrivacyHTTPAuthenticationConfirmationAndBodyLimits(t *testing.T) {
	repo := &stubPrivacy{}
	h := Handler{Service: Service{repo}, Authorize: func(ctx context.Context, token string) (auth.Principal, error) {
		if token != "fixture-only" {
			return auth.Principal{}, auth.ErrInvalid
		}
		return auth.Principal{User: auth.User{ID: "fixture-user"}}, nil
	}}
	mux := http.NewServeMux()
	h.Register(mux)
	call := func(method, path, body, token string) *httptest.ResponseRecorder {
		r := httptest.NewRequest(method, path, strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	for _, path := range []string{"/api/v1/me/export", "/api/v1/me/deletion-intent", "/api/v1/me"} {
		method := "GET"
		if strings.HasSuffix(path, "deletion-intent") {
			method = "POST"
		}
		if path == "/api/v1/me" {
			method = "DELETE"
		}
		if w := call(method, path, "{}", ""); w.Code != 401 || repo.calls != 0 {
			t.Fatal("anonymous private operation")
		}
	}
	if w := call("GET", "/api/v1/me/export?userId=other", "", "fixture-only"); w.Code != 400 {
		t.Fatal("client-supplied owner accepted")
	}
	if w := call("DELETE", "/api/v1/me", `{"confirmation":"yes","challenge":"bad"}`, "fixture-only"); w.Code != 400 || repo.calls != 0 {
		t.Fatal("unconfirmed deletion")
	}
	if w := call("DELETE", "/api/v1/me", strings.Repeat(" ", 9000), "fixture-only"); w.Code != 413 {
		t.Fatal("oversized private body")
	}
	if w := call("DELETE", "/api/v1/me", `{"confirmation":"EXCLUIR MINHA CONTA","challenge":"bad","userId":"other"}`, "fixture-only"); w.Code != 400 {
		t.Fatal("unknown owner field accepted")
	}
	if w := call("GET", "/api/v1/me/export", "", "fixture-only"); w.Code != 200 || w.Header().Get("Cache-Control") != "no-store" {
		t.Fatal("private export caching")
	}
}

type failedRow struct{ err error }

func (r failedRow) Scan(...any) error { return r.err }

type failedTx struct{ pgx.Tx }

func (failedTx) QueryRow(context.Context, string, ...any) pgx.Row {
	return failedRow{context.DeadlineExceeded}
}
func TestPrivacyDatabaseTimeoutDoesNotInvalidateSession(t *testing.T) {
	if err := fresh(context.Background(), failedTx{}, auth.Principal{}); !errors.Is(err, ErrUnavailable) {
		t.Fatal("dependency failure treated as invalid session")
	}
}
