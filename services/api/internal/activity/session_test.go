package activity

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"testing"
	"time"
)

// All prescriptions below are disposable synthetic fixtures, never runtime seed.
func integer(n int) *int          { return &n }
func milliseconds(n int64) *int64 { return &n }
func kilogram(s string) *string   { return &s }
func identifier(n int) string     { return fmt.Sprintf("00000000-0000-4000-8000-%012d", n) }
func instant(offset time.Duration) time.Time {
	return time.Date(2026, 11, 16, 10, 0, 0, 0, time.UTC).Add(offset)
}
func input() StartInput {
	return StartInput{ID: identifier(1), OwnerID: identifier(2), OccurrenceID: identifier(3), At: instant(0), Source: Source{ProgramID: "test:program:fixture", ProgramVersion: strings.Repeat("a", 64), SessionKey: "fixture-session"}, Items: []Item{{Position: 0, MovementID: "test:movement:fixture", MovementVersion: strings.Repeat("b", 64), Mode: "repetitions", Targets: []Target{{Repetitions: integer(10)}, {Repetitions: integer(10)}}}}}
}
func session(t *testing.T) Session {
	t.Helper()
	s, e := Start(input())
	if e != nil {
		t.Fatal(e)
	}
	return s
}
func command(id int, revision int, action string, at time.Duration) Command {
	return Command{ID: identifier(id), ExpectedRevision: revision, Action: action, At: instant(at), Confirmed: action == "partial" || action == "complete" || action == "cancel"}
}
func apply(t *testing.T, s Session, c Command) Session {
	t.Helper()
	next, _, e := s.Apply(c)
	if e != nil {
		t.Fatal(e)
	}
	return next
}
func recorded(id, revision, number int, at time.Duration) Command {
	c := command(id, revision, "record_set", at)
	c.Set = &Set{Position: 0, Number: number, Repetitions: integer(7)}
	return c
}

func TestStart(t *testing.T) {
	t.Run("preserves prescribed targets without recording them", func(t *testing.T) {
		s := session(t).Snapshot()
		if s.State != Started || s.Revision != 1 || s.ActiveMilliseconds != 0 || len(s.Sets) != 0 || len(s.Pauses) != 0 || s.EndedAt != nil || *s.Items[0].Targets[0].Repetitions != 10 {
			t.Fatalf("unexpected initial snapshot: %+v", s)
		}
	})
	cases := []struct {
		name   string
		change func(*StartInput)
	}{
		{"missing owner", func(i *StartInput) { i.OwnerID = "" }},
		{"missing version", func(i *StartInput) { i.Source.ProgramVersion = "" }},
		{"missing prescription", func(i *StartInput) { i.Items = nil }},
		{"unknown mode", func(i *StartInput) { i.Items[0].Mode = "unknown" }},
		{"unknown target", func(i *StartInput) { i.Items[0].Targets[0].Repetitions = nil }},
		{"zero is not unknown", func(i *StartInput) { i.Items[0].Targets[0].Repetitions = integer(0) }},
		{"mixed units", func(i *StartInput) { i.Items[0].Targets[0].DurationMilliseconds = milliseconds(1000) }},
		{"duplicate slot", func(i *StartInput) { i.Items = append(i.Items, i.Items[0]) }},
		{"missing clock", func(i *StartInput) { i.At = time.Time{} }},
		{"submicrosecond time", func(i *StartInput) { i.At = i.At.Add(time.Nanosecond) }},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			i := input()
			tc.change(&i)
			if _, e := Start(i); !errors.Is(e, ErrInvalid) {
				t.Fatalf("got %v", e)
			}
		})
	}
}

func TestSessionTimeline(t *testing.T) {
	s := session(t)
	s = apply(t, s, command(10, 1, "pause", 2*time.Minute))
	s = apply(t, s, command(11, 2, "resume", 5*time.Minute))
	s = apply(t, s, command(12, 3, "partial", 10*time.Minute))
	v := s.Snapshot()
	if !v.StartedAt.Equal(instant(0)) || v.State != Partial || v.ActiveMilliseconds != 7*60*1000 || len(v.Pauses) != 1 || v.Pauses[0].EndedAt == nil || !v.Pauses[0].EndedAt.Equal(instant(5*time.Minute)) || v.EndedAt == nil || !v.EndedAt.Equal(instant(10*time.Minute)) {
		t.Fatalf("timeline lost: %+v", v)
	}
	t.Run("closing while paused excludes entire pause", func(t *testing.T) {
		s := apply(t, session(t), command(20, 1, "pause", time.Minute))
		s = apply(t, s, command(21, 2, "partial", 10*time.Minute))
		v := s.Snapshot()
		if v.ActiveMilliseconds != 60000 || v.Pauses[0].EndedAt == nil || !v.Pauses[0].EndedAt.Equal(*v.EndedAt) {
			t.Fatal(v)
		}
	})
	t.Run("multiple pauses preserve original start", func(t *testing.T) {
		s := session(t)
		for n, a := range []string{"pause", "resume", "pause", "resume", "partial"} {
			s = apply(t, s, command(30+n, n+1, a, time.Duration(n+1)*time.Minute))
		}
		v := s.Snapshot()
		if v.ActiveMilliseconds != 180000 || len(v.Pauses) != 2 || !v.StartedAt.Equal(instant(0)) {
			t.Fatal(v)
		}
	})
}

func TestSessionApply(t *testing.T) {
	t.Run("completion needs each recorded set and explicit confirmation", func(t *testing.T) {
		s := session(t)
		if _, _, e := s.Apply(command(10, 1, "complete", time.Minute)); !errors.Is(e, ErrConflict) {
			t.Fatal(e)
		}
		s = apply(t, s, recorded(11, 1, 1, time.Minute))
		if _, _, e := s.Apply(command(12, 2, "complete", 2*time.Minute)); !errors.Is(e, ErrConflict) {
			t.Fatal(e)
		}
		s = apply(t, s, recorded(13, 2, 2, 2*time.Minute))
		c := command(14, 3, "complete", 3*time.Minute)
		c.Confirmed = false
		if _, _, e := s.Apply(c); !errors.Is(e, ErrInvalid) {
			t.Fatal(e)
		}
		c.Confirmed = true
		s = apply(t, s, c)
		v := s.Snapshot()
		if v.State != Completed || *v.Sets[0].Set.Repetitions != 7 || *v.Items[0].Targets[0].Repetitions != 10 {
			t.Fatal(v)
		}
	})
	t.Run("timed set is actual duration not its target", func(t *testing.T) {
		i := input()
		i.Items[0].Mode = "duration"
		i.Items[0].Targets = []Target{{DurationMilliseconds: milliseconds(30000)}}
		s, e := Start(i)
		if e != nil {
			t.Fatal(e)
		}
		c := command(10, 1, "record_set", time.Minute)
		c.Set = &Set{Position: 0, Number: 1, DurationMilliseconds: milliseconds(17000), LoadKg: kilogram("0")}
		s = apply(t, s, c)
		if *s.Snapshot().Sets[0].Set.DurationMilliseconds != 17000 {
			t.Fatal("invented duration")
		}
	})
	t.Run("replay does not add time or revision after termination", func(t *testing.T) {
		s := session(t)
		first := recorded(10, 1, 1, time.Minute)
		s = apply(t, s, first)
		s = apply(t, s, command(11, 2, "partial", 2*time.Minute))
		before := s.Snapshot()
		next, r, e := s.Apply(first)
		if e != nil || !r.Replayed || r.AppliedRevision != 2 || !reflect.DeepEqual(next.Snapshot(), before) || r.Snapshot.Revision != 3 {
			t.Fatalf("invalid replay: %+v %v", r, e)
		}
		first.Set.Repetitions = integer(8)
		if _, _, e = s.Apply(first); !errors.Is(e, ErrConflict) {
			t.Fatal(e)
		}
	})
	t.Run("terminal session cannot change", func(t *testing.T) {
		s := apply(t, session(t), command(10, 1, "cancel", time.Minute))
		for _, a := range []string{"resume", "pause", "record_set", "partial", "complete"} {
			if _, _, e := s.Apply(command(11, 2, a, 2*time.Minute)); !errors.Is(e, ErrConflict) {
				t.Fatalf("%s: %v", a, e)
			}
		}
	})
	t.Run("invalid operations leave original aggregate untouched", func(t *testing.T) {
		s := session(t)
		before := s.Snapshot()
		cs := []Command{command(10, 2, "pause", time.Minute), command(11, 1, "resume", time.Minute), command(12, 1, "automatic_finish", time.Minute), command(13, 1, "pause", -time.Second), recorded(14, 1, 3, time.Minute)}
		for _, c := range cs {
			next, _, e := s.Apply(c)
			if e == nil || !reflect.DeepEqual(next.Snapshot(), before) || !reflect.DeepEqual(s.Snapshot(), before) {
				t.Fatalf("invalid operation changed state: %+v %v", c, e)
			}
		}
	})
	t.Run("paused session cannot record", func(t *testing.T) {
		s := apply(t, session(t), command(10, 1, "pause", time.Minute))
		if _, _, e := s.Apply(recorded(11, 2, 1, 2*time.Minute)); !errors.Is(e, ErrConflict) {
			t.Fatal(e)
		}
	})
	t.Run("a new command cannot overwrite an already recorded set", func(t *testing.T) {
		s := apply(t, session(t), recorded(10, 1, 1, time.Minute))
		if _, _, e := s.Apply(recorded(11, 2, 1, 2*time.Minute)); !errors.Is(e, ErrConflict) {
			t.Fatal(e)
		}
	})
	t.Run("time is not rounded separately at every event", func(t *testing.T) {
		s := apply(t, session(t), recorded(10, 1, 1, 500*time.Microsecond))
		s = apply(t, s, recorded(11, 2, 2, time.Millisecond))
		if s.Snapshot().ActiveMilliseconds != 1 {
			t.Fatal(s.Snapshot())
		}
	})
}

func TestSessionIsolation(t *testing.T) {
	i := input()
	s, e := Start(i)
	if e != nil {
		t.Fatal(e)
	}
	*i.Items[0].Targets[0].Repetitions = 900
	v := s.Snapshot()
	*v.Items[0].Targets[0].Repetitions = 800
	if *s.Snapshot().Items[0].Targets[0].Repetitions != 10 {
		t.Fatal("caller mutated prescription")
	}
	c := recorded(10, 1, 1, time.Minute)
	next, r, e := s.Apply(c)
	if e != nil {
		t.Fatal(e)
	}
	*c.Set.Repetitions = 700
	*r.Snapshot.Sets[0].Set.Repetitions = 600
	if len(s.Snapshot().Sets) != 0 || *next.Snapshot().Sets[0].Set.Repetitions != 7 {
		t.Fatal("caller mutated recorded fact")
	}
	if _, _, e := (Session{}).Apply(command(10, 1, "pause", time.Minute)); !errors.Is(e, ErrInvalid) {
		t.Fatal(e)
	}
	raw, e := json.Marshal(next.Snapshot())
	if e != nil || strings.Contains(string(raw), "receipts") || strings.Contains(string(raw), "ExpectedRevision") {
		t.Fatal("private journal leaked")
	}
}

func TestSessionLimitsAndDeclaredMeasurements(t *testing.T) {
	t.Run("command cap still permits explicit termination", func(t *testing.T) {
		for _, action := range []string{"partial", "cancel"} {
			s := session(t)
			// A compact internal fixture represents the already full receipt journal.
			for n := 0; n < maxCommands; n++ {
				s.receipts[identifier(100+n)] = receipt{"fixture", n + 2}
			}
			s.snapshot.Revision = maxCommands + 1
			if _, _, e := s.Apply(command(9000, maxCommands+1, "pause", time.Minute)); !errors.Is(e, ErrInvalid) {
				t.Fatal(e)
			}
			closed, _, e := s.Apply(command(9001, maxCommands+1, action, time.Minute))
			if e != nil || closed.Snapshot().EndedAt == nil {
				t.Fatalf("session trapped open: %v", e)
			}
		}
	})
	t.Run("explicit zero remains different from a missing result", func(t *testing.T) {
		c := recorded(10, 1, 1, time.Minute)
		c.Set.Repetitions = integer(0)
		s := apply(t, session(t), c)
		if s.Snapshot().Sets[0].Set.Repetitions == nil || *s.Snapshot().Sets[0].Set.Repetitions != 0 {
			t.Fatal("lost declared zero")
		}
		c = recorded(11, 2, 2, 2*time.Minute)
		c.Set.Repetitions = nil
		if _, _, e := s.Apply(c); !errors.Is(e, ErrInvalid) {
			t.Fatal(e)
		}
	})
	t.Run("malformed identity and load never become records", func(t *testing.T) {
		for _, kg := range []string{"-1", "1e3", "NaN", "1,5", "01", "1.0000"} {
			c := recorded(10, 1, 1, time.Minute)
			c.Set.LoadKg = kilogram(kg)
			if _, _, e := session(t).Apply(c); !errors.Is(e, ErrInvalid) {
				t.Fatalf("%q: %v", kg, e)
			}
		}
		c := command(10, 1, "pause", time.Minute)
		c.ID = "client-text"
		if _, _, e := session(t).Apply(c); !errors.Is(e, ErrInvalid) {
			t.Fatal(e)
		}
	})
	t.Run("equal instant in another offset is the same retry", func(t *testing.T) {
		c := command(10, 1, "pause", time.Minute)
		s := apply(t, session(t), c)
		c.At = c.At.In(time.FixedZone("declared offset", -3*60*60))
		_, r, e := s.Apply(c)
		if e != nil || !r.Replayed {
			t.Fatalf("%+v %v", r, e)
		}
	})
}
