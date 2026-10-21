import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('manuals', Path(__file__).with_name('analisar-manuais-02.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ManualInventoryTests(unittest.TestCase):
    def document(self, folder, text='GOAL: PLAN: Example: Walking outdoors'):
        path = Path(folder) / 'sample.docx'
        with zipfile.ZipFile(path, 'w') as z:
            z.writestr('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>' + text + '</w:t></w:r></w:p></w:body></w:document>')
        return path

    def test_blank_log_is_not_prescription(self):
        with tempfile.TemporaryDirectory() as folder:
            data = module.docx_inventory(self.document(folder))
            self.assertTrue(data['hasBlankGoalAndPlanLabels'])
            self.assertTrue(data['hasWalkingExampleNotPrescription'])
            self.assertEqual(data['embeddedImages'], [])

    def test_references_to_missing_material(self):
        with tempfile.TemporaryDirectory() as folder:
            data = module.docx_inventory(self.document(folder, 'Intervention Manual and Intervener PA Work Sheet'))
            self.assertTrue(data['hasInterventionManualReference'])
            self.assertTrue(data['hasIntervenerWorksheetReference'])

    def test_budget_enforced_without_extraction(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                module.docx_inventory(self.document(folder), max_expanded=1)

    def test_inline_runs_do_not_invent_spaces(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'runs.docx'
            with zipfile.ZipFile(path, 'w') as z:
                z.writestr('word/document.xml', '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Intervention </w:t></w:r><w:r><w:t>Man</w:t></w:r><w:r><w:t>ual</w:t></w:r></w:p></w:body></w:document>')
            self.assertTrue(module.docx_inventory(path)['hasInterventionManualReference'])

    def test_unsafe_member_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = self.document(folder)
            with zipfile.ZipFile(path, 'a') as z:
                z.writestr('../unsafe', 'no execution')
            with self.assertRaises(ValueError):
                module.docx_inventory(path)

    def test_html_not_docx(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'false.docx'
            path.write_bytes(b'<html>challenge</html>')
            with self.assertRaises(zipfile.BadZipFile):
                module.docx_inventory(path)

    def test_hash_mismatch_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            body = self.document(folder)
            receipt = Path(folder) / 'receipt.json'
            receipt.write_text(json.dumps({'bodyFile':body.name, 'status':200, 'bytes':body.stat().st_size, 'sha256':'wrong'}), encoding='utf-8')
            with self.assertRaises(ValueError):
                module.verify_body(receipt, Path(folder))


if __name__ == '__main__':
    unittest.main()
