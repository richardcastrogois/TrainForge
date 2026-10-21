"""Keep ReViEEW's professional delivery and missing autonomous scripts explicit."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('revieew_focal', ROOT / 'analisar-cg04-revieew.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RevieewFocalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.p = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        cls.audit = module.analyse(write=False)
        cls.original = json.loads((ROOT / '2026-10-07/n15c-programa/leitura-programa.json').read_text(encoding='utf-8'))

    def test_integrity_originals_and_first_registry_get(self):
        self.assertEqual(self.audit['originalBodiesRevalidated'], 10)
        self.assertEqual(self.audit['receiptBodiesHashed'], 11)
        self.assertEqual(self.audit['newCollectorCalls'], 1)
        self.assertEqual(self.audit['newUsableBodies'], 1)
        self.assertEqual(self.audit['preflightFailureBeforeNetworking']['networkCalls'], 0)
        self.assertEqual(self.audit['networkCallsDuringAnalysis'], 0)

    def test_registry_is_plan_not_missing_execution_media(self):
        r = self.audit['registry']
        self.assertEqual(r['id'], 'NCT05050526')
        self.assertEqual(r['enrollment']['count'], 130)
        self.assertFalse(r['hasResults'])
        self.assertFalse(r['hasDocumentSection'])
        self.assertFalse(r['registryNoInterventionControlOverridesExecutedPaper'])

    def test_variants_preserve_executed_figure_labels(self):
        i = self.p['instructionEvidence']
        self.assertEqual(i['exerciseCount'], 9)
        self.assertEqual(sum(len(v['levels']) for v in i['variants']), 27)
        v = {v['id']:v for v in i['variants']}
        self.assertIn('3s isometric hold', v['CG-04-SQUAT']['levels'][2])
        self.assertEqual(v['CG-04-REVERSE_LUNGE']['levels'][2], 'Dynamic +2.6kg band')
        self.assertTrue(all(not v['standaloneClaimApproved'] for v in i['variants']))
        self.assertFalse(i['completeAutonomousStepScriptsReceived'])

    def test_dose_and_ending_categories_without_invented_scripts(self):
        d = self.p['programmeDose']
        self.assertEqual([d['weeks'],d['sessionsPerWeek'],d['statedMinutesPerSession'],d['minimumIntervalHours']], [12,2,45,48])
        self.assertEqual(d['effortRange'], [3,5])
        self.assertTrue(d['mustNotReachFailure'])
        self.assertFalse(d['assessmentTestsUntilFailureImportedIntoWorkout'])
        self.assertFalse(d['warmup']['exactMovementSequenceReceived'])
        self.assertFalse(d['cooldown']['exactMovementSequenceReceived'])
        self.assertFalse(d['newWarmupOrCooldownMovementsAuthoredByAi'])
        self.assertIsNone(d['repetitionCountPerTimedExercisePublished'])

    def test_progressions_match_original_and_require_human_review(self):
        p = self.p['progression']
        self.assertEqual(p['weeklyWorkRestSeconds'], [[r['work'],r['rest']] for r in self.original['sourceWeeklyWorkRestSeconds']])
        self.assertEqual(p['minimumCompletedPreviousLevelSessions'], 4)
        self.assertEqual(p['startLevel'], 1)
        self.assertFalse(p['fourSessionsAloneForceAutomaticProgression'])

    def test_pain_adjustment_in_source_is_not_ai_algorithm(self):
        s = self.p['safetyAndInterruption']
        self.assertEqual(len(s['intolerablePainAdjustmentStagesInPublishedOrder']), 4)
        self.assertIn('interromper', s['intolerablePainAdjustmentStagesInPublishedOrder'][3])
        row = next(r for r in self.audit['receipts'] if r['id']=='c15-revieew-protocolo-pdf')
        self.assertIn('reduce loading', row['selectedPagesText']['6'])
        self.assertFalse(s['specificAlternativeExerciseInvented'])
        self.assertFalse(s['resumeThresholdOrCompensationDoseInvented'])
        self.assertEqual([s['originalMinorTechnicalAffectedSessions'],s['originalMinorHealthAffectedSessions']], [31,24])
        self.assertFalse(s['adverseEventCountsAreParticipantCounts'])

    def test_live_professional_not_replaced_by_pictures_or_apk(self):
        d = self.p['delivery']
        self.assertTrue(d['experiencedPhysicalTherapistDeliveredOriginalTrial'])
        self.assertTrue(d['liveBidirectionalAudioAndVideoRequired'])
        self.assertFalse(d['actualProviderAvailableInApkAssumed'])
        self.assertFalse(d['photosAloneProvideCompleteSafetyInstructions'])
        self.assertFalse(d['writtenStepScriptOrOriginalPrivateVideoRecovered'])
        self.assertFalse(d['aiSelectsOrCorrectsExecutionInsteadOfProfessional'])

    def test_original_trial_and_later_analysis_not_equated(self):
        e = self.p['clinicalEvidence']
        self.assertEqual(e['ittAverageLowBackPain']['groupTimeP'], 0.034)
        self.assertEqual(e['followup']['averagePainGroupTimeP'], 0.140)
        self.assertFalse(e['followup']['autonomousHomeMaintenanceEstablished'])
        self.assertFalse(e['programmeBenefitAssignedToIndividualVariant'])
        self.assertFalse(e['registryOrProtocolNoInterventionControlReplacesExecutedControl'])
        self.assertFalse(e['perProtocolFiftyPercentAdherenceIsHalfDosePrescription'])
        self.assertFalse(e['adherence2026']['independentRCT'])

    def test_figures_are_not_circuit_calendar_or_universal_band_colours(self):
        self.assertFalse(self.p['instructionEvidence']['photoOrderIsPrescribedCircuitOrder'])
        self.assertFalse(self.p['sequence']['examplesAreBeginnerSessions'])
        self.assertEqual(self.p['sequence']['newSessionsOrCalendarCreatedByAi'], 0)
        self.assertFalse(self.p['materialsAndEnvironment']['bandColourIsUniversalResistanceIdentifier'])
        self.assertFalse(self.p['materialsAndEnvironment']['fatigueAuthorisesShorterValidatedDose'])

    def test_scoped_research_closure_is_not_complete_autonomous_guide(self):
        self.assertTrue(self.p['researchItemClosed'])
        self.assertFalse(self.p['closureEvidence']['fullAutonomousExecutionGuidesReceived'])
        self.assertFalse(self.p['closureEvidence']['newOriginalExecutionMaterialRecovered'])
        self.assertFalse(self.p['materialsAndRights']['rightsOfPrivateMaintenanceVideosInherited'])
        self.assertFalse(self.p['materialsAndRights']['originalWrittenMaintenanceInstructionsReceived'])
        self.assertTrue(self.p['publicationPrerequisites'])
        self.assertFalse(self.p['releaseApproved'])
        self.assertFalse(self.p['appImplemented'])


if __name__ == '__main__':
    unittest.main()
