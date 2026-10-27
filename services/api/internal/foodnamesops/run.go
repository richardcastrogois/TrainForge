package foodnamesops

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"github.com/jackc/pgx/v5"
	"io"
	"regexp"
	"time"
	"trainforge.local/api/internal/nutrition"
	"trainforge.local/api/internal/platform/postgres"
)

var errOptions = errors.New("use check-publish/check-withdraw with --package; writes additionally require --confirm and --verified-reviewer-ref after human verification")
var errTarget = errors.New("editorial command restricted to explicit owned local database and role; connection details withheld")
var testTarget = regexp.MustCompile(`^trainforge_v1_names_test_[a-f0-9]{12}$`)

func validateTarget(dsn string, write bool) error {
	c, err := pgx.ParseConfig(dsn)
	if dsn == "" || err != nil || c.Host != "127.0.0.1" || c.Port != 15432 || (c.Database != "trainforge_v1_dev" && !testTarget.MatchString(c.Database)) || (c.User != "trainforge_runtime" && c.User != "trainforge_migrator") || (write && c.User != "trainforge_migrator") || len(c.RuntimeParams) != 0 {
		return errTarget
	}
	for _, fallback := range c.Fallbacks {
		if fallback.Host != "127.0.0.1" || fallback.Port != 15432 {
			return errTarget
		}
	}
	return nil
}

type receipt struct {
	Contract        string `json:"contract"`
	Operation       string `json:"operation"`
	Scope           string `json:"scope"`
	PackageSHA      string `json:"packageSha256"`
	FoodID          string `json:"foodId"`
	FoodVersion     string `json:"foodVersion"`
	Locale          string `json:"locale"`
	NameVersion     string `json:"nameVersion"`
	ReviewerRef     string `json:"reviewerRef"`
	DatabaseChecked bool   `json:"databaseChecked"`
	Inserted        bool   `json:"inserted"`
	Note            string `json:"note"`
}

// Run defaults to filesystem-only preflight. A confirmation is bound to exact
// package bytes and reviewer reference. It is an operator acknowledgement, not
// authentication or automatic proof of review. The DB role is the write boundary.
func Run(args []string, getenv func(string) string, out io.Writer) error {
	f := flag.NewFlagSet("food-names", flag.ContinueOnError)
	f.SetOutput(io.Discard)
	operation := f.String("operation", "check-publish", "check-publish, check-withdraw, publish, withdraw or coverage")
	dir := f.String("package", "", "directory with fixed editorial package files")
	confirm := f.String("confirm", "", "exact preflight package SHA-256")
	reviewer := f.String("verified-reviewer-ref", "", "human-verified reviewer reference, matching the package")
	if f.Parse(args) != nil || f.NArg() != 0 {
		return errOptions
	}
	if *operation == "coverage" {
		if *dir != "" || *confirm != "" || *reviewer != "" {
			return errOptions
		}
		dsn := getenv("TF_FOOD_NAMES_DATABASE_URL")
		if err := validateTarget(dsn, false); err != nil {
			return err
		}
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		pool, err := postgres.Open(ctx, dsn, 1)
		if err != nil {
			return errTarget
		}
		defer pool.Close()
		coverage, err := nutrition.ReadFoodNameCoverage(ctx, pool)
		if err != nil {
			return err
		}
		return json.NewEncoder(out).Encode(coverage)
	}
	action := *operation
	check := false
	switch action {
	case "check-publish":
		action = "publish"
		check = true
	case "check-withdraw":
		action = "withdraw"
		check = true
	case "publish", "withdraw":
	default:
		return errOptions
	}
	if check && (*confirm != "" || *reviewer != "") {
		return errOptions
	}
	p, err := Load(*dir, action, time.Now().UTC())
	if err != nil {
		return err
	}
	r := receipt{Contract: "trainforge.food-name-operation/1", Operation: *operation, Scope: "structure-and-matching-evidence-only", PackageSHA: p.Fingerprint, ReviewerRef: p.ReviewerRef(), Note: "Matching hashes do not prove human review or rights. Retain the package and independently verify reviewer identity, exact food/version/locale, aliases and display/search rights."}
	if p.Publication != nil {
		n := p.Publication
		r.FoodID = n.FoodID
		r.FoodVersion = n.FoodVersion
		r.Locale = n.Locale
		r.NameVersion = n.VersionID()
	} else {
		w := p.Withdrawal
		r.FoodID = w.FoodID
		r.FoodVersion = w.FoodVersion
		r.Locale = w.Locale
		r.NameVersion = w.NameVersion
	}
	if check {
		return json.NewEncoder(out).Encode(r)
	}
	// Refuse before connecting if any package byte or reviewer acknowledgement changed.
	if *confirm != p.Fingerprint || *reviewer != p.ReviewerRef() {
		return errOptions
	}
	dsn := getenv("TF_FOOD_NAMES_DATABASE_URL")
	if err := validateTarget(dsn, true); err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := postgres.Open(ctx, dsn, 1)
	if err != nil {
		return errTarget
	}
	defer pool.Close()
	if p.Publication != nil {
		_, r.Inserted, err = nutrition.StoreReviewedFoodNames(ctx, pool, *p.Publication, p.Evidence, time.Now().UTC())
	} else {
		r.Inserted, err = nutrition.StoreFoodNameWithdrawal(ctx, pool, *p.Withdrawal, p.Decision, time.Now().UTC())
	}
	if err != nil {
		return err
	}
	r.DatabaseChecked = true
	r.Scope = "immutable-editorial-record"
	r.Note = "Stored record is not a claim of current displayability. Replay does not revive withdrawn names; current source visibility and latest withdrawals govern reads. Retain this receipt and the evidence package."
	return json.NewEncoder(out).Encode(r)
}
