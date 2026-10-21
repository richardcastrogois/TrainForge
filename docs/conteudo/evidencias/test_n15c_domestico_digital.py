import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-domestico-digital'


class CaregiverDomesticDigitalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {s['sourceId']: s for s in cls.reading['sources']}
        cls.inventory = json.loads((ROUND / 'inventario.json').read_text(encoding='utf-8'))
        spec = importlib.util.spec_from_file_location('digital_test_analysis', ROOT / 'analisar-n15c-domestico-digital.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_receipts_rehash_originals_without_network(self):
        plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
        checked = [self.module.receipts.check_receipt(ROUND / (r['id'] + '.evidencia.json'), ROOT) for r in plan['requests']]
        self.assertEqual((len(checked), sum(s['status'] == 200 for s in checked), sum(s['bodyVerified'] for s in checked)), (10, 7, 10))
        self.assertEqual(self.inventory['usableBodies'], 7)
        self.assertEqual(sum(s['status'] == 403 for s in checked), 3)

    def test_rutgers_series_dose_not_seconds_or_ten_minutes_each(self):
        programme = self.sources['PR81']['programme']
        self.assertEqual(programme['sourceStretchCount'], 8)
        self.assertEqual(len(self.reading['exerciseRecords']), 8)
        self.assertFalse(programme['endPauseIsNinthStretch'])
        self.assertEqual(programme['repetitionsEachMovement'], [3, 5])
        self.assertEqual(programme['seriesApproxMinutes'], 10)
        self.assertFalse(programme['minutesArePerMovement'])
        for field in ('holdSeconds', 'restSeconds', 'weeklySessions', 'weeklyProgression'):
            self.assertIsNone(programme[field])

    def test_source_neck_roll_not_full_circle_or_rewritten_breath(self):
        movements = {s['id']: s for s in self.reading['exerciseRecords']}
        self.assertFalse(movements['RUT-M04']['fullCirclePrescribed'])
        self.assertFalse(movements['RUT-M06']['breathDirectionNormalisedAcrossBothDirections'])
        self.assertEqual(movements['RUT-M06']['repetitionsPerDirection'], [3, 5])
        self.assertFalse(movements['RUT-M08']['finalRightReturnExplicit'])

    def test_source_breath_ratio_not_seconds_or_apnea(self):
        breathing = self.sources['PR81']['breathing']
        self.assertEqual(breathing['inhaleExhaleRatios'], ['1:1', 'ate2:1'])
        self.assertFalse(breathing['ratioEqualsFixedSeconds'])
        self.assertFalse(breathing['mandatoryBreathHolds'])
        self.assertIsNone(breathing['practiceMinutes'])

    def test_populations_and_versions_not_merged_into_trial(self):
        source = self.sources['PR81']
        self.assertFalse(source['population']['caregiverMustBeOlderAdult'])
        self.assertFalse(source['population']['homeCompatibleIsTrialAtHome'])
        self.assertFalse(source['evidenceBasis']['ownGuideClinicalTrialReceived'])
        self.assertEqual(len(source['versionDifferences']), 3)
        self.assertIn('fisioterapeuta', source['programme']['sourceSafety']['familyMedicalAdvice'])
        self.assertIn('nao acrescenta fisioterapeuta', source['programme']['sourceSafety']['professionalMedicalAdvice'])

    def test_credentials_do_not_transfer_rutgers_third_party_permission(self):
        source = self.sources['PR81']
        self.assertFalse(source['professionalAuthorship']['allCoauthorsArePhysicalTherapists'])
        self.assertFalse(source['rights']['thirdPartyPermissionToRutgersTransfersToApk'])
        self.assertFalse(source['rights']['explicitNcLicenceReceived'])
        self.assertFalse(source['rights']['stateFundingEqualsFederalPublicDomain'])
        self.assertFalse(source['rights']['importAllowed'])

    def test_roshid_protocol_preserves_human_teaching_not_future_outcomes(self):
        source = self.sources['PR80']
        self.assertFalse(source['protocolProgramme']['protocolIsCompletedOutcomeStudy'])
        self.assertTrue(source['protocolProgramme']['firstWeekFaceToFaceTeachingRetained'])
        self.assertTrue(source['protocolProgramme']['weeklyPhoneOrSmsSupportRetained'])
        self.assertFalse(source['protocolProgramme']['actualRelaxationStepsReceived'])
        self.assertFalse(source['protocolProgramme']['videoAssetsReceived'])
        self.assertIsNone(source['protocolProgramme']['durationPerBensonPracticeMinutes'])
        self.assertFalse(source['protocolPopulation']['exclusionIsAdviceToStopMedication'])

    def test_web403_not_received_video_result_or_profile(self):
        self.assertFalse(self.sources['PR79']['videosReceivedOrWatched'])
        self.assertFalse(self.sources['PR79']['localBodyIsSourceContent'])
        result = self.sources['PR80']['results2026']
        self.assertTrue(result['webOnly'])
        self.assertFalse(result['localBodyIsArticle'])
        self.assertFalse(result['downloadAlternateCdnToBypass403'])
        for barrier in self.reading['accessLimits']:
            self.assertEqual(barrier['status'], 403)
            self.assertFalse(barrier['usable'])

    def test_specific_visual_pages_and_record_traceability(self):
        self.assertFalse(self.inventory['visualInspectionConfirmedByScript'])
        source = self.sources['PR81']
        self.assertEqual(len(source['familyVisuallyInspectedPdfPages']), 9)
        self.assertEqual(len(source['professionalVisuallyInspectedPdfPages']), 9)
        self.assertFalse(source['wholePdfVisuallyReviewed'])
        self.assertTrue(self.reading['apkTraceability']['defaultsMustBeJoinedToEveryRecord'])
        for record in self.reading['exerciseRecords']:
            self.assertTrue(record['locator'].startswith('PDF'))
        for entry in self.inventory['sources']:
            if entry['id'].endswith('-pdf'):
                receipt = json.loads((ROUND / (entry['id'] + '.evidencia.json')).read_text(encoding='utf-8'))
                self.assertIsNone(receipt['maxBytes'])

    def test_no_closure_import_or_app_implementation(self):
        for flag in ('researchClosureApproved', 'releaseApproved', 'appImplemented', 'contactWithAuthors'):
            self.assertFalse(self.reading[flag])
        self.assertFalse(self.reading['recordDefaults']['importAllowed'])
        self.assertFalse(self.reading['apkTraceability']['mixSourcesIntoNewProgramme'])
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-07/n15c-domestico-digital/leitura-fontes.json', fiche['dependencies'])
        self.assertFalse(fiche['researchClosureApproved'])


if __name__ == '__main__':
    unittest.main()
