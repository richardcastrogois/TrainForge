"""M1 catalog proof in a fresh hosted PostgreSQL service. Never evaluation data."""
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
from sql_ci import check_environment as sql_environment, test_events, failure_locations

ROOT=Path(__file__).resolve().parents[1]
BOOTSTRAP='trainforge_ci_bootstrap'
READER='trainforge_catalog_reader'
MIGRATOR='trainforge_catalog_migrator'


def check_environment(env,root=ROOT,platform=sys.platform):
    if env.get('TF_CATALOG_M1_CI')!='1': raise RuntimeError('Explicit catalog M1 CI required')
    sql_environment(dict(env,TF_SQL_CI='1'),root=root,platform=platform)


def disposable_name(name):
    if not re.fullmatch(r'(?:trainforge_catalog_test_|trainforge_v1_private_test_)[a-f0-9]{12}',name):
        raise RuntimeError('Unsafe M1 fixture target')
    return name


def runtime_dependencies(raw):
    decoder=json.JSONDecoder();text=raw.decode('utf-8');packages=[]
    while text.strip():
        item,end=decoder.raw_decode(text.lstrip());text=text.lstrip()[end:]
        path=item.get('ImportPath','')
        if path.startswith('trainforge.local/api/'):
            if path not in {'trainforge.local/api/cmd/catalog','trainforge.local/api/internal/catalog',
                'trainforge.local/api/internal/catalogruntime','trainforge.local/api/internal/catalogtarget',
                'trainforge.local/api/internal/platform/httpapi'}:
                raise RuntimeError('Catalog runtime imported another business domain')
            packages.append(path)
    if 'trainforge.local/api/cmd/catalog' not in packages: raise RuntimeError('Runtime inventory missing')
    return sorted(packages)


def main():
    check_environment(os.environ)
    go,psql=shutil.which('go'),shutil.which('psql')
    if not go or not psql: raise RuntimeError('Hosted Go/psql missing; no installation attempted')
    env={k:v for k,v in os.environ.items() if not k.startswith(('TF_','PG'))}
    admin=dict(env,PGPASSWORD=os.environ['TF_CI_PG_PASSWORD'])
    artifact=Path(os.environ['RUNNER_TEMP'])/'catalog-m1-verification';artifact.mkdir(exist_ok=True)
    service=ROOT/'services/api'
    report={'commit':os.environ['GITHUB_SHA'],'scope':'isolated-fixture-ci-M1-only','status':'running',
        'evaluationDataAccessed':False,'apkOrApiCutover':False,'realPracticeOrGoogleValidated':False,'fixturesRemoved':False}
    def sql(statement,database='postgres'):
        if database!='postgres':disposable_name(database)
        r=subprocess.run([psql,'-X','-q','-v','ON_ERROR_STOP=1','-h','127.0.0.1','-p','15432','-U',BOOTSTRAP,'-d',database,'-t','-A'],
            input=statement,env=admin,text=True,encoding='utf-8',stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=35)
        if r.returncode:raise RuntimeError('M1 fixture SQL failed; raw output withheld')
        return r.stdout.strip()
    if sql("SELECT (SELECT count(*) FROM pg_roles WHERE rolname LIKE 'trainforge_%' AND rolname<>'trainforge_ci_bootstrap')+(SELECT count(*) FROM pg_database WHERE datname LIKE 'trainforge_%');")!='0':
        raise RuntimeError('Fresh dedicated service required')
    nonce=secrets.token_hex(6);catalog=disposable_name('trainforge_catalog_test_'+nonce);private=disposable_name('trainforge_v1_private_test_'+nonce)
    credentials={role:secrets.token_hex(32) for role in (READER,MIGRATOR)}
    created=[];roles=[]
    def dsn(role,database):
        disposable_name(database)
        return 'postgresql://'+role+':'+credentials[role]+'@127.0.0.1:15432/'+database+'?sslmode=disable'
    def run(args,timeout=120):
        return subprocess.run(args,cwd=service,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
    try:
        sql('REVOKE CONNECT ON DATABASE postgres,template1 FROM PUBLIC;')
        for role,password in credentials.items():
            print('::add-mask::'+password,flush=True)
            limit=12 if role==READER else 4
            sql("CREATE ROLE "+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT "+str(limit)+" PASSWORD '"+password+"';");roles.append(role)
        sql('CREATE DATABASE '+private+';');created.append(private)
        sql('REVOKE ALL ON DATABASE '+private+' FROM PUBLIC;')
        sql('CREATE SCHEMA trainforge_v1; CREATE TABLE trainforge_v1.users(id int); CREATE TABLE trainforge_v1.auth_families(id int); CREATE TABLE trainforge_v1.food_entries(id int);',private)
        sql('CREATE DATABASE '+catalog+' OWNER '+MIGRATOR+';');created.append(catalog)
        sql('REVOKE ALL ON DATABASE '+catalog+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+catalog+' TO '+READER+';')
        sql('REVOKE CREATE ON SCHEMA public FROM PUBLIC; GRANT USAGE,CREATE ON SCHEMA public TO '+MIGRATOR+';',catalog)
        env['TF_CATALOG_MIGRATION_DATABASE_URL']=dsn(MIGRATOR,catalog)
        applied=[]
        for _ in range(2):
            result=run([go,'run','./cmd/catalog-migrate'])
            if result.returncode:raise RuntimeError('Isolated catalog migration failed')
            match=re.search(rb'catalog_migrations_applied=([0-9]+)',result.stdout)
            if not match:raise RuntimeError('Missing migration evidence')
            applied.append(int(match[1]))
        if applied!=[1,0]:raise RuntimeError('Migration rerun not idempotent')
        objects=sql("SELECT string_agg(table_schema||'.'||table_name,',' ORDER BY table_schema,table_name) FROM information_schema.tables WHERE table_schema IN('public','trainforge_v1') AND table_type='BASE TABLE';",catalog).split(',')
        if objects!=['public.trainforge_catalog_schema_version','trainforge_v1.content_versions','trainforge_v1.content_withdrawals','trainforge_v1.sources']:
            raise RuntimeError('Projection contains unexpected tables')
        report['migrationsAppliedAndRerun']=applied;report['catalogDatabaseTables']=objects
        binary=Path(os.environ['RUNNER_TEMP'])/'trainforge-catalog-m1'
        result=run([go,'build','-trimpath','-buildvcs=false','-o',str(binary),'./cmd/catalog'])
        if result.returncode:raise RuntimeError('Standalone build failed')
        report['binarySha256']=hashlib.sha256(binary.read_bytes()).hexdigest()
        result=run([go,'list','-deps','-json','./cmd/catalog'])
        if result.returncode:raise RuntimeError('Dependency inventory failed')
        report['internalRuntimeDependencies']=runtime_dependencies(result.stdout)
        env['TF_CATALOG_M1_TEST_WRITER_URL']=dsn(MIGRATOR,catalog)
        env['TF_CATALOG_M1_TEST_READER_URL']=dsn(READER,catalog)
        env['TF_CATALOG_M1_PRIVATE_READER_URL']=dsn(READER,private)
        env['TF_CATALOG_M1_BINARY']=str(binary)
        env['TF_CATALOG_M1_CI']='1'
        result=run([go,'test','./internal/catalogruntime','-run','^TestIsolatedCatalogM1$','-count=1','-json','-timeout=120s'],150)
        if result.returncode:
            report['failureLocations']=failure_locations(result.stdout)
            print(json.dumps({'status':'failed','failureLocations':report['failureLocations']}))
            raise RuntimeError('M1 SQL/process/contract test failed; raw output withheld')
        report['tests']=test_events(result.stdout,['TestIsolatedCatalogM1'])
        for event in report['tests']:print(json.dumps(event),flush=True)
        report['status']='success'
    finally:
        for name in reversed(created):sql('DROP DATABASE '+disposable_name(name)+' WITH(FORCE);')
        for role in roles:sql('DROP ROLE '+role+';')
        report['fixturesRemoved']=True
        if report['status']=='running':report['status']='failed'
        (artifact/'safe-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':
    try:main()
    except Exception as error:
        # RuntimeErrors here are fixed operator messages; process/SQL output stays private.
        print('Catalog M1 CI failed: '+(str(error) if isinstance(error,RuntimeError) else type(error).__name__),file=sys.stderr)
        raise SystemExit(1)
