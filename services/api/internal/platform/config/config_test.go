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

func TestGoogleAudienceRequiresExplicitPublicClientID(t *testing.T) {
	for _, value := range []string{"", "example.apps.googleusercontent.com"} {
		c, err := Load(func(k string) string {
			if k == "TF_GOOGLE_SERVER_CLIENT_ID" {
				return value
			}
			return ""
		})
		if err != nil || c.GoogleAudience != value {
			t.Fatal("audience configuration mismatch")
		}
	}
	for _, value := range []string{"not-a-client", "one.apps.googleusercontent.com,two.apps.googleusercontent.com", "secret\n.apps.googleusercontent.com"} {
		if _, err := Load(func(k string) string {
			if k == "TF_GOOGLE_SERVER_CLIENT_ID" {
				return value
			}
			return ""
		}); err == nil {
			t.Fatal("accepted invalid audience configuration")
		}
	}
}

func TestTrustedProxyConfigurationIsExplicitAndBounded(t *testing.T) {
	for _, value := range []string{"0.0.0.0/0", "::/0", "bad", "127.0.0.1", strings.Repeat("10.0.0.0/24,", 17)} {
		if _, err := Load(func(k string) string {
			if k == "TF_TRUSTED_PROXY_CIDRS" {
				return value
			}
			return ""
		}); err == nil {
			t.Fatal("unsafe proxy configuration accepted")
		}
	}
	c, err := Load(func(k string) string {
		if k == "TF_TRUSTED_PROXY_CIDRS" {
			return "10.0.0.1/24,2001:db8::/64"
		}
		return ""
	})
	if err != nil || len(c.TrustedProxies) != 2 {
		t.Fatal("valid explicit proxies refused")
	}
}
