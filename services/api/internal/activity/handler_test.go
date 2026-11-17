package activity

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"trainforge.local/api/internal/auth"
)

type handlerStore struct {
	calls    int
	problem  error
	replayed bool
}

func (s *handlerStore) Feed(context.Context, auth.Principal) (Feed, error) {
	s.calls++
	return Feed{Upcoming: []Upcoming{}, Sessions: []Detail{}, Complete: true}, s.problem
}
func (s *handlerStore) Detail(context.Context, auth.Principal, string) (Detail, error) {
	s.calls++
	return Detail{}, s.problem
}
func (s *handlerStore) Start(context.Context, auth.Principal, StartRequest, string) (MutationResult, error) {
	s.calls++
	return MutationResult{AppliedRevision: 1, Replayed: s.replayed}, s.problem
}
func (s *handlerStore) Command(context.Context, auth.Principal, string, CommandInput, string) (MutationResult, error) {
	s.calls++
	return MutationResult{AppliedRevision: 2}, s.problem
}
func endpoint(s *handlerStore) *http.ServeMux {
	h := &Handler{Store: s, Authorize: func(_ context.Context, token string) (auth.Principal, error) {
		if token != "valid" {
			return auth.Principal{}, auth.ErrInvalid
		}
		return auth.Principal{User: auth.User{ID: identifier(2)}}, nil
	}}
	m := http.NewServeMux()
	h.Register(m)
	return m
}
func request(method, path, raw string) *http.Request {
	r := httptest.NewRequest(method, path, strings.NewReader(raw))
	r.Header.Set("Authorization", "Bearer valid")
	r.Header.Set("Content-Type", "application/json")
	r.Header.Set("Idempotency-Key", identifier(90))
	return r
}
func TestHandlerBoundaries(t *testing.T) {
	start := `{"occurrenceId":"` + identifier(3) + `"}`
	cases := []struct {
		name, method, path, raw string
		status                  int
		change                  func(*http.Request)
	}{
		{"missing credential", "GET", "/api/v1/me/activity", "", 401, func(r *http.Request) { r.Header.Del("Authorization") }},
		{"invalid credential", "GET", "/api/v1/me/activity", "", 401, func(r *http.Request) { r.Header.Set("Authorization", "Bearer invalid") }},
		{"different account", "GET", "/api/v1/me/activity", "", 401, func(r *http.Request) { r.Header.Set("X-TrainForge-Account", identifier(9)) }},
		{"query rejected", "GET", "/api/v1/me/activity?owner=x", "", 400, nil},
		{"missing key", "POST", "/api/v1/me/activity-sessions", start, 400, func(r *http.Request) { r.Header.Del("Idempotency-Key") }},
		{"duplicate key header", "POST", "/api/v1/me/activity-sessions", start, 400, func(r *http.Request) { r.Header.Add("Idempotency-Key", identifier(91)) }},
		{"json media required", "POST", "/api/v1/me/activity-sessions", start, 415, func(r *http.Request) { r.Header.Set("Content-Type", "text/plain") }},
		{"owner cannot be supplied", "POST", "/api/v1/me/activity-sessions", `{"occurrenceId":"x","ownerId":"y"}`, 400, nil},
		{"duplicate body key", "POST", "/api/v1/me/activity-sessions", `{"occurrenceId":"x","occurrenceId":"y"}`, 400, nil},
		{"case alias is not a second spelling", "POST", "/api/v1/me/activity-sessions", `{"occurrenceId":"x","OccurrenceId":"y"}`, 400, nil},
		{"null scalar", "POST", "/api/v1/me/activity-sessions", `{"occurrenceId":null}`, 400, nil},
		{"trailing JSON", "POST", "/api/v1/me/activity-sessions", start + ` {}`, 400, nil},
		{"bounded body", "POST", "/api/v1/me/activity-sessions", strings.Repeat(" ", 17000), 413, nil},
		{"time cannot be supplied", "POST", "/api/v1/me/activity-sessions/" + identifier(1) + "/commands", `{"expectedRevision":1,"action":"pause","confirmed":false,"at":"2026-11-16T10:00:00Z"}`, 400, nil},
		{"missing slot never defaults to first movement", "POST", "/api/v1/me/activity-sessions/" + identifier(1) + "/commands", `{"expectedRevision":1,"action":"record_set","confirmed":false,"set":{"number":1,"repetitions":0}}`, 400, nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := &handlerStore{}
			r := request(tc.method, tc.path, tc.raw)
			if tc.change != nil {
				tc.change(r)
			}
			w := httptest.NewRecorder()
			endpoint(s).ServeHTTP(w, r)
			if w.Code != tc.status || s.calls != 0 || w.Header().Get("Cache-Control") != "no-store" {
				t.Fatalf("%d calls=%d body=%s", w.Code, s.calls, w.Body.String())
			}
		})
	}
}
func TestHandlerResponses(t *testing.T) {
	t.Run("empty feed remains explicit", func(t *testing.T) {
		s := &handlerStore{}
		w := httptest.NewRecorder()
		endpoint(s).ServeHTTP(w, request("GET", "/api/v1/me/activity", ""))
		if w.Code != 200 || !strings.Contains(w.Body.String(), `"upcoming":[]`) || !strings.Contains(w.Body.String(), `"sessions":[]`) {
			t.Fatal(w.Body.String())
		}
	})
	for _, replayed := range []bool{false, true} {
		t.Run(map[bool]string{false: "new start", true: "replayed start"}[replayed], func(t *testing.T) {
			s := &handlerStore{replayed: replayed}
			w := httptest.NewRecorder()
			endpoint(s).ServeHTTP(w, request("POST", "/api/v1/me/activity-sessions", `{"occurrenceId":"`+identifier(3)+`"}`))
			expected := 201
			if replayed {
				expected = 200
			}
			if w.Code != expected {
				t.Fatal(w.Code)
			}
		})
	}
	cases := []struct {
		name   string
		err    error
		status int
		code   string
	}{{"missing", ErrMissing, 404, "activity_not_found"}, {"conflict", ErrConflict, 409, "activity_conflict"}, {"withdrawn", ErrPracticeUnavailable, 409, "activity_practice_unavailable"}, {"unavailable", ErrUnavailable, 503, "activity_unavailable"}, {"invalid", ErrInvalid, 400, "invalid_activity_command"}}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			s := &handlerStore{problem: tc.err}
			w := httptest.NewRecorder()
			endpoint(s).ServeHTTP(w, request("GET", "/api/v1/me/activity-sessions/"+identifier(1), ""))
			var v map[string]any
			json.Unmarshal(w.Body.Bytes(), &v)
			if w.Code != tc.status || v["code"] != tc.code {
				t.Fatalf("%d %v", w.Code, v)
			}
		})
	}
}
