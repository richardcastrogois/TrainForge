import tempfile
from pathlib import Path
import unittest
from sql_ci import check_environment, disposable_name


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
