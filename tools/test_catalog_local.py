from pathlib import Path
import json
import tempfile
import unittest
from unittest import mock
import catalog_local
class LocalCatalogBoundary(unittest.TestCase):
 def test_other_workspace_or_database_cannot_be_adopted(self):
  with tempfile.TemporaryDirectory() as folder:
   path=Path(folder)/'state.json'
   for value in [{'root':'other','database':catalog_local.CATALOG},{'root':str(catalog_local.ROOT),'database':'trainforge_v1_dev'}]:
    path.write_text(json.dumps(value))
    with mock.patch.object(catalog_local,'STATE',path),self.assertRaises(RuntimeError):catalog_local.owned_state()
 def test_invalid_mode_does_not_read_credentials_or_touch_database(self):
  with mock.patch.object(catalog_local,'settings',side_effect=AssertionError('must not read secrets')):
   with self.assertRaises(RuntimeError):catalog_local.select_mode('fallback')
 def test_snapshot_refuses_unreviewed_inventory_before_rows(self):
  with mock.patch.object(catalog_local,'sql',return_value='users;unsafe') as sql:
   with self.assertRaises(RuntimeError):catalog_local.snapshot('fixture')
   self.assertEqual(sql.call_count,1)

 def test_long_running_reader_opens_only_its_reader_file(self):
  values={'TF_CATALOG_MODE':'local','TF_CATALOG_DATABASE_URL':'fixture-reader-only'}
  with mock.patch.object(catalog_local,'environment',return_value=({'UNRELATED_SECRET':'synthetic-only'},Path('fixture-go'))) as sdk,mock.patch.object(catalog_local,'load_env',return_value=values) as load:
   env=catalog_local.reader_settings()
  sdk.assert_called_once_with(include_api_env=False);load.assert_called_once_with(catalog_local.DIRECTORY/'reader.env')
  self.assertEqual(set(env),set(values));self.assertNotIn('TF_CATALOG_CORE_DATABASE_URL',env)
 def test_reader_file_cannot_include_writer_or_core_connection(self):
  values={'TF_CATALOG_MODE':'local','TF_CATALOG_DATABASE_URL':'fixture-reader-only','TF_CATALOG_MIGRATION_DATABASE_URL':'fixture-must-not-reach-reader'}
  with mock.patch.object(catalog_local,'environment',return_value=({},Path('fixture-go'))),mock.patch.object(catalog_local,'load_env',return_value=values):
   with self.assertRaises(RuntimeError):catalog_local.reader_settings()
