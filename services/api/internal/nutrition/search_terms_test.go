package nutrition

import (
	"reflect"
	"testing"
)

func TestFoodDiscoveryTermsAreBoundedAndLocaleSpecific(t *testing.T) {
	for _, q := range []string{"feijão", "feijao", "FEIJÕES"} {
		if got := foodSearchTerms(q, "pt-BR"); !reflect.DeepEqual(got, []string{"bean", "beans", "haricot", "haricots"}) {
			t.Fatalf("unexpected terms for %s", q)
		}
	}
	if !reflect.DeepEqual(foodSearchTerms("arroz", "es"), []string{"rice", "riz"}) {
		t.Fatal("Spanish discovery missing")
	}
	for _, q := range []string{"rice", "arroz com feijão", "arroz%", "rice' OR TRUE --", "unknown"} {
		if len(foodSearchTerms(q, "pt-BR")) != 0 {
			t.Fatal("Unreviewed expression expanded")
		}
	}
	if len(foodSearchTerms("arroz", "en")) != 0 {
		t.Fatal("Locale ignored")
	}
}
