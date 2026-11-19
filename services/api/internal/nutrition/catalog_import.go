package nutrition

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"os"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CatalogImportResult struct {
	ArtifactSHA  string `json:"artifactSha256"`
	Version      string `json:"version"`
	ExpectedRows int64  `json:"expectedRows"`
	StagedRows   int64  `json:"stagedRows"`
	Active       bool   `json:"active"`
}

func catalogAnnotation(row CatalogRow) json.RawMessage {
	codes := []string{}
	for _, code := range row.Barcodes {
		if validGTIN(code) {
			codes = append(codes, code)
		}
	}
	annotation := map[string]any{"contract": CatalogContract, "brand": row.Brand, "barcodes": codes, "sourceBarcodes": row.Barcodes, "portions": row.Portions, "canonicalNutrients": row.Canonical, "sourceProvenance": row.Provenance}
	originals := map[string]string{}
	if _, original := pgStorableText(row.Name); original != "" {
		originals["nameOriginal"] = original
	}
	if row.Brand != nil {
		brand, original := pgStorableText(*row.Brand)
		if original != "" {
			annotation["brand"] = brand
			originals["brand"] = original
		}
	}
	if len(originals) > 0 {
		annotation["storageOriginalsBase64"] = originals
		annotation["storageSubstitution"] = "U+0000->U+FFFD"
	}
	value, _ := json.Marshal(annotation)
	return value
}

func legacyNameEquivalent(approved, exported string) bool {
	return approved != exported && exported != "" && strings.TrimSpace(approved) == exported
}

// PostgreSQL text/jsonb cannot store U+0000. The column receives U+FFFD and the
// exact original UTF-8 is kept as base64 in the release annotation, so no source
// byte is lost and food/version identities stay those of the signed export.
func pgStorableText(s string) (stored, originalBase64 string) {
	if !strings.ContainsRune(s, 0) {
		return s, ""
	}
	return strings.ReplaceAll(s, "\x00", "�"), base64.StdEncoding.EncodeToString([]byte(s))
}
func catalogNutrients(row CatalogRow) []Nutrient {
	result := make([]Nutrient, 0, len(row.Original))
	for _, cell := range row.Original {
		raw, _ := json.Marshal(cell.Raw)
		rowKey := cell.Row
		if rowKey == "" {
			rowKey = row.SourceFoodID
		}
		reasons := cell.Reasons
		if reasons == nil {
			reasons = []string{}
		}
		result = append(result, Nutrient{SourceContract: CatalogContract, Column: cell.Column, Row: rowKey, Name: cell.Name, Unit: cell.Unit, State: cell.State, Value: cell.Value, UpperBound: cell.UpperBound, Raw: raw, BasisQuantity: cell.BasisQuantity, BasisUnit: cell.BasisUnit, Declared: cell.Declared, Scaling: cell.Scaling, Reasons: reasons})
	}
	return result
}

// VerifyFoodCatalogExports streams every signed export without touching a DB.
// It also checks counts, units/states and canonical identity constraints.
func VerifyFoodCatalogExports(manifest CatalogManifest, exportsDir string) error {
	root, e := os.OpenRoot(exportsDir)
	if e != nil {
		return errors.New("catalog exports directory unavailable")
	}
	defer root.Close()
	for _, export := range manifest.Exports {
		if e = verifyCatalogExport(root, export); e != nil {
			return e
		}
		if e = walkCatalogExport(root, export, func(CatalogRow, int64) error { return nil }); e != nil {
			return e
		}
	}
	return nil
}

// StageFoodCatalog uses bounded CopyFrom batches. Each batch commits progress
// and immutable versions together; a restart can resume after committed rows.
// No stage row becomes selectable until ActivateFoodCatalog succeeds.
func StageFoodCatalog(ctx context.Context, pool *pgxpool.Pool, manifest CatalogManifest, exportsDir string) (CatalogImportResult, error) {
	result := CatalogImportResult{ArtifactSHA: manifest.SHA256, Version: manifest.Version, ExpectedRows: manifest.Counts["foods"]}
	if pool == nil || manifest.ManifestSHA == "" || result.ExpectedRows < 1 || result.ExpectedRows > 2147483647 {
		return result, ErrFoodQuery
	}
	root, e := os.OpenRoot(exportsDir)
	if e != nil {
		return result, errors.New("catalog exports directory unavailable")
	}
	defer root.Close()
	// Check all compressed artifacts before any write. Recheck after ingestion so
	// replacement while streaming cannot activate an unverified source.
	for _, export := range manifest.Exports {
		if e = verifyCatalogExport(root, export); e != nil {
			return result, e
		}
	}
	if e = catalogStart(ctx, pool, manifest); e != nil {
		return result, e
	}
	sources := map[string]CatalogSource{}
	for _, source := range manifest.Sources {
		sources[source.SourceID] = source
	}
	for _, export := range manifest.Exports {
		var imported int64
		var complete bool
		if pool.QueryRow(ctx, `SELECT imported_rows,complete FROM trainforge_v1.food_catalog_import_progress WHERE artifact_sha=$1 AND source_id=$2`, manifest.SHA256, export.SourceID).Scan(&imported, &complete) != nil {
			return result, ErrFoodUnavailable
		}
		if complete {
			continue
		}
		batch := make([]CatalogRow, 0, 500)
		flush := func() error {
			if len(batch) == 0 {
				return nil
			}
			e := catalogStageBatch(ctx, pool, manifest, sources[export.SourceID], imported, batch)
			if e == nil {
				imported += int64(len(batch))
				batch = batch[:0]
			}
			return e
		}
		e = walkCatalogExport(root, export, func(row CatalogRow, index int64) error {
			if index <= imported {
				return nil
			}
			batch = append(batch, row)
			if len(batch) >= 500 {
				return flush()
			}
			return nil
		})
		if e != nil {
			return result, e
		}
		if e = flush(); e != nil {
			return result, e
		}
		if e = verifyCatalogExport(root, export); e != nil {
			return result, e
		}
		if _, e = pool.Exec(ctx, `UPDATE trainforge_v1.food_catalog_import_progress SET complete=true WHERE artifact_sha=$1 AND source_id=$2 AND imported_rows=expected_rows`, manifest.SHA256, export.SourceID); e != nil {
			return result, ErrFoodUnavailable
		}
	}
	if pool.QueryRow(ctx, `SELECT staged_rows,status='active' FROM trainforge_v1.food_catalog_releases WHERE artifact_sha=$1`, manifest.SHA256).Scan(&result.StagedRows, &result.Active) != nil {
		return result, ErrFoodUnavailable
	}
	return result, nil
}

func catalogStart(ctx context.Context, pool *pgxpool.Pool, m CatalogManifest) error {
	tx, e := pool.Begin(ctx)
	if e != nil {
		return ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(2026111706)); e != nil {
		return ErrFoodUnavailable
	}
	var present bool
	if tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.food_import_batches WHERE artifact_sha=$1)`, m.SHA256).Scan(&present) != nil {
		return ErrFoodUnavailable
	}
	if !present {
		if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_import_batches(artifact_sha,bundle_id,manifest_sha,review_sha,imported_foods) VALUES($1,$2,$3,$3,$4)`, m.SHA256, "TF-CATALOG-"+m.Version, m.ManifestSHA, m.Counts["foods"]); e != nil {
			return errors.New("catalog batch registration unavailable")
		}
	} else {
		var same bool
		if tx.QueryRow(ctx, `SELECT manifest_sha=$2 AND review_sha=$2 AND imported_foods=$3 FROM trainforge_v1.food_import_batches WHERE artifact_sha=$1`, m.SHA256, m.ManifestSHA, m.Counts["foods"]).Scan(&same) != nil || !same {
			return errors.New("catalog artifact already registered with different review")
		}
	}
	if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_catalog_releases(artifact_sha,version,manifest_sha,status,expected_rows) VALUES($1,$2,$3,'staging',$4) ON CONFLICT DO NOTHING`, m.SHA256, m.Version, m.ManifestSHA, m.Counts["foods"]); e != nil {
		return ErrFoodUnavailable
	}
	for _, s := range m.Sources {
		urls, _ := json.Marshal([]string{s.URL})
		if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.sources(id,name,publisher,urls) VALUES($1,$2,$3,$4) ON CONFLICT(id) DO NOTHING`, s.SourceID, s.Name, s.Publisher, urls); e != nil {
			return errors.New("catalog source registration unavailable")
		}
		if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_catalog_import_progress(artifact_sha,source_id,expected_rows) VALUES($1,$2,$3) ON CONFLICT DO NOTHING`, m.SHA256, s.SourceID, s.Foods); e != nil {
			return ErrFoodUnavailable
		}
	}
	if tx.Commit(ctx) != nil {
		return ErrFoodUnavailable
	}
	return nil
}

func catalogStageBatch(ctx context.Context, pool *pgxpool.Pool, m CatalogManifest, source CatalogSource, after int64, foods []CatalogRow) error {
	tx, e := pool.Begin(ctx)
	if e != nil {
		return ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	var current int64
	var active bool
	if tx.QueryRow(ctx, `SELECT p.imported_rows,r.status='active' FROM trainforge_v1.food_catalog_import_progress p JOIN trainforge_v1.food_catalog_releases r USING(artifact_sha) WHERE p.artifact_sha=$1 AND p.source_id=$2 FOR UPDATE OF p,r`, m.SHA256, source.SourceID).Scan(&current, &active) != nil {
		return ErrFoodUnavailable
	}
	if active || current != after {
		return ErrEntryConflict
	}
	_, e = tx.Exec(ctx, `CREATE TEMP TABLE food_catalog_stage(food_id text,version_sha text,source_id text,source_food_id text,source_row_key text,name_original text,preparation text,basis_quantity text,basis_unit text,nutrients jsonb,provenance jsonb,source_published_version text,name_locale text,allowed_operations text[],metadata jsonb) ON COMMIT DROP`)
	if e != nil {
		return ErrFoodUnavailable
	}
	rows := make([][]any, 0, len(foods))
	for _, food := range foods {
		nutrients, _ := json.Marshal(catalogNutrients(food))
		provenance, _ := json.Marshal(map[string]any{"reviewSha256": m.ManifestSHA, "rights": source.citation(), "clinicalApproval": false, "sourceContract": CatalogContract, "sourceOriginal": food.Provenance})
		annotation := catalogAnnotation(food)
		name, _ := pgStorableText(food.Name)
		if bytes.Contains(nutrients, []byte(`\u0000`)) || bytes.Contains(provenance, []byte(`\u0000`)) || bytes.Contains(annotation, []byte(`\u0000`)) || (food.Preparation != nil && strings.ContainsRune(*food.Preparation, 0)) {
			return errors.New("catalog row has U+0000 outside name/brand; no storage mapping defined")
		}
		rows = append(rows, []any{food.FoodID, food.VersionID, food.SourceID, food.SourceFoodID, food.SourceFoodID, name, food.Preparation, food.Basis.Quantity, food.Basis.Unit, nutrients, provenance, food.SourceVersion, food.Locale, food.Allowed, annotation})
	}
	columns := []string{"food_id", "version_sha", "source_id", "source_food_id", "source_row_key", "name_original", "preparation", "basis_quantity", "basis_unit", "nutrients", "provenance", "source_published_version", "name_locale", "allowed_operations", "metadata"}
	if _, e = tx.CopyFrom(ctx, pgx.Identifier{"food_catalog_stage"}, columns, pgx.CopyFromRows(rows)); e != nil {
		return errors.New("catalog staging copy failed")
	}
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,source_food_id,source_row_key,name_original,preparation,basis_quantity,basis_unit,nutrients,provenance,source_published_version,name_locale,allowed_operations)
 SELECT food_id,version_sha,source_id,source_food_id,source_row_key,name_original,preparation,basis_quantity::numeric,basis_unit,nutrients,provenance,source_published_version,name_locale,allowed_operations FROM food_catalog_stage ON CONFLICT(food_id,version_sha) DO NOTHING`)
	if e != nil {
		return errors.New("catalog immutable version insert failed")
	}
	// A legacy version may gain annotations, but its source identity, values and
	// original snapshot remain unchanged. A colliding identity is never accepted.
	var conflicts int
	if tx.QueryRow(ctx, `SELECT count(*) FROM food_catalog_stage s JOIN trainforge_v1.food_versions v USING(food_id,version_sha)
 WHERE v.owner_id IS NOT NULL OR v.source_id<>s.source_id OR v.source_food_id<>s.source_food_id
 OR (v.name_original<>s.name_original AND v.provenance->>'sourceContract' IS NOT DISTINCT FROM $1)
 OR v.basis_quantity IS DISTINCT FROM s.basis_quantity::numeric OR v.basis_unit IS DISTINCT FROM s.basis_unit
 OR (v.provenance->>'sourceContract'=$1 AND (v.nutrients<>s.nutrients OR v.provenance->'sourceOriginal'<>s.provenance->'sourceOriginal'))`, CatalogContract).Scan(&conflicts) != nil || conflicts != 0 {
		return errors.New("catalog version conflicts with immutable source")
	}
	// Pre-catalog (legacy) versions keep their approved name byte-for-byte. The
	// catalog builder trimmed edge whitespace (Ciqual "Pain bis…" ends in U+00A0),
	// so only that exact difference is tolerated; the legacy row is not rewritten.
	legacy, e := tx.Query(ctx, `SELECT v.name_original,s.name_original FROM food_catalog_stage s JOIN trainforge_v1.food_versions v USING(food_id,version_sha)
 WHERE v.name_original<>s.name_original AND v.provenance->>'sourceContract' IS DISTINCT FROM $1`, CatalogContract)
	if e != nil {
		return ErrFoodUnavailable
	}
	for legacy.Next() {
		var approved, exported string
		if legacy.Scan(&approved, &exported) != nil || !legacyNameEquivalent(approved, exported) {
			legacy.Close()
			return errors.New("catalog version conflicts with immutable source")
		}
	}
	if legacy.Close(); legacy.Err() != nil {
		return ErrFoodUnavailable
	}
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_batch_versions(artifact_sha,food_id,version_sha) SELECT $1,food_id,version_sha FROM food_catalog_stage ON CONFLICT DO NOTHING`, m.SHA256)
	if e != nil {
		return ErrFoodUnavailable
	}
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_catalog_annotations(artifact_sha,food_id,version_sha,metadata) SELECT $1,food_id,version_sha,metadata FROM food_catalog_stage ON CONFLICT DO NOTHING`, m.SHA256)
	if e != nil {
		return ErrFoodUnavailable
	}
	if _, e = tx.Exec(ctx, `UPDATE trainforge_v1.food_catalog_import_progress SET imported_rows=imported_rows+$3 WHERE artifact_sha=$1 AND source_id=$2`, m.SHA256, source.SourceID, len(foods)); e != nil {
		return ErrFoodUnavailable
	}
	if _, e = tx.Exec(ctx, `UPDATE trainforge_v1.food_catalog_releases SET staged_rows=staged_rows+$2 WHERE artifact_sha=$1`, m.SHA256, len(foods)); e != nil {
		return ErrFoodUnavailable
	}
	if tx.Commit(ctx) != nil {
		return ErrFoodUnavailable
	}
	return nil
}

func ActivateFoodCatalog(ctx context.Context, pool *pgxpool.Pool, m CatalogManifest) (CatalogImportResult, error) {
	result := CatalogImportResult{ArtifactSHA: m.SHA256, Version: m.Version, ExpectedRows: m.Counts["foods"]}
	if pool == nil || m.ManifestSHA == "" {
		return result, ErrFoodQuery
	}
	tx, e := pool.Begin(ctx)
	if e != nil {
		return result, ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(2026111706)); e != nil {
		return result, ErrFoodUnavailable
	}
	var expected int64
	var manifestSHA string
	var pending int
	if tx.QueryRow(ctx, `SELECT expected_rows,staged_rows,manifest_sha,status='active' FROM trainforge_v1.food_catalog_releases WHERE artifact_sha=$1 FOR UPDATE`, m.SHA256).Scan(&expected, &result.StagedRows, &manifestSHA, &result.Active) != nil {
		return result, ErrFoodUnavailable
	}
	if manifestSHA != m.ManifestSHA || expected != result.ExpectedRows || result.StagedRows != expected {
		return result, errors.New("catalog release is incomplete")
	}
	if tx.QueryRow(ctx, `SELECT count(*) FROM trainforge_v1.food_catalog_import_progress WHERE artifact_sha=$1 AND (NOT complete OR imported_rows<>expected_rows)`, m.SHA256).Scan(&pending) != nil || pending != 0 {
		return result, errors.New("catalog source verification incomplete")
	}
	var linked int64
	if tx.QueryRow(ctx, `SELECT count(*) FROM trainforge_v1.food_batch_versions WHERE artifact_sha=$1`, m.SHA256).Scan(&linked) != nil || linked != expected {
		return result, errors.New("catalog duplicate identities/count mismatch")
	}
	if _, e = tx.Exec(ctx, `UPDATE trainforge_v1.food_catalog_releases SET status='active',activated_at=coalesce(activated_at,clock_timestamp()) WHERE artifact_sha=$1`, m.SHA256); e != nil || tx.Commit(ctx) != nil {
		return result, ErrFoodUnavailable
	}
	result.Active = true
	return result, nil
}
