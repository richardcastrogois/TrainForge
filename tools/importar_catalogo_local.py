"""Import only reviewed consultation metadata into the owned local development DB."""
import argparse
import subprocess
from dev_api import environment,SERVICE,LOCAL
from db_local import load_env,verify_owned

if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--dry-run",action="store_true");args=p.parse_args()
    env,go=environment()
    if not args.dry_run:verify_owned();env.update(load_env(LOCAL/"migrate.env"))
    subprocess.run([str(go),"run","./cmd/import-content",*(["--dry-run"] if args.dry_run else [])],cwd=SERVICE,env=env,check=True,timeout=90)
