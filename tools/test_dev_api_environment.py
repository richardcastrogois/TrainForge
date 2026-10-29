import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import dev_api

class SdkEnvironmentBoundary(unittest.TestCase):
 def fixture(self,root):
  binary=root/'.tools/go/bin/go.exe';binary.parent.mkdir(parents=True);binary.touch()
  local=root/'.local';local.mkdir()
  return local,binary
 def test_sdk_only_never_reads_api_file_or_inherits_connection_values(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);local,binary=self.fixture(root)
   (local/'api.env').write_text('TF_DATABASE_URL=fixture-file-must-not-be-read',encoding='utf-8')
   with mock.patch.multiple(dev_api,ROOT=root,LOCAL=local),mock.patch.dict(os.environ,{'PATH':'fixture-path','TF_DATABASE_URL':'fixture-inherited','PGPASSWORD':'fixture-inherited'},clear=True),mock.patch.object(Path,'read_text',side_effect=AssertionError('SDK mode must not read files')):
    env,go=dev_api.environment(include_api_env=False)
   self.assertEqual(go,binary)
   self.assertFalse(any(key.startswith(('TF_','PG')) for key in env))
   self.assertEqual(env['GOTOOLCHAIN'],'local')
 def test_api_watcher_default_keeps_explicit_environment_precedence(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);local,_=self.fixture(root)
   (local/'api.env').write_text('TF_DATABASE_URL=fixture-file\nTF_ENV=test\nTF_FIXTURE=file-value\n',encoding='utf-8')
   with mock.patch.multiple(dev_api,ROOT=root,LOCAL=local),mock.patch.dict(os.environ,{'PATH':'fixture-path','TF_FIXTURE':'explicit-value'},clear=True):
    env,_=dev_api.environment()
   self.assertEqual(env['TF_DATABASE_URL'],'fixture-file')
   self.assertEqual(env['TF_FIXTURE'],'explicit-value')
   self.assertEqual(env['TF_ENV'],'development')
