package catalog

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// All data below are isolated fixtures. They never enter an import database.
func fixture(t *testing.T, changeAsset func(map[string]any), changeManifest func(map[string]any)) string {
	t.Helper()
	root := t.TempDir()
	asset := map[string]any{
		"id": "fixture-movement", "kind": "movement", "sourceId": "fixture-source",
		"allowedOperations": []string{"catalog_metadata"},
		"review":            map[string]any{"state": "reviewed", "reviewer": "test-only", "rightsVerified": true, "fidelityChecked": true},
		"rights":            map[string]any{"attribution": "fixture", "licenseUrl": "https://example.invalid/license", "displayCredits": map[string]any{"author": "fixture"}, "operationGrants": map[string]string{"catalog_metadata": "allowed"}},
	}
	if changeAsset != nil {
		changeAsset(asset)
	}
	bundle := map[string]any{"schemaVersion": "1.0.0", "bundleId": "test-only", "stage": "approved_operations", "sources": []any{map[string]any{"id": "fixture-source"}}, "assets": []any{asset}}
	body, err := json.Marshal(bundle)
	if err != nil {
		t.Fatal(err)
	}
	manifest := map[string]any{"stage": "approved_consultation_operations", "importScope": "isolated_development_consultation", "output": map[string]any{"path": "content/local/reviewed.json", "sha256": sum(body)}, "rows": []any{map[string]any{"assetId": "fixture-movement", "allowedOperations": []string{"catalog_metadata"}}}}
	if changeManifest != nil {
		changeManifest(manifest)
	}
	if err := os.MkdirAll(filepath.Join(root, "content/local"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "content/local/reviewed.json"), body, 0600); err != nil {
		t.Fatal(err)
	}
	decision, err := json.Marshal(manifest)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "manifest.json"), decision, 0600); err != nil {
		t.Fatal(err)
	}
	return root
}

func TestReviewedMetadataAndIntegrity(t *testing.T) {
	root := fixture(t, nil, nil)
	loaded, err := Load(root, "manifest.json")
	if err != nil || len(loaded.Assets) != 1 || loaded.Assets[0].Kind != "movement" {
		t.Fatalf("metadata rejected: %v", err)
	}
	f, err := os.OpenFile(filepath.Join(root, "content/local/reviewed.json"), os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		t.Fatal(err)
	}
	_, err = f.WriteString(" ")
	f.Close()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = Load(root, "manifest.json"); err == nil || !strings.Contains(err.Error(), "hash") {
		t.Fatalf("changed bytes accepted: %v", err)
	}
}

func TestReviewCannotBroadenApprovedOperations(t *testing.T) {
	tests := []struct {
		name     string
		asset    func(map[string]any)
		manifest func(map[string]any)
	}{
		{"instruction kind", func(a map[string]any) { a["kind"] = "instruction" }, nil},
		{"extra operation", func(a map[string]any) { a["allowedOperations"] = []string{"catalog_metadata", "guided_practice"} }, nil},
		{"unreviewed", func(a map[string]any) { a["review"].(map[string]any)["rightsVerified"] = false }, nil},
		{"missing credits", func(a map[string]any) { a["rights"].(map[string]any)["displayCredits"] = map[string]any{} }, nil},
		{"unknown source", func(a map[string]any) { a["sourceId"] = "unreviewed-source" }, nil},
		{"manifest practice", nil, func(m map[string]any) {
			m["rows"].([]any)[0].(map[string]any)["allowedOperations"] = []string{"guided_practice"}
		}},
		{"duplicate decision", nil, func(m map[string]any) { r := m["rows"].([]any); m["rows"] = append(r, r[0]) }},
		{"missing decision", nil, func(m map[string]any) { m["rows"] = []any{} }},
		{"wrong scope", nil, func(m map[string]any) { m["importScope"] = "runtime_publication" }},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			root := fixture(t, tc.asset, tc.manifest)
			if _, err := Load(root, "manifest.json"); err == nil {
				t.Fatal("unreviewed data accepted")
			}
		})
	}
}

func TestRejectPathsOutsideRepository(t *testing.T) {
	root := fixture(t, nil, nil)
	for _, path := range []string{"../manifest.json", filepath.Join(t.TempDir(), "outside.json")} {
		if _, err := Load(root, path); err == nil {
			t.Fatalf("outside path accepted: %s", path)
		}
	}
	outside := filepath.Join(t.TempDir(), "outside.json")
	if err := os.WriteFile(outside, []byte("{}"), 0600); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "escape.json")
	if err := os.Symlink(outside, link); err != nil {
		t.Skip("Windows symlink privilege unavailable; traversal/absolute checks already ran")
	}
	if _, err := Load(root, "escape.json"); err == nil {
		t.Fatal("outside symlink accepted")
	}
}
