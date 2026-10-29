"""Owned local M4 transition. Never cloud, OAuth, APK installation or private business writes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import socket
import subprocess
import sys
import time
from urllib.request import build_opener,ProxyHandler
from db_local import LOCAL,NAME,DATA,verify_owned,start as start_database,run as pg_run,sql,load_env,owner_env
from dev_api import ROOT,SERVICE,environment,stop_owned

DIRECTORY=LOCAL/'catalog-evaluation'
STATE=DIRECTORY/'runtime.json'
CATALOG='trainforge_catalog_dev'
ROLES=('trainforge_catalog_reader','trainforge_catalog_migrator')
HTTP=build_opener(ProxyHandler({}))


def request(path,port=18083):
    with HTTP.open('http://127.0.0.1:'+str(port)+path,timeout=3) as response:
        return response.status,response.headers, response.read(2*1024*1024+1)


def ready():
    try:return request('/api/v1/health/ready')[0]==200
    except Exception:return False


def owned_state():
    value=json.loads(STATE.read_text(encoding='utf-8'))
    if value.get('root')!=str(ROOT) or value.get('database')!=CATALOG:raise RuntimeError('Catalog ownership mismatch')
    return value


def save_state(value):
    DIRECTORY.mkdir(exist_ok=True);STATE.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')


def protect(path):
    if os.name=='nt':
        identity=subprocess.run(['whoami','/user','/fo','csv','/nh'],capture_output=True,text=True,check=True).stdout
        sid=re.search(r'S-1-5-[0-9-]+',identity)
        if not sid:raise RuntimeError('Current Windows SID unavailable')
        result=subprocess.run(['icacls',str(path),'/inheritance:r','/grant:r','*'+sid.group(0)+':(F)','*S-1-5-18:(F)'],capture_output=True,text=True)
        if result.returncode:raise RuntimeError('Local credential permissions not restricted')
    else:path.chmod(0o600)


def settings():
    env,go=environment(include_api_env=False);env.update(load_env(DIRECTORY/'catalog.env'))
    env.update(load_env(LOCAL/'migrate.env'))
    env['TF_CATALOG_CORE_DATABASE_URL']=env['TF_MIGRATION_DATABASE_URL']
    return env,go


def go_command(args,env,go):
    result=subprocess.run([str(go),*args],cwd=SERVICE,env=env,capture_output=True,timeout=100)
    if result.returncode:raise RuntimeError('Catalog Go operation failed; raw output withheld')
    return result.stdout


def snapshot(database):
    tables=sql("SELECT string_agg(tablename,',' ORDER BY tablename) FROM pg_tables WHERE schemaname='trainforge_v1';",database).split(',')
    if len(tables)!=30 or any(not re.fullmatch('[a-z_]+',t) for t in tables):raise RuntimeError('Core inventory changed')
    result={}
    for table in tables:
        raw=sql("SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY to_jsonb(v)::text),'[]'::jsonb)::text FROM trainforge_v1."+table+' v;',database)
        result[table]=hashlib.sha256(raw.encode('utf-8')).hexdigest()
    return result


def checkpoint(before):
    backup=DIRECTORY/('core-before-'+secrets.token_hex(6)+'.dump')
    backup.touch(exist_ok=False);protect(backup)
    pg_run('pg_dump',['-h','127.0.0.1','-p','15432','-U','trainforge_owner','-d',NAME,'-Fc','-f',backup],env=owner_env(),timeout=100)
    temporary='trainforge_v1_catalog_restore_'+secrets.token_hex(6)
    if not re.fullmatch('trainforge_v1_catalog_restore_[a-f0-9]{12}',temporary):raise RuntimeError('Unsafe restore target')
    created=False
    try:
        sql('CREATE DATABASE '+temporary+' OWNER trainforge_migrator;');created=True
        sql('REVOKE ALL ON DATABASE '+temporary+' FROM PUBLIC;')
        pg_run('pg_restore',['-h','127.0.0.1','-p','15432','-U','trainforge_owner','-d',temporary,'--no-owner','--role=trainforge_migrator','--exit-on-error',backup],env=owner_env(),timeout=100)
        sql('REVOKE ALL ON DATABASE '+temporary+' FROM PUBLIC; REVOKE CONNECT ON DATABASE '+temporary+' FROM trainforge_runtime;')
        if snapshot(temporary)!=before:raise RuntimeError('Checkpoint logical restore differs')
        if sql("SELECT has_database_privilege('trainforge_runtime','"+temporary+"','CONNECT');")!='f':raise RuntimeError('Restore target not offline')
    finally:
        if created:sql('DROP DATABASE '+temporary+' WITH(FORCE);')
    return {'path':str(backup),'sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),'logicalRestoreMatched30Tables':True,'restoreTargetOfflineAndRemoved':True}


def provision():
    verify_owned();start_database();DIRECTORY.mkdir(exist_ok=True)
    if STATE.exists():return owned_state()
    if sql("SELECT count(*) FROM pg_roles WHERE rolname IN('trainforge_catalog_reader','trainforge_catalog_migrator');")!='0' or sql("SELECT count(*) FROM pg_database WHERE datname='trainforge_catalog_dev';")!='0':raise RuntimeError('Existing catalog not registered; no password reset or takeover')
    credentials={role:secrets.token_hex(32) for role in ROLES}
    def dsn(role):return 'postgresql://'+role+':'+credentials[role]+'@127.0.0.1:15432/'+CATALOG+'?sslmode=disable'
    file=DIRECTORY/'catalog.env';file.touch(exist_ok=False);protect(file)
    file.write_text('TF_CATALOG_MODE=local\nTF_CATALOG_DATABASE_URL='+dsn(ROLES[0])+'\nTF_CATALOG_MIGRATION_DATABASE_URL='+dsn(ROLES[1])+'\nTF_CATALOG_PACKAGE_ROOT='+str(DIRECTORY)+'\n',encoding='utf-8')
    for role,password in credentials.items():
        limit=12 if role.endswith('reader') else 4
        sql("CREATE ROLE "+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT "+str(limit)+" PASSWORD '"+password+"';")
    sql('CREATE DATABASE '+CATALOG+' OWNER trainforge_catalog_migrator;')
    sql('REVOKE ALL ON DATABASE '+CATALOG+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+CATALOG+' TO trainforge_catalog_reader;')
    sql('REVOKE CREATE ON SCHEMA public FROM PUBLIC;',CATALOG)
    state={'root':str(ROOT),'database':CATALOG,'mode':'prepared','privateRowsWritten':False};save_state(state);return state


def start_reader(state):
    if ready():
        # Reuse only a registered binary identity and correct database revision.
        if not state.get('binarySha256'):raise RuntimeError('Listener18083 not owned by this helper')
        return
    with socket.socket() as probe:
        if probe.connect_ex(('127.0.0.1',18083))==0:raise RuntimeError('Unknown listener18083; not stopped')
    env,go=settings();binary=DIRECTORY/('catalog.exe' if os.name=='nt' else 'catalog')
    go_command(['build','-trimpath','-o',str(binary),'./cmd/catalog'],env,go)
    state['binarySha256']=hashlib.sha256(binary.read_bytes()).hexdigest();state['stopFile']=str(DIRECTORY/('stop-'+secrets.token_hex(8)+'.flag'));save_state(state)
    with (DIRECTORY/'catalog.log').open('a',encoding='utf-8') as log:
        subprocess.Popen([sys.executable,str(Path(__file__).resolve()),'serve'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    end=time.monotonic()+20
    while time.monotonic()<end:
        if ready():return
        time.sleep(.25)
    raise RuntimeError('Catalog reader not ready; API configuration preserved')


def serve():
    state=owned_state();binary=DIRECTORY/('catalog.exe' if os.name=='nt' else 'catalog')
    if hashlib.sha256(binary.read_bytes()).hexdigest()!=state['binarySha256']:raise RuntimeError('Catalog binary identity changed')
    stop=Path(state['stopFile']).resolve()
    if stop.parent!=DIRECTORY.resolve() or not re.fullmatch('stop-[a-f0-9]{16}.flag',stop.name):raise RuntimeError('Unsafe stop path')
    env,_=settings();env.pop('TF_CATALOG_MIGRATION_DATABASE_URL',None);env.pop('TF_CATALOG_CORE_DATABASE_URL',None);env.pop('TF_MIGRATION_DATABASE_URL',None);env.pop('TF_IMPORT_DATABASE_URL',None)
    process=subprocess.Popen([str(binary)],cwd=SERVICE,env=env,creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name=='nt' else 0)
    try:
        while not stop.exists():
            if process.poll() is not None:raise RuntimeError('Owned catalog stopped')
            time.sleep(.5)
    finally:stop_owned(process)


def select_mode(mode):
    if mode not in ('remote','local-verified'):raise RuntimeError('Invalid explicit read mode')
    state=owned_state();env,go=settings()
    evidence=json.loads(go_command(['run','./cmd/catalog-transition','--action','verify'],env,go))
    # A running API must have a registered stop file before it can be restarted.
    from avaliar_android import STATE as API_STATE,STATE_DIR as API_DIR,port_occupied,wait_for
    if port_occupied():
        old=json.loads(API_STATE.read_text(encoding='utf-8'));stop=Path(old.get('apiStopFile','')).resolve()
        if old.get('root')!=str(ROOT) or stop.parent!=API_DIR.resolve() or not re.fullmatch('api-stop-[a-f0-9]{16}.flag',stop.name):raise RuntimeError('API listener not owned; configuration preserved')
        stop.touch();wait_for(lambda:not port_occupied(),15,'Owned API did not stop')
    path=LOCAL/'api.env';lines=path.read_text(encoding='utf-8-sig').splitlines()
    lines=[v for v in lines if not v.startswith(('TF_CATALOG_URL=','TF_CATALOG_READ_MODE='))]
    lines+=['TF_CATALOG_URL=http://127.0.0.1:18083','TF_CATALOG_READ_MODE='+mode]
    path.write_text('\n'.join(lines)+'\n',encoding='utf-8')
    state['mode']=mode;state['head']=evidence['head'];save_state(state)
    return state


def activate():
    state=provision();before=snapshot(NAME)
    if 'checkpoint' not in state:state['checkpoint']=checkpoint(before);save_state(state)
    env,go=settings()
    go_command(['run','./cmd/catalog-migrate'],env,go)
    bootstrap=json.loads(go_command(['run','./cmd/catalog-transition','--action','bootstrap'],env,go))
    if snapshot(NAME)!=before:raise RuntimeError('Bootstrap modified core data; no route change')
    state['head']=bootstrap['head'];state['coreSnapshotSha256']=hashlib.sha256(json.dumps(before,sort_keys=True).encode()).hexdigest();save_state(state)
    start_reader(state);selected=select_mode('remote')
    return {'mode':selected['mode'],'head':selected['head'],'core30TablesUnchanged':True,'checkpointRestoredAndCompared':True,'privateRowsWritten':False,'apkChanged':False}


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('action',choices=['activate','verify','rollback','serve']);args=parser.parse_args()
    if args.action=='serve':serve();return
    if args.action=='activate':result=activate()
    elif args.action=='rollback':state=select_mode('local-verified');result={'mode':state['mode'],'head':state['head']}
    else:
        env,go=settings();result=json.loads(go_command(['run','./cmd/catalog-transition','--action','verify'],env,go))
    print(json.dumps(result,ensure_ascii=True))
if __name__=='__main__':
    try:main()
    except Exception as error:
        print('Catalog local operation failed; sensitive details withheld: '+type(error).__name__,file=sys.stderr);raise SystemExit(1)
