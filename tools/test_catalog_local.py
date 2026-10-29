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
