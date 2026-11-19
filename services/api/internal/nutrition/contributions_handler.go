package nutrition

import (
	"encoding/json"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
)

type ContributionHandler struct{ *EntryHandler }

func (h *ContributionHandler) Register(m *http.ServeMux) {
	m.HandleFunc("POST /api/v1/me/food-contributions", h.private(h.CreateContribution))
	m.HandleFunc("GET /api/v1/me/food-contributions", h.private(h.ListContributions))
	m.HandleFunc("GET /api/v1/me/food-contributions/{id}", h.private(h.GetContribution))
	m.HandleFunc("DELETE /api/v1/me/food-contributions/{id}", h.private(h.DeleteContribution))
	m.HandleFunc("POST /api/v1/me/food-contributions/{id}/media", h.private(h.AttachMedia))
	m.HandleFunc("GET /api/v1/me/food-contributions/{id}/media/{mediaId}", h.private(h.GetMedia))
}
func contributionResponse(w http.ResponseWriter, r *http.Request, value any, e error, status int) {
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

// CreateContribution records only the reviewed copy explicitly authorized for reuse.
// @Summary Submit a voluntary food contribution
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body ContributionInput true "Explicit CC0 consent and food fields; no meal or account payload"
// @Success 201 {object} Contribution
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 409 {object} map[string]string
// @Router /api/v1/me/food-contributions [post]
func (h *ContributionHandler) CreateContribution(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	var in ContributionInput
	if _, ok := entryBodyLimit(w, r, &in, 64<<10); !ok {
		return
	}
	result, e := h.Store.CreateContribution(r.Context(), p, in)
	contributionResponse(w, r, result, e, 201)
}

// ListContributions lists only the authenticated contributor's submissions.
// @Summary List own food contributions
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param cursor query string false "Account-bound cursor"
// @Param limit query int false "Page size 1-100"
// @Success 200 {object} ContributionPage
// @Router /api/v1/me/food-contributions [get]
func (h *ContributionHandler) ListContributions(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, e := url.ParseQuery(r.URL.RawQuery)
	limit := 20
	if e != nil {
		entryFailure(w, r, ErrFoodQuery)
		return
	}
	for key, v := range q {
		if len(v) != 1 || len(v[0]) > 160 || (key != "limit" && key != "cursor") {
			entryFailure(w, r, ErrFoodQuery)
			return
		}
	}
	if raw := q.Get("limit"); raw != "" {
		limit, e = strconv.Atoi(raw)
		if e != nil {
			entryFailure(w, r, ErrFoodQuery)
			return
		}
	}
	result, e := h.Store.Contributions(r.Context(), p, q.Get("cursor"), limit)
	contributionResponse(w, r, result, e, 200)
}

// @Summary Read own food contribution status
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param id path string true "Contribution UUID"
// @Success 200 {object} Contribution
// @Router /api/v1/me/food-contributions/{id} [get]
func (h *ContributionHandler) GetContribution(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	result, e := h.Store.Contribution(r.Context(), p, r.PathValue("id"))
	contributionResponse(w, r, result, e, 200)
}

// @Summary Withdraw a contribution before review
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param id path string true "Contribution UUID"
// @Success 200 {object} Contribution
// @Failure 409 {object} map[string]string
// @Router /api/v1/me/food-contributions/{id} [delete]
func (h *ContributionHandler) DeleteContribution(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	result, e := h.Store.WithdrawContribution(r.Context(), p, r.PathValue("id"))
	contributionResponse(w, r, result, e, 200)
}

// @Summary Attach an optional label photo with metadata removed
// @Tags nutrition
// @Security BearerAuth
// @Accept image/jpeg,image/png
// @Produce json
// @Param id path string true "Contribution UUID"
// @Success 200 {object} Contribution
// @Router /api/v1/me/food-contributions/{id}/media [post]
func (h *ContributionHandler) AttachMedia(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	media, _, e := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if e != nil || (media != "image/jpeg" && media != "image/png") {
		httpapi.Failure(w, r, 415, "label_image_required")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 4<<20)
	raw, e := io.ReadAll(r.Body)
	if e != nil {
		httpapi.Failure(w, r, 413, "body_too_large")
		return
	}
	result, e := h.Store.AttachContributionMedia(r.Context(), p, r.PathValue("id"), raw, media)
	contributionResponse(w, r, result, e, 200)
}

// @Summary Read an own contribution's private label photo
// @Tags nutrition
// @Security BearerAuth
// @Produce image/jpeg
// @Param id path string true "Contribution UUID"
// @Param mediaId path string true "Media UUID"
// @Success 200 {file} binary
// @Router /api/v1/me/food-contributions/{id}/media/{mediaId} [get]
func (h *ContributionHandler) GetMedia(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	raw, e := h.Store.ContributionMedia(r.Context(), p, r.PathValue("id"), r.PathValue("mediaId"))
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	_, _ = w.Write(raw)
}
