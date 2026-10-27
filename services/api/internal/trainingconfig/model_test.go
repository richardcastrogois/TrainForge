package trainingconfig

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"
)

func pointer(s string) *string { return &s }
func declared() SaveCommand {
	return SaveCommand{Revision: 0, Reviewed: true, Configuration: Configuration{Environments: []string{"home", "park"}, Context: "caregiver_break", Timezone: "America/Sao_Paulo", Resources: Resources{Status: "unknown", Items: []ResourceRef{}}, Availability: []Availability{{Weekday: 1, StartTime: nil, MinutesAvailable: 12}, {Weekday: 5, StartTime: pointer("09:30"), MinutesAvailable: 7}}}}
}
func TestDeclaredContextAllowsUnknownResourcesWithoutCreatingPhysicalFacts(t *testing.T) {
	c := declared()
	if issues := c.Validate(); len(issues) != 0 {
		t.Fatal(issues)
	}
	raw, e := json.Marshal(c)
	if e != nil {
		t.Fatal(e)
	}
	for _, field := range []string{"weight", "height", "age", "patient", "clinical", "dose", "repetitions", "programId", "userId", "ownerId"} {
		if strings.Contains(string(raw), field) {
			t.Fatal("unexpected fact in declared context", field)
		}
	}
	if c.Configuration.Availability[0].StartTime != nil || c.Configuration.Resources.Status != "unknown" {
		t.Fatal("unknown declaration inferred")
	}
}
func TestInvalidFieldsHaveStableCodesWithoutEchoingValues(t *testing.T) {
	for _, tc := range []struct {
		name        string
		change      func(*SaveCommand)
		field, code string
	}{
		{"review", func(c *SaveCommand) { c.Reviewed = false }, "reviewed", "review_required"},
		{"revision", func(c *SaveCommand) { c.Revision = -1 }, "revision", "invalid_revision"},
		{"unknown context", func(c *SaveCommand) { c.Configuration.Context = "patient" }, "configuration.context", "choose_context"},
		{"no environment", func(c *SaveCommand) { c.Configuration.Environments = nil }, "configuration.environments", "choose_environment"},
		{"duplicate environment", func(c *SaveCommand) { c.Configuration.Environments = []string{"gym", "gym"} }, "configuration.environments", "invalid_environment"},
		{"unsupported environment", func(c *SaveCommand) { c.Configuration.Environments = []string{"clinic"} }, "configuration.environments", "invalid_environment"},
		{"implicit resources", func(c *SaveCommand) { c.Configuration.Resources = Resources{} }, "configuration.resources.status", "choose_resource_status"},
		{"null resources", func(c *SaveCommand) { c.Configuration.Resources.Items = nil }, "configuration.resources.items", "invalid_resources"},
		{"empty declared", func(c *SaveCommand) { c.Configuration.Resources.Status = "declared" }, "configuration.resources.items", "choose_resources"},
		{"items in unknown", func(c *SaveCommand) { c.Configuration.Resources.Items = []ResourceRef{{"source", 1}} }, "configuration.resources.items", "unexpected_resources"},
		{"invalid timezone", func(c *SaveCommand) { c.Configuration.Timezone = "Local" }, "configuration.timezone", "invalid_timezone"},
		{"unknown timezone", func(c *SaveCommand) { c.Configuration.Timezone = "NoSuch/Zone" }, "configuration.timezone", "invalid_timezone"},
		{"no slots", func(c *SaveCommand) { c.Configuration.Availability = nil }, "configuration.availability", "choose_availability"},
		{"invalid day", func(c *SaveCommand) { c.Configuration.Availability[0].Weekday = 0 }, "configuration.availability.0.weekday", "invalid_weekday"},
		{"minutes zero", func(c *SaveCommand) { c.Configuration.Availability[0].MinutesAvailable = 0 }, "configuration.availability.0.minutesAvailable", "invalid_available_minutes"},
		{"minutes excessive", func(c *SaveCommand) { c.Configuration.Availability[0].MinutesAvailable = 1441 }, "configuration.availability.0.minutesAvailable", "invalid_available_minutes"},
		{"time format", func(c *SaveCommand) { c.Configuration.Availability[0].StartTime = pointer("9:00") }, "configuration.availability.0.startTime", "invalid_start_time"},
		{"time24", func(c *SaveCommand) { c.Configuration.Availability[0].StartTime = pointer("24:00") }, "configuration.availability.0.startTime", "invalid_start_time"},
		{"empty time", func(c *SaveCommand) { c.Configuration.Availability[0].StartTime = pointer("") }, "configuration.availability.0.startTime", "invalid_start_time"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			c := declared()
			tc.change(&c)
			issues := c.Validate()
			if issues[tc.field] != tc.code || issues.Error() != "invalid training configuration" {
				t.Fatal("unstable field validation", issues)
			}
		})
	}
}
func TestResourcesRemainSourceScopedAndNeverAssumeEquipment(t *testing.T) {
	c := declared()
	c.Configuration.Resources = Resources{Status: "declared", Items: []ResourceRef{{"first-source", 1}, {"second-source", 1}}}
	if len(c.Validate()) != 0 {
		t.Fatal("source-scoped refs merged")
	}
	c.Configuration.Resources.Items[1] = c.Configuration.Resources.Items[0]
	if c.Validate()["configuration.resources.items.1"] != "invalid_resource" {
		t.Fatal("duplicate reference")
	}
	for _, resource := range []ResourceRef{{"../source", 1}, {"source", 0}, {"source", -1}, {"source", 2147483648}, {strings.Repeat("s", 101), 1}} {
		c.Configuration.Resources.Items = []ResourceRef{resource}
		if c.Validate()["configuration.resources.items.0"] != "invalid_resource" {
			t.Fatal("unsafe resource")
		}
	}
	for _, status := range []string{"none", "unknown"} {
		c.Configuration.Resources = Resources{Status: status, Items: []ResourceRef{}}
		if len(c.Validate()) != 0 {
			t.Fatal("explicit resource status refused")
		}
	}
}
func TestAvailabilityBoundsDuplicatesAndTimezone(t *testing.T) {
	c := declared()
	c.Configuration.Availability = append(c.Configuration.Availability, c.Configuration.Availability[0])
	if c.Validate()["configuration.availability.2"] != "duplicate_availability" {
		t.Fatal("duplicate slot")
	}
	for _, tz := range []string{"UTC", "+00:00", "-03:00", "+14:00", "America/Sao_Paulo", "Europe/Lisbon"} {
		c := declared()
		c.Configuration.Timezone = tz
		if len(c.Validate()) != 0 {
			t.Fatal("valid declared timezone")
		}
	}
	for _, tz := range []string{"+14:01", "-14:01", "+00:60", "-13:60", "+24:00", "UTC+3", "", "../private"} {
		c := declared()
		c.Configuration.Timezone = tz
		if len(c.Validate()) == 0 {
			t.Fatal("invalid timezone")
		}
	}
	c = declared()
	for len(c.Configuration.Availability) <= 28 {
		c.Configuration.Availability = append(c.Configuration.Availability, Availability{})
	}
	if c.Validate()["configuration.availability"] != "choose_availability" {
		t.Fatal("unbounded slots")
	}
}
func TestCanonicalCopyIsStableAndDoesNotRewriteInput(t *testing.T) {
	c := declared()
	c.Configuration.Environments = []string{"park", "home"}
	c.Configuration.Resources = Resources{Status: "declared", Items: []ResourceRef{{"z", 2}, {"a", 1}}}
	c.Configuration.Availability[0], c.Configuration.Availability[1] = c.Configuration.Availability[1], c.Configuration.Availability[0]
	before, _ := json.Marshal(c)
	normalized := c.Canonical()
	after, _ := json.Marshal(c)
	if string(before) != string(after) || !reflect.DeepEqual(normalized, normalized.Canonical()) || len(normalized.Validate()) != 0 {
		t.Fatal("canonicalization mutated input")
	}
	if normalized.Configuration.Environments[0] != "home" || normalized.Configuration.Resources.Items[0].SourceID != "a" || normalized.Configuration.Availability[0].Weekday != 1 {
		t.Fatal("unstable order")
	}
	*normalized.Configuration.Availability[1].StartTime = "11:00"
	if *c.Configuration.Availability[0].StartTime != "09:30" {
		t.Fatal("time pointer shared with caller")
	}
}

func TestOversizedCollectionsFailBeforePerItemWork(t *testing.T) {
	c := declared()
	c.Configuration.Environments = make([]string, 4)
	c.Configuration.Resources.Items = make([]ResourceRef, 33)
	c.Configuration.Availability = make([]Availability, 29)
	issues := c.Validate()
	if len(issues) != 3 || issues["configuration.resources.items"] != "invalid_resources" || issues["configuration.availability"] != "choose_availability" {
		t.Fatal("unbounded or partial size checks")
	}
}
