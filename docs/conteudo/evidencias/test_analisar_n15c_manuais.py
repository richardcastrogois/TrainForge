import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('n15c_manuals', Path(__file__).with_name('analisar-n15c-manuais.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class N15CReceiptTests(unittest.TestCase):
    def receipt(self, root, status=200, error=None, digest=None, body_file='body.pdf'):
        root = Path(root)
        body = b'%PDF- example for integrity test, not PDF parsing'
        (root / 'body.pdf').write_bytes(body)
        data = {'id': 'test', 'url': 'https://example.org', 'status': status,
                'bodyFile': body_file, 'bytes': len(body),
                'sha256': digest or hashlib.sha256(body).hexdigest()}
        if error:
            data['error'] = error
        path = root / 'receipt.json'
        path.write_text(json.dumps(data), encoding='utf-8')
        return path

    def test_usable_success(self):
        with tempfile.TemporaryDirectory() as root:
            self.assertTrue(module.check_receipt(self.receipt(root), Path(root))['usable'])

    def test_error_body_is_hashed_but_not_usable(self):
        with tempfile.TemporaryDirectory() as root:
            item = module.check_receipt(self.receipt(root, 404, 'HTTP 404'), Path(root))
            self.assertTrue(item['bodyVerified'])
            self.assertFalse(item['usable'])

    def test_200_wrong_format_is_not_usable(self):
        with tempfile.TemporaryDirectory() as root:
            self.assertFalse(module.check_receipt(self.receipt(root, error='wrong format'), Path(root))['usable'])

    def test_hash_mismatch_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaises(ValueError):
                module.check_receipt(self.receipt(root, digest='wrong'), Path(root))

    def test_body_escape_rejected(self):
        with tempfile.TemporaryDirectory() as root:
            with self.assertRaises(ValueError):
                module.check_receipt(self.receipt(root, body_file='../body.pdf'), Path(root))

    def test_tls_failure_is_not_a_document(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root) / 'receipt.json'
            path.write_text(json.dumps({'id': 'tls', 'status': None, 'error': 'TLS failed'}), encoding='utf-8')
            item = module.check_receipt(path, Path(root))
            self.assertFalse(item['usable'])
            self.assertFalse(item['bodyVerified'])


if __name__ == '__main__':
    unittest.main()
