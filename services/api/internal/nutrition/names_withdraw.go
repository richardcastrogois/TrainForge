package nutrition

import (
	"bytes"
	"context"
	"encoding/json"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"time"
	"unicode/utf8"
)

// FoodNameWithdrawal is an immutable operator decision. Its document must be
// retained with the package; a matching hash is traceability, not proof of rights.
type FoodNameWithdrawal struct {
	Contract    string `json:"contract"`
	FoodID      string `json:"foodId"`
	FoodVersion string `json:"foodVersion"`
	Locale      string `json:"locale"`
	NameVersion string `json:"nameVersion"`
	Reason      string `json:"reason"`
	ReviewerRef string `json:"reviewerRef"`
	ReviewedAt  string `json:"reviewedAt"`
	EvidenceSHA string `json:"evidenceSha256"`
}

func (w FoodNameWithdrawal) Validate(now time.Time) error {
	reviewed, err := time.Parse(time.RFC3339Nano, w.ReviewedAt)
	raw, _ := json.Marshal(w)
	if w.Contract != "trainforge.food-name-withdrawal/1" || !foodPattern.MatchString(w.FoodID) || !shaPattern.MatchString(w.FoodVersion) ||
		!foodNameLocale(w.Locale) || !shaPattern.MatchString(w.NameVersion) || !validNameText(w.Reason, 320) ||
		!validNameText(w.ReviewerRef, 160) || !shaPattern.MatchString(w.EvidenceSHA) || err != nil || reviewed.IsZero() || now.IsZero() || reviewed.After(now) || len(raw) > 1000 {
		return ErrFoodNames
	}
	return nil
}
func DecodeFoodNameWithdrawal(raw []byte, now time.Time) (FoodNameWithdrawal, error) {
	var w FoodNameWithdrawal
	if len(raw) == 0 || len(raw) > 8192 || !utf8.Valid(raw) || uniqueNameJSON(json.NewDecoder(bytes.NewReader(raw)), 0) != nil {
		return w, ErrFoodNames
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if dec.Decode(&w) != nil || dec.Decode(new(any)) != io.EOF || w.Validate(now) != nil {
		return FoodNameWithdrawal{}, ErrFoodNames
	}
	return w, nil
}

// StoreFoodNameWithdrawal appends a decision even when its source is withdrawn.
// Runtime cannot insert it. Replaying the same decision does not bump revision;
// another reason for an already withdrawn version cannot replace its history.
func StoreFoodNameWithdrawal(ctx context.Context, pool *pgxpool.Pool, w FoodNameWithdrawal, document []byte, now time.Time) (bool, error) {
	if w.Validate(now) != nil || len(document) == 0 || len(document) > 1048576 || hash(document) != w.EvidenceSHA {
		return false, ErrFoodNames
	}
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return false, ErrFoodUnavailable
	}
	defer tx.Rollback(ctx)
	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock(hashtextextended($1,20261026))", w.FoodID); err != nil {
		return false, ErrFoodUnavailable
	}
	var exists bool
	if tx.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM trainforge_v1.food_name_versions WHERE food_id=$1 AND food_version_sha=$2 AND locale=$3 AND version_sha=$4)", w.FoodID, w.FoodVersion, w.Locale, w.NameVersion).Scan(&exists) != nil {
		return false, ErrFoodUnavailable
	}
	if !exists {
		return false, ErrFoodNames
	}
	raw, _ := json.Marshal(w)
	tag, err := tx.Exec(ctx, "INSERT INTO trainforge_v1.food_name_withdrawals(food_id,food_version_sha,locale,version_sha,reason) VALUES($1,$2,$3,$4,$5) ON CONFLICT(food_id,food_version_sha,locale,version_sha) DO NOTHING", w.FoodID, w.FoodVersion, w.Locale, w.NameVersion, string(raw))
	if err != nil {
		return false, ErrFoodUnavailable
	}
	inserted := tag.RowsAffected() == 1
	if !inserted {
		var same bool
		if tx.QueryRow(ctx, "SELECT reason=$5 FROM trainforge_v1.food_name_withdrawals WHERE food_id=$1 AND food_version_sha=$2 AND locale=$3 AND version_sha=$4", w.FoodID, w.FoodVersion, w.Locale, w.NameVersion, string(raw)).Scan(&same) != nil {
			return false, ErrFoodUnavailable
		}
		if !same {
			return false, ErrFoodNames
		}
	}
	if tx.Commit(ctx) != nil {
		return false, ErrFoodUnavailable
	}
	return inserted, nil
}
