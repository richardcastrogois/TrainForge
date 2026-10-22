package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"time"
)

const AccessTTL = 15 * time.Minute
const RefreshTTL = 30 * 24 * time.Hour

type User struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Email string  `json:"email"`
	Image *string `json:"image"`
}
type Session struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	ExpiresIn    int    `json:"expiresIn"`
	User         User   `json:"user"`
}
type Credentials struct {
	Access, Refresh         string
	AccessHash, RefreshHash []byte
}
type Repository interface {
	Login(context.Context, Identity, Credentials) (User, error)
	Rotate(context.Context, []byte, Credentials) (User, error)
	Authenticate(context.Context, []byte) (User, error)
	Revoke(context.Context, []byte) error
}
type Service struct {
	Verifier   Verifier
	Repository Repository
}

func credentials() (Credentials, error) {
	a, err := randomToken("tfv1_a_")
	if err != nil {
		return Credentials{}, ErrUnavailable
	}
	r, err := randomToken("tfv1_r_")
	if err != nil {
		return Credentials{}, ErrUnavailable
	}
	return Credentials{a, r, hash(a), hash(r)}, nil
}
func randomToken(prefix string) (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return prefix + base64.RawURLEncoding.EncodeToString(b), nil
}
func hash(token string) []byte { sum := sha256.Sum256([]byte(token)); return sum[:] }
func validToken(token, prefix string) bool {
	if len(token) != len(prefix)+43 || token[:len(prefix)] != prefix {
		return false
	}
	b, err := base64.RawURLEncoding.DecodeString(token[len(prefix):])
	return err == nil && len(b) == 32
}
func session(c Credentials, u User) Session {
	return Session{c.Access, c.Refresh, int(AccessTTL.Seconds()), u}
}
func (s Service) Login(ctx context.Context, token string) (Session, error) {
	if s.Verifier == nil || s.Repository == nil {
		return Session{}, ErrUnavailable
	}
	i, err := s.Verifier.Verify(ctx, token)
	if err != nil {
		return Session{}, err
	}
	c, err := credentials()
	if err != nil {
		return Session{}, err
	}
	u, err := s.Repository.Login(ctx, i, c)
	if err != nil {
		return Session{}, err
	}
	return session(c, u), nil
}
func (s Service) Refresh(ctx context.Context, token string) (Session, error) {
	if s.Repository == nil {
		return Session{}, ErrUnavailable
	}
	if !validToken(token, "tfv1_r_") {
		return Session{}, ErrInvalid
	}
	c, err := credentials()
	if err != nil {
		return Session{}, err
	}
	u, err := s.Repository.Rotate(ctx, hash(token), c)
	if err != nil {
		return Session{}, err
	}
	return session(c, u), nil
}
func (s Service) Me(ctx context.Context, token string) (User, error) {
	if s.Repository == nil {
		return User{}, ErrUnavailable
	}
	if !validToken(token, "tfv1_a_") {
		return User{}, ErrInvalid
	}
	return s.Repository.Authenticate(ctx, hash(token))
}
func (s Service) Logout(ctx context.Context, token string) error {
	if s.Repository == nil {
		return ErrUnavailable
	}
	if !validToken(token, "tfv1_r_") {
		return nil
	}
	return s.Repository.Revoke(ctx, hash(token))
}
