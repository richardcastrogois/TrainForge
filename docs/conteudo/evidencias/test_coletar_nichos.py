"""Tests for collector byte limits; synthetic bodies and no network."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import io

MODULE_PATH = Path(__file__).with_name('coletar-nichos-off.py')
spec = importlib.util.spec_from_file_location('collector', MODULE_PATH)
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)

class Response(io.BytesIO):
    status = 200
    headers = {'Content-Type': 'application/pdf'}
    def geturl(self):
        return 'https://example.org/manual.pdf'

class Limits(unittest.TestCase):
    def test_default(self):
        self.assertEqual(collector.byte_limit({}, 'application/json,text/html,text/plain'), 2 * 1024 * 1024)

    def test_pdf_override(self):
        self.assertIsNone(collector.byte_limit({'maxBytes': 4194304, 'extension': 'pdf'}, 'application/pdf'))

    def test_xml_zip_limits_and_headers(self):
        for accept, extension in [('application/xml', 'xml'), ('application/zip', 'zip')]:
            with self.subTest(accept=accept), tempfile.TemporaryDirectory() as folder:
                self.assertEqual(collector.byte_limit({}, accept), 2097152)
                with self.assertRaises(AssertionError):
                    collector.byte_limit({'maxBytes': 4194304, 'extension': extension}, accept)
                root = Path(folder)
                plan_dir = root / 'day' / 'niche'
                plan_dir.mkdir(parents=True)
                plan = {'requests': [{'id': 'synthetic-format', 'url': 'https://example.org/public-data',
                    'purpose': 'synthetic negotiation test', 'extension': extension, 'accept': accept}]}
                (plan_dir / 'plan.json').write_text(json.dumps(plan), encoding='utf-8')
                with patch.object(collector, 'ROOT', root), patch.object(collector.urllib.request, 'urlopen',
                    return_value=Response(b'synthetic data')) as get:
                    collector.collect('day/niche/plan.json')
                    self.assertEqual(get.call_args.args[0].get_header('Accept'), accept)
                    record = json.loads((plan_dir / 'synthetic-format.evidencia.json').read_text())
                    self.assertEqual(record['maxBytes'], 2097152)
                    collector.collect('day/niche/plan.json')
                    self.assertEqual(get.call_count, 1)

    def test_invalid_override(self):
        for item, accept in [
            ({'maxBytes': True}, 'application/zip'),
            ({'maxBytes': 8388608, 'extension': 'zip'}, 'application/zip'),
            ({'maxBytes': 4194304, 'extension': 'html'}, 'application/pdf'),
            ({'maxBytes': 4194304, 'extension': 'pdf'}, 'application/json,text/html,text/plain'),
        ]:
            with self.subTest(item=item, accept=accept), self.assertRaises(AssertionError):
                collector.byte_limit(item, accept)

    def test_collect_and_cache(self):
        for cap, has_body in [(2097152, True), (4194304, True)]:
            with self.subTest(cap=cap), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                plan_dir = root / 'day' / 'niche'
                plan_dir.mkdir(parents=True)
                plan = {'requests': [{'id': 'synthetic-pdf', 'url': 'https://example.org/manual.pdf',
                    'purpose': 'test', 'extension': 'pdf', 'accept': 'application/pdf', 'maxBytes': cap}]}
                (plan_dir / 'plan.json').write_text(json.dumps(plan), encoding='utf-8')
                with patch.object(collector, 'ROOT', root), patch.object(collector.urllib.request, 'urlopen',
                    return_value=Response(b'x' * 3145728)) as get:
                    collector.collect('day/niche/plan.json')
                    record = json.loads((plan_dir / 'synthetic-pdf.evidencia.json').read_text())
                    self.assertEqual('bodyFile' in record, has_body)
                    self.assertIsNone(record['maxBytes'])
                    collector.collect('day/niche/plan.json')
                    self.assertEqual(get.call_count, 1)
                if not has_body:
                    self.assertEqual(list((root / 'day' / 'raw').iterdir()), [])

if __name__ == '__main__':
    unittest.main()
