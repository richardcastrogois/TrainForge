// Package catalog preserves the reviewed source versions; no exercise is generated here.
package catalog

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"path/filepath"
	"strings"
)

type Manifest struct {
	Stage       string `json:"stage"`
	ImportScope string `json:"importScope"`
	Output      struct {
		Path string `json:"path"`
		SHA  string `json:"sha256"`
	} `json:"output"`
	Rows []struct {
		ID  string   `json:"assetId"`
		Ops []string `json:"allowedOperations"`
	} `json:"rows"`
}
type Source struct {
	ID, Name, Publisher string
	URLs                []string `json:"urls"`
}
type Asset struct {
	ID            string   `json:"id"`
	Kind          string   `json:"kind"`
	SourceID      string   `json:"sourceId"`
	Title         *string  `json:"title"`
	Locale        *string  `json:"locale"`
	SourceVersion *string  `json:"sourceVersion"`
	Allowed       []string `json:"allowedOperations"`
}
type Bundle struct {
	Schema  string            `json:"schemaVersion"`
	ID      string            `json:"bundleId"`
	Stage   string            `json:"stage"`
	Sources []Source          `json:"sources"`
	Assets  []json.RawMessage `json:"assets"`
}
type Loaded struct {
	Bundle                   Bundle
	ArtifactSHA, ManifestSHA string
	Assets                   []Asset
	Payloads                 [][]byte
	Versions                 []string
}
type Result struct {
	DryRun      bool   `json:"dryRun"`
	Total       int    `json:"totalAssets"`
	Inserted    int64  `json:"inserted"`
	Unchanged   int    `json:"unchanged"`
	ArtifactSHA string `json:"artifactSha256"`
}

func sum(data []byte) string { h := sha256.Sum256(data); return hex.EncodeToString(h[:]) }
func readInside(root, path string) ([]byte, error) {
	if filepath.IsAbs(path) {
		return nil, errors.New("absolute content path rejected")
	}
	base, err := filepath.Abs(root)
	if err != nil {
		return nil, errors.New("invalid root")
	}
	target := filepath.Join(base, filepath.FromSlash(path))
	rel, err := filepath.Rel(base, target)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return nil, errors.New("content path escapes repository")
	}
	// Resolve symlinks before reading an external manifest's referenced file.
	actual, err := filepath.EvalSymlinks(target)
	if err != nil {
		return nil, errors.New("content file missing")
	}
	rel, err = filepath.Rel(base, actual)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return nil, errors.New("content symlink escapes repository")
	}
	info, err := os.Stat(actual)
	if err != nil || info.Size() > 16<<20 {
		return nil, errors.New("content file unavailable or too large")
	}
	data, err := os.ReadFile(actual)
	if err != nil {
		return nil, errors.New("content read failed")
	}
	return data, nil
}
func Load(root, manifestPath string) (Loaded, error) {
	var loaded Loaded
	raw, err := readInside(root, manifestPath)
	if err != nil {
		return loaded, err
	}
	var manifest Manifest
	if json.Unmarshal(raw, &manifest) != nil || manifest.Stage != "approved_consultation_operations" || manifest.ImportScope != "isolated_development_consultation" {
		return loaded, errors.New("manifest not approved for local consultation import")
	}
	if !strings.HasPrefix(manifest.Output.Path, "content/local/") {
		return loaded, errors.New("unexpected content corpus")
	}
	body, err := readInside(root, manifest.Output.Path)
	if err != nil {
		return loaded, err
	}
	if sum(body) != manifest.Output.SHA {
		return loaded, errors.New("content hash mismatch")
	}
	loaded.ArtifactSHA = manifest.Output.SHA
	loaded.ManifestSHA = sum(raw)
	if json.Unmarshal(body, &loaded.Bundle) != nil || loaded.Bundle.Schema != "1.0.0" || loaded.Bundle.Stage != "approved_operations" {
		return loaded, errors.New("invalid reviewed bundle")
	}
	allowed := map[string]bool{}
	for _, r := range manifest.Rows {
		if allowed[r.ID] || len(r.Ops) != 1 || r.Ops[0] != "catalog_metadata" {
			return loaded, errors.New("unreviewed operation or duplicate decision")
		}
		allowed[r.ID] = true
	}
	sources := map[string]bool{}
	for _, s := range loaded.Bundle.Sources {
		if s.ID == "" || sources[s.ID] {
			return loaded, errors.New("invalid source")
		}
		sources[s.ID] = true
	}
	seen := map[string]bool{}
	for _, rawAsset := range loaded.Bundle.Assets {
		var a Asset
		var fields struct {
			Review struct {
				State    string `json:"state"`
				Reviewer string `json:"reviewer"`
				Rights   bool   `json:"rightsVerified"`
				Fidelity bool   `json:"fidelityChecked"`
			} `json:"review"`
			Rights struct {
				Attribution string            `json:"attribution"`
				License     string            `json:"licenseUrl"`
				Credits     map[string]any    `json:"displayCredits"`
				Grants      map[string]string `json:"operationGrants"`
			} `json:"rights"`
		}
		if json.Unmarshal(rawAsset, &a) != nil || json.Unmarshal(rawAsset, &fields) != nil {
			return loaded, errors.New("invalid editorial object")
		}
		if !allowed[a.ID] || seen[a.ID] || !sources[a.SourceID] || a.Kind != "movement" || len(a.Allowed) != 1 || a.Allowed[0] != "catalog_metadata" {
			return loaded, errors.New("asset outside consultation allowlist")
		}
		if fields.Review.State != "reviewed" || fields.Review.Reviewer == "" || !fields.Review.Rights || !fields.Review.Fidelity || fields.Rights.Attribution == "" || fields.Rights.License == "" || len(fields.Rights.Credits) == 0 || fields.Rights.Grants["catalog_metadata"] != "allowed" {
			return loaded, errors.New("asset review or attribution missing")
		}
		var value any
		decoder := json.NewDecoder(bytes.NewReader(rawAsset))
		decoder.UseNumber()
		if decoder.Decode(&value) != nil {
			return loaded, errors.New("invalid asset JSON")
		}
		canonical, err := json.Marshal(value)
		if err != nil {
			return loaded, errors.New("invalid asset content")
		}
		loaded.Assets = append(loaded.Assets, a)
		loaded.Payloads = append(loaded.Payloads, canonical)
		loaded.Versions = append(loaded.Versions, sum(canonical))
		seen[a.ID] = true
	}
	if len(seen) != len(allowed) {
		return loaded, errors.New("allowlist coverage mismatch")
	}
	return loaded, nil
}
func Import(ctx context.Context, pool *pgxpool.Pool, loaded Loaded) (Result, error) {
	result := Result{Total: len(loaded.Assets), ArtifactSHA: loaded.ArtifactSHA}
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return result, errors.New("import transaction unavailable")
	}
	defer tx.Rollback(ctx)
	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", int64(2026102101)); err != nil {
		return result, errors.New("import lock unavailable")
	}
	var prior int
	err = tx.QueryRow(ctx, "SELECT imported_assets FROM trainforge_v1.import_batches WHERE artifact_sha=$1", loaded.ArtifactSHA).Scan(&prior)
	if err == nil {
		var actual int
		err = tx.QueryRow(ctx, "SELECT count(*) FROM trainforge_v1.batch_content WHERE artifact_sha=$1", loaded.ArtifactSHA).Scan(&actual)
		if err != nil || actual != result.Total || prior != result.Total {
			return result, errors.New("existing batch integrity mismatch")
		}
		result.Unchanged = result.Total
		return result, tx.Commit(ctx)
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return result, errors.New("batch lookup failed")
	}
	used := map[string]bool{}
	for _, a := range loaded.Assets {
		used[a.SourceID] = true
	}
	for _, s := range loaded.Bundle.Sources {
		if !used[s.ID] {
			continue
		}
		urls, _ := json.Marshal(s.URLs)
		if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.sources(id,name,publisher,urls) VALUES($1,$2,$3,$4::jsonb) ON CONFLICT(id) DO NOTHING", s.ID, s.Name, s.Publisher, string(urls)); err != nil {
			return result, errors.New("source insert failed")
		}
	}
	if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.import_batches(artifact_sha,bundle_id,manifest_sha,imported_assets) VALUES($1,$2,$3,$4)", loaded.ArtifactSHA, loaded.Bundle.ID, loaded.ManifestSHA, result.Total); err != nil {
		return result, errors.New("batch insert failed")
	}
	for i, a := range loaded.Assets {
		tag, err := tx.Exec(ctx, "INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,locale,source_published_version,allowed_operations,payload) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb) ON CONFLICT(asset_id,version_sha) DO NOTHING", a.ID, loaded.Versions[i], a.Kind, a.SourceID, a.Title, a.Locale, a.SourceVersion, a.Allowed, string(loaded.Payloads[i]))
		if err != nil {
			return result, errors.New("asset insert failed")
		}
		result.Inserted += tag.RowsAffected()
		if _, err = tx.Exec(ctx, "INSERT INTO trainforge_v1.batch_content(artifact_sha,asset_id,version_sha) VALUES($1,$2,$3)", loaded.ArtifactSHA, a.ID, loaded.Versions[i]); err != nil {
			return result, errors.New("batch reference insert failed")
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return result, errors.New("import commit failed")
	}
	result.Unchanged = result.Total - int(result.Inserted)
	return result, nil
}
