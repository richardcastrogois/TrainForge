package nutrition

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
)

func exampleEntry() EntryInput {
	return EntryInput{FoodID: "own:11111111-1111-4111-8111-111111111111", FoodVersion: strings.Repeat("a", 64), Quantity: "25.5", Unit: "g", OccurredAt: "2026-10-23T23:30:00-03:00", Timezone: "America/Sao_Paulo", QuantityEvidence: "estimated"}
}
func TestSourceRationalCalculation(t *testing.T) {
	in := exampleEntry()
	f := FoodDetail{Nutrients: []FoodCell{
		{Column: "a", State: "numeric", Value: ptr("0.1"), Unit: ptr("g"), BasisQuantity: ptr("100"), BasisUnit: ptr("g"), Scaling: true},
		{Column: "b", State: "less_than", UpperBound: ptr("0.5"), Raw: "<0.5", Unit: ptr("mg"), BasisQuantity: ptr("100"), BasisUnit: ptr("g")},
		{Column: "c", State: "numeric", Value: ptr("2"), Unit: ptr("g"), BasisQuantity: ptr("100"), BasisUnit: ptr("ml"), Scaling: true},
	}}
	c, e := scaled(f, in, "editorial")
	if e != nil {
		t.Fatal(e)
	}
	if *c.Nutrients[0].Exact != "51/2000" || *c.Nutrients[0].Value != "0.025500" || *c.Nutrients[0].Factor != "51/200" {
		t.Fatal("decimal precision lost")
	}
	if c.Nutrients[1].Value != nil || c.Nutrients[2].Value != nil {
		t.Fatal("unknown or density conversion invented")
	}
	if c.Nutrients[1].SourceUpperBound == nil || *c.Nutrients[1].SourceUpperBound != "0.5" || c.Nutrients[1].RawText != "<0.5" {
		t.Fatal("original upper bound lost")
	}
	if c.QuantityEvidence != "estimated" {
		t.Fatal("estimated quantity became measured")
	}
	all := totals([]Entry{{Calculation: c}, {Calculation: c}}, true)
	if *all.Nutrients[0].Exact != "51/1000" || all.Nutrients[1].Value != nil || all.Nutrients[1].Unknown != 2 {
		t.Fatal("invalid partial total")
	}
	if len(totals([]Entry{{Calculation: c}}, false).Nutrients) != 0 {
		t.Fatal("truncated total")
	}
}
func TestNutritionValidationAndCalendar(t *testing.T) {
	in := exampleEntry()
	for _, q := range []string{"0", "-1", "1e10", "NaN", "1/3", "1,5", "10000000", "0.0000001"} {
		in.Quantity = q
		if validateEntry(in) == nil {
			t.Fatalf("accepted %q", q)
		}
	}
	in = exampleEntry()
	in.QuantityEvidence = ""
	if validateEntry(in) == nil {
		t.Fatal("implicit evidence")
	}
	start, end, e := dayBounds("2026-10-23", "America/Sao_Paulo")
	if e != nil || start.UTC().Hour() != 3 || end.Sub(start) != 24*time.Hour {
		t.Fatal("local day")
	}
	start, end, e = dayBounds("2026-03-08", "America/New_York")
	if e != nil || end.Sub(start) != 23*time.Hour {
		t.Fatal("DST day")
	}
	if _, _, e = dayBounds("2026-02-30", "UTC"); e == nil {
		t.Fatal("invalid date")
	}
	own := OwnFoodInput{Name: "Alimento do titular", Basis: Basis{}, Nutrients: []OwnNutrient{{Name: "Proteína", Unit: "g"}}}
	if validateOwn(own) != nil {
		t.Fatal("unknown composition must be allowed")
	}
	own.Nutrients[0].Value = ptr("0")
	if validateOwn(own) != nil {
		t.Fatal("explicit zero")
	}
}
func TestNutritionHTTPBoundaries(t *testing.T) {
	p := auth.Principal{User: auth.User{ID: "11111111-1111-4111-8111-111111111111"}}
	for _, body := range []string{`{"name":"a","name":"b","nutrients":[]}`, `{"name":"a","unknown":1}`, `null`, `{"name":"a"} {}`} {
		r := httptest.NewRequest("POST", "/", strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		var in OwnFoodInput
		_, ok := entryBody(w, r, &in)
		if body == "null" {
			if ok && validateOwn(in) == nil {
				t.Fatal("null declaration accepted")
			}
		} else if ok {
			t.Fatal("ambiguous JSON accepted")
		}
	}
	f := privateFilter{Day: "2026-10-23", Zone: "UTC", Limit: 10}
	token := cursorFor("2026-10-23T12:00:00Z|11111111-1111-4111-8111-111111111111", p, f, "entries")
	q := url.Values{"date": {f.Day}, "timezone": {f.Zone}, "cursor": {*token}}
	if _, e := parsePrivate(q, p, "entries"); e != nil {
		t.Fatal(e)
	}
	q.Set("date", "2026-10-24")
	if _, e := parsePrivate(q, p, "entries"); e == nil {
		t.Fatal("cursor not bound")
	}
	h := &EntryHandler{Authorize: func(context.Context, string) (auth.Principal, error) { return p, auth.ErrUnavailable }}
	mux := http.NewServeMux()
	h.Register(mux)
	r := httptest.NewRequest("GET", "/api/v1/me/foods", nil)
	r.Header.Set("Authorization", "Bearer example")
	w := httptest.NewRecorder()
	mux.ServeHTTP(w, r)
	if w.Code != 503 {
		t.Fatal("network failure must not clear session", w.Code)
	}
	h.Authorize = func(context.Context, string) (auth.Principal, error) { return p, nil }
	r.Header.Set("X-TrainForge-Account", "22222222-2222-4222-8222-222222222222")
	w = httptest.NewRecorder()
	mux.ServeHTTP(w, r)
	if w.Code != 409 {
		t.Fatal("account context not guarded", w.Code)
	}
	r.Header.Del("X-TrainForge-Account")
	h.Authorize = func(context.Context, string) (auth.Principal, error) { return p, auth.ErrInvalid }
	w = httptest.NewRecorder()
	mux.ServeHTTP(w, r)
	if w.Code != 401 {
		t.Fatal(w.Code)
	}
}
