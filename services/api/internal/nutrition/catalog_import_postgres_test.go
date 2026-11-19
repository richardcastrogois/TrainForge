package nutrition

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Real OFF shapes (2026-11-19 full scan): U+0000 in name/brand, C1 control and a
// documentary 95-character portion quantity. PostgreSQL cannot store U+0000.
func TestFoodCatalogPostgresPreservesUnstorableSourceTextLosslessly(t *testing.T) {
	ctx, writer, runtime := mealPools(t)
	name, brand := "Leite\x00integral \u0090OFF", "Marca\x00X"
	longQuantity := "94." + strings.Repeat("3", 92)
	m, _, _, dir, row := signedCatalogFixtureWith(t, '9', func(r *CatalogRow) {
		r.SourceFoodID, r.VersionID, r.Name, r.Brand = "nul-shape", string(makeHex('7', 64)), name, &brand
		r.Portions = append(r.Portions, FoodPortion{ID: "off-serving-95", Label: "94,333", Quantity: longQuantity, Unit: "g"})
	})
	if _, e := StageFoodCatalog(ctx, writer, m, dir); e != nil {
		t.Fatal("stage source text with U+0000", e)
	}
	if active, e := ActivateFoodCatalog(ctx, writer, m); e != nil || !active.Active {
		t.Fatal("activate", e)
	}
	var stored string
	var meta []byte
	if e := writer.QueryRow(ctx, `SELECT v.name_original,a.metadata::text FROM trainforge_v1.food_versions v JOIN trainforge_v1.food_catalog_annotations a USING(food_id,version_sha) WHERE v.food_id=$1 AND v.version_sha=$2 AND a.artifact_sha=$3`, row.FoodID, row.VersionID, m.SHA256).Scan(&stored, &meta); e != nil {
		t.Fatal("stored row", e)
	}
	var annotation struct {
		Brand     string            `json:"brand"`
		Originals map[string]string `json:"storageOriginalsBase64"`
		Portions  []FoodPortion     `json:"portions"`
	}
	if stored != "Leite�integral \u0090OFF" || json.Unmarshal(meta, &annotation) != nil || annotation.Brand != "Marca�X" {
		t.Fatal("PostgreSQL columns did not receive the documented substitution")
	}
	for field, want := range map[string]string{"nameOriginal": name, "brand": brand} {
		if decoded, e := base64.StdEncoding.DecodeString(annotation.Originals[field]); e != nil || string(decoded) != want {
			t.Fatalf("exact %s original lost", field)
		}
	}
	if len(annotation.Portions) != 2 || annotation.Portions[1].Quantity != longQuantity {
		t.Fatal("documentary portion quantity changed")
	}
	_, p := mealLogin(t, ctx, runtime, "nul-catalog-consumer")
	in := EntryInput{FoodID: row.FoodID, FoodVersion: row.VersionID, Quantity: longQuantity, Unit: "g", OccurredAt: "2026-11-19T10:00:00Z", Timezone: "UTC", QuantityEvidence: "measured", CalculationAlgorithm: CanonicalAlgorithm, Portion: &PortionSelection{FoodPortion: annotation.Portions[1], Count: "1"}}
	body, _ := json.Marshal(in)
	if _, _, e := (NutritionStore{runtime}).Mutate(ctx, p, "create-entry", "", newID(), body); e == nil {
		t.Fatal("over-long documentary portion became selectable intake")
	}
}

// Real case (2026-11-19 local import): approved Ciqual "Pain bis (à la farine T80
// ou T110)" ends in U+00A0; the catalog export carries the trimmed name with the
// same food/version identity. Only that edge-whitespace difference is accepted.
func TestFoodCatalogPostgresLegacyNameEdgeWhitespaceOnly(t *testing.T) {
	ctx, writer, _ := mealPools(t)
	for i, c := range []struct {
		legacy string
		ok     bool
	}{{"Pain bis (à la farine T80 ou T110) ", true}, {"Pain complet (à la farine T150)", false}} {
		seed := byte('4' + i)
		m, _, _, dir, row := signedCatalogFixtureWith(t, seed, func(r *CatalogRow) {
			r.SourceFoodID, r.VersionID, r.Name = "legacy-name-"+string(seed), string(makeHex(seed-2, 64)), "Pain bis (à la farine T80 ou T110)"
		})
		if _, e := writer.Exec(ctx, `INSERT INTO trainforge_v1.sources(id,name,publisher,urls) VALUES($1,'Disposable source','SQL fixture','[]') ON CONFLICT(id) DO NOTHING`, row.SourceID); e != nil {
			t.Fatal(e)
		}
		if _, e := writer.Exec(ctx, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,source_food_id,source_row_key,name_original,basis_quantity,basis_unit,nutrients,provenance) VALUES($1,$2,$3,$4,$4,$5,100,'g','[]','{"legacy":true}')`, row.FoodID, row.VersionID, row.SourceID, row.SourceFoodID, c.legacy); e != nil {
			t.Fatal(e)
		}
		_, e := StageFoodCatalog(ctx, writer, m, dir)
		if (e == nil) != c.ok {
			t.Fatalf("legacy name %q: stage error %v", c.legacy, e)
		}
		var kept string
		if writer.QueryRow(ctx, `SELECT name_original FROM trainforge_v1.food_versions WHERE food_id=$1 AND version_sha=$2`, row.FoodID, row.VersionID).Scan(&kept) != nil || kept != c.legacy {
			t.Fatal("approved legacy name was rewritten")
		}
	}
}

func TestFoodCatalogPostgresStagingActivationAndCanonicalSnapshot(t *testing.T) {
	ctx, writer, runtime := mealPools(t)
	m, _, _, dir, row := signedCatalogFixture(t)
	staged, e := StageFoodCatalog(ctx, writer, m, dir)
	if e != nil || staged.Active || staged.StagedRows != 1 {
		t.Fatal("chunk stage", e, staged)
	}
	reader := FoodPostgres{runtime}
	if _, e = reader.Detail(ctx, row.FoodID, row.VersionID); !errors.Is(e, ErrFoodMissing) {
		t.Fatal("unpublished stage visible", e)
	}
	if again, e := StageFoodCatalog(ctx, writer, m, dir); e != nil || again.StagedRows != 1 || again.Active {
		t.Fatal("stage resume duplicated rows", e)
	}
	wrong := m
	wrong.ManifestSHA = string(makeHex('a', 64))
	if _, e = ActivateFoodCatalog(ctx, writer, wrong); e == nil {
		t.Fatal("changed review activated")
	}
	active, e := ActivateFoodCatalog(ctx, writer, m)
	if e != nil || !active.Active {
		t.Fatal("activate verified artifact", e)
	}
	food, e := reader.Detail(ctx, row.FoodID, row.VersionID)
	if e != nil || len(food.CanonicalNutrients) != 1 || food.CanonicalNutrients[0].NutrientID != "protein_g" {
		t.Fatal("active annotations missing", e)
	}
	_, p := mealLogin(t, ctx, runtime, "global-catalog-consumer")
	in := EntryInput{FoodID: row.FoodID, FoodVersion: row.VersionID, Quantity: "50", Unit: "g", OccurredAt: "2026-11-17T10:00:00Z", Timezone: "UTC", QuantityEvidence: "measured", CalculationAlgorithm: CanonicalAlgorithm}
	body, _ := json.Marshal(in)
	result, _, e := (NutritionStore{runtime}).Mutate(ctx, p, "create-entry", "", newID(), body)
	var entry Entry
	if e != nil || json.Unmarshal(result, &entry) != nil || len(entry.Calculation.Nutrients) != 1 || entry.Calculation.Nutrients[0].Value == nil || *entry.Calculation.Nutrients[0].Value != "1.25" {
		t.Fatal("canonical server calculation", e)
	}
	if len(food.Portions) != 1 || food.Portions[0] != row.Portions[0] {
		t.Fatal("documented source portion snapshot changed during import")
	}
	in.Quantity = row.Portions[0].Quantity
	in.Portion = &PortionSelection{FoodPortion: row.Portions[0], Count: "1"}
	body, _ = json.Marshal(in)
	result, _, e = (NutritionStore{runtime}).Mutate(ctx, p, "create-entry", "", newID(), body)
	if e != nil || json.Unmarshal(result, &entry) != nil || entry.Quantity != in.Quantity || entry.Calculation.Nutrients[0].Exact == nil || *entry.Calculation.Nutrients[0].Exact != "7000000000000001/20000000000000000" {
		t.Fatal("PostgreSQL rounded a documented source portion", e)
	}
	// A newer, registered staging version must not eclipse this active version.
	stageSHA := string(makeHex('1', 64))
	stageVersion := string(makeHex('2', 64))
	nextSHA := string(makeHex('3', 64))
	if _, e = writer.Exec(ctx, `INSERT INTO trainforge_v1.food_import_batches(artifact_sha,bundle_id,manifest_sha,review_sha,imported_foods) VALUES($1,'unpublished-fixture',$2,$2,1)`, stageSHA, stageVersion); e != nil {
		t.Fatal(e)
	}
	if _, e = writer.Exec(ctx, `INSERT INTO trainforge_v1.food_catalog_releases(artifact_sha,version,manifest_sha,status,expected_rows) VALUES($1,$2,$2,'staging',1)`, stageSHA, stageVersion); e != nil {
		t.Fatal(e)
	}
	if _, e = writer.Exec(ctx, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,source_food_id,source_row_key,name_original,preparation,basis_quantity,basis_unit,nutrients,provenance,source_published_version,name_locale,allowed_operations)
 SELECT food_id,$3,source_id,source_food_id,source_row_key,'Unpublished newer fixture',preparation,basis_quantity,basis_unit,nutrients,provenance,source_published_version,name_locale,allowed_operations FROM trainforge_v1.food_versions WHERE food_id=$1 AND version_sha=$2`, row.FoodID, row.VersionID, nextSHA); e != nil {
		t.Fatal(e)
	}
	if _, e = writer.Exec(ctx, `INSERT INTO trainforge_v1.food_batch_versions(artifact_sha,food_id,version_sha) VALUES($1,$2,$3)`, stageSHA, row.FoodID, nextSHA); e != nil {
		t.Fatal(e)
	}
	if latest, e := reader.Detail(ctx, row.FoodID, ""); e != nil || latest.VersionID != row.VersionID {
		t.Fatal("staging eclipsed active version", e)
	}
	if list, e := reader.List(ctx, FoodFilters{Q: "Disposable rice", Limit: 20}); e != nil || len(list) != 1 || list[0].VersionID != row.VersionID {
		t.Fatal("staging eclipsed list", e)
	}
	// Corruption on disk cannot be accepted as another import of an active row.
	if os.WriteFile(filepath.Join(dir, m.Exports[0].File), []byte("corrupted"), 0600) != nil {
		t.Fatal("fixture corruption")
	}
	if _, e = StageFoodCatalog(ctx, writer, m, dir); e == nil {
		t.Fatal("changed artifact bytes accepted")
	}
}
