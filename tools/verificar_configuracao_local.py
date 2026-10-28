"""V1-047 configuration SQL/HTTP fixtures in an owned disposable database only."""
import json,re,secrets,subprocess
from db_local import sql,NAME,LOCAL,DATA,load_env,verify_owned,start,run,grant_runtime
from dev_api import environment,SERVICE,ROOT
from urllib.parse import urlparse
from verificar_auth_local import database_url

def snapshot():
    return sql("""SELECT json_build_array(
     (SELECT md5(string_agg(row_to_json(u)::text,'' ORDER BY id)) FROM trainforge_v1.users u),
     (SELECT md5(string_agg(row_to_json(e)::text,'' ORDER BY id)) FROM trainforge_v1.food_entries e),
     (SELECT md5(string_agg(row_to_json(v)::text,'' ORDER BY food_id,version_sha)) FROM trainforge_v1.food_versions v),
     (SELECT md5(string_agg(row_to_json(v)::text,'' ORDER BY asset_id,version_sha)) FROM trainforge_v1.content_versions v))::text;""",NAME)

def main():
    verify_owned()
    try:run('pg_ctl',['-D',DATA,'status'],timeout=5);was_running=True
    except RuntimeError:was_running=False
    start();name='trainforge_v1_config_test_'+secrets.token_hex(6);created=False
    try:
        before=snapshot();env,go=environment()
        writer=database_url(load_env(LOCAL/'migrate.env')['TF_MIGRATION_DATABASE_URL'],name)
        runtime=database_url(load_env(LOCAL/'api.env')['TF_DATABASE_URL'],name)
        if not re.fullmatch(r'trainforge_v1_config_test_[a-f0-9]{12}',name):raise RuntimeError('Unsafe disposable name')
        for dsn,role in [(writer,"trainforge_migrator"),(runtime,"trainforge_runtime")]:
            target=urlparse(dsn)
            if target.hostname!="127.0.0.1" or target.port!=15432 or target.path!="/"+name or target.username!=role:raise RuntimeError("Unsafe disposable DSN target")
        if sql("SELECT count(*) FROM pg_database WHERE datname='"+name+"';")!='0':raise RuntimeError('No overwrite')
        try:
            sql('CREATE DATABASE '+name+' OWNER trainforge_migrator;');created=True
            env['TF_MIGRATION_DATABASE_URL']=writer
            subprocess.run([str(go),'run','./cmd/migrate'],cwd=SERVICE,env=env,check=True,timeout=90)
            sql('REVOKE ALL ON DATABASE '+name+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+name+' TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',name)
            grant_runtime(name)
            env['TF_CONFIGURATION_TEST_DATABASE_URL']=writer;env['TF_CONFIGURATION_TEST_RUNTIME_URL']=runtime
            subprocess.run([str(go),'test','./internal/trainingconfig','-count=1','-v'],cwd=SERVICE,env=env,check=True,timeout=90)
        finally:
            if created:sql('DROP DATABASE '+name+';')
        if snapshot()!=before:raise RuntimeError('Delivered records changed during isolated tests')
    finally:
        if not was_running:verify_owned();run('pg_ctl',['-D',DATA,'-m','fast','-w','-t','20','stop'],timeout=25)
    receipt={'schemaVersion':1,'date':'2026-10-27','story':'V1-047','status':'partial','passed':True,'scope':'disposable-configuration-sql-http-not-google-login','schemaTested':12,'deliveredSchemaMigrated':False,'deliveredRecordsUnchanged':True,'disposableDatabaseRemoved':True,'clusterRunningStatePreserved':True,'optimisticRevisionAndRetryVerified':True,'immutableVersionsVerified':True,'sourceScopedAndWithdrawnResourcesVerified':True,'liveCredentialRevalidationVerified':True,'privateExportAndErasureVerified':True,'runtimeDirectWritesRejected':True,'limits':['No real configuration,account or intake created/deleted.','Restore,Flutter and native acceptance need their own verification.']}
    (ROOT/'docs/execucao/v1/training-configuration-sql-verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt))
if __name__=='__main__':main()
