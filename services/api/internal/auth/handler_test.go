package auth

import (
	"bytes"
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/platform/httpapi"
)

type rejectedVerifier struct{ err error }

func (v rejectedVerifier) Verify(context.Context, string) (Identity, error) { return Identity{}, v.err }

type testRepository struct{ calls int }

func (r *testRepository) Login(context.Context, Identity, Credentials) (User, error) {
	r.calls++
	return User{}, errors.New("must not be reached")
}
func (*testRepository) Rotate(context.Context, []byte, Credentials) (User, error) {
	return User{}, ErrInvalid
}
func (*testRepository) Authenticate(context.Context, []byte) (User, error) { return User{}, ErrInvalid }
func (*testRepository) Revoke(context.Context, []byte) error               { return nil }
func TestHTTPRejectsUnsafeInputsWithoutLeakingOrCreatingUsers(t *testing.T) {
	for _, tc := range []struct {
		name, body, media, path string
		want                    int
	}{
		{"invalid google", `{"idToken":"secret-invalid"}`, "application/json", "/api/v1/auth/google", 401},
		{"unknown field", `{"idToken":"secret","userId":"attacker"}`, "application/json", "/api/v1/auth/google", 400},
		{"missing", `{}`, "application/json", "/api/v1/auth/google", 400},
		{"trailing", `{"idToken":"secret"} {}`, "application/json", "/api/v1/auth/google", 400},
		{"media", `{"idToken":"secret"}`, "text/plain", "/api/v1/auth/google", 415},
		{"large", `{"idToken":"` + strings.Repeat("s", 70000) + `"}`, "application/json", "/api/v1/auth/google", 413},
		{"bad refresh", `{"refreshToken":"secret"}`, "application/json", "/api/v1/auth/refresh", 401},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var logs bytes.Buffer
			repo := &testRepository{}
			h := &Handler{Service: Service{Verifier: rejectedVerifier{ErrInvalid}, Repository: repo}}
			server := httpapi.New(nil, slog.New(slog.NewTextHandler(&logs, nil)), time.Second, nil, h.Register)
			r := httptest.NewRequest("POST", tc.path, strings.NewReader(tc.body))
			r.Header.Set("Content-Type", tc.media)
			w := httptest.NewRecorder()
			server.ServeHTTP(w, r)
			if w.Code != tc.want {
				t.Fatalf("got %d want %d", w.Code, tc.want)
			}
			if repo.calls != 0 || strings.Contains(w.Body.String()+logs.String(), "secret") {
				t.Fatal("leak or unauthorized user creation")
			}
		})
	}
}
func TestUnavailableAndTransportAndRateLimit(t *testing.T) {
	h := &Handler{Service: Service{Verifier: rejectedVerifier{ErrUnavailable}, Repository: &testRepository{}}}
	server := httpapi.New(nil, slog.New(slog.NewTextHandler(io.Discard, nil)), time.Second, nil, h.Register)
	for n := 0; n < 11; n++ {
		r := httptest.NewRequest("POST", "/api/v1/auth/google", strings.NewReader(`{"idToken":"not-logged"}`))
		r.RemoteAddr = "127.0.0.1:1234"
		r.Header.Set("Content-Type", "application/json")
		r.Header.Set("X-Forwarded-For", strings.Repeat("x", n+1))
		w := httptest.NewRecorder()
		server.ServeHTTP(w, r)
		want := 503
		if n == 10 {
			want = 429
		}
		if w.Code != want {
			t.Fatalf("rate/network %d", w.Code)
		}
	}
	h.RequireTLS = true
	r := httptest.NewRequest("GET", "/api/v1/me", nil)
	r.Header.Set("X-Forwarded-Proto", "https")
	w := httptest.NewRecorder()
	server.ServeHTTP(w, r)
	if w.Code != 426 {
		t.Fatal("untrusted forwarded TLS accepted")
	}
}
