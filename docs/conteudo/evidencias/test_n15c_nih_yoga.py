import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-nih-yoga'


class CaregiverNIHYogaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {s['sourceId']: s for s in cls.reading['sources']}
        spec = importlib.util.spec_from_file_location('nih_test_analysis', ROOT / 'analisar-n15c-nih-yoga.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_originals_rehash_and_docx_safe_read(self):
        plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
        checked = [self.module.receipts.check_receipt(ROUND / (s['id'] + '.evidencia.json'), ROOT) for s in plan['requests']]
        self.assertEqual((len(checked), sum(s['usable'] for s in checked), sum(s['bodyVerified'] for s in checked)), (5, 5, 5))
        paragraphs, security = self.module.read_protocol(ROUND.parent / 'raw/c15-nih-yoga2022-s2-docx.docx')
        self.assertEqual((security['members'], security['uncompressedBytes']), (25, 3479263))
        self.assertTrue(security['embeddedObjectPresent'])
        self.assertFalse(security['embeddedObjectExecuted'])
        self.assertTrue(security['xmlVisibleTextOnly'])
        self.assertIn('February 14, 2018', paragraphs[0])
        self.assertEqual(paragraphs[528], 'SEQUENCE FOR YOGA PRACTICE AUDIO FILE')

    def test_sequence_repeat_not_new_eighth_pose(self):
        p = self.sources['PR82']['protocol']
        self.assertEqual((p['sequenceEntries'], p['uniquePractices']), (8, 7))
        records = self.reading['exerciseRecords']
        self.assertEqual(len(records), 8)
        self.assertEqual(records[-1]['repeatOf'], 'NIH-P06')
        self.assertFalse(records[4]['leftSidePrescribed'])
        self.assertFalse(records[-1]['wholeSessionExitScriptReceived'])

    def test_interval_sum_not_twenty_minute_prescription(self):
        records = self.reading['exerciseRecords']
        self.assertEqual([sum(r['holdSecondsRange'][i] for r in records) for i in [0, 1]], [725, 1035])
        self.assertFalse(self.reading['apkTraceability']['sumIntervalsDefinesStudiedTwentyMinuteRecording'])
        self.assertFalse(records[6]['breathHoldPrescribed'])
        self.assertIsNone(self.reading['recordDefaults']['repetitions'])
        self.assertIsNone(self.reading['recordDefaults']['weeklyProgression'])

    def test_credentials_do_not_remove_support_or_absent_assets(self):
        source = self.sources['PR82']
        self.assertIn('Certified Iyengar', source['professionalAuthorship']['ross'])
        for flag in ('initialIndividualTeachingRequired', 'initialReturnDemonstrationRequired', 'initialSupervisedPracticeRequired'):
            self.assertTrue(source['delivery'][flag])
        self.assertEqual(source['delivery']['professionalSupportCallsWeeks'], [2, 4])
        for flag in ('audioReceived', 'illustratedPamphletReceived', 'apkGuidanceReplacesInitialTeaching', 'actualProfessionalSupportAssumedAvailable'):
            self.assertFalse(source['delivery'][flag])

    def test_eligibility_and_version_conflicts_preserved(self):
        source = self.sources['PR82']
        self.assertTrue(source['population']['paidCaregiversExcludedByProtocol'])
        self.assertFalse(source['population']['age18SourceDisagreementResolved'])
        self.assertFalse(source['population']['biomarkerExclusionsAreExerciseContraindications'])
        self.assertEqual(len(source['versionDisagreements']), 4)
        self.assertFalse(source['protocol']['wholeProtocolReadOrVisuallyReviewed'])

    def test_null_outcomes_not_efficacy_guarantee(self):
        e = self.sources['PR82']['evidenceBasis']
        self.assertEqual((e['randomized'], e['perArm'], e['completed']), (50, 25, 44))
        self.assertEqual(len(e['noGroupDifference']), 3)
        self.assertFalse(e['perMovementClinicalEfficacyDemonstrated'])
        self.assertFalse(e['shortTermRespiteMeasuredImmediatelyAfterSession'])

    def test_open_published_text_does_not_license_missing_recording(self):
        r = self.sources['PR82']['rights']
        self.assertTrue(r['publishedTextPotentialCommercialUse'])
        self.assertEqual(r['articleLicence'], 'CC0 public domain dedication')
        for flag in ('unreceivedRecordingOrPamphletLicenceInherited', 'audioLicenceReceived', 'pamphletLicenceReceived', 'wholeProgrammeImportAllowed'):
            self.assertFalse(r[flag])

    def test_caremetoo_usability_not_exercise_dose(self):
        source = self.sources['PR83']
        self.assertEqual((source['population']['formalCaregivers'], source['population']['familyCaregivers']), (16, 6))
        self.assertFalse(source['evidenceBasis']['clinicalExerciseEfficacyTested'])
        self.assertFalse(source['evidenceBasis']['appUseTimeIsExercisePrescription'])
        self.assertFalse(source['exerciseAssets']['supplementsAreExerciseManuals'])
        self.assertFalse(source['exerciseAssets']['completeStepsOrDosesReceived'])
        self.assertFalse(source['rights']['articleLicenceTransferredToAbsentYoutubeVideos'])

    def test_traceability_and_no_closure(self):
        self.assertTrue(self.reading['apkTraceability']['defaultsMustBeJoinedToEveryRecord'])
        for r in self.reading['exerciseRecords']:
            self.assertIn('AppendixA', r['locator'])
        for flag in ('researchClosureApproved', 'releaseApproved', 'appImplemented', 'contactWithAuthors'):
            self.assertFalse(self.reading[flag])


if __name__ == '__main__':
    unittest.main()
