package nutrition

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
	"strings"
	"unicode"
	"unicode/utf8"
)

const CanonicalAlgorithm = "trainforge.canonical-nutrition/1"

// Original cells remain available separately. Only a declared primary participates in totals.
type CanonicalFoodCell struct {
	NutrientID    string  `json:"nutrientId"`
	Unit          string  `json:"unit"`
	Value         *string `json:"value"`
	State         string  `json:"state"`
	UpperBound    *string `json:"upperBound,omitempty"`
	MethodID      string  `json:"methodId"`
	Primary       bool    `json:"primaryForTotals"`
	BasisQuantity *string `json:"basisQuantity"`
	BasisUnit     *string `json:"basisUnit"`
	Column        string  `json:"sourceColumnKey"`
}

type FoodPortion struct {
	ID        string `json:"id"`
	Label     string `json:"label"`
	Quantity  string `json:"quantity"`
	Unit      string `json:"unit"`
	Condition string `json:"condition"`
	SourceID  string `json:"sourceId"`
}

type PortionSelection struct {
	FoodPortion
	Count string `json:"count"`
}

var canonicalNames = map[string]string{
	"energy_kcal": "Energy", "protein_g": "Protein", "carbohydrate_g": "Carbohydrate",
	"fat_g": "Fat", "fiber_g": "Fiber", "sodium_mg": "Sodium", "sugars_g": "Sugars",
	"saturated_fat_g": "Saturated fat", "cholesterol_mg": "Cholesterol",
	"calcium_mg": "Calcium", "iron_mg": "Iron", "potassium_mg": "Potassium",
}

func validGTIN(code string) bool {
	if len(code) != 8 && len(code) != 12 && len(code) != 13 && len(code) != 14 {
		return false
	}
	sum := 0
	for i := len(code) - 2; i >= 0; i-- {
		if code[i] < '0' || code[i] > '9' {
			return false
		}
		weight := 3
		if (len(code)-2-i)%2 == 1 {
			weight = 1
		}
		sum += int(code[i]-'0') * weight
	}
	return code[len(code)-1] >= '0' && code[len(code)-1] <= '9' && (10-sum%10)%10 == int(code[len(code)-1]-'0')
}

func validFoodPortion(p FoodPortion) bool {
	return textValid(p.ID, 1, 180) && textValid(p.Label, 1, 360) && quantity(p.Quantity, true) && (p.Unit == "g" || p.Unit == "ml") && textValid(p.Condition, 0, 360) && textValid(p.SourceID, 0, 100)
}

// Source text retains documentary whitespace without weakening private inputs.
func sourceTextValid(text string, min, max int) bool {
	if !utf8.ValidString(text) || strings.TrimSpace(text) != text {
		return false
	}
	length := utf8.RuneCountInString(text)
	return length >= min && length <= max && strings.IndexFunc(text, func(r rune) bool {
		return unicode.IsControl(r) && r != '\n' && r != '\r' && r != '\t'
	}) < 0
}

func validSourceFoodPortion(p FoodPortion) bool {
	weight, e := number(p.Quantity)
	return e == nil && weight.Sign() > 0 && textValid(p.ID, 1, 180) &&
		sourceTextValid(p.Label, 1, 360) && (p.Unit == "g" || p.Unit == "ml") &&
		sourceTextValid(p.Condition, 0, 360) && sourceTextValid(p.SourceID, 0, 100)
}

// Exact derived wire quantities stay finite plain decimals for Dart parity.
// Their portion identity and rational product are checked against the snapshot.
func validPortionDerivedQuantity(value string) bool {
	if strings.ContainsAny(value, "eE+-") {
		return false
	}
	n, e := number(value)
	return e == nil && n.Sign() > 0
}

func declarationNutrientID(name, unit string) string {
	normalized := strings.ToLower(strings.TrimSpace(name))
	normalized = strings.NewReplacer("á", "a", "à", "a", "â", "a", "ã", "a", "ä", "a", "å", "a", "é", "e", "è", "e", "ê", "e", "ë", "e", "í", "i", "ì", "i", "î", "i", "ï", "i", "ó", "o", "ò", "o", "ô", "o", "õ", "o", "ö", "o", "ú", "u", "ù", "u", "û", "u", "ü", "u", "ç", "c", "ñ", "n").Replace(normalized)
	normalized = strings.Join(strings.Fields(normalized), " ")
	synonyms := map[string][]string{
		"energy_kcal":    {"energy", "energia", "calorias", "calories"},
		"protein_g":      {"protein", "proteina", "proteinas"},
		"carbohydrate_g": {"carbohydrate", "carboidrato", "carboidratos", "carbohidratos"},
		"fat_g":          {"fat", "gordura", "gorduras", "gorduras totais", "lipidios"},
		"fiber_g":        {"fiber", "fibre", "fibra", "fibras"}, "sodium_mg": {"sodium", "sodio"},
	}
	for id, names := range synonyms {
		if strings.HasSuffix(id, "_"+unit) {
			for _, candidate := range names {
				if candidate == normalized {
					return id
				}
			}
		}
	}
	sum := sha256.Sum256([]byte(normalized + "|" + unit))
	return "declared:" + hex.EncodeToString(sum[:])
}

func personalCanonical(food FoodDetail) []CanonicalFoodCell {
	cells := make([]CanonicalFoodCell, 0, len(food.Nutrients))
	for _, n := range food.Nutrients {
		if n.Unit != nil {
			id := declarationNutrientID(n.Name, *n.Unit)
			cells = append(cells, CanonicalFoodCell{NutrientID: id, Unit: *n.Unit, Value: n.Value, State: n.State, UpperBound: n.UpperBound, MethodID: "user-declaration", Primary: true, BasisQuantity: n.BasisQuantity, BasisUnit: n.BasisUnit, Column: id})
		}
	}
	return cells
}

func scaleCanonicalFood(food FoodDetail, in EntryInput, origin string) (Calculation, error) {
	if food.SourceID == "personal" {
		food.CanonicalNutrients = personalCanonical(food)
	}
	result := Calculation{Algorithm: CanonicalAlgorithm, Food: food.FoodSummary, Origin: origin, Preparation: in.Preparation, QuantityEvidence: in.QuantityEvidence, Revision: 1, Nutrients: []ScaledCell{}, Changes: []EntryChange{}, Portion: in.Portion}
	if in.Portion != nil {
		match := false
		for _, p := range food.Portions {
			if p == in.Portion.FoodPortion {
				match = true
				break
			}
		}
		if !match {
			return Calculation{}, ErrFoodQuery
		}
		count, _ := new(big.Rat).SetString(in.Portion.Count)
		weight, _ := new(big.Rat).SetString(in.Portion.Quantity)
		q, _ := new(big.Rat).SetString(in.Quantity)
		if in.Portion.Unit != in.Unit || new(big.Rat).Mul(count, weight).Cmp(q) != 0 {
			return Calculation{}, ErrFoodQuery
		}
	}
	q, _ := new(big.Rat).SetString(in.Quantity)
	seen := map[string]bool{}
	for _, n := range food.CanonicalNutrients {
		if !n.Primary {
			continue
		}
		if n.NutrientID == "" || seen[n.NutrientID] {
			return Calculation{}, ErrFoodUnavailable
		}
		seen[n.NutrientID] = true
		name := canonicalNames[n.NutrientID]
		if name == "" {
			name = n.NutrientID
		}
		basis := Basis{n.BasisQuantity, n.BasisUnit}
		if basis.Quantity == nil {
			basis.Quantity = food.Basis.Quantity
		}
		if basis.Unit == nil {
			basis.Unit = food.Basis.Unit
		}
		raw := ""
		if n.Value != nil {
			raw = *n.Value
		}
		cell := ScaledCell{NutrientID: n.NutrientID, MethodID: n.MethodID, Column: n.NutrientID, Name: name, Unit: &n.Unit, State: n.State, SourceValue: n.Value, SourceUpperBound: n.UpperBound, RawText: raw, SourceReasons: []string{}, Basis: basis, Reason: "food_basis_unresolved"}
		if basis.Quantity != nil && basis.Unit != nil && *basis.Unit == in.Unit {
			base, e := number(*basis.Quantity)
			if e != nil || base.Sign() <= 0 {
				return Calculation{}, ErrFoodUnavailable
			}
			factor := new(big.Rat).Quo(q, base)
			f := trimDecimal(factor.FloatString(6))
			cell.Factor = &f
			cell.Reason = "no_exact_numeric_quantity"
			if n.State == "numeric" && n.Value != nil {
				value, e := number(*n.Value)
				if e != nil {
					return Calculation{}, ErrFoodUnavailable
				}
				value.Mul(value, factor)
				exact := value.Num().String() + "/" + value.Denom().String()
				rounded := trimDecimal(value.FloatString(6))
				cell.Exact = &exact
				cell.Value = &rounded
				cell.Reason = ""
			}
		}
		result.Nutrients = append(result.Nutrients, cell)
	}
	return result, nil
}

func trimDecimal(s string) string {
	if strings.Contains(s, ".") {
		s = strings.TrimRight(strings.TrimRight(s, "0"), ".")
	}
	return s
}

// Additive summary: legacy snapshots are never rewritten or reinterpreted by current food data.
func canonicalTotals(entries []Entry) []NutrientTotal {
	sums := map[string]*big.Rat{}
	cells := map[string]NutrientTotal{}
	order := []string{}
	for _, e := range entries {
		seen := map[string]bool{}
		for _, n := range e.Calculation.Nutrients {
			if n.NutrientID == "" || n.Unit == nil || seen[n.NutrientID] {
				continue
			}
			seen[n.NutrientID] = true
			key := fmt.Sprintf("%s|%s", n.NutrientID, *n.Unit)
			item, ok := cells[key]
			if !ok {
				order = append(order, key)
				item = NutrientTotal{NutrientID: n.NutrientID, Column: n.NutrientID, Name: n.Name, Unit: n.Unit}
				sums[key] = new(big.Rat)
			}
			if n.Exact != nil {
				if value, ok := new(big.Rat).SetString(*n.Exact); ok {
					sums[key].Add(sums[key], value)
					item.Included++
				}
			}
			cells[key] = item
		}
	}
	result := make([]NutrientTotal, 0, len(order))
	for _, key := range order {
		item := cells[key]
		item.Unknown = len(entries) - item.Included
		if item.Included > 0 {
			value := trimDecimal(sums[key].FloatString(6))
			exact := sums[key].Num().String() + "/" + sums[key].Denom().String()
			item.Value = &value
			item.Exact = &exact
		}
		result = append(result, item)
	}
	return result
}
