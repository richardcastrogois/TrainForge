// Package legal records which Terms of Use, Privacy Policy and health-data
// consent versions an account accepted. Records are append-only evidence.
package legal

import (
	"context"
	"errors"
	"regexp"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrInvalid     = errors.New("invalid consent")
	ErrUnavailable = errors.New("consent storage unavailable")
	versionPattern = regexp.MustCompile(`^[0-9]{1,3}[.][0-9]{1,3}$`)
	shaPattern     = regexp.MustCompile(`^[a-f0-9]{64}$`)
)

// Consent is one decision as sent by the app and as returned to it.
type Consent struct {
	Document         string    `json:"document" enums:"terms,privacy,health_data"`
	Version          string    `json:"version" example:"1.0"`
	DocumentSHA      *string   `json:"documentSha,omitempty"`
	Decision         string    `json:"decision" enums:"accepted,granted,revoked"`
	AppVersion       string    `json:"appVersion" example:"0.5.1+31"`
	Locale           string    `json:"locale" example:"pt-BR"`
	ClientRecordedAt time.Time `json:"clientRecordedAt"`
	RecordedAt       time.Time `json:"recordedAt,omitempty"`
}

type RecordRequest struct {
	Items []Consent `json:"items"`
}

type Current struct {
	Items []Consent `json:"items"`
}

// Validate rejects malformed or contradictory decisions before any write.
func (c Consent) Validate(now time.Time) error {
	health := c.Document == "health_data"
	switch {
	case c.Document != "terms" && c.Document != "privacy" && !health,
		!versionPattern.MatchString(c.Version),
		health && c.Decision != "granted" && c.Decision != "revoked",
		!health && c.Decision != "accepted",
		health && c.DocumentSHA != nil,
		!health && (c.DocumentSHA == nil || !shaPattern.MatchString(*c.DocumentSHA)),
		len(c.AppVersion) < 1 || len(c.AppVersion) > 32 || strings.ContainsAny(c.AppVersion, "\r\n\t"),
		len(c.Locale) < 2 || len(c.Locale) > 16 || strings.ContainsAny(c.Locale, " \r\n\t"),
		c.ClientRecordedAt.IsZero() || c.ClientRecordedAt.After(now.Add(24*time.Hour)) || c.ClientRecordedAt.Before(now.AddDate(-2, 0, 0)):
		return ErrInvalid
	}
	return nil
}

type Repository interface {
	Record(ctx context.Context, userID string, items []Consent) error
	Current(ctx context.Context, userID string) ([]Consent, error)
}

type Postgres struct{ Pool *pgxpool.Pool }

func (p Postgres) Record(ctx context.Context, userID string, items []Consent) error {
	if p.Pool == nil {
		return ErrUnavailable
	}
	tx, err := p.Pool.Begin(ctx)
	if err != nil {
		return ErrUnavailable
	}
	defer tx.Rollback(ctx)
	for _, c := range items {
		if _, err = tx.Exec(ctx, `INSERT INTO trainforge_v1.legal_consents(user_id,document,version,document_sha,decision,app_version,locale,client_recorded_at)
VALUES($1,$2,$3,$4,$5,$6,$7,$8)`, userID, c.Document, c.Version, c.DocumentSHA, c.Decision, c.AppVersion, c.Locale, c.ClientRecordedAt); err != nil {
			return ErrUnavailable
		}
	}
	if tx.Commit(ctx) != nil {
		return ErrUnavailable
	}
	return nil
}

// Current returns the latest decision per document for the account.
func (p Postgres) Current(ctx context.Context, userID string) ([]Consent, error) {
	if p.Pool == nil {
		return nil, ErrUnavailable
	}
	rows, err := p.Pool.Query(ctx, `SELECT DISTINCT ON (document) document,version,document_sha,decision,app_version,locale,client_recorded_at,recorded_at
FROM trainforge_v1.legal_consents WHERE user_id=$1 ORDER BY document, recorded_at DESC, id DESC`, userID)
	if err != nil {
		return nil, ErrUnavailable
	}
	defer rows.Close()
	result := []Consent{}
	for rows.Next() {
		var c Consent
		if rows.Scan(&c.Document, &c.Version, &c.DocumentSHA, &c.Decision, &c.AppVersion, &c.Locale, &c.ClientRecordedAt, &c.RecordedAt) != nil {
			return nil, ErrUnavailable
		}
		result = append(result, c)
	}
	if rows.Err() != nil {
		return nil, ErrUnavailable
	}
	return result, nil
}
