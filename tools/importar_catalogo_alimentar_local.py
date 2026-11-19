"""Stage and activate the exact signed food catalog in the owned local database.

Additive only: a fresh checkpoint is taken first, every pre-existing row of every
table must survive unchanged, and the cluster running state is restored. The Go
stage commits bounded batches, so an interrupted run resumes without duplicates.
"""
from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import tempfile
import time

from ativar_alimentacao_offline_local import applied_versions, digest, ensure_idle, file_digest, target
from db_local import DATA, LOCAL, NAME, PORT, load_env, owner_env, run, sql, start, verify_owned
from dev_api import ROOT, SERVICE, environment

RECEIPT = ROOT / 'docs/execucao/v1/food-catalog-local-import.json'
MANIFEST = ROOT / 'assets/food_catalog/manifest.json'
LOGS = LOCAL / 'food-catalog'
# Tables the importer may append to; every other table must be byte-identical.
ADDITIVE = ('trainforge_v1.sources', 'trainforge_v1.food_import_batches', 'trainforge_v1.food_catalog_releases',
            'trainforge_v1.food_catalog_import_progress', 'trainforge_v1.food_versions',
            'trainforge_v1.food_batch_versions', 'trainforge_v1.food_catalog_annotations')
MIN_START_FREE = 60 << 30
MIN_RUNNING_FREE = 10 << 30
_SHA = re.compile(r'[a-f0-9]{64}')
# Hashing millions of catalog rows exceeds db_local.sql's 35 s default.
LONG_SQL_SECONDS = 3600


def long_sql(statement, db=NAME):
    return run('psql', ['-X', '-q', '-v', 'ON_ERROR_STOP=1', '-h', '127.0.0.1', '-p', str(PORT), '-U', 'trainforge_owner',
                        '-d', db, '-t', '-A'], statement, owner_env(), timeout=LONG_SQL_SECONDS)


# Bookkeeping rows of the artifact being imported are updated in place while a
# resumable stage progresses; rows of every other artifact must stay identical.
PROGRESS = ('trainforge_v1.food_catalog_releases', 'trainforge_v1.food_catalog_import_progress')


def row_hashes(relation, artifact, db=NAME):
    where = " WHERE v.artifact_sha<>'" + artifact + "'" if relation in PROGRESS else ''
    raw = long_sql("SELECT coalesce(json_agg(h ORDER BY h),'[]'::json)::text FROM "
              "(SELECT md5(row_to_json(v)::text) h FROM " + relation + " v" + where + ") s;", db)
    return json.loads(raw)


def surviving(relation, hashes):
    if not hashes:
        return 0
    if any(not re.fullmatch(r'[a-f0-9]{32}', h) for h in hashes):
        raise RuntimeError('Unexpected row digest')
    literal = json.dumps(hashes)
    return int(long_sql("SELECT count(*) FROM " + relation + " v WHERE md5(row_to_json(v)::text) IN "
                   "(SELECT json_array_elements_text('" + literal + "'::json));", NAME))


def stage_and_activate(binary, env, artifact, exports, stamp):
    results = {}
    for operation in ('stage', 'activate'):
        out = LOGS / ('import-' + operation + '-' + stamp + '.log')
        err = LOGS / ('import-' + operation + '-' + stamp + '-errors.log')
        started = time.monotonic()
        with out.open('wb') as stdout, err.open('wb') as stderr:
            process = subprocess.Popen([str(binary), '--operation', operation, '--confirm', artifact,
                                        '--manifest', str(MANIFEST), '--trust', str(MANIFEST.with_name('trust.json')),
                                        '--exports', str(exports)], cwd=SERVICE, env=env, stdout=stdout, stderr=stderr)
            low = False
            while process.poll() is None:
                if shutil.disk_usage(LOCAL).free < MIN_RUNNING_FREE:
                    low = True
                    process.terminate()
                    process.wait(timeout=60)
                    break
                time.sleep(15)
        if low:
            raise RuntimeError('Free disk fell below 10 GiB; importer stopped. Committed batches resume on rerun.')
        if process.returncode:
            raise RuntimeError(operation + ' failed; see ' + err.relative_to(ROOT).as_posix())
        results[operation] = {'result': json.loads(out.read_text(encoding='utf-8')),
                              'seconds': round(time.monotonic() - started),
                              'log': out.relative_to(ROOT).as_posix()}
    return results


def import_catalog(apply=False):
    state = verify_owned()
    if NAME != 'trainforge_v1_dev' or state.get('database') != NAME or state.get('port') != 15432:
        raise RuntimeError('Unexpected owned local database registration')
    envelope = json.loads(MANIFEST.read_text(encoding='utf-8'))
    payload = json.loads(base64.b64decode(envelope['payload'], validate=True))
    artifact = payload['sha256']
    if not _SHA.fullmatch(artifact) or payload.get('complete') is not True or payload.get('fixture') is not False:
        raise RuntimeError('Signed complete catalog manifest required')
    exports = LOCAL / 'food-catalog/exports' / artifact
    if not (exports / 'manifest.json').is_file():
        raise RuntimeError('Archived exports for this artifact are missing')
    migrator = target(load_env(LOCAL / 'migrate.env')['TF_MIGRATION_DATABASE_URL'], 'migrator')
    if RECEIPT.exists():
        raise RuntimeError('Import receipt already exists; nothing overwritten')
    free = shutil.disk_usage(LOCAL).free
    if not apply:
        return {'scope': 'food-catalog-local-import-preview', 'artifactSha256': artifact,
                'rows': payload['counts']['foods'], 'diskFreeBytes': free, 'applied': False}
    if free < MIN_START_FREE:
        raise RuntimeError('At least 60 GiB free required before importing the global catalog')
    try:
        run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
        was_running = True
    except RuntimeError:
        was_running = False
    result = None
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    try:
        start()
        if Path(sql("SELECT current_setting('data_directory');", NAME)).resolve() != DATA.resolve():
            raise RuntimeError('Connected PostgreSQL data directory differs from owned cluster')
        ensure_idle()
        if applied_versions() != list(range(1, 17)):
            raise RuntimeError('Expected exactly schema16')
        before = snapshot_except(ADDITIVE)
        if not set(ADDITIVE) <= set(tables()):
            raise RuntimeError('Expected catalog tables are missing')
        kept = {relation: row_hashes(relation, artifact) for relation in ADDITIVE}
        resumed = int(sql("SELECT coalesce(sum(imported_rows),0) FROM trainforge_v1.food_catalog_import_progress "
                          "WHERE artifact_sha='" + artifact + "';", NAME))
        size_before = int(sql("SELECT pg_database_size('trainforge_v1_dev');", NAME))
        checkpoint_directory = LOCAL / 'checkpoints' / ('food-catalog-before-import-' + stamp + '-' + secrets.token_hex(4))
        checkpoint_directory.mkdir(mode=0o700, parents=True, exist_ok=False)
        checkpoint = checkpoint_directory / 'database.dump'
        run('pg_dump', ['-h', '127.0.0.1', '-p', '15432', '-U', 'trainforge_owner', '-d', NAME,
                        '-Fc', '--file', checkpoint], env=owner_env(), timeout=300)
        if not checkpoint.is_file() or checkpoint.stat().st_size < 5 or not run('pg_restore', ['--list', checkpoint], timeout=60):
            raise RuntimeError('Checkpoint could not be verified; nothing imported')
        ensure_idle()
        env, go = environment(include_api_env=False)
        env['TF_FOOD_CATALOG_DATABASE_URL'] = migrator
        with tempfile.TemporaryDirectory(prefix='food-import-', dir=LOCAL) as temporary:
            binary = Path(temporary) / 'import-food-catalog.exe'
            built = subprocess.run([str(go), 'build', '-o', str(binary), './cmd/import-food-catalog'],
                                   cwd=SERVICE, env=env, capture_output=True, timeout=600)
            if built.returncode:
                raise RuntimeError('Importer build failed')
            operations = stage_and_activate(binary, env, artifact, exports, stamp)
        after = compare_preserved(before, kept)
        release = sql("SELECT status||'|'||staged_rows||'|'||expected_rows FROM trainforge_v1.food_catalog_releases "
                      "WHERE artifact_sha='" + artifact + "';", NAME)
        linked = int(sql("SELECT count(*) FROM trainforge_v1.food_batch_versions WHERE artifact_sha='" + artifact + "';", NAME))
        expected = payload['counts']['foods']
        if release != 'active|%d|%d' % (expected, expected) or linked != expected:
            raise RuntimeError('Active release does not match the signed row count')
        result = {'contract': 'trainforge.food-catalog-local-import/1', 'importedAt': datetime.now(timezone.utc).isoformat(),
                  'artifactSha256': artifact, 'catalogVersion': payload['version'], 'rows': expected,
                  'linkedVersions': linked, 'releaseStatus': 'active', 'operations': operations,
                  'resumedFromRows': resumed,
                  'nonCatalogTablesCompared': len(after), 'nonCatalogTablesUnchanged': True,
                  'preexistingCatalogRowsKept': {name: len(hashes) for name, hashes in kept.items()},
                  'snapshotBeforeSha256': digest(before), 'databaseBytesBefore': size_before,
                  'databaseBytesAfter': int(sql("SELECT pg_database_size('trainforge_v1_dev');", NAME)),
                  'checkpointRelativePath': checkpoint.relative_to(ROOT).as_posix(),
                  'checkpointSha256': file_digest(checkpoint), 'checkpointBytes': checkpoint.stat().st_size,
                  'exportsRelativePath': exports.relative_to(ROOT).as_posix(), 'postgresWasRunning': was_running,
                  'apiRemainedStopped': True,
                  'limits': ['Checkpoint inspected with pg_restore --list, not restored.',
                             'Import does not establish native, sync or human acceptance.']}
        ensure_idle()
    finally:
        if not was_running:
            verify_owned()
            try:
                run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
            except RuntimeError:
                pass
            else:
                run('pg_ctl', ['-D', DATA, '-m', 'fast', '-w', '-t', '60', 'stop'], timeout=70)
    result['clusterRunningStatePreserved'] = True
    with RECEIPT.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(result, indent=2) + '\n')
    return result


def verify_from_checkpoint(checkpoint):
    """Finish the evidence of a run whose stage/activate succeeded but whose final
    comparison could not complete: the pre-import checkpoint is restored into a
    disposable database (dropped afterwards) and compared with the delivered one."""
    checkpoint = Path(checkpoint).resolve()
    directory = checkpoint.parent
    match = re.fullmatch(r'food-catalog-before-import-(\d{8}T\d{6}Z)-[a-f0-9]{8}', directory.name)
    if checkpoint.name != 'database.dump' or directory.parent != (LOCAL / 'checkpoints').resolve() or not match:
        raise RuntimeError('Expected a food-catalog-before-import checkpoint under .local/checkpoints')
    stamp = match.group(1)
    state = verify_owned()
    if NAME != 'trainforge_v1_dev' or state.get('database') != NAME or state.get('port') != 15432:
        raise RuntimeError('Unexpected owned local database registration')
    payload = json.loads(base64.b64decode(json.loads(MANIFEST.read_text(encoding='utf-8'))['payload'], validate=True))
    artifact, expected = payload['sha256'], payload['counts']['foods']
    exports = LOCAL / 'food-catalog/exports' / artifact
    if RECEIPT.exists():
        raise RuntimeError('Import receipt already exists; nothing overwritten')
    operations = {}
    for operation in ('stage', 'activate'):
        log = LOGS / ('import-' + operation + '-' + stamp + '.log')
        errors = LOGS / ('import-' + operation + '-' + stamp + '-errors.log')
        if errors.stat().st_size:
            raise RuntimeError(operation + ' logged errors; evidence refused')
        info = log.stat()
        operations[operation] = {'result': json.loads(log.read_text(encoding='utf-8')),
                                 'secondsFromLogFileTimes': round(info.st_mtime - getattr(info, 'st_birthtime', info.st_ctime)),
                                 'log': log.relative_to(ROOT).as_posix()}
    if not operations['activate']['result'].get('active'):
        raise RuntimeError('Activation log does not report an active release')
    try:
        run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
        was_running = True
    except RuntimeError:
        was_running = False
    check = 'trainforge_v1_importcheck_' + secrets.token_hex(4)
    created = False
    try:
        start()
        if Path(sql("SELECT current_setting('data_directory');", NAME)).resolve() != DATA.resolve():
            raise RuntimeError('Connected PostgreSQL data directory differs from owned cluster')
        ensure_idle()
        if applied_versions() != list(range(1, 17)):
            raise RuntimeError('Expected exactly schema16')
        sql('CREATE DATABASE ' + check + ';', 'postgres')
        created = True
        run('pg_restore', ['-h', '127.0.0.1', '-p', str(PORT), '-U', 'trainforge_owner', '-d', check, '--no-owner',
                           '--no-privileges', '--exit-on-error', checkpoint], env=owner_env(), timeout=1800)
        before = snapshot_except(ADDITIVE, check)
        if not set(ADDITIVE) <= set(tables(check)):
            raise RuntimeError('Expected catalog tables are missing from the checkpoint')
        kept = {relation: row_hashes(relation, artifact, check) for relation in ADDITIVE}
        resumed = int(sql("SELECT coalesce(sum(imported_rows),0) FROM trainforge_v1.food_catalog_import_progress "
                          "WHERE artifact_sha='" + artifact + "';", check))
        restored_bytes = int(sql("SELECT pg_database_size('" + check + "');", check))
        ensure_idle()
        after = compare_preserved(before, kept)
        release = sql("SELECT status||'|'||staged_rows||'|'||expected_rows FROM trainforge_v1.food_catalog_releases "
                      "WHERE artifact_sha='" + artifact + "';", NAME)
        linked = int(sql("SELECT count(*) FROM trainforge_v1.food_batch_versions WHERE artifact_sha='" + artifact + "';", NAME))
        if release != 'active|%d|%d' % (expected, expected) or linked != expected:
            raise RuntimeError('Active release does not match the signed row count')
        activated = (LOGS / ('import-activate-' + stamp + '.log')).stat().st_mtime
        result = {'contract': 'trainforge.food-catalog-local-import/1',
                  'importedAt': datetime.fromtimestamp(activated, timezone.utc).isoformat(),
                  'verifiedAt': datetime.now(timezone.utc).isoformat(),
                  'artifactSha256': artifact, 'catalogVersion': payload['version'], 'rows': expected,
                  'linkedVersions': linked, 'releaseStatus': 'active', 'operations': operations,
                  'resumedFromRows': resumed,
                  'nonCatalogTablesCompared': len(after), 'nonCatalogTablesUnchanged': True,
                  'preexistingCatalogRowsKept': {name: len(hashes) for name, hashes in kept.items()},
                  'snapshotBeforeSha256': digest(before), 'checkpointRestoredDatabaseBytes': restored_bytes,
                  'databaseBytesAfter': int(sql("SELECT pg_database_size('trainforge_v1_dev');", NAME)),
                  'checkpointRelativePath': checkpoint.relative_to(ROOT).as_posix(),
                  'checkpointSha256': file_digest(checkpoint), 'checkpointBytes': checkpoint.stat().st_size,
                  'exportsRelativePath': exports.relative_to(ROOT).as_posix(), 'apiRemainedStopped': True,
                  'verification': 'The original run staged and activated, then its final comparison hit the 35 s psql '
                                  'timeout; the preservation comparison was completed from the pre-import checkpoint '
                                  'restored into a disposable database that was dropped afterwards.',
                  'limits': ['Checkpoint restored only into a disposable database, never over the delivered one.',
                             'Import does not establish native, sync or human acceptance.']}
        ensure_idle()
    finally:
        if created:
            sql('DROP DATABASE IF EXISTS ' + check + ';', 'postgres')
        if not was_running:
            verify_owned()
            try:
                run('pg_ctl', ['-D', DATA, 'status'], timeout=5)
            except RuntimeError:
                pass
            else:
                run('pg_ctl', ['-D', DATA, '-m', 'fast', '-w', '-t', '60', 'stop'], timeout=70)
    result['postgresWasRunning'] = was_running
    result['clusterRunningStatePreserved'] = True
    result['disposableDatabaseDropped'] = True
    with RECEIPT.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(result, indent=2) + '\n')
    return result


def compare_preserved(before, kept):
    after = snapshot_except(ADDITIVE)
    changed = sorted(name for name, value in before.items() if after.get(name) != value)
    if changed or set(after) != set(before):
        raise RuntimeError('Non-catalog tables changed: ' + ', '.join(changed))
    for relation, hashes in kept.items():
        if surviving(relation, hashes) != len(hashes):
            raise RuntimeError('A pre-existing row changed in ' + relation)
    return after


def tables(db=NAME):
    raw = sql("SELECT coalesce(json_agg(schemaname||'.'||tablename ORDER BY schemaname,tablename),'[]'::json)::text "
              "FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') AND schemaname NOT LIKE 'pg_%';", db)
    return json.loads(raw)


def snapshot_except(excluded, db=NAME):
    """Per-table row digest (same SQL as verificar_atividade_local.snapshot) without the catalog tables."""
    result = {}
    for name in tables(db):
        if name in excluded:
            continue
        if not re.fullmatch(r'[a-z_][a-z0-9_]*\.[a-z_][a-z0-9_]*', name):
            raise RuntimeError('Unexpected table identifier; snapshot refused')
        schema, table = name.split('.')
        result[name] = long_sql("SELECT coalesce(md5(string_agg(row_to_json(v)::text,'' ORDER BY row_to_json(v)::text)),'empty') "
                                'FROM "' + schema + '"."' + table + '" v;', db)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--verify-from-checkpoint', metavar='DUMP',
                        help='complete the receipt of a finished stage/activate from its pre-import checkpoint')
    args = parser.parse_args()
    try:
        result = (verify_from_checkpoint(args.verify_from_checkpoint) if args.verify_from_checkpoint
                  else import_catalog(args.apply))
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        if isinstance(error, RuntimeError):
            parser.exit(1, str(error) + '\n')
        parser.exit(1, 'Local catalog import failed; private configuration and process output withheld.\n')
    print(json.dumps(result))


if __name__ == '__main__':
    main()
