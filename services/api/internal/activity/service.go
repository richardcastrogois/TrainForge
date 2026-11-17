package activity

import (
	"context"
	"errors"
	"time"
	"trainforge.local/api/internal/auth"
)

var (
	ErrUnavailable         = errors.New("activity unavailable")
	ErrMissing             = errors.New("activity not found")
	ErrPracticeUnavailable = errors.New("approved activity practice unavailable")
)

const PrescriptionContract = "trainforge.activity-prescription/1"

type StartRequest struct {
	OccurrenceID string `json:"occurrenceId"`
}
type CommandInput struct {
	ExpectedRevision int    `json:"expectedRevision"`
	Action           string `json:"action"`
	Confirmed        bool   `json:"confirmed"`
	Set              *Set   `json:"set"`
}

func (c CommandInput) valid() bool {
	if c.ExpectedRevision < 1 || c.ExpectedRevision > maxCommands+2 {
		return false
	}
	terminal := c.Action == "partial" || c.Action == "complete" || c.Action == "cancel"
	if terminal != c.Confirmed {
		return false
	}
	switch c.Action {
	case "record_set":
		return c.Set != nil
	case "pause", "resume", "partial", "complete", "cancel":
		return c.Set == nil
	}
	return false
}

type MovementLabel struct {
	ID        string `json:"id"`
	VersionID string `json:"versionId"`
	Title     string `json:"title"`
}
type Detail struct {
	Snapshot          Snapshot        `json:"snapshot"`
	Title             string          `json:"title"`
	MovementLabels    []MovementLabel `json:"movementLabels"`
	PracticeAvailable bool            `json:"practiceAvailable"`
}
type Upcoming struct {
	ID                string    `json:"id"`
	PlannedFor        time.Time `json:"plannedFor"`
	Timezone          string    `json:"timezone"`
	Source            Source    `json:"source"`
	Title             string    `json:"title"`
	PracticeAvailable bool      `json:"practiceAvailable"`
}
type Feed struct {
	Upcoming []Upcoming `json:"upcoming"`
	Sessions []Detail   `json:"sessions"`
	Complete bool       `json:"complete"`
}
type MutationResult struct {
	Detail
	AppliedRevision int  `json:"appliedRevision"`
	Replayed        bool `json:"replayed"`
}
type Repository interface {
	Feed(context.Context, auth.Principal) (Feed, error)
	Detail(context.Context, auth.Principal, string) (Detail, error)
	Start(context.Context, auth.Principal, StartRequest, string) (MutationResult, error)
	Command(context.Context, auth.Principal, string, CommandInput, string) (MutationResult, error)
}
