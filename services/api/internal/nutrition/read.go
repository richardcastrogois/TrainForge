package nutrition

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/url"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"
)

var ErrFoodQuery = errors.New("invalid food query")
var ErrFoodMissing = errors.New("food unavailable")
var ErrFoodUnavailable = errors.New("food references unavailable")

type FoodSummary struct {
	ID            string               `json:"id"`
	VersionID     string               `json:"versionId"`
	SourceID      string               `json:"sourceId"`
	SourceFoodID  string               `json:"sourceFoodId"`
	SourceVersion string               `json:"sourcePublishedVersion"`
	Name          string               `json:"nameOriginal"`
	Locale        string               `json:"nameLocale"`
	Basis         Basis                `json:"basis"`
	Source        Citation             `json:"source"`
	ReviewedName  *ReviewedNameDisplay `json:"reviewedName,omitempty"`
}
type FoodCell struct {
	Column        string       `json:"sourceColumnKey"`
	Row           string       `json:"sourceRowKey"`
	Name          string       `json:"nameOriginal"`
	Unit          *string      `json:"unit" extensions:"x-nullable"`
	State         string       `json:"state"`
	Value         *string      `json:"value" extensions:"x-nullable"`
	UpperBound    *string      `json:"upperBound" extensions:"x-nullable"`
	Raw           string       `json:"rawText"`
	BasisQuantity *string      `json:"basisQuantity" extensions:"x-nullable"`
	BasisUnit     *string      `json:"basisUnit" extensions:"x-nullable"`
	Declared      *ColumnBasis `json:"declaredColumnBasis" extensions:"x-nullable"`
	Scaling       bool         `json:"scalingAllowed"`
	Reasons       []string     `json:"reasons"`
}
type FoodDetail struct {
	FoodSummary
	Nutrients   []FoodCell       `json:"nutrients"`
	Notice      string           `json:"notice"`
	NameCatalog *FoodNameCatalog `json:"nameCatalog,omitempty"`
}
type FoodPage struct {
	Items       []FoodSummary    `json:"items"`
	NextCursor  *string          `json:"nextCursor" extensions:"x-nullable"`
	Notice      string           `json:"notice"`
	NameCatalog *FoodNameCatalog `json:"nameCatalog,omitempty"`
}
type FoodSourceCount struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Locale string `json:"nameLocale"`
	Count  int    `json:"count"`
}
type FoodFacets struct {
	Sources           []FoodSourceCount `json:"sources"`
	Total             int               `json:"total"`
	UnknownBasisCount int               `json:"unknownBasisCount"`
}
type FoodFilters struct {
	Q, Source, After string
	Limit            int
	Locale           string `json:",omitempty"`
	NamesVersion     string `json:",omitempty"`
}
type FoodRepository interface {
	List(context.Context, FoodFilters) ([]FoodSummary, error)
	Detail(context.Context, string, string) (FoodDetail, error)
	Facets(context.Context) (FoodFacets, error)
}
type FoodReader struct{ Repository FoodRepository }

const foodNotice = "Referência de composição da fonte, sem prescrição de dieta. Nomes e métodos originais preservados; ausência não significa zero. Sem cálculo de porção ou registro de consumo nesta consulta."

func (r FoodReader) List(ctx context.Context, f FoodFilters) (FoodPage, error) {
	page := FoodPage{Items: []FoodSummary{}, Notice: foodNotice}
	if r.Repository == nil {
		return page, ErrFoodUnavailable
	}
	var rows []FoodSummary
	var err error
	if f.Locale != "" {
		repo, ok := r.Repository.(LocalizedFoodRepository)
		if !ok {
			return page, ErrFoodUnavailable
		}
		var catalog FoodNameCatalog
		rows, catalog, err = repo.LocalizedList(ctx, f)
		page.NameCatalog = &catalog
		f.NamesVersion = catalog.Version
	} else {
		rows, err = r.Repository.List(ctx, f)
	}
	if err != nil {
		return page, err
	}
	if len(rows) > f.Limit {
		token := foodCursor(rows[f.Limit-1].ID, f)
		page.NextCursor = &token
		rows = rows[:f.Limit]
	}
	page.Items = rows
	return page, nil
}
func (r FoodReader) Detail(ctx context.Context, id, version string, locales ...string) (FoodDetail, error) {
	if r.Repository == nil {
		return FoodDetail{}, ErrFoodUnavailable
	}
	if len(locales) > 0 && locales[0] != "" {
		repo, ok := r.Repository.(LocalizedFoodRepository)
		if !ok {
			return FoodDetail{}, ErrFoodUnavailable
		}
		return repo.LocalizedDetail(ctx, id, version, locales[0])
	}
	return r.Repository.Detail(ctx, id, version)
}
func (r FoodReader) Facets(ctx context.Context) (FoodFacets, error) {
	if r.Repository == nil {
		return FoodFacets{}, ErrFoodUnavailable
	}
	return r.Repository.Facets(ctx)
}
func foodFingerprint(f FoodFilters) string {
	f.After = ""
	raw, _ := json.Marshal(f)
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}

type foodPageCursor struct {
	After        string `json:"after"`
	Filter       string `json:"filter"`
	NamesVersion string `json:"namesVersion,omitempty"`
}

func foodCursor(after string, f FoodFilters) string {
	raw, _ := json.Marshal(foodPageCursor{After: after, Filter: foodFingerprint(f), NamesVersion: f.NamesVersion})
	return base64.RawURLEncoding.EncodeToString(raw)
}
func foodFilters(q url.Values) (FoodFilters, error) {
	f := FoodFilters{Limit: 20}
	for key, values := range q {
		if (key != "q" && key != "sourceId" && key != "limit" && key != "cursor" && key != "locale" && key != "namesVersion") || len(values) != 1 || len(values[0]) > 1024 || !utf8.ValidString(values[0]) {
			return f, ErrFoodQuery
		}
	}
	f.Q = strings.Join(strings.Fields(q.Get("q")), " ")
	f.Source = q.Get("sourceId")
	f.Locale = q.Get("locale")
	f.NamesVersion = q.Get("namesVersion")
	if (f.Locale != "" && !foodNameLocale(f.Locale)) || (f.NamesVersion != "" && (f.Locale == "" || !validNamesRevision(f.NamesVersion))) {
		return f, ErrFoodQuery
	}
	if len(f.Q) > 100 || len(f.Source) > 100 || strings.IndexFunc(f.Q, unicode.IsControl) >= 0 || strings.IndexFunc(f.Source, unicode.IsControl) >= 0 {
		return f, ErrFoodQuery
	}
	if n := q.Get("limit"); n != "" {
		value, err := strconv.Atoi(n)
		if err != nil || value < 1 || value > 50 {
			return f, ErrFoodQuery
		}
		f.Limit = value
	}
	if token := q.Get("cursor"); token != "" {
		raw, err := base64.RawURLEncoding.DecodeString(token)
		if err != nil {
			return f, ErrFoodQuery
		}
		var c foodPageCursor
		dec := json.NewDecoder(bytes.NewReader(raw))
		dec.DisallowUnknownFields()
		if dec.Decode(&c) != nil {
			return f, ErrFoodQuery
		}
		if f.NamesVersion == "" {
			f.NamesVersion = c.NamesVersion
		}
		if !foodPattern.MatchString(c.After) || c.Filter != foodFingerprint(f) || c.NamesVersion != f.NamesVersion ||
			(f.NamesVersion != "" && (f.Locale == "" || !validNamesRevision(f.NamesVersion))) {
			return f, ErrFoodQuery
		}
		if dec.Decode(new(any)) != io.EOF {
			return f, ErrFoodQuery
		}
		f.After = c.After
	}
	return f, nil
}
func foodVersion(q url.Values) (string, error) {
	for k, v := range q {
		if k != "versionId" || len(v) != 1 {
			return "", ErrFoodQuery
		}
	}
	version := q.Get("versionId")
	if version != "" && !shaPattern.MatchString(version) {
		return "", ErrFoodQuery
	}
	return version, nil
}
