package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"trainforge.local/api/internal/auth"
)

func (s NutritionStore) SyncChanges(ctx context.Context, p auth.Principal, cursor string, limit int) (SyncPage, error) {
	result := SyncPage{Contract: SyncContract, Items: []SyncChange{}}
	after, e := parseSyncCursor(p.User.ID, cursor)
	if e != nil || limit < 1 || limit > 200 {
		return result, ErrFoodQuery
	}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return result, e
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, `SELECT trainforge_v1.nutrition_sync_seed($1,$2,$3)`, p.User.ID, p.FamilyID, p.AccessHash); e != nil {
		return result, ErrFoodUnavailable
	}
	var current int64
	if tx.QueryRow(ctx, `SELECT sequence FROM trainforge_v1.nutrition_sync_state WHERE user_id=$1`, p.User.ID).Scan(&current) != nil {
		return result, ErrFoodUnavailable
	}
	if after > current {
		return result, ErrFoodQuery
	}
	rows, e := tx.Query(ctx, `SELECT sequence,entity,resource_id,value,deleted FROM trainforge_v1.nutrition_changes WHERE user_id=$1 AND sequence>$2 ORDER BY sequence LIMIT $3`, p.User.ID, after, limit+1)
	if e != nil {
		return result, ErrFoodUnavailable
	}
	last := after
	for rows.Next() {
		var item SyncChange
		var sequence int64
		if rows.Scan(&sequence, &item.Entity, &item.ID, &item.Value, &item.Deleted) != nil {
			rows.Close()
			return result, ErrFoodUnavailable
		}
		if len(result.Items) == limit {
			result.HasMore = true
			break
		}
		item.Sequence = strconv.FormatInt(sequence, 10)
		last = sequence
		result.Items = append(result.Items, item)
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return result, ErrFoodUnavailable
	}
	result.Cursor = syncCursor(p.User.ID, last)
	result.NextCursor = result.Cursor
	return result, nil
}

func (s NutritionStore) SyncPush(ctx context.Context, p auth.Principal, push SyncPush) (SyncPushResult, error) {
	result := SyncPushResult{Contract: SyncContract, Results: []SyncResult{}}
	if push.Validate() != nil {
		return result, ErrFoodQuery
	}
	for _, op := range push.Operations {
		item, e := s.syncOperation(ctx, p, op)
		if e != nil {
			return result, e
		}
		result.Results = append(result.Results, item)
	}
	return result, nil
}

func syncFailure(op SyncOperation, e error) SyncResult {
	r := SyncResult{OperationID: op.OperationID, LocalID: op.LocalID, Status: "invalid", Code: "invalid_nutrition_request"}
	switch {
	case errors.Is(e, ErrEntryConflict):
		r.Status = "conflict"
		r.Code = "nutrition_conflict"
	case errors.Is(e, ErrFoodMissing):
		r.Status = "pending_catalog"
		r.Code = "food_version_unavailable"
	}
	return r
}

// The account lock serializes both legacy writes and offline operations. Domain
// write, receipt and change snapshots commit together, including after 24 hours.
func (s NutritionStore) syncOperation(ctx context.Context, p auth.Principal, op SyncOperation) (SyncResult, error) {
	r := SyncResult{OperationID: op.OperationID, LocalID: op.LocalID, Status: "confirmed"}
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return r, e
	}
	defer tx.Rollback(ctx)
	if _, e = tx.Exec(ctx, `SELECT trainforge_v1.nutrition_sync_seed($1,$2,$3)`, p.User.ID, p.FamilyID, p.AccessHash); e != nil {
		return r, ErrFoodUnavailable
	}
	// Canonicalize map key order without coercing exact decimal strings/numbers.
	raw, _ := json.Marshal(op)
	var canonical any
	decoder := json.NewDecoder(strings.NewReader(string(raw)))
	decoder.UseNumber()
	if decoder.Decode(&canonical) != nil {
		return syncFailure(op, ErrFoodQuery), nil
	}
	raw, _ = json.Marshal(canonical)
	requestHash := digest(raw)
	var priorHash, prior []byte
	e = tx.QueryRow(ctx, `SELECT request_hash,result FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND operation_id=$2`, p.User.ID, op.OperationID).Scan(&priorHash, &prior)
	if e == nil {
		if !equal(priorHash, requestHash) {
			return syncFailure(op, ErrEntryConflict), nil
		}
		if json.Unmarshal(prior, &r) != nil {
			return r, ErrFoodUnavailable
		}
		// Late replay returns the latest tombstone/revision, never resurrecting a
		// resource from the original cached response.
		if e = s.refreshSyncResult(ctx, tx, p.User.ID, op.Kind, &r); e != nil {
			return r, e
		}
		if tx.Commit(ctx) != nil {
			return r, ErrFoodUnavailable
		}
		return r, nil
	}
	if !errors.Is(e, pgx.ErrNoRows) {
		return r, ErrFoodUnavailable
	}
	for _, dependency := range op.DependsOn {
		var exists bool
		if tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND operation_id=$2)`, p.User.ID, dependency).Scan(&exists) != nil {
			return r, ErrFoodUnavailable
		}
		if !exists {
			r.Status = "dependency_pending"
			r.Code = "dependency_pending"
			return r, nil
		}
	}
	if strings.HasSuffix(op.Kind, ".create") {
		var exists bool
		if tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND kind=$2 AND local_id=$3)`, p.User.ID, op.Kind, op.LocalID).Scan(&exists) != nil {
			return r, ErrFoodUnavailable
		}
		if exists {
			return syncFailure(op, ErrEntryConflict), nil
		}
	}
	e = s.applySyncOperation(ctx, tx, p, op, &r)
	if e != nil {
		if errors.Is(e, ErrFoodQuery) || errors.Is(e, ErrEntryConflict) || errors.Is(e, ErrFoodMissing) {
			return syncFailure(op, e), nil
		}
		return r, e
	}
	resultBody, _ := json.Marshal(r)
	if _, e = tx.Exec(ctx, `SELECT trainforge_v1.nutrition_sync_receipt($1,$2,$3,$4,$5,$6,$7,$8)`, p.User.ID, p.FamilyID, p.AccessHash, op.OperationID, op.Kind, op.LocalID, requestHash, resultBody); e != nil {
		return r, ErrFoodUnavailable
	}
	if tx.Commit(ctx) != nil {
		return r, ErrFoodUnavailable
	}
	return r, nil
}

func (s NutritionStore) refreshSyncResult(ctx context.Context, tx pgx.Tx, user, kind string, r *SyncResult) error {
	entity := strings.Split(kind, ".")[0]
	// Internal snapshot is only read through already-authorized transactions.
	var raw []byte
	switch entity {
	case "food":
		e := tx.QueryRow(ctx, "SELECT "+ownProjection+" FROM trainforge_v1.food_versions v WHERE v.owner_id=$1 AND v.food_id=$2 ORDER BY created_at DESC,version_sha DESC LIMIT 1", user, r.RemoteID).Scan(&raw)
		if e != nil {
			return ErrFoodUnavailable
		}
	case "entry":
		v, e := readEntry(ctx, tx, user, r.RemoteID)
		if e != nil {
			return e
		}
		raw, _ = json.Marshal(v)
		r.Revision = v.Calculation.Revision
	case "meal":
		v, e := readMeal(ctx, tx, user, r.RemoteID)
		if e != nil {
			return e
		}
		raw, _ = json.Marshal(v)
		r.Revision = v.Meal.Revision
	}
	r.Value = raw
	return nil
}

func syncRemote(ctx context.Context, tx pgx.Tx, user, kind, local, remote string) (string, error) {
	if remote != "" {
		return remote, nil
	}
	var raw []byte
	e := tx.QueryRow(ctx, `SELECT result FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND kind=$2 AND local_id=$3`, user, kind+".create", local).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return local, nil
	}
	if e != nil {
		return "", ErrFoodUnavailable
	}
	var result SyncResult
	if json.Unmarshal(raw, &result) != nil {
		return "", ErrFoodUnavailable
	}
	return result.RemoteID, nil
}
func syncFoodReference(ctx context.Context, tx pgx.Tx, user string, in *EntryInput) error {
	if !strings.HasPrefix(in.FoodID, "own:") {
		return nil
	}
	local := strings.TrimPrefix(in.FoodID, "own:")
	if !uuidPattern.MatchString(local) {
		return ErrFoodQuery
	}
	var raw []byte
	e := tx.QueryRow(ctx, `SELECT result FROM trainforge_v1.nutrition_operation_receipts WHERE user_id=$1 AND kind='food.create' AND local_id=$2`, user, local).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return nil
	}
	if e != nil {
		return ErrFoodUnavailable
	}
	var r SyncResult
	var food FoodDetail
	if json.Unmarshal(raw, &r) != nil || json.Unmarshal(r.Value, &food) != nil {
		return ErrFoodUnavailable
	}
	in.FoodID = food.ID
	in.FoodVersion = food.VersionID
	return nil
}
func (s NutritionStore) applySyncOperation(ctx context.Context, tx pgx.Tx, p auth.Principal, op SyncOperation, r *SyncResult) error {
	entity := strings.Split(op.Kind, ".")[0]
	id, e := syncRemote(ctx, tx, p.User.ID, entity, op.LocalID, op.RemoteID)
	if e != nil {
		return e
	}
	switch op.Kind {
	case "food.create":
		var in OwnFoodInput
		if syncDecode(op.Body, &in) != nil || validateOwn(in) != nil {
			return ErrFoodQuery
		}
		body, _ := json.Marshal(in)
		raw, _, e := s.mutateTx(ctx, tx, p, "own-food", "", op.OperationID, body)
		if e != nil {
			return e
		}
		var food FoodDetail
		if json.Unmarshal(raw, &food) != nil {
			return ErrFoodUnavailable
		}
		r.Value = raw
		r.RemoteID = food.ID
		r.Revision = 1
	case "entry.create", "entry.update", "entry.delete":
		var in EntryInput
		if syncDecode(op.Body, &in) != nil {
			return ErrFoodQuery
		}
		if op.Revision != nil {
			in.Revision = *op.Revision
		}
		if e = syncFoodReference(ctx, tx, p.User.ID, &in); e != nil {
			return e
		}
		command := "create-entry"
		if op.Kind == "entry.create" {
			id = ""
		} else {
			if !uuidPattern.MatchString(id) {
				return ErrFoodQuery
			}
			if _, err := readEntry(ctx, tx, p.User.ID, id); errors.Is(err, ErrFoodMissing) {
				return ErrEntryConflict
			} else if err != nil {
				return err
			}
			command = "edit-entry:" + id
			if op.Kind == "entry.delete" {
				command = "delete-entry:" + id
			}
		}
		body, _ := json.Marshal(in)
		raw, _, e := s.mutateTx(ctx, tx, p, command, id, op.OperationID, body)
		if e != nil {
			if errors.Is(e, ErrFoodMissing) && strings.HasPrefix(in.FoodID, "own:") {
				return ErrEntryConflict
			}
			return e
		}
		var entry Entry
		if json.Unmarshal(raw, &entry) != nil {
			return ErrFoodUnavailable
		}
		r.Value = raw
		r.RemoteID = entry.ID
		r.Revision = entry.Calculation.Revision
	case "meal.create":
		var in NewMealCommand
		if syncDecode(op.Body, &in) != nil {
			return ErrFoodQuery
		}
		for i := range in.Items {
			if e = syncFoodReference(ctx, tx, p.User.ID, &in.Items[i]); e != nil {
				return e
			}
		}
		if in.Validate() != nil {
			return ErrFoodQuery
		}
		meal, e := (MealStore{s}).createMealTx(ctx, tx, p, in, op.OperationID)
		if e != nil {
			return e
		}
		r.RemoteID = meal.Meal.ID
		r.Revision = meal.Meal.Revision
		r.Value, _ = json.Marshal(meal)
	case "meal.update", "meal.delete":
		if !uuidPattern.MatchString(id) {
			return ErrFoodQuery
		}
		if _, err := readMeal(ctx, tx, p.User.ID, id); errors.Is(err, ErrFoodMissing) {
			return ErrEntryConflict
		} else if err != nil {
			return err
		}
		var edit *EditMealCommand
		var remove *DeleteMealCommand
		if op.Kind == "meal.update" {
			edit = &EditMealCommand{}
			if syncDecode(op.Body, edit) != nil {
				return ErrFoodQuery
			}
			if op.Revision != nil {
				edit.Revision = *op.Revision
			}
			if edit.Validate() != nil {
				return ErrFoodQuery
			}
		} else {
			remove = &DeleteMealCommand{}
			if syncDecode(op.Body, remove) != nil {
				return ErrFoodQuery
			}
			if op.Revision != nil {
				remove.Revision = *op.Revision
			}
			if !remove.Reviewed || remove.Revision < 1 {
				return ErrFoodQuery
			}
		}
		meal, e := (MealStore{s}).changeMealTx(ctx, tx, p, id, op.OperationID, edit, remove)
		if e != nil {
			return e
		}
		r.RemoteID = meal.Meal.ID
		r.Revision = meal.Meal.Revision
		r.Value, _ = json.Marshal(meal)
	default:
		return ErrFoodQuery
	}
	return nil
}
