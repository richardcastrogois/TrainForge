package nutrition

import (
	"encoding/json"
	"errors"
	"math/big"
	"regexp"
	"strings"
	"time"
	_ "time/tzdata"
	"unicode"
	"unicode/utf8"
)

var ErrEntryConflict = errors.New("nutrition revision or idempotency conflict")
var plainDecimal = regexp.MustCompile(`^[0-9]{1,7}(?:\.[0-9]{1,6})?$`)
var uuidPattern = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)
var privateFoodPattern = regexp.MustCompile(`^own:[a-f0-9-]{36}$`)

type OwnNutrient struct {
	Name  string  `json:"name"`
	Unit  string  `json:"unit"`
	Value *string `json:"value" extensions:"x-nullable"`
}
type OwnFoodInput struct {
	Name        string        `json:"name"`
	Preparation string        `json:"preparation"`
	Basis       Basis         `json:"basis"`
	Nutrients   []OwnNutrient `json:"nutrients"`
}
type EntryInput struct {
	FoodID           string `json:"foodId"`
	FoodVersion      string `json:"foodVersion"`
	Quantity         string `json:"quantity"`
	Unit             string `json:"unit"`
	Preparation      string `json:"preparation"`
	OccurredAt       string `json:"occurredAt"`
	Timezone         string `json:"timezone"`
	QuantityEvidence string `json:"quantityEvidence"`
	Revision         int    `json:"revision"`
}
type ScaledCell struct {
	SourceUpperBound *string  `json:"sourceUpperBound" extensions:"x-nullable"`
	RawText          string   `json:"rawText"`
	SourceReasons    []string `json:"sourceReasons"`
	Column           string   `json:"sourceColumnKey"`
	Name             string   `json:"nameOriginal"`
	Unit             *string  `json:"unit" extensions:"x-nullable"`
	State            string   `json:"sourceState"`
	SourceValue      *string  `json:"sourceValue" extensions:"x-nullable"`
	Basis            Basis    `json:"basis"`
	Factor           *string  `json:"factor" extensions:"x-nullable"`
	Value            *string  `json:"value" extensions:"x-nullable"`
	Exact            *string  `json:"exactFraction" extensions:"x-nullable"`
	Reason           string   `json:"reason"`
}
type EntryChange struct {
	Revision         int    `json:"revision"`
	Quantity         string `json:"quantity"`
	Unit             string `json:"unit"`
	Preparation      string `json:"preparation"`
	OccurredAt       string `json:"occurredAt"`
	Timezone         string `json:"timezone"`
	QuantityEvidence string `json:"quantityEvidence"`
	ReplacedAt       string `json:"replacedAt"`
}
type Calculation struct {
	Algorithm        string        `json:"algorithm"`
	Food             FoodSummary   `json:"food"`
	Origin           string        `json:"origin"`
	Preparation      string        `json:"preparation"`
	QuantityEvidence string        `json:"quantityEvidence"`
	Revision         int           `json:"revision"`
	Nutrients        []ScaledCell  `json:"nutrients"`
	Changes          []EntryChange `json:"changes"`
}
type Entry struct {
	ID          string            `json:"id"`
	FoodID      string            `json:"foodId"`
	FoodVersion string            `json:"foodVersion"`
	Quantity    string            `json:"quantity"`
	Unit        string            `json:"unit"`
	OccurredAt  string            `json:"occurredAt"`
	Timezone    string            `json:"timezone"`
	Calculation Calculation       `json:"calculation"`
	FoodDisplay *EntryFoodDisplay `json:"foodDisplay,omitempty"`
	DeletedAt   *string           `json:"deletedAt" extensions:"x-nullable"`
}
type NutritionPage struct {
	Items       json.RawMessage  `json:"items" swaggertype:"array,object"`
	NextCursor  *string          `json:"nextCursor" extensions:"x-nullable"`
	NameCatalog *FoodNameCatalog `json:"nameCatalog,omitempty"`
}
type NutrientTotal struct {
	Column   string  `json:"sourceColumnKey"`
	Name     string  `json:"nameOriginal"`
	Unit     *string `json:"unit" extensions:"x-nullable"`
	Value    *string `json:"value" extensions:"x-nullable"`
	Exact    *string `json:"exactFraction" extensions:"x-nullable"`
	Included int     `json:"includedEntries"`
	Unknown  int     `json:"unknownEntries"`
}
type NutritionTotals struct {
	MeasuredEntries  int             `json:"measuredEntries"`
	EstimatedEntries int             `json:"estimatedEntries"`
	Entries          int             `json:"entries"`
	Complete         bool            `json:"complete"`
	Nutrients        []NutrientTotal `json:"nutrients"`
	Notice           string          `json:"notice"`
}

func textValid(s string, min, max int) bool {
	return utf8.ValidString(s) && len([]rune(s)) >= min && len([]rune(s)) <= max && strings.TrimSpace(s) == s && strings.IndexFunc(s, unicode.IsControl) < 0
}
func quantity(s string, positive bool) bool {
	if !plainDecimal.MatchString(s) {
		return false
	}
	n, _ := new(big.Rat).SetString(s)
	return n != nil && (!positive || n.Sign() > 0)
}
func validateOwn(in OwnFoodInput) error {
	if !textValid(in.Name, 1, 180) || !textValid(in.Preparation, 0, 180) || in.Nutrients == nil || len(in.Nutrients) > 32 {
		return ErrFoodQuery
	}
	b := in.Basis
	if (b.Quantity == nil) != (b.Unit == nil) {
		return ErrFoodQuery
	}
	if b.Quantity != nil && (!quantity(*b.Quantity, true) || (*b.Unit != "g" && *b.Unit != "ml")) {
		return ErrFoodQuery
	}
	seen := map[string]bool{}
	for _, n := range in.Nutrients {
		key := strings.ToLower(n.Name)
		if !textValid(n.Name, 1, 100) || seen[key] || (n.Unit != "g" && n.Unit != "mg" && n.Unit != "µg" && n.Unit != "kcal" && n.Unit != "kJ") || (n.Value != nil && !quantity(*n.Value, false)) {
			return ErrFoodQuery
		}
		seen[key] = true
	}
	return nil
}
func zone(raw string) (*time.Location, error) {
	if len(raw) > 80 || raw == "" {
		return nil, ErrFoodQuery
	}
	if raw == "UTC" {
		return time.UTC, nil
	}
	if len(raw) == 6 && (raw[0] == '+' || raw[0] == '-') && raw[3] == ':' {
		t, e := time.Parse("-07:00", raw)
		if e != nil {
			return nil, ErrFoodQuery
		}
		_, offset := t.Zone()
		if offset > 14*3600 || offset < -14*3600 {
			return nil, ErrFoodQuery
		}
		return time.FixedZone(raw, offset), nil
	}
	l, e := time.LoadLocation(raw)
	if e != nil || raw == "Local" {
		return nil, ErrFoodQuery
	}
	return l, nil
}
func validateEntry(in EntryInput) error {
	if (!foodPattern.MatchString(in.FoodID) && !privateFoodPattern.MatchString(in.FoodID)) || !shaPattern.MatchString(in.FoodVersion) || !quantity(in.Quantity, true) || (in.Unit != "g" && in.Unit != "ml") || !textValid(in.Preparation, 0, 180) || in.Revision < 0 || in.Revision > 100 {
		return ErrFoodQuery
	}
	if in.QuantityEvidence != "measured" && in.QuantityEvidence != "estimated" {
		return ErrFoodQuery
	}
	t, e := time.Parse(time.RFC3339, in.OccurredAt)
	if e != nil || t.Year() < 1900 || t.Year() > 2100 {
		return ErrFoodQuery
	}
	_, e = zone(in.Timezone)
	return e
}
func dayBounds(day, tz string) (time.Time, time.Time, error) {
	z, e := zone(tz)
	if e != nil {
		return time.Time{}, time.Time{}, e
	}
	t, e := time.ParseInLocation("2006-01-02", day, z)
	if e != nil || t.Year() < 1900 || t.Year() > 2100 {
		return t, t, ErrFoodQuery
	}
	return t, t.AddDate(0, 0, 1), nil
}
func scaled(food FoodDetail, in EntryInput, origin string) (Calculation, error) {
	if err := validateEntry(in); err != nil {
		return Calculation{}, err
	}
	c := Calculation{Algorithm: "source-rational-v1", Food: food.FoodSummary, Origin: origin, Preparation: in.Preparation, QuantityEvidence: in.QuantityEvidence, Revision: 1, Nutrients: []ScaledCell{}, Changes: []EntryChange{}}
	q, _ := new(big.Rat).SetString(in.Quantity)
	for _, n := range food.Nutrients {
		out := ScaledCell{Column: n.Column, Name: n.Name, Unit: n.Unit, State: n.State, SourceValue: n.Value, Basis: Basis{n.BasisQuantity, n.BasisUnit}, Reason: "source_value_or_basis_unknown", SourceUpperBound: n.UpperBound, RawText: n.Raw, SourceReasons: n.Reasons}
		switch {
		case n.State != "numeric" || n.Value == nil || !n.Scaling || n.Unit == nil || n.BasisQuantity == nil || n.BasisUnit == nil:
		case *n.BasisUnit != in.Unit:
			out.Reason = "incompatible_unit_no_density_conversion"
		default:
			v, e := number(*n.Value)
			if e != nil {
				return c, ErrFoodUnavailable
			}
			b, e := number(*n.BasisQuantity)
			if e != nil || b.Sign() == 0 {
				return c, ErrFoodUnavailable
			}
			factor := new(big.Rat).Quo(q, b)
			value := new(big.Rat).Mul(v, factor)
			f, exact, rounded := factor.RatString(), value.RatString(), value.FloatString(6)
			out.Factor = &f
			out.Exact = &exact
			out.Value = &rounded
			out.Reason = ""
		}
		c.Nutrients = append(c.Nutrients, out)
	}
	return c, nil
}

// Totals retain source columns and methods. Estimated quantities are reported as
// estimates; missing cells and incompatible units never become zero.
func totals(entries []Entry, complete bool) NutritionTotals {
	result := NutritionTotals{Entries: len(entries), Complete: complete, Nutrients: []NutrientTotal{}, Notice: "Subtotais por coluna/método da fonte; não somar métodos ou unidades diferentes. Quantidades estimadas continuam estimadas; ausência não é zero. Valores exibidos arredondados a 6 casas; fração exata preservada. Sem metas ou compensação por exercício."}
	if !complete {
		return result
	}
	keys := []string{}
	cells := map[string]NutrientTotal{}
	sums := map[string]*big.Rat{}
	for _, e := range entries {
		if e.Calculation.QuantityEvidence == "measured" {
			result.MeasuredEntries++
		} else {
			result.EstimatedEntries++
		}
		for _, n := range e.Calculation.Nutrients {
			unit := ""
			if n.Unit != nil {
				unit = *n.Unit
			}
			key := n.Column + "|" + unit
			item, ok := cells[key]
			if !ok {
				keys = append(keys, key)
				item = NutrientTotal{Column: n.Column, Name: n.Name, Unit: n.Unit}
				sums[key] = new(big.Rat)
			}
			if n.Exact != nil {
				v, ok := new(big.Rat).SetString(*n.Exact)
				if ok {
					sums[key].Add(sums[key], v)
					item.Included++
				}
			}
			cells[key] = item
		}
	}
	for _, key := range keys {
		item := cells[key]
		item.Unknown = len(entries) - item.Included
		if item.Included > 0 {
			s, e := sums[key].FloatString(6), sums[key].RatString()
			item.Value = &s
			item.Exact = &e
		}
		result.Nutrients = append(result.Nutrients, item)
	}
	return result
}
