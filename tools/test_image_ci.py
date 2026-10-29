import tempfile
from pathlib import Path
import unittest
from image_ci import check_environment,resource_name

class ImageBoundaries(unittest.TestCase):
 def test_desktop_and_external_daemon_are_refused(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory)
   env=dict(CI='true',GITHUB_ACTIONS='true',RUNNER_ENVIRONMENT='github-hosted',TF_IMAGE_CI='1',GITHUB_SHA='a'*40,GITHUB_WORKSPACE=str(root))
   check_environment(env,root,'linux')
   with self.assertRaises(RuntimeError):check_environment(env,root,'win32')
   for key in ['DOCKER_HOST','DOCKER_CONTEXT','TF_DATABASE_URL','TF_MIGRATION_DATABASE_URL','DATABASE_URL']:
    with self.subTest(key=key),self.assertRaises(RuntimeError):check_environment(dict(env,**{key:'refused'}),root,'linux')
   for key in ['CI','GITHUB_ACTIONS','RUNNER_ENVIRONMENT','TF_IMAGE_CI','GITHUB_SHA','GITHUB_WORKSPACE']:
    invalid=dict(env);invalid.pop(key)
    with self.subTest(key=key),self.assertRaises(RuntimeError):check_environment(invalid,root,'linux')
 def test_cleanup_never_accepts_unrelated_resource_names(self):
  resource_name('trainforge-ci-image-012345abcdef')
  for name in ['trainforge','trainforge_v1_dev','docker','trainforge-ci-image-../../all','trainforge-ci-image-012345abcdef --all']:
   with self.subTest(name=name),self.assertRaises(RuntimeError):resource_name(name)
