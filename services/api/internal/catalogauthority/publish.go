package catalogauthority

import (
	"context"
	"encoding/json"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Command struct {
	ExpectedRevision int64    `json:"expectedRevision"`
	ExpectedDigest   string   `json:"expectedDigest"`
	PackageDigest    string   `json:"packageDigest"`
	Snapshot         Snapshot `json:"snapshot"`
}

// Publish is an operator-only SQL boundary. A digest proves package identity, never human rights review.
func Publish(ctx context.Context, pool *pgxpool.Pool, c Command) (Head, error) {
	body, e := Canonical(c.Snapshot)
	if e != nil || c.ExpectedRevision < 0 || c.ExpectedRevision > 2147483646 || c.PackageDigest != Hash(body) || (c.ExpectedRevision == 0 && c.ExpectedDigest != "") || (c.ExpectedRevision > 0 && !digestPattern.MatchString(c.ExpectedDigest)) {
		return Head{}, ErrPackage
	}
	if pool == nil {
		return Head{}, ErrUnavailable
	}
	tx, e := pool.Begin(ctx)
	if e != nil {
		return Head{}, ErrUnavailable
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, `SELECT pg_advisory_xact_lock($1)`, ProjectionLock); e != nil {
		return Head{}, ErrUnavailable
	}
	h, e := Current(ctx, tx)
	if e != nil {
		var n int
		if tx.QueryRow(ctx, `SELECT count(*) FROM trainforge_v1.catalog_releases`).Scan(&n) != nil || n != 0 {
			return Head{}, ErrUnavailable
		}
		h = Head{Contract: Contract}
	}
	if h.Revision == c.ExpectedRevision+1 && h.Digest == c.PackageDigest && h.PreviousDigest == c.ExpectedDigest && h.PackageDigest == c.PackageDigest {
		if tx.Commit(ctx) != nil {
			return Head{}, ErrUnavailable
		}
		return h, nil
	}
	if h.Revision != c.ExpectedRevision || h.Digest != c.ExpectedDigest {
		return Head{}, ErrConflict
	}
	old, _, e := Read(ctx, tx)
	if e != nil {
		return Head{}, e
	}
	if !Extends(old, c.Snapshot) {
		return Head{}, ErrConflict
	}
	groups := []struct {
		data  any
		query string
	}{
		{c.Snapshot.Sources, `INSERT INTO trainforge_v1.sources SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.sources,$1::jsonb) ON CONFLICT DO NOTHING`},
		{c.Snapshot.Versions, `INSERT INTO trainforge_v1.content_versions SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.content_versions,$1::jsonb) ON CONFLICT DO NOTHING`},
		{c.Snapshot.Withdrawals, `INSERT INTO trainforge_v1.content_withdrawals SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.content_withdrawals,$1::jsonb) ON CONFLICT DO NOTHING`},
	}
	for _, g := range groups {
		raw, _ := json.Marshal(g.data)
		if _, e = tx.Exec(ctx, g.query, raw); e != nil {
			return Head{}, ErrPackage
		}
	}
	_, digest, e := Read(ctx, tx)
	if e != nil || digest != c.PackageDigest {
		return Head{}, ErrPackage
	}
	h = Head{Contract: Contract, Revision: c.ExpectedRevision + 1, Digest: digest, PreviousDigest: c.ExpectedDigest, PackageDigest: c.PackageDigest}
	if _, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.catalog_releases(revision,digest,previous_digest,package_digest) VALUES($1,$2,$3,$4)`, h.Revision, h.Digest, h.PreviousDigest, h.PackageDigest); e != nil {
		return Head{}, ErrUnavailable
	}
	if tx.Commit(ctx) != nil {
		return Head{}, ErrUnavailable
	}
	return h, nil
}

// ApplyProjection is called only by an operator holding the existing core migrator credential.
// It cannot promote practice: it copies the exact committed package and rejects history removal.
func ApplyProjection(ctx context.Context, tx pgx.Tx, s Snapshot, want string) error {
	raw, e := Canonical(s)
	if e != nil || Hash(raw) != want {
		return ErrPackage
	}
	if _, e = tx.Exec(ctx, `SELECT pg_advisory_xact_lock($1)`, ProjectionLock); e != nil {
		return ErrUnavailable
	}
	old, _, e := Read(ctx, tx)
	if e != nil {
		return e
	}
	if !Extends(old, s) {
		return ErrConflict
	}
	for _, g := range []struct {
		data  any
		query string
	}{
		{s.Sources, `INSERT INTO trainforge_v1.sources SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.sources,$1::jsonb) ON CONFLICT DO NOTHING`},
		{s.Versions, `INSERT INTO trainforge_v1.content_versions SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.content_versions,$1::jsonb) ON CONFLICT DO NOTHING`},
		{s.Withdrawals, `INSERT INTO trainforge_v1.content_withdrawals SELECT * FROM jsonb_populate_recordset(NULL::trainforge_v1.content_withdrawals,$1::jsonb) ON CONFLICT DO NOTHING`},
	} {
		b, _ := json.Marshal(g.data)
		if _, e = tx.Exec(ctx, g.query, b); e != nil {
			return ErrPackage
		}
	}
	_, got, e := Read(ctx, tx)
	if e != nil || got != want {
		return ErrConflict
	}
	return nil
}
