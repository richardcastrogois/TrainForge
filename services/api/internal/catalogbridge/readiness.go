package catalogbridge

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"trainforge.local/api/internal/platform/httpapi"
)

type Readiness struct {
	Core    httpapi.Readiness
	Catalog *Client
	Pool    *pgxpool.Pool
}

func (r Readiness) Ping(ctx context.Context) error {
	if r.Core == nil || r.Catalog == nil || r.Pool == nil || r.Core.Ping(ctx) != nil {
		return ErrUnavailable
	}
	tx, e := r.Pool.Begin(ctx)
	if e != nil {
		return ErrUnavailable
	}
	defer tx.Rollback(ctx)
	if r.Catalog.CheckProjection(ctx, tx) != nil {
		return ErrUnavailable
	}
	if tx.Commit(ctx) != nil {
		return ErrUnavailable
	}
	return nil
}
