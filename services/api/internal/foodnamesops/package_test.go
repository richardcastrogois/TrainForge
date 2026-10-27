package foodnamesops

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
	"trainforge.local/api/internal/nutrition"
)

func sum(raw []byte) string { h := sha256.Sum256(raw); return hex.EncodeToString(h[:]) }
func publicationPackage(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	review, rights := []byte("isolated review fixture, not human content"), []byte("isolated rights fixture, not a license")
	n := nutrition.ReviewedFoodNames{Contract: "trainforge.food-names/1", FoodID: "food:" + strings.Repeat("a", 64), FoodVersion: strings.Repeat("b", 64), SourceName: "Fixture original", SourceLocale: "fr", Locale: "pt-BR", Name: "Isolated name fixture", Aliases: []string{"Isolated alias"}, Review: nutrition.NameReview{ReviewerRef: "fixture-only-reviewer", ReviewedAt: "2026-10-25T00:00:00Z", HumanReviewed: true, EvidenceSHA: sum(review), RightsSHA: sum(rights), LicenseLabel: "Fixture rights", LicenseURL: "https://example.test/rights", Attribution: "Never published fixture", Scope: "food_names_and_aliases", DisplayAllowed: true, SearchAllowed: true}}
	raw, _ := json.Marshal(n)
	for name, data := range map[string][]byte{"record.json": raw, "review.txt": review, "rights.txt": rights} {
		if os.WriteFile(filepath.Join(dir, name), data, 0600) != nil {
			t.Fatal("fixture write failed")
		}
	}
	return dir
}
func TestPackagePreflightDoesNotReadEnvironmentOrClaimPublication(t *testing.T) {
	dir := publicationPackage(t)
	var out bytes.Buffer
	if err := Run([]string{"--package", dir}, func(string) string { t.Fatal("preflight read credentials"); return "" }, &out); err != nil {
		t.Fatal(err)
	}
	var r receipt
	if json.Unmarshal(out.Bytes(), &r) != nil || r.DatabaseChecked || r.Inserted || r.Scope != "structure-and-matching-evidence-only" || len(r.PackageSHA) != 64 {
		t.Fatal("preflight claimed publication")
	}
	original, err := Load(dir, "publish", time.Now())
	if err != nil {
		t.Fatal(err)
	}
	// Even equivalent JSON formatting changes the confirmation of exact package bytes.
	raw, _ := os.ReadFile(filepath.Join(dir, "record.json"))
	os.WriteFile(filepath.Join(dir, "record.json"), append(raw, byte(10)), 0600)
	changed, err := Load(dir, "publish", time.Now())
	if err != nil || changed.Fingerprint == original.Fingerprint {
		t.Fatal("package fingerprint ignored changed bytes")
	}
}
func TestPackageRejectsMissingChangedAndOversizedEvidence(t *testing.T) {
	for _, name := range []string{"review.txt", "rights.txt", "record.json"} {
		t.Run(name, func(t *testing.T) {
			dir := publicationPackage(t)
			file := filepath.Join(dir, name)
			raw, _ := os.ReadFile(file)
			os.WriteFile(file, append(raw, 'x'), 0600)
			if _, err := Load(dir, "publish", time.Now()); !errors.Is(err, ErrPackage) {
				t.Fatal("changed evidence accepted")
			}
			os.Remove(file)
			if _, err := Load(dir, "publish", time.Now()); err == nil {
				t.Fatal("missing file accepted")
			}
			os.WriteFile(file, bytes.Repeat([]byte{'x'}, 1048577), 0600)
			if _, err := Load(dir, "publish", time.Now()); err == nil {
				t.Fatal("oversized file accepted")
			}
		})
	}
	dir := publicationPackage(t)
	os.Remove(filepath.Join(dir, "review.txt"))
	os.Mkdir(filepath.Join(dir, "review.txt"), 0700)
	if _, err := Load(dir, "publish", time.Now()); err == nil {
		t.Fatal("directory used as evidence")
	}
}
func TestPackageRejectsAmbiguousReviewBeforeCredentials(t *testing.T) {
	for _, replace := range [][2]string{{`"locale":"pt-BR"`, `"locale":"es","locale":"pt-BR"`}, {`"contract":`, `"unknown":true,"contract":`}, {`"humanReviewed":true`, `"humanReviewed":false`}} {
		dir := publicationPackage(t)
		p := filepath.Join(dir, "record.json")
		raw, _ := os.ReadFile(p)
		os.WriteFile(p, []byte(strings.Replace(string(raw), replace[0], replace[1], 1)), 0600)
		if err := Run([]string{"--package", dir}, func(string) string { t.Fatal("invalid review read credentials"); return "" }, &bytes.Buffer{}); err == nil {
			t.Fatal("ambiguous review accepted")
		}
	}
}
func TestWriteRequiresExactFingerprintAndVerifiedReviewerBeforeCredentials(t *testing.T) {
	dir := publicationPackage(t)
	p, err := Load(dir, "publish", time.Now())
	if err != nil {
		t.Fatal(err)
	}
	for _, args := range [][]string{{}, {"--confirm", p.Fingerprint}, {"--confirm", p.Fingerprint, "--verified-reviewer-ref", "other"}, {"--confirm", strings.Repeat("0", 64), "--verified-reviewer-ref", p.ReviewerRef()}} {
		args = append([]string{"--operation", "publish", "--package", dir}, args...)
		if err := Run(args, func(string) string { t.Fatal("unconfirmed write read credentials"); return "" }, &bytes.Buffer{}); !errors.Is(err, errOptions) {
			t.Fatal("unconfirmed write accepted")
		}
	}
}
func TestTargetRejectsRemoteRuntimeWritesForeignDatabaseAndOverrides(t *testing.T) {
	base := "postgresql://trainforge_migrator:fixture-secret@127.0.0.1:15432/trainforge_v1_dev?sslmode=disable"
	for _, name := range []string{"trainforge_v1_dev", "trainforge_v1_names_test_0123456789ab"} {
		if validateTarget(strings.Replace(base, "trainforge_v1_dev", name, 1), true) != nil {
			t.Fatal("owned target refused")
		}
	}
	runtime := strings.Replace(base, "trainforge_migrator", "trainforge_runtime", 1)
	if validateTarget(runtime, false) != nil || validateTarget(runtime, true) == nil {
		t.Fatal("role boundary failed")
	}
	for _, dsn := range []string{"", strings.Replace(base, "127.0.0.1", "remote.invalid", 1), strings.Replace(base, "15432", "5432", 1), strings.Replace(base, "trainforge_v1_dev", "postgres", 1), strings.Replace(base, "trainforge_migrator", "trainforge_owner", 1), strings.Replace(base, "trainforge_v1_dev", "trainforge_v1_names_test_wrong", 1), base + "&options=-crole%3Dtrainforge_owner", base + "&host=127.0.0.1,remote.invalid"} {
		err := validateTarget(dsn, true)
		if err == nil || strings.Contains(err.Error(), "fixture-secret") {
			t.Fatal("unsafe target accepted or credentials exposed")
		}
	}
}
func TestWithdrawalPackageBindsDecisionAndReviewer(t *testing.T) {
	dir := t.TempDir()
	decision := []byte("isolated withdrawal decision")
	w := nutrition.FoodNameWithdrawal{Contract: "trainforge.food-name-withdrawal/1", FoodID: "food:" + strings.Repeat("a", 64), FoodVersion: strings.Repeat("b", 64), Locale: "es", NameVersion: strings.Repeat("c", 64), Reason: "Isolated correction", ReviewerRef: "fixture-reviewer", ReviewedAt: "2026-10-25T00:00:00Z", EvidenceSHA: sum(decision)}
	raw, _ := json.Marshal(w)
	os.WriteFile(filepath.Join(dir, "record.json"), raw, 0600)
	os.WriteFile(filepath.Join(dir, "decision.txt"), decision, 0600)
	var out bytes.Buffer
	if Run([]string{"--operation", "check-withdraw", "--package", dir}, func(string) string { t.Fatal("preflight queried environment"); return "" }, &out) != nil {
		t.Fatal("withdrawal preflight failed")
	}
	os.WriteFile(filepath.Join(dir, "decision.txt"), []byte("modified"), 0600)
	if _, err := Load(dir, "withdraw", time.Now()); err == nil {
		t.Fatal("changed decision accepted")
	}
}
func TestCoverageRejectsMutationFlagsAndWithholdsConnectionDetails(t *testing.T) {
	for _, args := range [][]string{{"--operation", "coverage", "--confirm", "anything"}, {"--operation", "coverage", "--package", "any"}, {"--operation", "coverage"}, {"--operation", "unsupported"}, {"--operation", "publish", "extra-positional"}} {
		var out bytes.Buffer
		err := Run(args, func(string) string { return "postgresql://runtime:secret@remote.invalid/foreign" }, &out)
		if err == nil || out.Len() != 0 || strings.Contains(err.Error(), "secret") {
			t.Fatal("invalid CLI configuration accepted or leaked")
		}
	}
}
