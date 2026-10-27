package nutrition

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

// The binary is exercised only inside the explicit disposable SQL lifecycle.
// Fixtures never reach the delivered database or stand in for human approval.
func assertFoodNamesOperatorCLI(t *testing.T, writerDSN, runtimeDSN string, n ReviewedFoodNames, evidence NameEvidence) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	dir := t.TempDir()
	binary := filepath.Join(dir, "food-names.exe")
	build := exec.CommandContext(ctx, "go", "build", "-o", binary, "./cmd/food-names")
	build.Dir = filepath.Join("..", "..")
	if build.Run() != nil {
		t.Fatal("operator CLI build failed")
	}
	execute := func(dsn string, args ...string) map[string]json.RawMessage {
		t.Helper()
		command := exec.CommandContext(ctx, binary, args...)
		command.Env = append(os.Environ(), "TF_FOOD_NAMES_DATABASE_URL="+dsn)
		raw, err := command.Output()
		if err != nil {
			t.Fatal("operator CLI operation failed")
		}
		var result map[string]json.RawMessage
		if json.Unmarshal(raw, &result) != nil {
			t.Fatal("operator CLI receipt invalid")
		}
		return result
	}
	n.Locale = "es"
	n.Name = "Isolated CLI fixture"
	n.Aliases = []string{"Isolated CLI alias"}
	raw, _ := json.Marshal(n)
	os.WriteFile(filepath.Join(dir, "record.json"), raw, 0600)
	os.WriteFile(filepath.Join(dir, "review.txt"), evidence.ReviewDocument, 0600)
	os.WriteFile(filepath.Join(dir, "rights.txt"), evidence.RightsDocument, 0600)
	checked := execute("", "--operation", "check-publish", "--package", dir)
	var fingerprint string
	json.Unmarshal(checked["packageSha256"], &fingerprint)
	if fingerprint == "" || string(checked["databaseChecked"]) != "false" {
		t.Fatal("preflight claimed database access")
	}
	for i := 0; i < 2; i++ {
		stored := execute(writerDSN, "--operation", "publish", "--package", dir, "--confirm", fingerprint, "--verified-reviewer-ref", n.Review.ReviewerRef)
		expected := "true"
		if i == 1 {
			expected = "false"
		}
		if string(stored["inserted"]) != expected || string(stored["databaseChecked"]) != "true" {
			t.Fatal("CLI publication was not idempotent")
		}
	}
	decision := []byte("isolated CLI withdrawal evidence")
	w := fixtureWithdrawal()
	w.FoodID = n.FoodID
	w.FoodVersion = n.FoodVersion
	w.Locale = n.Locale
	w.NameVersion = n.VersionID()
	w.EvidenceSHA = hash(decision)
	raw, _ = json.Marshal(w)
	os.WriteFile(filepath.Join(dir, "record.json"), raw, 0600)
	os.WriteFile(filepath.Join(dir, "decision.txt"), decision, 0600)
	checked = execute("", "--operation", "check-withdraw", "--package", dir)
	json.Unmarshal(checked["packageSha256"], &fingerprint)
	for i := 0; i < 2; i++ {
		stored := execute(writerDSN, "--operation", "withdraw", "--package", dir, "--confirm", fingerprint, "--verified-reviewer-ref", w.ReviewerRef)
		expected := "true"
		if i == 1 {
			expected = "false"
		}
		if string(stored["inserted"]) != expected {
			t.Fatal("CLI withdrawal was not idempotent")
		}
	}
	covered := execute(runtimeDSN, "--operation", "coverage")
	var report FoodNameCoverage
	raw, _ = json.Marshal(covered)
	if json.Unmarshal(raw, &report) != nil || len(report.Locales) != 4 {
		t.Fatal("CLI coverage missing locales")
	}
	for _, row := range report.Locales {
		if row.Locale == "es" && (row.Foods != 2 || row.Active != 0 || row.Withdrawn != 1 || row.Fallback != 2) {
			t.Fatal("CLI withdrawal did not produce original fallback")
		}
	}
}
