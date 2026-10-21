"""Retain Pilates' source discrepancies and professional delivery requirements."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('pilates_focal', ROOT / 'analisar-cg05-pilates.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PilatesFocalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.p = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        cls.audit = module.analyse(write=False)
        cls.original = json.loads((ROOT / '2026-10-11/n15c-pilates-cuidadores/leitura-fontes.json').read_text(encoding='utf-8'))['sources'][1]

    def test_primary_integrity_metadata_and_failed_returns(self):
        self.assertEqual([self.audit['originalBodiesRevalidated'],self.audit['newCollectorCalls'],self.audit['newUsableBodies'],self.audit['receiptBodiesHashed']], [6,4,2,10])
        self.assertEqual(self.audit['networkCallsDuringAnalysis'], 0)
        self.assertFalse(self.audit['publisherFullArticleBodyLocallyReceived'])
        failures = [r for r in self.audit['receipts'] if not r['usableForReading']]
        self.assertEqual(len(failures),2)
        self.assertTrue(all(r['status']==403 and not r['failedBodyIsInstruction'] for r in failures))

    def test_dose_is_whole_programme_not_invented_fatigue_reduction(self):
        d = self.p['dose']
        self.assertEqual([d['weeks'],d['sessionsPerWeek'],d['sessionsTotal'],d['sets'],d['repetitionsPerExercise']], [8,2,16,1,10])
        self.assertEqual(d['sessionMinutesRange'], [45,60])
        self.assertEqual(d['mainMinutesRange'], [35,50])
        self.assertFalse(d['minimumMaximumSessionChosenAutomaticallyForFatigue'])
        self.assertIsNone(d['restSecondsBetweenExercisesPrescribed'])
        self.assertFalse(d['assessmentMaximumEffortTestsImportedAsWorkout'])

    def test_familiarisation_two_days_is_not_every_session_interval(self):
        d = self.p['delivery']
        self.assertEqual(d['publishedDaysBetweenFamiliarisationAndClasses'],2)
        self.assertIsNone(self.p['dose']['minimumHoursBetweenEverySessionPrescribed'])
        self.assertEqual(len(d['keyElements']),5)
        self.assertTrue(d['initialTeachingAndFamiliarisationRequired'])
        self.assertTrue(d['physiotherapistWithClinicalPilatesTrainingRequired'])
        self.assertFalse(d['photosOrApkReplaceProfessionalTeaching'])

    def test_calendar_versions_not_silently_reconciled(self):
        p = self.p['progressionVersionDecision']
        self.assertEqual(p['narrativeProgressionWeeks'],self.original['programme']['progressionNarrativeWeeks'])
        self.assertEqual(p['thesisTableWeekRanges'],self.original['programme']['tablePhaseWeekRanges'])
        self.assertEqual(p['publishedStageBoundariesWeeks'],[[0,3],[3,6],[6,8]])
        self.assertFalse(p['thesisInternalDiscrepancyCorrected'])
        self.assertFalse(p['automaticExecutionCalendarApproved'])
        self.assertIsNone(p['exactTransitionSessionNumbersPublished'])

    def test_stage_indices_are_not_independent_exercises_or_session_blocks(self):
        p = self.p['programme']
        self.assertEqual(p['progressionStages'],3)
        self.assertFalse(p['progressionStagesAreSessionBlocks'])
        self.assertFalse(p['parenthesisedNumbersAreRepetitionOrSetDose'])
        self.assertEqual(p['warmupSourceOrder'],self.original['programme']['warmupOrder'])
        self.assertEqual(p['cooldownSourceOrder'],self.original['programme']['cooldownOrder'])
        self.assertTrue(all(not p['phase'+str(i)]['standaloneClaimApproved'] for i in range(1,4)))

    def test_instruction_gaps_and_human_adjustments_remain_visible(self):
        i = self.p['instructionEvidence']
        self.assertFalse(i['publishedAllMovementStepScriptsReceived'])
        self.assertFalse(i['photosAreFullInstructions'])
        self.assertFalse(i['newInstructionsGeneratedByAi'])
        self.assertTrue(i['professionalMustProvideClearFaithfulInstructionBeforePractice'])
        self.assertFalse(self.p['safetyAndReturn']['apkOrAiSelectsAdjustmentInsteadOfProfessional'])
        self.assertFalse(self.p['safetyAndReturn']['newAlternativeExerciseOrCompensationDoseCreated'])

    def test_web_reading_not_fake_local_body_or_commercial_licence(self):
        self.assertFalse(self.p['source']['primaryWebReading2021']['fullRawArticleLocallyReceived'])
        self.assertFalse(self.p['source']['primaryWebReading2021']['webObservationHasInventedBodySha256'])
        r = self.p['materialsAndRights']
        self.assertIsNone(r['crossrefLicenceEntry'])
        self.assertFalse(r['currentPublisherFreeAccessIsCommercialLicence'])
        self.assertFalse(r['depositLicenceIsTrainForgePublicReuseGrant'])
        self.assertFalse(r['commercialPhotosAudioTranslationOrGuidesApproved'])

    def test_clinical_results_not_universal_or_independent_pose_proof(self):
        e = self.p['clinicalEvidence']
        self.assertEqual([e['originalThesisRandomised'],e['intervention'],e['control']],[55,28,27])
        self.assertEqual(e['fatigueThesis']['interventionPostMean'],2.8)
        self.assertEqual(e['sixMinuteWalkBetweenPostP'],0.10)
        self.assertFalse(e['pPrintedZeroMeansExactProbabilityZero'])
        self.assertFalse(e['programmeBenefitAssignedToIndividualPhaseOrPose'])
        self.assertTrue(e['companionPublication']['sameCohortIsInferenceNotDirectNctVerification'])
        self.assertFalse(e['companionPublication']['independentReplicationEstablished'])

    def test_setting_population_and_equipment_preserved(self):
        self.assertEqual(self.p['population']['ageRangeFromThesisAndRegistry'],[18,55])
        self.assertTrue(self.p['population']['publicationOnlyOneChildCriterionObserved'])
        self.assertEqual(self.p['materialsAndEnvironment']['exerciseBallDiameterCmFromThesisRegistry'],65)
        self.assertIsNone(self.p['materialsAndEnvironment']['resistanceKgPrescribed'])
        self.assertFalse(self.p['materialsAndEnvironment']['homeOrCentreExcludedJustByLiteralName'])
        self.assertFalse(self.p['materialsAndEnvironment']['fatigueOutcomeAllowsShorterSessionWithoutEvidence'])

    def test_scoped_closure_does_not_close_n15_or_publish(self):
        self.assertTrue(self.p['researchItemClosed'])
        self.assertFalse(self.p['closureEvidence']['fiveScopedItemsClosedMeansGlobalN15Closed'])
        self.assertFalse(self.p['releaseApproved'])
        self.assertFalse(self.p['appImplemented'])
        self.assertTrue(self.p['publicationPrerequisites'])


if __name__=='__main__':
    unittest.main()
