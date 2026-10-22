package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v5"
	"os"
	"time"
	"trainforge.local/api/internal/nutrition"
	"trainforge.local/api/internal/platform/postgres"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
func run() error {
	root := flag.String("root", "../..", "repository root")
	manifest := flag.String("manifest", "content/manifests/food-approved.json", "reviewed food manifest")
	dry := flag.Bool("dry-run", false, "validate all source rows without database access")
	flag.Parse()
	loaded, err := nutrition.Load(*root, *manifest)
	if err != nil {
		return err
	}
	defer loaded.Close()
	if *dry {
		return json.NewEncoder(os.Stdout).Encode(loaded.DryRun())
	}
	dsn := os.Getenv("TF_IMPORT_DATABASE_URL")
	cfg, err := pgx.ParseConfig(dsn)
	if dsn == "" || err != nil || cfg.Host != "127.0.0.1" || cfg.Port != 15432 || cfg.Database != "trainforge_v1_dev" {
		return errors.New("food import restricted to owned isolated local development database")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()
	pool, err := postgres.Open(ctx, dsn, 2)
	if err != nil {
		return err
	}
	defer pool.Close()
	result, err := nutrition.Import(ctx, pool, loaded)
	if err != nil {
		return err
	}
	return json.NewEncoder(os.Stdout).Encode(result)
}
