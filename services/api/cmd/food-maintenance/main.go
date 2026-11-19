package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"time"
	"trainforge.local/api/internal/nutrition"
)

func main() {
	if e := run(os.Args[1:], os.Getenv, os.Stdout); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
func run(args []string, getenv func(string) string, out io.Writer) error {
	f := flag.NewFlagSet("food-maintenance", flag.ContinueOnError)
	f.SetOutput(io.Discard)
	op := f.String("operation", "list", "list, show, media, approve, reject or export-approved")
	id := f.String("id", "", "exact contribution UUID")
	confirm := f.String("confirm", "", "fingerprint from show, after checking label and values")
	note := f.String("note", "", "review reason, without personal information")
	after := f.String("after", "", "last listed UUID; list page size is 50")
	mediaID := f.String("media-id", "", "exact label photo UUID for private review")
	output := f.String("output", "", "new local JPEG path, never overwritten")
	if f.Parse(args) != nil || f.NArg() != 0 {
		return errors.New("invalid food-maintenance options")
	}
	switch *op {
	case "list", "show", "media", "approve", "reject", "export-approved":
	default:
		return errors.New("unknown maintenance operation")
	}
	write := *op == "approve" || *op == "reject"
	if write && (*confirm == "" || *note == "") {
		return errors.New("review requires exact --id, --confirm fingerprint and --note; no approval inferred")
	}
	if !write && (*confirm != "" || *note != "") {
		return errors.New("confirmation only applies to an explicit decision")
	}
	if (*op == "show" || *op == "media" || write) && *id == "" {
		return errors.New("exact contribution ID required")
	}
	if *op == "media" && (*mediaID == "" || *output == "" || filepath.Ext(*output) != ".jpg") {
		return errors.New("private photo review requires --media-id and a new --output .jpg path")
	}
	if *op != "media" && (*mediaID != "" || *output != "") {
		return errors.New("photo output applies only to media review")
	}
	dsn := getenv("TF_FOOD_MAINTENANCE_DATABASE_URL")
	cfg, e := pgx.ParseConfig(dsn)
	validDB := regexp.MustCompile(`^trainforge_v1_privacy_test_[a-f0-9]{12}$`)
	if dsn == "" || e != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || cfg.User != "trainforge_migrator" || (cfg.Database != "trainforge_v1_dev" && !validDB.MatchString(cfg.Database)) || len(cfg.RuntimeParams) != 0 {
		return errors.New("explicit owned local maintainer target required; connection details withheld")
	}
	for _, fallback := range cfg.Fallbacks {
		if fallback.Host != "127.0.0.1" || fallback.Port != 15432 {
			return errors.New("external fallback refused")
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, e := pgxpool.New(ctx, dsn)
	if e != nil {
		return errors.New("maintainer connection unavailable")
	}
	defer pool.Close()
	encoder := json.NewEncoder(out)
	switch *op {
	case "list":
		v, e := nutrition.ListFoodContributionsForReview(ctx, pool, *after, 50)
		if e != nil {
			return e
		}
		return encoder.Encode(v)
	case "show":
		v, e := nutrition.ReviewFoodContribution(ctx, pool, *id)
		if e != nil {
			return e
		}
		return encoder.Encode(v)
	case "media":
		raw, e := nutrition.ReviewContributionMedia(ctx, pool, *id, *mediaID)
		if e != nil {
			return e
		}
		file, e := os.OpenFile(*output, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0600)
		if e != nil {
			return errors.New("private photo output unavailable; existing files are never overwritten")
		}
		_, e = file.Write(raw)
		closeErr := file.Close()
		if e != nil || closeErr != nil {
			return errors.New("private photo output incomplete")
		}
		return encoder.Encode(map[string]any{"saved": true, "contributionId": *id, "mediaId": *mediaID})
	case "approve", "reject":
		decision := "approved"
		if *op == "reject" {
			decision = "rejected"
		}
		v, e := nutrition.DecideFoodContribution(ctx, pool, *id, decision, *confirm, *note)
		if e != nil {
			return e
		}
		return encoder.Encode(v)
	case "export-approved":
		return nutrition.ExportApprovedContributions(ctx, pool, out)
	}
	return nil
}
