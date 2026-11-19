package publiccatalog

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"trainforge.local/api/internal/nutrition"
)

func testHash(raw []byte) string { sum := sha256.Sum256(raw); return hex.EncodeToString(sum[:]) }
func testArchive(t *testing.T, path string, entries map[string][]byte) {
	t.Helper()
	file, e := os.Create(path)
	if e != nil {
		t.Fatal(e)
	}
	z := zip.NewWriter(file)
	for name, raw := range entries {
		entry, e := z.Create(name)
		if e != nil {
			t.Fatal(e)
		}
		if _, e = entry.Write(raw); e != nil {
			t.Fatal(e)
		}
	}
	if z.Close() != nil || file.Close() != nil {
		t.Fatal("archive fixture")
	}
}
func catalogFilesFixture(t *testing.T) (*Files, Manifest, []byte, []byte) {
	t.Helper()
	directory := t.TempDir()
	pub, key, e := ed25519.GenerateKey(rand.Reader)
	if e != nil {
		t.Fatal(e)
	}
	var data bytes.Buffer
	gzipFile := gzip.NewWriter(&data)
	_, _ = gzipFile.Write([]byte("synthetic SQLite contents for distribution boundary"))
	_ = gzipFile.Close()
	payload := data.Bytes()
	source := nutrition.CatalogSource{SourceID: "AL-FIXTURE", Name: "Fixture", Publisher: "Disposable test", URL: "https://example.invalid/source", LicenseLabel: "CC0", LicenseURL: "https://creativecommons.org/publicdomain/zero/1.0/", Attribution: "Fixture only", Version: "2026", Conditions: []string{"Fixture only"}, Foods: 1}
	m := Manifest{Contract: nutrition.CatalogContract, SchemaVersion: 1, Version: testHash([]byte("version")), File: "catalog.sqlite.gz", SHA256: testHash(payload), Bytes: int64(len(payload)), DatabaseFile: "catalog.sqlite", DatabaseSHA256: testHash([]byte("raw")), DatabaseBytes: 3, Complete: true, Sources: []nutrition.CatalogSource{source}, Counts: map[string]int64{"foods": 1, source.SourceID: 1}, Exports: []nutrition.CatalogExport{{File: "AL-FIXTURE.jsonl.gz", SHA256: testHash(payload), Bytes: int64(len(payload)), Rows: 1, SourceID: source.SourceID, License: source.LicenseLabel}}}
	message, _ := json.Marshal(m)
	envelope, _ := json.Marshal(map[string]string{"keyId": "fixture-key", "payload": base64.StdEncoding.EncodeToString(message), "signature": base64.StdEncoding.EncodeToString(ed25519.Sign(key, message))})
	trust, _ := json.Marshal(map[string]any{"contract": "trainforge.food-catalog-trust/1", "keys": []map[string]string{{"keyId": "fixture-key", "algorithm": "Ed25519", "publicKey": base64.StdEncoding.EncodeToString(pub)}}})
	for name, raw := range map[string][]byte{"manifest.json": envelope, "trust.json": trust, "AL-FIXTURE.jsonl.gz": payload} {
		if os.WriteFile(filepath.Join(directory, name), raw, 0600) != nil {
			t.Fatal("fixture write")
		}
	}
	archive := filepath.Join(directory, "catalog-update.zip")
	testArchive(t, archive, map[string][]byte{"manifest.json": envelope, m.File: payload})
	m.ManifestSHA = testHash(message)
	f := &Files{Directory: directory, ExportsDirectory: directory, ArchivePath: archive, Active: func(_ context.Context, got Manifest) bool {
		return got.Version == m.Version && got.SHA256 == m.SHA256 && got.ManifestSHA == m.ManifestSHA
	}}
	return f, m, envelope, payload
}
func TestCatalogDistributionRequiresExactActiveArtifactAndPreservesRanges(t *testing.T) {
	f, m, manifest, _ := catalogFilesFixture(t)
	mux := http.NewServeMux()
	f.Register(mux)
	call := func(path, rangeValue string) *httptest.ResponseRecorder {
		r := httptest.NewRequest("GET", path, nil)
		if rangeValue != "" {
			r.Header.Set("Range", rangeValue)
		}
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	if out := call("/api/v1/food-catalog/manifest", ""); out.Code != 200 || !bytes.Equal(out.Body.Bytes(), manifest) {
		t.Fatal("signed manifest", out.Code)
	}
	if out := call("/api/v1/food-catalog/archive", "bytes=0-9"); out.Code != 206 || out.Body.Len() != 10 || out.Header().Get("Content-Type") != "application/zip" {
		t.Fatal("archive range", out.Code, out.Body.Len())
	}
	if out := call("/api/v1/food-catalog/exports/AL-FIXTURE.jsonl.gz", "bytes=0-4"); out.Code != 206 || out.Body.Len() != 5 || out.Header().Get("ETag") != `"`+m.Exports[0].SHA256+`"` {
		t.Fatal("export range/identity", out.Code)
	}
	f.Active = func(context.Context, Manifest) bool { return false }
	if out := call("/api/v1/food-catalog/manifest", ""); out.Code != 503 {
		t.Fatal("unactivated artifact distributed")
	}
}
func TestCatalogArchiveRejectsUndeclaredFilesAndWrongSignedManifest(t *testing.T) {
	f, m, manifest, payload := catalogFilesFixture(t)
	mux := http.NewServeMux()
	f.Register(mux)
	call := func() *httptest.ResponseRecorder {
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, httptest.NewRequest("GET", "/api/v1/food-catalog/archive", nil))
		return w
	}
	testArchive(t, f.ArchivePath, map[string][]byte{"manifest.json": manifest, m.File: payload, "private-data.txt": []byte("must not be served")})
	if out := call(); out.Code != 503 || bytes.Contains(out.Body.Bytes(), []byte("must not be served")) {
		t.Fatal("undeclared archive transmitted")
	}
	testArchive(t, f.ArchivePath, map[string][]byte{"manifest.json": []byte(`{"different":true}`), m.File: payload})
	if out := call(); out.Code != 503 {
		t.Fatal("wrong embedded manifest accepted")
	}
	testArchive(t, f.ArchivePath, map[string][]byte{"manifest.json": manifest, m.File: bytes.Repeat([]byte{'x'}, len(payload))})
	if out := call(); out.Code != 503 {
		t.Fatal("corrupt payload accepted")
	}
}
func TestCatalogVerificationCacheIsBoundToIdentityAndContext(t *testing.T) {
	f, _, _, _ := catalogFilesFixture(t)
	file, e := os.Open(f.ArchivePath)
	if e != nil {
		t.Fatal(e)
	}
	defer file.Close()
	info, _ := file.Stat()
	calls := 0
	check := func() error { calls++; return nil }
	if f.verify(context.Background(), f.ArchivePath, file, info, "artifact-a", check) != nil || f.verify(context.Background(), f.ArchivePath, file, info, "artifact-a", check) != nil || calls != 1 {
		t.Fatal("Range requests rehash unchanged artifact")
	}
	if f.verify(context.Background(), f.ArchivePath, file, info, "artifact-b", check) != nil || calls != 2 {
		t.Fatal("changed manifest reused verification")
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if f.verify(ctx, f.ArchivePath, file, info, "artifact-b", check) == nil {
		t.Fatal("cancelled verification continued")
	}
}

func TestCatalogVersionedExportsSurviveLatestReplacementAndMovedSources(t *testing.T) {
	f, first, firstRaw, firstData := catalogFilesFixture(t)
	exportName := first.Exports[0].File
	firstDirectory := filepath.Join(f.ExportsDirectory, first.SHA256)
	if os.Mkdir(firstDirectory, 0700) != nil || os.WriteFile(filepath.Join(firstDirectory, "manifest.json"), firstRaw, 0600) != nil ||
		os.Rename(filepath.Join(f.ExportsDirectory, exportName), filepath.Join(firstDirectory, exportName)) != nil {
		t.Fatal("archive first release")
	}
	// Archive-local keys are deliberately invalid: only server trust may verify.
	_ = os.WriteFile(filepath.Join(firstDirectory, "trust.json"), []byte(`{"keys":[]}`), 0600)
	pub, key, e := ed25519.GenerateKey(rand.Reader)
	if e != nil {
		t.Fatal(e)
	}
	secondData := []byte("second signed export, different public source bytes")
	second := first
	second.Version = testHash([]byte("second version"))
	second.SHA256 = testHash(secondData)
	second.Bytes = int64(len(secondData))
	second.Exports = append([]nutrition.CatalogExport{}, first.Exports...)
	second.Exports[0].SHA256 = testHash(secondData)
	second.Exports[0].Bytes = int64(len(secondData))
	message, _ := json.Marshal(second)
	second.ManifestSHA = testHash(message)
	secondRaw, _ := json.Marshal(map[string]string{"keyId": "second-key", "payload": base64.StdEncoding.EncodeToString(message), "signature": base64.StdEncoding.EncodeToString(ed25519.Sign(key, message))})
	trustRaw, _ := os.ReadFile(filepath.Join(f.Directory, "trust.json"))
	var trust map[string]any
	_ = json.Unmarshal(trustRaw, &trust)
	trust["keys"] = append(trust["keys"].([]any), map[string]string{"keyId": "second-key", "algorithm": "Ed25519", "publicKey": base64.StdEncoding.EncodeToString(pub)})
	trustRaw, _ = json.Marshal(trust)
	for path, raw := range map[string][]byte{filepath.Join(f.Directory, "trust.json"): trustRaw,
		filepath.Join(f.Directory, "manifest.json"): secondRaw, filepath.Join(f.ExportsDirectory, exportName): secondData} {
		if os.WriteFile(path, raw, 0600) != nil {
			t.Fatal("publish second fixture")
		}
	}
	active := map[string]Manifest{first.SHA256: first, second.SHA256: second}
	f.Active = func(_ context.Context, got Manifest) bool {
		want, ok := active[got.SHA256]
		return ok && got.Version == want.Version && got.ManifestSHA == want.ManifestSHA
	}
	mux := http.NewServeMux()
	f.Register(mux)
	call := func(path, rangeValue string) *httptest.ResponseRecorder {
		r := httptest.NewRequest("GET", path, nil)
		r.Header.Set("Range", rangeValue)
		w := httptest.NewRecorder()
		mux.ServeHTTP(w, r)
		return w
	}
	firstPath := "/api/v1/food-catalog/exports/" + first.SHA256 + "/" + exportName
	secondPath := "/api/v1/food-catalog/exports/" + second.SHA256 + "/" + exportName
	latestPath := "/api/v1/food-catalog/exports/" + exportName
	if out := call(firstPath, "bytes=0-4"); out.Code != 206 || !bytes.Equal(out.Body.Bytes(), firstData[:5]) || out.Header().Get("ETag") != `"`+first.Exports[0].SHA256+`"` {
		t.Fatal("old release lost exact source/Range identity", out.Code)
	}
	for _, path := range []string{latestPath, secondPath} {
		if out := call(path, ""); out.Code != 200 || !bytes.Equal(out.Body.Bytes(), secondData) {
			t.Fatal("current legacy layout unavailable", path, out.Code)
		}
	}
	// The publish helper moves (rather than copies) large files before activation.
	secondDirectory := filepath.Join(f.ExportsDirectory, second.SHA256)
	if os.Mkdir(secondDirectory, 0700) != nil || os.WriteFile(filepath.Join(secondDirectory, "manifest.json"), secondRaw, 0600) != nil ||
		os.Rename(filepath.Join(f.ExportsDirectory, exportName), filepath.Join(secondDirectory, exportName)) != nil {
		t.Fatal("move latest source export")
	}
	if out := call(latestPath, ""); out.Code != 200 || !bytes.Equal(out.Body.Bytes(), secondData) {
		t.Fatal("latest did not follow moved current source", out.Code)
	}
	if os.WriteFile(filepath.Join(f.ExportsDirectory, exportName), []byte("stale legacy file"), 0600) != nil {
		t.Fatal("legacy precedence fixture")
	}
	if out := call(secondPath, ""); out.Code != 200 || !bytes.Equal(out.Body.Bytes(), secondData) {
		t.Fatal("versioned current did not prefer immutable folder", out.Code)
	}
	for _, path := range []string{
		"/api/v1/food-catalog/exports/" + strings.Repeat("f", 64) + "/" + exportName,
		"/api/v1/food-catalog/exports/" + strings.Repeat("a", 63) + "/" + exportName,
		"/api/v1/food-catalog/exports/%2e%2e/" + exportName,
		"/api/v1/food-catalog/exports/" + first.SHA256 + "/%2e%2e%2fmanifest.json",
		firstPath + "?file=../private", "/api/v1/food-catalog/exports/" + first.SHA256 + "/undeclared.jsonl.gz",
	} {
		if out := call(path, ""); out.Code != 404 {
			t.Fatal("unknown/traversal export not rejected", path, out.Code)
		}
	}
	delete(active, first.SHA256)
	if out := call(firstPath, ""); out.Code != 404 {
		t.Fatal("unactivated archived source distributed", out.Code)
	}
	active[first.SHA256] = first
	if os.WriteFile(filepath.Join(firstDirectory, "manifest.json"), secondRaw, 0600) != nil {
		t.Fatal("wrong archive identity fixture")
	}
	if out := call(firstPath, ""); out.Code != 404 {
		t.Fatal("signed archived manifest did not match requested artifact", out.Code)
	}
}
