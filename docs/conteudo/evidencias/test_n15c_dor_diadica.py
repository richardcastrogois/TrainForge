import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-dor-diadica'


class DyadicPainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('dyadic_pain',ROOT/'analisar-n15c-dor-diadica.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {r['sourceId']:r for r in cls.reading['sources']}

    def test_received_originals_and_hashes(self):
        self.assertEqual([self.inventory[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies','pdfPages']],[9,9,9,9,29])
        self.assertTrue(self.sources['PR120']['resultOriginalJatsReceived'])
        self.assertFalse(self.sources['PR120']['resultPdfReceived'])

    def test_pilot_index_not_complete_book_or_caregiver_efficacy(self):
        p = self.sources['PR119']
        self.assertTrue(p['figure3']['isContentIndex'])
        self.assertFalse(p['figure3']['isCompleteExerciseBook'])
        self.assertFalse(p['caregiverClinicalEffectSeparatelyDemonstrated'])
        self.assertEqual(p['instructionRecords'],[])

    def test_result_population_dose_and_support(self):
        s = self.sources['PR120']
        self.assertEqual(s['population']['caregiverMinimumAge'],18)
        self.assertTrue(s['population']['caregiverHasNonCancerPain'])
        self.assertEqual([s['delivery']['homeMinutes'],s['delivery']['homeSessionsPerWeek']],[30,3])
        self.assertTrue(s['delivery']['researchAssistantFollowUpRequired'])
        self.assertFalse(s['delivery']['progressionByFatigueOrTimeInvented'])

    def test_posted_registry_not_article_results(self):
        s = self.sources['PR120']
        self.assertFalse(s['design']['registryHasResults'])
        self.assertEqual(s['design']['registryFirstSubmitted'],'2021-03-24')
        self.assertEqual(s['design']['registryFirstPosted'],'2021-09-24')
        self.assertTrue(s['sameTrialProtocolResultRegistryOneFamily'])
        self.assertTrue(s['pilot2020NotMerged'])

    def test_caregiver_endpoint_not_older_adult_psychology(self):
        r = self.sources['PR120']['clinicalResults']
        self.assertEqual([r['caregiverBurden']['betweenWeek8P'],r['caregiverBurden']['betweenWeek16P']],[0.137,0.001])
        self.assertTrue(r['psychologicalTable3IsOlderAdultsNotCaregivers'])
        self.assertTrue(r['caregiverDepressionAnxietyStressBenefitNotSeparatelyClaimed'])
        self.assertTrue(r['wholePackageNotIsolatedGestures'])
        self.assertFalse(r['directFatigueScaleReceived'])

    def test_physio_credential_not_every_gesture_authorship(self):
        s = self.sources['PR120']
        self.assertIn('registered physiotherapist',s['professionalAuthorship']['primaryCredential'])
        self.assertFalse(s['professionalAuthorship']['namedAuthorOfEachExerciseConfirmed'])
        self.assertFalse(s['delivery']['actualDetailedExerciseBookReceived'])
        self.assertFalse(s['rights']['externalExerciseBookVideosCoveredAutomatically'])

    def test_visual_review_and_approval_independent(self):
        self.assertEqual(self.reading['visualInspection']['pilotPagesActuallyViewed'],[1,5,6,13,18])
        self.assertEqual(self.reading['visualInspection']['protocolPagesActuallyViewed'],[1,4,5,11])
        for k in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[k])
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)

    def test_correction_not_automatic_replication_or_agent_repair(self):
        a = json.loads((FOLDER/'leitura-antecedentes.json').read_text(encoding='utf-8'))
        s = a['correctedStudy2023']
        self.assertEqual(s['correctedSamplePerArm'],30)
        self.assertEqual(s['caregiverBurden']['betweenFinalP'],0.011)
        self.assertFalse(s['oldTablesEligibleForApk'])
        self.assertFalse(s['independenceFrom2026Confirmed'])
        self.assertEqual(s['calendar']['oldFinalWeek'],12)
        self.assertEqual(s['calendar']['correctedFinalWeek'],16)
        self.assertFalse(a['pilotRegistry']['hasResults'])
        self.assertFalse(a['researchClosureApproved'])


if __name__ == '__main__':
    unittest.main()
