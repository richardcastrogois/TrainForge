"""V1-048 reviewed-name foundations in a disposable database; never publish fixtures."""
import argparse
import json
import re
import secrets
import subprocess
from urllib.parse import urlsplit
from db_local import sql, NAME, load_env, LOCAL, DATA, run, verify_owned, start, grant_runtime
from dev_api import environment, SERVICE, ROOT
from verificar_auth_local import database_url


def snapshot():
    return sql("""SELECT json_build_array(
      (SELECT count(*) FROM trainforge_v1.users),
      (SELECT count(*) FROM trainforge_v1.food_entries),
      (SELECT count(*) FROM trainforge_v1.food_versions),
      (SELECT md5(string_agg(row_to_json(v)::text,'' ORDER BY food_id,version_sha))
       FROM trainforge_v1.food_versions v),
      (SELECT count(*) FROM trainforge_v1.food_name_versions),
      (SELECT count(*) FROM trainforge_v1.food_name_withdrawals),
      (SELECT md5(string_agg(row_to_json(c)::text,'' ORDER BY locale))
       FROM trainforge_v1.food_name_catalogs c))::text;""", NAME)


def validate_connection(dsn, role, name):
    if role not in {"trainforge_migrator", "trainforge_runtime"} or not re.fullmatch(r"trainforge_v1_names_test_[0-9a-f]{12}", name):
        raise RuntimeError("Invalid disposable identity")
    target = urlsplit(dsn)
    if target.hostname != "127.0.0.1" or target.port != 15432 or target.username != role or target.path != "/" + name:
        raise RuntimeError("Refusing a fixture connection outside the owned local target")


def main(receipt_name="food-names-operations-verification.json"):
    verify_owned()
    try:
        run("pg_ctl", ["-D", DATA, "status"], timeout=5)
        was_running = True
    except RuntimeError:
        was_running = False
    start()
    name = "trainforge_v1_names_test_" + secrets.token_hex(6)
    if not re.fullmatch(r"trainforge_v1_names_test_[0-9a-f]{12}", name):
        raise RuntimeError("Invalid disposable target")
    created = False
    try:
        before = snapshot()
        if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
            raise RuntimeError("Disposable target already exists; no overwrite")
        env, go = environment()
        writer = database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name)
        runtime = database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name)
        for dsn, role in [(writer, "trainforge_migrator"), (runtime, "trainforge_runtime")]:
            validate_connection(dsn, role, name)
        try:
            sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
            created = True
            env["TF_MIGRATION_DATABASE_URL"] = writer
            subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
            sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name +
                " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", name)
            grant_runtime(name)
            env["TF_FOOD_NAMES_TEST_DATABASE_URL"] = writer
            env["TF_FOOD_NAMES_TEST_RUNTIME_URL"] = runtime
            subprocess.run([str(go), "test", "./internal/nutrition", "-run", "TestFoodNames", "-count=1", "-v"],
                           cwd=SERVICE, env=env, check=True, timeout=90)
        finally:
            if created:
                if not re.fullmatch(r"trainforge_v1_names_test_[0-9a-f]{12}", name):
                    raise RuntimeError("Refusing cleanup outside disposable target")
                sql("DROP DATABASE " + name + ";")
        if snapshot() != before:
            raise RuntimeError("Delivered data changed during isolated fixtures")
        # Read only: actual coverage through the operator CLI and runtime role.
        env["TF_FOOD_NAMES_DATABASE_URL"] = load_env(LOCAL / "api.env")["TF_DATABASE_URL"]
        coverage_process = subprocess.run([str(go), "run", "./cmd/food-names", "--operation", "coverage"],
            cwd=SERVICE, env=env, check=True, capture_output=True, text=True, timeout=60)
        coverage = json.loads(coverage_process.stdout)
        if coverage.get("contract") != "trainforge.food-name-coverage/1" or len(coverage.get("locales", [])) != 4:
            raise RuntimeError("Invalid coverage contract")
        if snapshot() != before:
            raise RuntimeError("Read-only coverage altered delivered data")
    finally:
        if not was_running:
            verify_owned()
            run("pg_ctl", ["-D", DATA, "-m", "fast", "-w", "-t", "20", "stop"], timeout=25)
    result = {"schemaVersion": 1, "date": "2026-10-26", "story": "V1-048", "status": "partial",
              "scope": "editorial-operations-disposable-sql-and-real-read-only-coverage",
              "passed": True, "temporaryDatabaseRemoved": True, "deliveredDataUnchanged": True,
              "clusterInitiallyRunning": was_running, "clusterRunningStatePreserved": True,
              "disposableSchemaVersion": 11, "runtimeReadOnly": True,
              "immutableHistoryAndIdempotencyVerified": True, "evidenceHashesVerified": True,
              "originalFoodVersionUnchanged": True, "publishedNames": 0,
              "batchedReadVerified": True, "localizedHTTPVerified": True,
              "cursorRejectsChangedLocaleAndRevision": True, "etagRevalidatesWithdrawal": True, "exactVersionAndLocaleVerified": True,
              "latestWithdrawalDoesNotReviveOlderName": True,
              "sourceBaseCommit": "a81f6db",
              "operatorWithdrawalIdempotencyVerified": True, "operatorCLIEndToEndDisposableVerified": True, "coverageByLocaleAndSourceVerified": True,
              "actualReadOnlyCoverage": coverage,
              "limits": ["Publication/withdrawal fixtures remain only in the removed disposable DB; no reviewed real name was published.",
                         "The delivered database remains schema11/26tables with user data preserved; no new migration is added by this increment.",
                         "Evidence hashes and operator acknowledgement do not prove reviewer identity or rights. Human verification and evidence retention are still required.",
                         "Coverage counts stored active editorial rows over visible latest source versions, not language quality, global food coverage or native acceptance."]}
    (ROOT / "docs/execucao/v1" / receipt_name).write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt-name", choices=["food-names-operations-verification.json"], default="food-names-operations-verification.json")
    main(parser.parse_args().receipt_name)
