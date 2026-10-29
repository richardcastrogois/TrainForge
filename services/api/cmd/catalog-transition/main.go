// Command catalog-transition bootstraps, verifies or advances the core's read-only editorial mirror.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"os"
	"regexp"
	"time"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/catalogtarget"
)

func main() {
	if run() != nil {
		fmt.Fprintln(os.Stderr, "catalog_transition_failed")
		os.Exit(1)
	}
}
func run() error {
	action := flag.String("action", "verify", "bootstrap, mirror or verify")
	flag.Parse()
	if flag.NArg() != 0 {
		return errors.New("invalid args")
	}
	local := os.Getenv("TF_CATALOG_MODE") == "local"
	if mode := os.Getenv("TF_CATALOG_MODE"); mode != "local" && mode != "fixture" {
		return errors.New("explicit mode required")
	}
	target := catalogtarget.Config
	if local {
		target = catalogtarget.LocalConfig
	}
	cc, e := target(os.Getenv("TF_CATALOG_MIGRATION_DATABASE_URL"), catalogtarget.MigratorRole)
	if e != nil {
		return e
	}
	cc.MaxConns = 1
	cc.ConnConfig.ConnectTimeout = time.Second
	coreConfig, e := coreTarget(os.Getenv("TF_CATALOG_CORE_DATABASE_URL"), local)
	if e != nil {
		return e
	}
	coreConfig.MaxConns = 1
	coreConfig.ConnConfig.ConnectTimeout = time.Second
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	authority, e := pgxpool.NewWithConfig(ctx, cc)
	if e != nil {
		return e
	}
	defer authority.Close()
	if catalogtarget.ActualRole(ctx, authority, catalogtarget.MigratorRole) != nil {
		return catalogauthority.ErrUnavailable
	}
	core, e := pgxpool.NewWithConfig(ctx, coreConfig)
	if e != nil {
		return e
	}
	defer core.Close()
	var actual bool
	if core.QueryRow(ctx, `SELECT current_user='trainforge_migrator' AND NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls))`).Scan(&actual) != nil || !actual {
		return catalogauthority.ErrUnavailable
	}
	var head catalogauthority.Head
	switch *action {
	case "bootstrap":
		tx, e := core.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
		if e != nil {
			return e
		}
		defer tx.Rollback(ctx)
		snapshot, digest, e := catalogauthority.Read(ctx, tx)
		if e != nil {
			return e
		}
		head, e = catalogauthority.Current(ctx, authority)
		if e == nil {
			if head.Digest != digest {
				return catalogauthority.ErrConflict
			}
		} else {
			head, e = catalogauthority.Publish(ctx, authority, catalogauthority.Command{PackageDigest: digest, Snapshot: snapshot})
			if e != nil {
				return e
			}
		}
	case "mirror", "verify":
		origin, e := authority.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
		if e != nil {
			return e
		}
		defer origin.Rollback(ctx)
		head, e = catalogauthority.Current(ctx, origin)
		if e != nil {
			return e
		}
		snapshot, digest, e := catalogauthority.Read(ctx, origin)
		if e != nil || digest != head.Digest {
			return catalogauthority.ErrConflict
		}
		tx, e := core.Begin(ctx)
		if e != nil {
			return e
		}
		defer tx.Rollback(ctx)
		if *action == "mirror" {
			if e = catalogauthority.ApplyProjection(ctx, tx, snapshot, digest); e != nil {
				return e
			}
		}
		_, mirror, e := catalogauthority.Read(ctx, tx)
		if e != nil || mirror != digest {
			return catalogauthority.ErrConflict
		}
		if tx.Commit(ctx) != nil {
			return catalogauthority.ErrUnavailable
		}
	default:
		return errors.New("invalid action")
	}
	return json.NewEncoder(os.Stdout).Encode(map[string]any{"action": *action, "head": head, "privateRowsWritten": false, "practiceApproved": false})
}
func coreTarget(raw string, local bool) (*pgxpool.Config, error) {
	u, e := url.Parse(raw)
	if e != nil || u.Scheme != "postgresql" || u.User == nil || u.User.Username() != "trainforge_migrator" || u.Hostname() != "127.0.0.1" || u.Port() != "15432" || u.Fragment != "" {
		return nil, catalogtarget.ErrTarget
	}
	name := u.Path
	valid := name == "/trainforge_v1_dev"
	if !local {
		valid = regexp.MustCompile(`^/trainforge_v1_config_test_[a-f0-9]{12}$`).MatchString(name)
	}
	q, e := url.ParseQuery(u.RawQuery)
	if !valid || e != nil || len(q) != 1 || len(q["sslmode"]) != 1 || q.Get("sslmode") != "disable" {
		return nil, catalogtarget.ErrTarget
	}
	password, ok := u.User.Password()
	if !ok || password == "" {
		return nil, catalogtarget.ErrTarget
	}
	for _, key := range []string{"PGSERVICE", "PGSERVICEFILE", "PGPASSFILE"} {
		if os.Getenv(key) != "" {
			return nil, catalogtarget.ErrTarget
		}
	}
	c, e := pgxpool.ParseConfig(raw)
	if e != nil || c.ConnConfig.TLSConfig != nil || len(c.ConnConfig.Fallbacks) != 0 || len(c.ConnConfig.RuntimeParams) != 0 {
		return nil, catalogtarget.ErrTarget
	}
	return c, nil
}
