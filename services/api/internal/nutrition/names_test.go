package nutrition

import (
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"strings"
	"testing"
	"time"
)

var namesNow = time.Date(2026, 10, 26, 12, 0, 0, 0, time.UTC)

func fixtureNames() ReviewedFoodNames {
	return ReviewedFoodNames{
		Contract: "trainforge.food-names/1", FoodID: "food:" + strings.Repeat("a", 64), FoodVersion: strings.Repeat("b", 64), SourceName: "Fixture raw", SourceLocale: "fr", Locale: "pt-BR", Name: "Isolated translated fixture", Aliases: []string{"Isolated alias"},
		Review: NameReview{ReviewerRef: "isolated-fixture-only", ReviewedAt: "2026-10-25T10:00:00Z", HumanReviewed: true, EvidenceSHA: strings.Repeat("c", 64), RightsSHA: strings.Repeat("d", 64), LicenseLabel: "Fixture rights only", LicenseURL: "https://example.test/fixture-rights", Attribution: "Isolated fixture, never runtime content", Scope: "food_names_and_aliases", DisplayAllowed: true, SearchAllowed: true},
	}
}
func TestFoodNamesValidationRejectsMissingReviewAndAmbiguousInput(t *testing.T) {
	good := fixtureNames()
	raw, _ := json.Marshal(good)
	parsed, err := DecodeReviewedFoodNames(raw, namesNow)
	if err != nil || parsed.VersionID() != good.VersionID() {
		t.Fatal("valid fixture refused")
	}
	cases := map[string]func(*ReviewedFoodNames){
		"private identity":         func(n *ReviewedFoodNames) { n.FoodID = "own:fixture" },
		"version mismatch format":  func(n *ReviewedFoodNames) { n.FoodVersion = "newest" },
		"unsupported locale":       func(n *ReviewedFoodNames) { n.Locale = "pt" },
		"regional locale mixed":    func(n *ReviewedFoodNames) { n.Locale = "pt_BR" },
		"no human review":          func(n *ReviewedFoodNames) { n.Review.HumanReviewed = false },
		"no evidence":              func(n *ReviewedFoodNames) { n.Review.EvidenceSHA = "" },
		"no rights":                func(n *ReviewedFoodNames) { n.Review.RightsSHA = "" },
		"future review":            func(n *ReviewedFoodNames) { n.Review.ReviewedAt = "2027-01-01T00:00:00Z" },
		"no identity":              func(n *ReviewedFoodNames) { n.Review.ReviewerRef = "" },
		"invalid rights URL":       func(n *ReviewedFoodNames) { n.Review.LicenseURL = "http://example.test" },
		"no display grant":         func(n *ReviewedFoodNames) { n.Review.DisplayAllowed = false },
		"no search grant":          func(n *ReviewedFoodNames) { n.Review.SearchAllowed = false },
		"wrong scope":              func(n *ReviewedFoodNames) { n.Review.Scope = "exercise_prescription" },
		"null aliases":             func(n *ReviewedFoodNames) { n.Aliases = nil },
		"duplicate aliases":        func(n *ReviewedFoodNames) { n.Aliases = []string{"Same", "same"} },
		"alias duplicates name":    func(n *ReviewedFoodNames) { n.Aliases = []string{strings.ToUpper(n.Name)} },
		"replacement character":    func(n *ReviewedFoodNames) { n.Name = "unknown\ufffd" },
		"unreviewed normalization": func(n *ReviewedFoodNames) { n.Name = " two  spaces " },
		"control character":        func(n *ReviewedFoodNames) { n.Name = "name\nother" },
		"hidden direction":         func(n *ReviewedFoodNames) { n.Name = "name\u202eother" },
		"too many aliases":         func(n *ReviewedFoodNames) { n.Aliases = make([]string, 17) },
	}
	for title, change := range cases {
		t.Run(title, func(t *testing.T) {
			n := fixtureNames()
			change(&n)
			if !errors.Is(n.Validate(namesNow), ErrFoodNames) {
				t.Fatal("unsafe fixture accepted")
			}
		})
	}
	for _, bad := range [][]byte{
		append(append([]byte{}, raw...), raw...),
		[]byte(strings.Replace(string(raw), `"contract":`, `"nutrients":[],"contract":`, 1)),
		[]byte(strings.Replace(string(raw), `"humanReviewed":true`, `"humanReviewed":false,"humanReviewed":true`, 1)),
		[]byte(strings.Replace(string(raw), `"locale":"pt-BR"`, `"locale":"es","locale":"pt-BR"`, 1)),
		append(raw, 0xff), []byte(strings.Repeat(" ", 32769)),
	} {
		if _, err := DecodeReviewedFoodNames(bad, namesNow); !errors.Is(err, ErrFoodNames) {
			t.Fatal("ambiguous JSON accepted")
		}
	}
}
func TestFoodNamesVersionBindsReviewLocaleAndAliases(t *testing.T) {
	n := fixtureNames()
	first := n.VersionID()
	if !shaPattern.MatchString(first) {
		t.Fatal("invalid version")
	}
	for _, change := range []func(*ReviewedFoodNames){func(n *ReviewedFoodNames) { n.Locale = "pt-PT" }, func(n *ReviewedFoodNames) { n.Aliases = append(n.Aliases, "another alias") }, func(n *ReviewedFoodNames) { n.Review.RightsSHA = strings.Repeat("e", 64) }, func(n *ReviewedFoodNames) { n.FoodVersion = strings.Repeat("f", 64) }} {
		copy := fixtureNames()
		change(&copy)
		if copy.VersionID() == first {
			t.Fatal("version not bound to reviewed content")
		}
	}
	n.SourceName = "Original\n spacing preserved"
	n.Aliases = []string{}
	if n.Validate(namesNow) != nil {
		t.Fatal("original source whitespace must be preserved")
	}
}
func TestFoodNamesPostgresImmutabilityAndRuntimePermissions(t *testing.T) {
	dsn := os.Getenv("TF_FOOD_NAMES_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("isolated reviewed-name fixture database not requested")
	}
	cfg, err := pgx.ParseConfig(dsn)
	if err != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || !strings.HasPrefix(cfg.Database, "trainforge_v1_names_test_") {
		t.Fatal("unsafe fixture target")
	}
	rc, err := pgx.ParseConfig(os.Getenv("TF_FOOD_NAMES_TEST_RUNTIME_URL"))
	if err != nil || rc.Database != cfg.Database || rc.Host != cfg.Host || rc.Port != cfg.Port || rc.User != "trainforge_runtime" {
		t.Fatal("unsafe runtime target")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	writer, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal("fixture writer unavailable")
	}
	defer writer.Close()
	runtime, err := pgxpool.New(ctx, os.Getenv("TF_FOOD_NAMES_TEST_RUNTIME_URL"))
	if err != nil {
		t.Fatal("fixture runtime unavailable")
	}
	defer runtime.Close()
	f := newFixture(t, "reviewed-name-only")
	if _, err = Import(ctx, writer, f.load(t)); err != nil {
		t.Fatal("fixture import failed")
	}
	var before string
	if writer.QueryRow(ctx, "SELECT row_to_json(v)::text FROM trainforge_v1.food_versions v WHERE food_id=$1", f.food.ID).Scan(&before) != nil {
		t.Fatal("fixture source missing")
	}
	var version string
	if writer.QueryRow(ctx, "SELECT version_sha FROM trainforge_v1.food_versions WHERE food_id=$1", f.food.ID).Scan(&version) != nil {
		t.Fatal("fixture version missing")
	}
	n := fixtureNames()
	evidence := NameEvidence{ReviewDocument: []byte("isolated human-review evidence fixture"), RightsDocument: []byte("isolated rights evidence fixture")}
	n.Review.EvidenceSHA = hash(evidence.ReviewDocument)
	n.Review.RightsSHA = hash(evidence.RightsDocument)
	n.FoodID = f.food.ID
	n.FoodVersion = version
	n.SourceName = f.food.Name
	n.SourceLocale = f.food.Locale
	id, inserted, err := StoreReviewedFoodNames(ctx, writer, n, evidence, namesNow)
	if err != nil || !inserted || id != n.VersionID() {
		t.Fatal("reviewed name fixture not stored")
	}
	var revisionBeforeRetry string
	if writer.QueryRow(ctx, "SELECT revision::text FROM trainforge_v1.food_name_catalogs WHERE locale='pt-BR'").Scan(&revisionBeforeRetry) != nil {
		t.Fatal("name revision missing")
	}

	second, inserted, err := StoreReviewedFoodNames(ctx, writer, n, evidence, namesNow)
	if err != nil || inserted || second != id {
		t.Fatal("non-idempotent name persistence")
	}
	var revisionAfterRetry string
	if writer.QueryRow(ctx, "SELECT revision::text FROM trainforge_v1.food_name_catalogs WHERE locale='pt-BR'").Scan(&revisionAfterRetry) != nil || revisionAfterRetry != revisionBeforeRetry {
		t.Fatal("idempotent retry changed name generation")
	}

	n.Name = "Isolated second revision"
	newest, inserted, err := StoreReviewedFoodNames(ctx, writer, n, evidence, namesNow)
	if err != nil || !inserted {
		t.Fatal("new immutable revision refused")
	}
	n.SourceName = "Different source"
	if _, _, err = StoreReviewedFoodNames(ctx, writer, n, evidence, namesNow); !errors.Is(err, ErrFoodNames) {
		t.Fatal("wrong source identity accepted")
	}
	n.SourceName = f.food.Name
	var canRead, canInsert, canUpdate, canDelete bool
	for _, table := range []string{"food_name_versions", "food_name_withdrawals", "food_name_catalogs"} {
		err = runtime.QueryRow(ctx, "SELECT has_table_privilege(current_user,$1,'SELECT'),has_table_privilege(current_user,$1,'INSERT'),has_table_privilege(current_user,$1,'UPDATE'),has_table_privilege(current_user,$1,'DELETE')", "trainforge_v1."+table).Scan(&canRead, &canInsert, &canUpdate, &canDelete)
		if err != nil || !canRead || canInsert || canUpdate || canDelete {
			t.Fatal("unsafe runtime name privileges")
		}
	}
	if _, _, err = StoreReviewedFoodNames(ctx, runtime, n, evidence, namesNow); !errors.Is(err, ErrFoodUnavailable) {
		t.Fatal("runtime published editorial name")
	}
	if _, err = writer.Exec(ctx, "UPDATE trainforge_v1.food_name_versions SET name='tampered' WHERE food_id=$1", n.FoodID); err == nil {
		t.Fatal("immutable name was updated")
	}
	if _, err = writer.Exec(ctx, "DELETE FROM trainforge_v1.food_name_versions WHERE food_id=$1", n.FoodID); err == nil {
		t.Fatal("name history was deleted")
	}

	resolver := FoodNamesPostgres{runtime}
	target := FoodNameTarget{n.FoodID, n.FoodVersion}
	resolved, err := resolver.Resolve(ctx, []FoodNameTarget{target, {n.FoodID, strings.Repeat("e", 64)}}, "pt-BR")
	if err != nil || len(resolved) != 1 || resolved[target].VersionID != newest || resolved[target].Name != n.Name {
		t.Fatal("name resolution crossed identity or source version")
	}
	if resolved[target].ReviewEvidenceSHA != n.Review.EvidenceSHA || resolved[target].LicenseURL != n.Review.LicenseURL {
		t.Fatal("name review attribution lost")
	}
	wrongVersion, err := resolver.Resolve(ctx, []FoodNameTarget{{n.FoodID, strings.Repeat("e", 64)}}, "pt-BR")
	if err != nil || len(wrongVersion) != 0 {
		t.Fatal("translation matched another source version")
	}
	// The same visible name is legal for different food identities; never merge.
	otherFood := newFixture(t, "reviewed-name-homonym")
	if _, err = Import(ctx, writer, otherFood.load(t)); err != nil {
		t.Fatal("homonym source fixture failed")
	}
	var otherVersion string
	if writer.QueryRow(ctx, "SELECT version_sha FROM trainforge_v1.food_versions WHERE food_id=$1", otherFood.food.ID).Scan(&otherVersion) != nil {
		t.Fatal("homonym version missing")
	}
	homonym := n
	homonym.FoodID = otherFood.food.ID
	homonym.FoodVersion = otherVersion
	homonymID, _, err := StoreReviewedFoodNames(ctx, writer, homonym, evidence, namesNow)
	if err != nil {
		t.Fatal("homonym fixture not stored")
	}
	otherTarget := FoodNameTarget{homonym.FoodID, homonym.FoodVersion}
	both, err := resolver.Resolve(ctx, []FoodNameTarget{target, otherTarget}, "pt-BR")
	if err != nil || len(both) != 2 || both[target].VersionID != newest || both[otherTarget].VersionID != homonymID {
		t.Fatal("homonymous foods were merged")
	}

	checkAfterHTTP := assertLocalizedFoodNames(t, FoodPostgres{runtime}, target, otherTarget, n.Aliases[0])

	for _, locale := range []string{"pt-PT", "en", "es"} {
		other, err := resolver.Resolve(ctx, []FoodNameTarget{target}, locale)
		if err != nil || len(other) != 0 {
			t.Fatal("name crossed locale boundary instead of original fallback")
		}
	}
	if _, err = writer.Exec(ctx, "INSERT INTO trainforge_v1.food_name_withdrawals(food_id,food_version_sha,locale,version_sha,reason) VALUES($1,$2,$3,$4,'latest isolated fixture withdrawn')", n.FoodID, n.FoodVersion, n.Locale, newest); err != nil {
		t.Fatal("latest withdrawal fixture failed")
	}
	resolved, err = resolver.Resolve(ctx, []FoodNameTarget{target}, "pt-BR")
	if err != nil || len(resolved) != 0 {
		t.Fatal("withdrawal revived an older translation")
	}

	checkAfterHTTP()

	if _, err = writer.Exec(ctx, "DELETE FROM trainforge_v1.food_name_withdrawals WHERE food_id=$1", n.FoodID); err == nil {
		t.Fatal("withdrawal history was deleted")
	}
	both, err = resolver.Resolve(ctx, []FoodNameTarget{target, otherTarget}, "pt-BR")
	if err != nil || len(both) != 1 || both[otherTarget].VersionID != homonymID {
		t.Fatal("withdrawal crossed another food identity")
	}

	var after string
	if writer.QueryRow(ctx, "SELECT row_to_json(v)::text FROM trainforge_v1.food_versions v WHERE food_id=$1", f.food.ID).Scan(&after) != nil || after != before {
		t.Fatal("original source was modified")
	}
	// Public read behavior is unchanged: no projection of reviewed names until the
	// locale/version/withdrawal contract is implemented as a separate increment.
	detail, err := (FoodPostgres{runtime}).Detail(ctx, n.FoodID, n.FoodVersion)
	if err != nil || detail.Name != f.food.Name || detail.VersionID != n.FoodVersion {
		t.Fatal("public original projection changed")
	}
}

func TestFoodNamesEvidenceMustMatchBeforePersistence(t *testing.T) {
	n := fixtureNames()
	e := NameEvidence{ReviewDocument: []byte("isolated review fixture"), RightsDocument: []byte("isolated rights fixture")}
	if e.Validate(n) == nil {
		t.Fatal("unchecked hashes accepted")
	}
	n.Review.EvidenceSHA = hash(e.ReviewDocument)
	n.Review.RightsSHA = hash(e.RightsDocument)
	if e.Validate(n) != nil {
		t.Fatal("matching evidence refused")
	}
	e.ReviewDocument = append(e.ReviewDocument, 'x')
	if e.Validate(n) == nil {
		t.Fatal("changed review accepted")
	}
	if _, _, err := StoreReviewedFoodNames(context.Background(), nil, n, e, namesNow); !errors.Is(err, ErrFoodNames) {
		t.Fatal("invalid evidence reached storage")
	}
}

func TestFoodNamesResolveRejectsUnsafeTargetsBeforeQuery(t *testing.T) {
	resolver := FoodNamesPostgres{}
	valid := FoodNameTarget{"food:" + strings.Repeat("a", 64), strings.Repeat("b", 64)}
	for _, test := range []struct {
		targets []FoodNameTarget
		locale  string
	}{
		{[]FoodNameTarget{valid}, "pt"},
		{[]FoodNameTarget{{"own:fixture", valid.FoodVersion}}, "en"},
		{[]FoodNameTarget{{valid.FoodID, "latest"}}, "es"},
		{make([]FoodNameTarget, 51), "pt-BR"},
	} {
		if _, err := resolver.Resolve(context.Background(), test.targets, test.locale); !errors.Is(err, ErrFoodQuery) {
			t.Fatal("invalid name target reached storage")
		}
	}
	names, err := resolver.Resolve(context.Background(), nil, "en")
	if err != nil || len(names) != 0 {
		t.Fatal("empty page should not query storage")
	}
}

func TestFoodNamesCanonicalLimitAllowsDatabaseJSONWhitespace(t *testing.T) {
	n := fixtureNames()
	n.SourceName = strings.Repeat("x", 2000)
	n.Name = strings.Repeat("x", 360)
	n.Review.Attribution = strings.Repeat("y", 2000)
	n.Aliases = []string{}
	for i := 0; i < 16; i++ {
		n.Aliases = append(n.Aliases, strings.Repeat("😀", 340)+string(rune('a'+i)))
	}
	if n.Validate(namesNow) != nil {
		t.Fatal("bounded canonical review refused")
	}
	// Pretty JSON may be larger than canonical while describing the same record.
	raw, _ := json.MarshalIndent(n, "", strings.Repeat(" ", 100))
	if _, err := DecodeReviewedFoodNames(raw, namesNow); err != nil {
		t.Fatal("equivalent database whitespace changed review")
	}
	n.SourceName = strings.Repeat("😀", 2000)
	n.Review.Attribution = strings.Repeat("😀", 2000)
	if n.Validate(namesNow) == nil {
		t.Fatal("oversized canonical review accepted")
	}
	if _, err := DecodeReviewedFoodNames([]byte(strings.Repeat(" ", 65537)), namesNow); err == nil {
		t.Fatal("unbounded JSON accepted")
	}
}
