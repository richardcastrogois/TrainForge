package nutrition

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"strings"
	"trainforge.local/api/internal/platform/httpapi"
)

type FoodHandler struct{ Reader FoodReader }

func (h FoodHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/foods/filters", h.Filters)
	mux.HandleFunc("GET /api/v1/foods/{id}", h.Detail)
	mux.HandleFunc("GET /api/v1/foods", h.List)
}
func foodFailure(w http.ResponseWriter, r *http.Request, err error) {
	status, code := 503, "food_references_unavailable"
	if errors.Is(err, ErrFoodQuery) {
		status, code = 400, "invalid_food_query"
	}
	if errors.Is(err, ErrFoodMissing) {
		status, code = 404, "food_unavailable"
	}
	httpapi.Failure(w, r, status, code)
}
func foodJSON(w http.ResponseWriter, r *http.Request, v any) {
	raw, err := json.Marshal(v)
	if err != nil {
		foodFailure(w, r, ErrFoodUnavailable)
		return
	}
	sum := sha256.Sum256(raw)
	tag := `"` + hex.EncodeToString(sum[:]) + `"`
	w.Header().Set("ETag", tag)
	w.Header().Set("Cache-Control", "private, no-cache, must-revalidate")
	// Authorization and withdrawal ran before evaluating conditional requests.
	for _, candidate := range strings.Split(r.Header.Get("If-None-Match"), ",") {
		if strings.TrimPrefix(strings.TrimSpace(candidate), "W/") == tag || strings.TrimSpace(candidate) == "*" {
			w.WriteHeader(304)
			return
		}
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(200)
	_, _ = w.Write(raw)
}

// List searches original source names. Stable food-ID order, not nutritional ranking.
// @Summary Search reviewed food references
// @Tags nutrition
// @Produce json
// @Param q query string false "Literal original-name substring with collapsed whitespace; maximum 100 UTF-8 bytes"
// @Param sourceId query string false "Exact reviewed source ID"
// @Param limit query int false "Page size" minimum(1) maximum(50) default(20)
// @Param cursor query string false "Opaque cursor bound to search, source and page size"
// @Success 200 {object} FoodPage
// @Success 304
// @Failure 400,503 {object} httpapi.Problem
// @Router /api/v1/foods [get]
func (h FoodHandler) List(w http.ResponseWriter, r *http.Request) {
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		foodFailure(w, r, ErrFoodQuery)
		return
	}
	f, err := foodFilters(q)
	if err != nil {
		foodFailure(w, r, err)
		return
	}
	page, err := h.Reader.List(r.Context(), f)
	if err != nil {
		foodFailure(w, r, err)
		return
	}
	foodJSON(w, r, page)
}

// Detail preserves units, exact decimal strings, bounds and missing/trace markers.
// @Summary Reviewed food composition and attribution
// @Tags nutrition
// @Produce json
// @Param id path string true "Source-derived food ID"
// @Param versionId query string false "Exact SHA-256 version; latest by default"
// @Success 200 {object} FoodDetail
// @Success 304
// @Failure 400,404,503 {object} httpapi.Problem
// @Router /api/v1/foods/{id} [get]
func (h FoodHandler) Detail(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !foodPattern.MatchString(id) {
		foodFailure(w, r, ErrFoodQuery)
		return
	}
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		foodFailure(w, r, ErrFoodQuery)
		return
	}
	version, err := foodVersion(q)
	if err != nil {
		foodFailure(w, r, err)
		return
	}
	item, err := h.Reader.Detail(r.Context(), id, version)
	if err != nil {
		foodFailure(w, r, err)
		return
	}
	foodJSON(w, r, item)
}

// Filters contains only visible reviewed public references, never private foods.
// @Summary Reviewed food sources and coverage
// @Tags nutrition
// @Produce json
// @Success 200 {object} FoodFacets
// @Success 304
// @Failure 400,503 {object} httpapi.Problem
// @Router /api/v1/foods/filters [get]
func (h FoodHandler) Filters(w http.ResponseWriter, r *http.Request) {
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil || len(q) > 0 {
		foodFailure(w, r, ErrFoodQuery)
		return
	}
	facets, err := h.Reader.Facets(r.Context())
	if err != nil {
		foodFailure(w, r, err)
		return
	}
	foodJSON(w, r, facets)
}
