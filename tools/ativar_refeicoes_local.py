"""Preview/apply only migration13 in the owned evaluation database; no business data is seeded."""
import argparse,hashlib,json,subprocess
from urllib.parse import urlparse
from db_local import verify_owned,sql,NAME,LOCAL,load_env,run,owner_env,grant_runtime
from dev_api import ROOT,SERVICE,environment
from verificar_refeicoes_local import snapshot
from avaliar_android import port_occupied

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true')
    args=parser.parse_args();verify_owned()
    if NAME!='trainforge_v1_dev':raise RuntimeError('Unexpected local database')
    versions=[int(p.name.split('_',1)[0]) for p in (SERVICE/'migrations').glob('*.sql')]
    if not versions or max(versions)!=13:raise RuntimeError('Only the reviewed schema13 checkpoint is accepted')
    version=int(sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',NAME))
    if version!=12:raise RuntimeError('Expected schema12; inspect state before repeating activation')
    verified=json.loads((ROOT/'docs/execucao/v1/meal-grouping-sql-verification.json').read_text(encoding='utf-8'))
    if not verified.get('passed') or verified.get('schemaTested')!=13 or not verified.get('dumpAndRestoreErasureGateVerified'):
        raise RuntimeError('Passing disposable SQL/HTTP/restore receipt required')
    dsn=load_env(LOCAL/'migrate.env')['TF_MIGRATION_DATABASE_URL'];target=urlparse(dsn)
    if target.hostname!='127.0.0.1' or target.port!=15432 or target.path!='/'+NAME or target.username!='trainforge_migrator':raise RuntimeError('Unsafe migration target')
    checkpoint=LOCAL/'checkpoints'/'meals-before-13.dump'
    if checkpoint.exists():raise RuntimeError('Checkpoint exists; inspect prior activation, do not overwrite it')
    if not args.apply:
        print(json.dumps({'scope':'local-meal-schema-preview','from':12,'to':13,'newTables':3,
                          'dataSeeded':False,'applied':False,'checkpointPlanned':'full-local-dump'}));return
    if port_occupied():raise RuntimeError('Stop only the registered API before activation; no process was stopped')
    checkpoint.parent.mkdir(parents=True,exist_ok=True)
    before=snapshot()
    run('pg_dump',['-h','127.0.0.1','-p','15432','-U','trainforge_owner','-d',NAME,'-Fc','--file',checkpoint],env=owner_env(),timeout=60)
    env,go=environment();env['TF_MIGRATION_DATABASE_URL']=dsn
    subprocess.run([str(go),'run','./cmd/migrate'],cwd=SERVICE,env=env,check=True,timeout=90)
    grant_runtime()
    if snapshot()!=before:raise RuntimeError('Existing delivered rows changed; inspect checkpoint and do not seed/retry')
    after=int(sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',NAME))
    counts=json.loads(sql("SELECT json_build_array((SELECT count(*) FROM information_schema.tables WHERE table_schema='trainforge_v1' AND table_type='BASE TABLE'),(SELECT count(*) FROM trainforge_v1.meals),(SELECT count(*) FROM trainforge_v1.meal_items),(SELECT count(*) FROM trainforge_v1.meal_versions))::text;",NAME))
    if after!=13 or counts!=[30,0,0,0]:raise RuntimeError('Unexpected activation result')
    receipt={'date':'2026-10-28','story':'V1-045','status':'partial','schemaFrom':12,'schemaTo':13,
             'tables':30,'mealCount':0,'membershipCount':0,'mealVersionCount':0,
             'deliveredRowsUnchanged':True,'runtimeGrantsApplied':True,'fullCheckpointLocal':True,
             'checkpointSha256':hashlib.sha256(checkpoint.read_bytes()).hexdigest(),
             'realMealOrIntakeCreated':False,'limits':['The new local checkpoint itself has not been restored; the migration and erasure gate were verified with disposable backups.','Activation does not establish native or human meal acceptance.']}
    (ROOT/'docs/execucao/v1/meal-grouping-local-activation.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(receipt))
if __name__=='__main__':main()
