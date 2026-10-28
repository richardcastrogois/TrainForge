"""Activate only migration12 in the owned local evaluation DB; never seed user answers."""
import hashlib,json,subprocess
from urllib.parse import urlparse
from db_local import verify_owned,start,sql,NAME,LOCAL,load_env,run,owner_env,grant_runtime
from dev_api import ROOT,SERVICE,environment
from verificar_configuracao_local import snapshot
from avaliar_android import port_occupied

def main():
    verify_owned();start()
    if port_occupied():raise RuntimeError("Stop the owned API before activation; no process was stopped by this helper")
    versions=[int(p.name.split("_",1)[0]) for p in (SERVICE/"migrations").glob("*.sql")]
    if not versions or max(versions)!=12:raise RuntimeError("This helper activates only the schema12 source checkpoint")
    if NAME!='trainforge_v1_dev':raise RuntimeError('Unexpected local DB')
    env,go=environment();dsn=load_env(LOCAL/'migrate.env')['TF_MIGRATION_DATABASE_URL'];target=urlparse(dsn)
    if target.hostname!='127.0.0.1' or target.port!=15432 or target.path!='/'+NAME or target.username!='trainforge_migrator':raise RuntimeError('Unsafe migration target')
    version=int(sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',NAME))
    if version!=11:raise RuntimeError('Expected schema11; inspect state before repeating activation')
    checkpoint=LOCAL/'checkpoints'/'training-configuration-before-12.sql'
    if checkpoint.exists():raise RuntimeError('Checkpoint already exists; inspect prior activation before retrying')
    checkpoint.parent.mkdir(parents=True,exist_ok=True)
    before=snapshot()
    run('pg_dump',['-h','127.0.0.1','-p','15432','-U','trainforge_owner','-d',NAME,'--schema-only','--file',checkpoint],env=owner_env(),timeout=30)
    env['TF_MIGRATION_DATABASE_URL']=dsn
    subprocess.run([str(go),'run','./cmd/migrate'],cwd=SERVICE,env=env,check=True,timeout=90)
    grant_runtime()
    if snapshot()!=before:raise RuntimeError('Delivered rows changed')
    after=int(sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',NAME))
    tables=int(sql("SELECT count(*) FROM information_schema.tables WHERE table_schema='trainforge_v1' AND table_type='BASE TABLE';",NAME))
    configurations=int(sql('SELECT count(*) FROM trainforge_v1.training_configuration_versions;',NAME))
    counts=json.loads(sql('SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),(SELECT count(*) FROM trainforge_v1.food_entries),(SELECT count(*) FROM trainforge_v1.food_versions))::text;',NAME))
    if after!=12 or tables!=27 or configurations!=0:raise RuntimeError('Unexpected activation result')
    receipt={'date':'2026-10-27','story':'V1-047','status':'partial','schemaFrom':11,'schemaTo':after,'tables':tables,'deliveredRowsUnchanged':True,'accountCount':counts[0],'entryCount':counts[1],'foodVersionCount':counts[2],'trainingConfigurationCount':configurations,'schemaOnlyCheckpointLocal':True,'checkpointSha256':hashlib.sha256(checkpoint.read_bytes()).hexdigest(),'runtimeGrantsApplied':True,'realUserConfigurationCreated':False,'limits':['Schema-only checkpoint is not a restored full backup.','Native/human configuration confirmation is not validated by migration.']}
    (ROOT/'docs/execucao/v1/training-configuration-local-activation.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8');print(json.dumps(receipt))
if __name__=='__main__':main()
