"""Apply only the owned development DB's forward migrations."""
import subprocess
from dev_api import environment, ROOT, SERVICE, LOCAL
from db_local import load_env, verify_owned

if __name__=="__main__":
    verify_owned();env,go=environment()
    env.update(load_env(LOCAL/"migrate.env"))
    subprocess.run([str(go),"run","./cmd/migrate"],cwd=SERVICE,env=env,check=True,timeout=90)
