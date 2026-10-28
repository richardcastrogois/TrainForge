package nutrition

import "time"

// Group metadata has its own revision; intakes keep independent quantities, times and revisions.
type EditMealCommand struct {
	Revision   int    `json:"revision"`
	Reviewed   bool   `json:"reviewed"`
	Title      string `json:"title"`
	OccurredAt string `json:"occurredAt"`
	Timezone   string `json:"timezone"`
}
type DeleteMealCommand struct {
	Revision int  `json:"revision"`
	Reviewed bool `json:"reviewed"`
}

func (c EditMealCommand) Validate() error {
	if !c.Reviewed || c.Revision < 1 || c.Revision >= 2147483647 || !textValid(c.Title, 0, 80) {
		return ErrFoodQuery
	}
	when, e := time.Parse(time.RFC3339, c.OccurredAt)
	if e != nil || when.Year() < 1900 || when.Year() > 2100 || when.Nanosecond()%1000 != 0 {
		return ErrFoodQuery
	}
	_, e = zone(c.Timezone)
	return e
}
