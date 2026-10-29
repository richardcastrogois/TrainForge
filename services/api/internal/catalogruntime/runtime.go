// Package catalogruntime composes only the public catalog and shared HTTP boundary.
package catalogruntime

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"net"
	"net/http"
	"strconv"
	"time"
	"trainforge.local/api/internal/catalog"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/catalogtarget"
	"trainforge.local/api/internal/platform/httpapi"
)

type Config struct {
	Address, DSN string
	Local        bool
	Timeout      time.Duration
}

var ErrConfig = errors.New("invalid isolated catalog configuration")

func Load(get func(string) string) (Config, error) {
	c := Config{Address: "127.0.0.1:18083", DSN: get("TF_CATALOG_DATABASE_URL"), Timeout: 3 * time.Second}
	if v := get("TF_CATALOG_LISTEN_ADDR"); v != "" {
		c.Address = v
	}
	host, port, err := net.SplitHostPort(c.Address)
	n, e := strconv.Atoi(port)
	if err != nil || e != nil || host != "127.0.0.1" || n < 1 || n > 65535 {
		return c, ErrConfig
	}
	if v := get("TF_CATALOG_REQUEST_TIMEOUT_SECONDS"); v != "" {
		n, e := strconv.Atoi(v)
		if e != nil || n < 1 || n > 5 {
			return c, ErrConfig
		}
		c.Timeout = time.Duration(n) * time.Second
	}
	mode := get("TF_CATALOG_MODE")
	if mode != "" && mode != "fixture" && mode != "local" {
		return c, ErrConfig
	}
	c.Local = mode == "local"
	target := catalogtarget.Config
	if c.Local {
		target = catalogtarget.LocalConfig
	}
	if _, err := target(c.DSN, catalogtarget.ReaderRole); err != nil {
		return c, ErrConfig
	}
	return c, nil
}

func Open(ctx context.Context, dsn string) (*pgxpool.Pool, error) { return open(ctx, dsn, false) }
func open(ctx context.Context, dsn string, local bool) (*pgxpool.Pool, error) {
	target := catalogtarget.Config
	if local {
		target = catalogtarget.LocalConfig
	}
	c, err := target(dsn, catalogtarget.ReaderRole)
	if err != nil {
		return nil, err
	}
	c.MaxConns = 4
	c.MinConns = 0
	c.ConnConfig.ConnectTimeout = time.Second
	c.MaxConnIdleTime = 30 * time.Second
	c.MaxConnLifetime = 10 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, c)
	if err != nil {
		return nil, errors.New("catalog connection unavailable")
	}
	return pool, nil
}

func Handler(pool *pgxpool.Pool, logger *slog.Logger, timeout time.Duration) http.Handler {
	var repo catalog.CatalogRepository
	if pool != nil {
		repo = catalog.CatalogPostgres{Pool: pool}
	}
	public := catalog.CatalogHandler{Reader: catalog.Reader{Repository: repo}}
	internal := func(m *http.ServeMux) {
		m.HandleFunc("GET /internal/catalog/revision", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", "no-store")
			if pool == nil {
				httpapi.Failure(w, r, 503, "catalog_unavailable")
				return
			}
			head, e := catalogauthority.Current(r.Context(), pool)
			if e != nil {
				httpapi.Failure(w, r, 503, "catalog_unavailable")
				return
			}
			httpapi.JSON(w, 200, head)
		})
	}
	return httpapi.New(Readiness{pool}, logger, timeout, nil, public.Register, internal)
}

// Run never starts the main API, a migration or an external Google client.
func Run(ctx context.Context, c Config, logger *slog.Logger) error {
	pool, err := open(ctx, c.DSN, c.Local)
	if err != nil {
		return err
	}
	defer pool.Close()
	server := &http.Server{Addr: c.Address, Handler: Handler(pool, logger, c.Timeout), ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 7 * time.Second, WriteTimeout: 7 * time.Second, IdleTimeout: 15 * time.Second, MaxHeaderBytes: 16 << 10}
	done := make(chan struct{})
	defer close(done)
	go func() {
		select {
		case <-ctx.Done():
			shutdown, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()
			_ = server.Shutdown(shutdown)
		case <-done:
		}
	}()
	logger.Info("catalog_listening", "address", c.Address)
	if err := httpapi.Serve(server, 64); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return errors.New("catalog listener unavailable")
	}
	return nil
}
