from pathlib import Path
import json
import tempfile
import unittest
from catalog_m1_ci import check_environment,disposable_name,runtime_dependencies

class CatalogM1Boundaries(unittest.TestCase):
 def test_explicit_hosted_fixture_only(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);env=dict(CI='true',GITHUB_ACTIONS='true',RUNNER_ENVIRONMENT='github-hosted',TF_CATALOG_M1_CI='1',TF_CI_PG_PASSWORD='disposable-service-only',GITHUB_WORKSPACE=str(root))
   check_environment(env,root,'linux')
   for key in ['TF_CATALOG_M1_CI','CI','GITHUB_ACTIONS','RUNNER_ENVIRONMENT','GITHUB_WORKSPACE']:
    invalid=dict(env);invalid.pop(key)
    with self.subTest(key=key),self.assertRaises(RuntimeError):check_environment(invalid,root,'linux')
   with self.assertRaises(RuntimeError):check_environment(env,root,'win32')
   (root/'.local').mkdir();(root/'.local/api.env').write_text('fixture')
   with self.assertRaises(RuntimeError):check_environment(env,root,'linux')
 def test_cleanup_refuses_real_database_and_injection(self):
  for good in ['trainforge_catalog_test_012345abcdef','trainforge_v1_private_test_012345abcdef']:disposable_name(good)
  for bad in ['trainforge_v1_dev','postgres','trainforge_catalog_test_012345abcdef; DROP DATABASE postgres','trainforge_catalog_test_../data']:
   with self.subTest(target=bad),self.assertRaises(RuntimeError):disposable_name(bad)
 def test_runtime_cannot_import_other_domains_or_the_migrator(self):
  def package(name):return json.dumps({'ImportPath':'trainforge.local/api/'+name}).encode()
  main=package('cmd/catalog')
  self.assertEqual(runtime_dependencies(main),['trainforge.local/api/cmd/catalog'])
  for name in ['internal/auth','internal/nutrition','internal/privacy','internal/trainingconfig','internal/catalogschema','migrations']:
   with self.subTest(name=name),self.assertRaises(RuntimeError):runtime_dependencies(main+b'\n'+package(name))
