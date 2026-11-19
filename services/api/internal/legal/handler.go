package legal

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"strings"
	"time"

	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
)

type Handler struct {
	Repository Repository
	Authorize  func(context.Context, string) (auth.Principal, error)
	Now        func() time.Time
	limits     httpapi.Limiter
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/me/legal-consents", h.private(h.Get))
	mux.HandleFunc("POST /api/v1/me/legal-consents", h.private(h.Post))
}

func failure(w http.ResponseWriter, r *http.Request, err error) {
	status, code := 503, "legal_unavailable"
	switch {
	case errors.Is(err, auth.ErrInvalid):
		status, code = 401, "invalid_credential"
		w.Header().Set("WWW-Authenticate", "Bearer")
	case errors.Is(err, ErrInvalid):
		status, code = 400, "invalid_consent"
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
		if h.Authorize == nil || h.Repository == nil {
			failure(w, r, ErrUnavailable)
			return
		}
		principal, err := h.Authorize(r.Context(), fields[1])
		if err != nil {
			failure(w, r, err)
			return
		}
		if !h.limits.Allow(principal.User.ID+":legal:"+r.Method, 30) {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		next(w, r, principal)
	}
}

// Get returns the latest decision per legal document for the current account.
// @Summary Current legal consents of the account
// @Tags legal
// @Security BearerAuth
// @Produce json
// @Success 200 {object} Current
// @Failure 401,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me/legal-consents [get]
func (h *Handler) Get(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	items, err := h.Repository.Current(r.Context(), p.User.ID)
	if err != nil {
		failure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, Current{Items: items})
}

// Post appends consent decisions made in the app (Terms, Privacy, health data).
// @Summary Record legal consent decisions
// @Tags legal
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param body body RecordRequest true "One to three decisions"
// @Success 200 {object} Current
// @Failure 400,401,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me/legal-consents [post]
func (h *Handler) Post(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 8<<10)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	var body RecordRequest
	if err = dec.Decode(&body); err == nil && dec.Decode(new(any)) != io.EOF {
		err = ErrInvalid
	}
	var large *http.MaxBytesError
	if errors.As(err, &large) {
		httpapi.Failure(w, r, 413, "body_too_large")
		return
	}
	if err != nil || len(body.Items) < 1 || len(body.Items) > 3 {
		failure(w, r, ErrInvalid)
		return
	}
	now := time.Now()
	if h.Now != nil {
		now = h.Now()
	}
	for _, item := range body.Items {
		if item.Validate(now) != nil {
			failure(w, r, ErrInvalid)
			return
		}
	}
	if err = h.Repository.Record(r.Context(), p.User.ID, body.Items); err != nil {
		failure(w, r, err)
		return
	}
	h.Get(w, r, p)
}
