package catalog

import (
	"context"
	"encoding/json"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/platform/httpapi"
)

func TestCatalogFiltersAndCursorBoundaries(t *testing.T) {
	f, err := parseFilters(url.Values{"limit": {"2"}, "q": {"Bench"}}, []string{"movement"})
	if err != nil {
		t.Fatal(err)
	}
	token, _ := encodeCursor("wger:movement:9", f)
	parsed, err := parseFilters(url.Values{"limit": {"2"}, "q": {"Bench"}, "cursor": {token}}, []string{"movement"})
	if err != nil || parsed.After != "wger:movement:9" {
		t.Fatal("cursor round trip")
	}
	for _, q := range []url.Values{
		{"limit": {"0"}}, {"limit": {"51"}}, {"limit": {"2", "3"}}, {"mode": {"invented"}},
		{"q": {strings.Repeat("x", 101)}}, {"unknown": {"x"}}, {"cursor": {"garbage"}},
		{"q": {"Changed"}, "limit": {"2"}, "cursor": {token}},
	} {
		if _, err := parseFilters(q, []string{"movement"}); err != ErrQuery {
			t.Fatalf("accepted query: %v", q)
		}
	}
	if _, _, err := parseDetail(url.Values{"versionId": {"not-sha"}}); err != ErrQuery {
		t.Fatal("invalid version accepted")
	}
}
func TestCatalogNeverSerializesUnauthorizedPayloadFields(t *testing.T) {
	raw := []byte(`{"id":"fixture:movement:1","versionId":"a","kind":"movement","source":{"id":"fixture","name":"Fixture","urls":[]},"authors":[],"rights":{"displayCredits":{"creators":[],"secretInstruction":"do-not-serve"}},"audience":{},"requirements":{},"content":{"instruction":"do-not-serve"},"dose":{"sets":12},"mediaUrl":"do-not-serve"}`)
	item, err := decodeMetadata(raw)
	if err != nil {
		t.Fatal(err)
	}
	body, _ := json.Marshal(item)
	if strings.Contains(string(body), "do-not-serve") || strings.Contains(string(body), "sets") || item.Availability.Practice || item.Availability.Instruction || item.Availability.Media {
		t.Fatal("unauthorized content leaked")
	}
	if item.Audience.SupportRequired != nil || item.Audience.Environment != nil || len(item.Availability.Reasons) < 4 {
		t.Fatal("unknown requirements inferred")
	}
}
func TestCatalogPostgresAndConditionalWithdrawal(t *testing.T) {
	dsn := os.Getenv("TF_CATALOG_TEST_DATABASE_URL")
	writerDSN := os.Getenv("TF_CATALOG_TEST_WRITER_DATABASE_URL")
	if dsn == "" || writerDSN == "" {
		t.Skip("requires isolated disposable catalog database")
	}
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil || !strings.HasPrefix(cfg.ConnConfig.Database, "trainforge_v1_catalog_test_") {
		t.Fatal("refusing non-disposable database")
	}
	writerCfg, err := pgxpool.ParseConfig(writerDSN)
	if err != nil || writerCfg.ConnConfig.Database != cfg.ConnConfig.Database {
		t.Fatal("fixture writer mismatch")
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		t.Fatal("runtime connection")
	}
	defer pool.Close()
	writer, err := pgxpool.NewWithConfig(ctx, writerCfg)
	if err != nil {
		t.Fatal("fixture connection")
	}
	defer writer.Close()
	if _, err = writer.Exec(ctx, `INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('fixture-source','Isolated catalog fixture','["https://example.invalid/source"]')`); err != nil {
		t.Fatal("fixture source")
	}
	versionA := strings.Repeat("a", 64)
	versionB := strings.Repeat("b", 64)
	insert := func(id, kind, version string, allowed, qualified, practice bool) {
		t.Helper()
		operations := []string{}
		grant := "unknown"
		if allowed {
			operations = []string{"catalog_metadata"}
			grant = "allowed"
		}
		grants := map[string]any{"catalog_metadata": grant, "guided_practice": "unknown"}
		if practice {
			operations = append(operations, "guided_practice")
			grants["guided_practice"] = "allowed"
		}
		audience := map[string]any{"population": nil, "environment": nil, "supportRequired": nil}
		content := map[string]any{"instruction": "fixture-secret-do-not-serve", "mediaUrl": "fixture-secret-do-not-serve"}
		if qualified {
			audience["environment"] = []string{"home"}
			audience["population"] = []string{"older_adults"}
			content["modality"] = "mobility"
			content["category"] = map[string]any{"id": 1, "name": "Mobility"}
			content["equipment"] = []any{map[string]any{"id": 1, "name": "Chair"}}
		}
		payload, _ := json.Marshal(map[string]any{"authors": []string{"Fixture creator"}, "rights": map[string]any{"label": "Fixture license", "licenseUrl": "https://example.invalid/license", "attribution": "Fixture creator", "operationGrants": grants, "displayCredits": map[string]any{"title": "Fixture", "creators": []string{"Fixture creator"}, "sourceUrl": "https://example.invalid/source", "licenseUrl": "https://example.invalid/license", "licenseLabel": "Fixture license", "changes": "Isolated fixture only", "warrantyNotice": "Fixture warranty notice"}}, "review": map[string]any{"state": "reviewed", "rightsVerified": true, "fidelityChecked": true, "instructionSufficient": practice, "safetyUseReviewed": practice}, "audience": audience, "content": content, "dose": map[string]any{"sets": 99}})
		_, err := writer.Exec(ctx, `INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,allowed_operations,payload) VALUES($1,$2,$3,'fixture-source',$1,$4,$5::jsonb)`, id, version, kind, operations, string(payload))
		if err != nil {
			t.Fatal("fixture content insert")
		}
	}
	insert("fixture:movement:1", "movement", versionA, true, true, false)
	insert("fixture:movement:2", "movement", versionA, true, false, false)
	insert("fixture:movement:3", "movement", versionA, true, false, false)
	if _, err := writer.Exec(ctx, "UPDATE trainforge_v1.content_versions SET payload=jsonb_set(jsonb_set(payload,'{audience,environment}',$1::jsonb),'{audience,population}',$1::jsonb) WHERE asset_id='fixture:movement:2'", "{\"uninterpreted\":\"source requirement object\"}"); err != nil {
		t.Fatal("unknown requirement fixture")
	}
	insert("fixture:movement:forbidden", "movement", versionA, false, false, false)
	insert("fixture:movement:replaced", "movement", versionA, true, false, false)
	insert("fixture:movement:replaced", "movement", versionB, false, false, false)
	insert("fixture:program:1", "program", versionA, true, true, true)
	insert("fixture:collection:1", "collection", versionA, true, false, false)
	repo := CatalogPostgres{Pool: pool}
	reader := Reader{Repository: repo}
	f, _ := parseFilters(url.Values{"limit": {"2"}}, []string{"movement"})
	page, err := reader.List(ctx, f)
	if err != nil || len(page.Items) != 2 || page.NextCursor == nil {
		t.Fatalf("pagination failed: %v", err)
	}
	next, _ := parseFilters(url.Values{"limit": {"2"}, "cursor": {*page.NextCursor}}, []string{"movement"})
	page2, err := reader.List(ctx, next)
	if err != nil || len(page2.Items) != 1 || page2.NextCursor != nil || page2.Items[0].ID == page.Items[0].ID {
		t.Fatal("pagination duplicated or leaked")
	}
	filtered, _ := parseFilters(url.Values{"environment": {"home"}, "population": {"older_adults"}, "equipment": {"Chair"}, "category": {"Mobility"}, "modality": {"mobility"}}, []string{"movement"})
	result, err := reader.List(ctx, filtered)
	if err != nil || len(result.Items) != 1 || result.Items[0].ID != "fixture:movement:1" {
		t.Fatal("source filters or unknown eligibility")
	}
	practice, _ := parseFilters(url.Values{"mode": {"practice"}}, []string{"movement"})
	result, err = reader.List(ctx, practice)
	if err != nil || len(result.Items) != 0 {
		t.Fatal("unapproved practice")
	}
	programs, _ := parseFilters(url.Values{}, []string{"program", "collection"})
	result, err = reader.List(ctx, programs)
	if err != nil || len(result.Items) != 2 || result.Items[0].Kind == result.Items[1].Kind {
		t.Fatal("collection relabelled")
	}
	if _, err = reader.Detail(ctx, []string{"movement"}, "fixture:movement:replaced", "", "consultation"); err != ErrMissing {
		t.Fatal("forbidden new version fell back")
	}
	if _, err = reader.Detail(ctx, []string{"movement"}, "fixture:movement:replaced", versionA, "consultation"); err != nil {
		t.Fatal("explicit permitted history unavailable")
	}
	facets, facetErr := reader.Facets(ctx)
	if facetErr != nil || facets.MovementCount != 3 || facets.ProgramCount != 2 || len(facets.Equipment) != 1 || facets.UnknownEnvironmentCount != 3 {
		t.Fatalf("facet coverage failed: %v", facetErr)
	}
	handler := httpapi.New(pool, slog.New(slog.NewTextHandler(io.Discard, nil)), time.Second, nil, CatalogHandler{Reader: reader}.Register)
	path := "/api/v1/catalog/movements/fixture:movement:1"
	request := httptest.NewRequest(http.MethodGet, path, nil)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != 200 || response.Header().Get("ETag") == "" || strings.Contains(response.Body.String(), "fixture-secret-do-not-serve") {
		t.Fatal("projection/etag failed")
	}
	tag := response.Header().Get("ETag")
	request = httptest.NewRequest(http.MethodGet, path, nil)
	request.Header.Set("If-None-Match", tag)
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != 304 || response.Body.Len() != 0 {
		t.Fatal("conditional response failed")
	}
	if _, err = writer.Exec(ctx, `INSERT INTO trainforge_v1.content_withdrawals(asset_id,version_sha,reason) VALUES('fixture:movement:1',$1,'isolated withdrawal fixture')`, versionA); err != nil {
		t.Fatal("withdrawal fixture")
	}
	request = httptest.NewRequest(http.MethodGet, path, nil)
	request.Header.Set("If-None-Match", tag)
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != 404 {
		t.Fatal("withdrawal bypassed through cache")
	}
	if _, err = pool.Exec(ctx, `INSERT INTO trainforge_v1.content_withdrawals(asset_id,version_sha,reason) VALUES('fixture:movement:2',$1,'must fail')`, versionA); err == nil {
		t.Fatal("runtime can edit editorial rights")
	}
}
