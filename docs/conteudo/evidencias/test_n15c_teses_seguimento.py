import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-teses-seguimento'


class ThesisFollowupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.families = {s['sourceId']: s for s in cls.reading['families']}
        spec = importlib.util.spec_from_file_location('followup_analysis', ROOT / 'analisar-n15c-teses-seguimento.py')
        cls.analyser = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.analyser)

    def test_receipts_rehashed_and_error_bodies_not_scientific_content(self):
        checked = [self.analyser.receipts.check_receipt(p, ROOT)
                   for p in ROUND.glob('*.evidencia.json')]
        self.assertEqual(len(checked), 30)
        self.assertEqual(sum(s['status'] == 200 for s in checked), 19)
        self.assertEqual(sum(s['usable'] for s in checked), 18)
        self.assertEqual(sum(s['bodyVerified'] for s in checked), 26)
        js = next(s for s in checked if s['id'] == 'c15-crea-editorial-script-text')
        self.assertEqual(js['status'], 200)
        self.assertFalse(js['bodyVerified'])
        self.assertFalse(js['usable'])
        self.assertFalse(next(s for s in checked if s['id'] == 'c15-hives2021-aerobico-xml')['usable'])

    def test_followup_not_positive_or_independent_programme(self):
        r = self.reading['followupReViEEW']
        self.assertEqual(r['sourceId'], 'PR68')
        self.assertEqual(r['pmid'], '40561221')
        self.assertIn('P=0.140', r['primaryFinding'])
        self.assertFalse(r['fullArticleReceived'])
        self.assertFalse(r['longTermAveragePainBenefitEstablished'])
        self.assertFalse(r['autonomousHomeMaintenanceProven'])
        self.assertFalse(r['invalidatesInitialTwelveWeekResults'])

    def test_adherence_observational_not_new_trial_dose_cut_or_medication_rule(self):
        r = self.reading['adherenceReViEEW2026']
        self.assertEqual((r['sourceId'], r['participants']), ('PR68', 105))
        self.assertTrue(r['includesOriginalAndLaterWaitlistExerciseWaves'])
        self.assertFalse(r['independentNewRandomizedTrial'])
        self.assertFalse(r['causalRelationshipsEstablished'])
        self.assertFalse(r['homeCareWorkersWereExercisingAtIndividualHomes'])
        self.assertFalse(r['borderlinePValueIsDefinitiveSelectionRule'])
        self.assertFalse(r['newDetailedWarmupCooldownOrVideosReceived'])

    def test_declared_degree_not_independent_licence_or_new_capture(self):
        r = self.reading['reViEEWDegreeCorrection']
        self.assertTrue(r['individualProfessionalQualificationExplicit'])
        self.assertFalse(r['newNetworkCall'])
        self.assertFalse(r['independentDiplomaOrLegalRegistrationVerified'])
        p = json.loads((ROOT / r['previousReceipt']).read_text(encoding='utf-8'))
        path = (ROOT / r['previousReceipt']).parent / p['bodyFile']
        self.assertIn('Graduado en Fisioterapia', path.read_text(encoding='utf-8'))

    def test_palliative_audio_and_noncommercial_no_import(self):
        s = self.families['PR86']
        self.assertEqual(s['dose']['sessions'], 28)
        self.assertEqual(s['dose']['minutes'], 30)
        self.assertFalse(s['dose']['reminderTimeIsExactExerciseStart'])
        self.assertFalse(s['assets']['originalReceived'])
        self.assertFalse(s['commercialAdaptationApproved'])
        self.assertTrue(s['population']['physicianApprovalRequired'])

    def test_va_visual_inspection_specificity_rights_and_no_borrowed_trial(self):
        s = self.families['PR87']
        originals = [o for o in s['originals'] if 'pdfPages' in o]
        self.assertEqual(sum(o['pdfPages'] for o in originals), 90)
        self.assertEqual(sum(len(o['visualPages']) for o in originals), 9)
        self.assertFalse(s['wholeManualsVisuallyReviewed'])
        self.assertFalse(s['records'][0]['thirteenTipsAreThirteenIndependentExercises'])
        self.assertIsNone(s['records'][0]['durationMinutes'])
        self.assertFalse(s['records'][0]['clinicalTrialOfThisSpecificModuleReceived'])
        self.assertFalse(s['rights']['allAssetsAutomaticallyPublicDomain'])
        self.assertFalse(s['rights']['commercialAdaptationGrantReceived'])
        self.assertFalse(s['specificCaregiverConstraints']['reducesDoseOfOtherTrials'])

    def test_workplace_home_not_equivalent_or_achieved_planned_dose(self):
        s = self.families['PR88']
        self.assertEqual(s['population']['workArm'] + s['population']['homeArm'], 200)
        self.assertTrue(s['programme']['homeUnsupervisedButDifferentExerciseSet'])
        self.assertEqual(s['programme']['plannedSessionsPerWeek'], 5)
        self.assertEqual(s['results']['achievedMeanSessionsPerWeek'], {'work': 2.2, 'home': 1.0})
        self.assertFalse(s['results']['achievedDoseEqualsPlannedFive'])
        self.assertFalse(s['secondaryStudyIsNewIndependentProgramme'])
        self.assertFalse(s['externalPosters']['received'])

    def test_nurse_sequence_not_full_audio_or_third_party_licence(self):
        s = self.families['PR89']
        self.assertEqual(s['table1']['muscleGroups'], 13)
        self.assertEqual(len(s['table1']['gesturesSummary']), 13)
        self.assertIsNone(s['dose']['contractionSeconds'])
        self.assertFalse(s['table1']['isOriginalTwentyMinuteAudioTranscript'])
        self.assertFalse(s['externalAssets']['commercialReuseOfTableEstablished'])
        self.assertFalse(s['externalAssets']['videoCdAndAudioReceived'])
        self.assertFalse(s['population']['familyCaregiversEfficacyDemonstrated'])

    def test_negative_pilot_and_completed_registry_not_positive_efficacy(self):
        pilot, registry = self.families['PR90'], self.families['PR91']
        self.assertEqual((pilot['caregivers'], pilot['perArm']), (10, 5))
        self.assertFalse(pilot['clinicalPositiveEfficacyEstablished'])
        self.assertEqual(registry['registeredActualEnrollment'], 80)
        self.assertEqual(registry['registryStatus'], 'COMPLETED')
        self.assertFalse(registry['resultsPosted'])
        self.assertFalse(registry['completedMeansClinicallyEffective'])
        self.assertTrue(registry['registeredAfterStart'])
        self.assertIsNone(registry['programme']['bensonMinutes'])

    def test_recovered_poster_not_version_dose_or_commercial_equivalence(self):
        r = self.reading['nivaPosterLinkedToPR88']
        self.assertEqual(r['sourceId'], 'PR88')
        self.assertEqual((r['pdfPages'], r['visualPages']), (1, [1]))
        self.assertEqual(len(r['records']), 4)
        self.assertFalse(r['identicalToTrial2014PosterVersionProven'])
        self.assertFalse(r['doseEquivalentToTrialFiveTimesTenMinutes'])
        self.assertFalse(r['rights']['articleCCBYInherited'])
        self.assertFalse(r['rights']['commercialAdaptationGrantReceived'])
        self.assertFalse(r['requiredOtherTwoPostersReceived'])
        self.assertFalse(r['importAllowed'])

    def test_no_closure_and_catalogue_linkage(self):
        catalogue = json.loads((ROOT.parent / 'fontes.json').read_text(encoding='utf-8'))
        sources = {s['id']: s for s in catalogue['sources']}
        for source_id, family in self.families.items():
            self.assertEqual(sources[source_id]['status'], family['status'])
            self.assertEqual(sources[source_id]['localEvidence'],
                             'evidencias/2026-10-07/n15c-teses-seguimento/leitura-fontes.json')
            self.assertFalse(family['importAllowed'])
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertGreaterEqual(len(fiche['evidence']), 108)
        self.assertGreaterEqual(len(fiche['dependencies']), 55)
        self.assertIn('2026-10-07/n15c-teses-seguimento/leitura-fontes.json', fiche['dependencies'])
        self.assertIn(fiche['latestSupplementRound'], fiche['dependencies'])
        self.assertFalse(fiche['researchClosureApproved'])
        self.assertFalse(fiche['releaseApproved'])
        mapping = json.loads((ROUND / 'mapa-apk-campos.json').read_text(encoding='utf-8'))
        self.assertFalse(mapping['runtimeImportCreated'])
        self.assertFalse(mapping['n21Started'])


if __name__ == '__main__':
    unittest.main()
