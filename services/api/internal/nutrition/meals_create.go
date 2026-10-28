package nutrition

import (
	"context"
	"errors"
	"math/big"
	"time"
	"trainforge.local/api/internal/auth"
)

// NewMealCommand creates new intakes together; it never attaches existing legacy
// entries by inference. The SQL adapter must write all or none.
type NewMealCommand struct {
	Title      string       `json:"title"`
	OccurredAt string       `json:"occurredAt"`
	Timezone   string       `json:"timezone"`
	Reviewed   bool         `json:"reviewed"`
	Items      []EntryInput `json:"items"`
}
type ConfirmedMeal struct {
	Meal      MealMetadata `json:"meal"`
	Entries   []Entry      `json:"entries"`
	DeletedAt *string      `json:"deletedAt" extensions:"x-nullable"`
}
type MealCreateRepository interface {
	CreateMeal(context.Context, auth.Principal, NewMealCommand, string) (ConfirmedMeal, error)
}
type MealCreateService struct{ Repository MealCreateRepository }

const maxNewMealItems = 32 // Technical input bound, not a recommended meal size.
func mealPrincipalValid(p auth.Principal) bool {
	return uuidPattern.MatchString(p.User.ID) && uuidPattern.MatchString(p.FamilyID) && len(p.AccessHash) == 32
}
func (c NewMealCommand) Validate() error {
	if !c.Reviewed || !textValid(c.Title, 0, 80) || c.Items == nil || len(c.Items) < 1 || len(c.Items) > maxNewMealItems {
		return ErrFoodQuery
	}
	when, e := time.Parse(time.RFC3339, c.OccurredAt)
	if e != nil || when.Year() < 1900 || when.Year() > 2100 || when.Nanosecond()%1000 != 0 {
		return ErrFoodQuery
	}
	if _, e = zone(c.Timezone); e != nil {
		return e
	}
	for _, item := range c.Items {
		if item.Revision != 0 || validateEntry(item) != nil {
			return ErrFoodQuery
		}
		when, _ := time.Parse(time.RFC3339, item.OccurredAt)
		if when.Nanosecond()%1000 != 0 {
			return ErrFoodQuery
		}
	}
	return nil
}
func sameMealTime(a, b string) bool {
	left, e := time.Parse(time.RFC3339, a)
	if e != nil {
		return false
	}
	right, e := time.Parse(time.RFC3339, b)
	return e == nil && left.Equal(right)
}
func confirmedMealMatches(saved ConfirmedMeal, command NewMealCommand) bool {
	meal := saved.Meal
	if !mealMetadataValid(meal) || saved.DeletedAt != nil || meal.Revision != 1 || meal.Title != command.Title || meal.Timezone != command.Timezone || !sameMealTime(meal.OccurredAt, command.OccurredAt) || meal.TotalActiveItems != len(command.Items) || len(saved.Entries) != len(command.Items) {
		return false
	}
	seen := map[string]bool{}
	for i, item := range command.Items {
		entry := saved.Entries[i]
		c := entry.Calculation
		if !uuidPattern.MatchString(entry.ID) || seen[entry.ID] || entry.DeletedAt != nil || entry.FoodID != item.FoodID || entry.FoodVersion != item.FoodVersion || !sameMealQuantity(entry.Quantity, item.Quantity) || entry.Unit != item.Unit || entry.Timezone != item.Timezone || !sameMealTime(entry.OccurredAt, item.OccurredAt) || c.Algorithm != "source-rational-v1" || len(c.Changes) != 0 || c.Revision != 1 || c.Preparation != item.Preparation || c.QuantityEvidence != item.QuantityEvidence || c.Food.ID != item.FoodID || c.Food.VersionID != item.FoodVersion {
			return false
		}
		seen[entry.ID] = true
	}
	return true
}
func sameMealQuantity(a, b string) bool {
	if !quantity(a, true) || !quantity(b, true) {
		return false
	}
	left, _ := new(big.Rat).SetString(a)
	right, _ := new(big.Rat).SetString(b)
	return left.Cmp(right) == 0
}
func (s MealCreateService) Create(ctx context.Context, p auth.Principal, command NewMealCommand, key string) (ConfirmedMeal, error) {
	if e := ctx.Err(); e != nil {
		return ConfirmedMeal{}, e
	}
	if !mealPrincipalValid(p) {
		return ConfirmedMeal{}, auth.ErrInvalid
	}
	if !uuidPattern.MatchString(key) || command.Validate() != nil {
		return ConfirmedMeal{}, ErrFoodQuery
	}
	if s.Repository == nil {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	// Keep caller values independent even if a repository works on its own slice.
	copyCommand := command
	copyCommand.Items = append([]EntryInput{}, command.Items...)
	saved, e := s.Repository.CreateMeal(ctx, p, copyCommand, key)
	if e != nil {
		if errors.Is(e, auth.ErrInvalid) || errors.Is(e, ErrEntryConflict) || errors.Is(e, ErrFoodQuery) || errors.Is(e, ErrFoodMissing) || errors.Is(e, context.Canceled) || errors.Is(e, context.DeadlineExceeded) {
			return ConfirmedMeal{}, e
		}
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	if e := ctx.Err(); e != nil {
		return ConfirmedMeal{}, e
	}
	if !confirmedMealMatches(saved, command) {
		return ConfirmedMeal{}, ErrFoodUnavailable
	}
	return saved, nil
}
