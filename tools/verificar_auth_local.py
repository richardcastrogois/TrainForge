"""Auth tests in a disposable database, never synthetic users in the delivered DB."""
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
from urllib.parse import urlsplit, urlunsplit
from db_local import sql, NAME, load_env, LOCAL, verify_owned, start
from dev_api import environment, SERVICE, ROOT

def database_url(dsn, name):
    parts = urlsplit(dsn)
    return urlunsplit(parts._replace(path="/" + name))

def main():
    verify_owned()
    start()
    name = "trainforge_v1_auth_test_" + secrets.token_hex(6)
    if not re.fullmatch(r"trainforge_v1_auth_test_[0-9a-f]{12}", name):
        raise RuntimeError("invalid disposable target")
    before = sql("SELECT count(*) FROM trainforge_v1.users;", NAME)
    if sql("SELECT count(*) FROM pg_database WHERE datname='" + name + "';") != "0":
        raise RuntimeError("test database already exists; no overwrite")
    env, go = environment()
    migration = load_env(LOCAL / "migrate.env")["TF_MIGRATION_DATABASE_URL"]
    runtime = load_env(LOCAL / "api.env")["TF_DATABASE_URL"]
    created = False
    success = False
    try:
        sql("CREATE DATABASE " + name + " OWNER trainforge_migrator;")
        created = True
        env["TF_MIGRATION_DATABASE_URL"] = database_url(migration, name)
        subprocess.run([str(go), "run", "./cmd/migrate"], cwd=SERVICE, env=env, check=True, timeout=90)
        sql("REVOKE ALL ON DATABASE " + name + " FROM PUBLIC; GRANT CONNECT ON DATABASE " + name + " TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC; GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_runtime; GRANT SELECT,INSERT,UPDATE,DELETE ON trainforge_v1.users,trainforge_v1.auth_families,trainforge_v1.refresh_tokens,trainforge_v1.access_tokens TO trainforge_runtime;", name)
        env["TF_AUTH_TEST_DATABASE_URL"] = database_url(runtime, name)
        subprocess.run([str(go), "test", "./internal/auth", "-count=1", "-v"], cwd=SERVICE, env=env, check=True, timeout=120)
        success = True
    finally:
        if created:
            # Exact, freshly generated name. No FORCE, no connections terminated elsewhere.
            sql("DROP DATABASE " + name + ";")
    after = sql("SELECT count(*) FROM trainforge_v1.users;", NAME)
    if before != after:
        raise RuntimeError("delivered user count changed")
    receipt = {"scope": "isolated-auth-fixtures-not-google-login", "passed": success,
               "temporaryDatabaseRemoved": True, "deliveredUserCountUnchanged": True,
               "realGoogleLoginValidated": False, "androidDebugOAuth": "console values match user screenshots",
               "androidReleaseOAuth": "pending dedicated signing certificate",
               "credentialsPrinted": False}
    (ROOT / "docs/execucao/v1/auth-local-verification.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt))

if __name__ == "__main__":
    main()
