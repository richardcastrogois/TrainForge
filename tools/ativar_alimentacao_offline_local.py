"""Activate only schema 13 -> 16 in the owned local database, preserving all data."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import secrets
import shutil
import subprocess
import tempfile
from urllib.parse import parse_qsl, urlsplit

from avaliar_android import port_occupied
from db_local import DATA, LOCAL, NAME, PORT, grant_runtime, load_env, owner_env, run, sql, start, verify_owned
from dev_api import ROOT, SERVICE, environment
from verificar_alimentacao_offline_local import EXPECTED
from verificar_atividade_local import snapshot

RECEIPT = ROOT / 'docs/execucao/v1/food-offline-local-activation.json'
SQL_RECEIPT = ROOT / 'docs/execucao/v1/offline-nutrition-sql-verification.json'
HISTORY = 'public.trainforge_v1_schema_version'
NEW_TABLES = frozenset('trainforge_v1.' + name for name in (
    'nutrition_sync_state', 'nutrition_changes', 'nutrition_operation_receipts',
    'food_contributions', 'food_contribution_media', 'food_catalog_releases',
    'food_catalog_import_progress', 'food_catalog_annotations'))
READINESS = '''package main
import (
 "context"
 "fmt"
 "os"
 "time"
 "github.com/jackc/pgx/v5/pgxpool"
 "trainforge.local/api/internal/platform/postgres"
)
func check() error {
 ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
 defer cancel()
 pool, err := pgxpool.New(ctx, os.Getenv("TF_DATABASE_URL"))
 if err != nil { return postgres.ErrNotReady }
 defer pool.Close()
 return (postgres.Readiness{Pool:pool}).Ping(ctx)
}
func main() {
 if check() != nil { fmt.Fprintln(os.Stderr,"Runtime readiness failed"); os.Exit(1) }
 fmt.Println("runtime_ready=true")
}
'''


def target(dsn, role):
    try:
        p = urlsplit(dsn)
        valid = (p.scheme in {'postgres', 'postgresql'} and p.hostname == '127.0.0.1'
                 and p.port == 15432 and p.path == '/trainforge_v1_dev'
                 and role in {'migrator', 'runtime'} and p.username == 'trainforge_' + role
                 and bool(p.password) and not p.fragment
                 and parse_qsl(p.query, keep_blank_values=True, strict_parsing=True) == [('sslmode', 'disable')])
    except (TypeError, ValueError):
        valid = False
    if not valid:
        raise RuntimeError('Unsafe local activation database target')
    return dsn


def validate_sql_receipt(receipt):
    required = {name for names in EXPECTED.values() for name in names}
    found = set()
    if (type(receipt) is not dict or receipt.get('contract') != 'trainforge.offline-nutrition-sql-verification/1'
            or type(receipt.get('schemaTested')) is not int or receipt['schemaTested'] != 16
            or receipt.get('deliveredDatabase') != NAME or receipt.get('deliveredSchemaMigrated') is not False
            or any(receipt.get(flag) is not True for flag in ('deliveredRecordsUnchanged',
                   'disposableDatabaseRemoved', 'clusterRunningStatePreserved'))):
        raise RuntimeError('Passing disposable schema16 receipt required')
    if type(receipt.get('results')) is not list:
        raise RuntimeError('Disposable SQL receipt has no test results')
    for package in receipt['results']:
        if type(package) is not dict or type(package.get('tests')) is not list:
            raise RuntimeError('Disposable SQL receipt has invalid test results')
        for test in package.get('tests', []):
            if type(test) is not dict or test.get('result') != 'pass' or type(test.get('test')) is not str:
                raise RuntimeError('Disposable SQL receipt contains a non-passing result')
            found.add(test.get('test'))
    if not required <= found:
        raise RuntimeError('Disposable SQL receipt is missing required tests')


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def file_digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def checked(command, env, timeout=120):
    result = subprocess.run(command, cwd=SERVICE, env=env, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError('Local activation command failed; raw output withheld')
    return result.stdout


def applied_versions():
    return json.loads(sql("SELECT coalesce(json_agg(version_id ORDER BY version_id),'[]'::json)::text "
                          "FROM public.trainforge_v1_schema_version WHERE is_applied AND version_id>0;", NAME))


def history_prefix():
    return sql("SELECT coalesce(md5(string_agg(row_to_json(v)::text,'' ORDER BY row_to_json(v)::text)),'empty') "
               "FROM public.trainforge_v1_schema_version v WHERE version_id<=13;", NAME)


def ensure_idle():
    if port_occupied():
        raise RuntimeError('API8082 must be stopped before local activation; no process was stopped')
    clients = sql("SELECT count(*) FROM pg_stat_activity WHERE datname='trainforge_v1_dev' "
                  "AND pid<>pg_backend_pid() AND backend_type='client backend';", NAME)
    if clients != '0':
        raise RuntimeError('Other clients are connected to the delivered database; activation refused')


def compare_existing(before, after):
    if HISTORY not in before or not before:
        raise RuntimeError('Missing pre-activation schema inventory')
    existing = {name: value for name, value in before.items() if name != HISTORY}
    preserved = {name: after.get(name) for name in existing}
    if preserved != existing or set(after) - set(before) != NEW_TABLES:
        raise RuntimeError('Delivered rows or expected table inventory changed; inspect checkpoint before any retry')
    return digest(existing), len(existing)


def activate(apply=False):
    state = verify_owned()
    if NAME != 'trainforge_v1_dev' or PORT != 15432 or state.get('port') != 15432 or state.get('database') != NAME:
        raise RuntimeError('Unexpected owned local database registration')
    migrations = sorted((SERVICE / 'migrations').glob('*.sql'))
    # 17 (legal consents) is reviewed too; the applied-count check below still
    # refuses to run this one-shot 13->16 transition on a different history.
    if [int(path.name.split('_', 1)[0]) for path in migrations] not in (list(range(1, 17)), list(range(1, 18))):
        raise RuntimeError('Only reviewed migrations through schema16 are accepted')
    validate_sql_receipt(json.loads(SQL_RECEIPT.read_text(encoding='utf-8')))
    migrator = target(load_env(LOCAL / 'migrate.env')['TF_MIGRATION_DATABASE_URL'], 'migrator')
    runtime = target(load_env(LOCAL / 'api.env')['TF_DATABASE_URL'], 'runtime')
    if RECEIPT.exists():
        raise RuntimeError('Activation receipt already exists; no migration or receipt overwrite performed')
    if port_occupied():
        raise RuntimeError('API8082 must be stopped before local activation; no process was stopped')
    if not apply:
        return {'scope': 'offline-food-schema-preview', 'schemaRequired': 13, 'schemaTarget': 16,
                'applied': False, 'dataSeeded': False, 'runtimePreconditionsChecked': False}
    try:
        run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
        was_running = True
    except RuntimeError:
        was_running = False
    result = None
    try:
        start()
        if Path(sql("SELECT current_setting('data_directory');", NAME)).resolve() != DATA.resolve():
            raise RuntimeError('Connected PostgreSQL data directory differs from owned cluster')
        ensure_idle()
        if applied_versions() != list(range(1, 14)):
            raise RuntimeError('Expected exactly schema13; inspect current state before activation')
        before = snapshot()
        prefix = history_prefix()
        database_bytes = int(sql("SELECT pg_database_size('trainforge_v1_dev');", NAME))
        if shutil.disk_usage(LOCAL).free < database_bytes + (128 << 20):
            raise RuntimeError('Insufficient free space for a new complete local checkpoint')
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        checkpoint_directory = LOCAL / 'checkpoints' / ('food-offline-before-16-' + stamp + '-' + secrets.token_hex(4))
        checkpoint_directory.mkdir(mode=0o700, parents=True, exist_ok=False)
        checkpoint = checkpoint_directory / 'database.dump'
        run('pg_dump', ['-h', '127.0.0.1', '-p', '15432', '-U', 'trainforge_owner', '-d', NAME,
                        '-Fc', '--file', checkpoint], env=owner_env(), timeout=120)
        if not checkpoint.is_file() or checkpoint.stat().st_size < 5 or not run('pg_restore', ['--list', checkpoint], timeout=30):
            raise RuntimeError('New complete checkpoint could not be verified; no migrations applied')
        checkpoint_sha = file_digest(checkpoint)
        ensure_idle()
        env, go = environment(include_api_env=False)
        env['TF_MIGRATION_DATABASE_URL'] = migrator
        if b'applied_migrations=3' not in checked([str(go), 'run', './cmd/migrate'], env).splitlines():
            raise RuntimeError('Unexpected applied migration count; inspect checkpoint before retrying')
        grant_runtime()
        after = snapshot()
        data_sha, existing_tables = compare_existing(before, after)
        if history_prefix() != prefix or applied_versions() != list(range(1, 17)):
            raise RuntimeError('Schema history differs from the reviewed13-to16 transition')
        for relation in sorted(NEW_TABLES):
            if sql('SELECT count(*) FROM ' + relation + ';', NAME) != '0':
                raise RuntimeError('New nutrition tables contain unexpected data; no seeding was authorized')
        env.pop('TF_MIGRATION_DATABASE_URL')
        env['TF_DATABASE_URL'] = runtime
        with tempfile.TemporaryDirectory(prefix='.food-readiness-', dir=SERVICE) as temporary:
            directory = Path(temporary).resolve()
            if not directory.is_relative_to(SERVICE.resolve()):
                raise RuntimeError('Temporary readiness runner escaped the service workspace')
            source = directory / 'main.go'
            source.write_text(READINESS, encoding='utf-8')
            if checked([str(go), 'run', str(source)], env).strip() != b'runtime_ready=true':
                raise RuntimeError('Runtime readiness was not confirmed')
        result = {'contract': 'trainforge.food-offline-local-activation/1',
                  'activatedAt': datetime.now(timezone.utc).isoformat(), 'schemaFrom': 13, 'schemaTo': 16,
                  'newTables': len(NEW_TABLES), 'preexistingDataTablesCompared': existing_tables,
                  'deliveredRowsUnchanged': True, 'preexistingDataSnapshotSha256': data_sha,
                  'fullSnapshotBeforeSha256': digest(before), 'fullSnapshotAfterSha256': digest(after),
                  'priorSchemaHistoryUnchanged': True, 'newTableRows': 0, 'runtimeGrantsApplied': True,
                  'runtimeReadinessVerified': True, 'apiRemainedStopped': not port_occupied(),
                  'fullCheckpointLocal': True, 'checkpointRelativePath': checkpoint.relative_to(ROOT).as_posix(),
                  'checkpointSha256': checkpoint_sha, 'checkpointBytes': checkpoint.stat().st_size,
                  'sqlVerificationReceiptSha256': file_digest(SQL_RECEIPT),
                  'migrationSha256': {path.name: file_digest(path) for path in migrations if int(path.name.split('_', 1)[0]) >= 14},
                  'dataSeeded': False, 'globalCatalogImported': False, 'postgresWasRunning': was_running,
                  'limits': ['The new local checkpoint was inspected with pg_restore --list, not restored.',
                             'Schema and readiness activation do not establish native or human acceptance.']}
        if not result['apiRemainedStopped']:
            raise RuntimeError('API started during activation; inspect state before continuing')
    finally:
        if not was_running:
            verify_owned()
            try:
                run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
            except RuntimeError:
                pass
            else:
                run('pg_ctl', ['-D', DATA, '-m', 'fast', '-w', '-t', '20', 'stop'], timeout=25)
        else:
            run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
    result['clusterRunningStatePreserved'] = True
    with RECEIPT.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(result, indent=2) + '\n')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    try:
        result = activate(args.apply)
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        if isinstance(error, RuntimeError):
            parser.exit(1, str(error) + '\n')
        parser.exit(1, 'Local nutrition activation failed; private configuration and process output withheld.\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
