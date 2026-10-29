package main

import (
	"context"
	"fmt"
	"os"
	"time"
	"trainforge.local/api/internal/catalogschema"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	apply := catalogschema.Apply
	if os.Getenv("TF_CATALOG_MODE") == "local" {
		apply = catalogschema.ApplyLocal
	} else if mode := os.Getenv("TF_CATALOG_MODE"); mode != "" && mode != "fixture" {
		fmt.Fprintln(os.Stderr, "catalog_mode_invalid")
		os.Exit(1)
	}
	n, err := apply(ctx, os.Getenv("TF_CATALOG_MIGRATION_DATABASE_URL"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "catalog_migration_failed")
		os.Exit(1)
	}
	fmt.Printf("catalog_migrations_applied=%d\n", n)
}
