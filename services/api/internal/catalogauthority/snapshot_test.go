package catalogauthority

import (
	"encoding/json"
	"strings"
	"testing"
)

func fixture(t *testing.T) Snapshot {
	t.Helper()
	raw := `{"sources":[{"id":"fixture","name":"Synthetic source","publisher":null,"urls":[],"created_at":"2000-01-01T00:00:00Z"}],"versions":[{"asset_id":"fixture:movement","version_sha":"` + strings.Repeat("a", 64) + `","kind":"movement","source_id":"fixture","title":null,"locale":null,"source_published_version":null,"allowed_operations":["catalog_metadata"],"payload":{},"created_at":"2000-01-01T00:00:00Z"}],"withdrawals":[]}`
	s, e := Decode([]byte(raw))
	if e != nil {
		t.Fatal(e)
	}
	return s
}
func TestCanonicalPreservesSourceAndRejectsForeignTables(t *testing.T) {
	s := fixture(t)
	raw, e := Canonical(s)
	if e != nil || len(Hash(raw)) != 64 {
		t.Fatal("invalid canonical package")
	}
	if _, e = Decode(append(raw[:len(raw)-1], []byte(`,"users":[]}`)...)); e == nil {
		t.Fatal("private table accepted")
	}
	s.Versions[0]["kind"] = "food"
	if s.Valid() {
		t.Fatal("nutrition entered movement authority")
	}
}
func TestNoWithdrawalResurrectionOrHistoricalMutation(t *testing.T) {
	original := fixture(t)
	raw, _ := Canonical(original)
	next, _ := Decode(raw)
	next.Withdrawals = append(next.Withdrawals, map[string]any{"asset_id": "fixture:movement", "version_sha": strings.Repeat("a", 64), "reason": "synthetic withdrawal", "withdrawn_at": "2000-01-02T00:00:00Z"})
	if !next.Valid() || !Extends(original, next) || Extends(next, original) {
		t.Fatal("withdrawal lifecycle broken")
	}
	next.Sources[0]["name"] = "changed"
	if Extends(original, next) {
		t.Fatal("historical source changed")
	}
}
func TestNullListsAndDuplicateIdentitiesRejected(t *testing.T) {
	s := fixture(t)
	s.Sources = append(s.Sources, s.Sources[0])
	if s.Valid() {
		t.Fatal("duplicate source accepted")
	}
	s = fixture(t)
	s.Withdrawals = nil
	if _, e := Canonical(s); e == nil {
		t.Fatal("nil withdrawals accepted")
	}
	s = fixture(t)
	s.Versions[0]["payload"] = json.Number("1")
	if s.Valid() {
		t.Fatal("nonobject editorial payload accepted")
	}
}
