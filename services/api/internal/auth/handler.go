package auth

import (
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
	"trainforge.local/api/internal/platform/httpapi"
)

type GoogleRequest struct {
	IDToken string `json:"idToken" minLength:"1" maxLength:"16384"`
}
type RefreshRequest struct {
	RefreshToken string `json:"refreshToken" minLength:"1" maxLength:"128"`
}
type window struct {
	start time.Time
	count int
}
type Handler struct {
	Service    Service
	RequireTLS bool
	mu         sync.Mutex
	windows    map[string]window
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/auth/google", h.guard(h.Login))
	mux.HandleFunc("POST /api/v1/auth/refresh", h.guard(h.Refresh))
	mux.HandleFunc("POST /api/v1/auth/logout", h.guard(h.Logout))
	mux.HandleFunc("GET /api/v1/me", h.guard(h.Me))
}
func (h *Handler) guard(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if h.RequireTLS && r.TLS == nil {
			httpapi.Failure(w, r, 426, "https_required")
			return
		}
		host, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			host = r.RemoteAddr
		}
		// Never trust client-supplied Forwarded/X-Forwarded-For headers.
		key := host
		if r.URL.Path == "/api/v1/auth/google" {
			key += ":login"
		}
		now := time.Now()
		h.mu.Lock()
		if h.windows == nil {
			h.windows = make(map[string]window)
		}
		for k, v := range h.windows {
			if now.Sub(v.start) >= time.Minute {
				delete(h.windows, k)
			}
		}
		entry := h.windows[key]
		limit := 60
		if strings.HasSuffix(key, ":login") {
			limit = 10
		}
		allowed := true
		if entry.count >= limit || len(h.windows) >= 4096 && entry.count == 0 {
			allowed = false
		} else {
			if entry.count == 0 {
				entry.start = now
			}
			entry.count++
			h.windows[key] = entry
		}
		h.mu.Unlock()
		if !allowed {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		next(w, r)
	}
}
func decode(w http.ResponseWriter, r *http.Request, target any) bool {
	media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return false
	}
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	err = decoder.Decode(target)
	if err == nil {
		var extra any
		if decoder.Decode(&extra) != io.EOF {
			err = errors.New("trailing JSON")
		}
	}
	if err != nil {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			httpapi.Failure(w, r, 413, "body_too_large")
		} else {
			httpapi.Failure(w, r, 400, "invalid_request")
		}
		return false
	}
	return true
}
func authFailure(w http.ResponseWriter, r *http.Request, err error) {
	if errors.Is(err, ErrInvalid) {
		w.Header().Set("WWW-Authenticate", "Bearer")
		httpapi.Failure(w, r, 401, "invalid_credential")
		return
	}
	httpapi.Failure(w, r, 503, "auth_unavailable")
}

// Login exchanges a real Google credential for an application session.
// @Summary Exchange Google ID token
// @Tags auth
// @Accept json
// @Produce json
// @Param body body GoogleRequest true "Google ID token"
// @Success 200 {object} Session
// @Failure 400,401,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/auth/google [post]
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var body GoogleRequest
	if !decode(w, r, &body) {
		return
	}
	if body.IDToken == "" || len(body.IDToken) > 16384 {
		httpapi.Failure(w, r, 400, "invalid_request")
		return
	}
	result, err := h.Service.Login(r.Context(), body.IDToken)
	if err != nil {
		authFailure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, result)
}

// Refresh atomically consumes the old refresh token; reuse revokes its family.
// @Summary Rotate session credentials
// @Tags auth
// @Accept json
// @Produce json
// @Param body body RefreshRequest true "Single-use refresh token"
// @Success 200 {object} Session
// @Failure 400,401,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/auth/refresh [post]
func (h *Handler) Refresh(w http.ResponseWriter, r *http.Request) {
	var body RefreshRequest
	if !decode(w, r, &body) {
		return
	}
	if body.RefreshToken == "" || len(body.RefreshToken) > 128 {
		httpapi.Failure(w, r, 400, "invalid_request")
		return
	}
	result, err := h.Service.Refresh(r.Context(), body.RefreshToken)
	if err != nil {
		authFailure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, result)
}

// Logout revokes this family, including access tokens, and is idempotent.
// @Summary Revoke the current device session
// @Tags auth
// @Accept json
// @Param body body RefreshRequest true "Refresh token of the device"
// @Success 204
// @Failure 400,413,415,426,429,503 {object} httpapi.Problem
// @Router /api/v1/auth/logout [post]
func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	var body RefreshRequest
	if !decode(w, r, &body) {
		return
	}
	if body.RefreshToken == "" || len(body.RefreshToken) > 128 {
		httpapi.Failure(w, r, 400, "invalid_request")
		return
	}
	if err := h.Service.Logout(r.Context(), body.RefreshToken); err != nil {
		authFailure(w, r, err)
		return
	}
	w.WriteHeader(204)
}

// Me returns only the authenticated user's identity.
// @Summary Current authenticated identity
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} User
// @Failure 401,426,429,503 {object} httpapi.Problem
// @Router /api/v1/me [get]
func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	fields := strings.Fields(r.Header.Get("Authorization"))
	if len(fields) != 2 || !strings.EqualFold(fields[0], "Bearer") {
		authFailure(w, r, ErrInvalid)
		return
	}
	result, err := h.Service.Me(r.Context(), fields[1])
	if err != nil {
		authFailure(w, r, err)
		return
	}
	httpapi.JSON(w, 200, result)
}
