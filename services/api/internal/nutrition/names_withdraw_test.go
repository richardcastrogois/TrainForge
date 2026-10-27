package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
)

func fixtureWithdrawal() FoodNameWithdrawal {
	return FoodNameWithdrawal{Contract: "trainforge.food-name-withdrawal/1", FoodID: "food:" + strings.Repeat("a", 64), FoodVersion: strings.Repeat("b", 64), Locale: "pt-BR", NameVersion: strings.Repeat("c", 64), Reason: "Isolated withdrawn name", ReviewerRef: "fixture-reviewer", ReviewedAt: "2026-10-25T00:00:00Z", EvidenceSHA: hash([]byte("isolated withdrawal evidence"))}
}
func TestFoodNamesWithdrawalRejectsAmbiguousOrUntraceableDecision(t *testing.T) {
	w := fixtureWithdrawal()
	raw, _ := json.Marshal(w)
	if _, err := DecodeFoodNameWithdrawal(raw, namesNow); err != nil {
		t.Fatal("valid decision refused")
	}
	for _, bad := range [][]byte{[]byte(strings.Replace(string(raw), `"locale":"pt-BR"`, `"locale":"es","locale":"pt-BR"`, 1)), []byte(strings.Replace(string(raw), `"contract":`, `"unknown":true,"contract":`, 1)), append(raw, raw...)} {
		if _, err := DecodeFoodNameWithdrawal(bad, namesNow); err == nil {
			t.Fatal("ambiguous decision accepted")
		}
	}
	for _, change := range []func(*FoodNameWithdrawal){func(w *FoodNameWithdrawal) { w.FoodID = "own:private" }, func(w *FoodNameWithdrawal) { w.Locale = "pt" }, func(w *FoodNameWithdrawal) { w.ReviewerRef = "" }, func(w *FoodNameWithdrawal) { w.ReviewedAt = "2027-01-01T00:00:00Z" }, func(w *FoodNameWithdrawal) { w.Reason = "hidden\ncontrol" }, func(w *FoodNameWithdrawal) { w.EvidenceSHA = "" }, func(w *FoodNameWithdrawal) { w.Reason = strings.Repeat("😀", 320) }} {
		copy := w
		change(&copy)
		if copy.Validate(namesNow) == nil {
			t.Fatal("unsafe decision accepted")
		}
	}
	if _, err := StoreFoodNameWithdrawal(context.Background(), nil, w, []byte("wrong bytes"), namesNow); !errors.Is(err, ErrFoodNames) {
		t.Fatal("unverified decision reached database")
	}
}
