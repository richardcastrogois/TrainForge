package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

type testDB struct {
	err      error
	panicNow bool
}

func (d testDB) Ping(ctx context.Context) error {
	if d.panicNow {
		panic("fixture secret")
	}
	return d.err
}
func TestRealHandlerStatusAndErrorContracts(t *testing.T) {
	for _, tc := range []struct {
		name, path string
		db         Readiness
		want       int
	}{
		{"live", "/api/v1/health/live", nil, 200}, {"missing db", "/api/v1/health/ready", nil, 503},
		{"failed db", "/api/v1/health/ready", testDB{err: errors.New("secret DSN")}, 503},
		{"ready dependency fixture", "/api/v1/health/ready", testDB{}, 200},
		{"panic containment", "/api/v1/health/ready", testDB{panicNow: true}, 500}, {"unknown", "/private-unknown", nil, 404},
	} {
		t.Run(tc.name, func(t *testing.T) {
			h := New(tc.db, slog.New(slog.NewJSONHandler(io.Discard, nil)), time.Second, nil)
			request := httptest.NewRequest(http.MethodGet, tc.path, nil)
			request.Header.Set("X-Request-Id", "injected-secret")
			response := httptest.NewRecorder()
			h.ServeHTTP(response, request)
			if response.Code != tc.want {
				t.Fatalf("status %d", response.Code)
			}
			if response.Header().Get("X-Request-Id") == "" || response.Header().Get("X-Request-Id") == "injected-secret" {
				t.Fatal("untrusted correlation")
			}
			if response.Header().Get("Cache-Control") != "no-store" || response.Header().Get("X-Content-Type-Options") != "nosniff" {
				t.Fatal("missing headers")
			}
			if strings.Contains(response.Body.String(), "secret") {
				t.Fatal("internal detail leaked")
			}
			if tc.want >= 400 {
				var p Problem
				if err := json.Unmarshal(response.Body.Bytes(), &p); err != nil || p.Status != tc.want || p.RequestID == "" {
					t.Fatal("problem contract mismatch")
				}
				if response.Header().Get("Content-Type") != "application/problem+json" {
					t.Fatal("wrong error media type")
				}
			}
		})
	}
}
