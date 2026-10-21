import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-caminhada-social'


class WalkingSocialTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('walking_social',ROOT/'analisar-n15c-caminhada-social.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {x['sourceId']:x for x in cls.reading['sources']}

    def test_actual_bodies_not_empty_error_articles(self):
        self.assertEqual([self.inventory[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies']],[5,3,5,3])
        self.assertFalse(self.inventory['empty500IsClinicalArticle'])
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)

    def test_walking_dose_not_observed_steps_or_another_edition(self):
        d = self.sources['PR125']['dose2020']
        self.assertEqual([d['minutes'],d['sessionsPerWeek'],d['weeks'],d['mets']],[30,3,12,3])
        self.assertTrue(d['normalWalkingSpeedNotBriskOrRunning'])
        self.assertFalse(self.sources['PR125']['countAsTwoIndependentReplications'])

    def test_results_not_caregiver_benefit_from_patient_or_within(self):
        r = self.sources['PR125']['results2020']
        self.assertEqual(r['dDimerBetweenChangeP'],0.377)
        self.assertTrue(r['articleCallsWithinResultNonSignificant'])
        self.assertTrue(r['patientMmseNotCaregiverOutcome'])
        self.assertFalse(self.sources['PR125']['operational']['exactPreparationWarmupCoolDownStopResumeReceived'])

    def test_game_comparator_and_doc_not_pdf_authorization(self):
        g = self.sources['PR126']
        self.assertFalse(g['design2023']['isolatedExerciseClinicalTrial'])
        self.assertTrue(g['empty500HashNotArticleHash'])
        self.assertFalse(g['supplement2020']['collected'])
        self.assertTrue(g['supplement2020']['pdfSizeAuthorizationDoesNotCoverDoc'])

    def test_no_release_or_app(self):
        for key in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[key])


if __name__=='__main__':
    unittest.main()
