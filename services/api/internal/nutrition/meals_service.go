package nutrition

import (
	"context"
	"errors"
	"trainforge.local/api/internal/auth"
)

// MealDayRepository must revalidate the live credential and return only this
// principal's active entries/memberships/metadata in a single bounded snapshot.
// A syntactically valid Principal here does not authenticate a database read.
type MealDayRepository interface {
	ReadMealDay(context.Context, auth.Principal, string, string) (MealDaySource, error)
}
type MealDiaryService struct{ Repository MealDayRepository }

func (s MealDiaryService) Day(ctx context.Context, p auth.Principal, day, tz string) (MealDiary, error) {
	if err := ctx.Err(); err != nil {
		return MealDiary{}, err
	}
	if !mealPrincipalValid(p) {
		return MealDiary{}, auth.ErrInvalid
	}
	if _, _, err := dayBounds(day, tz); err != nil {
		return MealDiary{}, err
	}
	if s.Repository == nil {
		return MealDiary{}, ErrFoodUnavailable
	}
	source, err := s.Repository.ReadMealDay(ctx, p, day, tz)
	if err != nil {
		if errors.Is(err, auth.ErrInvalid) || errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return MealDiary{}, err
		}
		return MealDiary{}, ErrFoodUnavailable
	}
	if err := ctx.Err(); err != nil {
		return MealDiary{}, err
	}
	return mealDiary(source, day, tz)
}
