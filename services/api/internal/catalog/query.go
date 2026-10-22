package catalog

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/url"
	"regexp"
	"strconv"
	"strings"
)

var assetIDPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9:._-]{0,254}$`)
var versionPattern = regexp.MustCompile(`^[a-f0-9]{64}$`)

type cursor struct {
	After  string `json:"after"`
	Filter string `json:"filter"`
}

func fingerprint(f Filters) string {
	f.After = ""
	data, _ := json.Marshal(f)
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}
func encodeCursor(after string, f Filters) (string, error) {
	b, err := json.Marshal(cursor{after, fingerprint(f)})
	return base64.RawURLEncoding.EncodeToString(b), err
}
func parseFilters(q url.Values, kinds []string) (Filters, error) {
	f := Filters{Kinds: kinds, Limit: 20, Mode: "consultation"}
	allowed := map[string]bool{"limit": true, "cursor": true, "q": true, "environment": true, "population": true, "modality": true, "equipment": true, "category": true, "mode": true}
	for k, v := range q {
		if !allowed[k] || len(v) != 1 || len(v[0]) > 1024 {
			return f, ErrQuery
		}
	}
	if value := q.Get("limit"); value != "" {
		n, e := strconv.Atoi(value)
		if e != nil || n < 1 || n > 50 {
			return f, ErrQuery
		}
		f.Limit = n
	}
	for _, pair := range []struct {
		key string
		dst *string
	}{
		{"q", &f.Q}, {"environment", &f.Environment}, {"population", &f.Population}, {"modality", &f.Modality}, {"equipment", &f.Equipment}, {"category", &f.Category},
	} {
		value := strings.TrimSpace(q.Get(pair.key))
		if len(value) > 100 || strings.IndexFunc(value, func(r rune) bool { return r < 32 || r == 127 }) >= 0 {
			return f, ErrQuery
		}
		*pair.dst = value
	}
	if value := q.Get("mode"); value != "" {
		f.Mode = value
	}
	if f.Mode != "consultation" && f.Mode != "practice" {
		return f, ErrQuery
	}
	if token := q.Get("cursor"); token != "" {
		raw, e := base64.RawURLEncoding.DecodeString(token)
		if e != nil {
			return f, ErrQuery
		}
		var c cursor
		decoder := json.NewDecoder(bytes.NewReader(raw))
		decoder.DisallowUnknownFields()
		if decoder.Decode(&c) != nil || !assetIDPattern.MatchString(c.After) || c.Filter != fingerprint(f) {
			return f, ErrQuery
		}
		var extra any
		if decoder.Decode(&extra) != io.EOF {
			return f, ErrQuery
		}
		f.After = c.After
	}
	return f, nil
}
func parseDetail(q url.Values) (string, string, error) {
	for k, v := range q {
		if (k != "versionId" && k != "mode") || len(v) != 1 {
			return "", "", ErrQuery
		}
	}
	version := q.Get("versionId")
	if version != "" && !versionPattern.MatchString(version) {
		return "", "", ErrQuery
	}
	mode := q.Get("mode")
	if mode == "" {
		mode = "consultation"
	}
	if mode != "consultation" && mode != "practice" {
		return "", "", ErrQuery
	}
	return version, mode, nil
}
