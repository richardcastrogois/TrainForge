package nutrition

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
)

func hash(data []byte) string { sum := sha256.Sum256(data); return hex.EncodeToString(sum[:]) }

type Loaded struct {
	root        *os.Root
	manifest    FoodManifest
	review      Review
	sources     map[string]ReviewedSource
	columns     map[string]map[string]ColumnSpec
	ManifestSHA string
}

func (l *Loaded) Close() error { return l.root.Close() }
func readSmall(root *os.Root, path string, limit int64) ([]byte, error) {
	if !filepath.IsLocal(path) {
		return nil, errors.New("food path is not local")
	}
	f, err := root.Open(filepath.FromSlash(path))
	if err != nil {
		return nil, errors.New("food input unavailable")
	}
	defer f.Close()
	info, err := f.Stat()
	if err != nil || !info.Mode().IsRegular() || info.Size() > limit {
		return nil, errors.New("food metadata too large or not regular")
	}
	body, err := io.ReadAll(io.LimitReader(f, limit+1))
	if err != nil || int64(len(body)) > limit {
		return nil, errors.New("food metadata read failed")
	}
	return body, nil
}
func verifyReference(root *os.Root, a Artifact, limit int64) error {
	if !shaPattern.MatchString(a.SHA) || !filepath.IsLocal(a.Path) {
		return errors.New("invalid food reference")
	}
	f, err := root.Open(filepath.FromSlash(a.Path))
	if err != nil {
		return errors.New("food reference unavailable")
	}
	defer f.Close()
	stat, err := f.Stat()
	if err != nil || !stat.Mode().IsRegular() || stat.Size() > limit {
		return errors.New("food reference too large or not regular")
	}
	sum := sha256.New()
	n, err := io.Copy(sum, io.LimitReader(f, limit+1))
	if err != nil || n > limit || hex.EncodeToString(sum.Sum(nil)) != a.SHA {
		return errors.New("food reference hash mismatch")
	}
	return nil
}
func decodeStrict(body []byte, target any) error {
	d := json.NewDecoder(bytes.NewReader(body))
	d.DisallowUnknownFields()
	if d.Decode(target) != nil {
		return errors.New("invalid food schema")
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return errors.New("trailing food JSON")
	}
	return nil
}
func Load(rootPath, manifestPath string) (_ *Loaded, err error) {
	dir, e := os.OpenRoot(rootPath)
	if e != nil {
		return nil, errors.New("food repository unavailable")
	}
	loaded := &Loaded{root: dir, sources: map[string]ReviewedSource{}, columns: map[string]map[string]ColumnSpec{}}
	defer func() {
		if err != nil {
			dir.Close()
		}
	}()
	raw, e := readSmall(dir, manifestPath, 2<<20)
	if e != nil {
		return nil, e
	}
	loaded.ManifestSHA = hash(raw)
	if json.Unmarshal(raw, &loaded.manifest) != nil {
		return nil, errors.New("invalid food manifest")
	}
	m := loaded.manifest
	if m.Schema != "1.0.0" || m.Stage != "approved_food_consultation_operations" || m.Scope != "isolated_development_food_consultation" ||
		m.Clinical || m.BundleID == "" || m.Output.Rows < 1 || m.Output.Rows > 100000 || !strings.HasPrefix(m.Output.Path, "content/local/") ||
		!shaPattern.MatchString(m.Output.SHA) {
		return nil, errors.New("food manifest not approved for local source consultation")
	}
	if verifyReference(dir, m.Review, 2<<20) != nil {
		return nil, errors.New("food review hash mismatch")
	}
	raw, e = readSmall(dir, m.Review.Path, 2<<20)
	if e != nil {
		return nil, e
	}
	if json.Unmarshal(raw, &loaded.review) != nil {
		return nil, errors.New("invalid food source review")
	}
	r := loaded.review
	if r.Contract != "trainforge.food-review/1" || r.Stage != "reviewed_source_operations" || r.Scope != m.Scope || r.Reviewer == "" || r.Clinical || len(r.Sources) < 1 || len(r.Sources) > 2 {
		return nil, errors.New("food source operations not reviewed")
	}
	known := map[string]bool{}
	for _, g := range r.Groups.Known {
		if known[g] || g == "" {
			return nil, errors.New("invalid source group policy")
		}
		known[g] = true
	}
	for _, g := range r.Groups.Alcohol {
		if !known[g] {
			return nil, errors.New("invalid source alcohol group")
		}
	}
	for _, s := range r.Sources {
		if loaded.sources[s.ID].ID != "" || !s.Rights || !s.Fidelity || !validCitation(s.Citation) || !shaPattern.MatchString(s.SnapshotSHA) || !shaPattern.MatchString(s.PreparedSHA) {
			return nil, errors.New("food source review/attribution missing")
		}
		if (s.ID != "AL-CIQUAL-2025" || s.Version != "2025") && (s.ID != "AL-COFID-2021" || s.Version != "2021") {
			return nil, errors.New("food source adapter unavailable")
		}
		if s.ID == "AL-COFID-2021" && len(known) == 0 {
			return nil, errors.New("CoFID source group policy absent")
		}
		for _, op := range operations {
			if s.Operations[op] != "allowed" {
				return nil, errors.New("unapproved source food operation")
			}
		}
		loaded.sources[s.ID] = s
	}
	if len(r.Evidence) == 0 {
		return nil, errors.New("food review evidence absent")
	}
	for _, a := range r.Evidence {
		if verifyReference(dir, a, 16<<20) != nil {
			return nil, errors.New("food review evidence changed")
		}
	}
	if verifyReference(dir, m.Preflight, 2<<20) != nil {
		return nil, errors.New("food preflight changed")
	}
	raw, e = readSmall(dir, m.Preflight.Path, 2<<20)
	if e != nil {
		return nil, e
	}
	var preflight struct {
		Contract string   `json:"contract"`
		Local    Artifact `json:"localManifest"`
		Sources  []struct {
			ID     string     `json:"sourceId"`
			Inputs []Artifact `json:"inputs"`
		} `json:"sources"`
	}
	if json.Unmarshal(raw, &preflight) != nil || preflight.Contract != "trainforge.food-staging/1" || len(preflight.Sources) != len(r.Sources) {
		return nil, errors.New("invalid food preflight")
	}
	seenPreflight := map[string]bool{}
	for _, s := range preflight.Sources {
		reviewed, ok := loaded.sources[s.ID]
		if !ok || seenPreflight[s.ID] || len(s.Inputs) != 3 || s.Inputs[0].SHA != reviewed.PreparedSHA || s.Inputs[1].SHA != reviewed.SnapshotSHA {
			return nil, errors.New("food preflight source mismatch")
		}
		seenPreflight[s.ID] = true
		for _, a := range s.Inputs {
			if verifyReference(dir, a, 256<<20) != nil {
				return nil, errors.New("original food input changed")
			}
		}
	}
	if verifyReference(dir, preflight.Local, 2<<20) != nil {
		return nil, errors.New("food source column dictionary changed")
	}
	raw, e = readSmall(dir, preflight.Local.Path, 2<<20)
	if e != nil {
		return nil, e
	}
	var dictionary struct {
		Contract string `json:"contract"`
		Sources  []struct {
			ID     string                  `json:"sourceId"`
			Tables map[string][]ColumnSpec `json:"columnsByTable"`
		} `json:"sources"`
	}
	if json.Unmarshal(raw, &dictionary) != nil || dictionary.Contract != "trainforge.food-staging/1" || len(dictionary.Sources) != len(r.Sources) {
		return nil, errors.New("invalid food source column dictionary")
	}
	for _, source := range dictionary.Sources {
		if _, ok := loaded.sources[source.ID]; !ok || loaded.columns[source.ID] != nil {
			return nil, errors.New("unknown/duplicate column source")
		}
		specs := map[string]ColumnSpec{}
		for _, columns := range source.Tables {
			for _, c := range columns {
				if c.ID == "" || specs[c.ID].ID != "" {
					return nil, errors.New("invalid/duplicate source column")
				}
				specs[c.ID] = c
			}
		}
		if len(specs) == 0 {
			return nil, errors.New("food source columns missing")
		}
		loaded.columns[source.ID] = specs
	}
	if e = loaded.Walk(nil); e != nil {
		return nil, e
	}
	return loaded, nil
}
func (l *Loaded) Walk(visit func(Food, string) error) error {
	f, err := l.root.Open(filepath.FromSlash(l.manifest.Output.Path))
	if err != nil {
		return errors.New("reviewed food artifact unavailable")
	}
	defer f.Close()
	stat, err := f.Stat()
	if err != nil || !stat.Mode().IsRegular() || stat.Size() > 512<<20 {
		return errors.New("reviewed food artifact too large")
	}
	sum := sha256.New()
	scanner := bufio.NewScanner(io.TeeReader(io.LimitReader(f, (512<<20)+1), sum))
	scanner.Buffer(make([]byte, 65536), 2<<20)
	seen := map[string]bool{}
	seenSources := map[string]bool{}
	count := 0
	for scanner.Scan() {
		raw := scanner.Bytes()
		if len(bytes.TrimSpace(raw)) == 0 {
			return errors.New("blank food row rejected")
		}
		var food Food
		if decodeStrict(raw, &food) != nil {
			return errors.New("invalid reviewed food row")
		}
		source, ok := l.sources[food.SourceID]
		if !ok || seen[food.ID] || validateFood(food, source, l.manifest.Review.SHA, l.review.Groups, l.columns[food.SourceID]) != nil {
			return errors.New("food row is outside reviewed source contract")
		}
		seen[food.ID] = true
		seenSources[food.SourceID] = true
		count++
		if count > l.manifest.Output.Rows {
			return errors.New("food artifact row count mismatch")
		}
		if visit != nil {
			if err := visit(food, hash(raw)); err != nil {
				return err
			}
		}
	}
	if scanner.Err() != nil || count != l.manifest.Output.Rows || len(seenSources) != len(l.sources) || hex.EncodeToString(sum.Sum(nil)) != l.manifest.Output.SHA {
		return errors.New("food artifact coverage/hash mismatch")
	}
	return nil
}

type ImportResult struct {
	DryRun      bool   `json:"dryRun"`
	Total       int    `json:"totalFoods"`
	Inserted    int    `json:"inserted"`
	Unchanged   int    `json:"unchanged"`
	ArtifactSHA string `json:"artifactSha256"`
}

func (l *Loaded) DryRun() ImportResult {
	return ImportResult{DryRun: true, Total: l.manifest.Output.Rows, ArtifactSHA: l.manifest.Output.SHA}
}
