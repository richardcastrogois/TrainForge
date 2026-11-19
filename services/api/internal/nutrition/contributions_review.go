package nutrition

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Moderation is reachable only through an explicit local maintainer command.
// The API runtime has no UPDATE grant and exposes no promotion endpoint.
type ContributionReview struct {
	Contribution Contribution `json:"contribution"`
	Fingerprint  string       `json:"fingerprint"`
}

func contributionFingerprint(c Contribution) string {
	raw, _ := json.Marshal(c)
	return hex.EncodeToString(digest(raw))
}
func maintainer(ctx context.Context, pool *pgxpool.Pool) error {
	if pool == nil {
		return ErrFoodUnavailable
	}
	var role string
	if pool.QueryRow(ctx, "SELECT current_user").Scan(&role) != nil || role != "trainforge_migrator" {
		return errors.New("maintainer credential required; connection details withheld")
	}
	return nil
}
func ReviewFoodContribution(ctx context.Context, pool *pgxpool.Pool, id string) (ContributionReview, error) {
	if !contributionIDValid(id) {
		return ContributionReview{}, ErrFoodQuery
	}
	if e := maintainer(ctx, pool); e != nil {
		return ContributionReview{}, e
	}
	tx, e := pool.Begin(ctx)
	if e != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	var user string
	if e = tx.QueryRow(ctx, "SELECT user_id::text FROM trainforge_v1.food_contributions WHERE id=$1", id).Scan(&user); errors.Is(e, pgx.ErrNoRows) {
		return ContributionReview{}, ErrFoodMissing
	} else if e != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	c, e := readContribution(ctx, tx, user, id)
	if e != nil {
		return ContributionReview{}, e
	}
	if tx.Commit(ctx) != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	return ContributionReview{c, contributionFingerprint(c)}, nil
}
func DecideFoodContribution(ctx context.Context, pool *pgxpool.Pool, id, decision, fingerprint, note string) (ContributionReview, error) {
	if !contributionIDValid(id) || (decision != "approved" && decision != "rejected") || !shaPattern.MatchString(fingerprint) || !textValid(note, 1, 1000) {
		return ContributionReview{}, ErrFoodQuery
	}
	if e := maintainer(ctx, pool); e != nil {
		return ContributionReview{}, e
	}
	tx, e := pool.Begin(ctx)
	if e != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	// Lock the account first, matching uploads, withdrawal and account erasure.
	var user string
	e = tx.QueryRow(ctx, `SELECT c.user_id::text FROM trainforge_v1.food_contributions c JOIN trainforge_v1.users u ON u.id=c.user_id WHERE c.id=$1 FOR UPDATE OF u`, id).Scan(&user)
	if errors.Is(e, pgx.ErrNoRows) {
		return ContributionReview{}, ErrFoodMissing
	}
	if e != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	c, e := readContribution(ctx, tx, user, id)
	if e != nil {
		return ContributionReview{}, e
	}
	if c.Status != "submitted" || contributionFingerprint(c) != fingerprint {
		return ContributionReview{}, ErrEntryConflict
	}
	if _, e = tx.Exec(ctx, `UPDATE trainforge_v1.food_contributions SET status=$2,review_note=$3,reviewed_at=clock_timestamp(),updated_at=clock_timestamp() WHERE id=$1`, id, decision, note); e != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	c, e = readContribution(ctx, tx, user, id)
	if e != nil {
		return ContributionReview{}, e
	}
	if tx.Commit(ctx) != nil {
		return ContributionReview{}, ErrFoodUnavailable
	}
	return ContributionReview{c, contributionFingerprint(c)}, nil
}
func ListFoodContributionsForReview(ctx context.Context, pool *pgxpool.Pool, after string, limit int) ([]ContributionReview, error) {
	if (after != "" && !contributionIDValid(after)) || limit < 1 || limit > 100 {
		return nil, ErrFoodQuery
	}
	if e := maintainer(ctx, pool); e != nil {
		return nil, e
	}
	if after == "" {
		after = "00000000-0000-0000-0000-000000000000"
	}
	rows, e := pool.Query(ctx, "SELECT "+contributionProjection+" FROM trainforge_v1.food_contributions c WHERE c.status='submitted' AND c.id>$1::uuid ORDER BY c.id LIMIT $2", after, limit)
	if e != nil {
		return nil, ErrFoodUnavailable
	}
	defer rows.Close()
	result := []ContributionReview{}
	for rows.Next() {
		var raw []byte
		var c Contribution
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &c) != nil {
			return nil, ErrFoodUnavailable
		}
		result = append(result, ContributionReview{c, contributionFingerprint(c)})
	}
	if rows.Err() != nil {
		return nil, ErrFoodUnavailable
	}
	return result, nil
}

// Export contains no account IDs, sender information, operation IDs, or photos.
// Approval is editorial review; the catalog importer still validates publication.
func ExportApprovedContributions(ctx context.Context, pool *pgxpool.Pool, out io.Writer) error {
	if e := maintainer(ctx, pool); e != nil {
		return e
	}
	rows, e := pool.Query(ctx, `SELECT id::text,food,consent,reviewed_at FROM trainforge_v1.food_contributions WHERE status='approved' ORDER BY id`)
	if e != nil {
		return ErrFoodUnavailable
	}
	defer rows.Close()
	encoder := json.NewEncoder(out)
	for rows.Next() {
		var id string
		var food, consent json.RawMessage
		var reviewed time.Time
		if rows.Scan(&id, &food, &consent, &reviewed) != nil {
			return ErrFoodUnavailable
		}
		if e = encoder.Encode(map[string]any{"contract": "trainforge.food-contribution-export/1", "sourceId": "TF-COMMUNITY-1", "sourceFoodId": id, "food": food, "consent": consent, "reviewedAt": reviewed.UTC().Format(time.RFC3339Nano)}); e != nil {
			return e
		}
	}
	if rows.Err() != nil {
		return ErrFoodUnavailable
	}
	return nil
}

// ReviewContributionMedia is for explicit local inspection only. The bytes are
// never included in list/show/export-approved or application logs.
func ReviewContributionMedia(ctx context.Context, pool *pgxpool.Pool, id, mediaID string) ([]byte, error) {
	if !contributionIDValid(id) || !contributionIDValid(mediaID) {
		return nil, ErrFoodQuery
	}
	if e := maintainer(ctx, pool); e != nil {
		return nil, e
	}
	var raw []byte
	e := pool.QueryRow(ctx, `SELECT m.content FROM trainforge_v1.food_contribution_media m JOIN trainforge_v1.food_contributions c ON c.id=m.contribution_id WHERE c.id=$1 AND m.id=$2`, id, mediaID).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return nil, ErrFoodMissing
	}
	if e != nil {
		return nil, ErrFoodUnavailable
	}
	return raw, nil
}
