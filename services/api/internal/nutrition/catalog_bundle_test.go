package nutrition

import (
	"bytes"
	"compress/gzip"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func signedCatalogFixture(t *testing.T) (CatalogManifest, string, string, string, CatalogRow) {
	t.Helper()
	return signedCatalogFixtureWith(t, 'f', nil)
}

// signedCatalogFixtureWith lets a test publish a distinct signed artifact (its
// manifest SHA/version derive from seed) with a modified source row.
func signedCatalogFixtureWith(t *testing.T, seed byte, mutate func(*CatalogRow)) (CatalogManifest, string, string, string, CatalogRow) {
	t.Helper()
	dir := t.TempDir()
	pub, key, e := ed25519.GenerateKey(rand.Reader)
	if e != nil {
		t.Fatal(e)
	}
	row := CatalogRow{Contract: CatalogContract, FoodID: "food:" + string(makeHex('c', 64)), VersionID: string(makeHex('d', 64)), SourceID: "AL-CATALOG-FIXTURE", SourceFoodID: "1", SourceVersion: "test-2026", Name: "Disposable rice catalog fixture", Locale: "pt-BR", Basis: Basis{ptr("100"), ptr("g")}, Allowed: []string{"food_catalog", "food_composition", "food_quantity_scale"}, Original: []CatalogOriginalCell{{Column: "fixture:protein", Name: "Proteína", Unit: ptr("g"), State: "numeric", Value: ptr("2.5"), Raw: "2.5", BasisQuantity: ptr("100"), BasisUnit: ptr("g"), MethodID: "fixture-laboratory", Scaling: true}}, Canonical: []CanonicalFoodCell{{NutrientID: "protein_g", Unit: "g", Value: ptr("2.5"), State: "numeric", MethodID: "fixture-laboratory", Primary: true, BasisQuantity: ptr("100"), BasisUnit: ptr("g"), Column: "fixture:protein"}}, Barcodes: []string{}, Portions: []FoodPortion{}, Provenance: json.RawMessage(`{"fixture":true}`)}
	row.FoodID = "food:" + hash([]byte(row.SourceID+"\x00"+row.SourceFoodID))
	row.Portions = []FoodPortion{{ID: "fixture-source-serving", Label: "Documented\nserving", Quantity: "14.000000000000002", Unit: "g", Condition: "Original\tlabel", SourceID: row.SourceID}}
	if mutate != nil {
		mutate(&row)
		row.FoodID = "food:" + hash([]byte(row.SourceID+"\x00"+row.SourceFoodID))
	}
	file := filepath.Join(dir, "AL-CATALOG-FIXTURE.jsonl.gz")
	stream, e := os.Create(file)
	if e != nil {
		t.Fatal(e)
	}
	z := gzip.NewWriter(stream)
	if json.NewEncoder(z).Encode(row) != nil || z.Close() != nil || stream.Close() != nil {
		t.Fatal("fixture gzip")
	}
	compressed, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	source := CatalogSource{SourceID: row.SourceID, Name: "Disposable source", Publisher: "SQL fixture", URL: "https://example.invalid/source", LicenseLabel: "CC0-1.0", LicenseURL: "https://creativecommons.org/publicdomain/zero/1.0/", Attribution: "Disposable integration fixture, never production data.", Version: row.SourceVersion, Conditions: []string{"Testing only; no clinical approval."}, Foods: 1}
	m := CatalogManifest{Contract: CatalogContract, SchemaVersion: 1, Version: string(makeHex(seed-1, 64)), File: "catalog.sqlite", SHA256: string(makeHex(seed, 64)), Bytes: 123, Complete: true, Counts: map[string]int64{"foods": 1, row.SourceID: 1}, Sources: []CatalogSource{source}, Exports: []CatalogExport{{File: filepath.Base(file), SHA256: hash(compressed), Bytes: int64(len(compressed)), Rows: 1, SourceID: row.SourceID, License: source.LicenseLabel}}}
	message, _ := json.Marshal(m)
	envelope, _ := json.Marshal(map[string]string{"keyId": "test-key", "payload": base64.StdEncoding.EncodeToString(message), "signature": base64.StdEncoding.EncodeToString(ed25519.Sign(key, message))})
	manifestPath := filepath.Join(dir, "manifest.json")
	trustPath := filepath.Join(dir, "configured-trust.json")
	trust, _ := json.Marshal(map[string]any{"contract": "trainforge.food-catalog-trust/1", "keys": []map[string]string{{"keyId": "test-key", "algorithm": "Ed25519", "publicKey": base64.StdEncoding.EncodeToString(pub)}}})
	if os.WriteFile(manifestPath, envelope, 0600) != nil || os.WriteFile(trustPath, trust, 0600) != nil {
		t.Fatal("fixture manifest")
	}
	verified, e := VerifyCatalogManifest(manifestPath, trustPath)
	if e != nil {
		t.Fatal("signed fixture", e)
	}
	return verified, manifestPath, trustPath, dir, row
}
func TestCatalogManifestSignatureTrustAndStreamingExport(t *testing.T) {
	m, path, trust, dir, _ := signedCatalogFixture(t)
	if VerifyFoodCatalogExports(m, dir) != nil {
		t.Fatal("valid export rejected")
	}
	raw, _ := os.ReadFile(path)
	var envelope map[string]string
	_ = json.Unmarshal(raw, &envelope)
	envelope["payload"] = base64.StdEncoding.EncodeToString([]byte(`{"contract":"forged"}`))
	raw, _ = json.Marshal(envelope)
	_ = os.WriteFile(path, raw, 0600)
	if _, e := VerifyCatalogManifest(path, trust); e == nil {
		t.Fatal("forged payload accepted")
	}
	if os.WriteFile(filepath.Join(dir, m.Exports[0].File), []byte("damaged"), 0600) != nil {
		t.Fatal("corrupt fixture")
	}
	if VerifyFoodCatalogExports(m, dir) == nil {
		t.Fatal("damaged export accepted")
	}
}
func TestCatalogNewMarkersPreserveOriginalTokens(t *testing.T) {
	for _, c := range []CatalogOriginalCell{{State: "missing", Raw: "NA"}, {State: "trace", Raw: "Traço"}, {State: "numeric", Raw: "2,5", Value: ptr("2.5")}, {State: "less_than", Raw: "< 0,1", UpperBound: ptr("0.1")}} {
		if validateCatalogCell(c) != nil {
			t.Fatal("new source marker rejected", c.Raw)
		}
	}
	if validateCatalogCell(CatalogOriginalCell{State: "numeric", Raw: "NA", Value: ptr("0")}) == nil {
		t.Fatal("unknown became zero")
	}
	if validateState(Nutrient{State: "missing", Raw: json.RawMessage(`"NA"`)}) == nil {
		t.Fatal("legacy meaning changed implicitly")
	}
}

func TestCatalogTACOExportExampleRemainsImportable(t *testing.T) {
	raw, e := os.ReadFile(filepath.Join("..", "..", "..", "..", "content", "food_catalog", "example-taco.json"))
	if e != nil {
		t.Fatal("versioned source example unavailable")
	}
	var row CatalogRow
	if json.Unmarshal(raw, &row) != nil || row.validate() != nil {
		t.Fatal("official TACO projection disagrees with server contract")
	}
	for _, n := range catalogNutrients(row) {
		if validateState(n) != nil {
			t.Fatal("source token cannot be read after import", n.Column)
		}
	}
}

func TestCatalogSourceNamesPreserveApprovedDocumentWhitespace(t *testing.T) {
	_, _, _, _, row := signedCatalogFixture(t)
	// Exact approved Ciqual sourceFoodId10002, legacy JSONL line4. The source
	// contains this line wrap; changing it would also invalidate its old version.
	const original = "Calmar ou calamar ou encornet, à la romaine\n(beignet), préemballé"
	row.Name = original
	foodID, versionID := row.FoodID, row.VersionID
	if row.validate() != nil || row.Name != original || row.FoodID != foodID || row.VersionID != versionID {
		t.Fatal("approved source name or identity was rejected/rewritten")
	}
	if validateOwn(OwnFoodInput{Name: original, Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{{Name: "Protein", Unit: "g", Value: ptr("1")}}}) == nil {
		t.Fatal("source whitespace exception reached a private declaration")
	}
	// Shapes found in the complete OFF export (2026-11-19 scan): C1 mojibake
	// (U+0090/U+009C), C0 controls, U+0000 and a 1,141-rune name. All preserved.
	for _, name := range []string{"Documented\r\nsource", "Documented\ttab", "Mojibake\u0090name", "Legacy\u009cbyte", "Null\x00byte", "Vertical\vtab", "Escape\x1bcontrol", "Delete\x7fcontrol", strings.Repeat("é", 1141), strings.Repeat("é", catalogNameMaxRunes)} {
		row.Name = name
		if row.validate() != nil || validateOwn(OwnFoodInput{Name: name, Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{{Name: "Protein", Unit: "g", Value: ptr("1")}}}) == nil {
			t.Fatalf("source name %q rejected or its exception reached private input", name[:min(len(name), 20)])
		}
	}
	for _, name := range []string{"", "\n", "\t", " leading", "trailing\n", string([]byte{0xff}), strings.Repeat("é", catalogNameMaxRunes+1)} {
		row.Name = name
		if row.validate() == nil {
			t.Fatal("invalid source name accepted")
		}
	}
}

func TestCatalogNULIsStoredLosslesslyForPostgres(t *testing.T) {
	_, _, _, _, row := signedCatalogFixture(t)
	row.Name, row.Brand = "Leite\x00integral", ptr("Marca\x00X")
	foodID, versionID := row.FoodID, row.VersionID
	if row.validate() != nil {
		t.Fatal("published source name with U+0000 rejected")
	}
	stored, original := pgStorableText(row.Name)
	if strings.ContainsRune(stored, 0) || stored != "Leite�integral" || original == "" {
		t.Fatal("U+0000 not mapped for PostgreSQL text")
	}
	var annotation struct {
		Brand     string            `json:"brand"`
		Originals map[string]string `json:"storageOriginalsBase64"`
	}
	raw := catalogAnnotation(row)
	if bytes.Contains(raw, []byte(`\u0000`)) || json.Unmarshal(raw, &annotation) != nil || annotation.Brand != "Marca�X" {
		t.Fatal("annotation is not storable in jsonb")
	}
	for field, want := range map[string]string{"nameOriginal": row.Name, "brand": *row.Brand} {
		decoded, e := base64.StdEncoding.DecodeString(annotation.Originals[field])
		if e != nil || string(decoded) != want {
			t.Fatalf("%s original bytes lost", field)
		}
	}
	if row.FoodID != foodID || row.VersionID != versionID {
		t.Fatal("identity rewritten")
	}
	if clean, original := pgStorableText("Arroz"); clean != "Arroz" || original != "" || bytes.Contains(catalogAnnotation(CatalogRow{Name: "Arroz"}), []byte("storageOriginals")) {
		t.Fatal("ordinary text gained a storage substitution")
	}
}

func TestCatalogSourcePortionsPreserveOriginalPrecisionWithoutChangingPrivateInputs(t *testing.T) {
	m, _, _, dir, row := signedCatalogFixture(t)
	if VerifyFoodCatalogExports(m, dir) != nil || row.validate() != nil {
		t.Fatal("documented exact source portion was rejected")
	}
	portion := row.Portions[0]
	if validFoodPortion(portion) {
		t.Fatal("source exception reached personal portion validation")
	}
	for _, quantity := range []string{"0", "-1", "NaN", "1,5", strings.Repeat("1", catalogPortionQuantity+1)} {
		copy := row
		copy.Portions = append([]FoodPortion{}, row.Portions...)
		copy.Portions[0].Quantity = quantity
		if copy.validate() == nil {
			t.Fatal("invalid or unbounded source portion accepted")
		}
	}
	// OFF documentary dízimas (95 and 169 characters) and a 380-rune label are kept
	// in the catalog, but never become selectable intake portions.
	for _, p := range []FoodPortion{
		{ID: "off-serving-95", Label: "94,33", Quantity: "94." + strings.Repeat("3", 92), Unit: "g"},
		{ID: "off-serving-169", Label: "20,83", Quantity: "20." + strings.Repeat("3", 166), Unit: "g"},
		{ID: "off-serving-label", Label: strings.Repeat("a", 380), Quantity: "15", Unit: "ml"},
	} {
		copy := row
		copy.Portions = []FoodPortion{p}
		if copy.validate() != nil || validSourceFoodPortion(p) {
			t.Fatalf("documentary portion %s rejected by catalog or accepted for intake", p.ID)
		}
	}
	row.Portions[0].Label = strings.Repeat("a", catalogPortionTextRunes+1)
	if row.validate() == nil {
		t.Fatal("unbounded source label accepted")
	}
}
