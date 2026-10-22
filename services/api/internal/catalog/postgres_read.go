package catalog

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CatalogPostgres struct{ Pool *pgxpool.Pool }

const projection = `jsonb_build_object(
 'id',v.asset_id,'versionId',v.version_sha,'kind',v.kind,'title',v.title,'locale',v.locale,
 'sourcePublishedVersion',v.source_published_version,
 'source',jsonb_build_object('id',s.id,'name',s.name,'publisher',s.publisher,'urls',s.urls),
 'authors',v.payload->'authors','rights',v.payload->'rights',
 'audience',jsonb_build_object(
  'population',CASE jsonb_typeof(v.payload#>'{audience,population}') WHEN 'array' THEN v.payload#>'{audience,population}' WHEN 'string' THEN jsonb_build_array(v.payload#>>'{audience,population}') ELSE 'null'::jsonb END,
  'environment',CASE jsonb_typeof(v.payload#>'{audience,environment}') WHEN 'array' THEN v.payload#>'{audience,environment}' WHEN 'string' THEN jsonb_build_array(v.payload#>>'{audience,environment}') ELSE 'null'::jsonb END,
  'supportRequired',v.payload#>'{audience,supportRequired}',
  'supportSource',CASE jsonb_typeof(v.payload#>'{audience,supportSource}') WHEN 'string' THEN v.payload#>'{audience,supportSource}' ELSE 'null'::jsonb END),
 'requirements',jsonb_build_object('category',v.payload#>'{content,category}','equipment',v.payload#>'{content,equipment}','modality',v.payload#>'{content,modality}')
)`
const permitted = `'catalog_metadata'=ANY(v.allowed_operations)
 AND v.payload#>>'{rights,operationGrants,catalog_metadata}'='allowed'
 AND v.payload#>>'{review,state}'='reviewed'
 AND v.payload#>>'{review,rightsVerified}'='true'
 AND v.payload#>>'{review,fidelityChecked}'='true'
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.content_withdrawals w WHERE w.asset_id=v.asset_id AND w.version_sha=v.version_sha)
 AND ($2='consultation' OR (
 'guided_practice'=ANY(v.allowed_operations)
 AND v.payload#>>'{rights,operationGrants,guided_practice}'='allowed'
 AND v.payload#>>'{review,instructionSufficient}'='true'
 AND v.payload#>>'{review,safetyUseReviewed}'='true'))`

func (p CatalogPostgres) List(ctx context.Context, f Filters) ([]CatalogItem, error) {
	// Select the latest version first, then apply permission/withdrawal. Never silently
	// resurrect an older version when the newest one was withdrawn or lost permission.
	query := `WITH latest AS (
 SELECT DISTINCT ON(asset_id) asset_id,version_sha,kind,title,locale,source_id,source_published_version,allowed_operations,payload
 FROM trainforge_v1.content_versions WHERE kind=ANY($1)
 ORDER BY asset_id,created_at DESC,version_sha DESC)
 SELECT ` + projection + ` FROM latest v JOIN trainforge_v1.sources s ON s.id=v.source_id
 WHERE ` + permitted + `
 AND ($3='' OR position(lower($3) in lower(coalesce(v.title,'')))>0)
 AND ($4='' OR (jsonb_typeof(v.payload#>'{audience,environment}')='string' AND lower(v.payload#>>'{audience,environment}')=lower($4)) OR EXISTS(SELECT 1 FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(v.payload#>'{audience,environment}')='array' THEN v.payload#>'{audience,environment}' ELSE '[]'::jsonb END) e WHERE lower(e)=lower($4)))
 AND ($5='' OR (jsonb_typeof(v.payload#>'{audience,population}')='string' AND lower(v.payload#>>'{audience,population}')=lower($5)) OR EXISTS(SELECT 1 FROM jsonb_array_elements_text(CASE WHEN jsonb_typeof(v.payload#>'{audience,population}')='array' THEN v.payload#>'{audience,population}' ELSE '[]'::jsonb END) e WHERE lower(e)=lower($5)))
 AND ($6='' OR lower(v.payload#>>'{content,modality}')=lower($6))
 AND ($7='' OR EXISTS(SELECT 1 FROM jsonb_array_elements(CASE WHEN jsonb_typeof(v.payload#>'{content,equipment}')='array' THEN v.payload#>'{content,equipment}' ELSE '[]'::jsonb END) e WHERE lower(e->>'name')=lower($7)))
 AND ($8='' OR lower(v.payload#>>'{content,category,name}')=lower($8))
 AND ($9='' OR v.asset_id COLLATE "C">$9 COLLATE "C")
 ORDER BY v.asset_id COLLATE "C" LIMIT $10`
	rows, err := p.Pool.Query(ctx, query, f.Kinds, f.Mode, f.Q, f.Environment, f.Population, f.Modality, f.Equipment, f.Category, f.After, f.Limit+1)
	if err != nil {
		return nil, ErrDependency
	}
	defer rows.Close()
	items := []CatalogItem{}
	for rows.Next() {
		var raw []byte
		if rows.Scan(&raw) != nil {
			return nil, ErrDependency
		}
		item, err := decodeMetadata(raw)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if rows.Err() != nil {
		return nil, ErrDependency
	}
	return items, nil
}
func (p CatalogPostgres) Detail(ctx context.Context, kinds []string, id, version, mode string) (CatalogItem, error) {
	query := `WITH selected AS (
 SELECT asset_id,version_sha,kind,title,locale,source_id,source_published_version,allowed_operations,payload
 FROM trainforge_v1.content_versions WHERE kind=ANY($1) AND asset_id=$3 AND ($4='' OR version_sha=$4)
 ORDER BY created_at DESC,version_sha DESC LIMIT 1)
 SELECT ` + projection + ` FROM selected v JOIN trainforge_v1.sources s ON s.id=v.source_id WHERE ` + permitted
	var raw []byte
	err := p.Pool.QueryRow(ctx, query, kinds, mode, id, version).Scan(&raw)
	if errors.Is(err, pgx.ErrNoRows) {
		return CatalogItem{}, ErrMissing
	}
	if err != nil {
		return CatalogItem{}, ErrDependency
	}
	return decodeMetadata(raw)
}

func (p CatalogPostgres) Facets(ctx context.Context) (CatalogFacets, error) {
	query := `WITH latest AS (
 SELECT DISTINCT ON(asset_id) asset_id,version_sha,kind,payload,allowed_operations
 FROM trainforge_v1.content_versions
 WHERE kind=ANY($1) ORDER BY asset_id,created_at DESC,version_sha DESC),
 visible AS (SELECT v.asset_id,v.version_sha,v.kind,v.payload,v.allowed_operations FROM latest v WHERE ` + permitted + `)
 SELECT jsonb_build_object(
 'movementCount',(SELECT count(*) FROM visible WHERE kind='movement'),
 'programCount',(SELECT count(*) FROM visible WHERE kind IN ('program','collection')),
 'unknownEnvironmentCount',(SELECT count(*) FROM visible WHERE payload#>'{audience,environment}' IS NULL OR jsonb_typeof(payload#>'{audience,environment}') NOT IN ('array','string') OR payload#>'{audience,environment}' IN ('null'::jsonb,'[]'::jsonb,'""'::jsonb)),
 'unknownPopulationCount',(SELECT count(*) FROM visible WHERE payload#>'{audience,population}' IS NULL OR jsonb_typeof(payload#>'{audience,population}') NOT IN ('array','string') OR payload#>'{audience,population}' IN ('null'::jsonb,'[]'::jsonb,'""'::jsonb)),
 'equipment',coalesce((SELECT jsonb_agg(name ORDER BY name) FROM (SELECT DISTINCT e->>'name' AS name FROM visible, jsonb_array_elements(CASE WHEN jsonb_typeof(payload#>'{content,equipment}')='array' THEN payload#>'{content,equipment}' ELSE '[]'::jsonb END) e WHERE coalesce(e->>'name','')<>'') vals),'[]'::jsonb),
 'categories',coalesce((SELECT jsonb_agg(name ORDER BY name) FROM (SELECT DISTINCT payload#>>'{content,category,name}' AS name FROM visible WHERE coalesce(payload#>>'{content,category,name}','')<>'') vals),'[]'::jsonb),
 'modalities',coalesce((SELECT jsonb_agg(name ORDER BY name) FROM (SELECT DISTINCT payload#>>'{content,modality}' AS name FROM visible WHERE coalesce(payload#>>'{content,modality}','')<>'') vals),'[]'::jsonb),
 'environments',coalesce((SELECT jsonb_agg(name ORDER BY name) FROM (SELECT DISTINCT name FROM visible,jsonb_array_elements_text(CASE jsonb_typeof(payload#>'{audience,environment}') WHEN 'array' THEN payload#>'{audience,environment}' WHEN 'string' THEN jsonb_build_array(payload#>>'{audience,environment}') ELSE '[]'::jsonb END) name WHERE name<>'') vals),'[]'::jsonb),
 'populations',coalesce((SELECT jsonb_agg(name ORDER BY name) FROM (SELECT DISTINCT name FROM visible,jsonb_array_elements_text(CASE jsonb_typeof(payload#>'{audience,population}') WHEN 'array' THEN payload#>'{audience,population}' WHEN 'string' THEN jsonb_build_array(payload#>>'{audience,population}') ELSE '[]'::jsonb END) name WHERE name<>'') vals),'[]'::jsonb)
 )`
	var raw []byte
	if p.Pool.QueryRow(ctx, query, []string{"movement", "program", "collection"}, "consultation").Scan(&raw) != nil {
		return CatalogFacets{}, ErrDependency
	}
	var facets CatalogFacets
	if json.Unmarshal(raw, &facets) != nil {
		return facets, ErrDependency
	}
	return facets, nil
}
