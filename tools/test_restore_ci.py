from pathlib import Path
import tempfile
import unittest
from restore_ci import check_environment,disposable_name

class RestoreCiBoundaries(unittest.TestCase):
 def test_refuses_local_or_foreign_service(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);env=dict(CI='true',GITHUB_ACTIONS='true',RUNNER_ENVIRONMENT='github-hosted',TF_RESTORE_CI='1',TF_RESTORE_PG_CONTAINER='a'*64,TF_CI_PG_PASSWORD='disposable-service-only',GITHUB_WORKSPACE=str(root))
   check_environment(env,root,'linux')
   with self.assertRaises(RuntimeError):check_environment(env,root,'win32')
   for key in ['TF_RESTORE_CI','TF_RESTORE_PG_CONTAINER','GITHUB_WORKSPACE','RUNNER_ENVIRONMENT']:
    bad=dict(env);bad.pop(key)
    with self.subTest(key=key),self.assertRaises(RuntimeError):check_environment(bad,root,'linux')
   for value in ['postgres','--privileged','a'*64+';echo secret']:
    with self.subTest(value=value),self.assertRaises(RuntimeError):check_environment(dict(env,TF_RESTORE_PG_CONTAINER=value),root,'linux')
   with self.assertRaises(RuntimeError):check_environment(dict(env,DOCKER_HOST='refused'),root,'linux')
   (root/'.local').mkdir();(root/'.local/migrate.env').write_text('fixture')
   with self.assertRaises(RuntimeError):check_environment(env,root,'linux')
 def test_cleanup_accepts_only_exact_created_fixture_prefixes(self):
  for name in ['trainforge_v1_privacy_test_012345abcdef','trainforge_v1_privacy_restore_012345abcdef']:disposable_name(name)
  for name in ['trainforge_v1_dev','postgres','trainforge_v1_privacy_restore_../data','trainforge_v1_privacy_test_012345abcdef;DROP DATABASE postgres']:
   with self.subTest(name=name),self.assertRaises(RuntimeError):disposable_name(name)
