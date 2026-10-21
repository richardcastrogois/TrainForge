import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-pilates-cuidadores'
spec = importlib.util.spec_from_file_location('caregiver_pilates', ROOT / 'analisar-n15c-pilates-cuidadores.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaregiverPilatesTests(unittest.TestCase):
    def test_integrity_and_no_network(self):
        result = module.analyse(write=False)
        self.assertEqual((result['collectorCalls'], result['usableBodies']), (7, 7))
        self.assertEqual(result['networkCallsDuringAnalysis'], 0)
        rows = {row['id']: row for row in result['receipts']}
        self.assertEqual(rows['c15-pilates-pediatrico2019-tese-pdf']['pdfPages'], 152)
        self.assertEqual(rows['c15-kirmizigil-bio-pdf']['pdfText'], [])

    def test_no_equivalence_or_wrong_outcome(self):
        source = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))['sources'][0]
        self.assertEqual(source['clinical']['withinGroupP']['VAS'][0], .59)
        self.assertFalse(source['clinical']['absenceDifferenceProvesEqualEfficacy'])
        self.assertFalse(source['design']['patientMs54AndEdssAreCaregiverOutcomes'])
        self.assertTrue(source['dose']['liveSupportRetained'])

    def test_original_photos_are_not_full_manual_or_license(self):
        source = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))['sources'][1]
        self.assertTrue(source['programme']['warmupAndCooldownReceived'])
        self.assertTrue(source['programme']['progressionDiscrepancyUnresolved'])
        self.assertFalse(source['programme']['fullStepCommandsAllTableMovementsReceived'])
        self.assertFalse(source['rights']['siteLicenseIsItemLicense'])
        self.assertEqual(source['clinical']['sixMinuteWalkBetweenPostP'], .10)


if __name__ == '__main__':
    unittest.main()
