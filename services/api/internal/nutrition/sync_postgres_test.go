package nutrition

import (
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/privacy"
)

func syncOp(kind, local string, body any) SyncOperation {
	raw, _ := json.Marshal(body)
	return SyncOperation{OperationID: newID(), Kind: kind, LocalID: local, Body: raw}
}
func TestNutritionSyncPostgresDurabilityBaselineMappingsAndTombstones(t *testing.T) {
	ctx, writer, runtime := mealPools(t)
	_, p := mealLogin(t, ctx, runtime, "sync-lifecycle")
	_, other := mealLogin(t, ctx, runtime, "sync-other")
	store := NutritionStore{runtime}
	legacyFood := mealFood(t, ctx, store, p)
	legacyBody, _ := json.Marshal(mealCommand(legacyFood).Items[0])
	if _, _, e := store.Mutate(ctx, p, "create-entry", "", newID(), legacyBody); e != nil {
		t.Fatal("legacy fixture", e)
	}
	first, e := store.SyncChanges(ctx, p, "", 1)
	if e != nil || len(first.Items) != 1 || !first.HasMore {
		t.Fatal("legacy baseline", e, first)
	}
	if _, e = store.SyncChanges(ctx, other, first.Cursor, 100); !errors.Is(e, ErrFoodQuery) {
		t.Fatal("foreign cursor")
	}
	foodOp := syncOp("food.create", newID(), OwnFoodInput{Name: "Offline food fixture", Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{{Name: "Protein", Unit: "g", Value: ptr("10")}}})
	push := func(op SyncOperation) SyncResult {
		t.Helper()
		out, e := store.SyncPush(ctx, p, SyncPush{SyncContract, []SyncOperation{op}})
		if e != nil || len(out.Results) != 1 {
			t.Fatal("push", e)
		}
		return out.Results[0]
	}
	createdFood := push(foodOp)
	if createdFood.Status != "confirmed" {
		t.Fatal("create food", createdFood)
	}
	if _, e = writer.Exec(ctx, "UPDATE trainforge_v1.idempotency_records SET expires_at=clock_timestamp()-interval '2 days' WHERE user_id=$1", p.User.ID); e != nil {
		t.Fatal(e)
	}
	if replay := push(foodOp); replay.RemoteID != createdFood.RemoteID || replay.Status != "confirmed" {
		t.Fatal("durable replay", replay)
	}
	var f FoodDetail
	if json.Unmarshal(createdFood.Value, &f) != nil {
		t.Fatal("food snapshot")
	}
	in := mealCommand(f).Items[0]
	in.FoodID = "own:" + foodOp.LocalID
	entryOp := syncOp("entry.create", newID(), in)
	entryOp.DependsOn = []string{foodOp.OperationID}
	createdEntry := push(entryOp)
	if createdEntry.Status != "confirmed" {
		t.Fatal("dependent mapping", createdEntry)
	}
	missingTarget := syncOp("entry.update", newID(), in)
	missingTarget.RemoteID = newID()
	if push(missingTarget).Status != "conflict" {
		t.Fatal("missing private resource confused with pending public catalog")
	}
	var entry Entry
	if json.Unmarshal(createdEntry.Value, &entry) != nil || entry.FoodID != f.ID {
		t.Fatal("mapped food snapshot")
	}
	wrong := foodOp
	wrong.Body = json.RawMessage(`{"name":"changed"}`)
	if push(wrong).Status != "conflict" {
		t.Fatal("operation body changed")
	}
	unknown := in
	unknown.FoodID = "food:" + string(makeHex('a', 64))
	unknown.FoodVersion = string(makeHex('b', 64))
	unknownOp := syncOp("entry.create", newID(), unknown)
	if push(unknownOp).Status != "pending_catalog" {
		t.Fatal("unknown catalog")
	}
	var receipts int
	if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND operation_id=$2", p.User.ID, unknownOp.OperationID).Scan(&receipts) != nil || receipts != 0 {
		t.Fatal("pending catalog persisted as completed")
	}
	remove := syncOp("entry.delete", entryOp.LocalID, EntryInput{Revision: 1})
	deleted := push(remove)
	if deleted.Status != "confirmed" {
		t.Fatal("delete", deleted)
	}
	late := push(entryOp)
	var lateEntry Entry
	_ = json.Unmarshal(late.Value, &lateEntry)
	if late.RemoteID != createdEntry.RemoteID || lateEntry.DeletedAt == nil {
		t.Fatal("late replay resurrected deleted entry")
	}
	page, e := store.SyncChanges(ctx, p, first.Cursor, 100)
	if e != nil || page.HasMore {
		t.Fatal("delta feed", e)
	}
	foundDeleted := false
	for _, change := range page.Items {
		if change.ID == createdEntry.RemoteID && change.Deleted {
			foundDeleted = true
		}
	}
	if !foundDeleted {
		t.Fatal("missing tombstone")
	}
	empty, e := store.SyncChanges(ctx, p, page.Cursor, 100)
	if e != nil || len(empty.Items) != 0 {
		t.Fatal("checkpoint did not advance")
	}
	service := privacy.Service{Repository: privacy.Postgres{Pool: runtime}}
	intent, e := service.Intent(ctx, p, privacy.Confirmation)
	if e != nil {
		t.Fatal("privacy inventory", e)
	}
	if _, e = service.Delete(ctx, p, privacy.DeleteRequest{Confirmation: privacy.Confirmation, Challenge: intent.Challenge}); e != nil {
		t.Fatal("erase", e)
	}
	for _, table := range []string{"nutrition_sync_state", "nutrition_changes", "nutrition_operation_receipts"} {
		var count int
		if writer.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1."+table+" WHERE user_id=$1", p.User.ID).Scan(&count) != nil || count != 0 {
			t.Fatal("private sync survived deletion", table)
		}
	}
	if _, e = store.SyncPush(ctx, p, SyncPush{SyncContract, []SyncOperation{foodOp}}); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("deleted session accepted")
	}
}
func makeHex(c byte, n int) []byte {
	out := make([]byte, n)
	for i := range out {
		out[i] = c
	}
	return out
}

func TestNutritionSyncPostgresMealAtomicReplayAndConcurrentReceipts(t *testing.T) {
	ctx, writer, runtime := mealPools(t)
	_, p := mealLogin(t, ctx, runtime, "sync-meal-atomic")
	store := NutritionStore{runtime}
	food := mealFood(t, ctx, store, p)
	push := func(op SyncOperation) SyncResult {
		t.Helper()
		out, e := store.SyncPush(ctx, p, SyncPush{SyncContract, []SyncOperation{op}})
		if e != nil || len(out.Results) != 1 {
			t.Fatal("meal push", e)
		}
		return out.Results[0]
	}
	command := mealCommand(food)
	for i := range command.Items {
		command.Items[i].CalculationAlgorithm = CanonicalAlgorithm
	}
	create := syncOp("meal.create", newID(), command)
	created := push(create)
	if created.Status != "confirmed" {
		t.Fatal("meal create", created)
	}
	var meal ConfirmedMeal
	if json.Unmarshal(created.Value, &meal) != nil || len(meal.Entries) != 2 {
		t.Fatal("meal entries mapping")
	}
	if meal.Entries[0].Quantity != command.Items[0].Quantity && !sameMealQuantity(meal.Entries[0].Quantity, command.Items[0].Quantity) {
		t.Fatal("meal order changed")
	}
	before, e := store.SyncChanges(ctx, p, "", 200)
	if e != nil {
		t.Fatal(e)
	}
	removeEntry := syncOp("entry.delete", meal.Entries[0].ID, EntryInput{Revision: 1})
	removeEntry.RemoteID = meal.Entries[0].ID
	if push(removeEntry).Status != "confirmed" {
		t.Fatal("delete grouped item")
	}
	changes, e := store.SyncChanges(ctx, p, before.Cursor, 200)
	if e != nil {
		t.Fatal(e)
	}
	updatedGroup := false
	for _, c := range changes.Items {
		if c.Entity == "meal" && c.ID == created.RemoteID {
			var m ConfirmedMeal
			if json.Unmarshal(c.Value, &m) == nil && m.Meal.TotalActiveItems == 1 && m.Entries[0].DeletedAt != nil {
				updatedGroup = true
			}
		}
	}
	if !updatedGroup {
		t.Fatal("entry edit did not update group snapshot")
	}
	edit := syncOp("meal.update", create.LocalID, EditMealCommand{Revision: 1, Reviewed: true, Title: "Corrected fixture", OccurredAt: command.OccurredAt, Timezone: "UTC"})
	if push(edit).Status != "confirmed" {
		t.Fatal("metadata mapping")
	}
	stale := edit
	stale.OperationID = newID()
	if push(stale).Status != "conflict" {
		t.Fatal("stale meal revision accepted")
	}
	remove := syncOp("meal.delete", create.LocalID, DeleteMealCommand{Revision: 2, Reviewed: true})
	if push(remove).Status != "confirmed" {
		t.Fatal("delete group")
	}
	if _, e = writer.Exec(ctx, "UPDATE trainforge_v1.idempotency_records SET expires_at=clock_timestamp()-interval '2 days' WHERE user_id=$1", p.User.ID); e != nil {
		t.Fatal(e)
	}
	late := push(create)
	if json.Unmarshal(late.Value, &meal) != nil || meal.DeletedAt == nil || late.RemoteID != created.RemoteID {
		t.Fatal("late meal create revived data")
	}
	newFood := syncOp("food.create", newID(), OwnFoodInput{Name: "Concurrent offline fixture", Basis: Basis{ptr("100"), ptr("g")}, Nutrients: []OwnNutrient{}})
	var group sync.WaitGroup
	outputs := make(chan SyncResult, 2)
	failures := make(chan error, 2)
	for i := 0; i < 2; i++ {
		group.Add(1)
		go func() {
			defer group.Done()
			out, e := store.SyncPush(ctx, p, SyncPush{SyncContract, []SyncOperation{newFood}})
			if e != nil {
				failures <- e
				return
			}
			outputs <- out.Results[0]
		}()
	}
	group.Wait()
	close(outputs)
	close(failures)
	for e := range failures {
		t.Fatal("concurrent push", e)
	}
	first := ""
	for out := range outputs {
		if out.Status != "confirmed" || (first != "" && out.RemoteID != first) {
			t.Fatal("concurrent receipt duplicated resource")
		}
		first = out.RemoteID
	}
}
