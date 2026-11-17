package activity

import (
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"time"
)

// Synthetic, disposable journal. It is never an editorial package or runtime seed.
func journal(t *testing.T) ([]storedEvent, Snapshot) {
	t.Helper()
	in := input()
	key := identifier(80)
	s, e := Start(in)
	if e != nil {
		t.Fatal(e)
	}
	first := event{Contract: eventContract, CommandID: key, Revision: 1, RequestHash: hashText(startCanonical(StartRequest{OccurrenceID: in.OccurrenceID})), Start: &in, Title: "Synthetic fixture", MovementLabels: []MovementLabel{{ID: in.Items[0].MovementID, VersionID: in.Items[0].MovementVersion, Title: "Synthetic movement"}}}
	raw, _ := json.Marshal(first)
	rows := []storedEvent{{ID: eventID(in.OwnerID, key), Kind: "session_started", At: in.At, Payload: raw}}
	commands := []Command{recorded(90, 1, 1, time.Minute), command(91, 2, "pause", 2*time.Minute), command(92, 3, "resume", 5*time.Minute), command(93, 4, "partial", 10*time.Minute)}
	for _, c := range commands {
		next, r, e := s.Apply(c)
		if e != nil {
			t.Fatal(e)
		}
		v := event{Contract: eventContract, CommandID: c.ID, Revision: r.AppliedRevision, RequestHash: hashText(commandCanonical(in.ID, CommandInput{ExpectedRevision: c.ExpectedRevision, Action: c.Action, Confirmed: c.Confirmed, Set: c.Set})), Command: &c}
		raw, _ = json.Marshal(v)
		rows = append(rows, storedEvent{ID: eventID(in.OwnerID, c.ID), Kind: "session_command", At: c.At, Payload: raw})
		s = next
	}
	return rows, s.Snapshot()
}
func TestRestore(t *testing.T) {
	t.Run("journal reconstructs facts and old retry at current revision", func(t *testing.T) {
		rows, wanted := journal(t)
		s, title, labels, e := restore(rows)
		if e != nil || title != "Synthetic fixture" || len(labels) != 1 || !reflect.DeepEqual(s.Snapshot(), wanted) {
			t.Fatalf("restore failed: %v", e)
		}
		_, r, e := s.Apply(recorded(90, 1, 1, time.Minute))
		if e != nil || !r.Replayed || r.AppliedRevision != 2 || r.Snapshot.Revision != 5 {
			t.Fatalf("lost durable intent: %+v %v", r, e)
		}
	})
	cases := []struct {
		name   string
		change func([]storedEvent)
	}{
		{"different owner namespace", func(r []storedEvent) { r[0].ID = eventID(identifier(999), identifier(80)) }},
		{"event time changed", func(r []storedEvent) { r[1].At = r[1].At.Add(time.Second) }},
		{"unknown event kind", func(r []storedEvent) { r[1].Kind = "legacy" }},
		{"changed recorded fact", func(r []storedEvent) {
			var e event
			json.Unmarshal(r[1].Payload, &e)
			e.Command.Set.Repetitions = integer(9)
			r[1].Payload, _ = json.Marshal(e)
		}},
		{"revision gap", func(r []storedEvent) {
			var e event
			json.Unmarshal(r[1].Payload, &e)
			e.Revision = 9
			r[1].Payload, _ = json.Marshal(e)
		}},
		{"labels do not match frozen movement", func(r []storedEvent) {
			var e event
			json.Unmarshal(r[0].Payload, &e)
			e.MovementLabels[0].ID = "another:movement"
			r[0].Payload, _ = json.Marshal(e)
		}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rows, _ := journal(t)
			tc.change(rows)
			if _, _, _, e := restore(rows); !errors.Is(e, ErrUnavailable) {
				t.Fatalf("accepted corrupt history: %v", e)
			}
		})
	}
}
func TestExplicitPrescription(t *testing.T) {
	valid := `{"contract":"trainforge.activity-prescription/1","mode":"repetitions","targets":[{"repetitions":10,"durationMilliseconds":null}]}`
	item, e := prescribedItem(0, "test:movement", input().Items[0].MovementVersion, []byte(valid))
	if e != nil || *item.Targets[0].Repetitions != 10 {
		t.Fatal(e)
	}
	cases := []struct{ name, raw string }{
		{"missing owned contract", `{"mode":"repetitions","targets":[{"repetitions":10}]}`},
		{"legacy dose not interpreted", `{"sets":3,"reps":10,"rest":60}`},
		{"missing target remains missing", `{"contract":"trainforge.activity-prescription/1","mode":"repetitions","targets":[{}]}`},
		{"unknown field", `{"contract":"trainforge.activity-prescription/1","mode":"repetitions","targets":[{"repetitions":10,"weight":20}]}`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, e := prescribedItem(0, "test:movement", input().Items[0].MovementVersion, []byte(tc.raw)); !errors.Is(e, ErrPracticeUnavailable) {
				t.Fatal(e)
			}
		})
	}
}
