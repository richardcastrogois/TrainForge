import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('encoding_validation', ROOT / 'validar-complementos-idosos.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EvidenceEncodingTests(unittest.TestCase):
    def test_explicit_japanese_encoding_preserves_readable_text(self):
        payload = '<html><p>Hitoshi Okamura, MD</p><p>\u592a\u7530</p></html>'.encode('cp932')
        text = module.evidence_text(payload, 'text/html', 'cp932')
        self.assertIn('Hitoshi Okamura, MD', text)
        self.assertIn('\u592a\u7530', text)

    def test_no_implicit_ignoring_of_invalid_utf8(self):
        with self.assertRaises(UnicodeDecodeError):
            module.evidence_text(b'<html>\x91</html>', 'text/html')


if __name__ == '__main__':
    unittest.main()
