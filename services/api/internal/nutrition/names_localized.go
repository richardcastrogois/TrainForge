package nutrition

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5"
	"net/url"
	"strconv"
	"time"
)

var ErrFoodNamesChanged = errors.New("food name catalog changed")

type FoodNameCatalog struct {
	Locale  string `json:"locale"`
	Version string `json:"version"`
}
type LocalizedFoodRepository interface {
	LocalizedList(context.Context, FoodFilters) ([]FoodSummary, FoodNameCatalog, error)
	LocalizedDetail(context.Context, string, string, string) (FoodDetail, error)
}

func validNamesRevision(value string) bool {
	parsed, err := strconv.ParseInt(value, 10, 64)
	return err == nil && parsed >= 0 && strconv.FormatInt(parsed, 10) == value
}
func foodDetailQuery(q url.Values) (string, string, error) {
	for key, values := range q {
		if (key != "versionId" && key != "locale") || len(values) != 1 || len(values[0]) > 1024 {
			return "", "", ErrFoodQuery
		}
	}
	onlyVersion := url.Values{}
	if values, exists := q["versionId"]; exists {
		onlyVersion["versionId"] = values
	}
	version, err := foodVersion(onlyVersion)
	locale := q.Get("locale")
	if err != nil || (locale != "" && !foodNameLocale(locale)) {
		return "", "", ErrFoodQuery
	}
	return version, locale, nil
}

const localizedNameJoin = ` LEFT JOIN LATERAL(SELECT nv.* FROM trainforge_v1.food_name_versions nv
 WHERE nv.food_id=v.food_id AND nv.food_version_sha=v.version_sha AND nv.locale=$3
 ORDER BY nv.created_at DESC,nv.version_sha DESC LIMIT 1) n ON true
 LEFT JOIN trainforge_v1.food_name_withdrawals nw ON nw.food_id=n.food_id
 AND nw.food_version_sha=n.food_version_sha AND nw.locale=n.locale AND nw.version_sha=n.version_sha `
const activeNamePayload = `CASE WHEN nw.version_sha IS NULL THEN n.payload ELSE NULL END`
const activeNameVersion = `CASE WHEN nw.version_sha IS NULL THEN n.version_sha ELSE NULL END`

// A repeatable-read snapshot binds the revision and name rows atomically. The
// locale revision increments in the same transaction as publication/withdrawal.
func (p FoodPostgres) nameSnapshot(ctx context.Context, locale, expected string) (pgx.Tx, FoodNameCatalog, error) {
	catalog := FoodNameCatalog{Locale: locale}
	if !foodNameLocale(locale) || (expected != "" && !validNamesRevision(expected)) {
		return nil, catalog, ErrFoodQuery
	}
	tx, err := p.Pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
	if err != nil {
		return nil, catalog, ErrFoodUnavailable
	}
	var revision int64
	if tx.QueryRow(ctx, "SELECT revision FROM trainforge_v1.food_name_catalogs WHERE locale=$1", locale).Scan(&revision) != nil {
		tx.Rollback(ctx)
		return nil, catalog, ErrFoodUnavailable
	}
	catalog.Version = strconv.FormatInt(revision, 10)
	if expected != "" && expected != catalog.Version {
		tx.Rollback(ctx)
		return nil, catalog, ErrFoodNamesChanged
	}
	return tx, catalog, nil
}

func attachReviewedName(item *FoodSummary, raw []byte, version *string, locale string) error {
	if version == nil && len(raw) == 0 {
		return nil
	}
	if version == nil {
		return ErrFoodUnavailable
	}
	n, err := DecodeReviewedFoodNames(raw, time.Now().UTC())
	if err != nil || n.VersionID() != *version || n.FoodID != item.ID || n.FoodVersion != item.VersionID || n.SourceName != item.Name || n.SourceLocale != item.Locale || n.Locale != locale {
		return ErrFoodUnavailable
	}
	item.ReviewedName = &ReviewedNameDisplay{Name: n.Name, Locale: n.Locale, VersionID: *version, Aliases: append([]string{}, n.Aliases...), Attribution: n.Review.Attribution, LicenseLabel: n.Review.LicenseLabel, LicenseURL: n.Review.LicenseURL, ReviewEvidenceSHA: n.Review.EvidenceSHA, RightsEvidenceSHA: n.Review.RightsSHA}
	return nil
}

func (p FoodPostgres) LocalizedList(ctx context.Context, f FoodFilters) ([]FoodSummary, FoodNameCatalog, error) {
	tx, catalog, err := p.nameSnapshot(ctx, f.Locale, f.NamesVersion)
	if err != nil {
		return nil, catalog, err
	}
	defer tx.Rollback(ctx)
	rows, err := tx.Query(ctx, foodLatest+`SELECT `+foodProjection+`,`+activeNamePayload+`,`+activeNameVersion+` FROM latest v `+localizedNameJoin+` WHERE `+foodVisible+`
 AND ($1='' OR position(lower($1) in lower(regexp_replace(v.name_original,U&'[\0009-\000D\0020\0085\00A0\1680\2000-\200A\2028\2029\202F\205F\3000]+',' ','g')))>0
 OR (n.version_sha IS NOT NULL AND nw.version_sha IS NULL AND (position(lower($1) in lower(n.name))>0 OR EXISTS(SELECT 1 FROM unnest(n.aliases) alias WHERE position(lower($1) in lower(alias))>0)))
 OR EXISTS(SELECT 1 FROM unnest($6::text[]) term WHERE lower(v.name_original) ~ ('^[[:space:]]*'||term||'([^[:alpha:]]|$)')))
 AND ($2='' OR v.source_id=$2) AND ($4='' OR v.food_id COLLATE "C">$4 COLLATE "C")
 ORDER BY v.food_id COLLATE "C" LIMIT $5`, f.Q, f.Source, f.Locale, f.After, f.Limit+1, foodSearchTerms(f.Q, f.Locale))
	if err != nil {
		return nil, catalog, ErrFoodUnavailable
	}
	defer rows.Close()
	result := []FoodSummary{}
	for rows.Next() {
		var raw, names []byte
		var version *string
		if rows.Scan(&raw, &names, &version) != nil {
			return nil, catalog, ErrFoodUnavailable
		}
		item, err := decodeFoodSummary(raw)
		if err != nil {
			return nil, catalog, err
		}
		if err = attachReviewedName(&item, names, version, f.Locale); err != nil {
			return nil, catalog, err
		}
		result = append(result, item)
	}
	if rows.Err() != nil {
		return nil, catalog, ErrFoodUnavailable
	}
	rows.Close()
	if tx.Commit(ctx) != nil {
		return nil, catalog, ErrFoodUnavailable
	}
	return result, catalog, nil
}
func (p FoodPostgres) LocalizedDetail(ctx context.Context, id, version, locale string) (FoodDetail, error) {
	tx, catalog, err := p.nameSnapshot(ctx, locale, "")
	if err != nil {
		return FoodDetail{}, err
	}
	defer tx.Rollback(ctx)
	query := `WITH selected AS(SELECT * FROM trainforge_v1.food_versions WHERE food_id=$1 AND ($2='' OR version_sha=$2) ORDER BY created_at DESC,version_sha DESC LIMIT 1)
 SELECT ` + foodProjection + `,v.nutrients,` + activeNamePayload + `,` + activeNameVersion + ` FROM selected v ` + localizedNameJoin + ` WHERE ` + foodVisible
	var raw, cells, names []byte
	var nameVersion *string
	err = tx.QueryRow(ctx, query, id, version, locale).Scan(&raw, &cells, &names, &nameVersion)
	if errors.Is(err, pgx.ErrNoRows) {
		return FoodDetail{}, ErrFoodMissing
	}
	if err != nil {
		return FoodDetail{}, ErrFoodUnavailable
	}
	item, err := decodeFoodSummary(raw)
	if err != nil {
		return FoodDetail{}, err
	}
	if attachReviewedName(&item, names, nameVersion, locale) != nil {
		return FoodDetail{}, ErrFoodUnavailable
	}
	detail, err := decodeFoodDetail(item, cells)
	if err != nil {
		return FoodDetail{}, err
	}
	detail.NameCatalog = &catalog
	if tx.Commit(ctx) != nil {
		return FoodDetail{}, ErrFoodUnavailable
	}
	return detail, nil
}
