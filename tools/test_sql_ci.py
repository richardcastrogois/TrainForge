import tempfile
from pathlib import Path
import unittest
import json
import re
from sql_ci import check_environment, disposable_name, test_events, failure_locations, SUITES


class SqlCiGuards(unittest.TestCase):
    def fixture(self,root):
        return dict(CI='true',GITHUB_ACTIONS='true',RUNNER_ENVIRONMENT='github-hosted',
                    TF_SQL_CI='1',TF_CI_PG_PASSWORD='disposable-fixture-only',GITHUB_WORKSPACE=str(root))

    def test_refuses_desktop_self_hosted_or_implicit_execution(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);env=self.fixture(root)
            check_environment(env,root=root,platform='linux')
            for key in ['CI','GITHUB_ACTIONS','RUNNER_ENVIRONMENT','TF_SQL_CI','GITHUB_WORKSPACE','TF_CI_PG_PASSWORD']:
                invalid=dict(env);invalid.pop(key)
                with self.subTest(key=key),self.assertRaises(RuntimeError):
                    check_environment(invalid,root=root,platform='linux')
            with self.assertRaises(RuntimeError):check_environment(env,root=root,platform='win32')

    def test_rejects_existing_connections_and_evaluation_state(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);env=self.fixture(root)
            for key in ['TF_DATABASE_URL','TF_MIGRATION_DATABASE_URL','DATABASE_URL','PGSERVICE']:
                with self.subTest(key=key),self.assertRaises(RuntimeError):
                    check_environment(dict(env,**{key:'do-not-connect'}),root=root,platform='linux')
            (root/'.local').mkdir();(root/'.local/api.env').write_text('fixture')
            with self.assertRaises(RuntimeError):check_environment(env,root=root,platform='linux')

    def test_drop_target_cannot_be_real_or_injected(self):
        for target in ['trainforge_v1_dev','postgres','trainforge_v1_privacy_test_000000000000; DROP DATABASE postgres','trainforge_v1_privacy_test_../dev']:
            with self.subTest(target=target),self.assertRaises(RuntimeError):disposable_name(target)
        self.assertEqual(disposable_name('trainforge_v1_privacy_test_012345abcdef'),'trainforge_v1_privacy_test_012345abcdef')


class SqlTestEvidence(unittest.TestCase):
    def event(self,name,action='pass'):
        return json.dumps({'Action':action,'Test':name,'Output':'sensitive-output-must-not-publish'})

    def test_missing_skipped_failed_or_bad_evidence_is_rejected(self):
        for raw in ['', self.event('Other'), self.event('Expected','skip'),
                    self.event('Expected','fail'), 'raw secret', '[]',
                    self.event('Expected')+'\n'+self.event('Expected/child','skip'),
                    self.event('Expected','fail')+'\n'+self.event('Expected')]:
            with self.subTest(raw=raw),self.assertRaises(RuntimeError): test_events(raw,['Expected'])
        result=test_events(self.event('Expected')+'\n'+self.event('Expected/child'),['Expected'])
        self.assertEqual(result,[{'test':'Expected','result':'pass'},{'test':'Expected/child','result':'pass'}])
        self.assertNotIn('sensitive-output',str(result))

    def test_every_suite_uses_an_allowlisted_disposable_database_and_explicit_test(self):
        self.assertEqual(len(SUITES),8)
        self.assertEqual(len({s[0] for s in SUITES}),8)
        for _,prefix,commands,variables in SUITES:
            disposable_name('trainforge_v1_'+prefix+'_test_012345abcdef')
            self.assertTrue(commands)
            self.assertTrue(variables)
            self.assertTrue(all(role in ('runtime','migrator') for role in variables.values()))
            for package,expected in commands:
                self.assertTrue(package.startswith('./internal/'))
                self.assertTrue(expected)
                self.assertTrue(all(name.startswith('Test') for name in expected))
                directory=Path(__file__).resolve().parents[1]/'services/api'/package.removeprefix('./')
                declared={name for source in directory.glob('*_test.go') for name in re.findall(r'func (Test[A-Za-z0-9_]+)\(',source.read_text(encoding='utf-8'))}
                self.assertTrue(set(expected)<=declared,'Selected SQL test name is missing from its package')


    def test_failure_diagnostics_do_not_publish_assertion_or_payload(self):
        raw=json.dumps({'Output':'    entries_postgres_test.go:129: private-person token=fixture-secret\n'})
        self.assertEqual(failure_locations(raw),[{'file':'entries_postgres_test.go','line':129}])
        self.assertEqual(failure_locations('not JSON\n[]\n{}'),[])
        self.assertNotIn('private-person',str(failure_locations(raw)))
