package auth

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"time"
)

type Postgres struct{ Pool *pgxpool.Pool }

func uuid() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		panic("random unavailable")
	}
	b[6] = b[6]&15 | 64
	b[8] = b[8]&63 | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[:4], b[4:6], b[6:8], b[8:10], b[10:])
}
func (p Postgres) Login(ctx context.Context, i Identity, c Credentials) (User, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return User{}, ErrUnavailable
	}
	defer tx.Rollback(ctx)
	var u User
	err = tx.QueryRow(ctx, `INSERT INTO trainforge_v1.users(id,provider,issuer,subject,display_name,email) VALUES($1,'google',$2,$3,$4,$5)
 ON CONFLICT(provider,issuer,subject) DO UPDATE SET display_name=EXCLUDED.display_name,email=EXCLUDED.email RETURNING id::text,coalesce(display_name,''),coalesce(email,'')`, uuid(), i.Issuer, i.Subject, i.Name, i.Email).Scan(&u.ID, &u.Name, &u.Email)
	if err != nil {
		return User{}, ErrUnavailable
	}
	family := uuid()
	if _, err = tx.Exec(ctx, `INSERT INTO trainforge_v1.auth_families(id,user_id) VALUES($1,$2)`, family, u.ID); err != nil {
		return User{}, ErrUnavailable
	}
	if err = insertCredentials(ctx, tx, family, c, time.Now().Add(RefreshTTL)); err != nil {
		return User{}, ErrUnavailable
	}
	if tx.Commit(ctx) != nil {
		return User{}, ErrUnavailable
	}
	return u, nil
}
func insertCredentials(ctx context.Context, tx pgx.Tx, family string, c Credentials, expiry time.Time) error {
	if _, err := tx.Exec(ctx, `INSERT INTO trainforge_v1.refresh_tokens(token_hash,family_id,expires_at) VALUES($1,$2,$3)`, c.RefreshHash, family, expiry); err != nil {
		return err
	}
	_, err := tx.Exec(ctx, `INSERT INTO trainforge_v1.access_tokens(token_hash,family_id,expires_at) VALUES($1,$2,$3)`, c.AccessHash, family, time.Now().Add(AccessTTL))
	return err
}
func (p Postgres) Authenticate(ctx context.Context, h []byte) (User, error) {
	var u User
	err := p.Pool.QueryRow(ctx, `SELECT u.id::text,coalesce(u.display_name,''),coalesce(u.email,'') FROM trainforge_v1.access_tokens a JOIN trainforge_v1.auth_families f ON f.id=a.family_id JOIN trainforge_v1.users u ON u.id=f.user_id WHERE a.token_hash=$1 AND a.expires_at>now() AND f.revoked_at IS NULL`, h).Scan(&u.ID, &u.Name, &u.Email)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrInvalid
	}
	if err != nil {
		return User{}, ErrUnavailable
	}
	return u, nil
}
func (p Postgres) Rotate(ctx context.Context, h []byte, c Credentials) (User, error) {
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return User{}, ErrUnavailable
	}
	defer tx.Rollback(ctx)
	var family string
	var expiry time.Time
	var consumed, revoked *time.Time
	var u User
	// All mutations lock the family, including logout. Concurrent replay revokes
	// the winner's new credentials. A lost response requires a new Google login.
	err = tx.QueryRow(ctx, `SELECT f.id::text,t.expires_at,t.consumed_at,f.revoked_at,u.id::text,coalesce(u.display_name,''),coalesce(u.email,'') FROM trainforge_v1.refresh_tokens t JOIN trainforge_v1.auth_families f ON f.id=t.family_id JOIN trainforge_v1.users u ON u.id=f.user_id WHERE t.token_hash=$1 FOR UPDATE OF f`, h).Scan(&family, &expiry, &consumed, &revoked, &u.ID, &u.Name, &u.Email)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrInvalid
	}
	if err != nil {
		return User{}, ErrUnavailable
	}
	// Re-read after locking: the first statement snapshot may precede another commit.
	if err = tx.QueryRow(ctx, `SELECT consumed_at FROM trainforge_v1.refresh_tokens WHERE token_hash=$1`, h).Scan(&consumed); err != nil {
		return User{}, ErrUnavailable
	}
	if revoked != nil {
		return User{}, ErrInvalid
	}
	if consumed != nil {
		if _, err = tx.Exec(ctx, `UPDATE trainforge_v1.auth_families SET revoked_at=now() WHERE id=$1`, family); err != nil {
			return User{}, ErrUnavailable
		}
		if tx.Commit(ctx) != nil {
			return User{}, ErrUnavailable
		}
		return User{}, ErrInvalid
	}
	if !expiry.After(time.Now()) {
		return User{}, ErrInvalid
	}
	if _, err = tx.Exec(ctx, `UPDATE trainforge_v1.refresh_tokens SET consumed_at=now() WHERE token_hash=$1`, h); err != nil {
		return User{}, ErrUnavailable
	}
	if err = insertCredentials(ctx, tx, family, c, expiry); err != nil {
		return User{}, ErrUnavailable
	}
	if tx.Commit(ctx) != nil {
		return User{}, ErrUnavailable
	}
	return u, nil
}
func (p Postgres) Revoke(ctx context.Context, h []byte) error {
	_, err := p.Pool.Exec(ctx, `UPDATE trainforge_v1.auth_families SET revoked_at=coalesce(revoked_at,now()) WHERE id=(SELECT family_id FROM trainforge_v1.refresh_tokens WHERE token_hash=$1)`, h)
	if err != nil {
		return ErrUnavailable
	}
	return nil
}
