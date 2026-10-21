"""Local fixtures for content-type mismatches; no network or closure changes."""
from io import BytesIO
from pathlib import Path
import runpy
import unittest

from pypdf import PdfWriter
from pypdf.errors import PdfReadError

READER = runpy.run_path(str(Path(__file__).with_name('validar-complementos-idosos.py')))


class EvidenceTextTests(unittest.TestCase):
    def test_octet_stream_pdf_is_detected_by_verified_body(self):
        writer = PdfWriter()
        writer.add_blank_page(width=100, height=100)
        stream = BytesIO()
        writer.write(stream)
        payload = stream.getvalue()
        self.assertTrue(payload.startswith(b'%PDF-'))
        self.assertEqual(READER['evidence_text'](payload, 'application/octet-stream'), '')

    def test_text_still_ignores_scripts(self):
        self.assertEqual(READER['evidence_text'](b'<p>Evidence</p><script>not evidence</script>', 'text/html'), 'Evidence')

    def test_declared_pdf_with_html_body_is_not_accepted_as_pdf(self):
        with self.assertRaises(PdfReadError):
            READER['evidence_text'](b'<html>shell, not a PDF</html>', 'application/pdf')


if __name__ == '__main__':
    unittest.main()
