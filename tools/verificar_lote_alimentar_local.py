"""Verify the reviewed food import and a new food-bearing backup in the owned local cluster."""
from __future__ import annotations
import hashlib
import json
import re
import secrets
import subprocess
from db_local import NAME, PORT, ROOT, LOCAL, verify_owned, start, sql, run, owner_env, load_env, grant_runtime
from dev_api import environment, SERVICE
from alimentos_lote import digest


def table_snapshot(database):
    tables = sql("SELECT tablename FROM pg_tables WHERE schemaname='trainforge_v1' ORDER BY tablename;", database).splitlines()
    result = {}
    for table in tables:
        if not re.fullmatch("[a-z_]+", table):
            raise RuntimeError("Unexpected table name")
        value = sql("SELECT json_build_object('count',count(*),'rowsSha256',"
                    "encode(sha256(convert_to(coalesce(string_agg(encode(sha256(convert_to(to_jsonb(v)::text,'UTF8')),'hex'),'' "
                    "ORDER BY to_jsonb(v)::text),''),'UTF8')),'hex'))::text FROM trainforge_v1." + table + " v;", database)
        result[table] = json.loads(value)
    return result


def go_import(env, go, dry=False):
    process = subprocess.run([str(go), "run", "./cmd/import-food", *(["--dry-run"] if dry else [])],
                             cwd=SERVICE, env=env, capture_output=True, text=True, timeout=180)
    if process.returncode:
        raise RuntimeError("Reviewed food Go import failed; diagnostics intentionally not echoed with connection values")
    return json.loads(process.stdout)


def dump_to(path):
    if path.exists():
        raise RuntimeError("Backup target exists; refusing overwrite")
    run("pg_dump", ["-h", "127.0.0.1", "-p", str(PORT), "-U", "trainforge_owner", "-d", NAME,
                    "-Fc", "-f", path], env=owner_env(), timeout=90)
    return digest(path)


def main():
    verify_owned()
    start()
    manifest = json.loads((ROOT / "content/manifests/food-approved.json").read_text(encoding="utf-8"))
    before = table_snapshot(NAME)
    token = secrets.token_hex(6)
    backup_dir = LOCAL / "backups"
    backup_dir.mkdir(exist_ok=True)
    before_dump = backup_dir / ("trainforge-v1-before-food-" + token + ".dump")
    before_sha = dump_to(before_dump)
    print("Checkpoint anterior preservado; aplicando migration aditiva alimentar.", flush=True)
    env, go = environment()
    env.update(load_env(LOCAL / "migrate.env"))
    subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
    grant_runtime()
    dry = go_import(env, go, dry=True)
    first = go_import(env, go)
    print("Lote real importado; conferindo reimportação sem duplicar.", flush=True)
    second = go_import(env, go)
    if dry["totalFoods"] != manifest["output"]["rows"] or first["totalFoods"] != dry["totalFoods"] or second["inserted"] != 0 or second["unchanged"] != dry["totalFoods"]:
        raise RuntimeError("Real food import coverage/idempotency mismatch")
    after = table_snapshot(NAME)
    for table in before:
        if table not in {"food_versions", "sources"} and before[table] != after[table]:
            raise RuntimeError("Unrelated delivered data changed")
    if after["food_versions"]["count"] != dry["totalFoods"] or after["food_batch_versions"]["count"] != dry["totalFoods"]:
        raise RuntimeError("Unexpected actual food/batch count")
    checks = json.loads(sql("""SELECT json_build_object(
     'sourceFoodCounts',(SELECT json_object_agg(source_id,n) FROM (SELECT source_id,count(*) n FROM trainforge_v1.food_versions GROUP BY source_id) s),
     'unknownBasis',(SELECT count(*) FROM trainforge_v1.food_versions WHERE basis_unit IS NULL),
     'millilitreBasis',(SELECT count(*) FROM trainforge_v1.food_versions WHERE basis_unit='ml'),
     'conflictingCodeImported',(SELECT count(*) FROM trainforge_v1.food_versions WHERE source_id='AL-COFID-2021' AND source_food_id='13-669'),
     'privateOwnersCreated',(SELECT count(*) FROM trainforge_v1.food_versions WHERE owner_id IS NOT NULL),
     'runtimeCanWriteFoods',has_table_privilege('trainforge_runtime','trainforge_v1.food_versions','UPDATE'),
     'runtimeCanReadFoods',has_table_privilege('trainforge_runtime','trainforge_v1.food_versions','SELECT'),
     'nutrientStates',(SELECT json_object_agg(state,n) FROM (SELECT item->>'state' state,count(*) n FROM trainforge_v1.food_versions,jsonb_array_elements(nutrients) item GROUP BY item->>'state') s)
    )::text;""", NAME))
    if checks["sourceFoodCounts"] != {"AL-CIQUAL-2025": 3484, "AL-COFID-2021": 2885} or checks["unknownBasis"] != 3 or checks["millilitreBasis"] != 31 or checks["conflictingCodeImported"] != 0 or checks["privateOwnersCreated"] != 0 or checks["runtimeCanWriteFoods"] or not checks["runtimeCanReadFoods"]:
        raise RuntimeError("Source coverage/basis/conflict/runtime policy mismatch")
    post_dump = backup_dir / ("trainforge-v1-post-food-" + token + ".dump")
    post_sha = dump_to(post_dump)
    restore = "trainforge_v1_food_restore_" + token
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + restore + "';") != "0":
        raise RuntimeError("Restore target exists; refusing overwrite")
    created = False
    try:
        sql("CREATE DATABASE " + restore + " OWNER trainforge_migrator;")
        created = True
        print("Restaurando backup novo em base separada para conferir todas as tabelas.", flush=True)
        run("pg_restore", ["-h", "127.0.0.1", "-p", str(PORT), "-U", "trainforge_owner", "-d", restore,
                           "--exit-on-error", post_dump], env=owner_env(), timeout=120)
        if table_snapshot(restore) != after:
            raise RuntimeError("Food-bearing restore differs from original database")
    finally:
        if created:
            sql("DROP DATABASE " + restore + ";")
    if table_snapshot(NAME) != after:
        raise RuntimeError("Source database changed during restore")
    receipt = {"date": "2026-10-22", "scope": "real-reviewed-food-import-and-restore",
               "dryRun": dry, "firstImport": first, "reimport": second,
               "sourceChecks": checks, "sameCountsAndAllTableContentAfterRestore": True,
               "tables": after, "restoreTargetRemoved": True, "unrelatedDeliveredDataUnchanged": True,
               "beforeBackup": {"relativePath": before_dump.relative_to(ROOT).as_posix(), "sha256": before_sha, "restoreTested": False},
               "verifiedBackup": {"relativePath": post_dump.relative_to(ROOT).as_posix(), "sha256": post_sha, "restoreTested": True},
               "realGoogleLoginValidated": False, "foodHttpApiImplemented": False, "flutterFoodIntegrated": False}
    (ROOT / "docs/execucao/v1/food-import-verification.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"scope": receipt["scope"], "foods": after["food_versions"]["count"], "reimportInserted": second["inserted"],
                      "restoreAllTablesVerified": True, "fixtureUsersCreatedInDeliveredDb": 0}))


if __name__ == "__main__":
    main()
