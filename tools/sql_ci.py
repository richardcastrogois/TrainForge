"""Migrations and isolated domain SQL fixtures in a fresh GitHub-hosted service only. No local mode."""
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

# Existing SQL tests have intentionally different disposable-name/DSN contracts.
# Each suite gets a fresh database; no fixture state is shared across domains.
SUITES = (
    ('privacy', 'privacy', (
        ('./internal/platform/postgres', ('TestPostgresRuntimeReadiness',)),
        ('./internal/nutrition', ('TestMealPostgresAtomicOwnershipReplayAndPrivacy',
            'TestMealPostgresDayBoundAndLegacy', 'TestMealPostgresHTTPContractAndBoundaries')),
        ('./internal/privacy', ('TestPrivacyPostgresOwnerExportConfirmedDeletionAndRollback',
            'TestPrivacyDeleteRefreshConcurrencyRevokesWinner', 'TestPrivacyMaintenancePreservesActiveReplayDetection')),
    ), {'TF_MEALS_TEST_DATABASE_URL':'migrator', 'TF_MEALS_TEST_RUNTIME_URL':'runtime',
        'TF_PRIVACY_TEST_DATABASE_URL':'migrator', 'TF_PRIVACY_TEST_RUNTIME_URL':'runtime'}),
    ('auth', 'auth', (('./internal/auth', ('TestPostgresIsolatedSessionLifecycle',)),),
        {'TF_AUTH_TEST_DATABASE_URL':'runtime'}),
    ('catalog', 'catalog', (('./internal/catalog', ('TestCatalogPostgresAndConditionalWithdrawal',)),),
        {'TF_CATALOG_TEST_DATABASE_URL':'runtime', 'TF_CATALOG_TEST_WRITER_DATABASE_URL':'migrator'}),
    ('food-import', 'food', (('./internal/nutrition', ('TestFoodPostgresIdempotencyRollbackAndReadonlyRuntime',)),),
        {'TF_FOOD_TEST_DATABASE_URL':'migrator', 'TF_FOOD_TEST_RUNTIME_URL':'runtime'}),
    ('food-read', 'food', (('./internal/nutrition', ('TestFoodPublicPostgresVisibilityPaginationAndWithdrawal',)),),
        {'TF_FOOD_TEST_DATABASE_URL':'migrator', 'TF_FOOD_TEST_RUNTIME_URL':'runtime'}),
    ('nutrition', 'nutrition', (('./internal/nutrition', ('TestNutritionPostgresFixtureLifecycle',)),),
        {'TF_NUTRITION_TEST_DATABASE_URL':'migrator', 'TF_NUTRITION_TEST_RUNTIME_URL':'runtime'}),
    ('names', 'names', (('./internal/nutrition', ('TestFoodNamesPostgresImmutabilityAndRuntimePermissions',)),),
        {'TF_FOOD_NAMES_TEST_DATABASE_URL':'migrator', 'TF_FOOD_NAMES_TEST_RUNTIME_URL':'runtime'}),
    ('configuration', 'config', (('./internal/trainingconfig', ('TestConfigurationPostgresLifecycle',)),),
        {'TF_CONFIGURATION_TEST_DATABASE_URL':'migrator', 'TF_CONFIGURATION_TEST_RUNTIME_URL':'runtime'}),
)


def test_events(raw, expected):
    """Only test metadata may leave the captured Go output; skips never mean success."""
    if not expected: raise RuntimeError('Explicit expected tests required')
    results = {}
    for line in raw.splitlines():
        try: event = json.loads(line)
        except (ValueError, TypeError): raise RuntimeError('Invalid Go test event output') from None
        if not isinstance(event, dict): raise RuntimeError('Invalid Go test event shape')
        test, action = event.get('Test'), event.get('Action')
        if test and action in ('pass', 'fail', 'skip'):
            if not isinstance(test,str) or test in results: raise RuntimeError('Invalid or duplicate test result')
            results[test] = action
    if any(results.get(name) != 'pass' for name in expected) or any(v != 'pass' for v in results.values()):
        raise RuntimeError('Expected SQL tests missing, failed or skipped; raw output withheld')
    return [{'test':name, 'result':action} for name,action in sorted(results.items())]



def failure_locations(raw):
    """Expose only source basename/line, never the assertion text or payload."""
    locations = set()
    for line in raw.splitlines():
        try: event = json.loads(line)
        except (ValueError, TypeError): continue
        output = event.get('Output') if isinstance(event,dict) else None
        if not isinstance(output,str): continue
        for item in output.splitlines():
            match = re.match(r'\s*([A-Za-z_][A-Za-z0-9_]*\.go):([1-9][0-9]{0,7}):',item)
            if match: locations.add((match[1],int(match[2])))
    return [{'file':file,'line':line} for file,line in sorted(locations)]


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
    if not re.fullmatch(r'trainforge_v1_(?:privacy|auth|catalog|food|nutrition|names|config)_test_[a-f0-9]{12}', name):
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
    credentials = {role:secrets.token_hex(32) for role in ('migrator','runtime')}
    for password in credentials.values(): print('::add-mask::'+password, flush=True)
    for role,password in credentials.items():
        sql("CREATE ROLE trainforge_"+role+" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD '"+password+"';")
    service = ROOT/'services/api'
    latest = max(int(p.name.split('_',1)[0]) for p in (service/'migrations').glob('*.sql'))
    report = {'scope':'fresh-github-service-only', 'commit':os.environ['GITHUB_SHA'],
        'schemaVersion':latest, 'suites':[], 'realGoogleOrHumanAcceptance':False}
    report_dir = Path(os.environ['RUNNER_TEMP'])/'sql-verification'
    report_dir.mkdir(exist_ok=True)
    try:
        for suite_id, prefix, commands, variables in SUITES:
            name = disposable_name('trainforge_v1_'+prefix+'_test_'+secrets.token_hex(6))
            item = {'suite':suite_id, 'status':'running', 'tests':[], 'databaseRemoved':False}
            report['suites'].append(item)
            suite_env = dict(env)  # Never retain another suite's TF_* connection variables.
            def dsn(role):
                return 'postgresql://trainforge_'+role+':'+credentials[role]+'@127.0.0.1:15432/'+name+'?sslmode=disable'
            created = False
            try:
                sql('CREATE DATABASE '+name+' OWNER trainforge_migrator;');created = True
                sql('REVOKE ALL ON DATABASE '+name+' FROM PUBLIC; GRANT CONNECT ON DATABASE '+name+' TO trainforge_runtime; REVOKE CREATE ON SCHEMA public FROM PUBLIC;',name)
                suite_env['TF_MIGRATION_DATABASE_URL'] = dsn('migrator')
                for _ in range(2):
                    subprocess.run([go,'run','./cmd/migrate'],cwd=service,env=suite_env,check=True,timeout=120)
                if sql('SELECT max(version_id) FROM public.trainforge_v1_schema_version WHERE is_applied;',name) != str(latest):
                    raise RuntimeError('Migration version mismatch')
                item['migrationRerunPassed'] = True
                for statement in runtime_statements(training=True,meals=True): sql(statement,name)
                for key,role in variables.items(): suite_env[key] = dsn(role)
                if suite_id == 'nutrition': suite_env['TF_NUTRITION_CI_FIXTURE'] = '1'
                for package, expected in commands:
                    pattern = '^('+'|'.join(expected)+')$'
                    result = subprocess.run([go,'test',package,'-run',pattern,'-count=1','-json','-timeout=90s'],
                        cwd=service,env=suite_env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
                    if result.returncode:
                        item['failureLocations'] = failure_locations(result.stdout)
                        print(json.dumps({'suite':suite_id, 'status':'failed', 'failureLocations':item['failureLocations']}),flush=True)
                        raise RuntimeError('SQL suite failed: '+suite_id+'; raw output withheld')
                    events = test_events(result.stdout,expected)
                    item['tests'].extend(events)
                    for event in events: print(json.dumps(dict(suite=suite_id,**event)), flush=True)
                item['status'] = 'passed'
            finally:
                if created:
                    sql('DROP DATABASE '+disposable_name(name)+';')
                    item['databaseRemoved'] = True
                if item['status'] == 'running': item['status'] = 'failed'
    finally:
        (report_dir/'safe-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'scope':'fresh-github-service-only', 'suitesPassed':len(report['suites']),
        'migrationsAppliedPerDatabase':latest, 'disposableDatabasesRemoved':True,
        'realGoogleOrHumanAcceptance':False}))


if __name__ == '__main__':
    try: main()
    except (RuntimeError,OSError,subprocess.SubprocessError) as error:
        # Do not stringify CalledProcessError: its env/command may change in future.
        print('SQL CI failed: '+(str(error) if isinstance(error,RuntimeError) else 'bounded process failure'),file=sys.stderr)
        raise SystemExit(1)
