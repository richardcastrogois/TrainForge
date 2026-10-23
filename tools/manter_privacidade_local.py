"""Preview/apply bounded local privacy maintenance; never removes backups/accounts."""
import argparse
import subprocess
from db_local import LOCAL, load_env, verify_owned
from dev_api import environment, SERVICE

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply",action="store_true",help="Apply one bounded batch; default previews only")
    args=p.parse_args()
    verify_owned()
    env,go=environment()
    env["TF_PRIVACY_MAINTENANCE_DATABASE_URL"]=load_env(LOCAL/"migrate.env")["TF_MIGRATION_DATABASE_URL"]
    command=[str(go),"run","./cmd/privacy-maintenance"]
    if args.apply:
        command.append("--apply")
    subprocess.run(command,cwd=SERVICE,env=env,check=True,timeout=45)

if __name__=="__main__":
    main()
