package nutrition

import (
	"context"
	"encoding/json"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"math/big"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/privacy"
)

type nutritionFixtureVerifier struct{ subject string }

func (v nutritionFixtureVerifier) Verify(context.Context, string) (auth.Identity, error) {
	return auth.Identity{Issuer: "https://accounts.google.com", Subject: v.subject, Name: "Disposable nutrition fixture", Email: "fixture@example.invalid"}, nil
}

// This entry point preserves the previous check with an actual reviewed reference,
// supplied only by the explicit local wrapper. It is not a real user intake.
func TestNutritionPostgresLifecycle(t *testing.T) {
	testNutritionPostgresLifecycle(t, false)
}

// CI uses a separate entry point and disposable synthetic reference. It never
// reads the evaluation catalog or claims validation of a researched food.
func TestNutritionPostgresFixtureLifecycle(t *testing.T) {
	if os.Getenv("TF_NUTRITION_CI_FIXTURE") != "1" {
		t.Skip("explicit disposable CI nutrition fixture not requested")
	}
	testNutritionPostgresLifecycle(t, true)
}

func testNutritionPostgresLifecycle(t *testing.T, synthetic bool) {
	dsn := os.Getenv("TF_NUTRITION_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("disposable nutrition fixture not requested")
	}
	c, e := pgx.ParseConfig(dsn)
	if e != nil || c.Host != "127.0.0.1" || c.Port != 15432 || !strings.HasPrefix(c.Database, "trainforge_v1_nutrition_test_") {
		t.Fatal("unsafe target")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	writer, e := pgxpool.New(ctx, dsn)
	if e != nil {
		t.Fatal("writer")
	}
	defer writer.Close()
	run, e := pgx.ParseConfig(os.Getenv("TF_NUTRITION_TEST_RUNTIME_URL"))
	if e != nil || run.Host != c.Host || run.Port != c.Port || run.Database != c.Database {
		t.Fatal("unsafe runtime")
	}
	pool, e := pgxpool.New(ctx, os.Getenv("TF_NUTRITION_TEST_RUNTIME_URL"))
	if e != nil {
		t.Fatal("runtime")
	}
	defer pool.Close()
	login := func(sub string) (auth.Service, auth.Session, auth.Principal) {
		s := auth.Service{Verifier: nutritionFixtureVerifier{sub}, Repository: auth.Postgres{Pool: pool}}
		session, e := s.Login(ctx, "isolated-fixture-not-google")
		if e != nil {
			t.Fatal(e)
		}
		p, e := s.Authorize(ctx, session.AccessToken)
		if e != nil {
			t.Fatal(e)
		}
		return s, session, p
	}
	a, sa, pa := login("nutrition-a")
	_, sb, _ := login("nutrition-b")
	h := &EntryHandler{Store: NutritionStore{pool}, Authorize: a.Authorize}
	mux := http.NewServeMux()
	h.Register(mux)
	request := func(method, path, token, key string, v any) (int, []byte) {
		raw, _ := json.Marshal(v)
		r := httptest.NewRequest(method, path, strings.NewReader(string(raw)))
		r.Header.Set("Authorization", "Bearer "+token)
		r.Header.Set("Content-Type", "application/json")
		if key != "" {
			r.Header.Set("Idempotency-Key", key)
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w.Code, w.Body.Bytes()
	}
	path := "/api/v1/me/food-entries?date=2026-10-23&timezone=America%2FSao_Paulo"
	status, raw := request("GET", path, sa.AccessToken, "", nil)
	if status != 200 || !strings.Contains(string(raw), `"items":[]`) {
		t.Fatal("history must start empty", status)
	}
	input := OwnFoodInput{Name: "Private fixture", Preparation: "Declarado pelo titular", Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{{Name: "Fixture protein", Unit: "g", Value: ptr("12.3")}, {Name: "Unknown", Unit: "mg"}}}
	key := newID()
	status, raw = request("POST", "/api/v1/me/foods", sa.AccessToken, key, input)
	if status != 201 {
		t.Fatal("create private food", status, string(raw))
	}
	var food FoodDetail
	if json.Unmarshal(raw, &food) != nil {
		t.Fatal("food JSON")
	}
	if food.Locale != "und" || food.Name != input.Name {
		t.Fatal("private name language was inferred")
	}
	var storedLocale string
	if writer.QueryRow(ctx, "SELECT name_locale FROM trainforge_v1.food_versions WHERE food_id=$1 AND owner_id=$2", food.ID, pa.User.ID).Scan(&storedLocale) != nil || storedLocale != "und" {
		t.Fatal("private source language not preserved as unknown")
	}
	if code, replay := request("POST", "/api/v1/me/foods", sa.AccessToken, key, input); code != 201 || !sameJSON(replay, raw) {
		t.Fatal("creation replay")
	}
	input.Name = "Changed"
	if code, _ := request("POST", "/api/v1/me/foods", sa.AccessToken, key, input); code != 409 {
		t.Fatal("idempotency conflict", code)
	}
	in := exampleEntry()
	in.FoodID = food.ID
	in.FoodVersion = food.VersionID
	if code, _ := request("POST", "/api/v1/me/food-entries", sb.AccessToken, newID(), in); code != 404 {
		t.Fatal("cross-account food", code)
	}
	key = newID()
	var wg sync.WaitGroup
	codes := make(chan int, 2)
	bodies := make(chan []byte, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c, b := request("POST", "/api/v1/me/food-entries", sa.AccessToken, key, in)
			codes <- c
			bodies <- b
		}()
	}
	wg.Wait()
	close(codes)
	close(bodies)
	for code := range codes {
		if code != 201 {
			t.Fatal("concurrent idempotency", code)
		}
	}
	var entry Entry
	for b := range bodies {
		if json.Unmarshal(b, &entry) != nil {
			t.Fatal("entry response")
		}
	}
	if !strings.HasSuffix(entry.OccurredAt, "Z") {
		t.Fatal("response must normalize the instant to UTC")
	}
	if *entry.Calculation.Nutrients[0].Exact != "6273/2000" {
		t.Fatal("exact portion")
	}
	var n int
	if e := writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_entries WHERE user_id=$1", pa.User.ID).Scan(&n); e != nil || n != 1 {
		t.Fatal("duplicate record")
	}
	if code, _ := request("PATCH", "/api/v1/me/food-entries/"+entry.ID, sb.AccessToken, newID(), in); code != 404 {
		t.Fatal("cross-account entry", code)
	}
	in.Revision = 1
	in.Quantity = "50"
	status, raw = request("PATCH", "/api/v1/me/food-entries/"+entry.ID, sa.AccessToken, newID(), in)
	if status != 200 {
		t.Fatal("edit", status, string(raw))
	}
	_ = json.Unmarshal(raw, &entry)
	if entry.Calculation.Revision != 2 || len(entry.Calculation.Changes) != 1 || entry.Calculation.Changes[0].Quantity != "25.5" {
		t.Fatal("edit trace")
	}
	if code, _ := request("PATCH", "/api/v1/me/food-entries/"+entry.ID, sa.AccessToken, newID(), in); code != 409 {
		t.Fatal("stale revision")
	}
	status, raw = request("GET", "/api/v1/me/food-summary?date=2026-10-23&timezone=America%2FSao_Paulo", sa.AccessToken, "", nil)
	var sum NutritionTotals
	_ = json.Unmarshal(raw, &sum)
	if status != 200 || sum.Entries != 1 || *sum.Nutrients[0].Exact != "123/20" || sum.Nutrients[1].Value != nil {
		t.Fatal("summary", status, string(raw))
	}
	if status, _ := request("GET", path, sb.AccessToken, "", nil); status != 200 {
		t.Fatal("other account history")
	}
	if _, err := pool.Exec(ctx, "INSERT INTO trainforge_v1.food_versions(food_id,version_sha,owner_id,name_original,nutrients,provenance) VALUES('forbidden',repeat('a',64),$1,'x','[]','{}')", pa.User.ID); err == nil {
		t.Fatal("broad editorial insert privilege")
	}

	// Keep the real-reference path separate from the synthetic CI path. Both
	// exercise the same ownership, calculation, withdrawal and privacy checks.
	referenceID, referenceSHA := os.Getenv("TF_NUTRITION_RESEARCHED_FOOD_ID"), os.Getenv("TF_NUTRITION_RESEARCHED_FOOD_SHA")
	if synthetic {
		f := newFixture(t, "nutrition-ci-only")
		f.food.Nutrients[0].Value = ptr("13.7")
		f.food.Nutrients[0].Raw = json.RawMessage(`"13.7"`)
		f.saveFood(t)
		if _, err := Import(ctx, writer, f.load(t)); err != nil {
			t.Fatal("synthetic nutrition reference import failed")
		}
		referenceID = f.food.ID
		if writer.QueryRow(ctx, "SELECT version_sha FROM trainforge_v1.food_versions WHERE food_id=$1", referenceID).Scan(&referenceSHA) != nil {
			t.Fatal("synthetic nutrition version missing")
		}
	} else if referenceID == "" || referenceSHA == "" {
		t.Fatal("explicit reviewed reference required; use the fixture entry point for CI")
	}
	referenceFood, err := (FoodPostgres{Pool: pool}).Detail(ctx, referenceID, referenceSHA)
	if err != nil {
		t.Fatal("reviewed reference unavailable", err)
	}
	referenceInput := exampleEntry()
	referenceInput.FoodID = referenceID
	referenceInput.FoodVersion = referenceSHA
	referenceInput.Quantity = "37.5"
	referenceInput.Unit = *referenceFood.Basis.Unit
	referenceInput.OccurredAt = "2026-10-24T02:45:00Z"
	referenceInput.QuantityEvidence = "measured"
	code, b := request("POST", "/api/v1/me/food-entries", sa.AccessToken, newID(), referenceInput)
	if code != 201 {
		t.Fatal("reference consumption fixture", code, string(b))
	}
	var referenceEntry Entry
	_ = json.Unmarshal(b, &referenceEntry)
	checked := false
	for i, n := range referenceFood.Nutrients {
		if n.Scaling && n.Value != nil && n.BasisQuantity != nil {
			value, _ := new(big.Rat).SetString(*n.Value)
			base, _ := new(big.Rat).SetString(*n.BasisQuantity)
			expected := new(big.Rat).Quo(new(big.Rat).Mul(value, big.NewRat(75, 2)), base)
			if referenceEntry.Calculation.Nutrients[i].Exact == nil || *referenceEntry.Calculation.Nutrients[i].Exact != expected.RatString() {
				t.Fatal("reference portion mismatch")
			}
			checked = true
			break
		}
	}
	if !checked {
		t.Fatal("known base not exercised")
	}
	// 02:45 UTC is still the previous day in Sao Paulo.
	if code, b = request("GET", path+"&limit=1", sa.AccessToken, "", nil); code != 200 {
		t.Fatal("first page")
	}
	var first NutritionPage
	_ = json.Unmarshal(b, &first)
	if first.NextCursor == nil {
		t.Fatal("missing chronological cursor")
	}
	nextURL := path + "&limit=1&cursor=" + url.QueryEscape(*first.NextCursor)
	if code, b = request("GET", nextURL, sa.AccessToken, "", nil); code != 200 {
		t.Fatal("second page", code, string(b))
	}
	var second NutritionPage
	_ = json.Unmarshal(b, &second)
	var firstItems, secondItems []Entry
	_ = json.Unmarshal(first.Items, &firstItems)
	_ = json.Unmarshal(second.Items, &secondItems)
	if len(firstItems) != 1 || len(secondItems) != 1 || firstItems[0].ID == secondItems[0].ID || firstItems[0].ID != referenceEntry.ID {
		t.Fatal("chronological pagination")
	}
	if code, _ = request("GET", nextURL, sb.AccessToken, "", nil); code != 400 {
		t.Fatal("cross-account cursor", code)
	}
	if code, b = request("GET", "/api/v1/me/foods?q=Private", sa.AccessToken, "", nil); code != 200 || !strings.Contains(string(b), food.ID) {
		t.Fatal("private search")
	}
	if code, b = request("GET", "/api/v1/me/foods?q=Private", sb.AccessToken, "", nil); code != 200 || !strings.Contains(string(b), `"items":[]`) {
		t.Fatal("private search leaked")
	}
	if _, err = writer.Exec(ctx, "INSERT INTO trainforge_v1.food_withdrawals(food_id,version_sha,reason) VALUES($1,$2,'Disposable withdrawal fixture')", referenceID, referenceSHA); err != nil {
		t.Fatal(err)
	}
	referenceInput.Revision = 1
	referenceInput.Quantity = "50"
	if code, _ = request("PATCH", "/api/v1/me/food-entries/"+referenceEntry.ID, sa.AccessToken, newID(), referenceInput); code != 404 {
		t.Fatal("withdrawn food recalculated", code)
	}
	if code, _ = request("DELETE", "/api/v1/me/food-entries/"+referenceEntry.ID, sa.AccessToken, newID(), EntryInput{Revision: 1}); code != 200 {
		t.Fatal("withdrawn entry cannot be deleted", code)
	}
	svc := privacy.Service{Repository: privacy.Postgres{Pool: pool}}
	page, e := svc.Repository.Export(ctx, pa, privacy.ExportFilter{Section: "foodEntries", Limit: 20})
	if e != nil || len(page.Items) != 2 {
		t.Fatal("privacy export new entries", e)
	}
	changes := make([]EntryChange, 100)
	for i := range changes {
		changes[i] = entry.Calculation.Changes[0]
	}
	history, _ := json.Marshal(changes)
	if _, err = writer.Exec(ctx, `UPDATE trainforge_v1.food_entries SET calculation=jsonb_set(calculation,'{changes}',$2::jsonb) WHERE id=$1`, entry.ID, history); err != nil {
		t.Fatal(err)
	}
	status, raw = request("DELETE", "/api/v1/me/food-entries/"+entry.ID, sa.AccessToken, newID(), EntryInput{Revision: 2})
	if status != 200 {
		t.Fatal("delete", status, string(raw))
	}
	status, raw = request("GET", "/api/v1/me/food-summary?date=2026-10-23&timezone=America%2FSao_Paulo", sa.AccessToken, "", nil)
	_ = json.Unmarshal(raw, &sum)
	if status != 200 || sum.Entries != 0 {
		t.Fatal("deleted entry counted")
	}
	intent, e := svc.Intent(ctx, pa, privacy.Confirmation)
	if e != nil {
		t.Fatal(e)
	}
	if _, e = svc.Delete(ctx, pa, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge}); e != nil {
		t.Fatal("erase new data", e)
	}
	if e = writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_versions WHERE owner_id=$1", pa.User.ID).Scan(&n); e != nil || n != 0 {
		t.Fatal("private food remains")
	}
	if status, _ := request("POST", "/api/v1/me/foods", sa.AccessToken, newID(), input); status != 401 {
		t.Fatal("deleted account write")
	}
}

func sameJSON(a, b []byte) bool {
	var x, y any
	return json.Unmarshal(a, &x) == nil && json.Unmarshal(b, &y) == nil && reflect.DeepEqual(x, y)
}
