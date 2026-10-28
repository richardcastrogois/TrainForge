package trainingconfig

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"trainforge.local/api/internal/auth"
)

type optionFixture struct{}

func (optionFixture) Resources(context.Context, auth.Principal, ResourceFilter) ([]ResourceOption, error) {
	return []ResourceOption{{SourceID: "source", EquipmentID: 1, Name: "Fixture", SourceName: "Fixture source"}}, nil
}
func TestConfigurationHTTPStrictBoundaries(t *testing.T) {
	store := &isolatedStore{}
	h := &Handler{Service: Service{store}, ResourceStore: optionFixture{}, Authorize: func(context.Context, string) (auth.Principal, error) { return actor(), nil }}
	mux := http.NewServeMux()
	h.Register(mux)
	request := func(method, path, token, key, body, contentType, account string) *httptest.ResponseRecorder {
		r := httptest.NewRequest(method, path, strings.NewReader(body))
		if token != "" {
			r.Header.Set("Authorization", token)
		}
		if key != "" {
			r.Header.Set("Idempotency-Key", key)
		}
		if contentType != "" {
			r.Header.Set("Content-Type", contentType)
		}
		if account != "" {
			r.Header.Set("X-TrainForge-Account", account)
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	path := "/api/v1/me/training-configuration"
	body, _ := json.Marshal(declared())
	for _, tc := range []struct {
		name, method, path, token, key, body, contentType, account string
		status                                                     int
	}{
		{"anonymous", "GET", path, "", "", "", "", "", 401},
		{"foreign header", "GET", path, "Bearer fixture", "", "", "", "99999999-9999-4999-8999-999999999999", 409},
		{"query owner", "GET", path + "?ownerId=other", "Bearer fixture", "", "", "", "", 400},
		{"bad query", "GET", path + "?q=%zz", "Bearer fixture", "", "", "", "", 400},
		{"missing key", "PUT", path, "Bearer fixture", "", string(body), "application/json", "", 400},
		{"missing type", "PUT", path, "Bearer fixture", fixtureKey, string(body), "", "", 415},
		{"trailing JSON", "PUT", path, "Bearer fixture", fixtureKey, string(body) + " {}", "application/json", "", 400},
		{"duplicate keys", "PUT", path, "Bearer fixture", fixtureKey, "{\"reviewed\":true,\"reviewed\":false}", "application/json", "", 400},
		{"unknown body", "PUT", path, "Bearer fixture", fixtureKey, "{\"ownerId\":\"other\"}", "application/json", "", 400},
		{"null body", "PUT", path, "Bearer fixture", fixtureKey, "null", "application/json", "", 400},
		{"invalid UTF8", "PUT", path, "Bearer fixture", fixtureKey, string([]byte{0xff}), "application/json", "", 400},
		{"oversized", "PUT", path, "Bearer fixture", fixtureKey, strings.Repeat("x", 16385), "application/json", "", 413},
	} {
		t.Run(tc.name, func(t *testing.T) {
			out := request(tc.method, tc.path, tc.token, tc.key, tc.body, tc.contentType, tc.account)
			if out.Code != tc.status || out.Header().Get("Cache-Control") != "no-store" {
				t.Fatal("boundary", out.Code, tc.status)
			}
		})
	}
	if store.saves != 0 || store.loads != 0 {
		t.Fatal("invalid request touched storage")
	}
	out := request("PUT", path, "Bearer fixture", fixtureKey, string(body), "application/json", actor().User.ID)
	if out.Code != 200 || store.saves != 1 {
		t.Fatal("confirmed write")
	}
	invalid := declared()
	invalid.Reviewed = false
	raw, _ := json.Marshal(invalid)
	out = request("PUT", path, "Bearer fixture", fixtureKey, string(raw), "application/json", actor().User.ID)
	if out.Code != 400 || !bytes.Contains(out.Body.Bytes(), []byte("review_required")) || !bytes.Contains(out.Body.Bytes(), []byte("requestId")) {
		t.Fatal("field envelope")
	}
}
func TestConfigurationResourceCursorBoundaries(t *testing.T) {
	p := actor()
	f := ResourceFilter{Q: "fixture", Limit: 1}
	raw, _ := json.Marshal(resourceCursor{Source: "source", ID: 1, Filter: resourceFingerprint(p, f)})
	token := base64.RawURLEncoding.EncodeToString(raw)
	q := url.Values{"q": {"fixture"}, "limit": {"1"}, "cursor": {token}}
	got, e := resourceQuery(q, p)
	if e != nil || got.AfterID != 1 {
		t.Fatal("cursor")
	}
	for key, value := range map[string]string{"q": "other", "limit": "2", "ownerId": "other", "cursor": "bad", "limitInvalid": "0"} {
		copy, _ := url.ParseQuery(q.Encode())
		copy.Set(key, value)
		if _, e := resourceQuery(copy, p); e == nil {
			t.Fatal("cursor crossed filter")
		}
	}
	other := p
	other.User.ID = "99999999-9999-4999-8999-999999999999"
	if _, e := resourceQuery(q, other); e == nil {
		t.Fatal("cursor crossed account")
	}
}
