package activity

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"net/url"
	"reflect"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
	"unicode/utf8"
)

type Handler struct {
	Store     Repository
	Authorize func(context.Context, string) (auth.Principal, error)
	limits    httpapi.Limiter
}

func (h *Handler) Register(m *http.ServeMux) {
	m.HandleFunc("GET /api/v1/me/activity", h.private(h.Feed))
	m.HandleFunc("GET /api/v1/me/activity-sessions/{id}", h.private(h.Detail))
	m.HandleFunc("POST /api/v1/me/activity-sessions", h.private(h.Start))
	m.HandleFunc("POST /api/v1/me/activity-sessions/{id}/commands", h.private(h.Command))
}
func failure(w http.ResponseWriter, r *http.Request, e error) {
	status, code := 503, "activity_unavailable"
	switch {
	case errors.Is(e, auth.ErrInvalid):
		status, code = 401, "invalid_credential"
		w.Header().Set("WWW-Authenticate", "Bearer")
	case errors.Is(e, ErrInvalid):
		status, code = 400, "invalid_activity_command"
	case errors.Is(e, ErrMissing):
		status, code = 404, "activity_not_found"
	case errors.Is(e, ErrConflict):
		status, code = 409, "activity_conflict"
	case errors.Is(e, ErrPracticeUnavailable):
		status, code = 409, "activity_practice_unavailable"
	}
	httpapi.Failure(w, r, status, code)
}
func (h *Handler) private(next func(http.ResponseWriter, *http.Request, auth.Principal)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		a := r.Header.Values("Authorization")
		if len(a) != 1 {
			failure(w, r, auth.ErrInvalid)
			return
		}
		parts := strings.Fields(a[0])
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			failure(w, r, auth.ErrInvalid)
			return
		}
		if h.Authorize == nil || h.Store == nil {
			failure(w, r, ErrUnavailable)
			return
		}
		p, e := h.Authorize(r.Context(), parts[1])
		if e != nil {
			failure(w, r, e)
			return
		}
		owners := r.Header.Values("X-TrainForge-Account")
		if len(owners) > 1 || (len(owners) == 1 && owners[0] != p.User.ID) {
			failure(w, r, auth.ErrInvalid)
			return
		}
		if !h.limits.Allow(p.User.ID, 60) {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		q, e := url.ParseQuery(r.URL.RawQuery)
		if e != nil || len(q) != 0 {
			failure(w, r, ErrInvalid)
			return
		}
		next(w, r, p)
	}
}
func uniqueJSON(d *json.Decoder) error {
	t, e := d.Token()
	if e != nil {
		return e
	}
	kind, ok := t.(json.Delim)
	if !ok {
		return nil
	}
	switch kind {
	case '{':
		seen := map[string]bool{}
		for d.More() {
			k, e := d.Token()
			if e != nil {
				return e
			}
			s, ok := k.(string)
			if !ok || seen[s] {
				return ErrInvalid
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
		return ErrInvalid
	}
	_, e = d.Token()
	return e
}

// encoding/json alone accepts case aliases and null scalars. A declared
// contract accepts its exact field spellings; absence is still handled by its
// semantic validator and nullable measurements remain explicit pointers.
func jsonShape(raw []byte, t reflect.Type) bool {
	if t.Kind() == reflect.Pointer {
		if bytes.Equal(bytes.TrimSpace(raw), []byte("null")) {
			return true
		}
		return jsonShape(raw, t.Elem())
	}
	if t == reflect.TypeOf(time.Time{}) {
		var v string
		return json.Unmarshal(raw, &v) == nil
	}
	if bytes.Equal(bytes.TrimSpace(raw), []byte("null")) {
		return t.Kind() == reflect.Slice || t.Kind() == reflect.Map
	}
	switch t.Kind() {
	case reflect.Struct:
		var m map[string]json.RawMessage
		if json.Unmarshal(raw, &m) != nil || m == nil {
			return false
		}
		// Position zero is a valid slot. Its absence must not silently select
		// the first movement when the caller omitted the slot identity.
		if t == reflect.TypeOf(Set{}) {
			if _, present := m["position"]; !present {
				return false
			}
		}
		allowed := map[string]reflect.Type{}
		for n := 0; n < t.NumField(); n++ {
			f := t.Field(n)
			if !f.IsExported() {
				continue
			}
			tag := strings.Split(f.Tag.Get("json"), ",")[0]
			if tag == "-" {
				continue
			}
			if tag == "" {
				tag = f.Name
			}
			allowed[tag] = f.Type
		}
		for k, v := range m {
			f, ok := allowed[k]
			if !ok || !jsonShape(v, f) {
				return false
			}
		}
	case reflect.Slice:
		var a []json.RawMessage
		if json.Unmarshal(raw, &a) != nil {
			return false
		}
		for _, v := range a {
			if !jsonShape(v, t.Elem()) {
				return false
			}
		}
	}
	return true
}
func strict(raw []byte, target any) bool {
	if !utf8.Valid(raw) {
		return false
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if uniqueJSON(d) != nil || d.Decode(new(any)) != io.EOF {
		return false
	}
	t := reflect.TypeOf(target)
	if t == nil || t.Kind() != reflect.Pointer || !jsonShape(raw, t.Elem()) {
		return false
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	return d.Decode(target) == nil && d.Decode(new(any)) == io.EOF
}
func body(w http.ResponseWriter, r *http.Request, target any) (string, bool) {
	media, _, e := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if e != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return "", false
	}
	keys := r.Header.Values("Idempotency-Key")
	if len(keys) != 1 || !uuid.MatchString(keys[0]) {
		failure(w, r, ErrInvalid)
		return "", false
	}
	raw, e := io.ReadAll(http.MaxBytesReader(w, r.Body, 16<<10))
	if e != nil {
		var size *http.MaxBytesError
		if errors.As(e, &size) {
			httpapi.Failure(w, r, 413, "body_too_large")
		} else {
			failure(w, r, ErrInvalid)
		}
		return "", false
	}
	if !strict(raw, target) {
		failure(w, r, ErrInvalid)
		return "", false
	}
	return keys[0], true
}

// Feed returns a bounded, private activity view; absence never creates a plan.
// @Summary Read own upcoming activity and execution history
// @Tags activity
// @Security BearerAuth
// @Produce json
// @Success 200 {object} Feed
// @Failure 400,401,429,503 {object} httpapi.Problem
// @Router /api/v1/me/activity [get]
func (h *Handler) Feed(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	v, e := h.Store.Feed(r.Context(), p)
	if e != nil {
		failure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, v)
}

// Detail reads the persisted original prescription and confirmed execution.
// @Summary Read own activity session
// @Tags activity
// @Security BearerAuth
// @Produce json
// @Param id path string true "Session UUID"
// @Success 200 {object} Detail
// @Failure 400,401,404,429,503 {object} httpapi.Problem
// @Router /api/v1/me/activity-sessions/{id} [get]
func (h *Handler) Detail(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	id := r.PathValue("id")
	if !uuid.MatchString(id) {
		failure(w, r, ErrInvalid)
		return
	}
	v, e := h.Store.Detail(r.Context(), p, id)
	if e != nil {
		failure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, v)
}

// Start requires an already owned occurrence and an exact, approved prescription.
// @Summary Start an existing owned activity occurrence
// @Tags activity
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param Idempotency-Key header string true "UUID retained by the durable activity event"
// @Param body body StartRequest true "Owned occurrence only; no prescription or owner supplied by client"
// @Success 201 {object} MutationResult
// @Success 200 {object} MutationResult
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/activity-sessions [post]
func (h *Handler) Start(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	var c StartRequest
	key, ok := body(w, r, &c)
	if !ok {
		return
	}
	v, e := h.Store.Start(r.Context(), p, c, key)
	if e != nil {
		failure(w, r, e)
		return
	}
	status := 201
	if v.Replayed {
		status = 200
	}
	httpapi.JSON(w, status, v)
}

// Command commits one explicit execution action with server time and stable intent.
// @Summary Record, pause, resume or explicitly close an owned activity session
// @Tags activity
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Session UUID"
// @Param Idempotency-Key header string true "Command UUID stable across retries"
// @Param body body CommandInput true "Expected revision and explicit action; no client timestamp"
// @Success 200 {object} MutationResult
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/activity-sessions/{id}/commands [post]
func (h *Handler) Command(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	id := r.PathValue("id")
	if !uuid.MatchString(id) {
		failure(w, r, ErrInvalid)
		return
	}
	var c CommandInput
	key, ok := body(w, r, &c)
	if !ok {
		return
	}
	v, e := h.Store.Command(r.Context(), p, id, c, key)
	if e != nil {
		failure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, v)
}
