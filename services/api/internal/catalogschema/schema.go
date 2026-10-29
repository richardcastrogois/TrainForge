// Package catalogschema owns only the disposable public read projection for M1.
package catalogschema

import (
	"context"
	"embed"
	"errors"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/pressly/goose/v3/lock"
	"trainforge.local/api/internal/catalogtarget"
)

//go:embed *.sql
var files embed.FS

func Apply(ctx context.Context, dsn string) (int, error) {
	c, err := catalogtarget.Config(dsn, catalogtarget.MigratorRole)
	if err != nil {
		return 0, err
	}
	db := stdlib.OpenDB(*c.ConnConfig)
	defer db.Close()
	db.SetMaxOpenConns(1)
	var valid bool
	if db.QueryRowContext(ctx, catalogtarget.RoleSQL, catalogtarget.MigratorRole, c.ConnConfig.Database).Scan(&valid) != nil || !valid {
		return 0, catalogtarget.ErrTarget
	}
	locker, err := lock.NewPostgresSessionLocker()
	if err != nil {
		return 0, errors.New("catalog migration lock unavailable")
	}
	provider, err := goose.NewProvider(goose.DialectPostgres, db, files, goose.WithTableName("trainforge_catalog_schema_version"), goose.WithSessionLocker(locker))
	if err != nil {
		return 0, errors.New("catalog migration provider unavailable")
	}
	results, err := provider.Up(ctx)
	if err != nil {
		return 0, errors.New("catalog migration failed")
	}
	return len(results), nil
}
