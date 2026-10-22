package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type FoodPostgres struct{ Pool *pgxpool.Pool }

// Latest is chosen before checking grants, owner and withdrawal: never revive an
// older public version when the latest version is unavailable.
const foodLatest = `WITH latest AS (SELECT DISTINCT ON(food_id) *
 FROM trainforge_v1.food_versions ORDER BY food_id,created_at DESC,version_sha DESC) `
const foodVisible = `v.owner_id IS NULL AND v.source_id IS NOT NULL
 AND 'food_catalog'=ANY(v.allowed_operations) AND 'food_composition'=ANY(v.allowed_operations)
 AND v.provenance->>'clinicalApproval'='false'
 AND EXISTS(SELECT 1 FROM trainforge_v1.food_batch_versions bv
 JOIN trainforge_v1.food_import_batches b ON b.artifact_sha=bv.artifact_sha
 WHERE bv.food_id=v.food_id AND bv.version_sha=v.version_sha
 AND b.review_sha=v.provenance->>'reviewSha256')
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.food_withdrawals w WHERE w.food_id=v.food_id AND w.version_sha=v.version_sha)`
const foodProjection = `jsonb_build_object(
 'id',v.food_id,'versionId',v.version_sha,'sourceId',v.source_id,
 'sourceFoodId',v.source_food_id,'sourcePublishedVersion',v.source_published_version,
 'nameOriginal',v.name_original,'nameLocale',v.name_locale,
 'basis',jsonb_build_object('quantity',v.basis_quantity::text,'unit',v.basis_unit),
 'source',v.provenance->'rights')`

func decodeFoodSummary(raw []byte) (FoodSummary, error) {
	var f FoodSummary
	if json.Unmarshal(raw, &f) != nil || !foodPattern.MatchString(f.ID) || !shaPattern.MatchString(f.VersionID) || f.Name == "" || !validCitation(f.Source) || !basisValid(f.Basis) {
		return f, ErrFoodUnavailable
	}
	return f, nil
}
func (p FoodPostgres) List(ctx context.Context, f FoodFilters) ([]FoodSummary, error) {
	rows, err := p.Pool.Query(ctx, foodLatest+`SELECT `+foodProjection+` FROM latest v WHERE `+foodVisible+`
 AND ($1='' OR position(lower($1) in lower(regexp_replace(v.name_original, U&'[\0009-\000D\0020\0085\00A0\1680\2000-\200A\2028\2029\202F\205F\3000]+',' ','g')))>0)
 AND ($2='' OR v.source_id=$2) AND ($3='' OR v.food_id COLLATE "C">$3 COLLATE "C")
 ORDER BY v.food_id COLLATE "C" LIMIT $4`, f.Q, f.Source, f.After, f.Limit+1)
	if err != nil {
		return nil, ErrFoodUnavailable
	}
	defer rows.Close()
	result := []FoodSummary{}
	for rows.Next() {
		var raw []byte
		if rows.Scan(&raw) != nil {
			return nil, ErrFoodUnavailable
		}
		item, err := decodeFoodSummary(raw)
		if err != nil {
			return nil, err
		}
		result = append(result, item)
	}
	if rows.Err() != nil {
		return nil, ErrFoodUnavailable
	}
	return result, nil
}
func (p FoodPostgres) Detail(ctx context.Context, id, version string) (FoodDetail, error) {
	query := `WITH selected AS(SELECT * FROM trainforge_v1.food_versions
 WHERE food_id=$1 AND ($2='' OR version_sha=$2) ORDER BY created_at DESC,version_sha DESC LIMIT 1)
 SELECT ` + foodProjection + `,v.nutrients FROM selected v WHERE ` + foodVisible
	var raw, cells []byte
	err := p.Pool.QueryRow(ctx, query, id, version).Scan(&raw, &cells)
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
	var nutrients []Nutrient
	if json.Unmarshal(cells, &nutrients) != nil {
		return FoodDetail{}, ErrFoodUnavailable
	}
	result := FoodDetail{FoodSummary: item, Nutrients: []FoodCell{}, Notice: foodNotice}
	for _, n := range nutrients {
		if validateState(n) != nil {
			return FoodDetail{}, ErrFoodUnavailable
		}
		var rawText string
		if json.Unmarshal(n.Raw, &rawText) != nil {
			rawText = string(n.Raw)
		}
		result.Nutrients = append(result.Nutrients, FoodCell{n.Column, n.Row, n.Name, n.Unit, n.State, n.Value, n.UpperBound, rawText, n.BasisQuantity, n.BasisUnit, n.Declared, n.Scaling, n.Reasons})
	}
	return result, nil
}
func (p FoodPostgres) Facets(ctx context.Context) (FoodFacets, error) {
	rows, err := p.Pool.Query(ctx, foodLatest+`SELECT v.source_id,v.provenance#>>'{rights,name}',v.name_locale,count(*),
 count(*) FILTER(WHERE v.basis_unit IS NULL) FROM latest v WHERE `+foodVisible+`
 GROUP BY v.source_id,v.provenance#>>'{rights,name}',v.name_locale ORDER BY v.source_id`)
	if err != nil {
		return FoodFacets{}, ErrFoodUnavailable
	}
	defer rows.Close()
	result := FoodFacets{Sources: []FoodSourceCount{}}
	for rows.Next() {
		var source FoodSourceCount
		var unknown int
		if rows.Scan(&source.ID, &source.Name, &source.Locale, &source.Count, &unknown) != nil {
			return result, ErrFoodUnavailable
		}
		result.Sources = append(result.Sources, source)
		result.Total += source.Count
		result.UnknownBasisCount += unknown
	}
	if rows.Err() != nil {
		return result, ErrFoodUnavailable
	}
	return result, nil
}
