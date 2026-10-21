import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-respiracao-oncologia'
spec = importlib.util.spec_from_file_location('breathing_oncology', ROOT / 'analisar-n15c-respiracao-oncologia.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaregiverBreathingTests(unittest.TestCase):
    def test_integrity_without_network(self):
        result = module.analyse(write=False)
        self.assertEqual(result['usableBodies'], 2)
        self.assertEqual(result['networkCallsDuringAnalysis'], 0)

    def test_bundle_and_teaching_are_not_isolated_home_prescription(self):
        reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        self.assertFalse(reading['design']['isolatedBreathingEfficacyDemonstrated'])
        self.assertIsNone(reading['intervention']['homePracticeMinutes'])
        self.assertTrue(reading['intervention']['personalCounsellingRetained'])
        self.assertFalse(reading['rights']['articlePolicyAutomaticallyLicensesVideo'])
        self.assertFalse(reading['researchClosureApproved'])


if __name__ == '__main__':
    unittest.main()
