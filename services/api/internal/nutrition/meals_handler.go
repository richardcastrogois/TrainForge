package nutrition

import (
	"net/http"
	"net/url"
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/platform/httpapi"
)

type MealDayResponse struct {
	Date        string           `json:"date"`
	Timezone    string           `json:"timezone"`
	Diary       MealDiary        `json:"diary"`
	NameCatalog *FoodNameCatalog `json:"nameCatalog,omitempty"`
}

func mealReadQuery(r *http.Request, day bool) (url.Values, error) {
	q, e := url.ParseQuery(r.URL.RawQuery)
	if e != nil {
		return nil, ErrFoodQuery
	}
	for k, v := range q {
		if len(v) != 1 || (k != "locale" && (!day || (k != "date" && k != "timezone"))) {
			return nil, ErrFoodQuery
		}
	}
	if locale, ok := q["locale"]; ok && !foodNameLocale(locale[0]) {
		return nil, ErrFoodQuery
	}
	if day {
		if _, _, e := dayBounds(q.Get("date"), q.Get("timezone")); e != nil {
			return nil, e
		}
	}
	return q, nil
}
func mealWriteBody(w http.ResponseWriter, r *http.Request, target any) (string, bool) {
	if !noEntryQuery(w, r) {
		return "", false
	}
	if r.Method != "POST" && !uuidPattern.MatchString(r.PathValue("id")) {
		entryFailure(w, r, ErrFoodQuery)
		return "", false
	}
	keys := r.Header.Values("Idempotency-Key")
	if len(keys) != 1 || !uuidPattern.MatchString(keys[0]) {
		entryFailure(w, r, ErrFoodQuery)
		return "", false
	}
	_, ok := entryBodyLimit(w, r, target, 64<<10)
	return keys[0], ok
}

// CreateMeal confirms the group and all new intakes atomically. It does not infer portions.
// @Summary Record one reviewed meal with 1..32 explicit new consumption items
// @Tags meals
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param Idempotency-Key header string true "UUID stable across retries; 24-hour retention"
// @Param body body NewMealCommand true "reviewed=true; quantities/versions/times per item; max64KiB; microsecond timestamp precision"
// @Success 201 {object} ConfirmedMeal
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/meals [post]
func (h *EntryHandler) CreateMeal(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	var c NewMealCommand
	key, ok := mealWriteBody(w, r, &c)
	if !ok {
		return
	}
	result, e := (MealCreateService{Repository: MealStore{Nutrition: h.Store}}).Create(r.Context(), p, c, key)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	httpapi.JSON(w, 201, result)
}

// MealDay serves two views referencing the same original intake identities.
// @Summary Read own meal/food diary for one day and timezone
// @Tags meals
// @Security BearerAuth
// @Produce json
// @Param date query string true "YYYY-MM-DD"
// @Param timezone query string true "UTC, IANA or offset; no server timezone default"
// @Param locale query string false "pt-BR,pt-PT,en,es; optional reviewed display names"
// @Success 200 {object} MealDayResponse
// @Failure 400,401,409,429,503 {object} httpapi.Problem
// @Router /api/v1/me/meal-diary [get]
func (h *EntryHandler) MealDay(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, e := mealReadQuery(r, true)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	diary, e := (MealDiaryService{Repository: MealStore{Nutrition: h.Store}}).Day(r.Context(), p, q.Get("date"), q.Get("timezone"))
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	result := MealDayResponse{Date: q.Get("date"), Timezone: q.Get("timezone"), Diary: diary}
	if locale := q.Get("locale"); locale != "" {
		if h.Names == nil {
			entryFailure(w, r, ErrFoodUnavailable)
			return
		}
		entries, catalog, e := h.Names.ProjectEntries(r.Context(), diary.Entries, locale, "")
		if e != nil {
			entryFailure(w, r, e)
			return
		}
		result.Diary.Entries = entries
		result.NameCatalog = &catalog
	}
	httpapi.JSON(w, 200, result)
}

// Meal returns owned metadata with the original intakes, including explicit tombstones.
// @Summary Read own meal and intake revisions
// @Tags meals
// @Security BearerAuth
// @Produce json
// @Param id path string true "Meal UUID; another owner returns404"
// @Param locale query string false "pt-BR,pt-PT,en,es; display only"
// @Success 200 {object} ConfirmedMeal
// @Failure 400,401,404,409,429,503 {object} httpapi.Problem
// @Router /api/v1/me/meals/{id} [get]
func (h *EntryHandler) Meal(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, e := mealReadQuery(r, false)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	result, e := (MealStore{Nutrition: h.Store}).Meal(r.Context(), p, r.PathValue("id"))
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	if locale := q.Get("locale"); locale != "" {
		if h.Names == nil {
			entryFailure(w, r, ErrFoodUnavailable)
			return
		}
		result.Entries, _, e = h.Names.ProjectEntries(r.Context(), result.Entries, locale, "")
		if e != nil {
			entryFailure(w, r, e)
			return
		}
	}
	httpapi.JSON(w, 200, result)
}

// EditMeal changes grouping metadata; each intake retains its own time and quantity.
// @Summary Correct own meal title/time without rewriting the intakes
// @Tags meals
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Meal UUID"
// @Param Idempotency-Key header string true "Stable retry UUID"
// @Param body body EditMealCommand true "Expected grouping revision and reviewed=true"
// @Success 200 {object} ConfirmedMeal
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/meals/{id} [patch]
func (h *EntryHandler) EditMeal(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	var c EditMealCommand
	key, ok := mealWriteBody(w, r, &c)
	if !ok {
		return
	}
	result, e := (MealStore{Nutrition: h.Store}).ChangeMeal(r.Context(), p, r.PathValue("id"), key, &c, nil)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, result)
}

// DeleteMeal tombstones the meal and remaining active items in one transaction.
// @Summary Delete own whole meal and its remaining intakes
// @Tags meals
// @Security BearerAuth
// @Accept json
// @Produce json
// @Param id path string true "Meal UUID"
// @Param Idempotency-Key header string true "Stable retry UUID"
// @Param body body DeleteMealCommand true "Expected grouping revision and reviewed=true"
// @Success 200 {object} ConfirmedMeal
// @Failure 400,401,404,409,413,415,429,503 {object} httpapi.Problem
// @Router /api/v1/me/meals/{id} [delete]
func (h *EntryHandler) DeleteMeal(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	var c DeleteMealCommand
	key, ok := mealWriteBody(w, r, &c)
	if !ok {
		return
	}
	result, e := (MealStore{Nutrition: h.Store}).ChangeMeal(r.Context(), p, r.PathValue("id"), key, nil, &c)
	if e != nil {
		entryFailure(w, r, e)
		return
	}
	httpapi.JSON(w, 200, result)
}
