package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func ptr(s string) *string { return &s }

type fixture struct {
	root     string
	manifest FoodManifest
	review   Review
	food     Food
}

func fixtureFile(t *testing.T, root, path string, body []byte) Artifact {
	t.Helper()
	target := filepath.Join(root, filepath.FromSlash(path))
	if err := os.MkdirAll(filepath.Dir(target), 0700); err != nil {
		t.Fatal("fixture directory")
	}
	if err := os.WriteFile(target, body, 0600); err != nil {
		t.Fatal("fixture write")
	}
	return Artifact{Path: path, SHA: hash(body)}
}
func fixtureJSON(t *testing.T, root, path string, v any) Artifact {
	t.Helper()
	raw, err := json.Marshal(v)
	if err != nil {
		t.Fatal("fixture JSON")
	}
	return fixtureFile(t, root, path, raw)
}
func newFixture(t *testing.T, code string) *fixture {
	t.Helper()
	f := &fixture{root: t.TempDir()}
	original := fixtureFile(t, f.root, "content/local/original.fixture", []byte("isolated source fixture"))
	prepared := fixtureFile(t, f.root, "content/local/prepared.fixture", []byte("isolated prepared fixture"))
	receipt := fixtureJSON(t, f.root, "content/local/receipt.fixture", map[string]any{"status": 200})
	cite := Citation{Name: "Fixture only", Publisher: "Fixture", SourceURL: "https://example.test/fixture", LicenseLabel: "Fixture only", LicenseURL: "https://example.test/license", Attribution: "Fixture not runtime", PublishedAt: "2025-01-01", Changes: "Fixture", Warranty: "Fixture", Conditions: []string{"Fixture"}}
	source := ReviewedSource{Citation: cite, ID: "AL-CIQUAL-2025", Version: "2025", SnapshotSHA: original.SHA, PreparedSHA: prepared.SHA, Rights: true, Fidelity: true, Operations: map[string]string{}}
	for _, op := range operations {
		source.Operations[op] = "allowed"
	}
	f.review = Review{Contract: "trainforge.food-review/1", Stage: "reviewed_source_operations", Scope: "isolated_development_food_consultation", Reviewer: "isolated test fixture", Sources: []ReviewedSource{source}, Evidence: []Artifact{original}}
	review := fixtureJSON(t, f.root, "content/manifests/review.json", f.review)
	column := ColumnSpec{ID: "AL-CIQUAL-2025:fixture:10", Header: "Fixture nutrient (g)", Unit: ptr("g"), Kind: "nutrient"}
	dictionary := fixtureJSON(t, f.root, "content/local/dictionary.json", map[string]any{"contract": "trainforge.food-staging/1", "sources": []any{map[string]any{"sourceId": source.ID, "columnsByTable": map[string]any{"fixture": []ColumnSpec{column}}}}})
	preflight := fixtureJSON(t, f.root, "docs/preflight.json", map[string]any{"contract": "trainforge.food-staging/1", "localManifest": dictionary, "sources": []any{map[string]any{"sourceId": source.ID, "inputs": []Artifact{prepared, original, receipt}}}})
	row := "AL-CIQUAL-2025:fixture:4"
	f.food = Food{Schema: "1.0.0", ID: "food:" + hash([]byte(source.ID+"\x00"+code)), SourceID: source.ID, SourceFoodID: code, SourceVersion: source.Version, Name: "Fixture raw", Locale: "fr", Basis: Basis{ptr("100"), ptr("g")}, Allowed: append([]string{}, operations...),
		Nutrients:  []Nutrient{{Column: column.ID, Row: row, Name: column.Header, Unit: ptr("g"), State: "numeric", Value: ptr("0"), Raw: json.RawMessage(`"0"`), BasisQuantity: ptr("100"), BasisUnit: ptr("g"), Scaling: true, Reasons: []string{}}},
		Provenance: FoodProvenance{ReviewSHA: review.SHA, SnapshotSHA: original.SHA, PreparedSHA: prepared.SHA, Rows: []string{row}, Excluded: map[string]int{}, Rights: cite, PreparationRule: "Fixture", PortionRule: "Fixture"}}
	f.manifest = FoodManifest{Schema: "1.0.0", Stage: "approved_food_consultation_operations", Scope: f.review.Scope, BundleID: "fixture-" + code, Review: review, Preflight: preflight}
	f.saveFood(t)
	return f
}
func (f *fixture) saveFood(t *testing.T) {
	t.Helper()
	raw, err := json.Marshal(f.food)
	if err != nil {
		t.Fatal("fixture food")
	}
	body := append(raw, '\n')
	output := fixtureFile(t, f.root, "content/local/foods.jsonl", body)
	output.Rows = 1
	f.manifest.Output = output
	fixtureJSON(t, f.root, "content/manifests/approved.json", f.manifest)
}
func (f *fixture) load(t *testing.T) *Loaded {
	t.Helper()
	loaded, err := Load(f.root, "content/manifests/approved.json")
	if err != nil {
		t.Fatalf("valid fixture rejected: %v", err)
	}
	t.Cleanup(func() { loaded.Close() })
	return loaded
}
func TestReviewedFoodRejectsSourceAndStateMutations(t *testing.T) {
	cases := map[string]func(*Food){
		"unknown parsed value":         func(f *Food) { f.Nutrients[0].Value = ptr("50") },
		"trace cannot become zero":     func(f *Food) { f.Nutrients[0].Raw = json.RawMessage(`"Tr"`); f.Nutrients[0].State = "trace" },
		"factor cannot be nutrient":    func(f *Food) { f.Nutrients[0].Name = "Facteur de Jones" },
		"false base":                   func(f *Food) { f.Basis.Unit = ptr("ml") },
		"translated name not reviewed": func(f *Food) { f.NamePT = ptr("invented") },
		"provider code is identity":    func(f *Food) { f.SourceFoodID = "different" },
		"foreign source row":           func(f *Food) { f.Nutrients[0].Row = "AL-OTHER:fixture:4" },
		"changed nutrient unit":        func(f *Food) { f.Nutrients[0].Unit = ptr("mg") },
		"clinical assertion":           func(f *Food) { f.Provenance.Clinical = true },
		"raw null":                     func(f *Food) { f.Nutrients[0].Raw = json.RawMessage("null") },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			f := newFixture(t, "source")
			mutate(&f.food)
			f.saveFood(t)
			l, err := Load(f.root, "content/manifests/approved.json")
			if l != nil {
				l.Close()
			}
			if err == nil {
				t.Fatal("unsafe food accepted")
			}
		})
	}
}
func TestReviewedFoodPreservesBoundsAndScientificDecimal(t *testing.T) {
	f := newFixture(t, "source")
	n := &f.food.Nutrients[0]
	n.Raw = json.RawMessage(`"<0,01"`)
	n.State = "less_than"
	n.Value = nil
	n.UpperBound = ptr("0.01")
	n.Scaling = false
	n.Reasons = []string{"no_exact_numeric_quantity"}
	f.food.Allowed = append([]string{}, operations[:2]...)
	f.saveFood(t)
	f.load(t)
	n.Raw = json.RawMessage(`"1e-5"`)
	n.State = "numeric"
	n.Value = ptr("0.00001")
	n.UpperBound = nil
	n.Scaling = true
	n.Reasons = []string{}
	f.food.Allowed = append([]string{}, operations...)
	f.saveFood(t)
	loaded := f.load(t)
	if loaded.DryRun().Total != 1 {
		t.Fatal("dry-run did not validate source row")
	}
}
func TestReviewedFoodRejectsUnapprovedManifestAndChangedInputs(t *testing.T) {
	f := newFixture(t, "source")
	f.manifest.Stage = "candidate"
	fixtureJSON(t, f.root, "content/manifests/approved.json", f.manifest)
	if l, err := Load(f.root, "content/manifests/approved.json"); err == nil {
		l.Close()
		t.Fatal("candidate promoted")
	}
	f.manifest.Stage = "approved_food_consultation_operations"
	f.saveFood(t)
	fixtureFile(t, f.root, "content/local/original.fixture", []byte("changed source"))
	if l, err := Load(f.root, "content/manifests/approved.json"); err == nil {
		l.Close()
		t.Fatal("changed source accepted")
	}
}
func TestReviewedFoodRejectsPathEscapeDuplicateAndOversizedLine(t *testing.T) {
	f := newFixture(t, "source")
	for _, path := range []string{"../outside", filepath.Join(f.root, "absolute.json")} {
		if l, err := Load(f.root, path); err == nil {
			l.Close()
			t.Fatal("external manifest accepted")
		}
	}
	raw, _ := json.Marshal(f.food)
	body := append(append(append([]byte{}, raw...), '\n'), append(raw, '\n')...)
	f.manifest.Output = fixtureFile(t, f.root, "content/local/foods.jsonl", body)
	f.manifest.Output.Rows = 2
	fixtureJSON(t, f.root, "content/manifests/approved.json", f.manifest)
	if l, err := Load(f.root, "content/manifests/approved.json"); err == nil {
		l.Close()
		t.Fatal("duplicate identity accepted")
	}
	f.manifest.Output = fixtureFile(t, f.root, "content/local/foods.jsonl", []byte(strings.Repeat(" ", (2<<20)+1)+"\n"))
	f.manifest.Output.Rows = 1
	fixtureJSON(t, f.root, "content/manifests/approved.json", f.manifest)
	if l, err := Load(f.root, "content/manifests/approved.json"); err == nil {
		l.Close()
		t.Fatal("oversized line accepted")
	}
}
func TestReviewedFoodRejectsMissingSourceGrant(t *testing.T) {
	f := newFixture(t, "source")
	f.review.Sources[0].Operations["food_composition"] = "pending"
	f.manifest.Review = fixtureJSON(t, f.root, "content/manifests/review.json", f.review)
	f.food.Provenance.ReviewSHA = f.manifest.Review.SHA
	f.saveFood(t)
	if l, err := Load(f.root, "content/manifests/approved.json"); err == nil {
		l.Close()
		t.Fatal("pending source grant accepted")
	}
}
func TestFoodPostgresIdempotencyRollbackAndReadonlyRuntime(t *testing.T) {
	dsn := os.Getenv("TF_FOOD_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("isolated PostgreSQL food fixture database not requested")
	}
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || !strings.HasPrefix(cfg.Database, "trainforge_v1_food_test_") {
		t.Fatal("fixture target refused")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal("fixture database unavailable")
	}
	defer pool.Close()
	runtimeCfg, err := pgx.ParseConfig(os.Getenv("TF_FOOD_TEST_RUNTIME_URL"))
	if err != nil || runtimeCfg.Database != cfg.Database || runtimeCfg.Host != cfg.Host || runtimeCfg.Port != cfg.Port {
		t.Fatal("runtime fixture target refused")
	}
	runtime, err := pgxpool.New(ctx, os.Getenv("TF_FOOD_TEST_RUNTIME_URL"))
	if err != nil {
		t.Fatal("fixture runtime unavailable")
	}
	defer runtime.Close()
	f := newFixture(t, "source")
	loaded := f.load(t)
	first, err := Import(ctx, pool, loaded)
	if err != nil || first.Inserted != 1 {
		t.Fatalf("first food import failed: %v", err)
	}
	again, err := Import(ctx, pool, loaded)
	if err != nil || again.Inserted != 0 || again.Unchanged != 1 {
		t.Fatalf("food import not idempotent: %v", err)
	}
	var count int
	if runtime.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_versions").Scan(&count) != nil || count != 1 {
		t.Fatal("runtime cannot read actual imported fixture")
	}
	for _, query := range []string{
		"UPDATE trainforge_v1.food_versions SET name_original='changed fixture'",
		"DELETE FROM trainforge_v1.food_versions",
		"UPDATE trainforge_v1.food_import_batches SET bundle_id='changed fixture'",
	} {
		_, err = runtime.Exec(ctx, query)
		var pgerr *pgconn.PgError
		if !errors.As(err, &pgerr) || pgerr.Code != "42501" {
			t.Fatal("runtime gained editorial write permission")
		}
	}
	second := newFixture(t, "rollback")
	secondLoaded := second.load(t)
	handle, err := os.OpenFile(filepath.Join(second.root, "content/local/foods.jsonl"), os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal("fixture mutation failed")
	}
	_, _ = handle.WriteString("\n")
	handle.Close()
	if _, err = Import(ctx, pool, secondLoaded); err == nil {
		t.Fatal("changed artifact committed")
	}
	if pool.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_versions").Scan(&count) != nil || count != 1 {
		t.Fatal("failed food import left partial food rows")
	}
	if pool.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_import_batches").Scan(&count) != nil || count != 1 {
		t.Fatal("failed food import left batch")
	}
	// A migration writer tamper must not be hidden by ON CONFLICT DO NOTHING on reimport.
	if _, err = pool.Exec(ctx, "UPDATE trainforge_v1.food_versions SET nutrients='[]'::jsonb"); err != nil {
		t.Fatal("fixture tamper failed")
	}
	if _, err = Import(ctx, pool, loaded); err == nil {
		t.Fatal("immutable source version tamper ignored")
	}
}
