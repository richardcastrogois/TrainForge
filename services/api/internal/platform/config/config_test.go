package config

import (
	"strings"
	"testing"
)

func TestConfigValidationAndNoLegacyDatabaseFallback(t *testing.T) {
	c, err := Load(func(k string) string {
		if k == "DATABASE_URL" {
			return "legacy-secret"
		}
		return ""
	})
	if err != nil || c.DatabaseURL != "" || c.ListenAddr != "127.0.0.1:8082" {
		t.Fatal("defaults or isolation failed")
	}
	for _, env := range []map[string]string{
		{"TF_LISTEN_ADDR": "bad"}, {"TF_LISTEN_ADDR": "127.0.0.1:0"}, {"TF_ENV": "prod?"}, {"TF_DB_MAX_CONNS": "1000"},
		{"TF_REQUEST_TIMEOUT_SECONDS": "-1"}, {"TF_SWAGGER": "yes?"}, {"TF_SWAGGER": "true", "TF_LISTEN_ADDR": "0.0.0.0:8082"},
		{"TF_SWAGGER": "true", "TF_ENV": "production"},
	} {
		_, err := Load(func(k string) string { return env[k] })
		if err == nil {
			t.Fatalf("accepted invalid configuration: %v", env)
		}
		if strings.Contains(err.Error(), "legacy-secret") {
			t.Fatal("secret leaked")
		}
	}
}
