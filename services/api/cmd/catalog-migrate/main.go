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
	n, err := catalogschema.Apply(ctx, os.Getenv("TF_CATALOG_MIGRATION_DATABASE_URL"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "catalog_migration_failed")
		os.Exit(1)
	}
	fmt.Printf("catalog_migrations_applied=%d\n", n)
}
