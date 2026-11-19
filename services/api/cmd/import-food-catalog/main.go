package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"regexp"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"trainforge.local/api/internal/nutrition"
)

func main() {
	if e := run(os.Args[1:], os.Getenv, os.Stdout); e != nil {
		fmt.Fprintln(os.Stderr, e)
		os.Exit(1)
	}
}
func run(args []string, getenv func(string) string, out io.Writer) error {
	f := flag.NewFlagSet("import-food-catalog", flag.ContinueOnError)
	f.SetOutput(io.Discard)
	op := f.String("operation", "verify", "verify, stage or activate; default does not access a database")
	manifestPath := f.String("manifest", "../../assets/food_catalog/manifest.json", "signed catalog manifest")
	trustPath := f.String("trust", "../../assets/food_catalog/trust.json", "separately trusted maintainer key file")
	exports := f.String("exports", "../../.local/food-catalog/exports", "directory containing declared JSONL gzip exports")
	confirm := f.String("confirm", "", "exact catalog SHA256 for stage/activate")
	if f.Parse(args) != nil || f.NArg() != 0 {
		return errors.New("invalid catalog import options")
	}
	if *op != "verify" && *op != "stage" && *op != "activate" {
		return errors.New("unknown catalog import operation")
	}
	m, e := nutrition.VerifyCatalogManifest(*manifestPath, *trustPath)
	if e != nil {
		return e
	}
	encoder := json.NewEncoder(out)
	if *op == "verify" {
		if *confirm != "" {
			return errors.New("verify has no write confirmation")
		}
		if e = nutrition.VerifyFoodCatalogExports(m, *exports); e != nil {
			return e
		}
		return encoder.Encode(map[string]any{"verified": true, "databaseWrites": 0, "artifactSha256": m.SHA256, "version": m.Version, "rows": m.Counts["foods"]})
	}
	if *confirm != m.SHA256 {
		return errors.New("explicit artifact SHA confirmation required; nothing imported")
	}
	dsn := getenv("TF_FOOD_CATALOG_DATABASE_URL")
	cfg, e := pgx.ParseConfig(dsn)
	if dsn == "" || e != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || cfg.User != "trainforge_migrator" || (cfg.Database != "trainforge_v1_dev" && !regexp.MustCompile(`^trainforge_v1_privacy_test_[a-f0-9]{12}$`).MatchString(cfg.Database)) || len(cfg.RuntimeParams) != 0 {
		return errors.New("catalog writes require explicit owned local migrator target; connection details withheld")
	}
	for _, fallback := range cfg.Fallbacks {
		if fallback.Host != "127.0.0.1" || fallback.Port != 15432 {
			return errors.New("external catalog database fallback refused")
		}
	}
	// Streaming sources can be large. Cancellation remains available, and each
	// bounded committed batch can be resumed without activating partial data.
	ctx, cancel := context.WithTimeout(context.Background(), 24*time.Hour)
	defer cancel()
	pool, e := pgxpool.New(ctx, dsn)
	if e != nil {
		return errors.New("catalog writer unavailable")
	}
	defer pool.Close()
	var role string
	if pool.QueryRow(ctx, "SELECT current_user").Scan(&role) != nil || role != "trainforge_migrator" {
		return errors.New("catalog writer role refused")
	}
	var result nutrition.CatalogImportResult
	if *op == "stage" {
		result, e = nutrition.StageFoodCatalog(ctx, pool, m, *exports)
	} else {
		result, e = nutrition.ActivateFoodCatalog(ctx, pool, m)
	}
	if e != nil {
		return e
	}
	return encoder.Encode(result)
}
