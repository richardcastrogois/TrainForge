package trainingconfig

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/auth"
)

const fixtureKey = "33333333-3333-4333-8333-333333333333"

func actor() auth.Principal {
	return auth.Principal{User: auth.User{ID: "11111111-1111-4111-8111-111111111111"}, FamilyID: "22222222-2222-4222-8222-222222222222", AccessHash: []byte(strings.Repeat("a", 32))}
}

type isolatedStore struct {
	loads, saves int
	principal    auth.Principal
	command      SaveCommand
	key          string
	result       *Snapshot
	failure      error
}

func (f *isolatedStore) Load(ctx context.Context, p auth.Principal) (*Snapshot, error) {
	f.loads++
	f.principal = p
	return f.result, f.failure
}
func (f *isolatedStore) Save(ctx context.Context, p auth.Principal, c SaveCommand, key string) (Snapshot, error) {
	f.saves++
	f.principal = p
	f.command = c
	f.key = key
	if f.failure != nil {
		return Snapshot{}, f.failure
	}
	if f.result != nil {
		return *f.result, nil
	}
	return Snapshot{Contract: Contract, Revision: c.Revision + 1, Configuration: c.Configuration, ConfirmedAt: time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)}, nil
}
func TestServiceUnconfiguredHasNoDefaultFacts(t *testing.T) {
	store := &isolatedStore{}
	got, err := (Service{store}).Load(context.Background(), actor())
	if err != nil || got != nil || store.loads != 1 || !reflect.DeepEqual(store.principal, actor()) {
		t.Fatal("unconfigured or owner context changed")
	}
}
func TestServiceValidatesBeforePersistenceAndPreservesCredential(t *testing.T) {
	store := &isolatedStore{}
	service := Service{store}
	cmd := declared()
	cmd.Reviewed = false
	if _, err := service.Save(context.Background(), actor(), cmd, fixtureKey); err == nil || store.saves != 0 {
		t.Fatal("unreviewed configuration reached store")
	}
	cmd = declared()
	if _, err := service.Save(context.Background(), actor(), cmd, "forged"); err == nil || store.saves != 0 {
		t.Fatal("invalid retry key reached store")
	}
	got, err := service.Save(context.Background(), actor(), cmd, fixtureKey)
	if err != nil || got.Revision != 1 || store.saves != 1 || store.key != fixtureKey || !reflect.DeepEqual(store.principal, actor()) || !reflect.DeepEqual(got.Configuration, cmd.Canonical().Configuration) {
		t.Fatal("valid declaration or credential not preserved")
	}
}
func TestServiceMissingOrMalformedActorFailsClosed(t *testing.T) {
	for _, bad := range []auth.Principal{{}, {User: actor().User}, {User: actor().User, FamilyID: actor().FamilyID}} {
		store := &isolatedStore{}
		service := Service{store}
		if _, err := service.Load(context.Background(), bad); !errors.Is(err, auth.ErrInvalid) || store.loads != 0 {
			t.Fatal("invalid actor read")
		}
		if _, err := service.Save(context.Background(), bad, declared(), fixtureKey); !errors.Is(err, auth.ErrInvalid) || store.saves != 0 {
			t.Fatal("invalid actor save")
		}
	}
}
func TestServiceCancellationAndUnavailableDoNotTouchPersistence(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	store := &isolatedStore{}
	s := Service{store}
	if _, err := s.Load(ctx, actor()); !errors.Is(err, context.Canceled) || store.loads != 0 {
		t.Fatal("canceled read")
	}
	if _, err := s.Save(ctx, actor(), declared(), fixtureKey); !errors.Is(err, context.Canceled) || store.saves != 0 {
		t.Fatal("canceled save")
	}
	if _, err := (Service{}).Load(context.Background(), actor()); !errors.Is(err, ErrUnavailable) {
		t.Fatal("nil load port")
	}
	if _, err := (Service{}).Save(context.Background(), actor(), declared(), fixtureKey); !errors.Is(err, ErrUnavailable) {
		t.Fatal("nil save port")
	}
}
func TestServicePreservesConflictAndRevokedCredential(t *testing.T) {
	for _, failure := range []error{ErrConflict, auth.ErrInvalid, ErrUnavailable} {
		s := Service{&isolatedStore{failure: failure}}
		if _, err := s.Load(context.Background(), actor()); !errors.Is(err, failure) {
			t.Fatal("load error changed")
		}
		if _, err := s.Save(context.Background(), actor(), declared(), fixtureKey); !errors.Is(err, failure) {
			t.Fatal("save error changed")
		}
	}
}
func TestServiceRejectsIncompleteOrSilentlyChangedStoreResponse(t *testing.T) {
	valid := Snapshot{Contract: Contract, Revision: 1, Configuration: declared().Canonical().Configuration, ConfirmedAt: time.Now().UTC()}
	for _, change := range []func(*Snapshot){func(s *Snapshot) { s.Contract = "unknown" }, func(s *Snapshot) { s.Revision = 0 }, func(s *Snapshot) { s.ConfirmedAt = time.Time{} }, func(s *Snapshot) { s.Configuration.Timezone = "Local" }} {
		bad := valid
		change(&bad)
		s := Service{&isolatedStore{result: &bad}}
		if _, err := s.Load(context.Background(), actor()); !errors.Is(err, ErrUnavailable) {
			t.Fatal("malformed stored snapshot exposed")
		}
	}
	altered := valid
	altered.Configuration.Context = "personal"
	if _, err := (Service{&isolatedStore{result: &altered}}).Save(context.Background(), actor(), declared(), fixtureKey); !errors.Is(err, ErrUnavailable) {
		t.Fatal("silently changed declaration accepted")
	}
}
