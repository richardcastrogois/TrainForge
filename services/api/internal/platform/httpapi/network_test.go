package httpapi

import (
	"crypto/tls"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strconv"
	"sync"
	"testing"
	"time"
)

func TestExplicitProxyBoundary(t *testing.T) {
	n := Network{RequireTLS: true, TrustedProxies: []netip.Prefix{netip.MustParsePrefix("10.0.0.0/24")}}
	for _, tc := range []struct {
		peer, xff, proto, want string
		secure, fail           bool
	}{
		{"198.51.100.1:3000", "192.0.2.9", "https", "198.51.100.1", false, false},
		{"10.0.0.1:3000", "192.0.2.9, 10.0.0.2", "https", "192.0.2.9", true, false},
		{"10.0.0.1:3000", "203.0.113.8, 192.0.2.9", "https", "192.0.2.9", true, false},
		{"10.0.0.1:3000", "invalid", "https", "", false, true},
		{"10.0.0.1:3000", "192.0.2.9", "https,http", "", false, true},
		{"[::ffff:198.51.100.1]:3000", "", "", "198.51.100.1", false, false},
	} {
		r := httptest.NewRequest("GET", "http://example.test/", nil)
		r.RemoteAddr = tc.peer
		if tc.xff != "" {
			r.Header.Set("X-Forwarded-For", tc.xff)
		}
		if tc.proto != "" {
			r.Header.Set("X-Forwarded-Proto", tc.proto)
		}
		ip, secure, err := n.Resolve(r)
		if (err != nil) != tc.fail || !tc.fail && (ip != tc.want || secure != tc.secure) {
			t.Fatalf("proxy boundary mismatch: %+v", tc)
		}
	}
	r := httptest.NewRequest("GET", "https://example.test/", nil)
	r.RemoteAddr = "10.0.0.1:3000"
	r.TLS = &tls.ConnectionState{}
	_, secure, err := n.Resolve(r)
	if err != nil || !secure {
		t.Fatal("direct TLS lost")
	}
	r.Header.Add("X-Forwarded-For", "192.0.2.1")
	r.Header.Add("X-Forwarded-For", "192.0.2.2")
	if _, _, err = n.Resolve(r); err == nil {
		t.Fatal("ambiguous forwarding headers accepted")
	}
}
func TestLimiterConcurrentBoundedAndExpiring(t *testing.T) {
	now := time.Now()
	l := Limiter{now: func() time.Time { return now }}
	var wg sync.WaitGroup
	var lock sync.Mutex
	allowed := 0
	for i := 0; i < 1000; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if l.Allow("one-peer", 60) {
				lock.Lock()
				allowed++
				lock.Unlock()
			}
		}()
	}
	wg.Wait()
	if allowed != 60 {
		t.Fatalf("concurrent allowance %d", allowed)
	}
	for i := 0; i < 10000; i++ {
		l.Allow("peer-"+strconv.Itoa(i), 60)
	}
	size := 0
	for i := range l.shards {
		size += len(l.shards[i].entries)
	}
	if size > 4096 {
		t.Fatal("unbounded limiter memory")
	}
	now = now.Add(time.Minute)
	if !l.Allow("one-peer", 60) {
		t.Fatal("window did not expire")
	}
}
func TestNetworkAndAdmissionGuard(t *testing.T) {
	entered := make(chan struct{}, 128)
	release := make(chan struct{})
	h := NewWithNetwork(nil, slog.New(slog.NewTextHandler(io.Discard, nil)), time.Second, nil, Network{}, func(m *http.ServeMux) {
		m.HandleFunc("GET /blocked", func(w http.ResponseWriter, r *http.Request) { entered <- struct{}{}; <-release; w.WriteHeader(204) })
	})
	var wg sync.WaitGroup
	for i := 0; i < 128; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			h.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest("GET", "/blocked", nil))
		}()
	}
	for i := 0; i < 128; i++ {
		select {
		case <-entered:
		case <-time.After(5 * time.Second):
			close(release)
			wg.Wait()
			t.Fatal("admission fixture timeout")
		}
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/blocked", nil))
	if w.Code != 503 || w.Header().Get("Retry-After") != "1" {
		close(release)
		wg.Wait()
		t.Fatal("admission not bounded")
	}
	close(release)
	wg.Wait()
	strict := NewWithNetwork(nil, slog.Default(), time.Second, nil, Network{RequireTLS: true})
	r := httptest.NewRequest("GET", "/api/v1/health/live", nil)
	r.Header.Set("X-Forwarded-Proto", "https")
	w = httptest.NewRecorder()
	strict.ServeHTTP(w, r)
	if w.Code != 426 {
		t.Fatal("untrusted proxy bypassed HTTPS")
	}
}
