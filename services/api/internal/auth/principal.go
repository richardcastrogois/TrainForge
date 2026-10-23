package auth

import (
	"context"
	"time"
)

type Principal struct {
	User       User
	FamilyID   string
	LoginAt    time.Time
	AccessHash []byte
}
type Authorizer interface {
	Authorize(context.Context, []byte) (Principal, error)
}

func (s Service) Authorize(ctx context.Context, token string) (Principal, error) {
	if s.Repository == nil {
		return Principal{}, ErrUnavailable
	}
	if !validToken(token, "tfv1_a_") {
		return Principal{}, ErrInvalid
	}
	repository, ok := s.Repository.(Authorizer)
	if !ok {
		return Principal{}, ErrUnavailable
	}
	return repository.Authorize(ctx, hash(token))
}
