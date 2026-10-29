// Command catalog-release publishes exact append-only editorial packages using operator credentials.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"path/filepath"
	"time"
	"trainforge.local/api/internal/catalogauthority"
	"trainforge.local/api/internal/catalogtarget"
)

func main() {
	if run() != nil {
		fmt.Fprintln(os.Stderr, "catalog_release_failed")
		os.Exit(1)
	}
}
func run() error {
	action := flag.String("action", "head", "head, export or publish")
	packagePath := flag.String("package", "", "explicit local package path; never printed")
	confirmation := flag.String("confirm-sha256", "", "exact canonical snapshot digest")
	expectedRevision := flag.Int64("expected-revision", 0, "last committed revision, zero only for initial import")
	expectedDigest := flag.String("expected-digest", "", "last committed digest")
	flag.Parse()
	if flag.NArg() != 0 {
		return errors.New("unexpected args")
	}
	role := catalogtarget.ReaderRole
	if *action == "publish" {
		role = catalogtarget.MigratorRole
	}
	mode := os.Getenv("TF_CATALOG_MODE")
	target := catalogtarget.Config
	if mode == "local" {
		target = catalogtarget.LocalConfig
	} else if mode != "" && mode != "fixture" {
		return errors.New("invalid mode")
	}
	key := "TF_CATALOG_DATABASE_URL"
	if role == catalogtarget.MigratorRole {
		key = "TF_CATALOG_MIGRATION_DATABASE_URL"
	}
	config, e := target(os.Getenv(key), role)
	if e != nil {
		return e
	}
	config.MaxConns = 1
	config.ConnConfig.ConnectTimeout = time.Second
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	pool, e := pgxpool.NewWithConfig(ctx, config)
	if e != nil {
		return e
	}
	defer pool.Close()
	if catalogtarget.ActualRole(ctx, pool, role) != nil {
		return catalogauthority.ErrUnavailable
	}
	var result any
	switch *action {
	case "head":
		result, e = catalogauthority.Current(ctx, pool)
	case "export":
		if *packagePath == "" {
			return errors.New("explicit output required")
		}
		var snapshot catalogauthority.Snapshot
		snapshot, _, e = catalogauthority.Read(ctx, pool)
		if e != nil {
			return e
		}
		raw, e := catalogauthority.Canonical(snapshot)
		if e != nil {
			return e
		}
		path, e := safePath(*packagePath)
		if e != nil {
			return e
		}
		file, e := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
		if e != nil {
			return e
		}
		_, e = file.Write(raw)
		ce := file.Close()
		if e != nil || ce != nil {
			return errors.New("package write failed")
		}
		result = map[string]any{"digest": catalogauthority.Hash(raw), "versions": len(snapshot.Versions), "withdrawals": len(snapshot.Withdrawals)}
	case "publish":
		path, e := safePath(*packagePath)
		if e != nil {
			return e
		}
		info, e := os.Stat(path)
		if e != nil || !info.Mode().IsRegular() || info.Size() > 16<<20 {
			return catalogauthority.ErrPackage
		}
		raw, e := os.ReadFile(path)
		if e != nil {
			return e
		}
		snapshot, e := catalogauthority.Decode(raw)
		if e != nil {
			return e
		}
		canonical, e := catalogauthority.Canonical(snapshot)
		if e != nil || *confirmation != catalogauthority.Hash(canonical) {
			return catalogauthority.ErrPackage
		}
		result, e = catalogauthority.Publish(ctx, pool, catalogauthority.Command{ExpectedRevision: *expectedRevision, ExpectedDigest: *expectedDigest, PackageDigest: *confirmation, Snapshot: snapshot})
	default:
		return errors.New("invalid action")
	}
	if e != nil {
		return catalogauthority.ErrUnavailable
	}
	return json.NewEncoder(os.Stdout).Encode(result)
}
func safePath(raw string) (string, error) {
	root := os.Getenv("TF_CATALOG_PACKAGE_ROOT")
	if root == "" || raw == "" {
		return "", catalogauthority.ErrPackage
	}
	root, e := filepath.EvalSymlinks(root)
	if e != nil {
		return "", e
	}
	root, e = filepath.Abs(root)
	if e != nil {
		return "", e
	}
	path, e := filepath.Abs(raw)
	if e != nil {
		return "", e
	}
	parent, e := filepath.EvalSymlinks(filepath.Dir(path))
	if e != nil || parent != root {
		return "", catalogauthority.ErrPackage
	}
	if actual, e := filepath.EvalSymlinks(path); e == nil && actual != path {
		return "", catalogauthority.ErrPackage
	}
	return path, nil
}
