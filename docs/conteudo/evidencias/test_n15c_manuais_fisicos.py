import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-manuais-fisicos'


class PhysicalManualTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('physical_manuals', ROOT/'analisar-n15c-manuais-fisicos.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {row['sourceId']:row for row in cls.reading['sources']}

    def test_actual_retained_bodies_not_failed_tls(self):
        inv = self.inventory
        self.assertEqual([inv[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies','pdfPages']], [5,3,3,3,13])
        failed = [row for row in inv['receipts'] if row['status'] is None]
        self.assertEqual(len(failed),2)
        self.assertTrue(all(row['sha256'] is None and row['bytes'] is None for row in failed))

    def test_embargo_and_versions_not_bypassed(self):
        source = self.sources['PR116']
        self.assertEqual(source['webMetadata']['embargoUntil'],'2028-05-22')
        self.assertFalse(source['webMetadata']['bitstreamOrDerivedTextAccessAttempted'])
        self.assertFalse(source['localThesisReceived'])
        versions = source['versions']
        self.assertEqual(versions[0]['targetTotal'],230)
        self.assertEqual(versions[1]['randomised'],45)
        self.assertEqual(versions[1]['completedIntervention'],12)
        self.assertFalse(source['results']['isolatedStretchBenefitClaimed'])

    def test_weekly_contacts_are_not_exercise_doses(self):
        source = self.sources['PR117']
        self.assertEqual(source['delivery']['weeklyContactMinutes'],[90,60,60,90,60,60,90,90])
        self.assertTrue(source['delivery']['minutesAreNotDailyExerciseDose'])
        self.assertFalse(source['delivery']['individualGestureStepsReceived'])
        self.assertFalse(source['professionalAuthorship']['apkMayReplaceTeam'])

    def test_results_and_flow_conflicts_are_preserved(self):
        source = self.sources['PR117']
        self.assertEqual(source['design']['randomised'],96)
        self.assertEqual(source['design']['analysed'],92)
        zbi, pcs = source['results']['endPointBetweenGroups'][:2]
        self.assertEqual(zbi['p'],0.032)
        self.assertEqual(pcs['p'],0.019)
        self.assertEqual(source['results']['baselineTableVsNarrativePConflict']['PCS'],[0.794,0.913])
        self.assertFalse(source['results']['directFatigueScaleReceived'])

    def test_sources_and_visual_review_not_release(self):
        self.assertEqual(self.reading['visualInspection']['sunPagesActuallyViewed'],[1,5,8,9,10])
        self.assertFalse(self.reading['visualInspection']['wholeSunPdfVisuallyReviewed'])
        self.assertEqual(self.sources['PR117']['rights']['license'],'CC BY-NC-ND4.0')
        for key in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[key])
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'],0)


if __name__ == '__main__':
    unittest.main()
