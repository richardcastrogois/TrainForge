import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from food_catalog import sign_manifest
from food_catalog_publish import archive_exports


class PublicExportsTests(unittest.TestCase):
    def fixture(self, root):
        assets, exports = root / 'assets', root / 'exports'
        exports.mkdir()
        data = b'public-source-fixture\n'
        item = {'file': 'AL-OFF.jsonl.gz', 'sourceId': 'AL-OFF', 'rows': 1,
                'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'license': 'ODbL 1.0'}
        (exports / item['file']).write_bytes(data)
        manifest = {'contract': 'trainforge.food-catalog/1', 'schemaVersion': 1,
                    'version': '1' * 64, 'sha256': '2' * 64, 'bytes': 100,
                    'file': 'catalog.sqlite', 'complete': True, 'fixture': False,
                    'missingSources': [], 'exports': [item]}
        sign_manifest(manifest, root / 'signing', assets)
        return assets, exports, manifest

    def test_preserves_only_public_exports_by_release_and_is_resumable(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            assets, exports, manifest = self.fixture(root)
            (exports / 'private.pem').write_text('fixture-secret')
            report = archive_exports(assets, exports, manifest['sha256'])
            destination = exports / manifest['sha256']
            self.assertEqual(report['moved'], 1)
            self.assertEqual(set(p.name for p in destination.iterdir()), {'AL-OFF.jsonl.gz', 'manifest.json'})
            self.assertTrue((exports / 'private.pem').exists())
            self.assertFalse((exports / 'AL-OFF.jsonl.gz').exists())
            self.assertEqual(archive_exports(assets, exports, manifest['sha256'])['moved'], 0)
            self.assertFalse(report['publishedToInternet'])

    def test_wrong_confirmation_and_corrupt_bytes_never_move_exports(self):
        with tempfile.TemporaryDirectory() as temp:
            assets, exports, manifest = self.fixture(Path(temp))
            with self.assertRaisesRegex(ValueError, 'confirmation'):
                archive_exports(assets, exports, '3' * 64)
            source = exports / 'AL-OFF.jsonl.gz'
            source.write_bytes(b'bad')
            with self.assertRaisesRegex(ValueError, 'identity'):
                archive_exports(assets, exports, manifest['sha256'])
            self.assertTrue(source.exists())
            self.assertFalse((exports / manifest['sha256']).exists())

    def test_signed_traversal_and_fixture_catalogs_are_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            assets, exports, manifest = self.fixture(root)
            manifest['exports'][0]['file'] = '../private.jsonl.gz'
            sign_manifest(manifest, root / 'signing', assets)
            with self.assertRaisesRegex(ValueError, 'Invalid signed'):
                archive_exports(assets, exports, manifest['sha256'])
            manifest['fixture'] = True
            sign_manifest(manifest, root / 'signing', assets)
            with self.assertRaisesRegex(ValueError, 'fixture'):
                archive_exports(assets, exports, manifest['sha256'])

    def test_existing_release_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as temp:
            assets, exports, manifest = self.fixture(Path(temp))
            destination = exports / manifest['sha256']
            destination.mkdir()
            (destination / 'AL-OFF.jsonl.gz').write_bytes(b'conflict')
            with self.assertRaisesRegex(ValueError, 'identity'):
                archive_exports(assets, exports, manifest['sha256'])
            self.assertEqual((destination / 'AL-OFF.jsonl.gz').read_bytes(), b'conflict')
            self.assertTrue((exports / 'AL-OFF.jsonl.gz').exists())


if __name__ == '__main__':
    unittest.main()
