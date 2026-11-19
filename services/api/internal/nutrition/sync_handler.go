package nutrition

import (
	"encoding/json"
	"net/http"
	"net/url"
	"strconv"
	"trainforge.local/api/internal/auth"
)

// SyncHandler shares authentication/account validation with legacy nutrition.
type SyncHandler struct{ *EntryHandler }

func (h *SyncHandler) Register(m *http.ServeMux) {
	m.HandleFunc("GET /api/v1/me/nutrition/sync", h.private(h.Changes))
	m.HandleFunc("GET /api/v1/me/nutrition/changes", h.private(h.Changes))
	m.HandleFunc("POST /api/v1/me/nutrition/sync", h.private(h.Push))
}

// Push applies durable operations individually, preserving successful results if
// a later operation needs its catalog or a user-resolved conflict.
// @Summary Synchronize durable offline nutrition operations
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body SyncPush true "Stable operation IDs, dependencies and legacy domain bodies"
// @Success 200 {object} SyncPushResult
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 503 {object} map[string]string
// @Router /api/v1/me/nutrition/sync [post]
func (h *SyncHandler) Push(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noEntryQuery(w, r) {
		return
	}
	var push SyncPush
	if _, ok := entryBodyLimit(w, r, &push, 2<<20); !ok {
		return
	}
	result, e := h.Store.SyncPush(r.Context(), p, push)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}

// Changes starts with a complete paginated baseline, followed by changes and
// tombstones. Cursors belong to one account and use commit-ordered sequences.
// @Summary Read account nutrition baseline and changes
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param cursor query string false "Opaque account-bound checkpoint"
// @Param limit query int false "Page size 1-200, default 100"
// @Success 200 {object} SyncPage
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 503 {object} map[string]string
// @Router /api/v1/me/nutrition/changes [get]
// @Router /api/v1/me/nutrition/sync [get]
func (h *SyncHandler) Changes(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	query, e := url.ParseQuery(r.URL.RawQuery)
	limit := 100
	if e != nil {
		entryFailure(w, r, ErrFoodQuery)
		return
	}
	for key, values := range query {
		if len(values) != 1 || len(values[0]) > 160 || (key != "cursor" && key != "limit") {
			entryFailure(w, r, ErrFoodQuery)
			return
		}
	}
	if raw := query.Get("limit"); raw != "" {
		limit, e = strconv.Atoi(raw)
		if e != nil {
			entryFailure(w, r, ErrFoodQuery)
			return
		}
	}
	result, e := h.Store.SyncChanges(r.Context(), p, query.Get("cursor"), limit)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(result)
}
