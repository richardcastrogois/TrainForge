"""Uma falha de coleta e resumos web nao sao roteiro clinico recebido."""
import hashlib
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-mentalizing'


class MentalizingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.receipt = json.loads((FOLDER / cls.reading['collector']['receipt']).read_text(encoding='utf-8'))

    def test_empty_error_not_full_text(self):
        body = (FOLDER / self.receipt['bodyFile']).read_bytes()
        self.assertEqual(self.receipt['status'], 500)
        self.assertEqual(body, b'')
        self.assertEqual(hashlib.sha256(body).hexdigest(), self.receipt['sha256'])
        self.assertFalse(self.reading['collector']['hashOfEmptyIsArticleHash'])

    def test_web_only_sources_not_local_evidence(self):
        self.assertTrue(all(not row['localBodyReceived'] for row in self.reading['webOnlyPrimarySources']))
        self.assertEqual(self.reading['collector']['usableBodies'], 0)

    def test_no_clinical_approval_or_package(self):
        for key in ['exerciseStepsDoseAndEndingReceived', 'commercialAdaptationRightsDemonstrated',
                    'researchClosureApproved', 'releaseApproved', 'appImplemented', 'n21Started']:
            self.assertFalse(self.reading[key])
        self.assertEqual(self.reading['newCatalogFamiliesAdded'], 0)

    def test_barrier_and_reading_linked_to_main_fiche(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-08/n15c-mentalizing/leitura-fontes.json', fiche['dependencies'])
        self.assertIn('2026-10-08/n15c-mentalizing/c15-mit-artigo-xml.evidencia.json',
                      {row['record'] for row in fiche['accessLimits']})


if __name__ == '__main__':
    unittest.main()
