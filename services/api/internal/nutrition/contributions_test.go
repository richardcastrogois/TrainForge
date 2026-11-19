package nutrition

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"testing"
)

func contributionFixture() ContributionInput {
	return ContributionInput{OperationID: newID(), Food: ContributionFood{Name: "Arroz cozido", Preparation: "cozido", Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{{Name: "Proteínas", Unit: "g", Value: ptr("2.5")}}, Barcodes: []string{"7891234567895"}, Portions: []FoodPortion{{ID: "spoon", Label: "Colher de sopa rasa", Quantity: "20", Unit: "g", Condition: "cozido", SourceID: "user-label"}}}, Consent: ContributionConsent{true, ContributionContract, "CC0-1.0"}}
}
func TestContributionRequiresSpecificVoluntaryConsent(t *testing.T) {
	in := contributionFixture()
	if in.Validate() != nil {
		t.Fatal("valid contribution rejected")
	}
	for _, change := range []func(*ContributionInput){
		func(v *ContributionInput) { v.Consent.Accepted = false }, func(v *ContributionInput) { v.Consent.Version = "other" }, func(v *ContributionInput) { v.Consent.License = "proprietary" },
		func(v *ContributionInput) { v.Food.Barcodes = append(v.Food.Barcodes, v.Food.Barcodes[0]) }, func(v *ContributionInput) { v.Food.Portions[0].Unit = "spoon" }, func(v *ContributionInput) { v.Food.Portions[0].Quantity = "0" },
	} {
		v := contributionFixture()
		change(&v)
		if v.Validate() == nil {
			t.Fatal("invalid consent or portion accepted")
		}
	}
}
func TestContributionImageDecodesPixelsAndRejectsInvalidInput(t *testing.T) {
	pixels := image.NewRGBA(image.Rect(0, 0, 2, 2))
	pixels.Set(0, 0, color.RGBA{R: 255, A: 255})
	var encoded bytes.Buffer
	if png.Encode(&encoded, pixels) != nil {
		t.Fatal("fixture encode")
	}
	raw, width, height, e := sanitizeContributionImage(encoded.Bytes(), "image/png")
	if e != nil || width != 2 || height != 2 || len(raw) < 3 || raw[0] != 0xff || raw[1] != 0xd8 {
		t.Fatal("sanitized JPEG unavailable", e)
	}
	if _, _, _, e = sanitizeContributionImage(encoded.Bytes(), "image/jpeg"); e == nil {
		t.Fatal("misleading MIME accepted")
	}
	if _, _, _, e = sanitizeContributionImage([]byte(`<svg/>`), "image/png"); e == nil {
		t.Fatal("non-image accepted")
	}
	encoded.Reset()
	_ = png.Encode(&encoded, image.NewRGBA(image.Rect(0, 0, 4097, 1)))
	if _, _, _, e = sanitizeContributionImage(encoded.Bytes(), "image/png"); e == nil {
		t.Fatal("oversized dimensions accepted")
	}
}
