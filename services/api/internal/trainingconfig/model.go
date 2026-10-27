// Package trainingconfig owns declared training context, never a prescription or eligibility decision.
package trainingconfig

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
	_ "time/tzdata"
)

const Contract = "trainforge.training-configuration/1"

// ResourceRef is scoped to the editorial source. Equal numeric IDs from two sources are not equivalent.
type ResourceRef struct {
	SourceID    string `json:"sourceId"`
	EquipmentID int    `json:"equipmentId"`
}

// Resources distinguishes an explicit empty declaration from uncertainty.
type Resources struct {
	Status string        `json:"status"`
	Items  []ResourceRef `json:"items"`
}

// Availability is a declared preference on the starting weekday, not a recurring prescription.
// StartTime may be null for an unfixed time; available minutes are supplied by the user.
type Availability struct {
	Weekday          int     `json:"weekday"`
	StartTime        *string `json:"startTime" extensions:"x-nullable"`
	MinutesAvailable int     `json:"minutesAvailable"`
}
type Configuration struct {
	Environments []string       `json:"environments"`
	Resources    Resources      `json:"resources"`
	Context      string         `json:"context"`
	Timezone     string         `json:"timezone"`
	Availability []Availability `json:"availability"`
}

// SaveCommand requires explicit review and optimistic revision. Identity never comes from this body.
type SaveCommand struct {
	Revision      int           `json:"revision"`
	Reviewed      bool          `json:"reviewed"`
	Configuration Configuration `json:"configuration"`
}

// Snapshot is the confirmed context; it does not contain an eligible program or any dose.
type Snapshot struct {
	Contract      string        `json:"contract"`
	Revision      int           `json:"revision"`
	Configuration Configuration `json:"configuration"`
	ConfirmedAt   time.Time     `json:"confirmedAt"`
}

// FieldIssues carries stable machine codes; localized UI text belongs to the client.
type FieldIssues map[string]string

func (FieldIssues) Error() string { return "invalid training configuration" }

var sourcePattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$`)
var clockPattern = regexp.MustCompile(`^(?:[01][0-9]|2[0-3]):[0-5][0-9]$`)

// Validate bounds storage and requires the necessary declarations without inferring physical facts.
func (c SaveCommand) Validate() FieldIssues {
	issues := FieldIssues{}
	// Stop before iterating oversized collections, even for non-HTTP callers.
	if len(c.Configuration.Environments) > 3 {
		issues["configuration.environments"] = "choose_environment"
	}
	if len(c.Configuration.Resources.Items) > 32 {
		issues["configuration.resources.items"] = "invalid_resources"
	}
	if len(c.Configuration.Availability) > 28 {
		issues["configuration.availability"] = "choose_availability"
	}
	if len(issues) > 0 {
		return issues
	}
	if c.Revision < 0 || c.Revision > 2147483646 {
		issues["revision"] = "invalid_revision"
	}
	if !c.Reviewed {
		issues["reviewed"] = "review_required"
	}
	f := c.Configuration
	if len(f.Environments) < 1 || len(f.Environments) > 3 {
		issues["configuration.environments"] = "choose_environment"
	}
	environments := map[string]bool{}
	for _, v := range f.Environments {
		if (v != "home" && v != "park" && v != "gym") || environments[v] {
			issues["configuration.environments"] = "invalid_environment"
		}
		environments[v] = true
	}
	if f.Context != "personal" && f.Context != "caregiver_break" {
		issues["configuration.context"] = "choose_context"
	}
	if !validTimezone(f.Timezone) {
		issues["configuration.timezone"] = "invalid_timezone"
	}
	if f.Resources.Items == nil || len(f.Resources.Items) > 32 {
		issues["configuration.resources.items"] = "invalid_resources"
	}
	switch f.Resources.Status {
	case "declared":
		if len(f.Resources.Items) == 0 {
			issues["configuration.resources.items"] = "choose_resources"
		}
	case "none", "unknown":
		if len(f.Resources.Items) != 0 {
			issues["configuration.resources.items"] = "unexpected_resources"
		}
	default:
		issues["configuration.resources.status"] = "choose_resource_status"
	}
	resources := map[ResourceRef]bool{}
	for i, v := range f.Resources.Items {
		if !sourcePattern.MatchString(v.SourceID) || v.EquipmentID < 1 || v.EquipmentID > 2147483647 || resources[v] {
			issues[fmt.Sprintf("configuration.resources.items.%d", i)] = "invalid_resource"
		}
		resources[v] = true
	}
	if len(f.Availability) < 1 || len(f.Availability) > 28 {
		issues["configuration.availability"] = "choose_availability"
	}
	slots := map[string]bool{}
	for i, v := range f.Availability {
		field := fmt.Sprintf("configuration.availability.%d", i)
		if v.Weekday < 1 || v.Weekday > 7 {
			issues[field+".weekday"] = "invalid_weekday"
		}
		if v.MinutesAvailable < 1 || v.MinutesAvailable > 1440 {
			issues[field+".minutesAvailable"] = "invalid_available_minutes"
		}
		start := ""
		if v.StartTime != nil {
			start = *v.StartTime
			if !clockPattern.MatchString(start) {
				issues[field+".startTime"] = "invalid_start_time"
			}
		}
		key := strconv.Itoa(v.Weekday) + "|" + start
		if slots[key] {
			issues[field] = "duplicate_availability"
		}
		slots[key] = true
	}
	return issues
}

func validTimezone(value string) bool {
	if value == "" || len(value) > 80 || value == "Local" {
		return false
	}
	if value == "UTC" {
		return true
	}
	if len(value) == 6 && (value[0] == '+' || value[0] == '-') && value[3] == ':' {
		if !clockPattern.MatchString(value[1:]) {
			return false
		}
		parsed, err := time.Parse("-07:00", value)
		if err != nil {
			return false
		}
		_, offset := parsed.Zone()
		return offset <= 14*3600 && offset >= -14*3600
	}
	if !strings.Contains(value, "/") {
		return false
	}
	_, err := time.LoadLocation(value)
	return err == nil
}

// Canonical returns an independent stable copy for persistence/idempotency; it never changes user input.
// It is valid only after Validate has no issues. Null start means no fixed time, never midnight.
func (c SaveCommand) Canonical() SaveCommand {
	result := c
	result.Configuration.Environments = append([]string{}, c.Configuration.Environments...)
	sort.Strings(result.Configuration.Environments)
	result.Configuration.Resources.Items = append([]ResourceRef{}, c.Configuration.Resources.Items...)
	sort.Slice(result.Configuration.Resources.Items, func(i, j int) bool {
		a, b := result.Configuration.Resources.Items[i], result.Configuration.Resources.Items[j]
		if a.SourceID != b.SourceID {
			return a.SourceID < b.SourceID
		}
		return a.EquipmentID < b.EquipmentID
	})
	result.Configuration.Availability = append([]Availability{}, c.Configuration.Availability...)
	for i, v := range result.Configuration.Availability {
		if v.StartTime != nil {
			value := *v.StartTime
			result.Configuration.Availability[i].StartTime = &value
		}
	}
	sort.Slice(result.Configuration.Availability, func(i, j int) bool {
		a, b := result.Configuration.Availability[i], result.Configuration.Availability[j]
		if a.Weekday != b.Weekday {
			return a.Weekday < b.Weekday
		}
		if a.StartTime == nil {
			return b.StartTime != nil
		}
		if b.StartTime == nil {
			return false
		}
		return *a.StartTime < *b.StartTime
	})
	return result
}
