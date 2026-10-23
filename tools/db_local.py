"""Own isolated native PostgreSQL cluster; never touches the installed service data."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
from urllib.parse import quote, urlparse

ROOT=Path(__file__).resolve().parents[1]
LOCAL=ROOT/".local"
DATA=LOCAL/"pgdata"
STATE=LOCAL/"postgres-state.json"
BIN=Path(os.environ.get("TF_POSTGRES_BIN", "C:/Program Files/PostgreSQL/17/bin"))
PORT=15432
NAME="trainforge_v1_dev"


def run(name,args=(),input_text=None,env=None,timeout=35):
    binary=BIN/(name+".exe" if os.name=="nt" else name)
    # Background pg_ctl children can inherit pipes on Windows and prevent communicate() EOF.
    # A local file bounds waiting to the actual command process; no global process is stopped.
    LOCAL.mkdir(exist_ok=True)
    fd,path=tempfile.mkstemp(prefix="pg-command-",suffix=".log",dir=LOCAL);os.close(fd)
    try:
        with open(path,"w+",encoding="utf-8") as output:
            result=subprocess.run([str(binary),*map(str,args)],input=input_text,text=True,encoding="utf-8",errors="replace",stdout=output,stderr=subprocess.STDOUT,env=env,timeout=timeout,creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
            output.seek(0);text=output.read()
        if result.returncode:raise RuntimeError(name+" failed (details intentionally not echoed with credentials)")
        return text.strip()
    finally:
        try:Path(path).unlink()
        except PermissionError:pass


def load_env(path):
    values={}
    for line in path.read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            key,sep,value=line.partition("=")
            if sep:values[key]=value
    return values


def owner_env():
    values=load_env(LOCAL/"owner.env")
    env=os.environ.copy();env["PGPASSWORD"]=values["TF_PG_OWNER_PASSWORD"]
    return env


def sql(statement,db="postgres"):
    return run("psql",["-X","-q","-v","ON_ERROR_STOP=1","-h","127.0.0.1","-p",str(PORT),"-U","trainforge_owner","-d",db,"-t","-A"],statement,owner_env())


def verify_owned():
    state=json.loads(STATE.read_text(encoding="utf-8"))
    if state.get("scope")!="trainforge-isolated-v1" or Path(state["data"]).resolve()!=DATA.resolve() or not DATA.resolve().is_relative_to(LOCAL.resolve()):raise RuntimeError("Cluster ownership not verified")
    return state


def start():
    verify_owned()
    try:run("pg_ctl",["-D",DATA,"status"],timeout=5);return
    except RuntimeError:pass
    with socket.socket() as s:
        if s.connect_ex(("127.0.0.1",PORT))==0:raise RuntimeError("Port15432 occupied by another process")
    run("pg_ctl",["-D",DATA,"-l",LOCAL/"postgres.log","-o",f"-h 127.0.0.1 -p {PORT} -c shared_buffers=64MB -c max_connections=30","-w","-t","25","start"],timeout=32)


def initialize():
    LOCAL.mkdir(exist_ok=True)
    if STATE.exists():
        verify_owned();start()
        if not (LOCAL/"migrate.env").exists():provision()
        return
    if DATA.exists():raise RuntimeError("Unregistered data directory already exists; no overwrite/reset performed")
    version=run("postgres",["--version"])
    if "17." not in version:raise RuntimeError("Expected verified PostgreSQL17 binaries")
    passwords={name:secrets.token_urlsafe(30) for name in ("owner","migrator","runtime")}
    pw=LOCAL/"pg-init-password.txt";pw.write_text(passwords["owner"],encoding="utf-8")
    run("initdb",["-D",DATA,"-U","trainforge_owner","--pwfile",pw,"--auth-local=scram-sha-256","--auth-host=scram-sha-256","--encoding=UTF8","--locale=C"],timeout=60)
    state={"scope":"trainforge-isolated-v1","data":str(DATA.resolve()),"port":PORT,"database":NAME,"binaryDirectory":str(BIN.resolve()),"version":version,"windowsServiceChanged":False,"externalReleaseApproved":False}
    STATE.write_text(json.dumps(state,indent=2)+"\n",encoding="utf-8")
    (LOCAL/"owner.env").write_text("TF_PG_OWNER_PASSWORD="+passwords["owner"]+"\n",encoding="utf-8")
    start()
    provision()
    pw.unlink()


def provision():
    if sql("SELECT count(*) FROM pg_roles WHERE rolname IN ('trainforge_migrator','trainforge_runtime');")!="0":
        raise RuntimeError("Roles exist but credential files are missing; no automatic password reset")
    passwords={name:secrets.token_urlsafe(30) for name in ("migrator","runtime")}
    sql("CREATE ROLE trainforge_migrator LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '"+passwords["migrator"]+"';\nCREATE ROLE trainforge_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '"+passwords["runtime"]+"';\nCREATE DATABASE "+NAME+" OWNER trainforge_migrator;\n")
    sql("REVOKE ALL ON DATABASE "+NAME+" FROM PUBLIC; GRANT CONNECT ON DATABASE "+NAME+" TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;",NAME)
    def dsn(role):return "postgresql://trainforge_"+role+":"+quote(passwords[role],safe="")+"@127.0.0.1:"+str(PORT)+"/"+NAME+"?sslmode=disable"
    (LOCAL/"api.env").write_text("TF_ENV=development\nTF_LISTEN_ADDR=127.0.0.1:8082\nTF_SWAGGER=true\nTF_DATABASE_URL="+dsn("runtime")+"\n",encoding="utf-8")
    (LOCAL/"migrate.env").write_text("TF_MIGRATION_DATABASE_URL="+dsn("migrator")+"\nTF_IMPORT_DATABASE_URL="+dsn("migrator")+"\n",encoding="utf-8")



def grant_runtime(db=NAME):
    verify_owned()
    readonly=["sources","content_versions","content_withdrawals","program_sessions","program_items","food_versions","food_import_batches","food_batch_versions","food_withdrawals"]
    writable=["users","auth_families","refresh_tokens","access_tokens","enrollments","schedule_occurrences","activity_sessions","activity_events","idempotency_records","food_entries","account_deletion_intents"]
    sql("GRANT INSERT,SELECT(erased_at) ON trainforge_v1.account_erasures TO trainforge_runtime; GRANT EXECUTE ON FUNCTION trainforge_v1.erase_private_foods(uuid,uuid,bytea,bytea) TO trainforge_runtime;",db)
    sql("GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_runtime; GRANT SELECT ON "+",".join("trainforge_v1."+x for x in readonly)+" TO trainforge_runtime; GRANT SELECT,INSERT,UPDATE,DELETE ON "+",".join("trainforge_v1."+x for x in writable)+" TO trainforge_runtime;",db)


def main():
    p=argparse.ArgumentParser();p.add_argument("action",choices=["init","start","stop","status","grant-runtime"]);args=p.parse_args()
    if args.action=="init":initialize()
    elif args.action=="start":start()
    elif args.action=="stop":verify_owned();run("pg_ctl",["-D",DATA,"-m","fast","-w","-t","20","stop"],timeout=25)
    elif args.action=="grant-runtime":grant_runtime()
    else:verify_owned();print(run("pg_ctl",["-D",DATA,"status"]))
    print(json.dumps({"action":args.action,"scope":"trainforge-isolated-v1","port":PORT,"credentialsPrinted":False}))


if __name__=="__main__":main()
