import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

import evidence_store as store


class EvidenceStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.index = self.root / store.INDEXES[0]
        self.index.parent.mkdir(parents=True)
        self.key = 'docs/conteudo/evidencias/round/receipt.json'
        self.content = b'{"fixtureOnly":true,"approved":false}\r\n'
        self.archive = self.index.parent / 'pesquisas.zip'
        self.bundle()

    def bundle(self, *, key=None, content=None, digest=None):
        key = self.key if key is None else key
        content = self.content if content is None else content
        with zipfile.ZipFile(self.archive, 'w') as bundle:
            bundle.writestr(key, content)
        self.index.write_text(json.dumps({'schemaVersion': 1, 'archive': self.archive.name,
            'files': [{'path': key, 'bytes': len(content),
                'sha256': digest or hashlib.sha256(content).hexdigest()}]}), encoding='utf-8')
        store._records.cache_clear()

    def test_original_bytes_and_virtual_location_survive_without_extraction(self):
        self.assertFalse((self.root / self.key).exists())
        self.assertTrue(store.available(self.key, root=self.root))
        self.assertEqual(store.read_bytes(self.key, root=self.root), self.content)
        self.assertEqual(store.verify(self.root), 1)
        self.assertFalse((self.root / '.local').exists())

    def test_changed_archive_never_passes_as_original_evidence(self):
        self.bundle(digest='a' * 64)
        with self.assertRaises(ValueError):
            store.read_bytes(self.key, root=self.root)
        with self.assertRaises(ValueError):
            store.verify(self.root)

    def test_current_guide_and_archived_snapshot_have_distinct_reads(self):
        current = self.root / self.key
        current.parent.mkdir(parents=True)
        current.write_bytes(b'current guide')
        self.assertEqual(store.read_bytes(self.key, root=self.root), b'current guide')
        self.assertEqual(store.read_bytes(self.key, root=self.root, archived=True), self.content)

    def test_extract_one_file_privately_without_overwriting_edits(self):
        output = store.extract(self.key, root=self.root)
        self.assertTrue(output.is_relative_to(self.root / '.local'))
        self.assertEqual(output.read_bytes(), self.content)
        self.assertEqual(store.extract(self.key, root=self.root), output)
        output.write_bytes(b'private user annotation')
        with self.assertRaises(ValueError):
            store.extract(self.key, root=self.root)
        self.assertEqual(output.read_bytes(), b'private user annotation')

    def test_extraction_and_reads_reject_escape_paths(self):
        for key in ('../private.env', '.local/private.env', 'docs/../../private.env'):
            with self.subTest(key=key), self.assertRaises(ValueError):
                store.read_bytes(key, root=self.root)
        with self.assertRaises(ValueError):
            store.extract(self.key, self.root / 'docs', root=self.root)

    def test_index_cannot_name_an_archive_outside_its_directory(self):
        data = json.loads(self.index.read_text())
        data['archive'] = '../outside.zip'
        self.index.write_text(json.dumps(data), encoding='utf-8')
        with self.assertRaises(ValueError):
            store.records(self.root)

    def test_zip_slip_entries_and_duplicate_ids_are_rejected(self):
        self.bundle(key='docs/../../escape.json')
        with self.assertRaises(ValueError):
            store.verify(self.root)
        self.bundle()
        data = json.loads(self.index.read_text())
        data['files'].append(data['files'][0])
        self.index.write_text(json.dumps(data), encoding='utf-8')
        with self.assertRaises(ValueError):
            store.records(self.root)

    def test_private_third_party_bodies_remain_available_without_becoming_public(self):
        key = 'docs/conteudo/evidencias/local/body.bin'
        body = self.root / '.local/pesquisa-corpos' / key
        body.parent.mkdir(parents=True)
        body.write_bytes(b'local fixture body')
        self.assertEqual(store.local_path(key, root=self.root), body)
        self.assertEqual(store.read_bytes(key, root=self.root), b'local fixture body')
        self.assertNotIn(key, store.records(self.root))

    def test_missing_body_is_an_absence_instead_of_an_empty_success(self):
        key = 'docs/conteudo/evidencias/missing.json'
        self.assertFalse(store.available(key, root=self.root))
        with self.assertRaises(FileNotFoundError):
            store.read_bytes(key, root=self.root)
