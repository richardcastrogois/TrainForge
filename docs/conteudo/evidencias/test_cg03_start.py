"""Keep START's components, therapeutic package and publishing limits distinct."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('start_focal', ROOT / 'analisar-cg03-start.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StartComponentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        cls.original = json.loads((module.ORIGINAL / 'leitura-fontes.json').read_text(encoding='utf-8'))['sources'][0]
        cls.audit = module.analyse(write=False)

    def test_original_bodies_integrity_and_failed_new_returns(self):
        self.assertEqual(self.audit['receiptBodiesHashed'], 6)
        self.assertEqual(self.audit['originalBodiesRevalidated'], 3)
        self.assertEqual(self.audit['newCollectorCalls'], 3)
        self.assertEqual(self.audit['newUsableBodies'], 0)
        self.assertEqual(self.audit['networkCallsDuringAnalysis'], 0)
        for row in self.audit['receipts'][3:]:
            self.assertFalse(row['usableForReading'])
            self.assertFalse(row['failureCountsAsDocxOrClinicalEvidence'])

    def test_chronological_order_matches_original_sessions(self):
        components = self.package['componentsInSourceSessionOrder']
        expected = sorted(self.original['instructionRecords'], key=lambda i:i['session'])
        self.assertEqual([i['session'] for i in components], list(range(1,9)))
        self.assertEqual([i['sourceInstructionId'] for i in components], [i['id'] for i in expected])
        for item in components:
            actual = self.original
            document = {'sources':[actual]}
            for part in item['sourceReadingPointer'].strip('/').split('/'):
                document = document[int(part)] if isinstance(document,list) else document[part]
            self.assertEqual(document['id'], item['sourceInstructionId'])
            self.assertEqual(item['pdfPages'], document['pdfPages'])
            self.assertTrue(item['endingAndInstructionReceived'])
            self.assertFalse(item['standaloneClaimApproved'])

    def test_programme_not_reduced_to_eight_independent_therapies(self):
        boundary = self.package['programmeBoundary']
        self.assertEqual(boundary['sessions'], 8)
        self.assertEqual(boundary['weeksRange'], [8,14])
        self.assertEqual(boundary['adherenceThresholdSessions'], 5)
        self.assertFalse(boundary['adherenceThresholdIsShorterPrescribedProgramme'])
        self.assertFalse(boundary['programmeResultsAreIsolatedComponentResults'])
        self.assertFalse(boundary['eightIndexedComponentsAreDailyEightExerciseCircuit'])
        self.assertFalse(self.package['clinicalEvidence']['evidenceCopiedToIndependentTechniqueOrNewApkProgramme'])

    def test_signal_and_stretch_keep_specific_source_dose(self):
        items = {i['sourceInstructionId']:i for i in self.package['componentsInSourceSessionOrder']}
        self.assertEqual(items['START-SIGNAL']['doseFacts']['holdSecondsRange'], [2,3])
        self.assertEqual(items['START-SIGNAL']['doseFacts']['maxRepetitionsPerOccasion'], 3)
        stretch = items['START-STRETCH']
        self.assertEqual(stretch['doseFacts']['initialPauseSeconds'], 2)
        self.assertEqual(stretch['doseFacts']['armSequencePasses'], 2)
        self.assertFalse(stretch['secondFullExecutionMandatory'])
        self.assertFalse(stretch['staticThirtySecondHoldImported'])
        self.assertTrue(stretch['originalSeatedOrStandingChoice'])

    def test_grounding_pauses_are_not_global_muscle_hold_timers(self):
        item = next(i for i in self.package['componentsInSourceSessionOrder'] if i['sourceInstructionId']=='START-GROUNDING')
        self.assertEqual(item['eyes'], 'abertos')
        self.assertEqual(item['scriptPauses']['secondsInOrder'], [10,10,10,10,30,30,15,20,7,7,15,5,5,5])
        self.assertFalse(item['scriptPauses']['sumIsWholePracticeDuration'])
        self.assertTrue(item['scriptPauses']['someApproximateAndAdditionalUntimedPauses'])
        self.assertTrue(all(i['wholePracticeMinutes'] is None for i in self.package['componentsInSourceSessionOrder']))

    def test_audio_format_options_do_not_grant_rights_or_replace_support(self):
        assets = self.package['materialsAndRights']
        self.assertEqual(assets['explicitFormatOptions'], ['CD','fita','MP3'])
        self.assertFalse(assets['formatChoiceIsPermissionToCopyOrReplaceAudioContent'])
        self.assertFalse(assets['originalStudyAudioReceived'])
        self.assertFalse(assets['futureMaterialsReadyOrSubstitutesApproved'])
        self.assertFalse(assets['commercialManualTranslationOrAudioReproductionApproved'])
        self.assertFalse(self.package['delivery']['apkOrAiReplacesTherapistSupervisionOrRiskManagement'])
        self.assertFalse(self.package['releaseApproved'])
        self.assertFalse(self.package['appImplemented'])

    def test_older_caregiver_assessment_not_automatic_diagnosis(self):
        eligibility = self.package['populationAndEligibility']
        self.assertFalse(eligibility['mmseIsAutomaticApkDiagnosisOrUniversalContraindication'])
        self.assertFalse(eligibility['researchTravelRadiusIsUniversalMedicalContraindication'])
        self.assertFalse(eligibility['universalAgeRangeInvented'])
        self.assertFalse(self.package['safetyAndInterruption']['alternativeTechniqueOrPostureAutomaticallySelectedByApk'])

    def test_scope_is_factual_not_whole_course_release(self):
        self.assertTrue(self.package['researchItemClosed'])
        self.assertFalse(self.package['programmeBoundary']['allTherapeuticPagesReviewedOrApkCourseApproved'])
        self.assertFalse(self.package['source']['currentSevenTranscriptWebListingMerged'])
        self.assertFalse(self.package['materialsAndRights']['researchClosureApprovesWholeCourseOrUnknownAssets'])
        self.assertTrue(self.package['publicationPrerequisites'])


if __name__=='__main__':
    unittest.main()
