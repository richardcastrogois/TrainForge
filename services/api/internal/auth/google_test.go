package auth

import (
	"cloud.google.com/go/auth/credentials/idtoken"
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"io"
	"log/slog"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func encoded(v any) string { b, _ := json.Marshal(v); return base64.RawURLEncoding.EncodeToString(b) }
func signFixture(t *testing.T, key *rsa.PrivateKey, claims map[string]any) string {
	t.Helper()
	data := encoded(map[string]any{"alg": "RS256", "kid": "fixture"}) + "." + encoded(claims)
	h := sha256.Sum256([]byte(data))
	sig, err := rsa.SignPKCS1v15(rand.Reader, key, crypto.SHA256, h[:])
	if err != nil {
		t.Fatal(err)
	}
	return data + "." + base64.RawURLEncoding.EncodeToString(sig)
}
func TestGoogleCryptographicValidationFixturesNotRealLogin(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "public, max-age=3600")
		_ = json.NewEncoder(w).Encode(map[string]any{"keys": []any{map[string]string{"kty": "RSA", "kid": "fixture", "alg": "RS256", "use": "sig", "n": base64.RawURLEncoding.EncodeToString(key.N.Bytes()), "e": base64.RawURLEncoding.EncodeToString(big.NewInt(int64(key.E)).Bytes())}}})
	}))
	defer server.Close()
	v, _ := idtoken.NewValidator(&idtoken.ValidatorOptions{Client: server.Client(), RS256CertsURL: server.URL, Logger: slog.New(slog.NewTextHandler(io.Discard, nil))})
	g := &Google{audience: "fixture-client", validator: v}
	for _, tc := range []struct {
		name    string
		change  func(map[string]any)
		invalid bool
	}{
		{"valid fixture", func(c map[string]any) {}, false},
		{"canonical issuer alias", func(c map[string]any) { c["iss"] = "accounts.google.com" }, false},
		{"audience", func(c map[string]any) { c["aud"] = "other" }, true},
		{"issuer", func(c map[string]any) { c["iss"] = "https://attacker.invalid" }, true},
		{"expired", func(c map[string]any) { c["exp"] = time.Now().Add(-time.Minute).Unix() }, true},
		{"subject", func(c map[string]any) { delete(c, "sub") }, true},
		{"unverified email", func(c map[string]any) { c["email_verified"] = false }, true},
		{"future issued", func(c map[string]any) { c["iat"] = time.Now().Add(time.Hour).Unix() }, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			claims := map[string]any{"iss": "https://accounts.google.com", "aud": "fixture-client", "sub": "fixture-only", "exp": time.Now().Add(time.Hour).Unix(), "iat": time.Now().Add(-time.Minute).Unix(), "email": "fixture@example.invalid", "email_verified": true, "name": "Isolated fixture"}
			tc.change(claims)
			token := signFixture(t, key, claims)
			i, err := g.Verify(context.Background(), token)
			if tc.invalid {
				if err != ErrInvalid {
					t.Fatalf("expected invalid: %v", err)
				}
			} else if err != nil || i.Issuer != "https://accounts.google.com" {
				t.Fatal("valid fixture rejected")
			}
		})
	}
	valid := signFixture(t, key, map[string]any{"iss": "https://accounts.google.com", "aud": "fixture-client", "sub": "fixture-only", "exp": time.Now().Add(time.Hour).Unix(), "iat": time.Now().Add(-time.Minute).Unix(), "email": "fixture@example.invalid", "email_verified": true})
	parts := strings.Split(valid, ".")
	parts[2] = base64.RawURLEncoding.EncodeToString(make([]byte, 256))
	for _, token := range []string{strings.Join(parts, "."), "malformed", encoded(map[string]string{"alg": "none", "kid": "fixture"}) + ".e30.", encoded(map[string]string{"alg": "RS256", "kid": "fixture"}) + ".bnVsbA.AA"} {
		if _, err := g.Verify(context.Background(), token); err != ErrInvalid {
			t.Fatal("malformed/tampered token accepted")
		}
	}
	disabled, _ := NewGoogle("")
	if _, err := disabled.Verify(context.Background(), valid); err != ErrUnavailable {
		t.Fatal("missing config must be unavailable")
	}
}

func TestGoogleKeyServiceFailureIsUnavailable(t *testing.T) {
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(503) }))
	defer server.Close()
	v, _ := idtoken.NewValidator(&idtoken.ValidatorOptions{Client: &http.Client{Transport: googleTransport{http.DefaultTransport}}, RS256CertsURL: server.URL, Logger: slog.New(slog.NewTextHandler(io.Discard, nil))})
	g := &Google{audience: "fixture-client", validator: v}
	token := signFixture(t, key, map[string]any{"iss": "https://accounts.google.com", "aud": "fixture-client", "sub": "fixture-only", "exp": time.Now().Add(time.Hour).Unix(), "iat": time.Now().Add(-time.Minute).Unix(), "email": "fixture@example.invalid", "email_verified": true})
	if _, err := g.Verify(context.Background(), token); err != ErrUnavailable {
		t.Fatalf("key dependency failure must be unavailable, got %v", err)
	}
}
