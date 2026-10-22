// Package nutrition imports source-backed food references, without prescribing diets.
package nutrition

import (
	"bytes"
	"encoding/json"
	"errors"
	"math/big"
	"net/url"
	"reflect"
	"regexp"
	"strconv"
	"strings"
)

var shaPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)
var foodPattern = regexp.MustCompile(`^food:[a-f0-9]{64}$`)
var decimalPattern = regexp.MustCompile(`^[+-]?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]{1,3})?$`)
var faHeader = regexp.MustCompile(`(?i)/\s*100\s*g?\s*FA\b`)
var operations = []string{"food_catalog", "food_composition", "food_quantity_scale"}

type Citation struct {
	Name         string   `json:"name"`
	Publisher    string   `json:"publisher"`
	SourceURL    string   `json:"sourceUrl"`
	LicenseLabel string   `json:"licenseLabel"`
	LicenseURL   string   `json:"licenseUrl"`
	Attribution  string   `json:"attribution"`
	PublishedAt  string   `json:"publishedAt"`
	Changes      string   `json:"changes"`
	Warranty     string   `json:"warrantyNotice"`
	Conditions   []string `json:"conditions"`
}
type ReviewedSource struct {
	Citation
	ID          string            `json:"sourceId"`
	Version     string            `json:"sourceVersion"`
	SnapshotSHA string            `json:"snapshotSha256"`
	PreparedSHA string            `json:"preparedSha256"`
	Rights      bool              `json:"rightsVerified"`
	Fidelity    bool              `json:"fidelityChecked"`
	Operations  map[string]string `json:"operations"`
}
type Artifact struct {
	Path string `json:"path"`
	SHA  string `json:"sha256"`
	Rows int    `json:"rows"`
}
type GroupPolicy struct {
	Known   []string `json:"knownGroups"`
	Alcohol []string `json:"alcoholGroups"`
}
type ColumnSpec struct {
	ID       string       `json:"id"`
	Header   string       `json:"headerOriginal"`
	Unit     *string      `json:"unit" extensions:"x-nullable"`
	Kind     string       `json:"kind"`
	Declared *ColumnBasis `json:"columnBasisDeclaration"`
}
type Review struct {
	Contract string           `json:"contract"`
	Stage    string           `json:"stage"`
	Scope    string           `json:"scope"`
	Reviewer string           `json:"reviewer"`
	Clinical bool             `json:"clinicalApproval"`
	Sources  []ReviewedSource `json:"sources"`
	Evidence []Artifact       `json:"evidence"`
	Groups   GroupPolicy      `json:"cofidGroupPolicy"`
}
type FoodManifest struct {
	Schema    string   `json:"schemaVersion"`
	Stage     string   `json:"stage"`
	Scope     string   `json:"importScope"`
	BundleID  string   `json:"bundleId"`
	Review    Artifact `json:"review"`
	Preflight Artifact `json:"preflight"`
	Output    Artifact `json:"output"`
	Clinical  bool     `json:"clinicalApproval"`
}
type Basis struct {
	Quantity *string `json:"quantity" extensions:"x-nullable"`
	Unit     *string `json:"unit" extensions:"x-nullable"`
}
type ColumnBasis struct {
	Quantity int    `json:"quantity"`
	Unit     string `json:"unit"`
	Kind     string `json:"kind"`
}
type Nutrient struct {
	Column        string          `json:"sourceColumnKey"`
	Row           string          `json:"sourceRowKey"`
	Name          string          `json:"nameOriginal"`
	Unit          *string         `json:"unit"`
	State         string          `json:"state"`
	Value         *string         `json:"value"`
	UpperBound    *string         `json:"upperBound"`
	Raw           json.RawMessage `json:"raw"`
	BasisQuantity *string         `json:"basisQuantity"`
	BasisUnit     *string         `json:"basisUnit"`
	Declared      *ColumnBasis    `json:"declaredColumnBasis"`
	Scaling       bool            `json:"scalingAllowed"`
	Reasons       []string        `json:"reasons"`
}
type FoodProvenance struct {
	ReviewSHA       string         `json:"reviewSha256"`
	SnapshotSHA     string         `json:"sourceSnapshotSha256"`
	PreparedSHA     string         `json:"preparedSha256"`
	Group           *string        `json:"sourceGroup"`
	Rows            []string       `json:"sourceRows"`
	Excluded        map[string]int `json:"auxiliaryCellsExcluded"`
	Rights          Citation       `json:"rights"`
	PreparationRule string         `json:"preparationRule"`
	PortionRule     string         `json:"portionRule"`
	Clinical        bool           `json:"clinicalApproval"`
}
type Food struct {
	Schema        string         `json:"schemaVersion"`
	ID            string         `json:"foodId"`
	SourceID      string         `json:"sourceId"`
	SourceFoodID  string         `json:"sourceFoodId"`
	SourceVersion string         `json:"sourcePublishedVersion"`
	Name          string         `json:"nameOriginal"`
	Locale        string         `json:"nameLocale"`
	NamePT        *string        `json:"namePt"`
	Preparation   *string        `json:"preparation"`
	Basis         Basis          `json:"basis"`
	Allowed       []string       `json:"allowedOperations"`
	Nutrients     []Nutrient     `json:"nutrients"`
	Provenance    FoodProvenance `json:"provenance"`
}

func https(raw string) bool {
	u, err := url.Parse(raw)
	return err == nil && u.Scheme == "https" && u.Host != "" && u.User == nil
}
func validCitation(c Citation) bool {
	return c.Name != "" && c.Publisher != "" && https(c.SourceURL) && https(c.LicenseURL) &&
		c.LicenseLabel != "" && c.Attribution != "" && c.PublishedAt != "" && c.Changes != "" && c.Warranty != "" && len(c.Conditions) > 0
}
func number(raw string) (*big.Rat, error) {
	if len(raw) > 80 || !decimalPattern.MatchString(raw) {
		return nil, errors.New("invalid decimal")
	}
	n, ok := new(big.Rat).SetString(raw)
	if !ok || n.Sign() < 0 {
		return nil, errors.New("invalid nonnegative decimal")
	}
	return n, nil
}
func rawValue(n Nutrient) (state, token string, err error) {
	if len(n.Raw) == 0 || len(n.Raw) > 1024 {
		return "", "", errors.New("invalid source cell")
	}
	raw := bytes.TrimSpace(n.Raw)
	if len(raw) == 0 {
		return "", "", errors.New("empty source cell")
	}
	if bytes.Equal(raw, []byte("null")) {
		token = ""
	} else if raw[0] == '"' {
		if json.Unmarshal(raw, &token) != nil {
			return "", "", errors.New("invalid source cell")
		}
	} else {
		var scalar json.Number
		decoder := json.NewDecoder(bytes.NewReader(raw))
		decoder.UseNumber()
		if decoder.Decode(&scalar) != nil {
			return "", "", errors.New("source cell is not scalar")
		}
		token = scalar.String()
	}
	token = strings.TrimSpace(token)
	switch {
	case token == "" || token == "-":
		return "missing", "", nil
	case strings.EqualFold(token, "tr") || strings.EqualFold(token, "trace") || strings.EqualFold(token, "traces"):
		return "trace", "", nil
	case strings.EqualFold(token, "N"):
		return "present_quantity_unknown", "", nil
	}
	bound := strings.HasPrefix(token, "<")
	if bound {
		token = strings.TrimSpace(strings.TrimPrefix(token, "<"))
	}
	token = strings.ReplaceAll(token, ",", ".")
	if _, err := number(token); err != nil {
		return "unparsed", "", nil
	}
	if bound {
		return "less_than", token, nil
	}
	return "numeric", token, nil
}
func validateState(n Nutrient) error {
	state, token, err := rawValue(n)
	if err != nil || state != n.State {
		return errors.New("source state mismatch")
	}
	switch state {
	case "numeric", "less_than":
		value := n.Value
		if state == "less_than" {
			value = n.UpperBound
			if n.Value != nil {
				return errors.New("upper bound is not an exact value")
			}
		} else if n.UpperBound != nil {
			return errors.New("unexpected upper bound")
		}
		if value == nil {
			return errors.New("numeric source value missing")
		}
		expected, _ := number(token)
		actual, err := number(*value)
		if err != nil || expected.Cmp(actual) != 0 {
			return errors.New("source decimal mismatch")
		}
	default:
		if n.Value != nil || n.UpperBound != nil {
			return errors.New("missing/trace marker cannot become numeric")
		}
	}
	return nil
}
func basisValid(b Basis) bool {
	return (b.Quantity == nil && b.Unit == nil) || (b.Quantity != nil && *b.Quantity == "100" && b.Unit != nil && (*b.Unit == "g" || *b.Unit == "ml"))
}
func rowParts(source, key string) (string, bool) {
	if !strings.HasPrefix(key, source+":") {
		return "", false
	}
	rest := strings.TrimPrefix(key, source+":")
	last := strings.LastIndex(rest, ":")
	if last < 1 {
		return "", false
	}
	position, err := strconv.Atoi(rest[last+1:])
	return rest[:last], err == nil && position > 0
}
func validateFood(f Food, source ReviewedSource, reviewSHA string, groups GroupPolicy, specs map[string]ColumnSpec) error {
	if f.Schema != "1.0.0" || !foodPattern.MatchString(f.ID) || f.SourceID != source.ID || f.SourceVersion != source.Version || f.SourceFoodID == "" || len(f.SourceFoodID) > 100 ||
		f.Name == "" || len(f.Name) > 2048 || (f.Locale != "en" && f.Locale != "fr") || f.NamePT != nil || f.Preparation != nil || !basisValid(f.Basis) {
		return errors.New("invalid source-backed food")
	}
	if f.ID != "food:"+hash([]byte(f.SourceID+"\x00"+f.SourceFoodID)) {
		return errors.New("food identity is not source-derived")
	}
	p := f.Provenance
	if p.ReviewSHA != reviewSHA || p.SnapshotSHA != source.SnapshotSHA || p.PreparedSHA != source.PreparedSHA || p.Clinical ||
		!reflect.DeepEqual(p.Rights, source.Citation) || p.PreparationRule == "" || p.PortionRule == "" || len(p.Rows) == 0 {
		return errors.New("food provenance/review mismatch")
	}
	if f.SourceID == "AL-CIQUAL-2025" {
		if p.Group != nil || f.Basis.Unit == nil || *f.Basis.Unit != "g" {
			return errors.New("Ciqual basis mismatch")
		}
	} else if f.SourceID == "AL-COFID-2021" {
		if p.Group == nil {
			return errors.New("source group missing")
		}
		known, alcohol := false, false
		for _, g := range groups.Known {
			if g == *p.Group {
				known = true
			}
		}
		for _, g := range groups.Alcohol {
			if g == *p.Group {
				alcohol = true
			}
		}
		if !known {
			if f.Basis.Unit != nil {
				return errors.New("unknown source group cannot infer unit")
			}
		} else {
			unit := "g"
			if alcohol {
				unit = "ml"
			}
			if f.Basis.Unit == nil || *f.Basis.Unit != unit {
				return errors.New("source group basis mismatch")
			}
		}
	} else {
		return errors.New("source adapter unavailable")
	}
	for kind, count := range p.Excluded {
		if (kind != "factor" && kind != "fatty_acids_basis") || count < 0 {
			return errors.New("invalid excluded component count")
		}
	}
	rows := map[string]bool{}
	for _, r := range p.Rows {
		if _, ok := rowParts(f.SourceID, r); !ok || rows[r] {
			return errors.New("invalid/duplicate source row")
		}
		rows[r] = true
	}
	if f.Nutrients == nil || len(f.Nutrients) > 512 {
		return errors.New("invalid nutrient projection")
	}
	columns := map[string]bool{}
	anyScaling := false
	for _, n := range f.Nutrients {
		sheet, ok := rowParts(f.SourceID, n.Column)
		rowSheet, rowOK := rowParts(f.SourceID, n.Row)
		if !ok || !rowOK || sheet != rowSheet || !rows[n.Row] || columns[n.Column] || n.Name == "" || len(n.Name) > 2048 ||
			sheet == "1.2 Factors" || strings.Contains(sheet, "100gFA") || strings.Contains(sheet, "100FA") || faHeader.MatchString(n.Name) ||
			strings.Join(strings.Fields(n.Name), " ") == "Facteur de Jones" {
			return errors.New("invalid/non-food nutrient column")
		}
		spec, exists := specs[n.Column]
		if !exists || spec.Kind != "nutrient" || spec.Header != n.Name || !reflect.DeepEqual(spec.Unit, n.Unit) || !reflect.DeepEqual(spec.Declared, n.Declared) {
			return errors.New("source column contract mismatch")
		}
		columns[n.Column] = true
		if n.Unit != nil && *n.Unit != "g" && *n.Unit != "mg" && *n.Unit != "µg" && *n.Unit != "kcal" && *n.Unit != "kJ" {
			return errors.New("unsupported nutrient unit")
		}
		if !basisValid(Basis{n.BasisQuantity, n.BasisUnit}) || validateState(n) != nil {
			return errors.New("invalid nutrient value/basis")
		}
		if n.Declared != nil && (n.Declared.Kind != "food" || n.Declared.Quantity != 100 || n.Declared.Unit != "g") {
			return errors.New("non-food denominator in food nutrients")
		}
		eligible := n.State == "numeric" && n.Unit != nil && n.BasisUnit != nil && f.Basis.Unit != nil && *n.BasisUnit == *f.Basis.Unit
		if n.Declared != nil && f.Basis.Unit != nil && *f.Basis.Unit == "ml" {
			eligible = false
			if n.BasisUnit != nil {
				return errors.New("conflicting denominator cannot be converted")
			}
		}
		if n.Scaling != eligible || (eligible && len(n.Reasons) != 0) || (!eligible && len(n.Reasons) == 0) {
			return errors.New("scaling permission is not supported by source")
		}
		if n.Scaling {
			anyScaling = true
		}
	}
	expected := operations[:2]
	if anyScaling {
		expected = operations
	}
	if !reflect.DeepEqual(f.Allowed, expected) {
		return errors.New("food operation allowlist mismatch")
	}
	for _, op := range f.Allowed {
		if source.Operations[op] != "allowed" {
			return errors.New("source operation not allowed")
		}
	}
	return nil
}
