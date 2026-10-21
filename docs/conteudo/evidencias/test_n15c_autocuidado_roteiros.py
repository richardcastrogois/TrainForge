"""Prevent unsupported clinical/dose claims in caregiver self-care evidence."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('caregiver_selfcare', ROOT / 'analisar-n15c-autocuidado-roteiros.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SelfCareEvidenceTests(unittest.TestCase):
    def test_received_bodies_have_integrity_and_no_network_analysis(self):
        result = module.analyse(render=False, write=False)
        self.assertEqual(result['collectorCalls'], 3)
        self.assertEqual(result['usableBodies'], 3)
        self.assertEqual(result['networkCallsDuringAnalysis'], 0)
        self.assertFalse(result['researchClosureApproved'])

    def test_class_minutes_do_not_become_exercise_dose(self):
        reading = json.loads((module.FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        practice = reading['pfa2022']['intervention']
        self.assertEqual(practice['classMinutes'], 60)
        self.assertFalse(practice['classMinutesAreExerciseMinutes'])
        self.assertIsNone(practice['physicalDose'])
        self.assertFalse(practice['meditationDoseAppliesToPmrOrStrength'])

    def test_null_results_are_not_equivalence_or_missing_manual(self):
        reading = json.loads((module.FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        yoga = reading['hamza2020']
        self.assertFalse(yoga['clinical']['nonsignificantProvesEquivalence'])
        self.assertFalse(yoga['intervention']['manualActuallyReceived'])
        self.assertTrue(yoga['intervention']['initialYogaTherapistRequired'])
        self.assertFalse(yoga['intervention']['selfHelpMeansNoProfessionalPreparation'])


if __name__ == '__main__':
    unittest.main()
