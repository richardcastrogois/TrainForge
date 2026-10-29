package catalogruntime

import (
	"io"
	"log/slog"
	"net/http/httptest"
	"testing"
	"time"
)

func TestConfigurationCannotReuseLegacyConnectionOrPublicListener(t *testing.T) {
	for _, key := range []string{"PGSERVICE", "PGSERVICEFILE", "PGPASSFILE"} {
		t.Setenv(key, "")
	}
	values := map[string]string{"TF_CATALOG_DATABASE_URL": "postgresql://trainforge_catalog_reader:fixture-only@127.0.0.1:15432/trainforge_catalog_test_012345abcdef?sslmode=disable"}
	get := func(k string) string { return values[k] }
	if _, err := Load(get); err != nil {
		t.Fatal("explicit proof config refused")
	}
	for _, addr := range []string{"0.0.0.0:18083", "localhost:18083", "127.0.0.1:0", "127.0.0.1:65536", "remote.invalid:18083"} {
		values["TF_CATALOG_LISTEN_ADDR"] = addr
		if _, err := Load(get); err == nil {
			t.Fatal("unsafe listener accepted")
		}
	}
	delete(values, "TF_CATALOG_LISTEN_ADDR")
	delete(values, "TF_CATALOG_DATABASE_URL")
	values["TF_DATABASE_URL"] = "legacy-must-not-be-used"
	if _, err := Load(get); err == nil {
		t.Fatal("ambient legacy connection used")
	}
}

func TestHandlerExposesOnlyPublicReadAndGenericHealth(t *testing.T) {
	handler := Handler(nil, slog.New(slog.NewJSONHandler(io.Discard, nil)), time.Second)
	for _, tc := range []struct {
		method, path string
		want         int
	}{
		{"GET", "/api/v1/health/live", 200}, {"GET", "/api/v1/health/ready", 503}, {"GET", "/api/v1/catalog/movements", 503},
		{"GET", "/api/v1/me", 404}, {"POST", "/api/v1/auth/google", 404}, {"GET", "/api/v1/me/food-entries", 404}, {"GET", "/api/v1/me/training-configuration", 404}, {"GET", "/docs/index.html", 404},
	} {
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, httptest.NewRequest(tc.method, tc.path, nil))
		if response.Code != tc.want {
			t.Fatalf("unexpected status for fixed test route: %d", response.Code)
		}
		if response.Header().Get("X-Request-Id") == "" {
			t.Fatal("missing correlation")
		}
	}
}
