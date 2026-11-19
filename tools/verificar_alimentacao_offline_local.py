"""Test offline nutrition in a new disposable database; never migrate delivered data."""
from datetime import datetime, timezone
import json
import secrets
import subprocess
from urllib.parse import parse_qsl, urlsplit

from db_local import DATA, LOCAL, NAME, grant_runtime, load_env, run, sql, start, verify_owned
from dev_api import ROOT, SERVICE, environment
from sql_ci import disposable_name, failure_locations, test_events
from verificar_atividade_local import snapshot
from verificar_auth_local import database_url

EXPECTED = {
    "./internal/nutrition": (
        "TestNutritionSyncPostgresDurabilityBaselineMappingsAndTombstones",
        "TestFoodContributionPostgresConsentOwnershipMediaWithdrawalAndErasure",
        "TestFoodCatalogPostgresStagingActivationAndCanonicalSnapshot",
        "TestFoodCatalogPostgresPreservesUnstorableSourceTextLosslessly",
        "TestFoodCatalogPostgresLegacyNameEdgeWhitespaceOnly",
        "TestMealPostgresAtomicOwnershipReplayAndPrivacy",
    ),
    "./internal/privacy": ("TestPrivacyPostgresOwnerExportConfirmedDeletionAndRollback",),
    "./internal/platform/postgres": ("TestPostgresRuntimeReadiness",),
}


def target(dsn, name, role):
    disposable_name(name)
    p = urlsplit(dsn)
    if (p.scheme not in {"postgres", "postgresql"} or p.hostname != "127.0.0.1"
            or p.port != 15432 or p.path != "/" + name
            or p.username != "trainforge_" + role or not p.password or p.fragment
            or parse_qsl(p.query, keep_blank_values=True) != [("sslmode", "disable")]):
        raise RuntimeError("Unsafe disposable nutrition target")
    return dsn


def execute(command, env, timeout=180):
    result = subprocess.run(command, cwd=SERVICE, env=env, capture_output=True,
                            text=True, encoding="utf-8", errors="strict", timeout=timeout)
    if result.returncode:
        raise RuntimeError("Offline nutrition SQL verification failed: " + json.dumps(failure_locations(result.stdout)))
    return result.stdout


def main():
    verify_owned()
    try:
        run("pg_ctl", ["-D", DATA, "status"], timeout=5)
        was_running = True
    except RuntimeError:
        was_running = False
    start()
    created = False
    before = snapshot()
    name = disposable_name("trainforge_v1_privacy_test_" + secrets.token_hex(6))
    env, go = environment(include_api_env=False)
    writer = target(database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name), name, "migrator")
    runtime = target(database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name), name, "runtime")
    env.update({"TF_MIGRATION_DATABASE_URL": writer, "TF_MEALS_TEST_DATABASE_URL": writer,
                "TF_MEALS_TEST_RUNTIME_URL": runtime, "TF_PRIVACY_TEST_DATABASE_URL": writer,
                "TF_PRIVACY_TEST_RUNTIME_URL": runtime})
    results = []
    try:
        if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
            raise RuntimeError("Disposable target already exists")
        sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
        created = True
        for _ in range(2):
            execute([str(go), "run", "./cmd/migrate"], env)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name
            + " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", name)
        grant_runtime(name)
        schema = int(sql("SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;", name))
        for package, tests in EXPECTED.items():
            raw = execute([str(go), "test", package, "-run", "^(" + "|".join(tests) + ")$", "-count=1", "-json"], env)
            results.append({"package": package, "tests": test_events(raw, tests)})
    finally:
        try:
            if created:
                sql("DROP DATABASE " + disposable_name(name) + ";")
            if snapshot() != before:
                raise RuntimeError("Delivered database changed during disposable verification")
        finally:
            if not was_running:
                verify_owned()
                run("pg_ctl", ["-D", DATA, "-m", "fast", "-w", "-t", "20", "stop"], timeout=25)
    receipt = {"contract": "trainforge.offline-nutrition-sql-verification/1",
               "verifiedAt": datetime.now(timezone.utc).isoformat(), "schemaTested": schema,
               "deliveredDatabase": NAME, "deliveredSchemaMigrated": False,
               "deliveredRecordsUnchanged": True, "disposableDatabaseRemoved": True,
               "clusterRunningStatePreserved": True, "results": results,
               "humanOrNativeAcceptance": False}
    (ROOT / "docs/execucao/v1/offline-nutrition-sql-verification.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt))


if __name__ == "__main__":
    main()
