package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
)

func TestFoodNamesPrivateCursorAndQuery(t *testing.T) {
	p := auth.Principal{User: auth.User{ID: "11111111-1111-4111-8111-111111111111"}}
	f := privateFilter{Day: "2026-10-23", Zone: "UTC", Locale: "pt-BR", NamesVersion: "2", Limit: 1}
	token := cursorFor("2026-10-23T12:00:00Z|11111111-1111-4111-8111-111111111111", p, f, "entries")
	q := url.Values{"date": {f.Day}, "timezone": {f.Zone}, "locale": {f.Locale}, "cursor": {*token}}
	got, err := parsePrivate(q, p, "entries")
	if err != nil || got.NamesVersion != "2" || got.After == "" {
		t.Fatal("private cursor lost name revision")
	}
	for _, change := range []string{"locale=es", "namesVersion=3", "date=2026-10-24", "timezone=-03:00"} {
		copy, _ := url.ParseQuery(q.Encode())
		kv, _ := url.ParseQuery(change)
		for k, v := range kv {
			copy[k] = v
		}
		if _, e := parsePrivate(copy, p, "entries"); !errors.Is(e, ErrFoodQuery) {
			t.Fatal("cursor crossed a name/filter boundary")
		}
	}
	other := p
	other.User.ID = "22222222-2222-4222-8222-222222222222"
	if _, e := parsePrivate(q, other, "entries"); !errors.Is(e, ErrFoodQuery) {
		t.Fatal("cursor crossed account")
	}
	for _, raw := range []string{"locale=pt", "locale=", "locale=en&locale=es", "namesVersion=1", "locale=en&namesVersion=-1", "locale=en&namesVersion=01", "locale=en&namesVersion=9223372036854775808", "locale=en&namesVersion="} {
		bad, _ := url.ParseQuery("date=2026-10-23&timezone=UTC&" + raw)
		if _, e := parsePrivate(bad, p, "entries"); !errors.Is(e, ErrFoodQuery) {
			t.Fatal("unsafe name query accepted")
		}
	}
	for _, kind := range []string{"foods", "summary"} {
		if _, e := parsePrivate(url.Values{"locale": {"en"}}, p, kind); !errors.Is(e, ErrFoodQuery) {
			t.Fatal("locale changed unrelated read")
		}
	}
}

// Called only from the disposable reviewed-name SQL suite. Never real Google or delivered data.
func assertEntryFoodNames(t *testing.T, writer, runtime *pgxpool.Pool, target FoodNameTarget, wantName string) func() {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	service := auth.Service{Verifier: nutritionFixtureVerifier{"names-private-a"}, Repository: auth.Postgres{Pool: runtime}}
	session, e := service.Login(ctx, "isolated fixture, not Google")
	if e != nil {
		t.Fatal("private name session fixture")
	}
	p, e := service.Authorize(ctx, session.AccessToken)
	if e != nil {
		t.Fatal("private name fixture principal")
	}
	otherService := auth.Service{Verifier: nutritionFixtureVerifier{"names-private-b"}, Repository: auth.Postgres{Pool: runtime}}
	other, e := otherService.Login(ctx, "isolated fixture, not Google")
	if e != nil {
		t.Fatal("other fixture session")
	}
	h := &EntryHandler{Store: NutritionStore{runtime}, Names: FoodPostgres{runtime}, Authorize: service.Authorize}
	mux := http.NewServeMux()
	h.Register(mux)
	request := func(method, path, token, key string, body any) *httptest.ResponseRecorder {
		raw, _ := json.Marshal(body)
		r := httptest.NewRequest(method, path, strings.NewReader(string(raw)))
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		r.Header.Set("Content-Type", "application/json")
		if key != "" {
			r.Header.Set("Idempotency-Key", key)
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	in := exampleEntry()
	in.FoodID = target.FoodID
	in.FoodVersion = target.FoodVersion
	key := newID()
	created := request("POST", "/api/v1/me/food-entries", session.AccessToken, key, in)
	var entry Entry
	if created.Code != 201 || json.Unmarshal(created.Body.Bytes(), &entry) != nil || entry.FoodDisplay != nil || entry.Calculation.Food.ReviewedName != nil {
		t.Fatal("name leaked into mutation snapshot")
	}
	second := request("POST", "/api/v1/me/food-entries", session.AccessToken, newID(), in)
	if second.Code != 201 {
		t.Fatal("pagination fixture entry")
	}
	var snapshot string
	if writer.QueryRow(ctx, "SELECT calculation::text FROM trainforge_v1.food_entries WHERE id=$1 AND user_id=$2", entry.ID, p.User.ID).Scan(&snapshot) != nil {
		t.Fatal("snapshot fixture")
	}
	path := "/api/v1/me/food-entries/" + entry.ID
	t.Run("private_names_owned_detail_and_fallback", func(t *testing.T) {
		for _, locale := range []string{"pt-BR", "pt-PT", "en", "es"} {
			out := request("GET", path+"?locale="+locale, session.AccessToken, "", nil)
			var got Entry
			if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &got) != nil || got.FoodDisplay == nil || got.FoodDisplay.NameCatalog.Locale != locale {
				t.Fatal("localized owned detail unavailable")
			}
			if out.Header().Get("Cache-Control") != "no-store" {
				t.Fatal("private read cacheable")
			}
			before, _ := json.Marshal(entry.Calculation)
			after, _ := json.Marshal(got.Calculation)
			if !sameJSON(before, after) {
				t.Fatal("read changed calculation")
			}
			if locale == "pt-BR" {
				if got.FoodDisplay.ReviewedName == nil || got.FoodDisplay.ReviewedName.Name != wantName {
					t.Fatal("reviewed name missing")
				}
			} else if got.FoodDisplay.ReviewedName != nil {
				t.Fatal("cross locale name")
			}
		}
		if out := request("GET", path, session.AccessToken, "", nil); out.Code != 200 || strings.Contains(out.Body.String(), "foodDisplay") {
			t.Fatal("legacy read changed")
		}
	})
	t.Run("private_names_ownership_and_validation", func(t *testing.T) {
		for _, tc := range []struct {
			path, token string
			code        int
		}{{path + "?locale=pt-BR", other.AccessToken, 404}, {path + "?locale=en", "", 401}, {path + "?locale=pt", session.AccessToken, 400}, {path + "?locale=en&locale=es", session.AccessToken, 400}, {path + "?namesVersion=1", session.AccessToken, 400}, {path + "?ownerId=other", session.AccessToken, 400}} {
			out := request("GET", tc.path, tc.token, "", nil)
			if out.Code != tc.code || strings.Contains(out.Body.String(), wantName) {
				t.Fatal("private read boundary", out.Code, tc.code)
			}
		}
	})
	history := "/api/v1/me/food-entries?date=2026-10-23&timezone=America%2FSao_Paulo&locale=pt-BR&limit=1"
	out := request("GET", history, session.AccessToken, "", nil)
	var page NutritionPage
	var items []Entry
	if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &page) != nil || json.Unmarshal(page.Items, &items) != nil || page.NameCatalog == nil || page.NextCursor == nil || len(items) != 1 || items[0].FoodDisplay.ReviewedName == nil {
		t.Fatal("localized private page")
	}
	cursorPath := history + "&cursor=" + url.QueryEscape(*page.NextCursor)
	t.Run("private_names_paginated_batch", func(t *testing.T) {
		next := request("GET", cursorPath, session.AccessToken, "", nil)
		var got NutritionPage
		if next.Code != 200 || json.Unmarshal(next.Body.Bytes(), &got) != nil || got.NameCatalog.Version != page.NameCatalog.Version {
			t.Fatal("private cursor lost coherent revision")
		}
		if request("GET", strings.Replace(cursorPath, "locale=pt-BR", "locale=es", 1), session.AccessToken, "", nil).Code != 400 {
			t.Fatal("cross locale private cursor")
		}
		if request("GET", cursorPath, other.AccessToken, "", nil).Code != 400 {
			t.Fatal("cross owner cursor")
		}
	})
	t.Run("private_names_personal_declaration", func(t *testing.T) {
		own := OwnFoodInput{Name: "Private declaration unchanged", Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{}}
		out := request("POST", "/api/v1/me/foods", session.AccessToken, newID(), own)
		var food FoodDetail
		if out.Code != 201 || json.Unmarshal(out.Body.Bytes(), &food) != nil {
			t.Fatal("personal fixture")
		}
		personal := in
		personal.FoodID = food.ID
		personal.FoodVersion = food.VersionID
		out = request("POST", "/api/v1/me/food-entries", session.AccessToken, newID(), personal)
		var item Entry
		if out.Code != 201 || json.Unmarshal(out.Body.Bytes(), &item) != nil {
			t.Fatal("personal entry fixture")
		}
		out = request("GET", "/api/v1/me/food-entries/"+item.ID+"?locale=es", session.AccessToken, "", nil)
		if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &item) != nil || item.FoodDisplay.ReviewedName != nil || item.Calculation.Food.Name != own.Name || item.Calculation.Food.Locale != "und" {
			t.Fatal("personal declaration translated")
		}
		removed := request("DELETE", "/api/v1/me/food-entries/"+item.ID, session.AccessToken, newID(), EntryInput{Revision: item.Calculation.Revision})
		if removed.Code != 200 || request("GET", "/api/v1/me/food-entries/"+item.ID+"?locale=es", session.AccessToken, "", nil).Code != 404 {
			t.Fatal("deleted detail remained visible")
		}
	})
	return func() {
		t.Helper()
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		t.Run("private_names_withdrawal_snapshot_and_idempotency", func(t *testing.T) {
			out := request("GET", cursorPath, session.AccessToken, "", nil)
			if out.Code != 409 || !strings.Contains(out.Body.String(), "food_name_catalog_changed") {
				t.Fatal("withdrawn name did not invalidate cursor")
			}
			out = request("GET", path+"?locale=pt-BR", session.AccessToken, "", nil)
			var got Entry
			if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &got) != nil || got.FoodDisplay.ReviewedName != nil {
				t.Fatal("withdrawal revived name")
			}
			var after string
			writer.QueryRow(ctx, "SELECT calculation::text FROM trainforge_v1.food_entries WHERE id=$1 AND user_id=$2", entry.ID, p.User.ID).Scan(&after)
			if after != snapshot {
				t.Fatal("name read rewrote stored snapshot")
			}
			replay := request("POST", "/api/v1/me/food-entries", session.AccessToken, key, in)
			if replay.Code != 201 || !sameJSON(replay.Body.Bytes(), created.Body.Bytes()) {
				t.Fatal("name revision changed idempotent response")
			}
			if _, e := writer.Exec(ctx, "UPDATE trainforge_v1.auth_families SET revoked_at=clock_timestamp() WHERE id=$1", p.FamilyID); e != nil {
				t.Fatal("fixture revoke")
			}
			if request("GET", path+"?locale=pt-BR", session.AccessToken, "", nil).Code != 401 {
				t.Fatal("revoked read accepted")
			}
		})
	}
}
