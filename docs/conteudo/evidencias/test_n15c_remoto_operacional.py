import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-remoto-operacional'


class RemoteOperationalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('remote_operational', ROOT/'analisar-n15c-remoto-operacional.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.source = cls.reading['sources'][0]

    def test_same_family_and_version(self):
        self.assertEqual(self.source['protocolVersion'],'2022-05-09')
        self.assertTrue(self.source['pilot2019NotMerged'])
        self.assertTrue(self.source['sameRandomisedTrialNotThreeStudies'])
        self.assertEqual(self.inventory['pdfs']['c15-remoto2026-protocolo-pdf'],27)

    def test_caregiver_age_not_patient_age(self):
        p = self.source['population']
        self.assertEqual([p['caregiverMinimumAge'],p['patientMinimumAge'],p['careHoursPerWeekMinimum']],[18,55,20])
        self.assertTrue(p['medicalClearanceForBoth'])

    def test_article_and_registry_periods(self):
        d = self.source['design']
        self.assertEqual([d['plannedDyads'],d['actualDyads'],d['registryActualPersons']],[100,99,198])
        self.assertEqual([d['articleFollowUpMonths'],d['registryFollowUpMonths']],[6,18])
        self.assertTrue(d['registryHasResults'])

    def test_primary_null_and_caregiver_fitness_not_fatigue(self):
        r = self.source['clinicalResults']
        self.assertEqual([x['beta'] for x in r['caregiverBetweenGroups']],[1.67,11.3])
        self.assertIn('P>0.05',r['primaryDailyMvpaAndSedentaryBetweenGroups'])
        self.assertFalse(r['directFatigueReductionClaimed'])
        self.assertFalse(r['isolatedMovementEfficacyClaimed'])

    def test_dose_and_live_support_not_invented_cards(self):
        d = self.source['delivery']
        self.assertEqual(d['initialSixMonths']['aerobicMets'],[3,5])
        self.assertEqual(d['initialSixMonths']['nominalSessionMinutes'],45)
        self.assertFalse(d['exactIndividualGestureStepsReceived'])
        self.assertFalse(self.source['professionalAuthorship']['apkMayReplaceRequiredCoach'])
        self.assertEqual(self.source['instructionRecords'],[])

    def test_safety_hash_and_release_distinct(self):
        s = self.source['safety']
        self.assertEqual(s['caregiverSeriousAffected'],{'rgv':6,'rgvAtRisk':57,'euc':1,'eucAtRisk':42})
        self.assertTrue(s['causalRelationToExerciseNotDeterminedFromRegistryTable'])
        self.assertTrue(s['noZeroRiskClaim'])
        for k in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[k])
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)

    def test_guide_printed_edition_and_auxiliary_steps_not_trial_dose(self):
        guide = json.loads((FOLDER/'leitura-guia-nia.json').read_text(encoding='utf-8'))
        self.assertEqual(guide['editionDate'],'2018-03')
        self.assertFalse(guide['trialExactEditionConfirmed'])
        self.assertEqual(len(guide['instructionRecords']),6)
        self.assertTrue(all(not x['exactRgvVariantDoseConfirmed'] for x in guide['instructionRecords']))
        self.assertEqual(self.inventory['pdfPages'],151)

    def test_visual_review_and_media_rights_separate(self):
        guide = json.loads((FOLDER/'leitura-guia-nia.json').read_text(encoding='utf-8'))
        self.assertEqual(len(self.reading['visualInspection']['protocolPagesActuallyViewed']),8)
        self.assertEqual(len(guide['visualPagesActuallyViewed']),13)
        self.assertTrue(guide['rights']['photosIllustrationsVideoThirdPartyExceptions'])
        self.assertFalse(guide['rights']['completePdfBlanketApproved'])


if __name__ == '__main__':
    unittest.main()
