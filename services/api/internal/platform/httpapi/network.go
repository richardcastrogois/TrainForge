package httpapi

import (
	"errors"
	"hash/fnv"
	"net"
	"net/http"
	"net/netip"
	"strings"
	"sync"
	"time"
)

var ErrProxyHeaders = errors.New("invalid proxy headers")

type Network struct {
	RequireTLS     bool
	TrustedProxies []netip.Prefix
}

func (n Network) trusted(ip netip.Addr) bool {
	for _, prefix := range n.TrustedProxies {
		if prefix.Contains(ip) {
			return true
		}
	}
	return false
}

// Resolve ignores every forwarding header from an untrusted socket peer.
// Trusted proxies must replace client-supplied headers at the edge.
func (n Network) Resolve(r *http.Request) (string, bool, error) {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	ip, err := netip.ParseAddr(host)
	if err != nil {
		return "", false, ErrProxyHeaders
	}
	ip = ip.Unmap()
	secure := r.TLS != nil
	if !n.trusted(ip) {
		return ip.String(), secure, nil
	}
	forwarded := r.Header.Values("X-Forwarded-For")
	proto := r.Header.Values("X-Forwarded-Proto")
	if len(forwarded) > 1 || len(proto) > 1 {
		return "", false, ErrProxyHeaders
	}
	if len(proto) == 1 {
		if proto[0] != "http" && proto[0] != "https" {
			return "", false, ErrProxyHeaders
		}
		secure = secure || proto[0] == "https"
	}
	if len(forwarded) == 0 {
		return ip.String(), secure, nil
	}
	if len(forwarded[0]) > 1024 {
		return "", false, ErrProxyHeaders
	}
	chain := strings.Split(forwarded[0], ",")
	if len(chain) > 8 {
		return "", false, ErrProxyHeaders
	}
	hops := make([]netip.Addr, len(chain))
	for i, raw := range chain {
		value, err := netip.ParseAddr(strings.TrimSpace(raw))
		if err != nil {
			return "", false, ErrProxyHeaders
		}
		hops[i] = value.Unmap()
	}
	current := ip
	for i := len(hops) - 1; i >= 0; i-- {
		if !n.trusted(current) {
			break
		}
		current = hops[i]
	}
	return current.String(), secure, nil
}

type rateEntry struct {
	start time.Time
	count int
}
type rateShard struct {
	sync.Mutex
	entries map[string]rateEntry
	swept   time.Time
}

// Limiter is per process, bounded to 4096 keys across 64 shards. No full-map scan
// on each request; expiration is swept at most once a minute in each shard.
type Limiter struct {
	shards [64]rateShard
	now    func() time.Time
}

func (l *Limiter) Allow(key string, limit int) bool {
	clock := time.Now
	if l.now != nil {
		clock = l.now
	}
	now := clock()
	hash := fnv.New64a()
	_, _ = hash.Write([]byte(key))
	s := &l.shards[hash.Sum64()%64]
	s.Lock()
	defer s.Unlock()
	if s.entries == nil {
		s.entries = make(map[string]rateEntry)
	}
	if s.swept.IsZero() || now.Sub(s.swept) >= time.Minute {
		for k, v := range s.entries {
			if now.Sub(v.start) >= time.Minute {
				delete(s.entries, k)
			}
		}
		s.swept = now
	}
	e, exists := s.entries[key]
	if !exists && len(s.entries) >= 64 {
		return false
	}
	if now.Sub(e.start) >= time.Minute {
		e = rateEntry{start: now}
	}
	if e.count >= limit {
		return false
	}
	e.count++
	s.entries[key] = e
	return true
}
func limited(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Retry-After", "60")
	Failure(w, r, 429, "rate_limited")
}
