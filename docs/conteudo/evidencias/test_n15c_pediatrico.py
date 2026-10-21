"""Fonte profissional/licenciada nao completa posturas ausentes nem vira RCT."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-pediatrico'
spec = importlib.util.spec_from_file_location('n15_pediatric', ROOT / 'analisar-n15c-pediatrico.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PediatricTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))

    def test_two_original_bodies_and_five_pages(self):
        self.assertEqual(self.inventory['collectorCalls'], 2)
        self.assertEqual(self.inventory['hashedBodies'], 2)
        self.assertEqual(self.inventory['pdfPages'], 5)

    def test_primary_license_not_secondary_nc(self):
        self.assertTrue(self.inventory['editorialQualificationAndCcBy4AnchorsVerified'])
        self.assertTrue(self.inventory['pdfCcByDeclarationVerified'])
        self.assertFalse(self.reading['rights']['secondaryResearchGateNcClaimUsed'])

    def test_no_rct_or_each_gesture_proven(self):
        self.assertEqual(self.reading['population']['participants'], 63)
        self.assertFalse(self.reading['results']['randomizedControlledTrial'])
        self.assertFalse(self.reading['results']['eachIndividualPostureEfficacyDemonstrated'])

    def test_muscles_not_instructions_and_test_not_workout(self):
        intervention = self.reading['intervention']
        self.assertEqual(intervention['positionsCount'], 17)
        self.assertFalse(intervention['muscleNamesAreSeventeenPostureInstructions'])
        self.assertIsNone(intervention['exactSeventeenPosturesSequence'])
        self.assertFalse(intervention['testingWellsBenchIsRequiredExerciseMaterial'])
        self.assertFalse(self.reading['selection']['researchClosureApproved'])

    def test_provenance_in_main_fiche(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        records = {row['record'] for row in fiche['evidence']}
        self.assertTrue({row['record'] for row in self.inventory['sources']}.issubset(records))
        self.assertIn('2026-10-08/n15c-pediatrico/leitura-fontes.json', fiche['dependencies'])


if __name__ == '__main__':
    unittest.main()
