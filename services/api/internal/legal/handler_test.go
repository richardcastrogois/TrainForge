package legal

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"trainforge.local/api/internal/auth"
)

type memory struct {
	saved map[string][]Consent
}

func (m *memory) Record(_ context.Context, user string, items []Consent) error {
	m.saved[user] = append(m.saved[user], items...)
	return nil
}
func (m *memory) Current(_ context.Context, user string) ([]Consent, error) {
	latest := map[string]Consent{}
	for _, c := range m.saved[user] {
		latest[c.Document] = c
	}
	out := []Consent{}
	for _, c := range latest {
		out = append(out, c)
	}
	return out, nil
}

func handler(m *memory) http.Handler {
	h := &Handler{Repository: m, Now: func() time.Time { return time.Date(2026, 11, 19, 12, 0, 0, 0, time.UTC) },
		Authorize: func(_ context.Context, token string) (auth.Principal, error) {
			if token != "good" {
				return auth.Principal{}, auth.ErrInvalid
			}
			return auth.Principal{User: auth.User{ID: "11111111-1111-1111-1111-111111111111"}}, nil
		}}
	mux := http.NewServeMux()
	h.Register(mux)
	return mux
}

const sha = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

func post(t *testing.T, h http.Handler, token, body string) *httptest.ResponseRecorder {
	t.Helper()
	r := httptest.NewRequest("POST", "/api/v1/me/legal-consents", strings.NewReader(body))
	r.Header.Set("Content-Type", "application/json")
	r.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	return w
}

func TestRecordsTermsPrivacyAndHealthForTheCallerOnly(t *testing.T) {
	m := &memory{saved: map[string][]Consent{}}
	body := `{"items":[{"document":"terms","version":"1.0","documentSha":"` + sha + `","decision":"accepted","appVersion":"0.5.1+31","locale":"pt-BR","clientRecordedAt":"2026-11-19T11:59:00Z"},
{"document":"privacy","version":"1.0","documentSha":"` + sha + `","decision":"accepted","appVersion":"0.5.1+31","locale":"pt-BR","clientRecordedAt":"2026-11-19T11:59:00Z"},
{"document":"health_data","version":"1.0","decision":"granted","appVersion":"0.5.1+31","locale":"pt-BR","clientRecordedAt":"2026-11-19T11:59:00Z"}]}`
	w := post(t, handler(m), "good", body)
	if w.Code != 200 || len(m.saved["11111111-1111-1111-1111-111111111111"]) != 3 || !strings.Contains(w.Body.String(), `"health_data"`) {
		t.Fatalf("record failed: %d %s", w.Code, w.Body.String())
	}
}

func TestRejectsInvalidDecisionsWithoutWriting(t *testing.T) {
	m := &memory{saved: map[string][]Consent{}}
	h := handler(m)
	cases := map[string]string{
		"terms without sha":   `{"items":[{"document":"terms","version":"1.0","decision":"accepted","appVersion":"1","locale":"pt","clientRecordedAt":"2026-11-19T11:59:00Z"}]}`,
		"health with sha":     `{"items":[{"document":"health_data","version":"1.0","documentSha":"` + sha + `","decision":"granted","appVersion":"1","locale":"pt","clientRecordedAt":"2026-11-19T11:59:00Z"}]}`,
		"terms revoked":       `{"items":[{"document":"terms","version":"1.0","documentSha":"` + sha + `","decision":"revoked","appVersion":"1","locale":"pt","clientRecordedAt":"2026-11-19T11:59:00Z"}]}`,
		"unknown document":    `{"items":[{"document":"ads","version":"1.0","decision":"granted","appVersion":"1","locale":"pt","clientRecordedAt":"2026-11-19T11:59:00Z"}]}`,
		"future timestamp":    `{"items":[{"document":"health_data","version":"1.0","decision":"granted","appVersion":"1","locale":"pt","clientRecordedAt":"2030-01-01T00:00:00Z"}]}`,
		"unknown field":       `{"items":[],"userId":"x"}`,
		"empty":               `{"items":[]}`,
	}
	for name, body := range cases {
		if w := post(t, h, "good", body); w.Code != 400 {
			t.Fatalf("%s accepted: %d", name, w.Code)
		}
	}
	if w := post(t, h, "bad", `{"items":[]}`); w.Code != 401 {
		t.Fatalf("unauthenticated write: %d", w.Code)
	}
	if len(m.saved) != 0 {
		t.Fatal("invalid decision written")
	}
}
