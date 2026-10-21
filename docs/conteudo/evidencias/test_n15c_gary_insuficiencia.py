"""Nao transforma barreira, registro agregado ou erratum em programa N15-C."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-gary-insuficiencia'
spec = importlib.util.spec_from_file_location('n15_gary', ROOT / 'analisar-n15c-gary-insuficiencia.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class GaryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))

    def test_three_calls_two_usable_bodies(self):
        self.assertEqual(self.inventory['collectorCalls'], 3)
        self.assertEqual(self.inventory['usableBodies'], 2)
        self.assertFalse(self.inventory['fullTextReceived'])

    def test_registry_total_not_heart_failure_sample(self):
        self.assertEqual(self.inventory['registry']['enrollmentActual'], 354)
        self.assertEqual(self.reading['webOnlyClinicalLead']['sample'], 127)
        self.assertFalse(self.inventory['registry']['hasResults'])

    def test_funding_erratum_not_invented_dose_correction(self):
        self.assertTrue(self.inventory['erratum']['abstractReceived'])
        self.assertFalse(self.inventory['erratum']['publisherFullTextReceived'])
        self.assertFalse(self.reading['erratum']['correctedArticleBodyConfirmedLocally'])

    def test_no_approval_no_instructions_created(self):
        self.assertIsNone(self.reading['registry']['individualExercisesStepsDose'])
        for field in ['researchClosureApproved','releaseApproved','appImplemented','n21Started']:
            self.assertFalse(self.reading[field])

    def test_provenance_and_barrier_attached_to_main_fiche(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        all_records = {r['record'] for r in fiche['evidence']} | {r['record'] for r in fiche['accessLimits']}
        self.assertTrue({r['record'] for r in self.inventory['sources']}.issubset(all_records))
        self.assertIn('2026-10-08/n15c-gary-insuficiencia/leitura-fontes.json',fiche['dependencies'])


if __name__ == '__main__':
    unittest.main()
