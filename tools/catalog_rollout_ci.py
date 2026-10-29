"""M3 extension to the fresh hosted catalog service; all dumps stay in memory."""
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
from db_permissions import runtime_statements
from sql_ci import test_events, failure_locations


def check_rollout_service(env):
    if not re.fullmatch('[a-f0-9]{64}',env.get('TF_CATALOG_PG_CONTAINER','')):raise RuntimeError('Dedicated catalog service container required')
    if env.get('DOCKER_HOST') or env.get('DOCKER_CONTEXT'):raise RuntimeError('Foreign Docker context refused')


def prove_rollout(*,sql,run,go,env,dsn,credentials,created,roles,report,service):
    check_rollout_service(os.environ)
    docker=shutil.which('docker')
    if not docker:raise RuntimeError('Hosted Docker client missing; no install attempted')
    container=os.environ['TF_CATALOG_PG_CONTAINER']
    catalog='trainforge_catalog_test_'+secrets.token_hex(6)
    core='trainforge_v1_config_test_'+secrets.token_hex(6)
    target='trainforge_catalog_test_'+secrets.token_hex(6)
    for role in ('trainforge_migrator','trainforge_runtime'):
        password=secrets.token_hex(32);credentials[role]=password
        print('::add-mask::'+password,flush=True)
        sql("CREATE ROLE "+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS CONNECTION LIMIT 8 PASSWORD '"+password+"';");roles.append(role)
    def create(database,owner,reader=None):
        sql('CREATE DATABASE '+database+' OWNER '+owner+';');created.append(database)
        sql('REVOKE ALL ON DATABASE '+database+' FROM PUBLIC;'+(' GRANT CONNECT ON DATABASE '+database+' TO '+reader+';' if reader else ''))
        sql('REVOKE CREATE ON SCHEMA public FROM PUBLIC;',database)
    create(core,'trainforge_migrator','trainforge_runtime')
    env['TF_MIGRATION_DATABASE_URL']=dsn('trainforge_migrator',core)
    if run([go,'run','./cmd/migrate']).returncode:raise RuntimeError('Rollout core migration failed')
    for statement in runtime_statements(training=True,meals=True):sql(statement,core)
    create(catalog,'trainforge_catalog_migrator','trainforge_catalog_reader')
    env['TF_CATALOG_MIGRATION_DATABASE_URL']=dsn('trainforge_catalog_migrator',catalog)
    if run([go,'run','./cmd/catalog-migrate']).returncode:raise RuntimeError('Rollout catalog migration failed')
    env.update(TF_CATALOG_ROLLOUT_CI='1',TF_ROLLOUT_CATALOG_WRITER=dsn('trainforge_catalog_migrator',catalog),
        TF_ROLLOUT_CATALOG_READER=dsn('trainforge_catalog_reader',catalog),
        TF_ROLLOUT_CORE_WRITER=dsn('trainforge_migrator',core),TF_ROLLOUT_CORE_RUNTIME=dsn('trainforge_runtime',core))
    def phase(name):
        env['TF_ROLLOUT_PHASE']=name
        result=run([go,'test','./internal/catalogbridge','-run','^TestCatalogRolloutSQL$','-count=1','-json','-timeout=100s'],130)
        if result.returncode:
            locations=failure_locations(result.stdout);report['rolloutFailureLocations']=locations
            print(json.dumps({'rolloutPhase':name,'failureLocations':locations}))
            raise RuntimeError('Rollout SQL phase failed; raw output withheld')
        events=test_events(result.stdout,['TestCatalogRolloutSQL'])
        print(json.dumps({'rolloutPhase':name,'tests':events}),flush=True)
        return events
    result={'prepare':phase('prepare'),'dumpUploaded':False,'dumpWrittenToDisk':False,'targetPromoted':False}
    settings={k:v for k,v in env.items() if not k.startswith(('TF_','PG'))}
    settings.update(PGUSER='trainforge_ci_bootstrap',PGPASSWORD=os.environ['TF_CI_PG_PASSWORD'])
    def pg(args,data=None):
        return subprocess.run([docker,'exec',*(['-i'] if data is not None else []),'-e','PGUSER','-e','PGPASSWORD',container,*args],
            input=data,env=settings,cwd=service,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=45)
    backup=pg(['pg_dump','-h','127.0.0.1','-d',catalog,'-Fc'])
    if backup.returncode or not backup.stdout.startswith(b'PGDMP'):raise RuntimeError('Catalog dump failed')
    dump=backup.stdout;result.update(dumpSha256=hashlib.sha256(dump).hexdigest(),dumpBytes=len(dump))
    result['withdraw']=phase('withdraw')
    create(target,'trainforge_catalog_migrator')
    restored=pg(['pg_restore','-h','127.0.0.1','-d',target,'--no-owner','--role=trainforge_catalog_migrator','--exit-on-error'],dump)
    dump=b''
    if restored.returncode:raise RuntimeError('Catalog old-backup restore failed')
    sql('REVOKE ALL ON DATABASE '+target+' FROM PUBLIC; REVOKE CONNECT ON DATABASE '+target+' FROM trainforge_catalog_reader;')
    if sql("SELECT has_database_privilege('trainforge_catalog_reader','"+target+"','CONNECT');")!='f':raise RuntimeError('Restore target not offline')
    env['TF_ROLLOUT_RESTORE_WRITER']=dsn('trainforge_catalog_migrator',target)
    result['restore']=phase('restore')
    result.update(status='success',authorityRevision=2,oldBackupRevision=1,withdrawalReappliedBeforePromotion=True,
        projectionRollbackAndCatchupPassed=True,networkFailureClosed=True,sessionAndPrivateDataPreserved=True,
        foodOnlySourceStayedInNutrition=True,restoreGateReplayIdempotent=True,restoreTargetOffline=True)
    report['rollout']=result
