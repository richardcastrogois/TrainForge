package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
)

func TestFoodQueryRejectsInvalidAndChangedCursor(t *testing.T) {
	for _, raw := range []string{"limit=0", "limit=51", "limit=NaN", "q=a&q=b", "mode=practice", "q=%00", "q=%FF", "cursor=bad", "q=" + strings.Repeat("a", 101)} {
		q, _ := url.ParseQuery(raw)
		if _, err := foodFilters(q); !errors.Is(err, ErrFoodQuery) {
			t.Fatalf("unsafe query accepted: %q", raw)
		}
	}
	f, _ := foodFilters(url.Values{"q": {"raw"}, "limit": {"1"}})
	token := foodCursor("food:"+strings.Repeat("a", 64), f)
	q := url.Values{"q": {"raw"}, "limit": {"1"}, "cursor": {token}}
	if got, err := foodFilters(q); err != nil || got.After == "" {
		t.Fatal("valid cursor refused")
	}
	q.Set("q", "different")
	if _, err := foodFilters(q); !errors.Is(err, ErrFoodQuery) {
		t.Fatal("cursor crossed search boundary")
	}
	for _, q := range []url.Values{{"versionId": {"bad"}}, {"versionId": {strings.Repeat("a", 64), strings.Repeat("b", 64)}}, {"ownerId": {"any"}}} {
		if _, err := foodVersion(q); !errors.Is(err, ErrFoodQuery) {
			t.Fatal("unsafe detail query")
		}
	}
}
func TestFoodUnavailableIsSafe(t *testing.T) {
	mux := http.NewServeMux()
	FoodHandler{}.Register(mux)
	for _, path := range []string{"/api/v1/foods?q=%zz", "/api/v1/foods/filters?x=%zz", "/api/v1/foods/food:" + strings.Repeat("a", 64) + "?versionId=%zz"} {
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, httptest.NewRequest("GET", path, nil))
		if response.Code != 400 {
			t.Fatal("malformed query silently dropped")
		}
	}
	for _, path := range []string{"/api/v1/foods", "/api/v1/foods/filters", "/api/v1/foods/food:" + strings.Repeat("a", 64)} {
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, httptest.NewRequest("GET", path, nil))
		if response.Code != 503 || strings.Contains(response.Body.String(), "postgres") {
			t.Fatal("unsafe dependency response")
		}
	}
}
func TestFoodPublicPostgresVisibilityPaginationAndWithdrawal(t *testing.T) {
	dsn := os.Getenv("TF_FOOD_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("isolated PostgreSQL food fixture database not requested")
	}
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || !strings.HasPrefix(cfg.Database, "trainforge_v1_food_test_") {
		t.Fatal("unsafe fixture target")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	writer, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal("writer unavailable")
	}
	defer writer.Close()
	runtimeCfg, err := pgx.ParseConfig(os.Getenv("TF_FOOD_TEST_RUNTIME_URL"))
	if err != nil || runtimeCfg.Database != cfg.Database || runtimeCfg.Host != cfg.Host || runtimeCfg.Port != cfg.Port {
		t.Fatal("unsafe runtime target")
	}
	runtime, err := pgxpool.New(ctx, os.Getenv("TF_FOOD_TEST_RUNTIME_URL"))
	if err != nil {
		t.Fatal("runtime unavailable")
	}
	defer runtime.Close()
	reader := FoodReader{FoodPostgres{runtime}}
	baseline, err := reader.Facets(ctx)
	if err != nil {
		t.Fatal("baseline facets")
	}
	for _, code := range []string{"public-a", "public-b", "public-c"} {
		f := newFixture(t, code)
		f.food.Name = "read-fixture 100%_\n " + code
		f.saveFood(t)
		if _, err := Import(ctx, writer, f.load(t)); err != nil {
			t.Fatalf("fixture import: %v", err)
		}
	}
	// Private foods and unreviewed source rows must never enter public pages/facets.
	_, err = writer.Exec(ctx, `INSERT INTO trainforge_v1.users(id,provider,issuer,subject,email,display_name)
 VALUES('00000000-0000-4000-8000-000000000119','fixture','https://fixture.invalid','fixture-food-private','fixture@example.test','Fixture');
 INSERT INTO trainforge_v1.food_versions(food_id,version_sha,owner_id,name_original,nutrients,provenance)
 VALUES('food:'||repeat('7',64),repeat('9',64),'00000000-0000-4000-8000-000000000119','read-fixture private','[]','{}');
 INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,name_original,nutrients,provenance,allowed_operations)
 VALUES('food:'||repeat('8',64),repeat('8',64),'AL-CIQUAL-2025','read-fixture unreviewed','[]','{}',ARRAY['food_catalog','food_composition']);`)
	if err != nil {
		t.Fatal("private/unreviewed fixtures failed")
	}
	f := FoodFilters{Q: "read-fixture", Limit: 1}
	first, err := reader.List(ctx, f)
	if err != nil || len(first.Items) != 1 || first.NextCursor == nil {
		t.Fatalf("first page %v", err)
	}
	secondFilter, err := foodFilters(url.Values{"q": {f.Q}, "limit": {"1"}, "cursor": {*first.NextCursor}})
	if err != nil {
		t.Fatal("cursor parse")
	}
	second, err := reader.List(ctx, secondFilter)
	if err != nil || len(second.Items) != 1 || second.Items[0].ID == first.Items[0].ID {
		t.Fatal("repeated page")
	}
	literal, err := reader.List(ctx, FoodFilters{Q: "100%_", Limit: 50})
	if err != nil || len(literal.Items) != 3 {
		t.Fatal("literal percent/underscore search")
	}
	space, err := reader.List(ctx, FoodFilters{Q: "100%_ public-a", Limit: 20})
	if err != nil || len(space.Items) != 1 {
		t.Fatal("source newline search failed")
	}
	empty, err := reader.List(ctx, FoodFilters{Q: "100XY", Limit: 50})
	if err != nil || len(empty.Items) != 0 {
		t.Fatal("wildcards expanded")
	}
	private, err := reader.List(ctx, FoodFilters{Q: "read-fixture private", Limit: 20})
	if err != nil || len(private.Items) != 0 {
		t.Fatal("private row leaked")
	}
	unknown, err := reader.List(ctx, FoodFilters{Source: "unknown", Limit: 20})
	if err != nil || len(unknown.Items) != 0 {
		t.Fatal("unknown source inferred")
	}
	item := first.Items[0]
	detail, err := reader.Detail(ctx, item.ID, item.VersionID)
	if err != nil || len(detail.Nutrients) != 1 || detail.Nutrients[0].Value == nil || *detail.Nutrients[0].Value != "0" || detail.Nutrients[0].Raw != "0" {
		t.Fatal("exact zero/source lost")
	}
	mux := http.NewServeMux()
	FoodHandler{reader}.Register(mux)
	request := func(path, tag string) *httptest.ResponseRecorder {
		r := httptest.NewRequest("GET", path, nil)
		r.Header.Set("If-None-Match", tag)
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	path := "/api/v1/foods/" + item.ID + "?versionId=" + item.VersionID
	response := request(path, "")
	tag := response.Header().Get("ETag")
	if response.Code != 200 || tag == "" || request(path, tag).Code != 304 {
		t.Fatal("conditional reference request")
	}
	if _, err = writer.Exec(ctx, "INSERT INTO trainforge_v1.food_withdrawals(food_id,version_sha,reason) VALUES($1,$2,'fixture withdrawal')", item.ID, item.VersionID); err != nil {
		t.Fatal("withdrawal fixture")
	}
	if request(path, tag).Code != 404 {
		t.Fatal("withdrawn item served from cache")
	}
	// A newer unavailable version blocks the default route rather than reviving old data.
	other := second.Items[0]
	if _, err = writer.Exec(ctx, `INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,name_original,nutrients,provenance,created_at)
 VALUES($1,repeat('f',64),'AL-CIQUAL-2025','unapproved latest','[]','{}',now()+interval '1 day')`, other.ID); err != nil {
		t.Fatal("latest fixture")
	}
	if _, err = reader.Detail(ctx, other.ID, ""); !errors.Is(err, ErrFoodMissing) {
		t.Fatal("older version revived")
	}
	visible, err := reader.List(ctx, FoodFilters{Q: "read-fixture", Limit: 50})
	if err != nil || len(visible.Items) != 1 {
		t.Fatal("visibility rule differed across routes")
	}
	facets, err := reader.Facets(ctx)
	if err != nil {
		t.Fatal("facets failed")
	}
	body, _ := json.Marshal(facets)
	if facets.Total != baseline.Total+1 {
		t.Fatal("private or unavailable counts leaked into facets")
	}
	remaining := visible.Items[0]
	if _, err = writer.Exec(ctx, "UPDATE trainforge_v1.food_versions SET allowed_operations=ARRAY['food_catalog'] WHERE food_id=$1 AND version_sha=$2", remaining.ID, remaining.VersionID); err != nil {
		t.Fatal("grant fixture")
	}
	if _, err = reader.Detail(ctx, remaining.ID, remaining.VersionID); !errors.Is(err, ErrFoodMissing) {
		t.Fatal("composition grant ignored")
	}
	if strings.Contains(string(body), "private") || strings.Contains(string(body), "unreviewed") {
		t.Fatal("private facet leaked")
	}
}
