package nutrition

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

var ErrFoodNames = errors.New("invalid reviewed food names")

// NameReview records a human editorial decision. Validation checks its structure,
// not the reviewer's identity or the truth of the external evidence. Publication
// still requires an authorized operator to verify those documents and hashes.
type NameReview struct {
	ReviewerRef    string `json:"reviewerRef"`
	ReviewedAt     string `json:"reviewedAt"`
	HumanReviewed  bool   `json:"humanReviewed"`
	EvidenceSHA    string `json:"evidenceSha256"`
	RightsSHA      string `json:"rightsEvidenceSha256"`
	LicenseLabel   string `json:"licenseLabel"`
	LicenseURL     string `json:"licenseUrl"`
	Attribution    string `json:"attribution"`
	Scope          string `json:"scope"`
	DisplayAllowed bool   `json:"displayAllowed"`
	SearchAllowed  bool   `json:"searchAllowed"`
}

// ReviewedFoodNames never changes the source version or its original hash. A
// record covers exactly one food version and locale; aliases share its review.
// This type is not accepted by any public HTTP endpoint or the food importer.
type ReviewedFoodNames struct {
	Contract     string     `json:"contract"`
	FoodID       string     `json:"foodId"`
	FoodVersion  string     `json:"foodVersion"`
	SourceName   string     `json:"nameOriginal"`
	SourceLocale string     `json:"nameLocale"`
	Locale       string     `json:"locale"`
	Name         string     `json:"name"`
	Aliases      []string   `json:"aliases"`
	Review       NameReview `json:"review"`
}

func validNameText(value string, maxRunes int) bool {
	return value != "" && utf8.ValidString(value) && utf8.RuneCountInString(value) <= maxRunes &&
		strings.IndexFunc(value, func(r rune) bool {
			return unicode.IsControl(r) || unicode.Is(unicode.Cf, r) || r == unicode.ReplacementChar
		}) < 0 &&
		strings.Join(strings.Fields(value), " ") == value
}
func foodNameLocale(locale string) bool {
	switch locale {
	case "pt-BR", "pt-PT", "en", "es":
		return true
	}
	return false
}
func (n ReviewedFoodNames) Validate(now time.Time) error {
	r := n.Review
	reviewed, err := time.Parse(time.RFC3339Nano, r.ReviewedAt)
	if n.Contract != "trainforge.food-names/1" || !foodPattern.MatchString(n.FoodID) || !shaPattern.MatchString(n.FoodVersion) ||
		!foodNameLocale(n.Locale) || n.SourceName == "" || !utf8.ValidString(n.SourceName) || utf8.RuneCountInString(n.SourceName) > 2000 || strings.ContainsRune(n.SourceName, 0) || !validNameText(n.SourceLocale, 35) ||
		!validNameText(n.Name, 360) || n.Aliases == nil || len(n.Aliases) > 16 ||
		!validNameText(r.ReviewerRef, 160) || !r.HumanReviewed || !shaPattern.MatchString(r.EvidenceSHA) ||
		!shaPattern.MatchString(r.RightsSHA) || !validNameText(r.LicenseLabel, 160) || !https(r.LicenseURL) || !utf8.ValidString(r.LicenseURL) || len(r.LicenseURL) > 2048 ||
		!validNameText(r.Attribution, 2000) || r.Scope != "food_names_and_aliases" || !r.DisplayAllowed || !r.SearchAllowed ||
		err != nil || reviewed.IsZero() || now.IsZero() || reviewed.After(now) {
		return ErrFoodNames
	}
	seen := map[string]bool{strings.ToLower(n.Name): true}
	for _, alias := range n.Aliases {
		key := strings.ToLower(alias)
		if !validNameText(alias, 360) || seen[key] {
			return ErrFoodNames
		}
		seen[key] = true
	}
	canonical, err := json.Marshal(n)
	if err != nil || len(canonical) > 32768 {
		return ErrFoodNames
	}
	return nil
}

// DecodeReviewedFoodNames allows bounded JSON whitespace from PostgreSQL jsonb
// serialization; Validate still limits canonical content to32KiB. Unknown fields
// and duplicate keys are rejected. It deliberately
// cannot import nutrients, personal foods or make an AI approval claim sufficient.
func DecodeReviewedFoodNames(raw []byte, now time.Time) (ReviewedFoodNames, error) {
	var n ReviewedFoodNames
	if len(raw) == 0 || len(raw) > 65536 || !utf8.Valid(raw) {
		return n, ErrFoodNames
	}
	check := json.NewDecoder(bytes.NewReader(raw))
	if uniqueNameJSON(check, 0) != nil {
		return n, ErrFoodNames
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if dec.Decode(&n) != nil || dec.Decode(new(any)) != io.EOF || n.Validate(now) != nil {
		return ReviewedFoodNames{}, ErrFoodNames
	}
	return n, nil
}
func (n ReviewedFoodNames) VersionID() string {
	raw, _ := json.Marshal(n)
	return hash(raw)
}

// Reject duplicate keys instead of accepting last-key-wins review metadata.
func uniqueNameJSON(dec *json.Decoder, depth int) error {
	if depth > 16 {
		return ErrFoodNames
	}
	token, err := dec.Token()
	if err != nil {
		return ErrFoodNames
	}
	switch token {
	case json.Delim('{'):
		seen := map[string]bool{}
		for dec.More() {
			key, err := dec.Token()
			if err != nil {
				return ErrFoodNames
			}
			name, ok := key.(string)
			if !ok || seen[name] {
				return ErrFoodNames
			}
			seen[name] = true
			if uniqueNameJSON(dec, depth+1) != nil {
				return ErrFoodNames
			}
		}
		close, err := dec.Token()
		if err != nil || close != json.Delim('}') {
			return ErrFoodNames
		}
	case json.Delim('['):
		for dec.More() {
			if uniqueNameJSON(dec, depth+1) != nil {
				return ErrFoodNames
			}
		}
		close, err := dec.Token()
		if err != nil || close != json.Delim(']') {
			return ErrFoodNames
		}
	}
	return nil
}

// NameEvidence is provided by operator tooling, never by a public request body.
// Matching bytes prove traceability, not human authorship or license validity.
type NameEvidence struct{ ReviewDocument, RightsDocument []byte }

func (e NameEvidence) Validate(n ReviewedFoodNames) error {
	if len(e.ReviewDocument) == 0 || len(e.RightsDocument) == 0 || len(e.ReviewDocument) > 1048576 || len(e.RightsDocument) > 1048576 ||
		hash(e.ReviewDocument) != n.Review.EvidenceSHA || hash(e.RightsDocument) != n.Review.RightsSHA {
		return ErrFoodNames
	}
	return nil
}
