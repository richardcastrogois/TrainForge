import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-individual'


class IndividualYogaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('individual_yoga',ROOT/'analisar-n15c-yoga-individual.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.source = cls.reading['sources'][0]

    def test_received_originals_and_primary_credential(self):
        self.assertEqual([self.inventory[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies']],[7,7,7,7])
        bio = next(r for r in self.inventory['receipts'] if r['id']=='c15-yoga-mallaiah-bio-pdf')
        self.assertEqual(bio['pdfPages'],1)
        self.assertIn('master',bio['pdfText'][0].lower())
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)

    def test_caregiver_population_individual_and_dyadic_not_generic(self):
        d = self.source['dose2023']
        self.assertEqual([d['sessions'],d['minutes'],d['weeks']],[15,45,6])
        self.assertTrue(d['liveInstructorRequired'])
        self.assertFalse(self.source['population']['allCaregiversOrPaidWorkersGeneralizationApproved'])
        self.assertFalse(self.source['versions']['mergedByAi'])

    def test_comparisons_not_subjective_or_medium_effect_proof(self):
        r = self.source['caregiverResults']
        self.assertEqual(r['mentalQolCYvsUC']['p'],0.13)
        self.assertFalse(r['mentalQolCYvsUC']['significant'])
        self.assertFalse(r['financialBurdenCYvsUC']['significant'])
        self.assertTrue(r['healthDeclineCYvsDY']['controlComparisonIsDyNotUsualCare'])
        self.assertFalse(r['isolatedPoseEfficacyClaim'])

    def test_materials_and_support_not_invented_or_released(self):
        self.assertFalse(self.source['content']['fullStepDoseEndSequencesReceived'])
        self.assertFalse(self.source['operational']['onlineClearInstructionsReplaceLiveTherapist'])
        self.assertFalse(self.source['professionalAuthorship']['actualInstructorManualScriptsReceived'])
        for k in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[k])


if __name__ == '__main__':
    unittest.main()
