"""V1-013 PostgreSQL fixtures only; never create/delete accounts in the delivered DB."""
import json
import secrets
import subprocess
from db_local import sql, NAME, load_env, LOCAL, verify_owned, start, grant_runtime
from dev_api import environment, SERVICE, ROOT
from verificar_auth_local import database_url

def snapshot():
    return sql("""SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),
      (SELECT count(*) FROM trainforge_v1.food_versions),
      (SELECT md5(string_agg(food_id||version_sha,'' ORDER BY food_id,version_sha)) FROM trainforge_v1.food_versions),
      (SELECT count(*) FROM trainforge_v1.content_versions))::text;""", NAME)


def restore_fixture(env, go, name, writer):
    """Old account snapshot must be sanitized with newer erasures before use."""
    from pathlib import Path
    from tempfile import TemporaryDirectory
    import hashlib
    import re
    from db_local import run, owner_env
    env["TF_PRIVACY_RESTORE_PHASE"] = "prepare"
    subprocess.run([str(go), "test", "./internal/privacy", "-run", "^TestPrivacyRestorePrepareFixture$", "-count=1"],
                   cwd=SERVICE, env=env, check=True, timeout=60)
    target = "trainforge_v1_privacy_restore_" + secrets.token_hex(6)
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + target + "';") != "0":
        raise RuntimeError("Restore fixture target exists")
    created = False
    with TemporaryDirectory(prefix="privacy-restore-", dir=LOCAL) as folder:
        folder = Path(folder).resolve()
        if not folder.is_relative_to(LOCAL.resolve()):
            raise RuntimeError("Fixture scratch boundary refused")
        backup = folder / "before-account-erasure.dump"
        run("pg_dump", ["-h", "127.0.0.1", "-p", "15432", "-U", "trainforge_owner",
                        "-d", name, "-Fc", "-f", backup], env=owner_env(), timeout=60)
        backup_sha = hashlib.sha256(backup.read_bytes()).hexdigest()
        env["TF_PRIVACY_RESTORE_PHASE"] = "erase"
        subprocess.run([str(go), "test", "./internal/privacy", "-run", "^TestPrivacyRestoreEraseFixture$", "-count=1"],
                       cwd=SERVICE, env=env, check=True, timeout=60)
        erased = json.loads(sql("SELECT coalesce(json_agg(user_id::text),'[]')::text FROM trainforge_v1.account_erasures;", name))
        if not erased or not all(re.fullmatch(r"[a-f0-9-]{36}", value) for value in erased):
            raise RuntimeError("Restore erasure identifiers invalid")
        ids = ",".join("'" + value + "'::uuid" for value in erased)
        try:
            sql("CREATE DATABASE " + target + " OWNER trainforge_migrator;")
            created = True
            sql("REVOKE ALL ON DATABASE " + target + " FROM PUBLIC; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", target)
            run("pg_restore", ["-h", "127.0.0.1", "-p", "15432", "-U", "trainforge_owner",
                              "-d", target, "--no-owner", "--role=trainforge_migrator", backup],
                env=owner_env(), timeout=60)
            resurrected = int(sql("SELECT count(*) FROM trainforge_v1.users WHERE id IN(" + ids + ");", target))
            if resurrected != 1:
                raise RuntimeError("Historical account resurrection fixture not present")
            editorial_query = """SELECT json_build_array(
              (SELECT md5(string_agg(food_id||version_sha||nutrients::text,'' ORDER BY food_id,version_sha))
               FROM trainforge_v1.food_versions WHERE owner_id IS NULL),
              (SELECT md5(string_agg(asset_id||version_sha||payload::text,'' ORDER BY asset_id,version_sha))
               FROM trainforge_v1.content_versions))::text;"""
            editorial = sql(editorial_query, target)
            env["TF_PRIVACY_LEDGER_SOURCE_DATABASE_URL"] = writer
            env["TF_PRIVACY_RESTORE_DATABASE_URL"] = database_url(writer, target)
            command = [str(go), "run", "./cmd/privacy-restore"]
            subprocess.run(command, cwd=SERVICE, env=env, check=True, timeout=90)
            if sql("SELECT count(*) FROM trainforge_v1.users WHERE id IN(" + ids + ");", target) != "0":
                raise RuntimeError("Erased account returned after restore")
            if sql(editorial_query, target) != editorial:
                raise RuntimeError("Editorial data altered by erasure gate")
            if sql("SELECT count(*) FROM trainforge_v1.food_versions WHERE food_id='restore-private-b';", target) != "1":
                raise RuntimeError("Other account changed during restore")
            if sql("SELECT to_regclass('trainforge_v1.training_configuration_versions') IS NOT NULL;", target) == "t":
                if sql("SELECT count(*) FROM trainforge_v1.training_configuration_versions WHERE user_id IN(" + ids + ");", target) != "0":
                    raise RuntimeError("Erased configuration returned after restore")
                if sql("SELECT count(*) FROM trainforge_v1.training_configuration_versions c JOIN trainforge_v1.users u ON u.id=c.user_id WHERE u.subject='privacy-restore-b';", target) != "1":
                    raise RuntimeError("Other account configuration changed during restore")
            after_first = sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
                              "(SELECT count(*) FROM trainforge_v1.food_versions),"
                              "(SELECT count(*) FROM trainforge_v1.account_erasures))::text;", target)
            subprocess.run(command, cwd=SERVICE, env=env, check=True, timeout=90)
            after_second = sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
                               "(SELECT count(*) FROM trainforge_v1.food_versions),"
                               "(SELECT count(*) FROM trainforge_v1.account_erasures))::text;", target)
            if after_first != after_second:
                raise RuntimeError("Restore erasure reapplication not idempotent")
        finally:
            if created:
                sql("DROP DATABASE " + target + ";")
    return {"scope": "historical-account-backup-erasure-gate", "snapshotSha256": backup_sha,
            "resurrectedAccountsBeforeGate": resurrected, "erasedAccountsAfterGate": 0,
            "otherAccountAndEditorialPreserved": True, "reapplicationIdempotent": True,
            "temporaryRestoreDatabaseAndBackupRemoved": True, "targetPromoted": False}

def fixtures():
    verify_owned()
    start()
    before = snapshot()
    env, go = environment()
    name = "trainforge_v1_privacy_test_" + secrets.token_hex(6)
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
        raise RuntimeError("Disposable privacy target exists; refusing overwrite")
    writer = database_url(load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"], name)
    runtime = database_url(load_env(LOCAL / "api.env")["TF_DATABASE_URL"], name)
    created = False
    restore = None
    try:
        sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
        created = True
        env["TF_MIGRATION_DATABASE_URL"] = writer
        subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name +
            " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;", name)
        grant_runtime(name)
        env["TF_PRIVACY_TEST_DATABASE_URL"] = writer
        env["TF_PRIVACY_TEST_RUNTIME_URL"] = runtime
        subprocess.run([str(go), "test", "./internal/privacy", "-count=1", "-v"],
                       cwd=SERVICE, env=env, check=True, timeout=120)
        restore = restore_fixture(env, go, name, writer)
    finally:
        if created:
            sql("DROP DATABASE " + name + ";")
    if snapshot() != before:
        raise RuntimeError("Delivered account/editorial data changed during privacy fixtures")
    return {"scope": "disposable-privacy-postgresql-not-google-login", "passed": True, "restore": restore,
            "temporaryDatabaseRemoved": True, "deliveredAccountsAndEditorialUnchanged": True,
            "ownershipAndCursorBoundariesVerified": True, "unknownPrivateStoreFailsClosed": True,
            "recentSessionAndExpiringFamilyBoundConfirmationVerified": True,
            "atomicDeletionAndRollbackVerified": True, "otherAccountAndEditorialPreserved": True,
            "allDeviceTokensRevokedOnDeletion": True, "runtimeEditorialAndLedgerPrivilegesVerified": True,
            "boundedMaintenanceAndReplayRetentionVerified": True, "confirmationClockAuthority": "PostgreSQL",
            "realGoogleLoginValidated": False}

if __name__ == "__main__":
    result = fixtures()
    (ROOT / "docs/execucao/v1/privacy-local-verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
