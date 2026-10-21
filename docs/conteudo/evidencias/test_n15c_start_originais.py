import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-start-originais'


class StartOriginalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('start_originals', ROOT / 'analisar-n15c-start-originais.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.source = cls.reading['sources'][0]

    def test_received_not_success_only(self):
        self.assertEqual(self.inventory['collectorCalls'], 6)
        self.assertEqual(self.inventory['http200'], 4)
        self.assertEqual(self.inventory['usableBodies'], 3)
        self.assertEqual(self.inventory['hashedBodies'], 6)
        self.assertEqual(self.inventory['pdfPages'], 282)
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'], 0)

    def test_manual_in_report_not_failed_lancet_version(self):
        self.assertTrue(self.inventory['manualIncludedInReport'])
        self.assertTrue(self.inventory['manualIsRaster'])
        self.assertEqual(self.source['versions']['reportPdfPages'], 272)
        self.assertFalse(self.source['versions']['lancet206PageSupplementReceived'])
        self.assertFalse(self.source['versions']['new2025EditionMerged'])

    def test_package_support_and_threshold_not_removed(self):
        delivery = self.source['delivery']
        self.assertEqual(delivery['sessions'], 8)
        self.assertEqual(delivery['adherenceThresholdSessions'], 5)
        self.assertFalse(delivery['adherenceThresholdIsPrescribedCourseLength'])
        self.assertFalse(delivery['apkMayReplaceRequiredHumanSupport'])
        self.assertFalse(self.source['design']['independentGestureEfficacyClaimed'])

    def test_source_precautions_and_variants_not_invented(self):
        rows = {row['id']: row for row in self.source['instructionRecords']}
        self.assertEqual(rows['START-SIGNAL']['maxRepetitionsPerOccasion'], 3)
        self.assertEqual(rows['START-SIGNAL']['holdSecondsRange'], [2,3])
        stretch = rows['START-STRETCH']
        self.assertTrue(stretch['sourceAllowsSeatedOrStanding'])
        self.assertFalse(stretch['secondExecutionMandatory'])
        self.assertFalse(stretch['staticThirtySecondHoldImported'])
        self.assertTrue(self.source['safety']['stretchStopCriterionReceived'])

    def test_rights_and_review_are_not_release(self):
        self.assertFalse(self.source['rights']['manualCommercialCopyOrTranslationApproved'])
        self.assertFalse(self.source['rights']['scientificFactsBlanketProhibited'])
        self.assertFalse(self.reading['visualInspection']['wholePdfVisuallyReviewed'])
        self.assertFalse(self.reading['releaseApproved'])
        self.assertFalse(self.reading['researchClosureApproved'])
        self.assertFalse(self.reading['appImplemented'])

    def test_all_eight_scripts_have_verified_endings_not_new_doses(self):
        rows = self.source['instructionRecords']
        self.assertEqual(sorted(row['session'] for row in rows), list(range(1,9)))
        self.assertTrue(all(row['instructionAndEndingReceived'] for row in rows))
        visual = self.reading['visualInspection']
        self.assertTrue(visual['allEightRelaxationScriptsVisuallyReviewed'])
        self.assertEqual(len(visual['pagesActuallyViewed']), 58)
        self.assertEqual(len(set(visual['pagesActuallyViewed'])), 58)
        self.assertTrue(all(set(row['pdfPages']) <= set(visual['pagesActuallyViewed']) for row in rows))
        mountain = next(row for row in rows if row['id'] == 'START-MOUNTAIN')
        self.assertEqual(mountain['explicitTenSecondPauses'], 2)
        self.assertIsNone(mountain['wholeMinutesReceived'])
        self.assertFalse(mountain['maintenanceScheduleInvented'])


if __name__ == '__main__':
    unittest.main()
