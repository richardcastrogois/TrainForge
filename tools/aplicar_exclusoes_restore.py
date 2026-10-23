"""Preview/apply current erasures only to an offline, separately restored local DB."""
import argparse
import json
import re
import subprocess
from db_local import verify_owned, sql, NAME, LOCAL, load_env
from dev_api import environment, SERVICE
from verificar_auth_local import database_url

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--target-database",required=True)
    p.add_argument("--apply",action="store_true",help="Apply erasure gate; default only checks the boundary/counts")
    args=p.parse_args()
    target=args.target_database
    if not re.fullmatch(r"trainforge_v1_privacy_restore_[a-f0-9]{12}",target):
        raise RuntimeError("Restore target refused; live database is never accepted")
    verify_owned()
    if sql("SELECT count(*) FROM pg_database WHERE datname='"+target+"';")!="1":
        raise RuntimeError("Restore target does not exist; no DB created automatically")
    if sql("SELECT count(*) FROM pg_stat_activity WHERE datname='"+target+"';")!="0":
        raise RuntimeError("Restore target has connections; keep it offline before sanitization")
    if sql("SELECT count(*) FROM information_schema.tables WHERE table_schema='trainforge_v1' AND table_name='account_erasures';",target)!="1":
        raise RuntimeError("Apply current migrations to the separate target before the gate")
    count=int(sql("SELECT count(*) FROM trainforge_v1.account_erasures;",NAME))
    if not args.apply:
        print(json.dumps({"scope":"separate-restore-erasure-preview","sourceErasureRecords":count,"sourceModified":False,"targetModified":False,"targetPromoted":False}))
        return
    env,go=environment()
    writer=load_env(LOCAL/"migrate.env")["TF_MIGRATION_DATABASE_URL"]
    env["TF_PRIVACY_LEDGER_SOURCE_DATABASE_URL"]=writer
    env["TF_PRIVACY_RESTORE_DATABASE_URL"]=database_url(writer,target)
    subprocess.run([str(go),"run","./cmd/privacy-restore"],cwd=SERVICE,env=env,check=True,timeout=660)

if __name__=="__main__":
    main()
