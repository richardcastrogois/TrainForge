package auth

import (
	"cloud.google.com/go/auth/credentials/idtoken"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

var ErrInvalid = errors.New("invalid credential")
var ErrUnavailable = errors.New("authentication unavailable")

type Identity struct{ Issuer, Subject, Name, Email string }
type Verifier interface {
	Verify(context.Context, string) (Identity, error)
}
type Google struct {
	audience  string
	validator *idtoken.Validator
}

// Cert URLs are fixed by the SDK. Discard SDK debug logs even if enabled by env.
func NewGoogle(audience string) (*Google, error) {
	v, err := idtoken.NewValidator(&idtoken.ValidatorOptions{
		Client: &http.Client{Timeout: 5 * time.Second, Transport: googleTransport{http.DefaultTransport}},
		Logger: slog.New(slog.NewTextHandler(io.Discard, nil)),
	})
	if err != nil {
		return nil, ErrUnavailable
	}
	return &Google{audience: audience, validator: v}, nil
}

type googleTransport struct{ base http.RoundTripper }

func (t googleTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	response, err := t.base.RoundTrip(r)
	if err != nil {
		return nil, ErrUnavailable
	}
	if response.StatusCode != http.StatusOK {
		response.Body.Close()
		return nil, ErrUnavailable
	}
	return response, nil
}
func (g *Google) Verify(ctx context.Context, token string) (Identity, error) {
	if g.audience == "" || g.validator == nil {
		return Identity{}, ErrUnavailable
	}
	parts := strings.Split(token, ".")
	if len(token) > 16384 || len(parts) != 3 {
		return Identity{}, ErrInvalid
	}
	// Google Sign-In uses RS256, unlike the SDK's additional IAP ES256 support.
	var header struct {
		Alg string `json:"alg"`
		Kid string `json:"kid"`
	}
	raw, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil || json.Unmarshal(raw, &header) != nil || header.Alg != "RS256" || header.Kid == "" {
		return Identity{}, ErrInvalid
	}
	payloadJSON, parseErr := base64.RawURLEncoding.DecodeString(parts[1])
	var candidate *idtoken.Payload
	if parseErr != nil || json.Unmarshal(payloadJSON, &candidate) != nil || candidate == nil {
		return Identity{}, ErrInvalid
	}
	if json.Unmarshal(payloadJSON, &candidate.Claims) != nil {
		return Identity{}, ErrInvalid
	}
	if _, claimErr := googleIdentity(candidate, g.audience, time.Now()); claimErr != nil {
		return Identity{}, ErrInvalid
	}
	p, err := g.validator.Validate(ctx, token, g.audience)
	if err != nil {
		if errors.Is(err, ErrUnavailable) || ctx.Err() != nil {
			return Identity{}, ErrUnavailable
		}
		return Identity{}, ErrInvalid
	}
	return googleIdentity(p, g.audience, time.Now())
}
func googleIdentity(p *idtoken.Payload, audience string, now time.Time) (Identity, error) {
	if p == nil || audience == "" || p.Audience != audience || (p.Issuer != "https://accounts.google.com" && p.Issuer != "accounts.google.com") || p.Subject == "" || len(p.Subject) > 255 || p.Expires <= now.Unix() || p.IssuedAt <= 0 || p.IssuedAt > now.Add(time.Minute).Unix() || p.IssuedAt >= p.Expires {
		return Identity{}, ErrInvalid
	}
	email, _ := p.Claims["email"].(string)
	verified, _ := p.Claims["email_verified"].(bool)
	name, _ := p.Claims["name"].(string)
	if !verified || email == "" || len(email) > 320 || len(name) > 512 {
		return Identity{}, ErrInvalid
	}
	return Identity{Issuer: "https://accounts.google.com", Subject: p.Subject, Name: name, Email: email}, nil
}
