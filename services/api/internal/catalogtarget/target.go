// Package catalogtarget constrains the M1 proof to its own disposable database.
package catalogtarget

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"net/url"
	"os"
	"regexp"
)

const ReaderRole = "trainforge_catalog_reader"
const MigratorRole = "trainforge_catalog_migrator"

var ErrTarget = errors.New("explicit isolated catalog M1 target required")
var databaseName = regexp.MustCompile(`^trainforge_catalog_test_[a-f0-9]{12}$`)

// RoleSQL checks the actual database identity, not only the supplied DSN.
const RoleSQL = `SELECT current_user=$1 AND current_database()=$2 AND NOT EXISTS(
 SELECT 1 FROM pg_roles WHERE rolname=current_user AND
 (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls OR NOT rolcanlogin OR rolconnlimit<1 OR rolconnlimit>16))
 AND NOT EXISTS(SELECT 1 FROM pg_auth_members WHERE member=(SELECT oid FROM pg_roles WHERE rolname=current_user))`

func Config(dsn, role string) (*pgxpool.Config, error)      { return config(dsn, role, false) }
func LocalConfig(dsn, role string) (*pgxpool.Config, error) { return config(dsn, role, true) }
func config(dsn, role string, local bool) (*pgxpool.Config, error) {
	allowedDatabase := func(name string) bool {
		if local {
			return name == "trainforge_catalog_dev"
		}
		return databaseName.MatchString(name)
	}
	if dsn == "" || (role != ReaderRole && role != MigratorRole) {
		return nil, ErrTarget
	}
	u, e := url.Parse(dsn)
	if e != nil || u.Scheme != "postgresql" || u.User == nil || u.User.Username() != role || u.Hostname() != "127.0.0.1" || u.Port() != "15432" || (len(u.Path) < 2 || !allowedDatabase(u.Path[1:])) || u.Fragment != "" {
		return nil, ErrTarget
	}
	password, present := u.User.Password()
	if !present || password == "" {
		return nil, ErrTarget
	}
	q, e := url.ParseQuery(u.RawQuery)
	if e != nil || len(q) != 1 || len(q["sslmode"]) != 1 || q.Get("sslmode") != "disable" {
		return nil, ErrTarget
	}
	for _, name := range []string{"PGSERVICE", "PGSERVICEFILE", "PGPASSFILE"} {
		if os.Getenv(name) != "" {
			return nil, ErrTarget
		}
	}
	c, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, ErrTarget
	}
	cc := c.ConnConfig
	if cc.Host != "127.0.0.1" || cc.Port != 15432 || cc.User != role || !allowedDatabase(cc.Database) || len(cc.RuntimeParams) != 0 || len(cc.Fallbacks) != 0 || cc.TLSConfig != nil {
		return nil, ErrTarget
	}
	return c, nil
}

func ActualRole(ctx context.Context, pool *pgxpool.Pool, role string) error {
	if pool == nil {
		return ErrTarget
	}
	var ok bool
	if pool.QueryRow(ctx, RoleSQL, role, pool.Config().ConnConfig.Database).Scan(&ok) != nil || !ok {
		return ErrTarget
	}
	return nil
}
