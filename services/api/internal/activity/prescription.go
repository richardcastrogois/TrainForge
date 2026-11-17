package activity

import (
	"encoding/json"
	"time"
)

// A dose must have been explicitly authored in this contract. Similar-looking
// third-party fields never acquire an interpretation or default prescription.
type prescription struct {
	Contract string   `json:"contract"`
	Mode     string   `json:"mode"`
	Targets  []Target `json:"targets"`
}

func prescribedItem(position int, id, versionID string, raw []byte) (Item, error) {
	var p prescription
	if !strict(raw, &p) || p.Contract != PrescriptionContract {
		return Item{}, ErrPracticeUnavailable
	}
	i := Item{Position: position, MovementID: id, MovementVersion: versionID, Mode: p.Mode, Targets: p.Targets}
	if position < 0 || position > 10000 || !assetID.MatchString(id) || !version.MatchString(versionID) || len(p.Targets) == 0 || len(p.Targets) > maxSets {
		return Item{}, ErrPracticeUnavailable
	}
	for _, t := range p.Targets {
		if !validTarget(t, p.Mode) {
			return Item{}, ErrPracticeUnavailable
		}
	}
	return i, nil
}

const eventContract = "trainforge.activity-event/1"

type event struct {
	Contract       string          `json:"contract"`
	CommandID      string          `json:"commandId"`
	Revision       int             `json:"revision"`
	RequestHash    string          `json:"requestHash"`
	Start          *StartInput     `json:"start,omitempty"`
	Command        *Command        `json:"command,omitempty"`
	Title          string          `json:"title,omitempty"`
	MovementLabels []MovementLabel `json:"movementLabels,omitempty"`
}

type storedEvent struct {
	ID, Kind string
	At       time.Time
	Payload  []byte
}

func restore(events []storedEvent) (Session, string, []MovementLabel, error) {
	if len(events) == 0 || len(events) > maxCommands+2 {
		return Session{}, "", nil, ErrUnavailable
	}
	var s Session
	var title string
	var labels []MovementLabel
	for n, row := range events {
		var v event
		if !strict(row.Payload, &v) || v.Contract != eventContract || !uuid.MatchString(v.CommandID) || v.Revision != n+1 || !version.MatchString(v.RequestHash) {
			return Session{}, "", nil, ErrUnavailable
		}
		if n == 0 {
			if row.Kind != "session_started" || v.Start == nil || v.Command != nil || !v.Start.At.Equal(row.At) {
				return Session{}, "", nil, ErrUnavailable
			}
			var e error
			s, e = Start(*v.Start)
			if e != nil {
				return Session{}, "", nil, ErrUnavailable
			}
			if row.ID != eventID(v.Start.OwnerID, v.CommandID) || v.RequestHash != hashText(startCanonical(StartRequest{OccurrenceID: v.Start.OccurrenceID})) {
				return Session{}, "", nil, ErrUnavailable
			}
			title = v.Title
			if _, e := titleValue(title, ""); e != nil {
				return Session{}, "", nil, ErrUnavailable
			}
			labels = clone(v.MovementLabels)
			wanted := map[string]bool{}
			for _, i := range v.Start.Items {
				wanted[i.MovementID+"/"+i.MovementVersion] = true
			}
			if len(labels) != len(wanted) {
				return Session{}, "", nil, ErrUnavailable
			}
			for _, l := range labels {
				k := l.ID + "/" + l.VersionID
				if _, e := titleValue(l.Title, ""); e != nil {
					return Session{}, "", nil, ErrUnavailable
				}
				if !wanted[k] {
					return Session{}, "", nil, ErrUnavailable
				}
				delete(wanted, k)
			}
		} else {
			if row.Kind != "session_command" || v.Start != nil || v.Command == nil || v.Command.ID != v.CommandID || row.ID != eventID(s.snapshot.OwnerID, v.CommandID) || !v.Command.At.Equal(row.At) {
				return Session{}, "", nil, ErrUnavailable
			}
			c := v.Command
			if v.RequestHash != hashText(commandCanonical(s.snapshot.ID, CommandInput{ExpectedRevision: c.ExpectedRevision, Action: c.Action, Confirmed: c.Confirmed, Set: c.Set})) {
				return Session{}, "", nil, ErrUnavailable
			}
			next, result, e := s.Apply(*v.Command)
			if e != nil || result.Replayed || result.AppliedRevision != v.Revision {
				return Session{}, "", nil, ErrUnavailable
			}
			s = next
		}
	}
	return s, title, labels, nil
}

func commandCanonical(id string, c CommandInput) []byte {
	raw, _ := json.Marshal(struct {
		Kind      string       `json:"kind"`
		SessionID string       `json:"sessionId"`
		Input     CommandInput `json:"input"`
	}{"command", id, c})
	return raw
}
func startCanonical(c StartRequest) []byte {
	raw, _ := json.Marshal(struct {
		Kind  string       `json:"kind"`
		Input StartRequest `json:"input"`
	}{"start", c})
	return raw
}
