"""Verify activity SQL only in a new disposable database on the already running owned cluster."""
from __future__ import annotations

from datetime import datetime, timezone
import json
import re
import secrets
import subprocess
import sys
from urllib.parse import parse_qsl, urlsplit

from db_local import DATA, LOCAL, NAME, grant_runtime, load_env, run, sql, verify_owned
from dev_api import ROOT, SERVICE, environment
from sql_ci import failure_locations, test_events
from verificar_auth_local import database_url


EXPECTED_TESTS = (
    "TestActivityPostgresLifecycle",
    "TestActivityPostgresAuthorizationWithdrawalAndErasure",
    "TestActivityPostgresHTTPContractAndBoundaries",
)
RECEIPT = ROOT / "docs/execucao/v1/activity-session-sql-verification.json"
_DISPOSABLE = re.compile(r"trainforge_v1_activity_test_[a-f0-9]{12}")
_IDENTIFIER = re.compile(r"[a-z][a-z0-9_]{0,62}")


def disposable_name(value):
    if not isinstance(value, str) or not _DISPOSABLE.fullmatch(value):
        raise RuntimeError("Unsafe disposable activity database name")
    return value


def target(dsn, name, role):
    """Validate effective destination inputs before any database is created or migrated."""
    disposable_name(name)
    try:
        parts = urlsplit(dsn)
        query = parse_qsl(parts.query, keep_blank_values=True, strict_parsing=True)
        valid = (
            parts.scheme in ("postgres", "postgresql")
            and parts.hostname == "127.0.0.1"
            and parts.port == 15432
            and parts.path == "/" + name
            and parts.username == "trainforge_" + role
            and role in ("migrator", "runtime")
            and bool(parts.password)
            and not parts.fragment
            and query == [("sslmode", "disable")]
        )
    except (ValueError, TypeError):
        valid = False
    if not valid:
        raise RuntimeError("Unsafe disposable activity connection target")
    return dsn


def snapshot():
    """Compare every user table, including schema history, without returning its rows."""
    raw = sql("""SELECT coalesce(json_agg(json_build_array(schemaname,tablename)
      ORDER BY schemaname,tablename),'[]'::json)::text FROM pg_tables
      WHERE schemaname NOT IN ('pg_catalog','information_schema')
      AND schemaname NOT LIKE 'pg_%';""", NAME)
    tables = json.loads(raw)
    result = {}
    for schema, table in tables:
        if not _IDENTIFIER.fullmatch(schema) or not _IDENTIFIER.fullmatch(table):
            raise RuntimeError("Unexpected table identifier; snapshot refused")
        # SQL identifiers come exclusively from this schema inventory and the strict allowlist.
        relation = '"' + schema + '"."' + table + '"'
        result[schema + "." + table] = sql(
            "SELECT coalesce(md5(string_agg(row_to_json(v)::text,'' "
            "ORDER BY row_to_json(v)::text)),'empty') FROM " + relation + " v;", NAME
        )
    if not result:
        raise RuntimeError("Delivered database has no inventoried tables")
    return result


def checked_process(command, env, timeout):
    result = subprocess.run(
        command, cwd=SERVICE, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8", errors="replace", timeout=timeout,
    )
    if result.returncode:
        locations = failure_locations(result.stdout)
        raise RuntimeError("Disposable activity verification failed; raw output withheld; "
                           + json.dumps({"failureLocations": locations}))
    return result.stdout


def main():
    verify_owned()
    # Deliberately no start/init/activate/restore: the operator must start the owned cluster.
    run("pg_ctl", ["-D", DATA, "status"], timeout=5)
    before = snapshot()
    name = disposable_name("trainforge_v1_activity_test_" + secrets.token_hex(6))
    writer = target(database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name), name, "migrator")
    runtime = target(database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name), name, "runtime")
    env, go = environment(include_api_env=False)
    env["TF_MIGRATION_DATABASE_URL"] = writer
    env["TF_ACTIVITY_TEST_DATABASE_URL"] = writer
    env["TF_ACTIVITY_TEST_RUNTIME_URL"] = runtime
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
        raise RuntimeError("Disposable target exists; no overwrite")
    created = False
    try:
        sql("CREATE DATABASE " + disposable_name(name) + " OWNER trainforge_migrator;")
        created = True
        checked_process([str(go), "run", "./cmd/migrate"], env, 120)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE "
            + name + " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", name)
        grant_runtime(name)
        pattern = "^(" + "|".join(EXPECTED_TESTS) + ")$"
        raw = checked_process([str(go), "test", "./internal/activity", "-run", pattern,
                               "-count=1", "-json", "-timeout=90s"], env, 120)
        events = test_events(raw, EXPECTED_TESTS)
    finally:
        try:
            if created:
                # Only this validated, freshly created name; no FORCE or other connection termination.
                sql("DROP DATABASE " + disposable_name(name) + ";")
        finally:
            if snapshot() != before:
                raise RuntimeError("Delivered database changed during isolated activity tests")
    executed_at = datetime.now(timezone.utc)
    receipt = {
        "date": executed_at.date().isoformat(),
        "dateUtc": executed_at.date().isoformat(),
        "executedAtUtc": executed_at.isoformat(),
        "story": "V1-017", "status": "partial", "passed": True,
        "scope": "disposable-activity-sql-http-not-human-practice-acceptance",
        "schemaTested": max(int(p.name.split("_", 1)[0]) for p in (SERVICE / "migrations").glob("*.sql")),
        "tests": events,
        "deliveredSchemaMigrated": False, "allDeliveredTablesUnchanged": True,
        "disposableDatabaseRemoved": True, "existingClusterLeftRunning": True,
        "clusterStartedOrStopped": False, "realGoogleOrHumanPracticeValidated": False,
        "fixtures": "synthetic editor-reviewed practice flags only in discarded test database",
        "credentialsPrinted": False,
        "limits": ["No content or activity was published in the delivered database.",
                   "No APK, real practice, offline queue, accessibility or release acceptance."],
    }
    RECEIPT.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt))


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.SubprocessError) as error:
        print("Activity SQL verification not completed; "
              + (str(error) if isinstance(error, RuntimeError) else "bounded local operation failure"), file=sys.stderr)
        raise SystemExit(1)
