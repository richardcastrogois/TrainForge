package nutrition

import (
	"encoding/json"
	"testing"
)

func TestSyncCursorAccountAndPrecision(t *testing.T) {
	user := "00000000-0000-4000-8000-000000000001"
	n := int64(9007199254740993)
	if got, e := parseSyncCursor(user, syncCursor(user, n)); e != nil || got != n {
		t.Fatal("sequence lost precision", got, e)
	}
	if _, e := parseSyncCursor("00000000-0000-4000-8000-000000000002", syncCursor(user, n)); e == nil {
		t.Fatal("foreign cursor accepted")
	}
	for _, raw := range []string{"!", syncCursor(user, -1), "YWJj"} {
		if _, e := parseSyncCursor(user, raw); e == nil {
			t.Fatal("invalid cursor accepted")
		}
	}
}
func TestSyncEnvelopeAndStrictBody(t *testing.T) {
	op := SyncOperation{OperationID: "00000000-0000-4000-8000-000000000001", LocalID: "00000000-0000-4000-8000-000000000002", Kind: "food.create", Body: json.RawMessage(`{"name":"Arroz","preparation":"cozido","basis":{"quantity":"100","unit":"g"},"nutrients":[]}`)}
	push := SyncPush{Contract: SyncContract, Operations: []SyncOperation{op}}
	if push.Validate() != nil {
		t.Fatal("valid envelope rejected")
	}
	push.Operations = append(push.Operations, op)
	if push.Validate() == nil {
		t.Fatal("duplicate operation accepted")
	}
	var in OwnFoodInput
	if syncDecode(op.Body, &in) != nil || validateOwn(in) != nil {
		t.Fatal("valid food rejected")
	}
	for _, raw := range []string{`{"name":"a","name":"b"}`, `{"name":"a","ownerId":"another-user"}`, `{} {}`} {
		if syncDecode([]byte(raw), &in) == nil {
			t.Fatal("ambiguous or foreign fields accepted")
		}
	}
}
func TestSyncValidationDoesNotMistakeDependencyOrCatalogForSuccess(t *testing.T) {
	op := SyncOperation{OperationID: "00000000-0000-4000-8000-000000000001", LocalID: "00000000-0000-4000-8000-000000000002", Kind: "entry.create", Body: json.RawMessage(`{}`)}
	if r := syncFailure(op, ErrFoodMissing); r.Status != "pending_catalog" || r.Value != nil {
		t.Fatal("missing catalog masqueraded as saved")
	}
	if r := syncFailure(op, ErrEntryConflict); r.Status != "conflict" {
		t.Fatal("conflict lost")
	}
	op.DependsOn = []string{op.OperationID}
	if (SyncPush{Contract: SyncContract, Operations: []SyncOperation{op}}).Validate() == nil {
		t.Fatal("self dependency accepted")
	}
}
