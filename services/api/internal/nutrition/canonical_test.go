package nutrition

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCanonicalSharedClientServerFixtures(t *testing.T) {
	raw, e := os.ReadFile(filepath.Join("..", "..", "..", "..", "test", "fixtures", "canonical_nutrition_cases.json"))
	if e != nil {
		t.Fatal(e)
	}
	var fixtures struct {
		Cases []struct {
			Name, Quantity, Unit string
			Basis                Basis
			Cells                []CanonicalFoodCell
			Expected             []struct {
				ID              string
				Value, Fraction *string
			}
		}
	}
	if e = json.Unmarshal(raw, &fixtures); e != nil {
		t.Fatal(e)
	}
	for _, c := range fixtures.Cases {
		t.Run(c.Name, func(t *testing.T) {
			food := FoodDetail{FoodSummary: FoodSummary{ID: "food:" + strings.Repeat("a", 64), VersionID: strings.Repeat("b", 64), SourceID: "fixture", Basis: c.Basis, CanonicalNutrients: c.Cells}}
			in := exampleEntry()
			in.FoodID = food.ID
			in.Quantity = c.Quantity
			in.Unit = c.Unit
			in.CalculationAlgorithm = CanonicalAlgorithm
			result, e := scaled(food, in, "editorial")
			if e != nil {
				t.Fatal(e)
			}
			if result.Algorithm != CanonicalAlgorithm || len(result.Nutrients) != len(c.Expected) {
				t.Fatal("canonical contract changed")
			}
			for i, want := range c.Expected {
				got := result.Nutrients[i]
				if got.NutrientID != want.ID || !sameString(got.Value, want.Value) || !sameString(got.Exact, want.Fraction) {
					t.Fatalf("fixture %s differs", want.ID)
				}
			}
		})
	}
}
func sameString(a, b *string) bool {
	return (a == nil && b == nil) || (a != nil && b != nil && *a == *b)
}

func TestCanonicalCrossSourceTotalsDoNotDoubleCountMethodsOrRecalculateLegacy(t *testing.T) {
	cell := CanonicalFoodCell{NutrientID: "energy_kcal", Unit: "kcal", Value: ptr("100"), State: "numeric", Primary: true, BasisQuantity: ptr("100"), BasisUnit: ptr("g"), MethodID: "sourceA"}
	food := FoodDetail{FoodSummary: FoodSummary{SourceID: "fixture", CanonicalNutrients: []CanonicalFoodCell{cell}}}
	input := exampleEntry()
	input.Quantity = "50"
	input.CalculationAlgorithm = CanonicalAlgorithm
	a, e := scaled(food, input, "editorial")
	if e != nil {
		t.Fatal(e)
	}
	food.CanonicalNutrients[0].MethodID = "sourceB"
	b, e := scaled(food, input, "editorial")
	if e != nil {
		t.Fatal(e)
	}
	legacy := Calculation{Algorithm: "source-rational-v1", Nutrients: []ScaledCell{{Column: "old-column", Unit: ptr("kcal"), Exact: ptr("999"), Value: ptr("999")}}}
	result := totals([]Entry{{Calculation: a}, {Calculation: b}, {Calculation: legacy}}, true)
	if len(result.CanonicalTotals) != 1 || *result.CanonicalTotals[0].Value != "100" || result.CanonicalTotals[0].Unknown != 1 {
		t.Fatal("cross-source/unknown accounting differs")
	}
	if legacy.Nutrients[0].NutrientID != "" || *legacy.Nutrients[0].Exact != "999" {
		t.Fatal("legacy snapshot changed")
	}
	food.CanonicalNutrients = append(food.CanonicalNutrients, cell)
	if _, e = scaled(food, input, "editorial"); e == nil {
		t.Fatal("ambiguous primary method accepted")
	}
}

func TestCanonicalPortionRequiresDocumentedVersionAndExactQuantity(t *testing.T) {
	portion := FoodPortion{ID: "fixture-spoon", Label: "One spoon", Quantity: "20", Unit: "g", SourceID: "fixture"}
	food := FoodDetail{FoodSummary: FoodSummary{SourceID: "fixture", Portions: []FoodPortion{portion}}}
	input := exampleEntry()
	input.Quantity = "40"
	input.CalculationAlgorithm = CanonicalAlgorithm
	input.Portion = &PortionSelection{FoodPortion: portion, Count: "2"}
	if _, e := scaled(food, input, "editorial"); e != nil {
		t.Fatal(e)
	}
	input.Quantity = "41"
	if _, e := scaled(food, input, "editorial"); e == nil {
		t.Fatal("portion weight silently changed")
	}
	input.Quantity = "40"
	input.Portion.Label = "invented"
	if _, e := scaled(food, input, "editorial"); e == nil {
		t.Fatal("undocumented portion accepted")
	}
}

func TestCanonicalSourcePortionKeepsOriginalPrecisionAndRejectsForgedMetadata(t *testing.T) {
	// OFF code0000111301201 preserves this explicit metric serving in raw CSV.
	portion := FoodPortion{ID: "source-serving", Label: "14.000000000000002g", Quantity: "14.000000000000002", Unit: "g", Condition: "declared serving", SourceID: "AL-OFF"}
	food := FoodDetail{FoodSummary: FoodSummary{SourceID: "fixture", Portions: []FoodPortion{portion}, CanonicalNutrients: []CanonicalFoodCell{{NutrientID: "protein_g", Unit: "g", State: "numeric", Value: ptr("2.5"), Primary: true, BasisQuantity: ptr("100"), BasisUnit: ptr("g"), MethodID: "fixture"}}}}
	in := exampleEntry()
	in.CalculationAlgorithm = CanonicalAlgorithm
	in.Quantity = portion.Quantity
	in.Portion = &PortionSelection{FoodPortion: portion, Count: "1"}
	result, e := scaled(food, in, "editorial")
	if e != nil || len(result.Nutrients) != 1 || result.Nutrients[0].Exact == nil || *result.Nutrients[0].Exact != "7000000000000001/20000000000000000" || result.Portion.Quantity != portion.Quantity {
		t.Fatal("original serving precision was rejected or rounded", e)
	}
	for name, change := range map[string]func(*EntryInput){
		"rounded quantity": func(c *EntryInput) { c.Quantity = "14" },
		"changed id":       func(c *EntryInput) { c.Portion.ID = "forged" },
		"changed source":   func(c *EntryInput) { c.Portion.SourceID = "forged" },
		"changed label":    func(c *EntryInput) { c.Portion.Label = "forged" },
		"changed condition": func(c *EntryInput) {
			c.Portion.Condition = "forged"
		},
		"changed weight": func(c *EntryInput) { c.Portion.Quantity = "14"; c.Quantity = "14" },
		"changed units":  func(c *EntryInput) { c.Portion.Unit = "ml"; c.Unit = "ml" },
		"count precision": func(c *EntryInput) {
			c.Portion.Count = "1.0000001"
		},
		"quantity bound": func(c *EntryInput) { c.Quantity = strings.Repeat("1", 81) },
		"scientific wire": func(c *EntryInput) {
			c.Quantity = "14.000000000000002e0"
		},
		"no portion": func(c *EntryInput) { c.Portion = nil },
		"legacy":     func(c *EntryInput) { c.CalculationAlgorithm = "" },
	} {
		t.Run(name, func(t *testing.T) {
			copy := in
			selection := *in.Portion
			copy.Portion = &selection
			change(&copy)
			if _, e := scaled(food, copy, "editorial"); e == nil {
				t.Fatal("forged or imprecise portion intent accepted")
			}
		})
	}
}

func TestCanonicalPersonalPortionProductCanExceedManualFractionDigits(t *testing.T) {
	portion := FoodPortion{ID: "personal-serving", Label: "Personal documented serving", Quantity: "1.234567", Unit: "g"}
	if !validFoodPortion(portion) {
		t.Fatal("valid personal portion declaration rejected")
	}
	food := FoodDetail{FoodSummary: FoodSummary{SourceID: "personal", Portions: []FoodPortion{portion}}}
	in := exampleEntry()
	in.CalculationAlgorithm = CanonicalAlgorithm
	in.Portion = &PortionSelection{FoodPortion: portion, Count: "1.234567"}
	in.Quantity = "1.524155677489"
	if _, e := scaled(food, in, "personal"); e != nil {
		t.Fatal("exact personal portion product rejected", e)
	}
	in.Portion = nil
	if validateEntry(in) == nil {
		t.Fatal("manual input precision was broadened")
	}
}
