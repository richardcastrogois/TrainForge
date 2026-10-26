package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

// StoreReviewedFoodNames is an operator-side persistence primitive, not a public
// publication endpoint. The caller must verify review identity/evidence before
// invoking it. Runtime has no table write grants. No translation is seeded here.
func StoreReviewedFoodNames(ctx context.Context, pool *pgxpool.Pool, n ReviewedFoodNames, evidence NameEvidence, now time.Time) (string, bool, error) {
	if n.Validate(now) != nil || evidence.Validate(n) != nil {
		return "", false, ErrFoodNames
	}
	version := n.VersionID()
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return "", false, errors.New("food name transaction unavailable")
	}
	defer tx.Rollback(ctx)
	// Serialize publications with the same food key; select the exact original
	// version, including visibility, before accepting an editorial name.
	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock(hashtextextended($1,20261026))", n.FoodID); err != nil {
		return "", false, ErrFoodUnavailable
	}
	var valid bool
	err = tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM trainforge_v1.food_versions v WHERE v.food_id=$1 AND v.version_sha=$2 AND v.name_original=$3 AND v.name_locale=$4 AND "+foodVisible+")", n.FoodID, n.FoodVersion, n.SourceName, n.SourceLocale).Scan(&valid)
	if err != nil {
		return "", false, ErrFoodUnavailable
	}
	if !valid {
		return "", false, ErrFoodNames
	}
	raw, err := json.Marshal(n)
	if err != nil {
		return "", false, ErrFoodNames
	}
	tag, err := tx.Exec(ctx, `INSERT INTO trainforge_v1.food_name_versions(food_id,food_version_sha,locale,version_sha,name,aliases,payload)
 VALUES($1,$2,$3,$4,$5,$6,$7::jsonb) ON CONFLICT(food_id,food_version_sha,locale,version_sha) DO NOTHING`, n.FoodID, n.FoodVersion, n.Locale, version, n.Name, n.Aliases, string(raw))
	if err != nil {
		return "", false, ErrFoodUnavailable
	}
	inserted := tag.RowsAffected() == 1
	if !inserted {
		var same bool
		err = tx.QueryRow(ctx, `SELECT name=$5 AND aliases=$6::text[] AND payload=$7::jsonb FROM trainforge_v1.food_name_versions
   WHERE food_id=$1 AND food_version_sha=$2 AND locale=$3 AND version_sha=$4`, n.FoodID, n.FoodVersion, n.Locale, version, n.Name, n.Aliases, string(raw)).Scan(&same)
		if err != nil || !same {
			return "", false, ErrFoodUnavailable
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return "", false, ErrFoodUnavailable
	}
	return version, inserted, nil
}
