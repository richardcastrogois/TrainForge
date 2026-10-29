package catalogbridge

import (
	"bytes"
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/http"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/platform/httpapi"
)

type buffer struct {
	header http.Header
	body   bytes.Buffer
	status int
	failed bool
}

func (b *buffer) Header() http.Header { return b.header }
func (b *buffer) WriteHeader(code int) {
	if b.status == 0 {
		b.status = code
	}
}
func (b *buffer) Write(raw []byte) (int, error) {
	if b.status == 0 {
		b.status = 200
	}
	if b.body.Len()+len(raw) > 2<<20 {
		b.failed = true
		return 0, ErrUnavailable
	}
	return b.body.Write(raw)
}
func (c *Client) currentMirror(ctx context.Context, pool *pgxpool.Pool) (catalogauthority.Head, error) {
	h, e := c.Head(ctx)
	if e != nil || pool == nil {
		return h, ErrUnavailable
	}
	_, digest, e := catalogauthority.Read(ctx, pool)
	if e != nil || digest != h.Digest {
		return h, ErrUnavailable
	}
	return h, nil
}

// LocalVerified is an explicit rollback mode, never an automatic fallback. Authority stays remote.
// The response is withheld unless before/after revisions and mirror digests agree.
func (c *Client) LocalVerified(pool *pgxpool.Pool, register func(*http.ServeMux)) func(*http.ServeMux) {
	local := http.NewServeMux()
	register(local)
	handler := func(w http.ResponseWriter, r *http.Request) {
		fail := func() { w.Header().Set("Cache-Control", "no-store"); httpapi.Failure(w, r, 503, "catalog_unavailable") }
		before, e := c.currentMirror(r.Context(), pool)
		if e != nil {
			fail()
			return
		}
		reply := &buffer{header: make(http.Header)}
		local.ServeHTTP(reply, r)
		after, e := c.currentMirror(r.Context(), pool)
		if e != nil || before != after || reply.failed {
			fail()
			return
		}
		for _, key := range []string{"Content-Type", "ETag", "Cache-Control", "Retry-After"} {
			if v := reply.header.Get(key); v != "" {
				w.Header().Set(key, v)
			}
		}
		status := reply.status
		if status == 0 {
			status = 200
		}
		w.WriteHeader(status)
		_, _ = w.Write(reply.body.Bytes())
	}
	return func(m *http.ServeMux) {
		for _, path := range []string{"/api/v1/catalog/filters", "/api/v1/catalog/programs", "/api/v1/catalog/programs/{id}", "/api/v1/catalog/movements", "/api/v1/catalog/movements/{id}"} {
			m.HandleFunc("GET "+path, handler)
		}
	}
}
