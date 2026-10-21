import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
DAY = ROOT / '2026-10-07'


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))


class CompatibleSettingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.decision = read('2026-10-07/n15c-ambiente-compativel/decisao.json')
        cls.atac = read('2026-10-07/n15c-alongamento-profissional/leitura-fontes.json')
        cls.dance = read('2026-10-07/n15c-dancecare/leitura-fontes.json')
        cls.montero = read('2026-10-07/n15c-ambiente-compativel/leitura-montero.json')
        cls.revieew = read('2026-10-07/n15c-programa/leitura-programa.json')
        spec = importlib.util.spec_from_file_location('compatible_receipts', ROOT / 'analisar-n15c-manuais.py')
        cls.receipts = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.receipts)

    def test_global_rule_not_literal_venue_or_dose_change(self):
        self.assertFalse(self.decision['studyStrictlyAtHomeRequired'])
        self.assertTrue(self.decision['sourceExerciseMustRemainUnchanged'])
        self.assertEqual(len(self.decision['compatibilityDimensions']), 6)
        self.assertEqual(len(self.decision['separateClaims']), 3)
        self.assertFalse(self.decision['priorResearchReevaluation']['allPriorItemsReevaluated'])
        self.assertFalse(self.decision['n21Started'])

    def test_received_originals_rehash_and_failed_body_is_not_article(self):
        expected = {'n15c-alongamento-profissional': (5, 5, 5),
                    'n15c-dancecare': (5, 5, 5), 'n15c-ambiente-compativel': (2, 1, 2)}
        for folder, counts in expected.items():
            path = DAY / folder
            plan = json.loads((path / 'requisicoes.json').read_text(encoding='utf-8'))
            checked = [self.receipts.check_receipt(path / (s['id'] + '.evidencia.json'), ROOT)
                       for s in plan['requests']]
            self.assertEqual((len(checked), sum(s['usable'] for s in checked),
                              sum(s['bodyVerified'] for s in checked)), counts)
        failed = read('2026-10-07/n15c-ambiente-compativel/c15-kamioka2011-xml.evidencia.json')
        self.assertEqual((failed['status'], failed['bytes']), (500, 0))

    def test_duplicate_atac_does_not_create_new_family_or_version(self):
        pairs = [('c15-atac2024-xml', 'c15-atac-alongamento-2024-xml'),
                 ('c15-atac2026-correcao-xml', 'c15-atac-correcao-2026-xml')]
        for current, prior in pairs:
            new = read('2026-10-07/n15c-alongamento-profissional/' + current + '.evidencia.json')
            old = read('2026-10-04/n15c-retomada/' + prior + '.evidencia.json')
            self.assertEqual((new['url'], new['sha256'], new['bytes']),
                             (old['url'], old['sha256'], old['bytes']))
        self.assertEqual(self.atac['sourceId'], 'PR42')
        self.assertEqual(self.atac['duplicateRetrievalAudit']['newIndependentArticleVersions'], 0)

    def test_static_and_pnf_not_merged_or_shortened(self):
        static, pnf = self.atac['records']
        dose = static['dose']
        self.assertEqual(dose['secondsPerRepetition'] * dose['repetitionsPerLeg'] * 2, 480)
        self.assertEqual(dose['minutesBothLegs'], 8)
        self.assertIn('nao65%de1RM', pnf['execution'])
        self.assertFalse(self.atac['trialReconciliation']['pnfRestConflictResolved'])
        self.assertFalse(self.atac['settingReevaluation']['fatigueOrTimeAuthorisesDoseReduction'])
        self.assertEqual(self.atac['population']['ageRange'], [18, 40])

    def test_atac_credentials_not_cross_trial_exercise_or_prospective_registration(self):
        p = self.atac['professionalAuthorship']
        self.assertTrue(p['sourceDeclaredIndividualProfessionalQualificationVerified'])
        self.assertFalse(p['individualDiplomaOrLegalProfessionalRegistrationVerified'])
        self.assertTrue(p['professionalQualificationSource']['differentTrialProvidesQualificationOnly'])
        self.assertTrue(self.atac['trialReconciliation']['registrationAfterReportedArticleCollection'])
        self.assertFalse(self.atac['evidenceBasis']['lungVolumeImprovementDemonstrated'])

    def test_dance_planned_population_not_clinical_result(self):
        e = self.dance['evidenceBasis']
        self.assertEqual((e['plannedCaregivers'], e['plannedCaregiversPerCountry']), (90, 30))
        self.assertFalse(e['plannedCountsAreAchievedEnrollment'])
        self.assertFalse(e['publishedQuantitativeClinicalEffectivenessResultsReceived'])
        self.assertFalse(e['manualFeedbackIsControlledClinicalOutcome'])

    def test_dance_phases_not_four_solo_prescriptions(self):
        session = self.dance['records'][0]
        self.assertEqual(sum(p['minutes'] for p in session['structure']), 90)
        self.assertFalse(session['fourPhasesAreFourValidatedStandaloneRoutines'])
        self.assertIsNone(session['homeIndependentDose'])
        self.assertTrue(session['sourceEndingPresent'])
        self.assertFalse(self.dance['settingCompatibility']['soloHomeExecutionOfAllGroupExercisesEquivalent'])
        self.assertTrue(self.dance['delivery']['sourceSupportsHomeContinuation'])
        self.assertFalse(self.dance['delivery']['apkReplacesFacilitator'])

    def test_dance_actual_visual_pages_not_render_count_or_asset_permission(self):
        originals = self.dance['originals']
        self.assertEqual(sum(len(originals[k]['visualPages']) for k in ['handbook', 'guidelines']), 13)
        self.assertFalse(originals['wholeManualVisuallyReviewed'])
        self.assertFalse(self.dance['rights']['euFundingGrantsAllAssetsReuse'])
        self.assertFalse(self.dance['rights']['commercialProgrammeImportApproved'])
        self.assertFalse(self.dance['records'][0]['videoViewed'])

    def test_revieew_compatible_space_not_remove_live_support_or_invent_calendar(self):
        r = self.revieew['settingReevaluation']
        self.assertTrue(r['workplaceDoesNotExcludeOtherCompatibleSpace'])
        self.assertTrue(r['sameProfessionalSupervisionRequired'])
        self.assertFalse(r['complete24DistinctSessionRecipesAreNecessary'])
        self.assertFalse(r['generatedCalendarApproved'])
        self.assertFalse(r['trialAtHomeProven'])
        self.assertFalse(self.revieew['originalExamples']['examplesAreBeginnerSessions'])
        self.assertEqual(len(self.revieew['sourceWeeklyWorkRestSeconds']), 12)

    def test_montero_results_not_gesture_instructions_or_appendix_manual(self):
        p = self.montero['population']
        self.assertEqual((p['analysed'], p['controlAnalysed'], p['exerciseAnalysed']), (62, 30, 32))
        self.assertEqual(p['minimumAgeExclusive'], 50)
        self.assertFalse(self.montero['programme']['appendixAIsExerciseManual'])
        self.assertFalse(self.montero['programme']['individualMovementInstructionsAndDoseReceived'])
        self.assertFalse(self.montero['programme']['borgScaleIsCr10'])
        self.assertTrue(self.montero['professionalDelivery']['regularBloodPressureChecks'])
        self.assertFalse(self.montero['evidence']['noRecordedEffectsIsZeroRisk'])
        self.assertFalse(self.montero['settingCompatibility']['homeEfficacyDemonstrated'])

    def test_partial_revalidation_and_no_closure(self):
        review = read('2026-10-07/n15c-ambiente-compativel/revalidacao-n15.json')
        self.assertEqual(len(review['reviewedFamilies']), 6)
        self.assertFalse(review['allN15FamiliesReevaluated'])
        self.assertFalse(review['allOtherPreviousNichesReevaluated'])
        for s in [self.atac, self.dance, self.montero]:
            selection = s.get('selection', s)
            self.assertFalse(selection.get('researchClosureApproved', s.get('researchClosureApproved', False)))
        fiche = read('2026-10-04/n15c-retomada/pesquisa-complemento.json')
        records = [s['record'] for s in fiche['evidence']]
        self.assertEqual(len(records), len(set(records)))
        self.assertFalse(fiche['researchClosureApproved'])
        self.assertFalse(fiche['releaseApproved'])


if __name__ == '__main__':
    unittest.main()
