package nutrition

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
)

type EntryHandler struct {
	Store     NutritionStore
	Authorize func(context.Context, string) (auth.Principal, error)
	limits    httpapi.Limiter
}

func (h *EntryHandler) Register(m *http.ServeMux) {
	m.HandleFunc("POST /api/v1/me/foods", h.private(h.CreateFood))
	m.HandleFunc("GET /api/v1/me/foods", h.private(h.Foods))
	m.HandleFunc("POST /api/v1/me/food-entries", h.private(h.CreateEntry))
	m.HandleFunc("GET /api/v1/me/food-entries", h.private(h.Entries))
	m.HandleFunc("PATCH /api/v1/me/food-entries/{id}", h.private(h.EditEntry))
	m.HandleFunc("DELETE /api/v1/me/food-entries/{id}", h.private(h.DeleteEntry))
	m.HandleFunc("GET /api/v1/me/food-summary", h.private(h.Summary))
}
func entryFailure(w http.ResponseWriter, r *http.Request, e error) {
	status, code := 503, "nutrition_unavailable"
	switch {
	case errors.Is(e, auth.ErrInvalid):
		status, code = 401, "invalid_credential"
		w.Header().Set("WWW-Authenticate", "Bearer")
	case errors.Is(e, ErrFoodQuery):
		status, code = 400, "invalid_nutrition_request"
	case errors.Is(e, ErrFoodMissing):
		status, code = 404, "food_or_entry_unavailable"
	case errors.Is(e, ErrEntryConflict):
		status, code = 409, "nutrition_conflict"
	}
	httpapi.Failure(w, r, status, code)
}
func (h *EntryHandler) private(next func(http.ResponseWriter, *http.Request, auth.Principal)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		values := r.Header.Values("Authorization")
		if len(values) != 1 {
			entryFailure(w, r, auth.ErrInvalid)
			return
		}
		f := strings.Fields(values[0])
		if len(f) != 2 || !strings.EqualFold(f[0], "Bearer") {
			entryFailure(w, r, auth.ErrInvalid)
			return
		}
		if h.Authorize == nil {
			entryFailure(w, r, ErrFoodUnavailable)
			return
		}
		p, e := h.Authorize(r.Context(), f[1])
		if e != nil {
			entryFailure(w, r, e)
			return
		}
		expected := r.Header.Values("X-TrainForge-Account")
		if len(expected) > 1 || (len(expected) == 1 && (!uuidPattern.MatchString(expected[0]) || expected[0] != p.User.ID)) {
			entryFailure(w, r, ErrEntryConflict)
			return
		}
		if !h.limits.Allow(p.User.ID+":nutrition", 60) {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		next(w, r, p)
	}
}

// Reject duplicate JSON object keys as well as trailing values and unknown fields.
func uniqueJSON(d *json.Decoder) error {
	token, e := d.Token()
	if e != nil {
		return e
	}
	delimiter, ok := token.(json.Delim)
	if !ok {
		return nil
	}
	switch delimiter {
	case '{':
		seen := map[string]bool{}
		for d.More() {
			key, e := d.Token()
			if e != nil {
				return e
			}
			s, ok := key.(string)
			if !ok || seen[s] {
				return ErrFoodQuery
			}
			seen[s] = true
			if e = uniqueJSON(d); e != nil {
				return e
			}
		}
	case '[':
		for d.More() {
			if e = uniqueJSON(d); e != nil {
				return e
			}
		}
	default:
		return ErrFoodQuery
	}
	_, e = d.Token()
	return e
}
func entryBody(w http.ResponseWriter, r *http.Request, target any) ([]byte, bool) {
	media, _, e := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if e != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return nil, false
	}
	r.Body = http.MaxBytesReader(w, r.Body, 16<<10)
	raw, e := io.ReadAll(r.Body)
	if e != nil {
		httpapi.Failure(w, r, 413, "body_too_large")
		return nil, false
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if uniqueJSON(d) != nil || d.Decode(new(any)) != io.EOF {
		entryFailure(w, r, ErrFoodQuery)
		return nil, false
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if d.Decode(target) != nil {
		entryFailure(w, r, ErrFoodQuery)
		return nil, false
	}
	canonical, e := json.Marshal(target)
	if e != nil {
		entryFailure(w, r, ErrFoodQuery)
		return nil, false
	}
	return canonical, true
}
func noEntryQuery(w http.ResponseWriter, r *http.Request) bool {
	q, e := url.ParseQuery(r.URL.RawQuery)
	if e != nil || len(q) != 0 {
		entryFailure(w, r, ErrFoodQuery)
		return false
	}
	return true
}
func (h *EntryHandler) mutate(w http.ResponseWriter, r *http.Request, p auth.Principal, op string, target any) {
	if !noEntryQuery(w, r) {
		return
	}
	keys := r.Header.Values("Idempotency-Key")
	if len(keys) != 1 || !uuidPattern.MatchString(keys[0]) {
		entryFailure(w, r, ErrFoodQuery)
		return
	}
	id := r.PathValue("id")
	if id != "" && !uuidPattern.MatchString(id) {
		entryFailure(w, r, ErrFoodQuery)
		return
	}
	raw, ok := entryBody(w, r, target)
	if !ok {
		return
	}
	if id != "" {
		op += ":" + id
	}
	result, status, e := h.Store.Mutate(r.Context(), p, op, id, keys[0], raw)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(result)
}

// CreateFood stores a private, immutable declaration, without recording consumption.
// @Summary Create own food declaration
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param Idempotency-Key header string true "UUID, stable across retries; 24-hour retention"
// @Param body body OwnFoodInput true "Private declaration, nullable basis and nutrient values"
// @Success 201 {object} FoodDetail
// @Failure 400,401,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/foods [post]
func (h *EntryHandler) CreateFood(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	h.mutate(w, r, p, "own-food", &OwnFoodInput{})
}

// CreateEntry records only explicitly submitted consumption.
// @Summary Record food consumption
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param Idempotency-Key header string true "UUID stable across retries"
// @Param body body EntryInput true "Exact food version, quantity, unit, preparation, time, zone and measured/estimated evidence; revision zero"
// @Success 201 {object} Entry
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-entries [post]
func (h *EntryHandler) CreateEntry(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	h.mutate(w, r, p, "create-entry", &EntryInput{})
}

// EditEntry preserves the food version and the previous quantity/time/preparation.
// @Summary Correct own consumption with optimistic revision
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Entry UUID"
// @Param Idempotency-Key header string true "UUID stable across retries"
// @Param body body EntryInput true "Complete replacement; same food version and current revision; maximum 100 corrections"
// @Success 200 {object} Entry
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-entries/{id} [patch]
func (h *EntryHandler) EditEntry(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	h.mutate(w, r, p, "edit-entry", &EntryInput{})
}

// DeleteEntry excludes the record from totals, retaining a private tombstone until account erasure.
// @Summary Remove own consumption from active history
// @Tags nutrition
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Entry UUID"
// @Param Idempotency-Key header string true "UUID stable across retries"
// @Param body body EntryInput true "Current revision; other fields omitted"
// @Success 200 {object} Entry
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-entries/{id} [delete]
func (h *EntryHandler) DeleteEntry(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	h.mutate(w, r, p, "delete-entry", &EntryInput{})
}
func filterFingerprint(p auth.Principal, f privateFilter, kind string) string {
	return hex.EncodeToString(digest([]byte(p.User.ID + "|" + kind + "|" + f.Q + "|" + f.Day + "|" + f.Zone)))
}

type entryCursor struct{ After, Filter string }

func parsePrivate(q url.Values, p auth.Principal, kind string) (privateFilter, error) {
	f := privateFilter{Q: q.Get("q"), Day: q.Get("date"), Zone: q.Get("timezone"), Limit: 10}
	for k, v := range q {
		if len(v) != 1 || len(v[0]) > 1024 || (k != "q" && k != "date" && k != "timezone" && k != "limit" && k != "cursor") {
			return f, ErrFoodQuery
		}
		if kind == "foods" && (k == "date" || k == "timezone") {
			return f, ErrFoodQuery
		}
		if kind != "foods" && k == "q" {
			return f, ErrFoodQuery
		}
		if kind == "summary" && (k == "cursor" || k == "limit") {
			return f, ErrFoodQuery
		}
	}
	if !textValid(f.Q, 0, 100) {
		return f, ErrFoodQuery
	}
	if s := q.Get("limit"); s != "" {
		n, e := strconv.Atoi(s)
		if e != nil || n < 1 || n > 20 {
			return f, ErrFoodQuery
		}
		f.Limit = n
	}
	if kind != "foods" {
		if _, _, e := dayBounds(f.Day, f.Zone); e != nil {
			return f, e
		}
	}
	if s := q.Get("cursor"); s != "" {
		raw, e := base64.RawURLEncoding.DecodeString(s)
		if e != nil {
			return f, ErrFoodQuery
		}
		var c entryCursor
		d := json.NewDecoder(bytes.NewReader(raw))
		d.DisallowUnknownFields()
		if d.Decode(&c) != nil || d.Decode(new(any)) != io.EOF || c.Filter != filterFingerprint(p, f, kind) || (!validAfter(c.After, kind)) {
			return f, ErrFoodQuery
		}
		f.After = c.After
	}
	return f, nil
}
func validAfter(s, kind string) bool {
	if kind == "foods" {
		return privateFoodPattern.MatchString(s)
	}
	parts := strings.Split(s, "|")
	if len(parts) != 2 || !uuidPattern.MatchString(parts[1]) {
		return false
	}
	_, err := time.Parse(time.RFC3339, parts[0])
	return err == nil
}
func cursorFor(id string, p auth.Principal, f privateFilter, kind string) *string {
	raw, _ := json.Marshal(entryCursor{id, filterFingerprint(p, f, kind)})
	s := base64.RawURLEncoding.EncodeToString(raw)
	return &s
}
func entryJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
func (h *EntryHandler) filter(w http.ResponseWriter, r *http.Request, p auth.Principal, kind string) (privateFilter, bool) {
	q, e := url.ParseQuery(r.URL.RawQuery)
	if e != nil {
		entryFailure(w, r, ErrFoodQuery)
		return privateFilter{}, false
	}
	f, e := parsePrivate(q, p, kind)
	if e != nil {
		entryFailure(w, r, e)
		return f, false
	}
	return f, true
}

// Foods queries only this account's private declarations.
// @Summary Search own foods
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param q query string false "Literal name, maximum 100 characters"
// @Param limit query int false "1..20; default 10"
// @Param cursor query string false "Account and filter-bound cursor"
// @Success 200 {object} NutritionPage
// @Failure 400,401,429,503 {object} httpapi.Problem
// @Router /api/v1/me/foods [get]
func (h *EntryHandler) Foods(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	f, ok := h.filter(w, r, p, "foods")
	if !ok {
		return
	}
	items, e := h.Store.Foods(r.Context(), p, f)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	var next *string
	if len(items) > f.Limit {
		next = cursorFor(items[f.Limit-1].ID, p, f, "foods")
		items = items[:f.Limit]
	}
	raw, _ := json.Marshal(items)
	entryJSON(w, NutritionPage{raw, next})
}

// Entries returns active consumption for a calendar day in the requested zone.
// @Summary Own consumption history by local day
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param date query string true "YYYY-MM-DD"
// @Param timezone query string true "IANA name, UTC or fixed offset such as -03:00"
// @Param limit query int false "1..20; default 10"
// @Param cursor query string false "Account and filter-bound cursor"
// @Success 200 {object} NutritionPage
// @Failure 400,401,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-entries [get]
func (h *EntryHandler) Entries(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	f, ok := h.filter(w, r, p, "entries")
	if !ok {
		return
	}
	items, e := h.Store.Entries(r.Context(), p, f, false)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	var next *string
	if len(items) > f.Limit {
		next = cursorFor(items[f.Limit-1].OccurredAt+"|"+items[f.Limit-1].ID, p, f, "entries")
		items = items[:f.Limit]
	}
	raw, _ := json.Marshal(items)
	entryJSON(w, NutritionPage{raw, next})
}

// Summary never silently truncates totals or merges unrelated nutrient methods.
// @Summary Daily confirmed consumption subtotals by source column
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param date query string true "YYYY-MM-DD"
// @Param timezone query string true "IANA name, UTC or fixed offset"
// @Success 200 {object} NutritionTotals
// @Failure 400,401,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-summary [get]
func (h *EntryHandler) Summary(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	f, ok := h.filter(w, r, p, "summary")
	if !ok {
		return
	}
	items, e := h.Store.Entries(r.Context(), p, f, true)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	result := totals(items, len(items) <= 100)
	if !result.Complete {
		result.Notice = "Mais de 100 registros neste dia; total não calculado. Consulte o histórico paginado."
	}
	entryJSON(w, result)
}
