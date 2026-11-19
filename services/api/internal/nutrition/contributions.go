package nutrition

import (
	"bytes"
	"encoding/json"
	"image"
	"image/jpeg"
	_ "image/png"
	"strings"
)

const ContributionContract = "trainforge.food-contribution/1"

type ContributionFood struct {
	Name        string        `json:"name"`
	Preparation string        `json:"preparation"`
	Basis       Basis         `json:"basis"`
	Nutrients   []OwnNutrient `json:"nutrients"`
	Brand       string        `json:"brand,omitempty"`
	Barcodes    []string      `json:"barcodes,omitempty"`
	Portions    []FoodPortion `json:"portions,omitempty"`
}
type ContributionConsent struct {
	Accepted bool   `json:"accepted"`
	Version  string `json:"version"`
	License  string `json:"license"`
}
type ContributionInput struct {
	OperationID string              `json:"operationId"`
	Food        ContributionFood    `json:"food"`
	Consent     ContributionConsent `json:"consent"`
}
type ContributionMedia struct {
	ID        string `json:"id"`
	SHA256    string `json:"sha256"`
	MediaType string `json:"mediaType"`
	Width     int    `json:"width"`
	Height    int    `json:"height"`
}
type Contribution struct {
	ID         string              `json:"id"`
	Status     string              `json:"status"`
	Food       ContributionFood    `json:"food"`
	Consent    ContributionConsent `json:"consent"`
	CreatedAt  string              `json:"createdAt"`
	UpdatedAt  string              `json:"updatedAt"`
	ReviewNote string              `json:"reviewNote"`
	Media      []ContributionMedia `json:"media"`
}
type ContributionPage struct {
	Items      []Contribution `json:"items"`
	NextCursor *string        `json:"nextCursor"`
}

func (in ContributionInput) Validate() error {
	if !uuidPattern.MatchString(in.OperationID) || !in.Consent.Accepted || in.Consent.Version != ContributionContract || in.Consent.License != "CC0-1.0" {
		return ErrFoodQuery
	}
	food := in.Food
	if validateOwn(OwnFoodInput{Name: food.Name, Preparation: food.Preparation, Basis: food.Basis, Nutrients: food.Nutrients}) != nil || !textValid(food.Brand, 0, 180) || len(food.Barcodes) > 16 || len(food.Portions) > 32 {
		return ErrFoodQuery
	}
	seen := map[string]bool{}
	for _, code := range food.Barcodes {
		if !validGTIN(code) || seen[code] {
			return ErrFoodQuery
		}
		seen[code] = true
	}
	seen = map[string]bool{}
	for _, portion := range food.Portions {
		if !textValid(portion.ID, 1, 100) || seen[portion.ID] || !textValid(portion.Label, 1, 180) || !quantity(portion.Quantity, true) || (portion.Unit != "g" && portion.Unit != "ml") || !textValid(portion.Condition, 0, 180) || !textValid(portion.SourceID, 1, 100) {
			return ErrFoodQuery
		}
		seen[portion.ID] = true
	}
	return nil
}

// Only decoded pixels are retained: EXIF/GPS/comments and original metadata are
// removed by JPEG re-encoding. Dimensions are checked before allocating pixels.
func sanitizeContributionImage(raw []byte, mediaType string) ([]byte, int, int, error) {
	if len(raw) == 0 || len(raw) > 4<<20 || (mediaType != "image/jpeg" && mediaType != "image/png") {
		return nil, 0, 0, ErrFoodQuery
	}
	config, format, e := image.DecodeConfig(bytes.NewReader(raw))
	if e != nil || config.Width < 1 || config.Height < 1 || config.Width > 4096 || config.Height > 4096 || config.Width*config.Height > 12_000_000 || ((format == "jpeg") != (mediaType == "image/jpeg")) {
		return nil, 0, 0, ErrFoodQuery
	}
	pixels, _, e := image.Decode(bytes.NewReader(raw))
	if e != nil {
		return nil, 0, 0, ErrFoodQuery
	}
	var out bytes.Buffer
	if jpeg.Encode(&out, pixels, &jpeg.Options{Quality: 90}) != nil || out.Len() > 4<<20 {
		return nil, 0, 0, ErrFoodQuery
	}
	return out.Bytes(), config.Width, config.Height, nil
}

func contributionCanonical(in ContributionInput) ([]byte, []byte, []byte) {
	food, _ := json.Marshal(in.Food)
	consent, _ := json.Marshal(in.Consent)
	body, _ := json.Marshal(in)
	return food, consent, digest(body)
}
func contributionIDValid(id string) bool {
	return uuidPattern.MatchString(strings.TrimSpace(id)) && id == strings.TrimSpace(id)
}
