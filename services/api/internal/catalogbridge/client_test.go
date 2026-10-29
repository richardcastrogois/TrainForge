package catalogbridge

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/catalogauthority"
)

func TestEndpointCannotSelectExternalHostOrCredentials(t *testing.T) {
	for _, url := range []string{"https://evil.invalid", "http://localhost:18083", "http://127.0.0.1:8082", "http://user:password@127.0.0.1:18083", "http://127.0.0.1:18083/", "http://127.0.0.1:18083?target=x"} {
		if _, e := New(url); e == nil {
			t.Fatal("unsafe endpoint accepted")
		}
	}
	if _, e := New("http://127.0.0.1:18083"); e != nil {
		t.Fatal(e)
	}
}
func TestForwardDropsPrivateHeadersPreservesEncodedQueryAndConditionalCache(t *testing.T) {
	for _, status := range []int{200, 304} {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			for _, header := range []string{"Authorization", "Cookie", "X-TrainForge-Account", "X-Forwarded-For", "X-Request-Id", "Idempotency-Key"} {
				if r.Header.Get(header) != "" {
					t.Error("private/header propagated")
				}
			}
			if r.URL.RawQuery != "q=a%20b" || r.URL.Path != "/api/v1/catalog/movements/fixture:one" || r.Header.Get("If-None-Match") != "fixture-etag" {
				t.Error("public request changed")
			}
			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("ETag", "fixture-etag")
			w.Header().Set("Cache-Control", "private, no-cache")
			w.Header().Set("Set-Cookie", "must-not-propagate")
			w.WriteHeader(status)
			if status == 200 {
				w.Write([]byte(`{"items":[]}`))
			}
		}))
		c := &Client{base: server.URL, http: server.Client()}
		request := httptest.NewRequest("GET", "/api/v1/catalog/movements/fixture%3Aone?q=a%20b", nil)
		for _, h := range []string{"Authorization", "Cookie", "X-TrainForge-Account", "X-Request-Id", "Idempotency-Key"} {
			request.Header.Set(h, "private-must-not-leave-api")
		}
		request.Header.Set("If-None-Match", "fixture-etag")
		result := httptest.NewRecorder()
		c.Forward(result, request)
		if result.Code != status || result.Header().Get("ETag") != "fixture-etag" || result.Header().Get("Set-Cookie") != "" {
			t.Fatal("response contract changed")
		}
		server.Close()
	}
}
func TestFailuresNeverExposeRemoteBodiesAndDoNotFallback(t *testing.T) {
	for _, tc := range []struct {
		status     int
		body, kind string
	}{{200, "private-invalid-json", "text/plain"}, {302, "redirect", "application/json"}, {500, `{"secret":"must-not-propagate"}`, "application/json"}, {200, strings.Repeat("x", (2<<20)+1), "application/json"}, {400, `{"code":"unexpected_remote_detail"}`, "application/problem+json"}} {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", tc.kind)
			w.WriteHeader(tc.status)
			w.Write([]byte(tc.body))
		}))
		c := &Client{base: server.URL, http: server.Client()}
		result := httptest.NewRecorder()
		c.Forward(result, httptest.NewRequest("GET", "/api/v1/catalog/programs", nil))
		if result.Code != 503 || strings.Contains(result.Body.String(), "must-not-propagate") {
			t.Fatal("unsafe remote failure")
		}
		server.Close()
	}
}
func TestRevisionTimeoutCancellationAndContract(t *testing.T) {
	h := catalogauthority.Head{Contract: catalogauthority.Contract, Revision: 1, Digest: strings.Repeat("a", 64), PackageDigest: strings.Repeat("a", 64)}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/internal/catalog/revision" {
			t.Error("wrong revision route")
		}
		json.NewEncoder(w).Encode(h)
	}))
	defer server.Close()
	c := &Client{base: server.URL, http: server.Client()}
	if got, e := c.Head(context.Background()); e != nil || got != h {
		t.Fatal("head mismatch")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, e := c.Head(ctx); e == nil {
		t.Fatal("cancellation ignored")
	}
	slow := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-r.Context().Done():
		case <-time.After(200 * time.Millisecond):
		}
	}))
	defer slow.Close()
	c.base = slow.URL
	c.http = slow.Client()
	c.http.Timeout = 20 * time.Millisecond
	if _, e := c.Head(context.Background()); e == nil {
		t.Fatal("timeout ignored")
	}
}
