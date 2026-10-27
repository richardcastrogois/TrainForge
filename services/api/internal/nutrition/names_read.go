package nutrition

import (
	"context"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

// FoodNameTarget binds a display name to the same identity/version used by the
// composition. Homonyms and old source versions must never share a translation.
type FoodNameTarget struct{ FoodID, FoodVersion string }

// ReviewedNameDisplay contains display/search editorial metadata only. Source
// names, nutrients, quantities and consumed versions are never rewritten.
type ReviewedNameDisplay struct {
	Name              string   `json:"name"`
	Locale            string   `json:"locale"`
	VersionID         string   `json:"versionId"`
	Aliases           []string `json:"-"`
	Attribution       string   `json:"attribution"`
	LicenseLabel      string   `json:"licenseLabel"`
	LicenseURL        string   `json:"licenseUrl"`
	ReviewEvidenceSHA string   `json:"reviewEvidenceSha256"`
	RightsEvidenceSHA string   `json:"rightsEvidenceSha256"`
}

type FoodNamesPostgres struct{ Pool *pgxpool.Pool }

// Resolve handles a whole public page with one SQL query, not N+1 detail calls.
// The latest name version is selected BEFORE withdrawal; a withdrawn latest
// version falls back to the original, never to an older reviewed name.
// The caller may bind this query and a catalog revision to one read snapshot.
func (p FoodNamesPostgres) Resolve(ctx context.Context, targets []FoodNameTarget, locale string) (map[FoodNameTarget]ReviewedNameDisplay, error) {
	return resolveFoodNames(ctx, p.Pool, targets, locale)
}

type foodNameQuery interface {
	Query(context.Context, string, ...any) (pgx.Rows, error)
}

func resolveFoodNames(ctx context.Context, q foodNameQuery, targets []FoodNameTarget, locale string) (map[FoodNameTarget]ReviewedNameDisplay, error) {
	result := map[FoodNameTarget]ReviewedNameDisplay{}
	if !foodNameLocale(locale) || len(targets) > 50 {
		return nil, ErrFoodQuery
	}
	ids, versions := []string{}, []string{}
	for _, target := range targets {
		if !foodPattern.MatchString(target.FoodID) || !shaPattern.MatchString(target.FoodVersion) {
			return nil, ErrFoodQuery
		}
		ids = append(ids, target.FoodID)
		versions = append(versions, target.FoodVersion)
	}
	if len(targets) == 0 {
		return result, nil
	}
	rows, err := q.Query(ctx, `WITH requested AS(SELECT * FROM unnest($1::text[],$2::text[]) r(food_id,version_sha))
 SELECT v.food_id,v.version_sha,v.name_original,v.name_locale,n.version_sha,n.payload
 FROM requested r JOIN trainforge_v1.food_versions v ON v.food_id=r.food_id AND v.version_sha=r.version_sha
 JOIN LATERAL(SELECT nv.* FROM trainforge_v1.food_name_versions nv
  WHERE nv.food_id=v.food_id AND nv.food_version_sha=v.version_sha AND nv.locale=$3
  ORDER BY nv.created_at DESC,nv.version_sha DESC LIMIT 1) n ON true
 WHERE `+foodVisible+` AND NOT EXISTS(SELECT 1 FROM trainforge_v1.food_name_withdrawals w
  WHERE w.food_id=n.food_id AND w.food_version_sha=n.food_version_sha AND w.locale=n.locale AND w.version_sha=n.version_sha)`, ids, versions, locale)
	if err != nil {
		return nil, ErrFoodUnavailable
	}
	defer rows.Close()
	for rows.Next() {
		var target FoodNameTarget
		var original, sourceLocale, version string
		var raw []byte
		if rows.Scan(&target.FoodID, &target.FoodVersion, &original, &sourceLocale, &version, &raw) != nil {
			return nil, ErrFoodUnavailable
		}
		names, err := DecodeReviewedFoodNames(raw, time.Now().UTC())
		if err != nil || names.FoodID != target.FoodID || names.FoodVersion != target.FoodVersion || names.SourceName != original || names.SourceLocale != sourceLocale || names.Locale != locale || names.VersionID() != version {
			return nil, ErrFoodUnavailable
		}
		result[target] = ReviewedNameDisplay{Name: names.Name, Locale: locale, VersionID: version, Aliases: append([]string{}, names.Aliases...), Attribution: names.Review.Attribution, LicenseLabel: names.Review.LicenseLabel, LicenseURL: names.Review.LicenseURL, ReviewEvidenceSHA: names.Review.EvidenceSHA, RightsEvidenceSHA: names.Review.RightsSHA}
	}
	if rows.Err() != nil {
		return nil, ErrFoodUnavailable
	}
	return result, nil
}
