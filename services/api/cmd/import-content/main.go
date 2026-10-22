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
	"trainforge.local/api/internal/catalog"
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
	manifest := flag.String("manifest", "content/manifests/pilot-approved.json", "reviewed manifest")
	dry := flag.Bool("dry-run", false, "validate without database access")
	flag.Parse()
	loaded, err := catalog.Load(*root, *manifest)
	if err != nil {
		return err
	}
	if *dry {
		return json.NewEncoder(os.Stdout).Encode(catalog.Result{DryRun: true, Total: len(loaded.Assets), ArtifactSHA: loaded.ArtifactSHA})
	}
	dsn := os.Getenv("TF_IMPORT_DATABASE_URL")
	cfg, err := pgx.ParseConfig(dsn)
	if dsn == "" || err != nil || cfg.Host != "127.0.0.1" || cfg.Database != "trainforge_v1_dev" || cfg.Port != 15432 {
		return errors.New("import is restricted to the isolated local development database")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := postgres.Open(ctx, dsn, 2)
	if err != nil {
		return err
	}
	defer pool.Close()
	result, err := catalog.Import(ctx, pool, loaded)
	if err != nil {
		return err
	}
	return json.NewEncoder(os.Stdout).Encode(result)
}
