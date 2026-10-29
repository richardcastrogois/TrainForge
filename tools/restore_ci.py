"""Hosted-only pg_dump/pg_restore and account-erasure gate. Never local evaluation."""
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
from db_permissions import runtime_statements
from sql_ci import check_environment as sql_environment, test_events, failure_locations

ROOT=Path(__file__).resolve().parents[1]
BOOTSTRAP='trainforge_ci_bootstrap'


def check_environment(env,root=ROOT,platform=sys.platform):
    if env.get('TF_RESTORE_CI')!='1':raise RuntimeError('Explicit restore CI required')
    sql_environment(dict(env,TF_SQL_CI='1'),root=root,platform=platform)
    if env.get('DOCKER_HOST') or env.get('DOCKER_CONTEXT'):raise RuntimeError('Foreign Docker context refused')
    if not re.fullmatch('[a-f0-9]{64}',env.get('TF_RESTORE_PG_CONTAINER','')):raise RuntimeError('Dedicated service container required')


def disposable_name(name):
    if not re.fullmatch(r'trainforge_v1_privacy_(?:test|restore)_[a-f0-9]{12}',name):raise RuntimeError('Unsafe restore fixture target')
    return name


def main():
    check_environment(os.environ)
    go,psql,docker=shutil.which('go'),shutil.which('psql'),shutil.which('docker')
    if not all((go,psql,docker)):raise RuntimeError('Hosted tools missing; no installation attempted')
    service=ROOT/'services/api';container=os.environ['TF_RESTORE_PG_CONTAINER']
    env={k:v for k,v in os.environ.items() if not k.startswith(('TF_','PG'))}
    admin=dict(env,PGPASSWORD=os.environ['TF_CI_PG_PASSWORD'])
    docker_env=dict(env,PGUSER=BOOTSTRAP,PGPASSWORD=os.environ['TF_CI_PG_PASSWORD'])
    report={'commit':os.environ['GITHUB_SHA'],'scope':'hosted-synthetic-dump-restore-erasure-gate',
        'status':'running','evaluationDataAccessed':False,'targetPromoted':False,'dumpUploaded':False,'dumpWrittenToDisk':False,
        'databasesRemoved':False,'rolesRemoved':False}
    artifact=Path(os.environ['RUNNER_TEMP'])/'restore-verification';artifact.mkdir(exist_ok=True)
    def sql(statement,database='postgres'):
        if database!='postgres':disposable_name(database)
        r=subprocess.run([psql,'-X','-q','-v','ON_ERROR_STOP=1','-h','127.0.0.1','-p','15432','-U',BOOTSTRAP,'-d',database,'-t','-A'],
            input=statement,env=admin,text=True,encoding='utf-8',stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=35)
        if r.returncode:raise RuntimeError('Restore fixture SQL failed; raw output withheld')
        return r.stdout.strip()
    if sql("SELECT (SELECT count(*) FROM pg_roles WHERE rolname IN('trainforge_owner','trainforge_migrator','trainforge_runtime'))+(SELECT count(*) FROM pg_database WHERE datname LIKE 'trainforge_v1_%');")!='0':
        raise RuntimeError('Fresh service required; existing state preserved')
    nonce=secrets.token_hex(6);source=disposable_name('trainforge_v1_privacy_test_'+nonce);target=disposable_name('trainforge_v1_privacy_restore_'+nonce)
    credentials={role:secrets.token_hex(32) for role in ('migrator','runtime')};created=[];roles=[];dump=b''
    def dsn(role,database):
        disposable_name(database)
        return 'postgresql://trainforge_'+role+':'+credentials[role]+'@127.0.0.1:15432/'+database+'?sslmode=disable'
    def command(args,settings=env,input=None,timeout=120):
        return subprocess.run(args,cwd=service,env=settings,input=input,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
    def go_test(name):
        r=command([go,'test','./internal/privacy','-run','^'+name+'$','-count=1','-json','-timeout=90s'])
        if r.returncode:
            report['failureLocations']=failure_locations(r.stdout);print(json.dumps({'failureLocations':report['failureLocations']}))
            raise RuntimeError('Restore fixture Go test failed; raw output withheld')
        return test_events(r.stdout,[name])
    def fingerprint(query,database):
        # Only a digest leaves this function; row data is neither logged nor uploaded.
        raw=sql("SELECT coalesce(jsonb_agg(to_jsonb(snapshot_row) ORDER BY to_jsonb(snapshot_row)::text),'[]'::jsonb)::text FROM ("+query+") snapshot_row;",database)
        return hashlib.sha256(raw.encode('utf-8')).hexdigest()
    def full_snapshot(database):
        tables=sql("SELECT string_agg(tablename,',' ORDER BY tablename) FROM pg_tables WHERE schemaname='trainforge_v1';",database).split(',')
        if len(tables)!=30 or any(not re.fullmatch('[a-z_]+',t) for t in tables):raise RuntimeError('Schema inventory changed; review restore coverage')
        return {t:fingerprint('SELECT * FROM trainforge_v1.'+t,database) for t in tables}
    def preserved_snapshot(database):
        result={}
        for table in ('sources','content_versions','content_withdrawals'):
            result[table]=fingerprint('SELECT * FROM trainforge_v1.'+table,database)
        result['publicFoods']=fingerprint('SELECT * FROM trainforge_v1.food_versions WHERE owner_id IS NULL',database)
        owner="(SELECT id FROM trainforge_v1.users WHERE subject='privacy-restore-b')"
        for table in ('users','auth_families','food_versions','food_entries','training_configuration_versions','meals','meal_items','meal_versions','idempotency_records','account_deletion_intents'):
            column='id' if table=='users' else ('owner_id' if table=='food_versions' else 'user_id')
            result['otherOwner:'+table]=fingerprint('SELECT * FROM trainforge_v1.'+table+' WHERE '+column+'='+owner,database)
        for table in ('access_tokens','refresh_tokens'):
            result['otherOwner:'+table]=fingerprint('SELECT * FROM trainforge_v1.'+table+' WHERE family_id IN(SELECT id FROM trainforge_v1.auth_families WHERE user_id='+owner+')',database)
        return result
    try:
        for role,password in credentials.items():
            print('::add-mask::'+password,flush=True)
            sql("CREATE ROLE trainforge_"+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '"+password+"';");roles.append(role)
        sql('CREATE DATABASE '+source+' OWNER trainforge_migrator;');created.append(source)
        sql('REVOKE ALL ON DATABASE '+source+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+source+' TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',source)
        env['TF_MIGRATION_DATABASE_URL']=dsn('migrator',source)
        for _ in range(2):
            if command([go,'run','./cmd/migrate']).returncode:raise RuntimeError('Restore source migration failed')
        latest=max(int(p.name.split('_',1)[0]) for p in (service/'migrations').glob('*.sql'))
        if sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',source)!=str(latest):raise RuntimeError('Restore source schema version mismatch')
        for statement in runtime_statements(training=True,meals=True):sql(statement,source)
        env['TF_PRIVACY_TEST_DATABASE_URL']=dsn('migrator',source);env['TF_PRIVACY_TEST_RUNTIME_URL']=dsn('runtime',source)
        env['TF_PRIVACY_RESTORE_PHASE']='prepare';report['prepareTests']=go_test('TestPrivacyRestorePrepareFixture')
        sql("INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('restore-ci-source','Synthetic public restore fixture','[]'); INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,payload) VALUES('restore-ci-movement',repeat('a',64),'movement','restore-ci-source','{}'); INSERT INTO trainforge_v1.food_versions(food_id,version_sha,source_id,name_original,nutrients,provenance) VALUES('restore-ci-editorial',repeat('b',64),'restore-ci-source','Synthetic public restore fixture','[]','{}');",source)
        before=full_snapshot(source)
        r=command([docker,'exec','-e','PGPASSWORD','-e','PGUSER',container,'pg_dump','-h','127.0.0.1','-p','5432','-d',source,'-Fc'],settings=docker_env)
        if r.returncode or not r.stdout.startswith(b'PGDMP'):raise RuntimeError('Matching-version service pg_dump failed')
        dump=r.stdout;report['dumpSha256']=hashlib.sha256(dump).hexdigest();report['dumpBytes']=len(dump)
        env['TF_PRIVACY_RESTORE_PHASE']='erase';report['eraseTests']=go_test('TestPrivacyRestoreEraseFixture')
        if sql("SELECT count(*) FROM trainforge_v1.account_erasures;",source)!='1':raise RuntimeError('Expected one synthetic erasure')
        sql('CREATE DATABASE '+target+' OWNER trainforge_migrator;');created.append(target)
        sql('REVOKE ALL ON DATABASE '+target+' FROM PUBLIC; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',target)
        r=command([docker,'exec','-i','-e','PGPASSWORD','-e','PGUSER',container,'pg_restore','-h','127.0.0.1','-p','5432','-d',target,'--no-owner','--role=trainforge_migrator','--exit-on-error'],settings=docker_env,input=dump)
        if r.returncode:raise RuntimeError('Matching-version service pg_restore failed')
        sql('REVOKE ALL ON DATABASE '+target+' FROM PUBLIC; REVOKE CONNECT ON DATABASE '+target+' FROM trainforge_runtime;')
        if full_snapshot(target)!=before:raise RuntimeError('Restored logical rows differ from pre-erasure backup')
        report['allThirtyTablesLogicalSnapshotMatched']=True
        if sql("SELECT count(*) FROM trainforge_v1.users WHERE subject='privacy-restore-a';",target)!='1':raise RuntimeError('Historical account fixture not present before gate')
        report['historicalAccountPresentBeforeGate']=True
        keep=preserved_snapshot(target);current_source=full_snapshot(source)
        env['TF_PRIVACY_LEDGER_SOURCE_DATABASE_URL']=dsn('migrator',source);env['TF_PRIVACY_RESTORE_DATABASE_URL']=dsn('migrator',target)
        first=None
        for _ in range(2):
            r=command([go,'run','./cmd/privacy-restore'])
            if r.returncode:raise RuntimeError('Restore erasure CLI failed; target remains unpromoted')
            output=json.loads(r.stdout)
            if output.get('processedErasureRecords')!=1 or output.get('sourceModified') is not False or output.get('targetPromoted') is not False:raise RuntimeError('Restore CLI evidence mismatch')
            if sql("SELECT count(*) FROM trainforge_v1.users WHERE subject='privacy-restore-a';",target)!='0':raise RuntimeError('Erased account survived restore gate')
            for table,column in [('users','id'),('auth_families','user_id'),('food_versions','owner_id'),('food_entries','user_id'),('training_configuration_versions','user_id'),('meals','user_id'),('meal_items','user_id'),('meal_versions','user_id'),('idempotency_records','user_id')]:
                if sql('SELECT count(*) FROM trainforge_v1.'+table+' WHERE '+column+' IN(SELECT user_id FROM trainforge_v1.account_erasures);',target)!='0':raise RuntimeError('Erased owner data survived gate')
            if preserved_snapshot(target)!=keep or full_snapshot(source)!=current_source:raise RuntimeError('Erasure gate changed other owner/editorial/source')
            snapshot=full_snapshot(target)
            if first is not None and snapshot!=first:raise RuntimeError('Erasure gate replay changed logical state')
            first=snapshot
        report.update({'schemaVersion':latest,'erasedAccountAbsentAfterGate':True,'privateMealsConfigurationAndFoodRemoved':True,
            'otherOwnerAndPublicMetadataPreserved':True,'sourceUnchangedByGate':True,'gateReplayIdempotent':True,
            'runtimeCannotConnectRestoreTarget':None})
        # The restore never gains a runtime CONNECT grant; verify actual denial, not a bad credential.
        probe=sql("SELECT has_database_privilege('trainforge_runtime','"+target+"','CONNECT');")
        if probe!='f':raise RuntimeError('Runtime can connect to offline restore target')
        report['runtimeCannotConnectRestoreTarget']=True
        report['status']='success'
    finally:
        dump=b''
        for name in reversed(created):sql('DROP DATABASE '+disposable_name(name)+' WITH(FORCE);')
        report['databasesRemoved']=True
        for role in roles:sql('DROP ROLE trainforge_'+role+';')
        report['rolesRemoved']=True
        if report['status']=='running':report['status']='failed'
        (artifact/'safe-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':
    try:main()
    except Exception as error:
        print('Restore CI failed: '+(str(error) if isinstance(error,RuntimeError) else type(error).__name__)+'; raw process output withheld.',file=sys.stderr)
        raise SystemExit(1)
