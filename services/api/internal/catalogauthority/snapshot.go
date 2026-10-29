// Package catalogauthority owns append-only editorial releases. No private rows are accepted.
package catalogauthority

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5"
	"io"
	"regexp"
	"sort"
)

var ErrUnavailable = errors.New("catalog authority unavailable")
var ErrConflict = errors.New("catalog release conflict")
var ErrPackage = errors.New("invalid catalog release package")
var digestPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)

const Contract = "trainforge.catalog.release.v1"
const ProjectionLock int64 = 724583016

type Queryer interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}
type Snapshot struct {
	Sources     []map[string]any `json:"sources"`
	Versions    []map[string]any `json:"versions"`
	Withdrawals []map[string]any `json:"withdrawals"`
}
type Head struct {
	Contract       string `json:"contract"`
	Revision       int64  `json:"revision"`
	Digest         string `json:"digest"`
	PreviousDigest string `json:"previousDigest"`
	PackageDigest  string `json:"packageDigest"`
}

func (h Head) Valid() bool {
	return h.Contract == Contract && h.Revision > 0 && digestPattern.MatchString(h.Digest) && digestPattern.MatchString(h.PackageDigest) && (h.PreviousDigest == "" || digestPattern.MatchString(h.PreviousDigest))
}
func Hash(raw []byte) string { h := sha256.Sum256(raw); return hex.EncodeToString(h[:]) }
func Canonical(s Snapshot) ([]byte, error) {
	if !s.Valid() {
		return nil, ErrPackage
	}
	s.Sources = append([]map[string]any{}, s.Sources...)
	s.Versions = append([]map[string]any{}, s.Versions...)
	s.Withdrawals = append([]map[string]any{}, s.Withdrawals...)
	sort.Slice(s.Sources, func(i, j int) bool { return s.Sources[i]["id"].(string) < s.Sources[j]["id"].(string) })
	less := func(a, b map[string]any) bool {
		if a["asset_id"] == b["asset_id"] {
			return a["version_sha"].(string) < b["version_sha"].(string)
		}
		return a["asset_id"].(string) < b["asset_id"].(string)
	}
	sort.Slice(s.Versions, func(i, j int) bool { return less(s.Versions[i], s.Versions[j]) })
	sort.Slice(s.Withdrawals, func(i, j int) bool { return less(s.Withdrawals[i], s.Withdrawals[j]) })
	return json.Marshal(s)
}
func Decode(raw []byte) (Snapshot, error) {
	var s Snapshot
	if len(raw) > 16<<20 {
		return s, ErrPackage
	}
	validation := json.NewDecoder(bytes.NewReader(raw))
	validation.UseNumber()
	if uniqueJSON(validation) != nil || validation.Decode(new(any)) != io.EOF {
		return s, ErrPackage
	}
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	d.DisallowUnknownFields()
	if d.Decode(&s) != nil || d.Decode(new(any)) != io.EOF || !s.Valid() {
		return s, ErrPackage
	}
	return s, nil
}
func only(row map[string]any, fields []string) bool {
	if len(row) != len(fields) {
		return false
	}
	for _, f := range fields {
		if _, ok := row[f]; !ok {
			return false
		}
	}
	return true
}
func (s Snapshot) Valid() bool {
	if s.Sources == nil || s.Versions == nil || s.Withdrawals == nil || len(s.Sources) > 10000 || len(s.Versions) > 10000 || len(s.Withdrawals) > 10000 {
		return false
	}
	sources := map[string]bool{}
	versions := map[string]bool{}
	for _, r := range s.Sources {
		id, ok := r["id"].(string)
		name, nok := r["name"].(string)
		_, urls := r["urls"].([]any)
		if !only(r, []string{"id", "name", "publisher", "urls", "created_at"}) || !ok || id == "" || len(id) > 200 || !nok || name == "" || !urls || sources[id] {
			return false
		}
		sources[id] = true
	}
	for _, r := range s.Versions {
		id, ok := r["asset_id"].(string)
		v, vok := r["version_sha"].(string)
		source, _ := r["source_id"].(string)
		kind, _ := r["kind"].(string)
		_, payload := r["payload"].(map[string]any)
		ops, opok := r["allowed_operations"].([]any)
		if !only(r, []string{"asset_id", "version_sha", "kind", "source_id", "title", "locale", "source_published_version", "allowed_operations", "payload", "created_at"}) || !ok || id == "" || len(id) > 300 || !vok || !digestPattern.MatchString(v) || !sources[source] || (kind != "movement" && kind != "program" && kind != "collection") || !payload || !opok || versions[id+"/"+v] {
			return false
		}
		for _, op := range ops {
			if op != "catalog_metadata" && op != "instruction_text" && op != "media_display" && op != "guided_practice" && op != "export_dataset" {
				return false
			}
		}
		versions[id+"/"+v] = true
	}
	seen := map[string]bool{}
	for _, r := range s.Withdrawals {
		a, _ := r["asset_id"].(string)
		v, _ := r["version_sha"].(string)
		reason, _ := r["reason"].(string)
		key := a + "/" + v
		if !only(r, []string{"asset_id", "version_sha", "reason", "withdrawn_at"}) || !versions[key] || reason == "" || seen[key] {
			return false
		}
		seen[key] = true
	}
	return true
}

// SQL selects only movement/program/collection provenance; food sources stay with nutrition.
const snapshotSQL = `SELECT jsonb_build_object(
 'sources',coalesce((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.id COLLATE "C") FROM trainforge_v1.sources s WHERE EXISTS(SELECT 1 FROM trainforge_v1.content_versions v WHERE v.source_id=s.id AND v.kind IN('movement','program','collection'))),'[]'::jsonb),
 'versions',coalesce((SELECT jsonb_agg(to_jsonb(v) ORDER BY v.asset_id COLLATE "C",v.version_sha COLLATE "C") FROM trainforge_v1.content_versions v WHERE v.kind IN('movement','program','collection')),'[]'::jsonb),
 'withdrawals',coalesce((SELECT jsonb_agg(to_jsonb(w) ORDER BY w.asset_id COLLATE "C",w.version_sha COLLATE "C") FROM trainforge_v1.content_withdrawals w JOIN trainforge_v1.content_versions v USING(asset_id,version_sha) WHERE v.kind IN('movement','program','collection')),'[]'::jsonb))`

func Read(ctx context.Context, q Queryer) (Snapshot, string, error) {
	var raw []byte
	if q == nil || q.QueryRow(ctx, snapshotSQL).Scan(&raw) != nil {
		return Snapshot{}, "", ErrUnavailable
	}
	s, e := Decode(raw)
	if e != nil {
		return s, "", ErrUnavailable
	}
	canonical, e := Canonical(s)
	if e != nil {
		return s, "", ErrUnavailable
	}
	return s, Hash(canonical), nil
}
func Current(ctx context.Context, q Queryer) (Head, error) {
	h := Head{Contract: Contract}
	if q == nil || q.QueryRow(ctx, `SELECT revision,digest,previous_digest,package_digest FROM trainforge_v1.catalog_releases ORDER BY revision DESC LIMIT 1`).Scan(&h.Revision, &h.Digest, &h.PreviousDigest, &h.PackageDigest) != nil || !h.Valid() {
		return Head{}, ErrUnavailable
	}
	return h, nil
}

// Extends rejects deletion, alteration and resurrection of any previously published row.
func Extends(old, next Snapshot) bool {
	for i, group := range [][]map[string]any{old.Sources, old.Versions, old.Withdrawals} {
		candidates := [][]map[string]any{next.Sources, next.Versions, next.Withdrawals}[i]
		set := map[string]bool{}
		for _, r := range candidates {
			b, _ := json.Marshal(r)
			set[string(b)] = true
		}
		for _, r := range group {
			b, _ := json.Marshal(r)
			if !set[string(b)] {
				return false
			}
		}
	}
	return true
}

func uniqueJSON(d *json.Decoder) error {
	token, e := d.Token()
	if e != nil {
		return e
	}
	delim, container := token.(json.Delim)
	if !container {
		return nil
	}
	if delim == '{' {
		seen := map[string]bool{}
		for d.More() {
			key, e := d.Token()
			if e != nil {
				return e
			}
			name, ok := key.(string)
			if !ok || seen[name] {
				return ErrPackage
			}
			seen[name] = true
			if e := uniqueJSON(d); e != nil {
				return e
			}
		}
	} else if delim == '[' {
		for d.More() {
			if e := uniqueJSON(d); e != nil {
				return e
			}
		}
	} else {
		return ErrPackage
	}
	_, e = d.Token()
	return e
}
