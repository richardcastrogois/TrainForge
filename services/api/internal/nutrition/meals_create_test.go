package nutrition

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"testing"
	"trainforge.local/api/internal/auth"
)

const mealCreateKey = "88888888-8888-4888-8888-888888888888"

func newMealFixture() NewMealCommand {
	return NewMealCommand{Title: "", OccurredAt: "2026-10-23T23:30:00-03:00", Timezone: "America/Sao_Paulo", Reviewed: true, Items: []EntryInput{exampleEntry()}}
}
func mealConfirmationFixture(command NewMealCommand) ConfirmedMeal {
	result := ConfirmedMeal{Meal: MealMetadata{ID: mealFixtureID, Title: command.Title, OccurredAt: "2026-10-24T02:30:00Z", Timezone: command.Timezone, Revision: 1, TotalActiveItems: len(command.Items)}, Entries: []Entry{}}
	for i, item := range command.Items {
		id := []string{"11111111-1111-4111-8111-111111111111", "22222222-2222-4222-8222-222222222222"}[i]
		result.Entries = append(result.Entries, Entry{ID: id, FoodID: item.FoodID, FoodVersion: item.FoodVersion, Quantity: item.Quantity, Unit: item.Unit, OccurredAt: item.OccurredAt, Timezone: item.Timezone, Calculation: Calculation{Algorithm: "source-rational-v1", Food: FoodSummary{ID: item.FoodID, VersionID: item.FoodVersion}, Revision: 1, QuantityEvidence: item.QuantityEvidence, Preparation: item.Preparation, Nutrients: []ScaledCell{}, Changes: []EntryChange{}}})
	}
	return result
}

type mealCreateFixture struct {
	calls       int
	actor       auth.Principal
	command     NewMealCommand
	key         string
	failure     error
	mutate      func(*ConfirmedMeal)
	mutateInput bool
}

func (r *mealCreateFixture) CreateMeal(_ context.Context, p auth.Principal, c NewMealCommand, key string) (ConfirmedMeal, error) {
	r.calls++
	r.actor = p
	r.command = c
	r.key = key
	if r.failure != nil {
		return ConfirmedMeal{}, r.failure
	}
	saved := mealConfirmationFixture(c)
	if r.mutateInput {
		c.Items[0].Quantity = "999"
	}
	if r.mutate != nil {
		r.mutate(&saved)
	}
	return saved, nil
}
func TestMealCreationRequiresReviewedExplicitIntakesBeforeRepository(t *testing.T) {
	cases := map[string]func(*NewMealCommand){
		"unreviewed":           func(c *NewMealCommand) { c.Reviewed = false },
		"empty":                func(c *NewMealCommand) { c.Items = []EntryInput{} },
		"nil":                  func(c *NewMealCommand) { c.Items = nil },
		"too_many":             func(c *NewMealCommand) { c.Items = make([]EntryInput, maxNewMealItems+1) },
		"title_controls":       func(c *NewMealCommand) { c.Title = "private\nlabel" },
		"title_limit":          func(c *NewMealCommand) { c.Title = strings.Repeat("a", 81) },
		"unknown_zone":         func(c *NewMealCommand) { c.Timezone = "Local" },
		"unknown_time":         func(c *NewMealCommand) { c.OccurredAt = "" },
		"existing_revision":    func(c *NewMealCommand) { c.Items[0].Revision = 1 },
		"guessed_quantity":     func(c *NewMealCommand) { c.Items[0].Quantity = "" },
		"unknown_evidence":     func(c *NewMealCommand) { c.Items[0].QuantityEvidence = "" },
		"bad_unit":             func(c *NewMealCommand) { c.Items[0].Unit = "portion" },
		"no_version":           func(c *NewMealCommand) { c.Items[0].FoodVersion = "" },
		"group_submicrosecond": func(c *NewMealCommand) { c.OccurredAt = "2026-10-27T12:00:00.123456789Z" },
		"item_submicrosecond":  func(c *NewMealCommand) { c.Items[0].OccurredAt = "2026-10-27T12:00:00.123456789Z" },
	}
	for name, change := range cases {
		t.Run(name, func(t *testing.T) {
			c := newMealFixture()
			change(&c)
			r := &mealCreateFixture{}
			if _, e := (MealCreateService{r}).Create(context.Background(), mealActor(), c, mealCreateKey); !errors.Is(e, ErrFoodQuery) || r.calls != 0 {
				t.Fatal("invalid or unreviewed intake reached repository", e)
			}
		})
	}
}
func TestMealCreationPreservesActorIntentAndDoesNotMergeEqualFoods(t *testing.T) {
	c := newMealFixture()
	c.Items = append(c.Items, c.Items[0])
	r := &mealCreateFixture{mutateInput: true}
	saved, e := (MealCreateService{r}).Create(context.Background(), mealActor(), c, mealCreateKey)
	if e != nil || len(saved.Entries) != 2 || saved.Entries[0].ID == saved.Entries[1].ID || c.Items[0].Quantity != "25.5" || r.key != mealCreateKey || !reflect.DeepEqual(r.actor, mealActor()) {
		t.Fatal("explicit items, caller or intent changed", e)
	}
}
func TestMealCreationRejectsIncompleteOrSilentlyChangedConfirmation(t *testing.T) {
	cases := map[string]func(*ConfirmedMeal){
		"partial_entries":            func(v *ConfirmedMeal) { v.Entries = []Entry{} },
		"inferred_title":             func(v *ConfirmedMeal) { v.Meal.Title = "Lunch" },
		"wrong_revision":             func(v *ConfirmedMeal) { v.Meal.Revision = 2 },
		"wrong_count":                func(v *ConfirmedMeal) { v.Meal.TotalActiveItems = 2 },
		"wrong_time":                 func(v *ConfirmedMeal) { v.Meal.OccurredAt = "2026-10-25T12:00:00Z" },
		"different_food":             func(v *ConfirmedMeal) { v.Entries[0].FoodID = "own:33333333-3333-4333-8333-333333333333" },
		"different_version":          func(v *ConfirmedMeal) { v.Entries[0].FoodVersion = strings.Repeat("b", 64) },
		"changed_quantity":           func(v *ConfirmedMeal) { v.Entries[0].Quantity = "0" },
		"changed_evidence":           func(v *ConfirmedMeal) { v.Entries[0].Calculation.QuantityEvidence = "measured" },
		"changed_algorithm":          func(v *ConfirmedMeal) { v.Entries[0].Calculation.Algorithm = "guessed" },
		"changed_calculation_origin": func(v *ConfirmedMeal) { v.Entries[0].Calculation.Food.ID = "other" },
		"already_deleted":            func(v *ConfirmedMeal) { v.Entries[0].DeletedAt = ptr("2026-10-25T12:00:00Z") },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			r := &mealCreateFixture{mutate: mutate}
			if _, e := (MealCreateService{r}).Create(context.Background(), mealActor(), newMealFixture(), mealCreateKey); !errors.Is(e, ErrFoodUnavailable) {
				t.Fatal("broken confirmation accepted", e)
			}
		})
	}
}
func TestMealCreationErrorBoundariesAndCancellation(t *testing.T) {
	r := &mealCreateFixture{}
	s := MealCreateService{r}
	c := newMealFixture()
	if _, e := s.Create(context.Background(), auth.Principal{}, c, mealCreateKey); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("invalid actor")
	}
	if _, e := s.Create(context.Background(), mealActor(), c, "forged"); !errors.Is(e, ErrFoodQuery) {
		t.Fatal("invalid retry key")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, e := s.Create(ctx, mealActor(), c, mealCreateKey); !errors.Is(e, context.Canceled) || r.calls != 0 {
		t.Fatal("canceled write reached repository")
	}
	for _, failure := range []error{auth.ErrInvalid, ErrEntryConflict, ErrFoodQuery, context.DeadlineExceeded} {
		r.failure = failure
		if _, e := s.Create(context.Background(), mealActor(), c, mealCreateKey); !errors.Is(e, failure) {
			t.Fatal("known failure lost")
		}
	}
	r.failure = errors.New("private database error")
	if _, e := s.Create(context.Background(), mealActor(), c, mealCreateKey); !errors.Is(e, ErrFoodUnavailable) {
		t.Fatal("internal detail escaped")
	}
	if _, e := (MealCreateService{}).Create(context.Background(), mealActor(), c, mealCreateKey); !errors.Is(e, ErrFoodUnavailable) {
		t.Fatal("nil writer")
	}
}
