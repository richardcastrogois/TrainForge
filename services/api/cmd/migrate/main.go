package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/pressly/goose/v3/lock"
	"os"
	"strings"
	"time"
	"trainforge.local/api/migrations"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
func run() error {
	dsn := os.Getenv("TF_MIGRATION_DATABASE_URL")
	cfg, err := pgx.ParseConfig(dsn)
	if dsn == "" || err != nil || !strings.HasPrefix(cfg.Database, "trainforge_v1_") || cfg.User == "" {
		return errors.New("explicit isolated migration database required")
	}
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return errors.New("migration connection invalid")
	}
	defer db.Close()
	db.SetMaxOpenConns(1)
	locker, err := lock.NewPostgresSessionLocker()
	if err != nil {
		return errors.New("migration lock invalid")
	}
	provider, err := goose.NewProvider(goose.DialectPostgres, db, migrations.Files, goose.WithTableName("trainforge_v1_schema_version"), goose.WithSessionLocker(locker))
	if err != nil {
		return errors.New("migration provider invalid")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	results, err := provider.Up(ctx)
	if err != nil {
		return errors.New("migration failed; inspect applied versions and database diagnostics before retrying")
	}
	fmt.Printf("applied_migrations=%d\n", len(results))
	return nil
}
