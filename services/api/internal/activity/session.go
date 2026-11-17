package activity

import (
	"encoding/json"
	"errors"
	"regexp"
	"time"
)

const SessionContract = "trainforge.activity-session/1"

type State string

const (
	Started   State = "started"
	Paused    State = "paused"
	Partial   State = "partial"
	Completed State = "completed"
	Cancelled State = "cancelled"
)

var (
	ErrInvalid  = errors.New("invalid activity command or prescription")
	ErrConflict = errors.New("activity revision, command identity or transition conflict")
	uuid        = regexp.MustCompile(`^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$`)
	assetID     = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9:._/-]{0,199}$`)
	version     = regexp.MustCompile(`^[a-f0-9]{64}$`)
	load        = regexp.MustCompile(`^(0|[1-9][0-9]{0,5})(\.[0-9]{1,3})?$`)
)

// These bounds protect an aggregate; they are not recommendations for exercise.
const maxSets = 1000
const maxCommands = 4096

type Source struct {
	ProgramID      string `json:"programId"`
	ProgramVersion string `json:"programVersion"`
	SessionKey     string `json:"sessionKey"`
}

type Target struct {
	Repetitions          *int   `json:"repetitions"`
	DurationMilliseconds *int64 `json:"durationMilliseconds"`
}

// Item preserves a prescription supplied by an authorized application boundary.
// This engine does not verify editorial rights, eligibility or clinical safety.
type Item struct {
	Position        int      `json:"position"`
	MovementID      string   `json:"movementId"`
	MovementVersion string   `json:"movementVersion"`
	Mode            string   `json:"mode"`
	Targets         []Target `json:"targets"`
}

type Set struct {
	Position             int     `json:"position"`
	Number               int     `json:"number"`
	Repetitions          *int    `json:"repetitions"`
	DurationMilliseconds *int64  `json:"durationMilliseconds"`
	LoadKg               *string `json:"loadKg"`
}

type Pause struct {
	StartedAt time.Time  `json:"startedAt"`
	EndedAt   *time.Time `json:"endedAt"`
}

type RecordedSet struct {
	CommandID  string    `json:"commandId"`
	RecordedAt time.Time `json:"recordedAt"`
	Set        Set       `json:"set"`
}

type Snapshot struct {
	Contract           string        `json:"contract"`
	ID                 string        `json:"id"`
	OwnerID            string        `json:"ownerId"`
	OccurrenceID       string        `json:"occurrenceId"`
	Source             Source        `json:"source"`
	State              State         `json:"state"`
	Revision           int           `json:"revision"`
	StartedAt          time.Time     `json:"startedAt"`
	LastEventAt        time.Time     `json:"lastEventAt"`
	EndedAt            *time.Time    `json:"endedAt"`
	ActiveMilliseconds int64         `json:"activeMilliseconds"`
	Items              []Item        `json:"items"`
	Sets               []RecordedSet `json:"sets"`
	Pauses             []Pause       `json:"pauses"`
}

// StartInput must be constructed from verified ownership and an approved, exact
// program/occurrence by a future persistence adapter. It is NOT an HTTP request.
type StartInput struct {
	ID           string    `json:"id"`
	OwnerID      string    `json:"ownerId"`
	OccurrenceID string    `json:"occurrenceId"`
	Source       Source    `json:"source"`
	At           time.Time `json:"at"`
	Items        []Item    `json:"items"`
}

type Command struct {
	ID               string    `json:"id"`
	ExpectedRevision int       `json:"expectedRevision"`
	Action           string    `json:"action"`
	At               time.Time `json:"at"`
	Confirmed        bool      `json:"confirmed"`
	Set              *Set      `json:"set"`
}

type Result struct {
	Snapshot        Snapshot `json:"snapshot"`
	AppliedRevision int      `json:"appliedRevision"`
	Replayed        bool     `json:"replayed"`
}

type receipt struct {
	body     string
	revision int
}

// Session is an immutable value. Snapshots and results are independent copies.
// The in-memory receipts only constrain domain behavior; durable idempotency,
// live credentials and atomic state/event/response writes remain adapter duties.
type Session struct {
	snapshot Snapshot
	receipts map[string]receipt
}

func validTime(t time.Time) bool {
	return !t.IsZero() && t.UTC().Year() >= 1900 && t.UTC().Year() <= 2100 && t.Nanosecond()%1000 == 0
}

func validTarget(t Target, mode string) bool {
	switch mode {
	case "repetitions":
		return t.Repetitions != nil && *t.Repetitions > 0 && *t.Repetitions <= 10000 && t.DurationMilliseconds == nil
	case "duration":
		return t.DurationMilliseconds != nil && *t.DurationMilliseconds > 0 && *t.DurationMilliseconds <= 86400000 && t.Repetitions == nil
	}
	return false
}

func clone[T any](v T) T {
	// All aggregate fields are concrete JSON-safe values, never arbitrary payloads.
	raw, _ := json.Marshal(v)
	var result T
	_ = json.Unmarshal(raw, &result)
	return result
}

func Start(in StartInput) (Session, error) {
	if !uuid.MatchString(in.ID) || !uuid.MatchString(in.OwnerID) || !uuid.MatchString(in.OccurrenceID) || !validTime(in.At) || !assetID.MatchString(in.Source.ProgramID) || !version.MatchString(in.Source.ProgramVersion) || !assetID.MatchString(in.Source.SessionKey) || len(in.Items) == 0 || len(in.Items) > 100 {
		return Session{}, ErrInvalid
	}
	seen, total := map[int]bool{}, 0
	for _, item := range in.Items {
		if item.Position < 0 || item.Position > 10000 || seen[item.Position] || !assetID.MatchString(item.MovementID) || !version.MatchString(item.MovementVersion) || len(item.Targets) == 0 || len(item.Targets) > maxSets {
			return Session{}, ErrInvalid
		}
		seen[item.Position] = true
		total += len(item.Targets)
		if total > maxSets {
			return Session{}, ErrInvalid
		}
		for _, target := range item.Targets {
			if !validTarget(target, item.Mode) {
				return Session{}, ErrInvalid
			}
		}
	}
	at := in.At.UTC()
	view := Snapshot{Contract: SessionContract, ID: in.ID, OwnerID: in.OwnerID, OccurrenceID: in.OccurrenceID, Source: in.Source, State: Started, Revision: 1, StartedAt: at, LastEventAt: at, Items: clone(in.Items), Sets: []RecordedSet{}, Pauses: []Pause{}}
	return Session{snapshot: view, receipts: map[string]receipt{}}, nil
}

func (s Session) Snapshot() Snapshot { return clone(s.snapshot) }

func (s Session) Apply(command Command) (Session, Result, error) {
	if s.snapshot.Contract != SessionContract || !uuid.MatchString(command.ID) || command.ExpectedRevision < 1 || !validTime(command.At) {
		return s, Result{}, ErrInvalid
	}
	command.At = command.At.UTC()
	raw, err := json.Marshal(command)
	if err != nil {
		return s, Result{}, ErrInvalid
	}
	// A legitimate retry is recognized even after a later command or termination.
	if saved, ok := s.receipts[command.ID]; ok {
		if saved.body != string(raw) {
			return s, Result{}, ErrConflict
		}
		return s, Result{Snapshot: s.Snapshot(), AppliedRevision: saved.revision, Replayed: true}, nil
	}
	if command.ExpectedRevision != s.snapshot.Revision || s.snapshot.State == Partial || s.snapshot.State == Completed || s.snapshot.State == Cancelled {
		return s, Result{}, ErrConflict
	}
	terminal := command.Action == "complete" || command.Action == "partial" || command.Action == "cancel"
	// Reserve one final receipt: a technical history cap must never trap a
	// legitimate session open and prevent an explicit partial/cancel/complete.
	if (len(s.receipts) >= maxCommands && !terminal) || command.At.Before(s.snapshot.LastEventAt) {
		return s, Result{}, ErrInvalid
	}
	if command.Action != "record_set" && command.Set != nil {
		return s, Result{}, ErrInvalid
	}
	if terminal != command.Confirmed {
		return s, Result{}, ErrInvalid
	}

	next := s.Snapshot()
	switch command.Action {
	case "pause":
		if next.State != Started {
			return s, Result{}, ErrConflict
		}
		next.State = Paused
		next.Pauses = append(next.Pauses, Pause{StartedAt: command.At})
	case "resume":
		if next.State != Paused {
			return s, Result{}, ErrConflict
		}
		next.State = Started
		next.Pauses[len(next.Pauses)-1].EndedAt = &command.At
	case "record_set":
		if next.State != Started {
			return s, Result{}, ErrConflict
		}
		if command.Set == nil || !setValid(next, *command.Set) {
			return s, Result{}, ErrInvalid
		}
		for _, done := range next.Sets {
			if done.Set.Position == command.Set.Position && done.Set.Number == command.Set.Number {
				return s, Result{}, ErrConflict
			}
		}
		next.Sets = append(next.Sets, RecordedSet{CommandID: command.ID, RecordedAt: command.At, Set: clone(*command.Set)})
	case "complete", "partial", "cancel":
		if command.Action == "complete" && !allSetsRecorded(next) {
			return s, Result{}, ErrConflict
		}
		if next.State == Paused {
			next.Pauses[len(next.Pauses)-1].EndedAt = &command.At
		}
		next.EndedAt = &command.At
		switch command.Action {
		case "complete":
			next.State = Completed
		case "partial":
			next.State = Partial
		case "cancel":
			next.State = Cancelled
		}
	default:
		return s, Result{}, ErrInvalid
	}
	// Calculate once over the full timeline: rounding every short event interval
	// separately would lose fractions of a millisecond after repeated set records.
	active := command.At.Sub(next.StartedAt)
	for _, pause := range next.Pauses {
		end := command.At
		if pause.EndedAt != nil {
			end = *pause.EndedAt
		}
		active -= end.Sub(pause.StartedAt)
	}
	next.ActiveMilliseconds = active.Milliseconds()
	next.LastEventAt = command.At
	next.Revision++
	receipts := make(map[string]receipt, len(s.receipts)+1)
	for id, r := range s.receipts {
		receipts[id] = r
	}
	receipts[command.ID] = receipt{string(raw), next.Revision}
	result := Session{snapshot: next, receipts: receipts}
	return result, Result{Snapshot: result.Snapshot(), AppliedRevision: next.Revision}, nil
}

func setValid(s Snapshot, set Set) bool {
	var selected *Item
	for i := range s.Items {
		if s.Items[i].Position == set.Position {
			selected = &s.Items[i]
			break
		}
	}
	if selected == nil || set.Number < 1 || set.Number > len(selected.Targets) {
		return false
	}
	// A declared zero is a failed/zero-result attempt, not an unknown value.
	// Prescribed targets remain positive; performed measurements preserve zero.
	valid := false
	switch selected.Mode {
	case "repetitions":
		valid = set.Repetitions != nil && *set.Repetitions >= 0 && *set.Repetitions <= 10000 && set.DurationMilliseconds == nil
	case "duration":
		valid = set.DurationMilliseconds != nil && *set.DurationMilliseconds >= 0 && *set.DurationMilliseconds <= 86400000 && set.Repetitions == nil
	}
	if !valid {
		return false
	}
	return set.LoadKg == nil || load.MatchString(*set.LoadKg)
}

func allSetsRecorded(s Snapshot) bool {
	total := 0
	for _, item := range s.Items {
		total += len(item.Targets)
	}
	return total > 0 && len(s.Sets) == total
}
