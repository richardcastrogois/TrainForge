package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"time"
	"trainforge.local/api/internal/auth"
)

// MealStore reuses the authorized transaction and the source-rational calculator.
// Account locks serialize meal/entry writes and prevent mixed read snapshots.
type MealStore struct{ Nutrition NutritionStore }

func mealDatabaseError(e error) error {
	var p *pgconn.PgError
	if errors.As(e, &p) {
		switch p.Code {
		case "TFA01":
			return auth.ErrInvalid
		case "TFQ01":
			return ErrFoodQuery
		case "TFC01":
			return ErrEntryConflict
		case "TFM01":
			return ErrFoodMissing
		}
	}
	return ErrFoodUnavailable
}

const mealProjection = `jsonb_build_object('id',m.id,'title',m.title,
 'occurredAt',to_char(m.occurred_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
 'timezone',m.timezone,'revision',m.revision,'totalActiveItems',
 (SELECT count(*) FROM trainforge_v1.meal_items mi JOIN trainforge_v1.food_entries e ON e.id=mi.entry_id AND e.user_id=mi.user_id
  WHERE mi.meal_id=m.id AND mi.user_id=m.user_id AND e.deleted_at IS NULL))`

func readMeal(ctx context.Context, tx pgx.Tx, user, id string) (ConfirmedMeal, error) {
	result := ConfirmedMeal{Entries: []Entry{}}
	var raw []byte
	e := tx.QueryRow(ctx, "SELECT "+mealProjection+",to_char(m.deleted_at AT TIME ZONE 'UTC','YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"') FROM trainforge_v1.meals m WHERE m.id=$1 AND m.user_id=$2", id, user).Scan(&raw, &result.DeletedAt)
	if errors.Is(e, pgx.ErrNoRows) {
		return result, ErrFoodMissing
	}
	if e != nil || json.Unmarshal(raw, &result.Meal) != nil || !mealMetadataValid(result.Meal) {
		return result, ErrFoodUnavailable
	}
	rows, e := tx.Query(ctx, "SELECT "+entryProjection+" FROM trainforge_v1.meal_items mi JOIN trainforge_v1.food_entries v ON v.id=mi.entry_id AND v.user_id=mi.user_id WHERE mi.meal_id=$1 AND mi.user_id=$2 ORDER BY mi.position LIMIT 32", id, user)
	if e != nil {
		return result, ErrFoodUnavailable
	}
	defer rows.Close()
	for rows.Next() {
		var entry Entry
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &entry) != nil {
			return result, ErrFoodUnavailable
		}
		result.Entries = append(result.Entries, entry)
	}
	if rows.Err() != nil {
		return result, ErrFoodUnavailable
	}
	return result, nil
}
func (s MealStore) Meal(ctx context.Context, p auth.Principal, id string) (ConfirmedMeal, error) {
	if !mealPrincipalValid(p) {
		return ConfirmedMeal{}, auth.ErrInvalid
	}
	if !uuidPattern.MatchString(id) {
		return ConfirmedMeal{}, ErrFoodQuery
	}
	tx, e := s.Nutrition.begin(ctx, p, false)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	defer tx.Rollback(ctx)
	result, e := readMeal(ctx, tx, p.User.ID, id)
	if e != nil {
		return result, e
	}
	if tx.Commit(ctx) != nil {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	return result, nil
}

func (s MealStore) ReadMealDay(ctx context.Context, p auth.Principal, day, tz string) (MealDaySource, error) {
	source := MealDaySource{Entries: []Entry{}, Meals: []MealMetadata{}, Memberships: []MealMembership{}, Complete: true}
	if !mealPrincipalValid(p) {
		return source, auth.ErrInvalid
	}
	start, end, e := dayBounds(day, tz)
	if e != nil {
		return source, e
	}
	tx, e := s.Nutrition.begin(ctx, p, false)
	if e != nil {
		return source, e
	}
	defer tx.Rollback(ctx)
	rows, e := tx.Query(ctx, "SELECT "+entryProjection+" FROM trainforge_v1.food_entries v WHERE v.user_id=$1 AND v.deleted_at IS NULL AND v.occurred_at>=$2 AND v.occurred_at<$3 ORDER BY v.occurred_at DESC,v.id DESC LIMIT 101", p.User.ID, start, end)
	if e != nil {
		return source, ErrFoodUnavailable
	}
	for rows.Next() {
		var raw []byte
		var entry Entry
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &entry) != nil {
			rows.Close()
			return source, ErrFoodUnavailable
		}
		source.Entries = append(source.Entries, entry)
	}
	e = rows.Err()
	rows.Close()
	if e != nil {
		return source, ErrFoodUnavailable
	}
	if len(source.Entries) > maxMealDayEntries {
		source.Complete = false
		source.Entries = source.Entries[:maxMealDayEntries]
	}
	ids := []string{}
	for _, entry := range source.Entries {
		ids = append(ids, entry.ID)
	}
	rows, e = tx.Query(ctx, "SELECT mi.entry_id::text,mi.meal_id::text,"+mealProjection+" FROM trainforge_v1.meal_items mi JOIN trainforge_v1.meals m ON m.id=mi.meal_id AND m.user_id=mi.user_id WHERE mi.user_id=$1 AND mi.entry_id=ANY($2::text[]::uuid[]) AND m.deleted_at IS NULL", p.User.ID, ids)
	if e != nil {
		return source, ErrFoodUnavailable
	}
	seen := map[string]bool{}
	for rows.Next() {
		var binding MealMembership
		var raw []byte
		var meal MealMetadata
		if rows.Scan(&binding.EntryID, &binding.MealID, &raw) != nil || json.Unmarshal(raw, &meal) != nil {
			rows.Close()
			return source, ErrFoodUnavailable
		}
		source.Memberships = append(source.Memberships, binding)
		if !seen[meal.ID] {
			source.Meals = append(source.Meals, meal)
			seen[meal.ID] = true
		}
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return source, ErrFoodUnavailable
	}
	return source, nil
}

// replayMeal checks current tombstones/revisions, so a late create retry never
// presents an edited/deleted meal as freshly recorded. It never inserts records.
func replayMeal(ctx context.Context, tx pgx.Tx, user, op string, keyHash, requestHash []byte) (ConfirmedMeal, bool, error) {
	var priorHash, raw []byte
	e := tx.QueryRow(ctx, `SELECT request_hash,response_body FROM trainforge_v1.idempotency_records WHERE user_id=$1 AND operation=$2 AND key_hash=$3 AND expires_at>clock_timestamp()`, user, op, keyHash).Scan(&priorHash, &raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return ConfirmedMeal{}, false, nil
	}
	if e != nil {
		return ConfirmedMeal{}, false, ErrFoodUnavailable
	}
	if !equal(priorHash, requestHash) {
		return ConfirmedMeal{}, true, ErrEntryConflict
	}
	var prior ConfirmedMeal
	if json.Unmarshal(raw, &prior) != nil {
		return prior, true, ErrFoodUnavailable
	}
	current, e := readMeal(ctx, tx, user, prior.Meal.ID)
	if e != nil {
		return prior, true, e
	}
	left, _ := json.Marshal(prior)
	right, _ := json.Marshal(current)
	if !equal(left, right) {
		return prior, true, ErrEntryConflict
	}
	return prior, true, nil
}
func saveMealReplay(ctx context.Context, tx pgx.Tx, user, op string, keyHash, requestHash []byte, result ConfirmedMeal, status int) error {
	raw, e := json.Marshal(result)
	if e != nil {
		return ErrFoodUnavailable
	}
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,response_body,expires_at)
 VALUES($1,$2,$3,$4,$5,$6,clock_timestamp()+interval '24 hours') ON CONFLICT(user_id,operation,key_hash) DO UPDATE SET request_hash=EXCLUDED.request_hash,response_status=EXCLUDED.response_status,response_body=EXCLUDED.response_body,expires_at=EXCLUDED.expires_at`, user, op, keyHash, requestHash, status, raw)
	if e != nil {
		return ErrFoodUnavailable
	}
	return nil
}
func insertMealEntry(ctx context.Context, tx pgx.Tx, p auth.Principal, in EntryInput) (string, error) {
	food, origin, e := selectedFood(ctx, tx, p, in.FoodID, in.FoodVersion)
	if e != nil {
		return "", e
	}
	calc, e := scaled(food, in, origin)
	if e != nil {
		return "", e
	}
	id := newID()
	occurred, _ := time.Parse(time.RFC3339, in.OccurredAt)
	raw, _ := json.Marshal(calc)
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation) VALUES($1,$2,$3,$4,$5::numeric,$6,$7,$8,$9)`, id, p.User.ID, in.FoodID, in.FoodVersion, in.Quantity, in.Unit, occurred, in.Timezone, raw)
	if e != nil {
		return "", ErrFoodUnavailable
	}
	return id, nil
}
func (s MealStore) CreateMeal(ctx context.Context, p auth.Principal, c NewMealCommand, key string) (ConfirmedMeal, error) {
	if !mealPrincipalValid(p) {
		return ConfirmedMeal{}, auth.ErrInvalid
	}
	if c.Validate() != nil || !uuidPattern.MatchString(key) {
		return ConfirmedMeal{}, ErrFoodQuery
	}
	tx, e := s.Nutrition.begin(ctx, p, true)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	defer tx.Rollback(ctx)
	body, _ := json.Marshal(c)
	keyHash, requestHash := digest([]byte(key)), digest(body)
	prior, found, e := replayMeal(ctx, tx, p.User.ID, "create-meal", keyHash, requestHash)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	if found {
		if tx.Commit(ctx) != nil {
			return ConfirmedMeal{}, ErrFoodUnavailable
		}
		return prior, nil
	}
	ids := []string{}
	for _, item := range c.Items {
		id, e := insertMealEntry(ctx, tx, p, item)
		if e != nil {
			return ConfirmedMeal{}, e
		}
		ids = append(ids, id)
	}
	id := newID()
	when, _ := time.Parse(time.RFC3339, c.OccurredAt)
	_, e = tx.Exec(ctx, `SELECT trainforge_v1.confirm_meal_group($1,$2,$3,$4,0,$5,$6,$7,$8::text[]::uuid[])`, p.User.ID, p.FamilyID, p.AccessHash, id, c.Title, when, c.Timezone, ids)
	if e != nil {
		return ConfirmedMeal{}, mealDatabaseError(e)
	}
	saved, e := readMeal(ctx, tx, p.User.ID, id)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	if !confirmedMealMatches(saved, c) {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	if saveMealReplay(ctx, tx, p.User.ID, "create-meal", keyHash, requestHash, saved, 201) != nil || tx.Commit(ctx) != nil {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	return saved, nil
}
func (s MealStore) ChangeMeal(ctx context.Context, p auth.Principal, id, key string, edit *EditMealCommand, remove *DeleteMealCommand) (ConfirmedMeal, error) {
	if !mealPrincipalValid(p) {
		return ConfirmedMeal{}, auth.ErrInvalid
	}
	if !uuidPattern.MatchString(id) || !uuidPattern.MatchString(key) || (edit == nil) == (remove == nil) {
		return ConfirmedMeal{}, ErrFoodQuery
	}
	op := "edit-meal:" + id
	var command any = edit
	if edit != nil {
		if edit.Validate() != nil {
			return ConfirmedMeal{}, ErrFoodQuery
		}
	} else {
		if !remove.Reviewed || remove.Revision < 1 || remove.Revision >= 2147483647 {
			return ConfirmedMeal{}, ErrFoodQuery
		}
		op = "delete-meal:" + id
		command = remove
	}
	tx, e := s.Nutrition.begin(ctx, p, true)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	defer tx.Rollback(ctx)
	body, _ := json.Marshal(command)
	keyHash, requestHash := digest([]byte(key)), digest(body)
	prior, found, e := replayMeal(ctx, tx, p.User.ID, op, keyHash, requestHash)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	if found {
		if tx.Commit(ctx) != nil {
			return ConfirmedMeal{}, ErrFoodUnavailable
		}
		return prior, nil
	}
	if edit != nil {
		when, _ := time.Parse(time.RFC3339, edit.OccurredAt)
		_, e = tx.Exec(ctx, `SELECT trainforge_v1.confirm_meal_group($1,$2,$3,$4,$5,$6,$7,$8,NULL)`, p.User.ID, p.FamilyID, p.AccessHash, id, edit.Revision, edit.Title, when, edit.Timezone)
	} else {
		_, e = tx.Exec(ctx, `SELECT trainforge_v1.delete_meal_group($1,$2,$3,$4,$5)`, p.User.ID, p.FamilyID, p.AccessHash, id, remove.Revision)
	}
	if e != nil {
		return ConfirmedMeal{}, mealDatabaseError(e)
	}
	saved, e := readMeal(ctx, tx, p.User.ID, id)
	if e != nil {
		return ConfirmedMeal{}, e
	}
	if saveMealReplay(ctx, tx, p.User.ID, op, keyHash, requestHash, saved, 200) != nil || tx.Commit(ctx) != nil {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	return saved, nil
}
