package trainingconfig

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"regexp"
	"trainforge.local/api/internal/auth"
)

var ErrUnavailable = errors.New("training configuration unavailable")
var ErrConflict = errors.New("training configuration revision or idempotency conflict")
var uuidPattern = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)

// Repository is the application persistence port; a future SQL implementation must revalidate
// the live credential, lock the owner, verify resource identities and save the immutable version
// plus its idempotent response atomically. This interface alone does not authorize any account.
type Repository interface {
	Load(context.Context, auth.Principal) (*Snapshot, error)
	Save(context.Context, auth.Principal, SaveCommand, string) (Snapshot, error)
}
type Service struct{ Repository Repository }

func actorValid(p auth.Principal) bool {
	return uuidPattern.MatchString(p.User.ID) && uuidPattern.MatchString(p.FamilyID) && len(p.AccessHash) == 32
}
func snapshotValid(s Snapshot) bool {
	return s.Contract == Contract && s.Revision > 0 && s.Revision <= 2147483647 && !s.ConfirmedAt.IsZero() && len((SaveCommand{Reviewed: true, Configuration: s.Configuration}).Validate()) == 0
}

// Load represents an unconfigured account with nil, never an invented default profile.
func (s Service) Load(ctx context.Context, p auth.Principal) (*Snapshot, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if !actorValid(p) {
		return nil, auth.ErrInvalid
	}
	if s.Repository == nil {
		return nil, ErrUnavailable
	}
	result, err := s.Repository.Load(ctx, p)
	if err != nil {
		return nil, err
	}
	if result == nil {
		return nil, nil
	}
	if !snapshotValid(*result) {
		return nil, ErrUnavailable
	}
	return result, nil
}

// Save validates declarations before touching persistence. Canonicalization keeps one stable
// request meaning across retries, while account/session authorization remains a store obligation.
func (s Service) Save(ctx context.Context, p auth.Principal, command SaveCommand, key string) (Snapshot, error) {
	if err := ctx.Err(); err != nil {
		return Snapshot{}, err
	}
	if !actorValid(p) {
		return Snapshot{}, auth.ErrInvalid
	}
	if issues := command.Validate(); len(issues) != 0 {
		return Snapshot{}, issues
	}
	if !uuidPattern.MatchString(key) {
		return Snapshot{}, FieldIssues{"idempotencyKey": "invalid_idempotency_key"}
	}
	if s.Repository == nil {
		return Snapshot{}, ErrUnavailable
	}
	canonical := command.Canonical()
	// Retain a value independent of a buggy adapter before calling that boundary.
	expected, _ := json.Marshal(canonical.Configuration)
	result, err := s.Repository.Save(ctx, p, canonical, key)
	if err != nil {
		return Snapshot{}, err
	}
	actual, _ := json.Marshal(result.Configuration)
	if !snapshotValid(result) || result.Revision != command.Revision+1 || !bytes.Equal(expected, actual) {
		return Snapshot{}, ErrUnavailable
	}
	return result, nil
}
