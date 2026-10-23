"""V1-020: disposable SQL/HTTP fixtures. Never human consumption or Google-login proof."""
import json
import secrets
import subprocess
from db_local import sql, NAME, load_env, LOCAL, verify_owned, grant_runtime
from dev_api import environment, SERVICE, ROOT
from verificar_auth_local import database_url

def snapshot():
    return sql("""SELECT json_build_array(
      (SELECT count(*) FROM trainforge_v1.users),
      (SELECT count(*) FROM trainforge_v1.food_entries),
      (SELECT count(*) FROM trainforge_v1.food_versions),
      (SELECT md5(string_agg(row_to_json(v)::text,'' ORDER BY food_id,version_sha))
       FROM trainforge_v1.food_versions v WHERE owner_id IS NULL))::text;""", NAME)

def main():
    verify_owned()
    before = snapshot()
    env, go = environment()
    name = "trainforge_v1_nutrition_test_" + secrets.token_hex(6)
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
        raise RuntimeError("Disposable target exists")
    writer = database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name)
    runtime = database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name)
    created = False
    try:
        sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
        created = True
        env["TF_MIGRATION_DATABASE_URL"] = writer
        subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name +
            " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", name)
        grant_runtime(name)
        # Copy one already reviewed real reference into the disposable DB only.
        # No new collection, approval or mutation of the delivered catalog.
        food = json.loads(sql("""SELECT row_to_json(v)::text FROM trainforge_v1.food_versions v
          WHERE owner_id IS NULL AND 'food_quantity_scale'=ANY(allowed_operations)
          ORDER BY food_id LIMIT 1;""", NAME))
        batches = json.loads(sql("SELECT coalesce(json_agg(b),'[]')::text FROM trainforge_v1.food_import_batches b WHERE artifact_sha IN(SELECT artifact_sha FROM trainforge_v1.food_batch_versions WHERE food_id='" + food["food_id"] + "' AND version_sha='" + food["version_sha"] + "');", NAME))
        links = json.loads(sql("SELECT coalesce(json_agg(v),'[]')::text FROM trainforge_v1.food_batch_versions v WHERE food_id='" + food["food_id"] + "' AND version_sha='" + food["version_sha"] + "';", NAME))
        source = json.loads(sql("SELECT row_to_json(s)::text FROM trainforge_v1.sources s WHERE id='" + food["source_id"] + "';", NAME))
        for table, rows in [("sources", [source]), ("food_versions", [food]), ("food_import_batches", batches), ("food_batch_versions", links)]:
            for row in rows:
                literal = json.dumps(row, ensure_ascii=False).replace("'", "''")
                statement = "INSERT INTO trainforge_v1." + table + " SELECT * FROM jsonb_populate_record(NULL::trainforge_v1." + table + ", '" + literal + "'::jsonb);"
                diagnostic = sql("DO $copy$ DECLARE c text; BEGIN " + statement + " EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS c=CONSTRAINT_NAME; RAISE NOTICE 'copy failure: % %',SQLSTATE,c; END;$copy$;", name)
                if diagnostic:
                    raise RuntimeError("Disposable reference copy: " + table + " " + diagnostic)
        env["TF_NUTRITION_RESEARCHED_FOOD_ID"] = food["food_id"]
        env["TF_NUTRITION_RESEARCHED_FOOD_SHA"] = food["version_sha"]
        env["TF_NUTRITION_TEST_DATABASE_URL"] = writer
        env["TF_NUTRITION_TEST_RUNTIME_URL"] = runtime
        subprocess.run([str(go), "test", "./internal/nutrition", "-count=1", "-v"],
                       cwd=SERVICE, env=env, check=True, timeout=90)
    finally:
        if created:
            sql("DROP DATABASE " + name + ";")
    if snapshot() != before:
        raise RuntimeError("Delivered data changed during fixtures")
    result = {"scope": "disposable-nutrition-sql-http-not-human-consumption",
              "passed": True, "temporaryDatabaseRemoved": True,
              "deliveredDataUnchanged": True, "realGoogleLoginValidated": False,
              "humanConsumptionValidated": False, "reviewedReferenceCopiedOnlyToDisposableDatabase": True,
              "ownershipIdempotencyRevisionsPrivacyVerified": True}
    (ROOT / "docs/execucao/v1/nutrition-local-verification.json").write_text(
        json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))

if __name__ == "__main__":
    main()
