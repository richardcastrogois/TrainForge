package nutrition

import (
	"encoding/json"
	"sort"
	"time"
)

// MealMetadata is a user-declared grouping, not a nutritional prescription.
// TotalActiveItems includes members outside the selected day. A meal may cross midnight.
type MealMetadata struct {
	ID               string
	Title            string
	OccurredAt       string
	Timezone         string
	Revision         int
	TotalActiveItems int
}
type MealMembership struct{ EntryID, MealID string }

// MealDaySource must come from one authorized database snapshot. No SQL adapter
// is installed yet. Memberships cover exactly the entries returned for the day.
type MealDaySource struct {
	Entries     []Entry
	Meals       []MealMetadata
	Memberships []MealMembership
	Complete    bool
}
type MealGroup struct {
	Meal             MealMetadata
	EntryIDs         []string
	OtherActiveItems int
	Totals           NutritionTotals
}

// Entries are emitted once. Both UI views reference these IDs, so switching view
// cannot create a second intake or add its nutrients twice.
type MealDiary struct {
	Entries           []Entry
	Meals             []MealGroup
	UngroupedEntryIDs []string
	Totals            NutritionTotals
	Complete          bool
}

const maxMealDayEntries = 100 // Matches the current bounded daily summary.

func mealMetadataValid(v MealMetadata) bool {
	if !uuidPattern.MatchString(v.ID) || !textValid(v.Title, 0, 80) || v.Revision < 1 || v.Revision > 2147483647 || v.TotalActiveItems < 1 {
		return false
	}
	when, e := time.Parse(time.RFC3339, v.OccurredAt)
	if e != nil || when.Year() < 1900 || when.Year() > 2100 {
		return false
	}
	_, e = zone(v.Timezone)
	return e == nil
}

// mealDiary groups only explicit memberships. Legacy entries stay ungrouped;
// neither time proximity nor food names infer a meal, label or missing nutrient.
func mealDiary(source MealDaySource, day, tz string) (MealDiary, error) {
	result := MealDiary{Entries: []Entry{}, Meals: []MealGroup{}, UngroupedEntryIDs: []string{}, Complete: source.Complete}
	start, end, err := dayBounds(day, tz)
	if err != nil {
		return result, err
	}
	if source.Entries == nil || source.Meals == nil || source.Memberships == nil || len(source.Entries) > maxMealDayEntries || len(source.Meals) > len(source.Entries) || len(source.Memberships) > len(source.Entries) {
		return MealDiary{}, ErrFoodUnavailable
	}
	// A detached projection prevents a later client-side correction from mutating
	// the input snapshot shared by another presentation of the same diary.
	raw, err := json.Marshal(source.Entries)
	if err != nil || json.Unmarshal(raw, &result.Entries) != nil {
		return MealDiary{}, ErrFoodUnavailable
	}
	entries := make(map[string]Entry, len(result.Entries))
	times := make(map[string]time.Time, len(result.Entries))
	for _, entry := range result.Entries {
		when, e := time.Parse(time.RFC3339, entry.OccurredAt)
		if !uuidPattern.MatchString(entry.ID) || entry.DeletedAt != nil || e != nil || when.Before(start) || !when.Before(end) {
			return MealDiary{}, ErrFoodUnavailable
		}
		if _, exists := entries[entry.ID]; exists {
			return MealDiary{}, ErrFoodUnavailable
		}
		entries[entry.ID] = entry
		times[entry.ID] = when
	}
	sort.Slice(result.Entries, func(i, j int) bool {
		a, b := result.Entries[i], result.Entries[j]
		if !times[a.ID].Equal(times[b.ID]) {
			return times[a.ID].After(times[b.ID])
		}
		return a.ID > b.ID
	})
	metadata := make(map[string]MealMetadata, len(source.Meals))
	for _, meal := range source.Meals {
		if !mealMetadataValid(meal) {
			return MealDiary{}, ErrFoodUnavailable
		}
		if _, exists := metadata[meal.ID]; exists {
			return MealDiary{}, ErrFoodUnavailable
		}
		metadata[meal.ID] = meal
	}
	owners := make(map[string]string, len(source.Memberships))
	for _, binding := range source.Memberships {
		if _, exists := entries[binding.EntryID]; !exists {
			return MealDiary{}, ErrFoodUnavailable
		}
		if _, exists := metadata[binding.MealID]; !exists {
			return MealDiary{}, ErrFoodUnavailable
		}
		if _, exists := owners[binding.EntryID]; exists {
			return MealDiary{}, ErrFoodUnavailable
		}
		owners[binding.EntryID] = binding.MealID
	}
	groups := map[string]int{}
	groupEntries := map[string][]Entry{}
	for _, entry := range result.Entries {
		mealID, bound := owners[entry.ID]
		if !bound {
			result.UngroupedEntryIDs = append(result.UngroupedEntryIDs, entry.ID)
			continue
		}
		index, exists := groups[mealID]
		if !exists {
			index = len(result.Meals)
			groups[mealID] = index
			result.Meals = append(result.Meals, MealGroup{Meal: metadata[mealID], EntryIDs: []string{}})
		}
		result.Meals[index].EntryIDs = append(result.Meals[index].EntryIDs, entry.ID)
		groupEntries[mealID] = append(groupEntries[mealID], entry)
	}
	if len(groups) != len(metadata) {
		return MealDiary{}, ErrFoodUnavailable
	}
	for i := range result.Meals {
		group := &result.Meals[i]
		group.OtherActiveItems = group.Meal.TotalActiveItems - len(group.EntryIDs)
		if group.OtherActiveItems < 0 {
			return MealDiary{}, ErrFoodUnavailable
		}
		group.Totals = totals(groupEntries[group.Meal.ID], source.Complete)
	}
	result.Totals = totals(result.Entries, source.Complete)
	return result, nil
}
