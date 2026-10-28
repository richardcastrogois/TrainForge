package trainingconfig

import (
	"context"
	"regexp"
	"trainforge.local/api/internal/auth"
)

var resourceFieldPattern = regexp.MustCompile(`^configuration[.]resources[.]items[.](0|[1-9]|[12][0-9]|3[01])$`)

// Resource options are source metadata, never training instructions or permission to practice.
type ResourceOption struct {
	SourceID    string `json:"sourceId"`
	EquipmentID int    `json:"equipmentId"`
	Name        string `json:"nameOriginal"`
	SourceName  string `json:"sourceName"`
}
type ResourceFilter struct {
	Q, AfterSource string
	AfterID, Limit int
}
type ResourceRepository interface {
	Resources(context.Context, auth.Principal, ResourceFilter) ([]ResourceOption, error)
}

type ResourceResolver interface {
	ResolveResources(context.Context, auth.Principal, []ResourceRef) ([]ResourceOption, error)
}
