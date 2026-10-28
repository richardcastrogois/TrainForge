package privacy

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
	"unicode"
	"unicode/utf8"
)

type Handler struct {
	Service   Service
	Authorize func(context.Context, string) (auth.Principal, error)
	limits    httpapi.Limiter
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/privacy", h.Policy)
	mux.HandleFunc("GET /api/v1/me/export", h.private(h.Export))
	mux.HandleFunc("POST /api/v1/me/deletion-intent", h.private(h.Intent))
	mux.HandleFunc("DELETE /api/v1/me", h.private(h.Delete))
}
func failure(w http.ResponseWriter, r *http.Request, err error) {
	status, code := 503, "privacy_unavailable"
	switch {
	case errors.Is(err, auth.ErrInvalid):
		status, code = 401, "invalid_credential"
		w.Header().Set("WWW-Authenticate", "Bearer")
	case errors.Is(err, ErrQuery):
		status, code = 400, "invalid_privacy_request"
	case errors.Is(err, ErrConfirmation):
		status, code = 400, "deletion_confirmation_invalid"
	case errors.Is(err, ErrReauthenticate):
		status, code = 409, "recent_login_required"
	}
	httpapi.Failure(w, r, status, code)
}
func (h *Handler) private(next func(http.ResponseWriter, *http.Request, auth.Principal)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		values := r.Header.Values("Authorization")
		if len(values) != 1 {
			failure(w, r, auth.ErrInvalid)
			return
		}
		fields := strings.Fields(values[0])
		if len(fields) != 2 || !strings.EqualFold(fields[0], "Bearer") {
			failure(w, r, auth.ErrInvalid)
			return
		}
		if h.Authorize == nil {
			failure(w, r, ErrUnavailable)
			return
		}
		principal, err := h.Authorize(r.Context(), fields[1])
		if err != nil {
			failure(w, r, err)
			return
		}
		limit := 60
		if r.Method == "POST" {
			limit = 3
		}
		key := principal.User.ID + ":" + r.Method
		if !h.limits.Allow(key, limit) {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		next(w, r, principal)
	}
}
func decode(w http.ResponseWriter, r *http.Request, v any) bool {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return false
	}
	r.Body = http.MaxBytesReader(w, r.Body, 8<<10)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	err = dec.Decode(v)
	if err == nil {
		err = dec.Decode(new(any))
		if err == io.EOF {
			return true
		}
		if err == nil {
			err = ErrQuery
		}
	}
	var large *http.MaxBytesError
	if errors.As(err, &large) {
		httpapi.Failure(w, r, 413, "body_too_large")
	} else {
		failure(w, r, ErrQuery)
	}
	return false
}
func emptyQuery(w http.ResponseWriter, r *http.Request) bool {
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil || len(q) != 0 {
		failure(w, r, ErrQuery)
		return false
	}
	return true
}
func parseExport(q url.Values, user string) (ExportFilter, error) {
	f := ExportFilter{Section: "account", Limit: 20}
	for k, v := range q {
		if (k != "section" && k != "limit" && k != "cursor") || len(v) != 1 || len(v[0]) > 2048 {
			return f, ErrQuery
		}
	}
	if value := q.Get("section"); value != "" {
		f.Section = value
	}
	if _, ok := sections[f.Section]; !ok {
		return f, ErrQuery
	}
	if value := q.Get("limit"); value != "" {
		n, err := strconv.Atoi(value)
		if err != nil || n < 1 || n > 50 {
			return f, ErrQuery
		}
		f.Limit = n
	}
	if value := q.Get("cursor"); value != "" {
		raw, err := base64.RawURLEncoding.DecodeString(value)
		if err != nil {
			return f, ErrQuery
		}
		var c struct{ After, Filter string }
		d := json.NewDecoder(bytes.NewReader(raw))
		d.DisallowUnknownFields()
		if d.Decode(&c) != nil || d.Decode(new(any)) != io.EOF || len(c.After) < 1 || len(c.After) > 512 || !utf8.ValidString(c.After) || strings.IndexFunc(c.After, unicode.IsControl) >= 0 || c.Filter != fingerprint(user, f) {
			return f, ErrQuery
		}
		f.After = c.After
	}
	return f, nil
}

// Policy describes implemented data handling and operational backup limitations.
// @Summary Privacy and data lifecycle policy
// @Tags privacy
// @Produce json
// @Success 200 {object} Policy
// @Failure 400 {object} httpapi.Problem
// @Router /api/v1/privacy [get]
func (h *Handler) Policy(w http.ResponseWriter, r *http.Request) {
	if !emptyQuery(w, r) {
		return
	}
	w.Header().Set("Cache-Control", "no-store")
	httpapi.JSON(w, 200, CurrentPolicy())
}

// Export returns a bounded section of the authenticated account, never another ID.
// @Summary Export a page of the current account's data
// @Tags privacy
// @Security BearerAuth
// @Produce json
// @Param section query string false "Owned data section" Enums(account,sessions,enrollments,occurrences,activitySessions,activityEvents,foods,foodEntries,trainingConfigurations)
// @Param limit query int false "Maximum page size" minimum(1) maximum(50) default(20)
// @Param cursor query string false "Opaque cursor bound to user, section and limit"
// @Success 200 {object} ExportPage
// @Failure 400,401,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me/export [get]
func (h *Handler) Export(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		failure(w, r, ErrQuery)
		return
	}
	f, err := parseExport(q, p.User.ID)
	if err != nil {
		failure(w, r, err)
		return
	}
	if h.Service.Repository == nil {
		failure(w, r, ErrUnavailable)
		return
	}
	page, err := h.Service.Repository.Export(r.Context(), p, f)
	if err != nil {
		failure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, page)
}

// Intent requires recent Google authentication and explicit confirmation.
// @Summary Create a five-minute account deletion challenge
// @Tags privacy
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body IntentRequest true "Explicit account deletion confirmation"
// @Success 200 {object} Intent
// @Failure 400,401,409,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me/deletion-intent [post]
func (h *Handler) Intent(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !emptyQuery(w, r) {
		return
	}
	var body IntentRequest
	if !decode(w, r, &body) {
		return
	}
	result, err := h.Service.Intent(r.Context(), p, body.Confirmation)
	if err != nil {
		failure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, result)
}

// Delete atomically erases owned live data. Historical backup limits remain explicit.
// @Summary Confirm deletion of the current TrainForge account
// @Tags privacy
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body DeleteRequest true "Confirmation and challenge of this account/session"
// @Success 200 {object} Erased
// @Failure 400,401,409,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me [delete]
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !emptyQuery(w, r) {
		return
	}
	var body DeleteRequest
	if !decode(w, r, &body) {
		return
	}
	result, err := h.Service.Delete(r.Context(), p, body)
	if err != nil {
		failure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, result)
}
