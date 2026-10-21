import importlib.util
import io
import json
from pathlib import Path
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-curriculos-adicionais'
spec = importlib.util.spec_from_file_location('extra_curricula', ROOT / 'analisar-n15c-curriculos-adicionais.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ExtraCurriculaTests(unittest.TestCase):
    def test_receipts_include_unusable_empty_500(self):
        result = module.analyse()
        self.assertEqual((result['collectorCalls'], result['http200'], result['usableBodies']), (10, 9, 9))
        failed = next(r for r in result['receipts'] if r['status'] == 500)
        self.assertEqual(failed['bytes'], 0)
        self.assertFalse(failed['usableForReading'])

    def test_nested_original_pdf_hash(self):
        module.analyse()
        archives = json.loads((FOLDER / 'leitura-suplementos.json').read_text(encoding='utf-8'))
        hybrid = next(a for a in archives if 'hibrido' in a['record'])
        nested = next(m for m in hybrid['members'] if m['chain'][-1].endswith('.zip'))
        pdf = nested['members'][0]
        self.assertEqual(pdf['pdfPages'], 5)
        self.assertEqual(pdf['sha256'], '7ca60012578ce5846701a251280207ebb28d4197accb151c0fccdb934a22abe6')
        self.assertEqual(len(pdf['chain']), 2)

    def test_archive_traversal_and_depth_rejected(self):
        buffer = io.BytesIO()
        with ZipFile(buffer, 'w') as archive:
            archive.writestr('../escaped.pdf', b'not a pdf')
        with self.assertRaises(ValueError):
            module.read_archive(buffer.getvalue())
        with self.assertRaises(ValueError):
            module.read_archive(b'', depth=2)

    def test_no_script_or_causal_fatigue_inferred(self):
        reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        sources = {s['sourceId']:s for s in reading['sources']}
        self.assertFalse(reading['researchClosureApproved'])
        self.assertFalse(reading['releaseApproved'])
        self.assertFalse(sources['PR132']['clinical']['fatigueSuperiorityQGProven'])
        self.assertEqual(sources['PR134']['clinical']['burdenInteractionP'], .38)
        self.assertFalse(sources['PR131']['supplement']['questionAboutWorkbookIsWorkbookReceived'])


if __name__ == '__main__':
    unittest.main()
