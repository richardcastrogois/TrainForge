package privacy

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"regexp"
)

type MaintenanceResult struct {
	Applied            bool `json:"applied"`
	ExpiredIntents     int  `json:"expiredIntents"`
	ExpiredIdempotency int  `json:"expiredIdempotency"`
	ExpiredAccess      int  `json:"expiredAccess"`
	ClosedFamilies     int  `json:"closedFamilies"`
}

func Maintain(ctx context.Context, pool *pgxpool.Pool, apply bool) (MaintenanceResult, error) {
	result := MaintenanceResult{Applied: apply}
	cfg := pool.Config().ConnConfig
	db := cfg.Database
	if cfg.Host != "127.0.0.1" || cfg.Port != 15432 || (db != "trainforge_v1_dev" && !regexp.MustCompile("^trainforge_v1_privacy_test_[a-f0-9]{12}$").MatchString(db)) {
		return result, ErrQuery
	}
	tx, err := pool.Begin(ctx)
	if err != nil {
		return result, ErrUnavailable
	}
	defer tx.Rollback(ctx)
	if err = coverage(ctx, tx); err != nil {
		return result, err
	}
	targets := []struct {
		table, condition string
		count            *int
	}{
		{"account_deletion_intents", "expires_at<clock_timestamp()", &result.ExpiredIntents},
		{"idempotency_records", "expires_at<clock_timestamp()", &result.ExpiredIdempotency},
		{"access_tokens", "expires_at<clock_timestamp()-interval '1 day'", &result.ExpiredAccess},
	}
	for _, target := range targets {
		if apply {
			tag, err := tx.Exec(ctx, "DELETE FROM trainforge_v1."+target.table+" WHERE ctid IN(SELECT ctid FROM trainforge_v1."+target.table+" WHERE "+target.condition+" LIMIT 500 FOR UPDATE SKIP LOCKED)")
			if err != nil {
				return result, ErrUnavailable
			}
			*target.count = int(tag.RowsAffected())
		} else {
			if tx.QueryRow(ctx, "SELECT count(*) FROM(SELECT 1 FROM trainforge_v1."+target.table+" WHERE "+target.condition+" LIMIT 500) candidates").Scan(target.count) != nil {
				return result, ErrUnavailable
			}
		}
	}
	query := `SELECT f.id::text FROM trainforge_v1.auth_families f WHERE f.created_at<clock_timestamp()-interval '31 days'
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.refresh_tokens r WHERE r.family_id=f.id AND r.expires_at>clock_timestamp())
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.access_tokens a WHERE a.family_id=f.id AND a.expires_at>clock_timestamp())
 ORDER BY f.created_at,f.id LIMIT 500`
	if apply {
		query += " FOR UPDATE OF f SKIP LOCKED"
	}
	rows, err := tx.Query(ctx, query)
	if err != nil {
		return result, ErrUnavailable
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if rows.Scan(&id) != nil {
			rows.Close()
			return result, ErrUnavailable
		}
		ids = append(ids, id)
	}
	err = rows.Err()
	rows.Close()
	if err != nil {
		return result, ErrUnavailable
	}
	result.ClosedFamilies = len(ids)
	if apply && len(ids) > 0 {
		for _, table := range []string{"account_deletion_intents", "access_tokens", "refresh_tokens"} {
			if _, err = tx.Exec(ctx, "DELETE FROM trainforge_v1."+table+" WHERE family_id=ANY($1::uuid[])", ids); err != nil {
				return result, ErrUnavailable
			}
		}
		if _, err = tx.Exec(ctx, "DELETE FROM trainforge_v1.auth_families WHERE id=ANY($1::uuid[])", ids); err != nil {
			return result, ErrUnavailable
		}
	}
	if tx.Commit(ctx) != nil {
		return result, ErrUnavailable
	}
	return result, nil
}
