package nutrition

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"trainforge.local/api/internal/auth"
)

const contributionProjection = `jsonb_build_object('id',c.id,'status',c.status,'food',c.food,'consent',c.consent,
 'createdAt',to_char(c.created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
 'updatedAt',to_char(c.updated_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'reviewNote',c.review_note,
 'media',coalesce((SELECT jsonb_agg(jsonb_build_object('id',m.id,'sha256',encode(m.sha256,'hex'),
 'mediaType',m.media_type,'width',m.width,'height',m.height) ORDER BY m.id)
 FROM trainforge_v1.food_contribution_media m WHERE m.contribution_id=c.id),'[]'::jsonb))`

func readContribution(ctx context.Context, tx pgx.Tx, user, id string) (Contribution, error) {
	var raw []byte
	var result Contribution
	e := tx.QueryRow(ctx, "SELECT "+contributionProjection+" FROM trainforge_v1.food_contributions c WHERE c.user_id=$1 AND c.id=$2", user, id).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return result, ErrFoodMissing
	}
	if e != nil || json.Unmarshal(raw, &result) != nil {
		return result, ErrFoodUnavailable
	}
	return result, nil
}
func (s NutritionStore) CreateContribution(ctx context.Context, p auth.Principal, in ContributionInput) (Contribution, error) {
	if in.Validate() != nil {
		return Contribution{}, ErrFoodQuery
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return Contribution{}, e
	}
	defer tx.Rollback(ctx)
	food, consent, hash := contributionCanonical(in)
	var priorHash []byte
	var id string
	e = tx.QueryRow(ctx, `SELECT id::text,request_hash FROM trainforge_v1.food_contributions WHERE user_id=$1 AND operation_id=$2`, p.User.ID, in.OperationID).Scan(&id, &priorHash)
	if e == nil {
		if !equal(hash, priorHash) {
			return Contribution{}, ErrEntryConflict
		}
	} else if errors.Is(e, pgx.ErrNoRows) {
		id = newID()
		if _, e = tx.Exec(ctx, `SELECT trainforge_v1.food_contribution_save($1,$2,$3,$4,$5,$6,$7,$8)`, p.User.ID, p.FamilyID, p.AccessHash, id, in.OperationID, hash, food, consent); e != nil {
			return Contribution{}, mealDatabaseError(e)
		}
	} else {
		return Contribution{}, ErrFoodUnavailable
	}
	result, e := readContribution(ctx, tx, p.User.ID, id)
	if e != nil {
		return result, e
	}
	if tx.Commit(ctx) != nil {
		return Contribution{}, ErrFoodUnavailable
	}
	return result, nil
}
func (s NutritionStore) Contribution(ctx context.Context, p auth.Principal, id string) (Contribution, error) {
	if !contributionIDValid(id) {
		return Contribution{}, ErrFoodQuery
	}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return Contribution{}, e
	}
	defer tx.Rollback(ctx)
	result, e := readContribution(ctx, tx, p.User.ID, id)
	if e != nil {
		return result, e
	}
	if tx.Commit(ctx) != nil {
		return Contribution{}, ErrFoodUnavailable
	}
	return result, nil
}
func (s NutritionStore) Contributions(ctx context.Context, p auth.Principal, cursor string, limit int) (ContributionPage, error) {
	result := ContributionPage{Items: []Contribution{}}
	if limit < 1 || limit > 100 {
		return result, ErrFoodQuery
	}
	after := "00000000-0000-0000-0000-000000000000"
	if cursor != "" {
		if len(cursor) > 160 {
			return result, ErrFoodQuery
		}
		raw, e := base64.RawURLEncoding.DecodeString(cursor)
		parts := strings.Split(string(raw), ":")
		if e != nil || len(parts) != 2 || parts[0] != p.User.ID || !uuidPattern.MatchString(parts[1]) {
			return result, ErrFoodQuery
		}
		after = parts[1]
	}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return result, e
	}
	defer tx.Rollback(ctx)
	rows, e := tx.Query(ctx, "SELECT "+contributionProjection+" FROM trainforge_v1.food_contributions c WHERE c.user_id=$1 AND c.id>$2::uuid ORDER BY c.id LIMIT $3", p.User.ID, after, limit+1)
	if e != nil {
		return result, ErrFoodUnavailable
	}
	for rows.Next() {
		var raw []byte
		var c Contribution
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &c) != nil {
			rows.Close()
			return result, ErrFoodUnavailable
		}
		result.Items = append(result.Items, c)
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return result, ErrFoodUnavailable
	}
	if len(result.Items) > limit {
		result.Items = result.Items[:limit]
		next := base64.RawURLEncoding.EncodeToString([]byte(p.User.ID + ":" + result.Items[limit-1].ID))
		result.NextCursor = &next
	}
	return result, nil
}
func (s NutritionStore) WithdrawContribution(ctx context.Context, p auth.Principal, id string) (Contribution, error) {
	if !contributionIDValid(id) {
		return Contribution{}, ErrFoodQuery
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return Contribution{}, e
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, `SELECT trainforge_v1.food_contribution_withdraw($1,$2,$3,$4)`, p.User.ID, p.FamilyID, p.AccessHash, id); e != nil {
		return Contribution{}, mealDatabaseError(e)
	}
	result, e := readContribution(ctx, tx, p.User.ID, id)
	if e != nil {
		return result, e
	}
	if tx.Commit(ctx) != nil {
		return Contribution{}, ErrFoodUnavailable
	}
	return result, nil
}
func (s NutritionStore) AttachContributionMedia(ctx context.Context, p auth.Principal, id string, raw []byte, mediaType string) (Contribution, error) {
	if !contributionIDValid(id) {
		return Contribution{}, ErrFoodQuery
	}
	clean, width, height, e := sanitizeContributionImage(raw, mediaType)
	if e != nil {
		return Contribution{}, e
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return Contribution{}, e
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, `SELECT trainforge_v1.food_contribution_attach($1,$2,$3,$4,$5,$6,$7,$8,$9)`, p.User.ID, p.FamilyID, p.AccessHash, id, newID(), digest(clean), clean, width, height); e != nil {
		return Contribution{}, mealDatabaseError(e)
	}
	result, e := readContribution(ctx, tx, p.User.ID, id)
	if e != nil {
		return result, e
	}
	if tx.Commit(ctx) != nil {
		return Contribution{}, ErrFoodUnavailable
	}
	return result, nil
}
func (s NutritionStore) ContributionMedia(ctx context.Context, p auth.Principal, id, mediaID string) ([]byte, error) {
	if !contributionIDValid(id) || !contributionIDValid(mediaID) {
		return nil, ErrFoodQuery
	}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return nil, e
	}
	defer tx.Rollback(ctx)
	var raw []byte
	e = tx.QueryRow(ctx, `SELECT content FROM trainforge_v1.food_contribution_media WHERE user_id=$1 AND contribution_id=$2 AND id=$3`, p.User.ID, id, mediaID).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return nil, ErrFoodMissing
	}
	if e != nil || tx.Commit(ctx) != nil {
		return nil, ErrFoodUnavailable
	}
	return raw, nil
}
