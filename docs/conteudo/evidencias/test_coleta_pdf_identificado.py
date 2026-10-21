"""User-authorized research PDF streaming and source-specific DOCX guards."""
import hashlib
import io
import json
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

MODULE = runpy.run_path(str(Path(__file__).with_name('coletar-nichos-off.py')))


class KnownPdfTests(unittest.TestCase):
    def test_pdf_has_no_byte_ceiling(self):
        for size in (None, 2097152, 16777216, 100000000):
            self.assertIsNone(MODULE['byte_limit']({'extension': 'pdf', 'maxBytes': size}, 'application/pdf'))

    def test_streamed_pdf_above_old_ceiling_preserves_hash(self):
        body = b'%PDF-1.7\n' + b'x' * (17 * 1024 * 1024)
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'large.pdf'
            size, digest = MODULE['store_body'](io.BytesIO(body), target, None)
            self.assertEqual(size, len(body))
            self.assertEqual(digest, hashlib.sha256(body).hexdigest())
            self.assertEqual(target.read_bytes(), body)

    def test_large_zip_remains_rejected(self):
        with self.assertRaises(AssertionError):
            MODULE['byte_limit']({'extension': 'zip', 'maxBytes': 16777216}, 'application/zip')

    def test_authorized_react_docx_only(self):
        item = {'url': MODULE['REACT_SUPPLEMENT'], 'extension': 'docx', 'maxBytes': 16777216}
        self.assertEqual(MODULE['byte_limit'](item, MODULE['DOCX']), 16777216)
        item['url'] = 'https://example.org/other.docx'
        with self.assertRaises(AssertionError):
            MODULE['byte_limit'](item, MODULE['DOCX'])

    def test_bounded_failure_leaves_no_partial_file(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'bounded.zip'
            with self.assertRaises(ValueError):
                MODULE['store_body'](io.BytesIO(b'x' * 3145728), target, 2097152)
            self.assertEqual(list(Path(folder).iterdir()), [])

    def test_existing_body_and_partial_are_preserved(self):
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / 'existing.pdf'
            partial = target.with_name(target.name + '.part')
            partial.write_bytes(b'earlier incomplete download')
            with self.assertRaises(ValueError):
                MODULE['store_body'](io.BytesIO(b'new'), target, None)
            self.assertEqual(partial.read_bytes(), b'earlier incomplete download')
            partial.unlink()
            target.write_bytes(b'original')
            with self.assertRaises(ValueError):
                MODULE['store_body'](io.BytesIO(b'new'), target, None)
            self.assertEqual(target.read_bytes(), b'original')

    def test_http200_html_is_not_docx_and_is_retained(self):
        class Response(io.BytesIO):
            status = 200
            headers = {'Content-Type': 'text/html'}
            def geturl(self):
                return MODULE['REACT_SUPPLEMENT']
        body = b'<html>Preparing to download ... POW_CHALLENGE</html>'
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            plan_dir = root / 'day' / 'niche'
            plan_dir.mkdir(parents=True)
            item = {'id': 'react-test', 'url': MODULE['REACT_SUPPLEMENT'], 'extension': 'docx',
                    'accept': MODULE['DOCX'], 'maxBytes': 16777216, 'purpose': 'synthetic test'}
            (plan_dir / 'plan.json').write_text(json.dumps({'requests': [item]}), encoding='utf-8')
            with patch.dict(MODULE['collect'].__globals__, {'ROOT': root}), patch('urllib.request.urlopen', return_value=Response(body)) as get:
                MODULE['collect']('day/niche/plan.json')
                MODULE['collect']('day/niche/plan.json')
            record = json.loads((plan_dir / 'react-test.evidencia.json').read_text())
            self.assertFalse(record['bodyFormatMatchesRequest'])
            self.assertEqual(record['sha256'], hashlib.sha256(body).hexdigest())
            self.assertIn('not the requested binary format', record['error'])
            self.assertEqual(get.call_count, 1)

    def test_unlimited_pdf_known_size_mismatch_is_retained(self):
        class Response(io.BytesIO):
            status = 200
            headers = {'Content-Type': 'application/pdf'}
            def geturl(self):
                return 'https://example.org/manual.pdf'
        body = b'%PDF-1.7\nsynthetic-not-parseable'
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            plan_dir = root / 'day' / 'niche'
            plan_dir.mkdir(parents=True)
            item = {'id': 'pdf-test', 'url': 'https://example.org/manual.pdf', 'extension': 'pdf',
                    'accept': 'application/pdf', 'expectedBytes': 100, 'purpose': 'synthetic test'}
            (plan_dir / 'plan.json').write_text(json.dumps({'requests': [item]}), encoding='utf-8')
            with patch.dict(MODULE['collect'].__globals__, {'ROOT': root}), patch('urllib.request.urlopen', return_value=Response(body)):
                MODULE['collect']('day/niche/plan.json')
            record = json.loads((plan_dir / 'pdf-test.evidencia.json').read_text())
            self.assertIsNone(record['maxBytes'])
            self.assertFalse(record['expectedBytesMatch'])
            self.assertEqual(record['sha256'], hashlib.sha256(body).hexdigest())
