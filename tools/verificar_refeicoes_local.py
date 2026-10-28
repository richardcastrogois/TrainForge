"""Meal SQL fixtures only in a guarded disposable database; never migrate the delivered DB."""
import json,re,secrets,subprocess
from urllib.parse import urlparse
from db_local import sql,NAME,LOCAL,DATA,load_env,verify_owned,start,run,grant_runtime
from dev_api import environment,SERVICE,ROOT
from verificar_auth_local import database_url

def snapshot():
    # Anonymous full-row digests detect changes to the existing real records/configuration.
    tables={"users":"id","food_entries":"id","food_versions":"food_id,version_sha",
            "content_versions":"asset_id,version_sha","training_configuration_versions":"user_id,revision"}
    return {table:sql("SELECT coalesce(md5(string_agg(row_to_json(v)::text,'' ORDER BY "+order+")),'empty') FROM trainforge_v1."+table+" v;",NAME) for table,order in tables.items()}

def main():
    verify_owned()
    try:run('pg_ctl',['-D',DATA,'status'],timeout=5);was_running=True
    except RuntimeError:was_running=False
    start();name='trainforge_v1_privacy_test_'+secrets.token_hex(6);created=False
    try:
        before=snapshot();env,go=environment()
        writer=database_url(load_env(LOCAL/'migrate.env')['TF_MIGRATION_DATABASE_URL'],name)
        runtime=database_url(load_env(LOCAL/'api.env')['TF_DATABASE_URL'],name)
        if not re.fullmatch(r'trainforge_v1_privacy_test_[a-f0-9]{12}',name):raise RuntimeError('Unsafe disposable name')
        for dsn,role in [(writer,'trainforge_migrator'),(runtime,'trainforge_runtime')]:
            target=urlparse(dsn)
            if target.hostname!='127.0.0.1' or target.port!=15432 or target.path!='/'+name or target.username!=role:raise RuntimeError('Unsafe disposable target')
        if sql("SELECT count(*) FROM pg_database WHERE datname='"+name+"';")!='0':raise RuntimeError('No overwrite')
        try:
            sql('CREATE DATABASE '+name+' OWNER trainforge_migrator;');created=True
            env['TF_MIGRATION_DATABASE_URL']=writer
            subprocess.run([str(go),'run','./cmd/migrate'],cwd=SERVICE,env=env,check=True,timeout=90)
            sql('REVOKE ALL ON DATABASE '+name+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+name+' TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',name)
            grant_runtime(name)
            env['TF_MEALS_TEST_DATABASE_URL']=writer;env['TF_MEALS_TEST_RUNTIME_URL']=runtime
            subprocess.run([str(go),'test','./internal/nutrition','-run','TestMealPostgres','-count=1','-v'],cwd=SERVICE,env=env,check=True,timeout=120)
            from verificar_privacidade_local import restore_fixture
            env['TF_PRIVACY_TEST_DATABASE_URL']=writer;env['TF_PRIVACY_TEST_RUNTIME_URL']=runtime
            restore_fixture(env,go,name,writer)
        finally:
            if created:sql('DROP DATABASE '+name+';')
            if snapshot()!=before:raise RuntimeError('Delivered data changed during disposable tests')
    finally:
        if not was_running:verify_owned();run('pg_ctl',['-D',DATA,'-m','fast','-w','-t','20','stop'],timeout=25)
    receipt={'date':'2026-10-28','story':'V1-045','status':'partial','passed':True,
             'scope':'disposable-meal-sql-not-human-meal-acceptance','schemaTested':13,
             'deliveredSchemaMigrated':False,'deliveredRecordsUnchanged':True,
             'disposableDatabaseRemoved':True,'clusterRunningStatePreserved':True,
             'atomicGroupAndIntakesVerified':True,'ownerAndLiveCredentialVerified':True,
             'concurrentCreateRetryVerified':True,'metadataRevisionsAndReplayVerified':True,
             'crossDayAndLegacyAndBoundVerified':True,'itemAndWholeMealDeletionVerified':True,
             'lateReplayDoesNotReviveDeletedMeal':True,'privateExportAndAccountErasureVerified':True,
             'runtimeDirectMealDmlRejected':True,'httpContractAndNegativeBoundariesVerified':True,
             'localizedDiaryReadVerified':['pt-BR','pt-PT','en','es'],'dumpAndRestoreErasureGateVerified':True,
             'otherOwnerMealsPreservedAfterRestore':True,
             'limits':['No real account,meal,intake or photo created/deleted.','Flutter and human acceptance have separate gates.']}
    (ROOT/'docs/execucao/v1/meal-grouping-sql-verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt))
if __name__=='__main__':main()
