"""Preserva dose estatica sem importar contradicoes PNF ou regras inventadas."""
import hashlib
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
PATH = ROOT / '2026-10-08/n15c-originais-caser/revalidacao-estatico.json'


class StaticRevalidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads(PATH.read_text(encoding='utf-8'))
        receipt_path = PATH.parent / cls.reading['canonicalReceipts'][0]
        cls.receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        cls.body = (receipt_path.parent / cls.receipt['bodyFile']).read_bytes()
        cls.xml = ET.fromstring(cls.body)

    def test_canonical_body_hash_and_no_recollection(self):
        self.assertEqual(hashlib.sha256(self.body).hexdigest(), self.receipt['sha256'])
        self.assertEqual(self.reading['networkCallsAdded'], 0)

    def test_static_dose_arithmetic_and_explicit_same_posture(self):
        branch = self.reading['selectedBranch']
        dose = branch['dose']
        self.assertEqual(dose['secondsPerRepetition'] * dose['repetitionsPerLeg'], 240)
        self.assertEqual(dose['activeMinutesBothLegs'], 8)
        text = ''.join(self.xml.find('.//sec[@id="sec2dot3-ijerph-21-01361"]').itertext())
        self.assertIn('30 s each, eight repetitions', text)
        self.assertIn('posture position in PNF stretching', text)
        self.assertFalse(branch['pnfContractionOrIntensityTransferred'])

    def test_no_longitudinal_dose_or_return_invented(self):
        branch = self.reading['selectedBranch']
        self.assertIsNone(branch['dose']['weeklyFrequency'])
        self.assertIsNone(branch['dose']['programmeWeeks'])
        self.assertIsNone(branch['sourceEndingInstruction'])
        self.assertTrue(branch['acuteSessionOnly'])

    def test_absent_height_and_centre_do_not_exclude(self):
        setting = self.reading['environmentDecision']
        for key in ['centreIsAutomaticExclusion', 'missingNumericStepHeightIsAutomaticExclusion',
                    'missingNumericFloorAreaIsAutomaticExclusion', 'fatigueOrShortTimeAuthorisesDoseReduction']:
            self.assertFalse(setting[key])

    def test_no_supplement_in_received_xml_not_global_absence(self):
        self.assertEqual(self.xml.findall('.//supplementary-material'), [])
        self.assertFalse(self.reading['evidenceLimits']['longTermHomeBenefitDemonstrated'])
        self.assertEqual(self.reading['evidenceLimits']['staticWithinMethodPValues']['fingerToFloor'], 0.634)

    def test_conditional_not_approved(self):
        decision = self.reading['decision']
        self.assertEqual(decision['status'], 'condicional')
        self.assertFalse(decision['staticDoseConflict'])
        for key in ['researchClosureApproved', 'releaseApproved', 'n21Started', 'appImplemented']:
            self.assertFalse(decision[key])


if __name__ == '__main__':
    unittest.main()
