"""Migrations and meal SQL fixtures in a fresh GitHub-hosted service only. No local mode."""
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
from db_permissions import runtime_statements

ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP = 'trainforge_ci_bootstrap'


def check_environment(env, *, root=ROOT, platform=sys.platform):
    if platform != 'linux' or any(env.get(k) != v for k,v in {
        'CI':'true','GITHUB_ACTIONS':'true','RUNNER_ENVIRONMENT':'github-hosted',
        'TF_SQL_CI':'1',
    }.items()):
        raise RuntimeError('Only an explicit GitHub-hosted Linux fixture is accepted')
    if not env.get('GITHUB_WORKSPACE') or Path(env['GITHUB_WORKSPACE']).resolve() != root.resolve():
        raise RuntimeError('Unexpected checkout')
    if any(env.get(k) for k in ('TF_DATABASE_URL','TF_MIGRATION_DATABASE_URL',
                               'TF_IMPORT_DATABASE_URL','DATABASE_URL','PGSERVICE','PGSERVICEFILE')):
        raise RuntimeError('Existing connection configuration refused')
    if any((root/'.local'/name).exists() for name in ('api.env','owner.env','migrate.env','postgres-state.json')):
        raise RuntimeError('Local evaluation state refused')
    if len(env.get('TF_CI_PG_PASSWORD','')) < 16:
        raise RuntimeError('Explicit disposable bootstrap credential required')


def disposable_name(name):
    if not re.fullmatch(r'trainforge_v1_privacy_test_[a-f0-9]{12}', name):
        raise RuntimeError('Unsafe fixture name')
    return name


def main():
    check_environment(os.environ)
    go, psql = shutil.which('go'), shutil.which('psql')
    if not go or not psql:
        raise RuntimeError('Go and psql are required; no automatic installation')
    env = {k:v for k,v in os.environ.items() if not k.startswith(('TF_','PG'))}
    admin_env = dict(env, PGPASSWORD=os.environ['TF_CI_PG_PASSWORD'])

    def sql(statement, database='postgres'):
        if database != 'postgres': disposable_name(database)
        result = subprocess.run([psql,'-X','-q','-v','ON_ERROR_STOP=1','-h','127.0.0.1',
            '-p','15432','-U',BOOTSTRAP,'-d',database,'-t','-A'], input=statement,
            env=admin_env,text=True,encoding='utf-8',stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,timeout=35)
        if result.returncode:
            raise RuntimeError('Disposable database command failed; credentials not echoed')
        return result.stdout.strip()

    # This guard also refuses a mistakenly configured evaluation/production cluster.
    if sql("SELECT (SELECT count(*) FROM pg_roles WHERE rolname IN ('trainforge_owner','trainforge_migrator','trainforge_runtime'))+(SELECT count(*) FROM pg_database WHERE datname LIKE 'trainforge_v1_%');") != '0':
        raise RuntimeError('Fresh service required; existing roles/databases preserved')
    name = disposable_name('trainforge_v1_privacy_test_'+secrets.token_hex(6))
    credentials = {role:secrets.token_hex(32) for role in ('migrator','runtime')}
    for password in credentials.values(): print('::add-mask::'+password, flush=True)
    for role,password in credentials.items():
        sql("CREATE ROLE trainforge_"+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '"+password+"';")
    created = False
    def dsn(role):
        return 'postgresql://trainforge_'+role+':'+credentials[role]+'@127.0.0.1:15432/'+name+'?sslmode=disable'
    try:
        sql('CREATE DATABASE '+name+' OWNER trainforge_migrator;');created = True
        sql('REVOKE ALL ON DATABASE '+name+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+name+' TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',name)
        env['TF_MIGRATION_DATABASE_URL'] = dsn('migrator')
        service = ROOT/'services/api'
        for _ in range(2):
            subprocess.run([go,'run','./cmd/migrate'],cwd=service,env=env,check=True,timeout=120)
        latest = max(int(p.name.split('_',1)[0]) for p in (service/'migrations').glob('*.sql'))
        if sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',name) != str(latest):
            raise RuntimeError('Migration version mismatch')
        for statement in runtime_statements(training=True,meals=True): sql(statement,name)
        env['TF_MEALS_TEST_DATABASE_URL'] = dsn('migrator')
        env['TF_MEALS_TEST_RUNTIME_URL'] = dsn('runtime')
        subprocess.run([go,'test','./internal/platform/postgres','-run','^TestPostgresRuntimeReadiness$','-count=1','-v'],
                       cwd=service,env=env,check=True,timeout=90)
        subprocess.run([go,'test','./internal/nutrition','-run','^TestMealPostgres','-count=1','-v'],
                       cwd=service,env=env,check=True,timeout=180)
        env['TF_PRIVACY_TEST_DATABASE_URL'] = dsn('migrator')
        env['TF_PRIVACY_TEST_RUNTIME_URL'] = dsn('runtime')
        subprocess.run([go,'test','./internal/privacy','-run','^TestPrivacyPostgresOwnerExportConfirmedDeletionAndRollback$','-count=1','-v'],
                       cwd=service,env=env,check=True,timeout=120)
    finally:
        if created: sql('DROP DATABASE '+disposable_name(name)+';')
    print(json.dumps({'scope':'fresh-github-service-only','migrationsApplied':latest,
        'migrationRerun':True,'runtimeReadinessPassed':True,'mealSqlAndHttpPassed':True,'privacySqlPassed':True,
        'disposableDatabaseRemoved':True,'realGoogleOrHumanAcceptance':False}))


if __name__ == '__main__':
    try: main()
    except (RuntimeError,OSError,subprocess.SubprocessError) as error:
        # Do not stringify CalledProcessError: its env/command may change in future.
        print('SQL CI failed: '+(str(error) if isinstance(error,RuntimeError) else 'bounded process failure'),file=sys.stderr)
        raise SystemExit(1)
