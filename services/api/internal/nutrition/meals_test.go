package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"
	"trainforge.local/api/internal/auth"
)

const mealFixtureID = "99999999-9999-4999-8999-999999999999"

func mealEntry(t *testing.T, id, when string) Entry {
	t.Helper()
	in := exampleEntry()
	in.OccurredAt = when
	food := FoodDetail{Nutrients: []FoodCell{
		{Column: "fixture-fiber", Name: "Isolated fiber", State: "numeric", Value: ptr("2"), Unit: ptr("g"), BasisQuantity: ptr("100"), BasisUnit: ptr("g"), Scaling: true},
		{Column: "fixture-unknown", Name: "Isolated unknown", State: "missing", Unit: ptr("mg")},
	}}
	calculation, e := scaled(food, in, "isolated-fixture")
	if e != nil {
		t.Fatal(e)
	}
	return Entry{ID: id, FoodID: in.FoodID, FoodVersion: in.FoodVersion, Quantity: in.Quantity, Unit: in.Unit, OccurredAt: in.OccurredAt, Timezone: in.Timezone, Calculation: calculation}
}
func mealSource(t *testing.T) MealDaySource {
	entries := []Entry{mealEntry(t, "11111111-1111-4111-8111-111111111111", "2026-10-23T12:00:00Z"), mealEntry(t, "22222222-2222-4222-8222-222222222222", "2026-10-23T12:00:00Z"), mealEntry(t, "33333333-3333-4333-8333-333333333333", "2026-10-23T15:00:00Z")}
	return MealDaySource{Entries: entries, Meals: []MealMetadata{{ID: mealFixtureID, Title: "", OccurredAt: "2026-10-22T23:30:00Z", Timezone: "UTC", Revision: 2, TotalActiveItems: 3}}, Memberships: []MealMembership{{entries[0].ID, mealFixtureID}, {entries[1].ID, mealFixtureID}}, Complete: true}
}
func TestMealDiarySharesEntryIdentitiesWithoutDoubleCounting(t *testing.T) {
	source := mealSource(t)
	before, _ := json.Marshal(source)
	got, e := mealDiary(source, "2026-10-23", "UTC")
	if e != nil {
		t.Fatal(e)
	}
	if len(got.Entries) != 3 || len(got.Meals) != 1 || len(got.Meals[0].EntryIDs) != 2 || len(got.UngroupedEntryIDs) != 1 || got.Totals.Entries != 3 {
		t.Fatal("grouping changed entry cardinality")
	}
	group := got.Meals[0]
	if group.Meal.Title != "" || group.OtherActiveItems != 1 || group.Meal.OccurredAt != source.Meals[0].OccurredAt {
		t.Fatal("meal name/date or coverage invented")
	}
	if *got.Totals.Nutrients[0].Exact != "153/100" || *group.Totals.Nutrients[0].Exact != "51/50" {
		t.Fatal("calculation was counted twice or rescaled")
	}
	if got.Totals.Nutrients[1].Value != nil || got.Totals.Nutrients[1].Unknown != 3 || group.Totals.Nutrients[1].Unknown != 2 {
		t.Fatal("unknown became zero")
	}
	if got.Entries[0].ID != source.Entries[2].ID || group.EntryIDs[0] != source.Entries[1].ID {
		t.Fatal("diary ordering not deterministic")
	}
	// Correction replaces a record; a returned projection must not mutate source.
	got.Entries[0].Calculation.Nutrients[0].Name = "changed"
	*got.Entries[0].Calculation.Nutrients[0].Unit = "kg"
	after, _ := json.Marshal(source)
	if string(before) != string(after) {
		t.Fatal("source snapshot rewritten")
	}
}
func TestMealDiaryLegacyEntriesRemainExplicitlyUngrouped(t *testing.T) {
	source := mealSource(t)
	source.Meals = []MealMetadata{}
	source.Memberships = []MealMembership{}
	got, e := mealDiary(source, "2026-10-23", "UTC")
	if e != nil || len(got.Meals) != 0 || len(got.UngroupedEntryIDs) != 3 {
		t.Fatal("legacy intake assigned an inferred meal", e)
	}
}
func TestMealDiaryIncompleteSnapshotSuppressesTotals(t *testing.T) {
	source := mealSource(t)
	source.Complete = false
	got, e := mealDiary(source, "2026-10-23", "UTC")
	if e != nil || got.Complete || got.Totals.Complete || len(got.Totals.Nutrients) != 0 || got.Meals[0].Totals.Complete || len(got.Meals[0].Totals.Nutrients) != 0 {
		t.Fatal("truncated view reported complete nutrition")
	}
}
func TestMealDiaryRejectsAmbiguousOrBrokenMemberships(t *testing.T) {
	cases := map[string]func(*MealDaySource){
		"missing_entries":            func(s *MealDaySource) { s.Entries = nil },
		"missing_meals":              func(s *MealDaySource) { s.Meals = nil },
		"missing_memberships":        func(s *MealDaySource) { s.Memberships = nil },
		"oversized":                  func(s *MealDaySource) { s.Entries = make([]Entry, maxMealDayEntries+1) },
		"duplicate_entry":            func(s *MealDaySource) { s.Entries[1].ID = s.Entries[0].ID },
		"deleted_entry":              func(s *MealDaySource) { s.Entries[0].DeletedAt = ptr("2026-10-23T16:00:00Z") },
		"foreign_day":                func(s *MealDaySource) { s.Entries[0].OccurredAt = "2026-10-24T00:00:00Z" },
		"bad_timestamp":              func(s *MealDaySource) { s.Entries[0].OccurredAt = "not-time" },
		"missing_entry_for_binding":  func(s *MealDaySource) { s.Memberships[0].EntryID = "44444444-4444-4444-8444-444444444444" },
		"missing_meal_for_binding":   func(s *MealDaySource) { s.Memberships[0].MealID = "44444444-4444-4444-8444-444444444444" },
		"two_bindings_for_one_entry": func(s *MealDaySource) { s.Memberships[1].EntryID = s.Memberships[0].EntryID },
		"unused_metadata": func(s *MealDaySource) {
			s.Meals = append(s.Meals, MealMetadata{ID: "44444444-4444-4444-8444-444444444444", Title: "isolated", OccurredAt: "2026-10-23T12:00:00Z", Timezone: "UTC", Revision: 1, TotalActiveItems: 1})
		},
		"duplicate_metadata":   func(s *MealDaySource) { s.Meals = append(s.Meals, s.Meals[0]) },
		"meal_count_too_small": func(s *MealDaySource) { s.Meals[0].TotalActiveItems = 1 },
		"invalid_revision":     func(s *MealDaySource) { s.Meals[0].Revision = 0 },
		"unfounded_label":      func(s *MealDaySource) { s.Meals[0].Title = " inferred " },
		"invalid_zone":         func(s *MealDaySource) { s.Meals[0].Timezone = "Local" },
	}
	for name, mutate := range cases {
		t.Run(name, func(t *testing.T) {
			source := mealSource(t)
			mutate(&source)
			if _, e := mealDiary(source, "2026-10-23", "UTC"); !errors.Is(e, ErrFoodUnavailable) {
				t.Fatal("broken projection accepted", e)
			}
		})
	}
}
func TestMealDiaryUsesEntryTimeForBothViewsAtLocalDayBoundary(t *testing.T) {
	source := mealSource(t)
	source.Entries = source.Entries[:1]
	source.Entries[0].OccurredAt = "2026-10-24T02:59:59Z"
	source.Memberships = source.Memberships[:1]
	if got, e := mealDiary(source, "2026-10-23", "America/Sao_Paulo"); e != nil || got.Totals.Entries != 1 {
		t.Fatal("entry's local day lost", e)
	}
	source.Entries[0].OccurredAt = "2026-10-24T03:00:00Z"
	if _, e := mealDiary(source, "2026-10-23", "America/Sao_Paulo"); e == nil {
		t.Fatal("next local day included")
	}
}
func TestMealDiaryOrderingDoesNotDependOnRepositoryOrder(t *testing.T) {
	source := mealSource(t)
	expected, e := mealDiary(source, "2026-10-23", "UTC")
	if e != nil {
		t.Fatal(e)
	}
	source.Entries[0], source.Entries[2] = source.Entries[2], source.Entries[0]
	source.Memberships[0], source.Memberships[1] = source.Memberships[1], source.Memberships[0]
	got, e := mealDiary(source, "2026-10-23", "UTC")
	if e != nil || !reflect.DeepEqual(expected, got) {
		t.Fatal("query enumeration changed view")
	}
}
func TestMealDiaryEmptyIsKnownAbsenceWithoutInventedNutrition(t *testing.T) {
	got, e := mealDiary(MealDaySource{Entries: []Entry{}, Meals: []MealMetadata{}, Memberships: []MealMembership{}, Complete: true}, "2026-10-23", "UTC")
	if e != nil || len(got.Meals) != 0 || len(got.Entries) != 0 || got.Totals.Entries != 0 || len(got.Totals.Nutrients) != 0 {
		t.Fatal("empty day invented a meal or nutrients", e)
	}
}

type mealReadFixture struct {
	calls     int
	principal auth.Principal
	source    MealDaySource
	err       error
}

func (r *mealReadFixture) ReadMealDay(_ context.Context, p auth.Principal, _, _ string) (MealDaySource, error) {
	r.calls++
	r.principal = p
	return r.source, r.err
}
func mealActor() auth.Principal {
	return auth.Principal{User: auth.User{ID: "11111111-1111-4111-8111-111111111111"}, FamilyID: "22222222-2222-4222-8222-222222222222", AccessHash: []byte(strings.Repeat("a", 32))}
}
func TestMealServiceRejectsInvalidContextBeforeCallingRepository(t *testing.T) {
	r := &mealReadFixture{source: mealSource(t)}
	s := MealDiaryService{r}
	if _, e := s.Day(context.Background(), auth.Principal{}, "2026-10-23", "UTC"); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("missing actor")
	}
	if _, e := s.Day(context.Background(), mealActor(), "2026-02-30", "UTC"); !errors.Is(e, ErrFoodQuery) {
		t.Fatal("invalid day")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, e := s.Day(ctx, mealActor(), "2026-10-23", "UTC"); !errors.Is(e, context.Canceled) {
		t.Fatal("canceled read")
	}
	if r.calls != 0 {
		t.Fatal("invalid input reached repository")
	}
	if _, e := (MealDiaryService{}).Day(context.Background(), mealActor(), "2026-10-23", "UTC"); !errors.Is(e, ErrFoodUnavailable) {
		t.Fatal("nil repository")
	}
}
func TestMealServicePreservesPrincipalAndSanitizesRepositoryErrors(t *testing.T) {
	r := &mealReadFixture{source: mealSource(t)}
	s := MealDiaryService{r}
	p := mealActor()
	if got, e := s.Day(context.Background(), p, "2026-10-23", "UTC"); e != nil || got.Totals.Entries != 3 || r.calls != 1 || !reflect.DeepEqual(p, r.principal) {
		t.Fatal("authenticated context changed", e)
	}
	r.err = auth.ErrInvalid
	if _, e := s.Day(context.Background(), p, "2026-10-23", "UTC"); !errors.Is(e, auth.ErrInvalid) {
		t.Fatal("revocation hidden")
	}
	r.err = errors.New("private database details")
	if _, e := s.Day(context.Background(), p, "2026-10-23", "UTC"); !errors.Is(e, ErrFoodUnavailable) {
		t.Fatal("database error leaked")
	}
}
