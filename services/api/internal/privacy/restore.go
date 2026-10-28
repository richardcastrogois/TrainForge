package privacy

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"regexp"
	"time"
)

type Erasure struct {
	UserID   string
	ErasedAt time.Time
}

// ApplyErasures is an administrative restore gate, never an HTTP operation.
// The target must be a separately named, non-serving restore database.
func ApplyErasures(ctx context.Context, pool *pgxpool.Pool, records []Erasure) (int, error) {
	cfg := pool.Config().ConnConfig
	if cfg.Host != "127.0.0.1" || cfg.Port != 15432 || !regexp.MustCompile("^trainforge_v1_privacy_restore_[a-f0-9]{12}$").MatchString(cfg.Database) || len(records) > 500 {
		return 0, ErrQuery
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, ErrUnavailable
	}
	defer tx.Rollback(ctx)
	if err = coverage(ctx, tx); err != nil {
		return 0, err
	}
	for _, record := range records {
		var id string
		err = tx.QueryRow(ctx, "SELECT id::text FROM trainforge_v1.users WHERE id=$1 FOR UPDATE", record.UserID).Scan(&id)
		if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrUnavailable
		}
		if record.ErasedAt.IsZero() {
			return 0, ErrQuery
		}
		if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.account_erasures(user_id,erased_at) VALUES($1,$2) ON CONFLICT DO NOTHING", record.UserID, record.ErasedAt); err != nil {
			return 0, ErrUnavailable
		}
		if err = purge(ctx, tx, record.UserID, func() error {
			_, err := tx.Exec(ctx, "DELETE FROM trainforge_v1.food_versions WHERE owner_id=$1", record.UserID)
			return err
		}, func() error {
			_, err := tx.Exec(ctx, "DELETE FROM trainforge_v1.training_configuration_versions WHERE user_id=$1", record.UserID)
			return err
		}); err != nil {
			return 0, err
		}
	}
	if tx.Commit(ctx) != nil {
		return 0, ErrUnavailable
	}
	return len(records), nil
}
