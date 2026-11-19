package nutrition

import (
	"bufio"
	"bytes"
	"compress/gzip"
	"crypto/ed25519"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"os"
	"path/filepath"
	"strings"
	"unicode/utf8"
)

const CatalogContract = "trainforge.food-catalog/1"

type CatalogExport struct {
	File     string `json:"file"`
	SHA256   string `json:"sha256"`
	Bytes    int64  `json:"bytes"`
	Rows     int64  `json:"rows"`
	SourceID string `json:"sourceId"`
	License  string `json:"license"`
}
type CatalogSource struct {
	SourceID     string   `json:"sourceId"`
	Name         string   `json:"name"`
	Publisher    string   `json:"publisher"`
	URL          string   `json:"url"`
	LicenseLabel string   `json:"licenseLabel"`
	LicenseURL   string   `json:"licenseUrl"`
	Attribution  string   `json:"attribution"`
	Version      string   `json:"version"`
	Conditions   []string `json:"conditions"`
	Foods        int64    `json:"foods"`
}
type CatalogManifest struct {
	Contract       string           `json:"contract"`
	SchemaVersion  int              `json:"schemaVersion"`
	Version        string           `json:"version"`
	File           string           `json:"file"`
	SHA256         string           `json:"sha256"`
	Bytes          int64            `json:"bytes"`
	DatabaseFile   string           `json:"databaseFile,omitempty"`
	DatabaseSHA256 string           `json:"databaseSha256,omitempty"`
	DatabaseBytes  int64            `json:"databaseBytes,omitempty"`
	Complete       bool             `json:"complete"`
	Fixture        bool             `json:"fixture"`
	MissingSources []string         `json:"missingSources"`
	Counts         map[string]int64 `json:"counts"`
	Sources        []CatalogSource  `json:"sources"`
	Exports        []CatalogExport  `json:"exports"`
	ManifestSHA    string           `json:"-"`
}
type CatalogRow struct {
	Contract      string                `json:"contract"`
	FoodID        string                `json:"foodId"`
	VersionID     string                `json:"versionId"`
	SourceID      string                `json:"sourceId"`
	SourceFoodID  string                `json:"sourceFoodId"`
	SourceVersion string                `json:"sourcePublishedVersion"`
	Name          string                `json:"nameOriginal"`
	Locale        string                `json:"nameLocale"`
	Preparation   *string               `json:"preparation"`
	Basis         Basis                 `json:"basis"`
	Allowed       []string              `json:"allowedOperations"`
	Brand         *string               `json:"brand"`
	Barcodes      []string              `json:"barcodes"`
	Portions      []FoodPortion         `json:"portions"`
	Canonical     []CanonicalFoodCell   `json:"canonicalNutrients"`
	Original      []CatalogOriginalCell `json:"originalNutrients"`
	Provenance    json.RawMessage       `json:"provenance"`
}
type CatalogOriginalCell struct {
	Column        string       `json:"sourceColumnKey"`
	Row           string       `json:"sourceRowKey"`
	Name          string       `json:"nameOriginal"`
	Unit          *string      `json:"unit"`
	State         string       `json:"state"`
	Value         *string      `json:"value"`
	UpperBound    *string      `json:"upperBound"`
	Raw           string       `json:"rawText"`
	BasisQuantity *string      `json:"basisQuantity"`
	BasisUnit     *string      `json:"basisUnit"`
	MethodID      string       `json:"methodId"`
	Scaling       bool         `json:"scalingAllowed"`
	Declared      *ColumnBasis `json:"declaredColumnBasis"`
	Reasons       []string     `json:"reasons"`
}

func readCatalogMetadata(path string, limit int64) ([]byte, error) {
	f, e := os.Open(path)
	if e != nil {
		return nil, errors.New("catalog metadata unavailable")
	}
	defer f.Close()
	stat, e := f.Stat()
	if e != nil || !stat.Mode().IsRegular() || stat.Size() > limit {
		return nil, errors.New("invalid catalog metadata size")
	}
	raw, e := io.ReadAll(io.LimitReader(f, limit+1))
	if e != nil || int64(len(raw)) > limit {
		return nil, errors.New("catalog metadata read failed")
	}
	return raw, nil
}

// Trust is supplied separately by the operator/server configuration. A key file
// shipped inside an untrusted update archive is never a source of trust.
// This verifies only the small signature/manifest, not the multi-GB SQLite file.
func VerifyCatalogManifest(manifestPath, trustPath string) (CatalogManifest, error) {
	var result CatalogManifest
	raw, e := readCatalogMetadata(manifestPath, 2<<20)
	if e != nil {
		return result, e
	}
	var envelope struct {
		KeyID     string `json:"keyId"`
		Payload   string `json:"payload"`
		Signature string `json:"signature"`
	}
	if syncDecode(raw, &envelope) != nil {
		return result, errors.New("invalid catalog envelope")
	}
	trusted, e := readCatalogMetadata(trustPath, 64<<10)
	if e != nil {
		return result, e
	}
	var trust struct {
		Contract string `json:"contract"`
		Keys     []struct {
			KeyID     string `json:"keyId"`
			Algorithm string `json:"algorithm"`
			PublicKey string `json:"publicKey"`
		} `json:"keys"`
	}
	if syncDecode(trusted, &trust) != nil || trust.Contract != "trainforge.food-catalog-trust/1" || len(trust.Keys) < 1 || len(trust.Keys) > 16 {
		return result, errors.New("invalid configured catalog trust")
	}
	message, e := base64.StdEncoding.Strict().DecodeString(envelope.Payload)
	if e != nil {
		return result, errors.New("invalid signed payload")
	}
	signature, e := base64.StdEncoding.Strict().DecodeString(envelope.Signature)
	if e != nil {
		return result, errors.New("invalid catalog signature")
	}
	var key []byte
	for _, candidate := range trust.Keys {
		if candidate.KeyID == envelope.KeyID && candidate.Algorithm == "Ed25519" {
			if key != nil {
				return result, errors.New("ambiguous catalog key")
			}
			key, e = base64.StdEncoding.Strict().DecodeString(candidate.PublicKey)
			if e != nil {
				return result, errors.New("invalid configured public key")
			}
		}
	}
	if len(key) != ed25519.PublicKeySize || !ed25519.Verify(key, message, signature) {
		return result, errors.New("catalog signature not trusted")
	}
	var arbitrary any
	d := json.NewDecoder(bytes.NewReader(message))
	d.UseNumber()
	if uniqueJSON(d) != nil || d.Decode(&arbitrary) != io.EOF {
		return result, errors.New("ambiguous signed catalog payload")
	}
	if json.Unmarshal(message, &result) != nil || result.Contract != CatalogContract || result.SchemaVersion != 1 || (result.File != "catalog.sqlite" && result.File != "catalog.sqlite.gz") || !shaPattern.MatchString(result.Version) || !shaPattern.MatchString(result.SHA256) || result.Bytes < 1 || !result.Complete || result.Fixture || len(result.MissingSources) != 0 {
		return result, errors.New("catalog incomplete, fixture or incompatible")
	}
	if result.File == "catalog.sqlite.gz" && (result.DatabaseFile != "catalog.sqlite" || !shaPattern.MatchString(result.DatabaseSHA256) || result.DatabaseBytes < 1) {
		return result, errors.New("uncompressed catalog identity missing")
	}
	if len(result.Sources) < 1 || len(result.Exports) != len(result.Sources) || len(result.Sources) > 128 {
		return result, errors.New("catalog source coverage missing")
	}
	sources := map[string]CatalogSource{}
	var total int64
	for _, s := range result.Sources {
		if s.SourceID == "" || sources[s.SourceID].SourceID != "" || s.Foods < 1 || !validCitation(s.citation()) || result.Counts[s.SourceID] != s.Foods {
			return result, errors.New("catalog source citation/count invalid")
		}
		sources[s.SourceID] = s
		total += s.Foods
	}
	if result.Counts["foods"] != total {
		return result, errors.New("catalog total coverage mismatch")
	}
	seen := map[string]bool{}
	for _, export := range result.Exports {
		if !filepath.IsLocal(export.File) || filepath.Base(export.File) != export.File || !strings.HasSuffix(export.File, ".jsonl.gz") || !shaPattern.MatchString(export.SHA256) || export.Bytes < 1 || export.Rows != sources[export.SourceID].Foods || seen[export.SourceID] || export.License != sources[export.SourceID].LicenseLabel {
			return result, errors.New("catalog export coverage invalid")
		}
		seen[export.SourceID] = true
	}
	result.ManifestSHA = hash(message)
	return result, nil
}

func (s CatalogSource) citation() Citation {
	return Citation{Name: s.Name, Publisher: s.Publisher, SourceURL: s.URL, LicenseLabel: s.LicenseLabel, LicenseURL: s.LicenseURL, Attribution: s.Attribution, PublishedAt: s.Version, Changes: "Projeção normalizada de dados nutricionais e medidas documentadas; originais preservados separadamente.", Warranty: "Dados de referência sem garantia, endosso ou aprovação clínica.", Conditions: s.Conditions}
}

func verifyCatalogExport(root *os.Root, export CatalogExport) error {
	f, e := root.Open(export.File)
	if e != nil {
		return errors.New("catalog export unavailable")
	}
	defer f.Close()
	stat, e := f.Stat()
	if e != nil || !stat.Mode().IsRegular() || stat.Size() != export.Bytes {
		return errors.New("catalog export size mismatch")
	}
	sum := sha256.New()
	if _, e = io.Copy(sum, f); e != nil || hex.EncodeToString(sum.Sum(nil)) != export.SHA256 {
		return errors.New("catalog export checksum mismatch")
	}
	return nil
}

func walkCatalogExport(root *os.Root, export CatalogExport, each func(CatalogRow, int64) error) error {
	f, e := root.Open(export.File)
	if e != nil {
		return errors.New("catalog export unavailable")
	}
	defer f.Close()
	z, e := gzip.NewReader(f)
	if e != nil {
		return errors.New("catalog export gzip invalid")
	}
	defer z.Close()
	scanner := bufio.NewScanner(z)
	scanner.Buffer(make([]byte, 64<<10), 4<<20)
	var count int64
	for scanner.Scan() {
		count++
		if count > export.Rows {
			return errors.New("catalog export has extra rows")
		}
		var row CatalogRow
		// Forward-compatible descriptive provenance fields are retained as JSON;
		// IDs, composition and the source bound to the export are always checked.
		if e := json.Unmarshal(scanner.Bytes(), &row); e != nil {
			return fmt.Errorf("catalog export %s row %d has invalid JSON: %w", export.File, count, e)
		}
		if row.SourceID != export.SourceID {
			return fmt.Errorf("catalog export %s row %d has mismatched source", export.File, count)
		}
		if e := row.validate(); e != nil {
			return fmt.Errorf("catalog export %s row %d is invalid: %w", export.File, count, e)
		}
		if e = each(row, count); e != nil {
			return e
		}
	}
	if scanner.Err() != nil || count != export.Rows {
		return errors.New("catalog export truncated or count mismatch")
	}
	return nil
}

// Catalog limits are derived from the complete signed exports (2026-11-19 scan of
// 6,702,350 rows: longest OFF name 1,141 runes, portion label 380, documentary
// portion quantity 169 characters) with headroom. User input stays strict.
const (
	catalogNameMaxRunes     = 4000
	catalogPortionTextRunes = 1000
	catalogPortionQuantity  = 512
)

// Catalog source text is evidence, not user input: every valid UTF-8 rune is
// preserved as published, including legacy control bytes from collaborative
// sources (OFF has C0/C1 controls and U+0000). Storage adapters that cannot hold
// a rune keep the exact original separately; see pgStorableText.
func catalogSourceTextValid(text string, min, max int) bool {
	if !utf8.ValidString(text) || strings.TrimSpace(text) != text {
		return false
	}
	length := utf8.RuneCountInString(text)
	return length >= min && length <= max
}

// Source names preserve documented line wrapping from the approved originals.
// User-entered names keep the stricter textValid rules; no value is rewritten.
func catalogSourceNameValid(name string) bool {
	return catalogSourceTextValid(name, 1, catalogNameMaxRunes)
}

// A catalog portion keeps its documentary quantity exactly. Quantities longer than
// the 80-character intake limit stay as evidence but are not selectable for exact
// calculation: intake still uses validSourceFoodPortion.
func validCatalogPortion(p FoodPortion) bool {
	if len(p.Quantity) > catalogPortionQuantity || !decimalPattern.MatchString(p.Quantity) {
		return false
	}
	weight, ok := new(big.Rat).SetString(p.Quantity)
	return ok && weight.Sign() > 0 && textValid(p.ID, 1, 180) &&
		catalogSourceTextValid(p.Label, 1, catalogPortionTextRunes) && (p.Unit == "g" || p.Unit == "ml") &&
		catalogSourceTextValid(p.Condition, 0, catalogPortionTextRunes) && sourceTextValid(p.SourceID, 0, 100)
}

func (r CatalogRow) validate() error {
	if r.Contract != CatalogContract || !foodPattern.MatchString(r.FoodID) || !shaPattern.MatchString(r.VersionID) || !textValid(r.SourceID, 1, 100) || !textValid(r.SourceFoodID, 1, 256) || !catalogSourceNameValid(r.Name) || r.SourceVersion == "" || r.Locale == "" || !basisValid(r.Basis) || len(r.Original) > 1024 || len(r.Canonical) > 1024 {
		return ErrFoodQuery
	}
	if r.FoodID != "food:"+hash([]byte(r.SourceID+"\x00"+r.SourceFoodID)) {
		return errors.New("catalog identity is not source-derived")
	}
	allowed := map[string]bool{}
	for _, op := range r.Allowed {
		if op != "food_catalog" && op != "food_composition" && op != "food_quantity_scale" {
			return ErrFoodQuery
		}
		allowed[op] = true
	}
	if !allowed["food_catalog"] || !allowed["food_composition"] {
		return ErrFoodQuery
	}
	seen := map[string]bool{}
	for _, cell := range r.Original {
		if cell.Column == "" || cell.Name == "" || len(cell.Raw) > 1024 {
			return ErrFoodQuery
		}
		if e := validateCatalogCell(cell); e != nil {
			return e
		}
	}
	for _, n := range r.Canonical {
		if n.NutrientID == "" || n.Unit == "" || n.MethodID == "" || n.Column == "" {
			return ErrFoodQuery
		}
		if n.Primary {
			if seen[n.NutrientID] {
				return ErrFoodQuery
			}
			seen[n.NutrientID] = true
		}
		if n.State == "numeric" {
			if n.Value == nil {
				return ErrFoodQuery
			}
			if _, e := number(*n.Value); e != nil {
				return e
			}
		} else if n.Value != nil {
			return ErrFoodQuery
		}
	}
	for _, p := range r.Portions {
		if !validCatalogPortion(p) {
			return ErrFoodQuery
		}
	}
	for _, code := range r.Barcodes {
		// Original identifiers may contain invalid check digits in collaborative
		// sources. Preserve them as evidence, but only valid GTINs are searchable.
		if !textValid(code, 1, 128) {
			return ErrFoodQuery
		}
	}
	return nil
}
func validateCatalogCell(c CatalogOriginalCell) error {
	// The global source contract explicitly recognizes these additional markers;
	// the legacy parser and historical snapshots retain their previous meaning.
	marker := strings.ToLower(strings.TrimSpace(c.Raw))
	if c.State == "missing" && (marker == "na" || marker == "n/a" || marker == "nan" || marker == "null" || marker == "not available") && c.Value == nil && c.UpperBound == nil {
		return nil
	}
	if c.State == "trace" && (marker == "traço" || marker == "traços" || marker == "traco" || marker == "tracos") && c.Value == nil && c.UpperBound == nil {
		return nil
	}
	if c.State == "numeric" || c.State == "less_than" {
		bound := strings.HasPrefix(strings.TrimSpace(c.Raw), "<")
		if bound != (c.State == "less_than") {
			return ErrFoodQuery
		}
		token := strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(c.Raw), "<"))
		token = strings.ReplaceAll(token, ",", ".")
		expected, e := number(token)
		if e != nil {
			return e
		}
		value := c.Value
		if bound {
			value = c.UpperBound
			if c.Value != nil {
				return ErrFoodQuery
			}
		} else if c.UpperBound != nil {
			return ErrFoodQuery
		}
		if value == nil {
			return ErrFoodQuery
		}
		actual, e := number(*value)
		if e != nil || actual.Cmp(expected) != 0 {
			return ErrFoodQuery
		}
		return nil
	}
	raw, _ := json.Marshal(c.Raw)
	return validateState(Nutrient{Column: c.Column, Name: c.Name, Unit: c.Unit, State: c.State, Value: c.Value, UpperBound: c.UpperBound, Raw: raw})
}
