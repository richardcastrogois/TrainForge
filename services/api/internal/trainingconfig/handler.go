package trainingconfig

import (
	"bytes"
	"context"
	"crypto/sha256"
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
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
	"unicode"
	"unicode/utf8"
)

type Current struct {
	ResourceLabels       []ResourceOption `json:"resourceLabels"`
	UnavailableResources []ResourceRef    `json:"unavailableResources"`
	Current              *Snapshot        `json:"current" extensions:"x-nullable"`
}
type ResourcePage struct {
	Items      []ResourceOption `json:"items"`
	NextCursor *string          `json:"nextCursor" extensions:"x-nullable"`
}
type Handler struct {
	Service       Service
	ResourceStore ResourceRepository
	Authorize     func(context.Context, string) (auth.Principal, error)
	limits        httpapi.Limiter
}

func (h *Handler) Register(m *http.ServeMux) {
	m.HandleFunc("GET /api/v1/me/training-configuration", h.private(h.Load))
	m.HandleFunc("PUT /api/v1/me/training-configuration", h.private(h.Save))
	m.HandleFunc("GET /api/v1/me/training-configuration/resources", h.private(h.Options))
}
func failure(w http.ResponseWriter, r *http.Request, e error) {
	status, code := 503, "training_configuration_unavailable"
	var fields FieldIssues
	switch {
	case errors.Is(e, auth.ErrInvalid):
		status, code = 401, "invalid_credential"
		w.Header().Set("WWW-Authenticate", "Bearer")
	case errors.Is(e, ErrConflict):
		status, code = 409, "training_configuration_conflict"
	case errors.As(e, &fields):
		status, code = 400, "invalid_training_configuration"
	}
	httpapi.FailureFields(w, r, status, code, map[string]string(fields))
}
func (h *Handler) private(next func(http.ResponseWriter, *http.Request, auth.Principal)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		values := r.Header.Values("Authorization")
		if len(values) != 1 {
			failure(w, r, auth.ErrInvalid)
			return
		}
		parts := strings.Fields(values[0])
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			failure(w, r, auth.ErrInvalid)
			return
		}
		if h.Authorize == nil {
			failure(w, r, ErrUnavailable)
			return
		}
		p, e := h.Authorize(r.Context(), parts[1])
		if e != nil {
			failure(w, r, e)
			return
		}
		expected := r.Header.Values("X-TrainForge-Account")
		if len(expected) > 1 || (len(expected) == 1 && (!uuidPattern.MatchString(expected[0]) || expected[0] != p.User.ID)) {
			failure(w, r, ErrConflict)
			return
		}
		if !h.limits.Allow(p.User.ID+":training-config", 60) {
			w.Header().Set("Retry-After", "60")
			httpapi.Failure(w, r, 429, "rate_limited")
			return
		}
		next(w, r, p)
	}
}
func noQuery(w http.ResponseWriter, r *http.Request) bool {
	q, e := url.ParseQuery(r.URL.RawQuery)
	if e != nil || len(q) != 0 {
		failure(w, r, FieldIssues{"query": "invalid_query"})
		return false
	}
	return true
}
func unique(d *json.Decoder) error {
	token, e := d.Token()
	if e != nil {
		return e
	}
	kind, ok := token.(json.Delim)
	if !ok {
		return nil
	}
	if kind == '{' {
		seen := map[string]bool{}
		for d.More() {
			key, e := d.Token()
			if e != nil {
				return e
			}
			s, ok := key.(string)
			if !ok || seen[s] {
				return ErrUnavailable
			}
			seen[s] = true
			if e := unique(d); e != nil {
				return e
			}
		}
	} else if kind == '[' {
		for d.More() {
			if e := unique(d); e != nil {
				return e
			}
		}
	} else {
		return ErrUnavailable
	}
	_, e = d.Token()
	return e
}
func strict(raw []byte, target any) bool {
	if !utf8.Valid(raw) {
		return false
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if unique(d) != nil || d.Decode(new(any)) != io.EOF {
		return false
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	return d.Decode(target) == nil && d.Decode(new(any)) == io.EOF
}

// Load returns absence explicitly, without prefilled personal context.
// @Summary Read own confirmed training configuration
// @Tags training-configuration
// @Security BearerAuth
// @Produce json
// @Success 200 {object} Current
// @Failure 400,401,409,429,503 {object} httpapi.Problem
// @Router /api/v1/me/training-configuration [get]
func (h *Handler) Load(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noQuery(w, r) {
		return
	}
	current, e := h.Service.Load(r.Context(), p)
	if e != nil {
		failure(w, r, e)
		return
	}
	reply, e := h.current(r.Context(), p, current)
	if e != nil {
		failure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, reply)
}

// Save confirms one complete reviewed declaration using optimistic revision and stable retry identity.
// @Summary Confirm or replace own training configuration
// @Tags training-configuration
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param Idempotency-Key header string true "UUID stable across retries;24-hour retention"
// @Param body body SaveCommand true "Complete declaration,reviewed=true and expected revision; no owner field"
// @Success 200 {object} Current
// @Failure 400,401,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/training-configuration [put]
func (h *Handler) Save(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	if !noQuery(w, r) {
		return
	}
	media, _, e := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if e != nil || media != "application/json" {
		httpapi.Failure(w, r, 415, "json_required")
		return
	}
	keys := r.Header.Values("Idempotency-Key")
	if len(keys) != 1 || !uuidPattern.MatchString(keys[0]) {
		failure(w, r, FieldIssues{"idempotencyKey": "invalid_idempotency_key"})
		return
	}
	raw, e := io.ReadAll(http.MaxBytesReader(w, r.Body, 16<<10))
	if e != nil {
		var large *http.MaxBytesError
		if errors.As(e, &large) {
			httpapi.Failure(w, r, 413, "body_too_large")
		} else {
			failure(w, r, FieldIssues{"body": "invalid_json"})
		}
		return
	}
	var command SaveCommand
	if !strict(raw, &command) {
		failure(w, r, FieldIssues{"body": "invalid_json"})
		return
	}
	saved, e := h.Service.Save(r.Context(), p, command, keys[0])
	if e != nil {
		failure(w, r, e)
		return
	}
	reply, e := h.current(r.Context(), p, &saved)
	if e != nil {
		failure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, reply)
}

type resourceCursor struct {
	Source string `json:"source"`
	ID     int    `json:"id"`
	Filter string `json:"filter"`
}

func resourceFingerprint(p auth.Principal, f ResourceFilter) string {
	raw, _ := json.Marshal([]any{p.User.ID, f.Q, f.Limit})
	hash := sha256.Sum256(raw)
	return hex.EncodeToString(hash[:])
}
func resourceQuery(q url.Values, p auth.Principal) (ResourceFilter, error) {
	f := ResourceFilter{Q: strings.TrimSpace(q.Get("q")), Limit: 20}
	invalid := FieldIssues{"query": "invalid_query"}
	for k, v := range q {
		if len(v) != 1 || len(v[0]) > 2048 || (k != "q" && k != "limit" && k != "cursor") {
			return f, invalid
		}
	}
	if !utf8.ValidString(f.Q) || len([]rune(f.Q)) > 100 || strings.IndexFunc(f.Q, unicode.IsControl) >= 0 {
		return f, invalid
	}
	if raw := q.Get("limit"); raw != "" {
		n, e := strconv.Atoi(raw)
		if e != nil || n < 1 || n > 20 {
			return f, invalid
		}
		f.Limit = n
	}
	if token := q.Get("cursor"); token != "" {
		raw, e := base64.RawURLEncoding.DecodeString(token)
		var c resourceCursor
		if e != nil || !strict(raw, &c) || !sourcePattern.MatchString(c.Source) || c.ID < 1 || c.ID > 2147483647 || c.Filter != resourceFingerprint(p, f) {
			return f, invalid
		}
		f.AfterSource, f.AfterID = c.Source, c.ID
	}
	return f, nil
}

// Options returns only equipment identities from permitted source metadata.
// @Summary Search source-scoped training equipment
// @Tags training-configuration
// @Security BearerAuth
// @Produce json
// @Param q query string false "Literal original equipment name; maximum100characters"
// @Param limit query int false "1..20; default20"
// @Param cursor query string false "Account/query/limit-bound cursor"
// @Success 200 {object} ResourcePage
// @Failure 400,401,409,429,503 {object} httpapi.Problem
// @Router /api/v1/me/training-configuration/resources [get]
func (h *Handler) Options(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, e := url.ParseQuery(r.URL.RawQuery)
	if e != nil {
		failure(w, r, FieldIssues{"query": "invalid_query"})
		return
	}
	f, e := resourceQuery(q, p)
	if e != nil {
		failure(w, r, e)
		return
	}
	if h.ResourceStore == nil {
		failure(w, r, ErrUnavailable)
		return
	}
	items, e := h.ResourceStore.Resources(r.Context(), p, f)
	if e != nil {
		failure(w, r, e)
		return
	}
	page := ResourcePage{Items: items}
	if len(items) > f.Limit {
		last := items[f.Limit-1]
		raw, _ := json.Marshal(resourceCursor{last.SourceID, last.EquipmentID, resourceFingerprint(p, f)})
		token := base64.RawURLEncoding.EncodeToString(raw)
		page.NextCursor = &token
		page.Items = items[:f.Limit]
	}
	httpapi.JSON(w, 200, page)
}

func (h *Handler) current(ctx context.Context, p auth.Principal, snapshot *Snapshot) (Current, error) {
	result := Current{Current: snapshot, ResourceLabels: []ResourceOption{}, UnavailableResources: []ResourceRef{}}
	if snapshot == nil || len(snapshot.Configuration.Resources.Items) == 0 {
		return result, nil
	}
	resolver, ok := h.ResourceStore.(ResourceResolver)
	if !ok {
		return result, ErrUnavailable
	}
	labels, e := resolver.ResolveResources(ctx, p, snapshot.Configuration.Resources.Items)
	if e != nil {
		return result, e
	}
	result.ResourceLabels = labels
	found := map[ResourceRef]bool{}
	for _, item := range labels {
		found[ResourceRef{item.SourceID, item.EquipmentID}] = true
	}
	for _, ref := range snapshot.Configuration.Resources.Items {
		if !found[ref] {
			result.UnavailableResources = append(result.UnavailableResources, ref)
		}
	}
	return result, nil
}
