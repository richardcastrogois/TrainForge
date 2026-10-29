package httpapi

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestRequestDiagnosticsContainOnlyBoundedMetadata(t *testing.T) {
	for _, tc := range []struct {
		method, path, route string
		status              int
	}{
		{"POST", "/private/private-id-fixture?token=private-query", "POST /private/{id}", 201},
		{"GET", "/missing-private-id?token=private-query", "/", 404},
		{"PRIVATE_METHOD", "/missing-private-id", "/", 404},
		{"GET", "/api/v1/health/ready", "GET /api/v1/health/ready", 503},
	} {
		t.Run(tc.method+tc.route, func(t *testing.T) {
			var logs bytes.Buffer
			handler := New(nil, slog.New(slog.NewJSONHandler(&logs, nil)), time.Second, nil, func(mux *http.ServeMux) {
				mux.HandleFunc("POST /private/{id}", func(w http.ResponseWriter, r *http.Request) {
					if _, ok := w.(http.Flusher); !ok {
						t.Fatal("response writer capability lost")
					}
					JSON(w, 201, Status{Status: "created"})
				})
			})
			request := httptest.NewRequest(tc.method, tc.path, strings.NewReader("private-body"))
			request.Header.Set("Authorization", "Bearer private-credential")
			request.Header.Set("Cookie", "private-cookie")
			request.Header.Set("X-Request-Id", "private-injected-id")
			response := httptest.NewRecorder()
			handler.ServeHTTP(response, request)
			if response.Code != tc.status {
				t.Fatalf("unexpected status %d", response.Code)
			}
			var event map[string]any
			if json.Unmarshal(logs.Bytes(), &event) != nil {
				t.Fatal("one structured event required")
			}
			wantMethod := tc.method
			if tc.method == "PRIVATE_METHOD" {
				wantMethod = "OTHER"
			}
			if event["method"] != wantMethod || event["route"] != tc.route || event["status"] != float64(tc.status) || event["responseBytes"] != float64(response.Body.Len()) || event["requestId"] != response.Header().Get("X-Request-Id") {
				t.Fatal("diagnostic contract mismatch")
			}
			if elapsed, ok := event["durationMs"].(float64); !ok || elapsed < 0 {
				t.Fatal("duration missing")
			}
			allowed := map[string]bool{"time": true, "level": true, "msg": true,
				"requestId": true, "method": true, "route": true, "status": true,
				"durationMs": true, "responseBytes": true}
			for key := range event {
				if !allowed[key] {
					t.Fatal("unexpected diagnostic field")
				}
			}
			for _, private := range []string{"private-id-fixture", "private-query", "private-body", "private-credential", "private-cookie", "private-injected-id", "missing-private-id", "PRIVATE_METHOD"} {
				if strings.Contains(logs.String(), private) {
					t.Fatal("private value leaked")
				}
			}
		})
	}
}

func TestPanicDiagnosticStaysCorrelatedAndRedacted(t *testing.T) {
	var logs bytes.Buffer
	handler := New(testDB{panicNow: true}, slog.New(slog.NewJSONHandler(&logs, nil)), time.Second, nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, httptest.NewRequest("GET", "/api/v1/health/ready", nil))
	if response.Code != 500 || strings.Contains(logs.String(), "fixture secret") {
		t.Fatal("panic containment changed")
	}
	decoder := json.NewDecoder(&logs)
	for _, message := range []string{"request_failed", "http_request"} {
		var event map[string]any
		if decoder.Decode(&event) != nil || event["msg"] != message || event["requestId"] != response.Header().Get("X-Request-Id") {
			t.Fatal("correlation missing")
		}
		if message == "http_request" && event["status"] != float64(500) {
			t.Fatal("wrong observed status")
		}
	}
}
