// Package foodnamesops provides local operator tooling, outside the public API.
// Validation proves matching bytes and exact scope, never human identity/rights.
package foodnamesops

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"io"
	"os"
	"path/filepath"
	"time"
	"trainforge.local/api/internal/nutrition"
)

var ErrPackage = errors.New("invalid editorial package; check fixed files, limits and evidence hashes")

type Package struct {
	Publication *nutrition.ReviewedFoodNames
	Withdrawal  *nutrition.FoodNameWithdrawal
	Evidence    nutrition.NameEvidence
	Decision    []byte
	Fingerprint string
}

// Only explicitly named regular files are read. No URL fetch, template expansion,
// installation, generated translation or database access occurs during Load.
func readFile(dir, name string, limit int64) ([]byte, error) {
	path := filepath.Join(dir, name)
	before, err := os.Lstat(path)
	if err != nil || !before.Mode().IsRegular() || before.Size() > limit {
		return nil, ErrPackage
	}
	f, err := os.Open(path)
	if err != nil {
		return nil, ErrPackage
	}
	defer f.Close()
	opened, err := f.Stat()
	if err != nil || !opened.Mode().IsRegular() || !os.SameFile(before, opened) {
		return nil, ErrPackage
	}
	raw, err := io.ReadAll(io.LimitReader(f, limit+1))
	if err != nil || len(raw) == 0 || int64(len(raw)) > limit {
		return nil, ErrPackage
	}
	return raw, nil
}
func Load(dir, operation string, now time.Time) (Package, error) {
	var p Package
	if dir == "" || (operation != "publish" && operation != "withdraw") {
		return p, ErrPackage
	}
	h := sha256.New()
	h.Write([]byte("trainforge.food-name-package/1:" + operation))
	read := func(name string, limit int64) ([]byte, error) {
		raw, err := readFile(dir, name, limit)
		if err != nil {
			return nil, err
		}
		h.Write([]byte(name))
		binary.Write(h, binary.BigEndian, uint64(len(raw)))
		h.Write(raw)
		return raw, nil
	}
	raw, err := read("record.json", 65536)
	if err != nil {
		return p, err
	}
	if operation == "publish" {
		n, err := nutrition.DecodeReviewedFoodNames(raw, now)
		if err != nil {
			return p, ErrPackage
		}
		p.Publication = &n
		p.Evidence.ReviewDocument, err = read("review.txt", 1048576)
		if err != nil {
			return p, err
		}
		p.Evidence.RightsDocument, err = read("rights.txt", 1048576)
		if err != nil || p.Evidence.Validate(n) != nil {
			return p, ErrPackage
		}
	} else {
		w, err := nutrition.DecodeFoodNameWithdrawal(raw, now)
		if err != nil {
			return p, ErrPackage
		}
		p.Withdrawal = &w
		p.Decision, err = read("decision.txt", 1048576)
		if err != nil {
			return p, err
		}
		sum := sha256.Sum256(p.Decision)
		if hex.EncodeToString(sum[:]) != w.EvidenceSHA {
			return p, ErrPackage
		}
	}
	p.Fingerprint = hex.EncodeToString(h.Sum(nil))
	return p, nil
}
func (p Package) ReviewerRef() string {
	if p.Publication != nil {
		return p.Publication.Review.ReviewerRef
	}
	return p.Withdrawal.ReviewerRef
}
