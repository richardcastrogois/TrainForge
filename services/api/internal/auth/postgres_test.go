package auth

import (
	"context"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"strings"
	"sync"
	"testing"
	"time"
)

func TestPostgresIsolatedSessionLifecycle(t *testing.T) {
	dsn := os.Getenv("TF_AUTH_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("requires disposable auth test database; not a real Google login")
	}
	ctx := context.Background()
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil || !strings.HasPrefix(cfg.ConnConfig.Database, "trainforge_v1_auth_test_") {
		t.Fatal("refusing non-disposable database")
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		t.Fatal("test connection failed")
	}
	defer pool.Close()
	repo := Postgres{Pool: pool}
	identity := Identity{Issuer: "https://accounts.google.com", Subject: "isolated-fixture-only", Name: "Isolated fixture", Email: "fixture@example.invalid"}
	// Concurrent duplicate identity must converge without linking another subject by email.
	const n = 8
	ids := make(chan string, n)
	errs := make(chan error, n)
	var wg sync.WaitGroup
	for j := 0; j < n; j++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c, _ := credentials()
			u, e := repo.Login(ctx, identity, c)
			ids <- u.ID
			errs <- e
		}()
	}
	wg.Wait()
	close(ids)
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("concurrent login failed")
		}
	}
	var id string
	for v := range ids {
		if id != "" && id != v {
			t.Fatal("duplicate identity")
		}
		id = v
	}
	other := identity
	other.Subject = "different-subject"
	otherCred, _ := credentials()
	otherUser, e := repo.Login(ctx, other, otherCred)
	if e != nil || otherUser.ID == id {
		t.Fatal("email linked accounts")
	}
	first, _ := credentials()
	u, e := repo.Login(ctx, identity, first)
	if e != nil || u.ID != id {
		t.Fatal("identity changed")
	}
	second, _ := credentials()
	if _, e = repo.Login(ctx, identity, second); e != nil {
		t.Fatal("second device failed")
	}
	if _, e = repo.Authenticate(ctx, hash(first.Access)); e != nil {
		t.Fatal("access rejected")
	}
	if _, e = repo.Authenticate(ctx, hash(first.Refresh)); e != ErrInvalid {
		t.Fatal("refresh used as access")
	}
	winner := make(chan Credentials, 2)
	rotatedErrors := make(chan error, 2)
	for j := 0; j < 2; j++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c, _ := credentials()
			_, e := repo.Rotate(ctx, hash(first.Refresh), c)
			if e == nil {
				winner <- c
			}
			rotatedErrors <- e
		}()
	}
	wg.Wait()
	close(winner)
	close(rotatedErrors)
	var wins, invalid int
	for e := range rotatedErrors {
		if e == nil {
			wins++
		} else if e == ErrInvalid {
			invalid++
		} else {
			t.Fatal("rotation unavailable")
		}
	}
	if wins != 1 || invalid != 1 {
		t.Fatal("rotation was not single use")
	}
	for c := range winner {
		if _, e = repo.Authenticate(ctx, hash(c.Access)); e != ErrInvalid {
			t.Fatal("replayed family stayed active")
		}
		if _, e = repo.Rotate(ctx, hash(c.Refresh), Credentials{}); e != ErrInvalid {
			t.Fatal("new refresh survived family revocation")
		}
	}
	if _, e = repo.Authenticate(ctx, hash(second.Access)); e != nil {
		t.Fatal("other device revoked")
	}
	if e = repo.Revoke(ctx, hash(second.Refresh)); e != nil {
		t.Fatal("logout failed")
	}
	if e = repo.Revoke(ctx, hash(second.Refresh)); e != nil {
		t.Fatal("logout not idempotent")
	}
	if _, e = repo.Authenticate(ctx, hash(second.Access)); e != ErrInvalid {
		t.Fatal("logout did not invalidate access")
	}
	expiring, _ := credentials()
	_, e = repo.Login(ctx, identity, expiring)
	if e != nil {
		t.Fatal("expiry login failed")
	}
	if _, e = pool.Exec(ctx, "UPDATE trainforge_v1.access_tokens SET expires_at=$1 WHERE token_hash=$2", time.Now().Add(-time.Second), hash(expiring.Access)); e != nil {
		t.Fatal("expiry setup failed")
	}
	if _, e = repo.Authenticate(ctx, hash(expiring.Access)); e != ErrInvalid {
		t.Fatal("expired access accepted")
	}
	if _, e = pool.Exec(ctx, "UPDATE trainforge_v1.refresh_tokens SET expires_at=$1 WHERE token_hash=$2", time.Now().Add(-time.Second), hash(expiring.Refresh)); e != nil {
		t.Fatal("refresh expiry setup failed")
	}
	next, _ := credentials()
	if _, e = repo.Rotate(ctx, hash(expiring.Refresh), next); e != ErrInvalid {
		t.Fatal("expired refresh accepted")
	}
	// No raw token columns, and digests have the expected length.
	var count int
	err = pool.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.access_tokens WHERE octet_length(token_hash)<>32").Scan(&count)
	if err != nil || count != 0 {
		t.Fatal("invalid stored hashes")
	}
	// Sequential refresh preserves a fixed maximum lifetime from original login.
	original, _ := credentials()
	_, e = repo.Login(ctx, identity, original)
	if e != nil {
		t.Fatal("sequential login")
	}
	rotated, _ := credentials()
	if _, e = repo.Rotate(ctx, hash(original.Refresh), rotated); e != nil {
		t.Fatal("sequential rotation")
	}
	var oldExpiry, newExpiry time.Time
	if e = pool.QueryRow(ctx, "SELECT expires_at FROM trainforge_v1.refresh_tokens WHERE token_hash=$1", hash(original.Refresh)).Scan(&oldExpiry); e != nil {
		t.Fatal("old expiry")
	}
	if e = pool.QueryRow(ctx, "SELECT expires_at FROM trainforge_v1.refresh_tokens WHERE token_hash=$1", hash(rotated.Refresh)).Scan(&newExpiry); e != nil || !oldExpiry.Equal(newExpiry) {
		t.Fatal("refresh extended maximum lifetime")
	}
}
