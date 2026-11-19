package httpapi

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestCatalogTransferLimitsDoNotWidenPrivateAPIRequests(t *testing.T) {
	normal := 10 * time.Second
	for _, tc := range []struct {
		method, path string
		want         time.Duration
	}{
		{"GET", "/api/v1/food-catalog/archive", 30 * time.Minute},
		{"HEAD", "/api/v1/food-catalog/exports/AL-OFF.jsonl.gz", 30 * time.Minute},
		{"GET", "/api/v1/food-catalog/exports/" + strings.Repeat("a", 64) + "/AL-OFF.jsonl.gz", 30 * time.Minute},
		{"HEAD", "/api/v1/food-catalog/exports/" + strings.Repeat("a", 64) + "/AL-OFF.jsonl.gz", 30 * time.Minute},
		{"GET", "/api/v1/food-catalog/exports/" + strings.Repeat("a", 63) + "/AL-OFF.jsonl.gz", normal},
		{"GET", "/api/v1/food-catalog/exports/" + strings.Repeat("A", 64) + "/AL-OFF.jsonl.gz", normal},
		{"GET", "/api/v1/food-catalog/exports/" + strings.Repeat("a", 64) + "/../private", normal},
		{"GET", "/api/v1/food-catalog/exports/" + strings.Repeat("a", 64) + "/AL-OFF.jsonl.gz?file=../private", normal},
		{"GET", "/api/v1/food-catalog/manifest", normal},
		{"POST", "/api/v1/food-catalog/archive", normal},
		{"GET", "/api/v1/food-catalog/exports/../private", normal},
		{"GET", "/api/v1/food-catalog/archive/other", normal},
		{"POST", "/api/v1/me/nutrition/sync", normal},
	} {
		r := httptest.NewRequest(tc.method, tc.path, nil)
		if got := requestTimeout(r, normal); got != tc.want {
			t.Fatalf("%s %s: %s", tc.method, tc.path, got)
		}
	}
	if requestBodyLimit(httptest.NewRequest("POST", "/api/v1/me/nutrition/sync", nil)) != 2<<20 {
		t.Fatal("sync batch outer body limit")
	}
	if requestBodyLimit(httptest.NewRequest("POST", "/api/v1/me/food-contributions/11111111-1111-4111-8111-111111111111/media", nil)) != 4<<20 {
		t.Fatal("label upload outer body limit")
	}
	if requestBodyLimit(httptest.NewRequest(http.MethodPost, "/api/v1/me/foods", nil)) != 64<<10 {
		t.Fatal("legacy JSON limit widened")
	}
}
