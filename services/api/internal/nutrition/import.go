package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func Import(ctx context.Context, pool *pgxpool.Pool, l *Loaded) (ImportResult, error) {
	result := ImportResult{Total: l.manifest.Output.Rows, ArtifactSHA: l.manifest.Output.SHA}
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return result, errors.New("food import transaction unavailable")
	}
	defer tx.Rollback(ctx)
	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(2026102202)); err != nil {
		return result, errors.New("food import lock unavailable")
	}
	var prior int
	var priorReview, priorManifest, priorID string
	err = tx.QueryRow(ctx, "SELECT imported_foods,review_sha,manifest_sha,bundle_id FROM trainforge_v1.food_import_batches WHERE artifact_sha=$1", result.ArtifactSHA).Scan(&prior, &priorReview, &priorManifest, &priorID)
	exists := err == nil
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return result, errors.New("food import batch lookup failed")
	}
	if exists && (prior != result.Total || priorReview != l.manifest.Review.SHA || priorManifest != l.ManifestSHA || priorID != l.manifest.BundleID) {
		return result, errors.New("food batch review/integrity mismatch")
	}
	if !exists {
		if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.food_import_batches(artifact_sha,bundle_id,manifest_sha,review_sha,imported_foods) VALUES($1,$2,$3,$4,$5)",
			result.ArtifactSHA, l.manifest.BundleID, l.ManifestSHA, l.manifest.Review.SHA, result.Total); err != nil {
			return result, errors.New("food batch insert failed")
		}
	}
	for _, source := range l.review.Sources {
		urls, _ := json.Marshal([]string{source.SourceURL})
		if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.sources(id,name,publisher,urls) VALUES($1,$2,$3,$4::jsonb) ON CONFLICT(id) DO NOTHING", source.ID, source.Name, source.Publisher, string(urls)); err != nil {
			return result, errors.New("food source insert failed")
		}
		var same bool
		if tx.QueryRow(ctx, "SELECT name=$2 AND publisher=$3 AND urls=$4::jsonb FROM trainforge_v1.sources WHERE id=$1", source.ID, source.Name, source.Publisher, string(urls)).Scan(&same) != nil || !same {
			return result, errors.New("existing food source conflicts with review")
		}
	}
	err = l.Walk(func(food Food, version string) error {
		nutrients, _ := json.Marshal(food.Nutrients)
		provenance, _ := json.Marshal(food.Provenance)
		tag, err := tx.Exec(ctx, `INSERT INTO trainforge_v1.food_versions(
   food_id,version_sha,source_id,source_food_id,source_row_key,name_original,name_pt,preparation,
   basis_quantity,basis_unit,nutrients,provenance,source_published_version,name_locale,allowed_operations)
   VALUES($1,$2,$3,$4,$5,$6,NULL,NULL,$7::numeric,$8,$9::jsonb,$10::jsonb,$11,$12,$13)
   ON CONFLICT(food_id,version_sha) DO NOTHING`,
			food.ID, version, food.SourceID, food.SourceFoodID, food.Provenance.Rows[0], food.Name, food.Basis.Quantity, food.Basis.Unit,
			string(nutrients), string(provenance), food.SourceVersion, food.Locale, food.Allowed)
		if err != nil {
			return errors.New("food version insert failed")
		}
		if tag.RowsAffected() == 1 {
			if exists {
				return errors.New("registered food batch lost a version")
			}
			result.Inserted++
		} else {
			var same bool
			err = tx.QueryRow(ctx, `SELECT source_id=$3 AND source_food_id=$4 AND source_row_key=$5 AND owner_id IS NULL
    AND name_original=$6 AND name_pt IS NULL AND preparation IS NULL
    AND basis_quantity IS NOT DISTINCT FROM $7::numeric AND basis_unit IS NOT DISTINCT FROM $8::text
    AND nutrients=$9::jsonb AND provenance=$10::jsonb AND source_published_version=$11 AND name_locale=$12
    AND allowed_operations=$13::text[] FROM trainforge_v1.food_versions WHERE food_id=$1 AND version_sha=$2`,
				food.ID, version, food.SourceID, food.SourceFoodID, food.Provenance.Rows[0], food.Name, food.Basis.Quantity, food.Basis.Unit,
				string(nutrients), string(provenance), food.SourceVersion, food.Locale, food.Allowed).Scan(&same)
			if err != nil || !same {
				return errors.New("immutable food version changed")
			}
			result.Unchanged++
		}
		if exists {
			var linked bool
			if tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM trainforge_v1.food_batch_versions WHERE artifact_sha=$1 AND food_id=$2 AND version_sha=$3)", result.ArtifactSHA, food.ID, version).Scan(&linked) != nil || !linked {
				return errors.New("registered food batch link missing")
			}
		} else if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.food_batch_versions(artifact_sha,food_id,version_sha) VALUES($1,$2,$3)", result.ArtifactSHA, food.ID, version); err != nil {
			return errors.New("food batch version link failed")
		}
		return nil
	})
	if err != nil {
		return result, err
	}
	var linked int
	if tx.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_batch_versions WHERE artifact_sha=$1", result.ArtifactSHA).Scan(&linked) != nil || linked != result.Total {
		return result, errors.New("food batch coverage mismatch")
	}
	if err = tx.Commit(ctx); err != nil {
		return result, errors.New("food import commit failed")
	}
	return result, nil
}
