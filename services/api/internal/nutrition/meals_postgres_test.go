package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"regexp"
	"strings"
	"sync"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/privacy"
)

func mealPools(t *testing.T) (context.Context, *pgxpool.Pool, *pgxpool.Pool) {
	t.Helper()
	dsn := os.Getenv("TF_MEALS_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("disposable meal SQL fixture not requested")
	}
	writer, e := pgx.ParseConfig(dsn)
	if e != nil || writer.Host != "127.0.0.1" || writer.Port != 15432 || writer.User != "trainforge_migrator" || !regexp.MustCompile(`^trainforge_v1_privacy_test_[a-f0-9]{12}$`).MatchString(writer.Database) {
		t.Fatal("unsafe writer target")
	}
	runtime, e := pgx.ParseConfig(os.Getenv("TF_MEALS_TEST_RUNTIME_URL"))
	if e != nil || runtime.Host != writer.Host || runtime.Port != writer.Port || runtime.Database != writer.Database || runtime.User != "trainforge_runtime" {
		t.Fatal("unsafe runtime target")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	t.Cleanup(cancel)
	w, e := pgxpool.New(ctx, dsn)
	if e != nil {
		t.Fatal("writer pool")
	}
	t.Cleanup(w.Close)
	r, e := pgxpool.New(ctx, os.Getenv("TF_MEALS_TEST_RUNTIME_URL"))
	if e != nil {
		t.Fatal("runtime pool")
	}
	t.Cleanup(r.Close)
	return ctx, w, r
}
func mealLogin(t *testing.T, ctx context.Context, pool *pgxpool.Pool, sub string) (auth.Service, auth.Principal) {
	t.Helper()
	s := auth.Service{Verifier: nutritionFixtureVerifier{sub}, Repository: auth.Postgres{Pool: pool}}
	session, e := s.Login(ctx, "isolated-fixture-not-google")
	if e != nil {
		t.Fatal(e)
	}
	p, e := s.Authorize(ctx, session.AccessToken)
	if e != nil {
		t.Fatal(e)
	}
	return s, p
}
func mealFood(t *testing.T, ctx context.Context, store NutritionStore, p auth.Principal) FoodDetail {
	t.Helper()
	c := OwnFoodInput{Name: "Disposable meal fixture", Basis: Basis{Quantity: ptr("100"), Unit: ptr("g")}, Nutrients: []OwnNutrient{{Name: "Fixture fiber", Unit: "g", Value: ptr("2")}, {Name: "Fixture unknown", Unit: "mg"}}}
	raw, _ := json.Marshal(c)
	out, _, e := store.Mutate(ctx, p, "own-food", "", newID(), raw)
	if e != nil {
		t.Fatal(e)
	}
	var f FoodDetail
	if json.Unmarshal(out, &f) != nil {
		t.Fatal("fixture food")
	}
	return f
}
func mealCommand(f FoodDetail) NewMealCommand {
	item := EntryInput{FoodID: f.ID, FoodVersion: f.VersionID, Quantity: "01.00", Unit: "g", OccurredAt: "2026-10-27T23:59:00Z", Timezone: "UTC", QuantityEvidence: "estimated"}
	other := item
	other.Quantity = "2"
	other.OccurredAt = "2026-10-28T00:01:00Z"
	return NewMealCommand{Title: "", OccurredAt: item.OccurredAt, Timezone: "UTC", Reviewed: true, Items: []EntryInput{item, other}}
}
func TestMealPostgresAtomicOwnershipReplayAndPrivacy(t *testing.T) {
	ctx, w, r := mealPools(t)
	_, a := mealLogin(t, ctx, r, "meal-a")
	_, b := mealLogin(t, ctx, r, "meal-b")
	base := NutritionStore{Pool: r}
	store := MealStore{Nutrition: base}
	service := MealCreateService{Repository: store}
	fa, fb := mealFood(t, ctx, base, a), mealFood(t, ctx, base, b)
	command := mealCommand(fa)
	key := newID()
	var startCount int
	if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.food_entries WHERE user_id=$1", a.User.ID).Scan(&startCount) != nil {
		t.Fatal("count")
	}
	bad := command
	bad.Items = append([]EntryInput{}, command.Items...)
	bad.Items[1].FoodID = fb.ID
	bad.Items[1].FoodVersion = fb.VersionID
	if _, e := service.Create(ctx, a, bad, newID()); !errors.Is(e, ErrFoodMissing) {
		t.Fatalf("foreign private food: %v", e)
	}
	var entries, groups int
	if w.QueryRow(ctx, "SELECT (SELECT count(*) FROM trainforge_v1.food_entries WHERE user_id=$1),(SELECT count(*) FROM trainforge_v1.meals WHERE user_id=$1)", a.User.ID).Scan(&entries, &groups) != nil || entries != startCount || groups != 0 {
		t.Fatal("failed second item left partial data")
	}
	// Parallel delivery of one intention must create only one meal and two entries.
	var wg sync.WaitGroup
	results := make(chan ConfirmedMeal, 2)
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			result, e := service.Create(ctx, a, command, key)
			results <- result
			errs <- e
		}()
	}
	wg.Wait()
	close(results)
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	var created ConfirmedMeal
	for v := range results {
		if created.Meal.ID != "" && !reflect.DeepEqual(created, v) {
			t.Fatal("retry changed result")
		}
		created = v
	}
	if len(created.Entries) != 2 || created.Entries[0].Quantity != "1.00" || created.Meal.TotalActiveItems != 2 {
		t.Fatal("decimal or item count changed")
	}
	// A day uses each entry once, and reports the other active item outside that day.
	diary := MealDiaryService{Repository: store}
	day, e := diary.Day(ctx, a, "2026-10-27", "UTC")
	if e != nil || len(day.Entries) != 1 || len(day.Meals) != 1 || day.Meals[0].OtherActiveItems != 1 || day.Totals.Entries != 1 || *day.Totals.Nutrients[0].Exact != "1/50" || day.Totals.Nutrients[1].Value != nil {
		t.Fatalf("day grouping: %v", e)
	}
	if _, e = store.Meal(ctx, b, created.Meal.ID); !errors.Is(e, ErrFoodMissing) {
		t.Fatal("other account read meal")
	}
	if _, e = store.ChangeMeal(ctx, b, created.Meal.ID, newID(), nil, &DeleteMealCommand{Revision: 1, Reviewed: true}); !errors.Is(e, ErrFoodMissing) {
		t.Fatal("other account deleted meal")
	}
	// Forged principal fails against a live credential, independently of HTTP auth.
	forged := a
	forged.User.ID = b.User.ID
	if _, e = store.ReadMealDay(ctx, forged, "2026-10-27", "UTC"); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("forged principal accepted")
	}
	for _, query := range []string{"UPDATE trainforge_v1.meals SET title='forged'", "DELETE FROM trainforge_v1.meal_items", "DELETE FROM trainforge_v1.meal_versions"} {
		if _, e = r.Exec(ctx, query); e == nil {
			t.Fatal("direct runtime meal DML accepted")
		}
	}
	// Database function rejects cross-owner membership even if an application adapter is wrong.
	cb, e := service.Create(ctx, b, mealCommand(fb), newID())
	if e != nil {
		t.Fatal(e)
	}
	_, e = r.Exec(ctx, `SELECT trainforge_v1.confirm_meal_group($1,$2,$3,$4,0,'',clock_timestamp(),'UTC',ARRAY[$5::uuid])`, a.User.ID, a.FamilyID, a.AccessHash, newID(), cb.Entries[0].ID)
	if !errors.Is(mealDatabaseError(e), ErrFoodQuery) {
		t.Fatal("SQL cross-owner binding accepted")
	}
	edit := EditMealCommand{Revision: 1, Reviewed: true, Title: "Explicit fixture title", OccurredAt: command.OccurredAt, Timezone: command.Timezone}
	editKey := newID()
	updated, e := store.ChangeMeal(ctx, a, created.Meal.ID, editKey, &edit, nil)
	if e != nil || updated.Meal.Revision != 2 || updated.Meal.Title != edit.Title || !reflect.DeepEqual(updated.Entries, created.Entries) {
		t.Fatalf("metadata edit changed intakes: %v", e)
	}
	again, e := store.ChangeMeal(ctx, a, created.Meal.ID, editKey, &edit, nil)
	if e != nil || !reflect.DeepEqual(updated, again) {
		t.Fatal("metadata edit retry")
	}
	if _, e = service.Create(ctx, a, command, key); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("late create replay hid metadata correction")
	}
	if _, e = store.ChangeMeal(ctx, a, created.Meal.ID, newID(), &edit, nil); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("stale group revision accepted")
	}
	// Item correction uses the original entry path and affects the group projection once.
	in := command.Items[0]
	in.Quantity = "3"
	in.Revision = 1
	raw, _ := json.Marshal(in)
	if _, _, e = base.Mutate(ctx, a, "edit-entry:"+created.Entries[0].ID, created.Entries[0].ID, newID(), raw); e != nil {
		t.Fatal(e)
	}
	day, e = diary.Day(ctx, a, "2026-10-27", "UTC")
	if e != nil || *day.Totals.Nutrients[0].Exact != "3/50" || *day.Meals[0].Totals.Nutrients[0].Exact != "3/50" {
		t.Fatal("corrected item double-counted or not reflected")
	}
	// Single item deletion preserves group identity and the other item.
	raw = []byte(`{"revision":2}`)
	if _, _, e = base.Mutate(ctx, a, "delete-entry:"+created.Entries[0].ID, created.Entries[0].ID, newID(), raw); e != nil {
		t.Fatal(e)
	}
	detail, e := store.Meal(ctx, a, created.Meal.ID)
	if e != nil || detail.Meal.TotalActiveItems != 1 || detail.DeletedAt != nil || detail.Entries[1].DeletedAt != nil {
		t.Fatal("single item delete removed meal or peer")
	}
	deleteKey := newID()
	deleted, e := store.ChangeMeal(ctx, a, created.Meal.ID, deleteKey, nil, &DeleteMealCommand{Revision: 2, Reviewed: true})
	if e != nil || deleted.Meal.Revision != 3 || deleted.Meal.TotalActiveItems != 0 || deleted.DeletedAt == nil || deleted.Entries[1].DeletedAt == nil {
		t.Fatalf("whole meal delete: %v", e)
	}
	if v, e := store.ChangeMeal(ctx, a, created.Meal.ID, deleteKey, nil, &DeleteMealCommand{Revision: 2, Reviewed: true}); e != nil || !reflect.DeepEqual(v, deleted) {
		t.Fatal("delete retry changed revisions")
	}
	if _, e = service.Create(ctx, a, command, key); !errors.Is(e, ErrEntryConflict) {
		t.Fatal("create replay revived deleted meal")
	}
	day, e = diary.Day(ctx, a, "2026-10-28", "UTC")
	if e != nil || len(day.Entries) != 0 || len(day.Meals) != 0 {
		t.Fatal("deleted meal still in diary")
	}
	// Export includes grouping/history but never the other account's IDs or foods.
	priv := privacy.Service{Repository: privacy.Postgres{Pool: r}}
	for _, section := range []string{"meals", "mealItems", "mealVersions"} {
		v, e := priv.Repository.Export(ctx, a, privacy.ExportFilter{Section: section, Limit: 50})
		if e != nil || len(v.Items) == 0 {
			t.Fatalf("export %s: %v", section, e)
		}
		raw, _ := json.Marshal(v)
		if regexp.MustCompile(b.User.ID + "|" + cb.Meal.ID).Match(raw) {
			t.Fatal("foreign export")
		}
	}
	intent, e := priv.Intent(ctx, a, privacy.Confirmation)
	if e != nil {
		t.Fatal(e)
	}
	erased, e := priv.Delete(ctx, a, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge})
	if e != nil || !erased.Deleted {
		t.Fatalf("account meal erasure: %v", e)
	}
	for _, table := range []string{"meals", "meal_items", "meal_versions", "food_entries"} {
		var count int
		if w.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1."+table+" WHERE user_id=$1", a.User.ID).Scan(&count) != nil || count != 0 {
			t.Fatal("owned rows survived erasure: " + table)
		}
	}
	if _, e = store.Meal(ctx, b, cb.Meal.ID); e != nil {
		t.Fatal("erasure affected other owner")
	}
	// No actual Google login, user data, image upload or clinical content in this fixture.
}

func TestMealPostgresDayBoundAndLegacy(t *testing.T) {
	ctx, w, r := mealPools(t)
	_, p := mealLogin(t, ctx, r, "meal-bounded")
	base := NutritionStore{Pool: r}
	store := MealStore{Nutrition: base}
	f := mealFood(t, ctx, base, p)
	in := mealCommand(f).Items[0]
	food, _, e := func() (FoodDetail, string, error) {
		tx, e := base.begin(ctx, p, false)
		if e != nil {
			return FoodDetail{}, "", e
		}
		defer tx.Rollback(ctx)
		return selectedFood(ctx, tx, p, f.ID, f.VersionID)
	}()
	if e != nil {
		t.Fatal(e)
	}
	calc, e := scaled(food, in, "personal")
	if e != nil {
		t.Fatal(e)
	}
	raw, _ := json.Marshal(calc)
	for i := 0; i < 101; i++ {
		_, e = w.Exec(ctx, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation) VALUES($1,$2,$3,$4,1,'g','2026-10-27 12:00Z','UTC',$5)`, fmt.Sprintf("12345678-0000-4000-8000-%012d", i), p.User.ID, f.ID, f.VersionID, raw)
		if e != nil {
			t.Fatal("bounded fixture insert")
		}
	}
	day, e := (MealDiaryService{Repository: store}).Day(ctx, p, "2026-10-27", "UTC")
	if e != nil || day.Complete || day.Totals.Complete || len(day.Entries) != 100 || len(day.UngroupedEntryIDs) != 100 || len(day.Meals) != 0 {
		t.Fatalf("bound or legacy changed: %v", e)
	}
	if _, e = w.Exec(ctx, "UPDATE trainforge_v1.auth_families SET revoked_at=clock_timestamp() WHERE id=$1", p.FamilyID); e != nil {
		t.Fatal(e)
	}
	if _, e = store.ReadMealDay(ctx, p, "2026-10-27", "UTC"); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("revoked principal read meals")
	}
}

func TestMealPostgresHTTPContractAndBoundaries(t *testing.T) {
	ctx, _, r := mealPools(t)
	authentication := auth.Service{Verifier: nutritionFixtureVerifier{"meal-http"}, Repository: auth.Postgres{Pool: r}}
	session, e := authentication.Login(ctx, "isolated-http-fixture-not-google")
	if e != nil {
		t.Fatal(e)
	}
	p, e := authentication.Authorize(ctx, session.AccessToken)
	if e != nil {
		t.Fatal(e)
	}
	base := NutritionStore{Pool: r}
	food := mealFood(t, ctx, base, p)
	h := &EntryHandler{Store: base, Names: FoodPostgres{Pool: r}, Authorize: authentication.Authorize}
	mux := http.NewServeMux()
	h.Register(mux)
	request := func(method, path, key string, body any, mutate func(*http.Request)) *httptest.ResponseRecorder {
		var raw []byte
		if s, ok := body.(string); ok {
			raw = []byte(s)
		} else {
			raw, _ = json.Marshal(body)
		}
		req := httptest.NewRequest(method, path, strings.NewReader(string(raw)))
		req.Header.Set("Authorization", "Bearer "+session.AccessToken)
		req.Header.Set("Content-Type", "application/json")
		if key != "" {
			req.Header.Set("Idempotency-Key", key)
		}
		if mutate != nil {
			mutate(req)
		}
		out := httptest.NewRecorder()
		mux.ServeHTTP(out, req)
		return out
	}
	command := mealCommand(food)
	key := newID()
	out := request("POST", "/api/v1/me/meals", key, command, nil)
	var created ConfirmedMeal
	if out.Code != 201 || json.Unmarshal(out.Body.Bytes(), &created) != nil || out.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("HTTP create status %d", out.Code)
	}
	if out := request("POST", "/api/v1/me/meals", key, command, nil); out.Code != 201 {
		t.Fatal("HTTP retry")
	}
	for _, locale := range []string{"pt-BR", "pt-PT", "en", "es"} {
		out := request("GET", "/api/v1/me/meal-diary?date=2026-10-27&timezone=UTC&locale="+locale, "", nil, nil)
		var response MealDayResponse
		if out.Code != 200 || json.Unmarshal(out.Body.Bytes(), &response) != nil || response.Diary.Totals.Entries != 1 || response.NameCatalog == nil || response.NameCatalog.Locale != locale || response.Diary.Entries[0].FoodDisplay == nil {
			t.Fatalf("localized diary status %d", out.Code)
		}
	}
	path := "/api/v1/me/meals/" + created.Meal.ID
	if out := request("GET", path+"?locale=es", "", nil, nil); out.Code != 200 {
		t.Fatal("HTTP detail")
	}
	edit := EditMealCommand{Reviewed: true, Revision: 1, Title: "HTTP fixture", OccurredAt: command.OccurredAt, Timezone: "UTC"}
	if out := request("PATCH", path, newID(), edit, nil); out.Code != 200 {
		t.Fatal("HTTP edit")
	}
	if out := request("PATCH", path, newID(), edit, nil); out.Code != 409 {
		t.Fatal("HTTP stale revision")
	}
	for _, c := range []struct {
		method, path, key, body string
		status                  int
	}{
		{"GET", "/api/v1/me/meal-diary", "", "", 400},
		{"GET", "/api/v1/me/meal-diary?date=2026-10-27&timezone=UTC&date=2026-10-28", "", "", 400},
		{"GET", path + "?locale=pt", "", "", 400},
		{"GET", "/api/v1/me/meals/not-a-uuid", "", "", 400},
		{"GET", "/api/v1/me/meals/00000000-0000-4000-8000-000000000000", "", "", 404},
		{"POST", "/api/v1/me/meals?userId=forged", newID(), `{}`, 400},
		{"POST", "/api/v1/me/meals", "", `{}`, 400},
		{"POST", "/api/v1/me/meals", newID(), `{"reviewed":true,"reviewed":false}`, 400},
		{"POST", "/api/v1/me/meals", newID(), `{"userId":"forged"}`, 400},
		{"POST", "/api/v1/me/meals", newID(), "{\"title\":\"\xff\"}", 400},
		{"POST", "/api/v1/me/meals", newID(), strings.Repeat(" ", 65537), 413},
	} {
		if out := request(c.method, c.path, c.key, c.body, nil); out.Code != c.status {
			t.Fatalf("boundary %s status %d expected %d", c.path, out.Code, c.status)
		}
	}
	for _, mutate := range []func(*http.Request){
		func(r *http.Request) { r.Header.Add("Authorization", "Bearer duplicate") },
		func(r *http.Request) { r.Header.Del("Authorization") },
	} {
		if out := request("GET", path, "", nil, mutate); out.Code != 401 {
			t.Fatal("ambiguous credential accepted")
		}
	}
	if out := request("GET", path, "", nil, func(r *http.Request) { r.Header.Set("X-TrainForge-Account", newID()) }); out.Code != 409 {
		t.Fatal("wrong account header accepted")
	}
	if out := request("POST", "/api/v1/me/meals", newID(), command, func(r *http.Request) { r.Header.Set("Content-Type", "text/plain") }); out.Code != 415 {
		t.Fatal("wrong content type accepted")
	}
	if out := request("DELETE", path, newID(), DeleteMealCommand{Revision: 2, Reviewed: true}, nil); out.Code != 200 {
		t.Fatal("HTTP whole meal delete")
	}
	if out := request("POST", "/api/v1/me/meals", key, command, nil); out.Code != 409 {
		t.Fatal("HTTP replay revived deleted meal")
	}
	if e := authentication.Logout(ctx, session.RefreshToken); e != nil {
		t.Fatal(e)
	}
	if out := request("GET", path, "", nil, nil); out.Code != 401 {
		t.Fatal("revoked HTTP credential accepted")
	}
}
