package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"regexp"
	"time"
	"trainforge.local/api/internal/privacy"
)

func run() error {
	apply := flag.Bool("apply", false, "Apply bounded cleanup; default only reports candidates")
	flag.Parse()
	cfg, err := pgxpool.ParseConfig(os.Getenv("TF_PRIVACY_MAINTENANCE_DATABASE_URL"))
	if err != nil {
		return fmt.Errorf("maintenance configuration unavailable")
	}
	db := cfg.ConnConfig.Database
	if cfg.ConnConfig.Host != "127.0.0.1" || cfg.ConnConfig.Port != 15432 || (db != "trainforge_v1_dev" && !regexp.MustCompile("^trainforge_v1_privacy_test_[a-f0-9]{12}$").MatchString(db)) {
		return fmt.Errorf("maintenance target refused")
	}
	cfg.MaxConns = 2
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return fmt.Errorf("maintenance unavailable")
	}
	defer pool.Close()
	result, err := privacy.Maintain(ctx, pool, *apply)
	if err != nil {
		return fmt.Errorf("maintenance failed; no details with credentials")
	}
	return json.NewEncoder(os.Stdout).Encode(result)
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
