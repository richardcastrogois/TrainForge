"""Activation guards use synthetic metadata only; no PostgreSQL process is started."""
from contextlib import ExitStack
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

import ativar_alimentacao_offline_local as activation


def fixture_receipt():
    return {'contract': 'trainforge.offline-nutrition-sql-verification/1', 'schemaTested': 16,
            'deliveredDatabase': 'trainforge_v1_dev', 'deliveredSchemaMigrated': False,
            'deliveredRecordsUnchanged': True, 'disposableDatabaseRemoved': True,
            'clusterRunningStatePreserved': True,
            'results': [{'package': package, 'tests': [{'test': name, 'result': 'pass'} for name in names]}
                        for package, names in activation.EXPECTED.items()]}


class OfflineActivationGuards(unittest.TestCase):
    def dsn(self, role='migrator', **changes):
        fields = {'host': '127.0.0.1', 'port': '15432', 'name': 'trainforge_v1_dev',
                  'role': role, 'query': 'sslmode=disable', **changes}
        return 'postgresql://trainforge_{role}:fixture-password@{host}:{port}/{name}?{query}'.format(**fields)

    def test_exact_local_destination_and_role_are_required(self):
        for role in ['migrator', 'runtime']:
            self.assertEqual(activation.target(self.dsn(role), role), self.dsn(role))
        for dsn in [self.dsn(host='localhost'), self.dsn(host='example.invalid'), self.dsn(port='5432'),
                    self.dsn(name='postgres'), self.dsn(role='owner'), self.dsn(query=''),
                    self.dsn(query='sslmode=disable&host=example.invalid'),
                    self.dsn(query='sslmode=disable&sslmode=prefer'), self.dsn() + '#fragment']:
            with self.subTest(dsn=dsn), self.assertRaises(RuntimeError):
                activation.target(dsn, 'migrator')

    def test_disposable_success_requires_all_expected_test_results(self):
        activation.validate_sql_receipt(fixture_receipt())
        for change in [{'schemaTested': True}, {'schemaTested': 13}, {'deliveredRecordsUnchanged': False},
                       {'disposableDatabaseRemoved': False}, {'results': []}, {'results': [None]}]:
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                activation.validate_sql_receipt({**fixture_receipt(), **change})
        receipt = fixture_receipt()
        receipt['results'][0]['tests'][0]['result'] = 'skip'
        with self.assertRaises(RuntimeError):
            activation.validate_sql_receipt(receipt)

    def test_every_preexisting_data_table_is_compared_and_only_new_tables_may_appear(self):
        before = {activation.HISTORY: 'old-schema', 'trainforge_v1.users': 'opaque-users',
                  'public.extra_existing_table': 'opaque-extra'}
        after = {**before, activation.HISTORY: 'new-schema', **{name: 'empty' for name in activation.NEW_TABLES}}
        digest, count = activation.compare_existing(before, after)
        self.assertEqual(count, 2)
        self.assertEqual(len(digest), 64)
        for changed in [{**after, 'trainforge_v1.users': 'changed'},
                        {**after, 'public.extra_existing_table': None}, {**after, 'public.unreviewed': 'empty'}]:
            with self.assertRaises(RuntimeError):
                activation.compare_existing(before, changed)

    def test_running_api_blocks_before_any_database_query(self):
        with patch.object(activation, 'port_occupied', return_value=True), patch.object(activation, 'sql') as sql:
            with self.assertRaisesRegex(RuntimeError, 'API8082'):
                activation.ensure_idle()
            sql.assert_not_called()

    def test_command_failure_does_not_echo_credentials_or_process_output(self):
        secret = 'synthetic-private-command-output'
        with patch.object(activation.subprocess, 'run', return_value=SimpleNamespace(returncode=1, stdout=secret, stderr=secret)):
            with self.assertRaises(RuntimeError) as caught:
                activation.checked(['fixture'], {'TF_MIGRATION_DATABASE_URL': secret})
        self.assertNotIn(secret, str(caught.exception))

    def test_wrong_schema_never_dumps_or_migrates_and_restores_cluster_running_state(self):
        for was_running in [False, True]:
            with self.subTest(was_running=was_running), tempfile.TemporaryDirectory() as temporary, ExitStack() as stack:
                root = Path(temporary)
                receipt = root / 'sql.json'
                receipt.write_text(json.dumps(fixture_receipt()), encoding='utf-8')
                stack.enter_context(patch.object(activation, 'SQL_RECEIPT', receipt))
                stack.enter_context(patch.object(activation, 'RECEIPT', root / 'not-created.json'))
                stack.enter_context(patch.object(activation, 'verify_owned', return_value={'port': 15432, 'database': activation.NAME}))
                stack.enter_context(patch.object(activation, 'load_env', return_value={
                    'TF_MIGRATION_DATABASE_URL': self.dsn(), 'TF_DATABASE_URL': self.dsn('runtime')}))
                stack.enter_context(patch.object(activation, 'port_occupied', return_value=False))
                stack.enter_context(patch.object(activation, 'sql', side_effect=lambda query, db: str(activation.DATA) if 'data_directory' in query else '0'))
                stack.enter_context(patch.object(activation, 'applied_versions', return_value=list(range(1, 13))))
                status = stack.enter_context(patch.object(activation, 'run', side_effect=['running', 'running'] if was_running else [RuntimeError('stopped'), 'running', 'stopped']))
                start = stack.enter_context(patch.object(activation, 'start'))
                snapshot = stack.enter_context(patch.object(activation, 'snapshot'))
                migrate = stack.enter_context(patch.object(activation, 'checked'))
                with self.assertRaisesRegex(RuntimeError, 'schema13'):
                    activation.activate(True)
                start.assert_called_once()
                snapshot.assert_not_called()
                migrate.assert_not_called()
                self.assertTrue(all(call.args[0] == 'pg_ctl' for call in status.call_args_list))
                stops = [call for call in status.call_args_list if call.args[1][-1] == 'stop']
                self.assertEqual(len(stops), 0 if was_running else 1)
