package nutrition

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

func TestFoodNamesQueryBindsLocaleRevisionAndCursor(t *testing.T) {
	for _, raw := range []string{"locale=pt", "locale=en&locale=es", "namesVersion=1", "locale=en&namesVersion=01", "locale=en&namesVersion=-1", "locale=en&namesVersion=9223372036854775808", "locale=%FF"} {
		q, _ := url.ParseQuery(raw)
		if _, err := foodFilters(q); !errors.Is(err, ErrFoodQuery) {
			t.Fatal("invalid localized query accepted")
		}
	}
	f, err := foodFilters(url.Values{"locale": {"pt-BR"}, "namesVersion": {"3"}, "limit": {"1"}, "q": {"alias"}})
	if err != nil {
		t.Fatal("valid localized filters refused")
	}
	token := foodCursor("food:"+strings.Repeat("a", 64), f)
	q := url.Values{"locale": {"pt-BR"}, "limit": {"1"}, "q": {"alias"}, "cursor": {token}}
	got, err := foodFilters(q)
	if err != nil || got.NamesVersion != "3" || got.After == "" {
		t.Fatal("cursor lost its lexicon revision")
	}
	for key, value := range map[string]string{"locale": "pt-PT", "namesVersion": "4", "q": "different", "limit": "2"} {
		copy := url.Values{}
		for k, v := range q {
			copy[k] = append([]string{}, v...)
		}
		copy.Set(key, value)
		if _, err := foodFilters(copy); !errors.Is(err, ErrFoodQuery) {
			t.Fatal("cursor crossed locale/revision/filter boundary")
		}
	}
	for _, q := range []url.Values{{"locale": {"pt"}}, {"locale": {"en", "es"}}, {"namesVersion": {"1"}}, {"versionId": {"bad"}}, {"ownerId": {"other"}}} {
		if _, _, err := foodDetailQuery(q); !errors.Is(err, ErrFoodQuery) {
			t.Fatal("unsafe localized detail accepted")
		}
	}
	if version, locale, err := foodDetailQuery(url.Values{"locale": {"en"}}); err != nil || version != "" || locale != "en" {
		t.Fatal("optional detail locale failed")
	}
}

// Runs only from the explicitly isolated SQL test. No human or delivered DB data.
func assertLocalizedFoodNames(t *testing.T, p FoodPostgres, target, other FoodNameTarget, alias string) func() {
	t.Helper()
	mux := http.NewServeMux()
	FoodHandler{Reader: FoodReader{p}}.Register(mux)
	get := func(path, etag string) *httptest.ResponseRecorder {
		t.Helper()
		req := httptest.NewRequest("GET", path, nil)
		if etag != "" {
			req.Header.Set("If-None-Match", etag)
		}
		out := httptest.NewRecorder()
		mux.ServeHTTP(out, req)
		return out
	}
	readPage := func(out *httptest.ResponseRecorder) FoodPage {
		t.Helper()
		var page FoodPage
		if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &page) != nil {
			t.Fatal("localized page failed")
		}
		return page
	}
	first := readPage(get("/api/v1/foods?locale=pt-BR&limit=1&q="+url.QueryEscape(alias), ""))
	if len(first.Items) != 1 || first.NextCursor == nil || first.NameCatalog == nil || first.NameCatalog.Locale != "pt-BR" || first.NameCatalog.Version == "0" || first.Items[0].ReviewedName == nil {
		t.Fatal("localized first page missing metadata")
	}
	cursor := *first.NextCursor
	pagePath := "/api/v1/foods?locale=pt-BR&limit=1&q=" + url.QueryEscape(alias) + "&cursor=" + url.QueryEscape(cursor)
	second := readPage(get(pagePath, ""))
	if len(second.Items) != 1 || second.Items[0].ID == first.Items[0].ID || second.NextCursor != nil {
		t.Fatal("localized pagination merged or duplicated homonyms")
	}
	if get(strings.Replace(pagePath, "locale=pt-BR", "locale=es", 1), "").Code != 400 {
		t.Fatal("HTTP cursor crossed locale")
	}
	english := readPage(get("/api/v1/foods?locale=en&q="+url.QueryEscape(alias), ""))
	if len(english.Items) != 0 || english.NameCatalog == nil || english.NameCatalog.Version != "0" {
		t.Fatal("alias crossed locale")
	}
	path := "/api/v1/foods/" + url.PathEscape(target.FoodID) + "?versionId=" + target.FoodVersion + "&locale=pt-BR"
	before := get(path, "")
	var detail FoodDetail
	if before.Code != 200 || json.Unmarshal(before.Body.Bytes(), &detail) != nil || detail.ReviewedName == nil || detail.ID != target.FoodID || detail.VersionID != target.FoodVersion {
		t.Fatal("localized detail changed identity")
	}
	if detail.Name == detail.ReviewedName.Name || detail.NameCatalog == nil {
		t.Fatal("original name overwritten")
	}
	oldTag := before.Header().Get("ETag")
	if get(path, oldTag).Code != 304 {
		t.Fatal("localized ETag did not revalidate")
	}
	en := get(strings.Replace(path, "locale=pt-BR", "locale=en", 1), "")
	es := get(strings.Replace(path, "locale=pt-BR", "locale=es", 1), "")
	if en.Code != 200 || es.Code != 200 || en.Header().Get("ETag") == es.Header().Get("ETag") {
		t.Fatal("fallback ETag ignored locale")
	}
	var original FoodDetail
	rawOriginal := get(strings.Replace(path, "&locale=pt-BR", "", 1), "")
	if rawOriginal.Code != 200 || json.Unmarshal(rawOriginal.Body.Bytes(), &original) != nil || original.ReviewedName != nil || original.NameCatalog != nil {
		t.Fatal("legacy detail contract changed")
	}
	a, _ := json.Marshal(detail.Nutrients)
	b, _ := json.Marshal(original.Nutrients)
	if string(a) != string(b) {
		t.Fatal("localized detail changed nutrient values or methods")
	}
	return func() {
		t.Helper()
		if get(pagePath, "").Code != 409 {
			t.Fatal("stale name-generation cursor was silently reused")
		}
		after := get(path, oldTag)
		var withdrawn FoodDetail
		if after.Code != 200 || json.Unmarshal(after.Body.Bytes(), &withdrawn) != nil || withdrawn.ReviewedName != nil || withdrawn.Name != original.Name || withdrawn.VersionID != original.VersionID {
			t.Fatal("withdrawal failed to fall back to exact original")
		}
		if after.Header().Get("ETag") == oldTag || get(path, after.Header().Get("ETag")).Code != 304 {
			t.Fatal("withdrawal reused stale ETag")
		}
		remaining := readPage(get("/api/v1/foods?locale=pt-BR&q="+url.QueryEscape(alias), ""))
		if len(remaining.Items) != 1 || remaining.Items[0].ID != other.FoodID {
			t.Fatal("alias search revived old name or crossed a homonym")
		}
	}
}

func TestFoodNamesKeepsLegacyOriginalOnlyCursor(t *testing.T) {
	token := "eyJhZnRlciI6ImZvb2Q6YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYSIsImZpbHRlciI6IjdjZjc2MWE4MjEzODU3MTBkZWZkOTBkNmEzMDIzZWI4Y2YyMGJiNDQ5NjUyM2M3NTQxMjU5Yzc0OTI4MDIzOTAifQ"
	got, err := foodFilters(url.Values{"q": {"raw"}, "limit": {"1"}, "cursor": {token}})
	if err != nil || got.After == "" || got.Locale != "" || got.NamesVersion != "" {
		t.Fatal("original-only cursor was invalidated by optional localization")
	}
}
