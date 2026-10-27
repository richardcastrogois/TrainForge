package nutrition

import (
	"context"
	"net/http"
	"net/url"
	"trainforge.local/api/internal/auth"
)

// EntryFoodDisplay is read metadata; never persist it in calculation or a write response.
type EntryFoodDisplay struct {
	FoodID       string               `json:"foodId"`
	FoodVersion  string               `json:"foodVersion"`
	NameCatalog  FoodNameCatalog      `json:"nameCatalog"`
	ReviewedName *ReviewedNameDisplay `json:"reviewedName,omitempty"`
}
type EntryNameProjector interface {
	ProjectEntries(context.Context, []Entry, string, string) ([]Entry, FoodNameCatalog, error)
}

// ProjectEntries resolves a page in one revision snapshot and one batched SQL query.
// Call after the private transaction ends: a pool with one connection works.
func (p FoodPostgres) ProjectEntries(ctx context.Context, entries []Entry, locale, expected string) ([]Entry, FoodNameCatalog, error) {
	if len(entries) > 20 {
		return nil, FoodNameCatalog{}, ErrFoodQuery
	}
	tx, catalog, err := p.nameSnapshot(ctx, locale, expected)
	if err != nil {
		return nil, catalog, err
	}
	defer tx.Rollback(ctx)
	targets := []FoodNameTarget{}
	seen := map[FoodNameTarget]bool{}
	for _, entry := range entries {
		food := entry.Calculation.Food
		if food.ID != entry.FoodID || food.VersionID != entry.FoodVersion {
			return nil, catalog, ErrFoodUnavailable
		}
		if food.SourceID == "personal" || privateFoodPattern.MatchString(entry.FoodID) {
			continue
		}
		target := FoodNameTarget{entry.FoodID, entry.FoodVersion}
		if !seen[target] {
			targets = append(targets, target)
			seen[target] = true
		}
	}
	names, err := resolveFoodNames(ctx, tx, targets, locale)
	if err != nil {
		return nil, catalog, err
	}
	result := append([]Entry{}, entries...)
	for i := range result {
		entry := &result[i]
		entry.FoodDisplay = &EntryFoodDisplay{FoodID: entry.FoodID, FoodVersion: entry.FoodVersion, NameCatalog: catalog}
		if name, ok := names[FoodNameTarget{entry.FoodID, entry.FoodVersion}]; ok {
			entry.FoodDisplay.ReviewedName = &name
		}
	}
	if tx.Commit(ctx) != nil {
		return nil, catalog, ErrFoodUnavailable
	}
	return result, catalog, nil
}

// Entry reads one active record owned by the live authenticated account.
func (s NutritionStore) Entry(ctx context.Context, p auth.Principal, id string) (Entry, error) {
	if !uuidPattern.MatchString(id) {
		return Entry{}, ErrFoodQuery
	}
	tx, err := s.begin(ctx, p, false)
	if err != nil {
		return Entry{}, err
	}
	defer tx.Rollback(ctx)
	entry, err := readEntry(ctx, tx, p.User.ID, id)
	if err != nil {
		return Entry{}, err
	}
	if entry.DeletedAt != nil {
		return Entry{}, ErrFoodMissing
	}
	if tx.Commit(ctx) != nil {
		return Entry{}, ErrFoodUnavailable
	}
	return entry, nil
}

// Entry returns an owned immutable calculation with optional current name metadata.
// @Summary Read own consumption and current reviewed display name
// @Tags nutrition
// @Security BearerAuth
// @Produce json
// @Param id path string true "Entry UUID; other owners and deleted records return 404"
// @Param locale query string false "pt-BR, pt-PT, en or es; display metadata only"
// @Success 200 {object} Entry
// @Failure 400,401,404,409,429,503 {object} httpapi.Problem
// @Router /api/v1/me/food-entries/{id} [get]
func (h *EntryHandler) Entry(w http.ResponseWriter, r *http.Request, p auth.Principal) {
	q, err := url.ParseQuery(r.URL.RawQuery)
	if err != nil {
		entryFailure(w, r, ErrFoodQuery)
		return
	}
	for k, v := range q {
		if k != "locale" || len(v) != 1 || !foodNameLocale(v[0]) {
			entryFailure(w, r, ErrFoodQuery)
			return
		}
	}
	entry, err := h.Store.Entry(r.Context(), p, r.PathValue("id"))
	if err != nil {
		entryFailure(w, r, err)
		return
	}
	if locale := q.Get("locale"); locale != "" {
		if h.Names == nil {
			entryFailure(w, r, ErrFoodUnavailable)
			return
		}
		items, _, e := h.Names.ProjectEntries(r.Context(), []Entry{entry}, locale, "")
		if e != nil {
			entryFailure(w, r, e)
			return
		}
		entry = items[0]
	}
	entryJSON(w, entry)
}
