import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-protocolos'


class YogaProtocolsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('caregiver_yoga',ROOT/'analisar-n15c-yoga-protocolos.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {x['sourceId']:x for x in cls.reading['sources']}

    def test_integrity_and_originals(self):
        self.assertEqual([self.inventory[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies','pdfPages']],[6,6,6,6,15])
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)

    def test_feasibility_not_randomized_or_causal_efficacy(self):
        s = self.sources['PR122']
        self.assertFalse(s['design']['randomizedControlledTrial'])
        self.assertTrue(s['caregiverResults']['prePostNotControlledCausalEfficacy'])
        self.assertEqual(s['caregiverResults']['energyFatigueP'],0.021)
        self.assertEqual(s['caregiverResults']['burdenReactionP'],0.102)

    def test_support_and_prescribed_vs_observed_dose(self):
        s = self.sources['PR122']['delivery']
        self.assertEqual([s['weeklyLiveClassMinutes'],s['homePracticeMinutes'],s['homePracticeNonClassDays']],[75,[15,20],5])
        self.assertTrue(s['liveTeacherAndSafetyObserverRequired'])
        self.assertTrue(s['caregiverMedicalClearanceRequired'])
        self.assertTrue(s['observedAdherenceIsNotPrescribedDose'])

    def test_appendix_and_protocol_not_homework_manual(self):
        s = self.sources['PR122']['operational']
        self.assertTrue(s['appendixReceived'])
        self.assertFalse(s['completeStepDoseEndPerGesture'])
        self.assertFalse(s['homeworkManualReceived'])
        self.assertTrue(s['protocolPdfIsNotHomeworkManual'])
        self.assertFalse(self.sources['PR122']['rights']['externalManualVideosLicensed'])

    def test_old_trial_between_vs_within_and_authorship(self):
        s = self.sources['PR123']
        self.assertIn('Cameron',s['authorship']['developer'])
        self.assertFalse(s['clinicalResults']['betweenGroupEndTestsSignificant'])
        self.assertFalse(s['operational']['movementStepsDoseEndReceived'])

    def test_visual_and_registry_not_release(self):
        self.assertEqual(self.reading['visualInspection']['protocolPagesActuallyViewed'],[1,5,6,7,11,12,13])
        self.assertEqual(self.sources['PR124']['registry']['estimatedPersons'],400)
        self.assertFalse(self.sources['PR124']['registry']['hasResults'])
        for key in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[key])


if __name__=='__main__':
    unittest.main()
