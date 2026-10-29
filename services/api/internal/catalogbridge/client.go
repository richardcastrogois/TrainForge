// Package catalogbridge is the bounded, credential-free boundary to the public catalog service.
package catalogbridge

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/platform/httpapi"
)

var ErrUnavailable = errors.New("catalog bridge unavailable")

type Client struct {
	base string
	http *http.Client
}

// New accepts a configured loopback endpoint only. DNS, proxies, redirects and credentials are disabled.
func New(raw string) (*Client, error) {
	u, e := url.Parse(raw)
	if e != nil || u.Scheme != "http" || u.Hostname() != "127.0.0.1" || u.Port() != "18083" || u.User != nil || u.Path != "" || u.RawQuery != "" || u.Fragment != "" || u.Opaque != "" {
		return nil, ErrUnavailable
	}
	transport := &http.Transport{Proxy: nil, DialContext: (&net.Dialer{Timeout: time.Second}).DialContext, MaxConnsPerHost: 8, MaxIdleConnsPerHost: 4, IdleConnTimeout: 30 * time.Second, ResponseHeaderTimeout: time.Second, DisableCompression: true}
	return &Client{base: raw, http: &http.Client{Timeout: 2 * time.Second, Transport: transport, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}}, nil
}
func (c *Client) request(ctx context.Context, path string, headers http.Header) (*http.Response, error) {
	if c == nil || c.http == nil {
		return nil, ErrUnavailable
	}
	r, e := http.NewRequestWithContext(ctx, "GET", c.base+path, nil)
	if e != nil {
		return nil, ErrUnavailable
	}
	r.Header.Set("Accept", "application/json")
	if tag := headers.Get("If-None-Match"); tag != "" && len(tag) <= 256 {
		r.Header.Set("If-None-Match", tag)
	}
	reply, e := c.http.Do(r)
	if e != nil {
		return nil, ErrUnavailable
	}
	return reply, nil
}
func (c *Client) Head(ctx context.Context) (catalogauthority.Head, error) {
	var h catalogauthority.Head
	r, e := c.request(ctx, "/internal/catalog/revision", nil)
	if e != nil {
		return h, e
	}
	defer r.Body.Close()
	if r.StatusCode != 200 {
		return h, ErrUnavailable
	}
	raw, e := io.ReadAll(io.LimitReader(r.Body, 4097))
	if e != nil || len(raw) > 4096 {
		return h, ErrUnavailable
	}
	if json.Unmarshal(raw, &h) != nil || !h.Valid() {
		return catalogauthority.Head{}, ErrUnavailable
	}
	return h, nil
}

// CheckProjection never accepts session/user identifiers. It compares exact editorial bytes.
// The core transaction holds the mirror lock until its own SQL operation commits.
func (c *Client) CheckProjection(ctx context.Context, tx pgx.Tx) error {
	if tx == nil {
		return ErrUnavailable
	}
	if _, e := tx.Exec(ctx, `SELECT pg_advisory_xact_lock_shared($1)`, catalogauthority.ProjectionLock); e != nil {
		return ErrUnavailable
	}
	head, e := c.Head(ctx)
	if e != nil {
		return ErrUnavailable
	}
	_, digest, e := catalogauthority.Read(ctx, tx)
	if e != nil || head.Digest != digest {
		return ErrUnavailable
	}
	return nil
}
func (c *Client) Register(m *http.ServeMux) {
	for _, path := range []string{"/api/v1/catalog/filters", "/api/v1/catalog/programs", "/api/v1/catalog/programs/{id}", "/api/v1/catalog/movements", "/api/v1/catalog/movements/{id}"} {
		m.HandleFunc("GET "+path, c.Forward)
	}
}

// Forward has no local repository fallback and buffers the bounded response before writing headers.
func (c *Client) Forward(w http.ResponseWriter, r *http.Request) {
	failure := func() { w.Header().Set("Cache-Control", "no-store"); httpapi.Failure(w, r, 503, "catalog_unavailable") }
	path := r.URL.EscapedPath()
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}
	response, e := c.request(r.Context(), path, r.Header)
	if e != nil {
		failure()
		return
	}
	defer response.Body.Close()
	switch response.StatusCode {
	case 200, 304, 400, 404, 429, 503:
	default:
		failure()
		return
	}
	raw, e := io.ReadAll(io.LimitReader(response.Body, (2<<20)+1))
	if e != nil || len(raw) > 2<<20 {
		failure()
		return
	}
	if response.StatusCode != 304 && (!strings.HasPrefix(response.Header.Get("Content-Type"), "application/json") && !strings.HasPrefix(response.Header.Get("Content-Type"), "application/problem+json") || !json.Valid(raw)) {
		failure()
		return
	}
	for _, key := range []string{"Content-Type", "ETag", "Cache-Control", "Retry-After"} {
		if v := response.Header.Get(key); v != "" {
			w.Header().Set(key, v)
		}
	}
	if response.StatusCode >= 400 {
		// Keep correlation at the caller's boundary; never propagate remote diagnostics or bodies.
		var problem httpapi.Problem
		if json.Unmarshal(raw, &problem) != nil {
			failure()
			return
		}
		allowed := map[string]bool{"invalid_catalog_query": true, "catalog_item_unavailable": true, "catalog_unavailable": true, "rate_limited": true}
		if !allowed[problem.Code] {
			failure()
			return
		}
		httpapi.Failure(w, r, response.StatusCode, problem.Code)
		return
	}
	w.WriteHeader(response.StatusCode)
	_, _ = w.Write(raw)
}
