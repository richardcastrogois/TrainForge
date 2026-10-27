package nutrition

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

type FoodNameCoverageCount struct {
	Foods     int64 `json:"visibleSourceVersions"`
	Active    int64 `json:"storedActiveNames"`
	Withdrawn int64 `json:"withdrawnLatestNames"`
	Fallback  int64 `json:"originalFallbacks"`
}
type FoodNameLocaleCoverage struct {
	Locale  string `json:"locale"`
	Version string `json:"catalogVersion"`
	FoodNameCoverageCount
}
type FoodNameSourceCoverage struct {
	Locale        string `json:"locale"`
	SourceID      string `json:"sourceId"`
	SourceVersion string `json:"sourcePublishedVersion"`
	FoodNameCoverageCount
}
type FoodNameCoverage struct {
	Contract    string                   `json:"contract"`
	GeneratedAt string                   `json:"generatedAt"`
	Basis       string                   `json:"basis"`
	Locales     []FoodNameLocaleCoverage `json:"locales"`
	Sources     []FoodNameSourceCoverage `json:"sources"`
}

// ReadFoodNameCoverage counts stored editorial rows over visible latest public
// source versions. It is not a language-quality audit or a claim of global food
// coverage. No names, review documents, private foods or user records are read.
func ReadFoodNameCoverage(ctx context.Context, pool *pgxpool.Pool) (FoodNameCoverage, error) {
	out := FoodNameCoverage{Contract: "trainforge.food-name-coverage/1", Basis: "latest-visible-public-source-versions/stored-editorial-rows", Locales: []FoodNameLocaleCoverage{}, Sources: []FoodNameSourceCoverage{}}
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
	if err != nil {
		return out, ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	var generated time.Time
	if tx.QueryRow(ctx, "SELECT transaction_timestamp()").Scan(&generated) != nil {
		return out, ErrFoodUnavailable
	}
	out.GeneratedAt = generated.UTC().Format(time.RFC3339Nano)
	rows, err := tx.Query(ctx, "SELECT locale,revision::text FROM trainforge_v1.food_name_catalogs ORDER BY locale COLLATE \"C\"")
	if err != nil {
		return out, ErrFoodUnavailable
	}
	indices := map[string]int{}
	for rows.Next() {
		var l FoodNameLocaleCoverage
		if rows.Scan(&l.Locale, &l.Version) != nil || !foodNameLocale(l.Locale) || !validNamesRevision(l.Version) {
			rows.Close()
			return out, ErrFoodUnavailable
		}
		indices[l.Locale] = len(out.Locales)
		out.Locales = append(out.Locales, l)
	}
	if rows.Err() != nil || len(out.Locales) != 4 {
		rows.Close()
		return out, ErrFoodUnavailable
	}
	rows.Close()
	rows, err = tx.Query(ctx, foodLatest+`SELECT c.locale,v.source_id,v.source_published_version,count(*),
 count(*) FILTER(WHERE n.version_sha IS NOT NULL AND w.version_sha IS NULL),
 count(*) FILTER(WHERE w.version_sha IS NOT NULL)
 FROM latest v CROSS JOIN trainforge_v1.food_name_catalogs c
 LEFT JOIN LATERAL(SELECT nv.version_sha FROM trainforge_v1.food_name_versions nv
 WHERE nv.food_id=v.food_id AND nv.food_version_sha=v.version_sha AND nv.locale=c.locale
 ORDER BY nv.created_at DESC,nv.version_sha DESC LIMIT 1)n ON true
 LEFT JOIN trainforge_v1.food_name_withdrawals w ON w.food_id=v.food_id AND w.food_version_sha=v.version_sha AND w.locale=c.locale AND w.version_sha=n.version_sha
 WHERE `+foodVisible+` GROUP BY c.locale,v.source_id,v.source_published_version
 ORDER BY c.locale COLLATE "C",v.source_id COLLATE "C",v.source_published_version COLLATE "C"`)
	if err != nil {
		return out, ErrFoodUnavailable
	}
	defer rows.Close()
	for rows.Next() {
		var r FoodNameSourceCoverage
		if rows.Scan(&r.Locale, &r.SourceID, &r.SourceVersion, &r.Foods, &r.Active, &r.Withdrawn) != nil {
			return out, ErrFoodUnavailable
		}
		i, ok := indices[r.Locale]
		if !ok || r.Active+r.Withdrawn > r.Foods {
			return out, ErrFoodUnavailable
		}
		r.Fallback = r.Foods - r.Active
		out.Sources = append(out.Sources, r)
		l := &out.Locales[i]
		l.Foods += r.Foods
		l.Active += r.Active
		l.Withdrawn += r.Withdrawn
		l.Fallback += r.Fallback
	}
	if rows.Err() != nil {
		return out, ErrFoodUnavailable
	}
	rows.Close()
	if tx.Commit(ctx) != nil {
		return out, ErrFoodUnavailable
	}
	return out, nil
}
