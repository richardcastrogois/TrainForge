package catalog

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"trainforge.local/api/internal/platform/httpapi"
)

type CatalogHandler struct{ Reader Reader }

func (h CatalogHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/catalog/filters", h.Filters)
	mux.HandleFunc("GET /api/v1/catalog/programs", h.Programs)
	mux.HandleFunc("GET /api/v1/catalog/programs/{id}", h.Program)
	mux.HandleFunc("GET /api/v1/catalog/movements", h.Movements)
	mux.HandleFunc("GET /api/v1/catalog/movements/{id}", h.Movement)
}
func catalogFailure(w http.ResponseWriter, r *http.Request, err error) {
	status, code := 503, "catalog_unavailable"
	if errors.Is(err, ErrQuery) {
		status, code = 400, "invalid_catalog_query"
	}
	if errors.Is(err, ErrMissing) {
		status, code = 404, "catalog_item_unavailable"
	}
	httpapi.Failure(w, r, status, code)
}
func metadataJSON(w http.ResponseWriter, r *http.Request, v any) {
	body, err := json.Marshal(v)
	if err != nil {
		catalogFailure(w, r, ErrDependency)
		return
	}
	sum := sha256.Sum256(body)
	tag := `"` + hex.EncodeToString(sum[:]) + `"`
	w.Header().Set("ETag", tag)
	// Revalidate on every use. Withdrawal/permission checks always ran before here.
	w.Header().Set("Cache-Control", "private, no-cache, must-revalidate")
	for _, candidate := range strings.Split(r.Header.Get("If-None-Match"), ",") {
		if strings.TrimPrefix(strings.TrimSpace(candidate), "W/") == tag || strings.TrimSpace(candidate) == "*" {
			w.WriteHeader(http.StatusNotModified)
			return
		}
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(200)
	_, _ = w.Write(body)
}
func (h CatalogHandler) list(w http.ResponseWriter, r *http.Request, kinds []string) {
	f, err := parseFilters(r.URL.Query(), kinds)
	if err != nil {
		catalogFailure(w, r, err)
		return
	}
	page, err := h.Reader.List(r.Context(), f)
	if err != nil {
		catalogFailure(w, r, err)
		return
	}
	metadataJSON(w, r, page)
}
func (h CatalogHandler) detail(w http.ResponseWriter, r *http.Request, kinds []string) {
	id := r.PathValue("id")
	if !assetIDPattern.MatchString(id) {
		catalogFailure(w, r, ErrQuery)
		return
	}
	version, mode, err := parseDetail(r.URL.Query())
	if err != nil {
		catalogFailure(w, r, err)
		return
	}
	item, err := h.Reader.Detail(r.Context(), kinds, id, version, mode)
	if err != nil {
		catalogFailure(w, r, err)
		return
	}
	metadataJSON(w, r, item)
}

// Programs lists authorized metadata only, preserving program/collection kinds.
// @Summary List reviewed program and collection metadata
// @Tags catalog
// @Produce json
// @Param mode query string false "consultation (default) or practice; unknown requirements never imply eligibility" Enums(consultation,practice)
// @Param q query string false "Literal title substring, maximum 100 UTF-8 bytes"
// @Param environment query string false "Exact source environment; unknown values do not match"
// @Param population query string false "Exact source population"
// @Param modality query string false "Exact source modality"
// @Param equipment query string false "Exact source equipment name"
// @Param category query string false "Exact source category"
// @Param limit query int false "Page size" minimum(1) maximum(50) default(20)
// @Param cursor query string false "Opaque cursor bound to the filters and page size"
// @Success 200 {object} CatalogPage
// @Success 304
// @Failure 400,503 {object} httpapi.Problem
// @Router /api/v1/catalog/programs [get]
func (h CatalogHandler) Programs(w http.ResponseWriter, r *http.Request) {
	h.list(w, r, []string{"program", "collection"})
}

// Program reads one immutable authorized version; withdrawn content is never cached through.
// @Summary Reviewed program or collection metadata
// @Tags catalog
// @Produce json
// @Param id path string true "Editorial asset ID"
// @Param versionId query string false "Exact SHA-256 version; latest by default"
// @Param mode query string false "consultation or practice" Enums(consultation,practice)
// @Success 200 {object} CatalogItem
// @Success 304
// @Failure 400,404,503 {object} httpapi.Problem
// @Router /api/v1/catalog/programs/{id} [get]
func (h CatalogHandler) Program(w http.ResponseWriter, r *http.Request) {
	h.detail(w, r, []string{"program", "collection"})
}

// Movements lists movement references, without relabelling them as executable programs.
// @Summary List reviewed movement metadata
// @Tags catalog
// @Produce json
// @Param mode query string false "consultation or practice" Enums(consultation,practice)
// @Param q query string false "Literal title substring"
// @Param environment query string false "Exact source environment"
// @Param population query string false "Exact source population"
// @Param modality query string false "Exact source modality"
// @Param equipment query string false "Exact source equipment name"
// @Param category query string false "Exact source category"
// @Param limit query int false "Page size" minimum(1) maximum(50) default(20)
// @Param cursor query string false "Opaque cursor bound to filters"
// @Success 200 {object} CatalogPage
// @Success 304
// @Failure 400,503 {object} httpapi.Problem
// @Router /api/v1/catalog/movements [get]
func (h CatalogHandler) Movements(w http.ResponseWriter, r *http.Request) {
	h.list(w, r, []string{"movement"})
}

// Movement returns source, attribution, requirements and explicit unavailability.
// @Summary Reviewed movement metadata
// @Tags catalog
// @Produce json
// @Param id path string true "Editorial movement ID"
// @Param versionId query string false "Exact SHA-256 version"
// @Param mode query string false "consultation or practice" Enums(consultation,practice)
// @Success 200 {object} CatalogItem
// @Success 304
// @Failure 400,404,503 {object} httpapi.Problem
// @Router /api/v1/catalog/movements/{id} [get]
func (h CatalogHandler) Movement(w http.ResponseWriter, r *http.Request) {
	h.detail(w, r, []string{"movement"})
}

// Filters lists only actual values present in visible source metadata.
// @Summary Source-backed catalog filters and coverage
// @Tags catalog
// @Produce json
// @Success 200 {object} CatalogFacets
// @Success 304
// @Failure 400,503 {object} httpapi.Problem
// @Router /api/v1/catalog/filters [get]
func (h CatalogHandler) Filters(w http.ResponseWriter, r *http.Request) {
	if len(r.URL.Query()) != 0 {
		catalogFailure(w, r, ErrQuery)
		return
	}
	facets, err := h.Reader.Facets(r.Context())
	if err != nil {
		catalogFailure(w, r, err)
		return
	}
	metadataJSON(w, r, facets)
}
