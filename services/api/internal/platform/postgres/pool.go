package postgres

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"strings"
	"time"
)

func Open(ctx context.Context, dsn string, max int32) (*pgxpool.Pool, error) {
	c, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("invalid database configuration")
	}
	if !strings.HasPrefix(c.ConnConfig.Database, "trainforge_v1_") || c.ConnConfig.User == "" {
		return nil, errors.New("isolated database and explicit user required")
	}
	if max < 1 || max > 50 {
		return nil, errors.New("invalid database pool limit")
	}
	c.MaxConns = max
	c.MinConns = 0
	c.MaxConnLifetime = 30 * time.Minute
	c.MaxConnIdleTime = 5 * time.Minute
	c.ConnConfig.ConnectTimeout = 3 * time.Second
	p, err := pgxpool.NewWithConfig(ctx, c)
	if err != nil {
		return nil, errors.New("database initialization failed")
	}
	return p, nil
}
