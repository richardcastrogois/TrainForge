"""Regressoes documentais N15-C, sem rede ou aprovacao clinica/APP."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-08/n15c-originais-caser'
spec = importlib.util.spec_from_file_location('n15_caser', ROOT / 'analisar-n15c-originais-caser.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class CaserOriginalsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.inventory = audit.analyse(False)

    def test_received_bytes_status_and_hash_not_search_snippet(self):
        d = self.inventory
        self.assertEqual((d['newCollectorCalls'], d['http200Responses'],
                          d['usableBodies'], d['hashedBodies']), (17, 13, 13, 17))
        failed = [r for r in d['sources'] if r['status'] == 404]
        self.assertEqual(len(failed), 2)
        self.assertTrue(all(r['bodyVerified'] and not r['usable'] for r in failed))
        self.assertEqual(d['pdfs']['c15-caser2018-pdf']['pages'], 24)
        self.assertEqual(d['pdfs']['c15-usc-cuidate-capitulo-pdf']['pages'], 38)
        self.assertTrue(all(c['matched'] for c in d['anchorChecks']))

    def test_named_qualifications_are_not_independent_licensure(self):
        p = self.reading['caser2018LinkedToPR85']['professionalAuthorship']
        self.assertTrue(p['qualificationVerifiedInPrimaryPublishedText'])
        self.assertEqual(len(p['sourceDeclaredNamedQualifications']), 6)
        self.assertFalse(p['independentDiplomaOrClinicalRegistrationVerified'])

    def test_session_model_not_full_exercises_or_twenty_five_session_dose(self):
        p = self.reading['caser2018LinkedToPR85']['programme']
        self.assertEqual((p['weeks'], p['sessionsPerWeek'], p['plannedSessions']), (12, 3, 36))
        self.assertEqual(p['warmupMinutesRange'], [10, 15])
        self.assertEqual(p['cooldownMinutes'], 10)
        self.assertEqual(p['minimumSessionsForAnalysis'], 25)
        self.assertFalse(p['analysisThresholdIsApprovedDoseReduction'])
        self.assertIsNone(p['perMovementSteps'])
        self.assertIsNone(p['perMovementDose'])
        self.assertFalse(p['derivedRangeIsPrescribedAlternativeDuration'])

    def test_versions_not_silently_merged_or_independent_trials(self):
        p = self.reading['caser2018LinkedToPR85']
        self.assertEqual(p['population']['includedAgeExclusive'], 18)
        self.assertEqual(p['population']['observedAgeRange'], [47, 76])
        self.assertEqual(p['versionReconciliation']['independentTrialCountIncrement'], 0)
        self.assertTrue(p['versionReconciliation']['overlapIsInferenceNotConfirmedIdentifierMatch'])
        self.assertFalse(p['versionReconciliation']['silentVersionMergeAllowed'])
        self.assertEqual(p['results']['depressionBetweenGroupCohenD'], -1.37)
        self.assertFalse(p['results']['eachGestureEfficacyProven'])

    def test_open_chapter_qualitative_not_operational_clinical_trial(self):
        p = self.reading['usc2020']
        self.assertEqual((p['population']['sample'], p['population']['observedAgeRange']), (60, [24, 84]))
        self.assertTrue(p['rights']['explicitGrantVerifiedInReceivedPdf'])
        self.assertFalse(p['design']['clinicalControlledTrial'])
        self.assertFalse(p['design']['reported99PercentWellbeingIsClinicalEfficacy'])
        self.assertFalse(p['content']['sourceSaysWhichBreathingTechnique'])
        self.assertIsNone(p['content']['doseMinutes'])
        self.assertFalse(p['spanish2016CuidateBookSameWork'])

    def test_rights_and_failed_request_do_not_create_missing_assets(self):
        p = self.reading['caser2018LinkedToPR85']['rights']
        self.assertFalse(p['article2020CCBYAutomaticallyCoversThis2018Publication'])
        self.assertFalse(p['commercialGrantEstablished'])
        self.assertTrue(p['factsAndScientificFindingsAreNotBlanketCopyrightBan'])
        self.assertEqual(len(self.reading['retainedFailures']), 4)
        self.assertFalse(self.reading['existingAtacReceiptRechecked']['registryDocumentSectionPresent'])
        self.assertFalse(self.reading['existingAtacReceiptRechecked']['stepHeightOrFreeAreaAbsenceAloneIsAutomaticRejection'])

    def test_aggregate_fiche_and_map_retain_open_gates(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertGreaterEqual(len(fiche['evidence']), 121)
        self.assertGreaterEqual(len(fiche['dependencies']), 59)
        round_records = {r['record'] for r in self.inventory['sources'] if r['usable']}
        self.assertTrue(round_records.issubset({r['record'] for r in fiche['evidence']}))
        self.assertEqual(fiche['latestSupplementRound'], '2026-10-08/n15c-originais-caser/leitura-fontes.json')
        self.assertFalse(fiche['researchClosureApproved'])
        self.assertFalse(fiche['releaseApproved'])
        mapping = json.loads((ROUND / 'mapa-apk-campos.json').read_text(encoding='utf-8'))
        self.assertFalse(mapping['runtimeImportCreated'])
        self.assertFalse(mapping['n21Started'])
        catalogue = json.loads((ROOT.parent / 'fontes.json').read_text(encoding='utf-8'))
        chapter = next(s for s in catalogue['sources'] if s['id'] == 'PR92')
        self.assertEqual(chapter['status'], 'referencia')
        self.assertEqual(chapter['localEvidence'], 'evidencias/2026-10-08/n15c-originais-caser/leitura-fontes.json')

    def test_fast_not_excluded_by_literal_gym_or_user_membership_cost(self):
        p = self.reading['fast2021']
        self.assertTrue(p['settingRevalidation']['previousLiteralHomeFreeGymFilterNotRetained'])
        self.assertFalse(p['settingRevalidation']['costOfUsersGymIsSameAsRightsFeeForAppContent'])
        self.assertTrue(p['professionalAuthorship']['primaryTextDeclaresPhysicianDesignedProject'])
        self.assertFalse(p['delivery']['coachMayBeRemovedBecauseApkShowsSteps'])
        self.assertEqual((p['programme']['weeks'], p['programme']['targetReachedWeek']), (24, 9))
        self.assertFalse(p['programme']['automaticLinearInterpolationAllowed'])
        self.assertEqual(p['independentTrialCountIncrementFromSecondaryPublication'], 0)

    def test_fast_registry_versions_results_and_missing_manual_kept_distinct(self):
        p = self.reading['fast2021']
        self.assertEqual(len(p['registry']['sourceDifferencesPreserved']), 3)
        self.assertFalse(p['registry']['silentVersionMergeAllowed'])
        self.assertFalse(p['registry']['documentSectionPresent'])
        self.assertTrue(p['registry']['articleClinicalResultsStillReceivedSeparately'])
        self.assertEqual(p['results']['stressorOccurrenceTreatmentEffectP'], 0.93)
        self.assertFalse(p['results']['stressorOccurrenceImprovedBetweenGroups'])
        self.assertIsNone(p['programme']['specificExerciseModeAndIndividualStepsInThisBody'])

    def test_fast_osf_lists_not_dataset_download_or_commercial_grant(self):
        p = self.reading['fast2021']['osf']
        self.assertEqual((p['rootFolderCount'], p['listedChildren'], len(p['filesListed'])), (1, 0, 2))
        self.assertIsNone(p['projectLicense'])
        self.assertFalse(p['participantDatasetsOrSyntaxDownloaded'])
        self.assertFalse(p['absenceInAllOtherRepositoriesProven'])
        self.assertEqual(self.inventory['fastMetadataChecks']['c15-fast-osf-pasta-json']['count'], 2)
        self.assertFalse(self.inventory['fastMetadataChecks']['registry']['documentSectionPresent'])

    def test_dbe_home_training_not_complete_rhythm_or_all_caregivers(self):
        p = self.reading['dbe2026']
        self.assertEqual((p['population']['randomized'], p['population']['breathingArm'], p['population']['vnsArm']), (39, 20, 19))
        self.assertTrue(p['programme']['continuedAtHomeInRegistry'])
        self.assertIsNone(p['programme']['inspirationSeconds'])
        self.assertIsNone(p['programme']['sessionMinutes'])
        self.assertFalse(p['population']['generaliseToAllCaregiversOrOlderCarers'])
        self.assertFalse(p['programme']['vnsIsAnApkExerciseForSelfUse'])

    def test_dbe_active_comparator_not_causal_placebo_or_open_licence(self):
        p = self.reading['dbe2026']
        self.assertFalse(p['results']['withinGroupImprovementProvesCausalEffectVsNoIntervention'])
        self.assertFalse(p['results']['nonSignificanceMeansDemonstratedEquivalence'])
        self.assertFalse(p['results']['painSignificantBetweenGroupChange'])
        self.assertTrue(p['registry']['retrospectivelyRegistered'])
        self.assertFalse(p['fullArticleReceived'])
        self.assertEqual(p['rights']['europepmcIsOpenAccess'], 'N')

    def test_revieew_registry_not_manual_results_or_removal_of_cointervention(self):
        p = self.reading['revieewRegistryRecheckedPR68']
        self.assertFalse(p['documentSectionPresent'])
        self.assertFalse(p['originalMovementManualOrVideoLinksFound'])
        self.assertEqual(p['dose']['exercisesPerSession'], 6)
        self.assertFalse(p['versionBoundary']['registrySixExercisesPerSessionIsWholeCatalogueSize'])
        self.assertTrue(p['versionBoundary']['routinePreventionTrainingNotEliminatedFromPublishedStudy'])
        self.assertTrue(p['publishedArticleResultsAndAnnexesAlreadyReceivedIndependently'])


if __name__ == '__main__':
    unittest.main()
