"""Food import integration in an owned disposable DB; delivered rows are untouched."""
import json
import secrets
import subprocess
from db_local import sql, NAME, load_env, LOCAL, verify_owned, start
from dev_api import environment, SERVICE, ROOT
from verificar_auth_local import database_url


def snapshot():
    return sql("""SELECT json_build_object(
     'catalogCount',(SELECT count(*) FROM trainforge_v1.content_versions),
     'catalogHash',(SELECT md5(coalesce(string_agg(asset_id||version_sha,'' ORDER BY asset_id,version_sha),'')) FROM trainforge_v1.content_versions),
     'users',(SELECT count(*) FROM trainforge_v1.users),
     'foods',(SELECT count(*) FROM trainforge_v1.food_versions),
     'foodHash',(SELECT md5(coalesce(string_agg(food_id||version_sha||nutrients::text||provenance::text,'' ORDER BY food_id,version_sha),'')) FROM trainforge_v1.food_versions)
    )::text;""", NAME)


def fixtures():
    verify_owned()
    start()
    before = snapshot()
    env, go = environment()
    name = "trainforge_v1_food_test_" + secrets.token_hex(6)
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
        raise RuntimeError("Temporary food database exists; refusing overwrite")
    writer = database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name)
    runtime = database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name)
    created = False
    try:
        sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
        created = True
        env["TF_MIGRATION_DATABASE_URL"] = writer
        subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name +
            " TO trainforge_runtime; GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_runtime; "
            "GRANT SELECT ON trainforge_v1.food_versions,trainforge_v1.food_import_batches,"
            "trainforge_v1.food_batch_versions,trainforge_v1.food_withdrawals TO trainforge_runtime;", name)
        env["TF_FOOD_TEST_DATABASE_URL"] = writer
        env["TF_FOOD_TEST_RUNTIME_URL"] = runtime
        subprocess.run([str(go), "test", "./internal/nutrition", "-count=1", "-v"],
                       cwd=SERVICE, env=env, check=True, timeout=120)
    finally:
        if created:
            sql("DROP DATABASE " + name + ";")
    if snapshot() != before:
        raise RuntimeError("Delivered data changed during isolated food fixtures")
    return {"scope": "isolated-food-import-postgresql-fixtures", "temporaryDatabaseRemoved": True,
            "deliveredDataUnchanged": True, "idempotencyVerified": True,
            "partialFailureRolledBack": True, "immutableVersionTamperRejected": True,
            "runtimeEditorialWritesDenied": True,
            "publicReadVisibilityVerified": True, "privateAndUnreviewedRowsExcluded": True,
            "withdrawalOverridesETagVerified": True, "latestCannotReviveOlderVersion": True,
            "literalSearchAndFilterBoundCursorVerified": True, "realGoogleLoginValidated": False}


if __name__ == "__main__":
    result = fixtures()
    (ROOT / "docs/execucao/v1/food-import-fixtures-verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
