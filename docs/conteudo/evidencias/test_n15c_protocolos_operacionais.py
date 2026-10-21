"""Preserve versioned prescriptions, caregiver outcomes and acquisition limits."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-protocolos-operacionais'
spec = importlib.util.spec_from_file_location('caregiver_protocols', ROOT / 'analisar-n15c-protocolos-operacionais.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaregiverProtocolTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))

    def test_original_receipts_and_all_pdf_text(self):
        self.assertGreaterEqual(self.inventory['collectorCalls'], 38)
        self.assertGreaterEqual(self.inventory['usableBodies'], 27)
        self.assertEqual(self.inventory['pdfPages'], 888)
        self.assertEqual(len(self.inventory['pdfs']), 6)
        self.assertTrue(all(row['allPagesTextExtracted'] for row in self.inventory['pdfs']))

    def test_bad_format_is_not_successful_document(self):
        rows = {Path(row['record']).name: row for row in self.inventory['sources']}
        bad = rows['c15-sui2023-pmc-app1-docx.evidencia.json']
        self.assertEqual(bad['status'], 200)
        self.assertFalse(bad['bodyUsable'])
        self.assertEqual(bad['bytes'], 1817)
        self.assertIsNotNone(bad['sha256'])
        failed = rows['c15-dogan-sanko-curriculo-pdf.evidencia.json']
        self.assertIsNone(failed['sha256'])
        self.assertFalse(failed['bodyUsable'])

    def test_dogan_version_and_support_not_practice(self):
        row = self.reading['doganPranayama']
        self.assertTrue(row['doseVersions']['methods2025']['dailyPractice'])
        self.assertEqual(row['doseVersions']['abstract2025']['daysPerWeek'], 3)
        self.assertIsNone(row['doseVersions']['chosenApkDose'])
        self.assertFalse(row['doseVersions']['supportFrequencyIsAutomaticallyExerciseFrequency'])
        self.assertFalse(row['rights']['preprintLicenceTransferredToJournalVersion'])
        self.assertFalse(row['instructions']['aiCorrectedBreathingOrder'])

    def test_nagamatsu_and_gyyb_not_false_equivalence(self):
        self.assertFalse(self.reading['nagamatsuAntecedent']['sixStagesAreSameEightCaregiverPositions2015'])
        row = self.reading['gyybCaregivers']
        self.assertEqual(row['protocol']['caregiverSample'], 20)
        self.assertEqual(row['protocol']['totalMainPlusCaregiverSample'], 50)
        self.assertFalse(row['protocol']['mainOlderAdultRandomizedTrialIsCaregiverRandomizedTrial'])
        self.assertTrue(row['timeFlexibilityExplicitInPublishedArticle']['doesNotAuthoriseSplittingOtherProgrammes'])

    def test_original_one_stretch_figure_and_no_rights_transfer(self):
        row = self.reading['oneStretch']
        self.assertTrue(row['figure2015']['actualFigureReviewed'])
        self.assertEqual(row['figure2015']['publishedInstructions']['repetitionsRange'], [1, 2])
        self.assertFalse(row['figure2015']['publishedInstructions']['oneOrTwoRepetitionsAreOneOrTwoDailySessions'])
        self.assertFalse(row['additionalPamphlet']['allThreeAreSameStandingExtensionTrial'])
        self.assertFalse(row['rights']['governmentHostingTransfersThirdPartyRights'])
        self.assertFalse(row['additionalDenominators2015']['all136ContributedToBothOutcomes'])

    def test_chinese_caregiver_not_patient_and_sleep_ns(self):
        row = self.reading['baduanjinStrokeCaregivers']
        self.assertEqual(row['design']['initialEnrolment'], 73)
        self.assertEqual(row['design']['analysed'], 70)
        self.assertFalse(row['population']['patientAgeMistakenForCaregiverAge'])
        self.assertTrue(row['programme']['homeContinuationExplicit'])
        self.assertFalse(row['programme']['callsAreAdditionalExerciseSessions'])
        self.assertEqual(row['results']['sleepInteractionP'][:2], [0.091, 0.075])
        self.assertFalse(row['results']['significantSleepBenefitAt12WeeksOr1MonthProven'])
        self.assertFalse(row['editorialConflicts']['ciSignsSilentlyCorrected'])
        self.assertFalse(row['rights']['oaLicenceTransferredTo2023Article'])

    def test_public_read_only_query_is_not_get_or_reuse_licence(self):
        receipt = json.loads((FOLDER / 'c15-baduanjin-acesso-pdf.evidencia.json').read_text(encoding='utf-8'))
        self.assertEqual(receipt['method'], 'POST')
        self.assertTrue(self.inventory['publicPdfAvailabilityConfirmed'])
        self.assertFalse(self.reading['baduanjinStrokeCaregivers']['acquisition']['publicPdfTokenIsReuseLicence'])

    def test_qigong_protocol_not_results_and_page_count(self):
        row = self.reading['qigongOriginalProtocol']
        self.assertFalse(row['registry']['hasResults'])
        self.assertEqual(row['protocol']['actualPdfPages'], 26)
        self.assertEqual(row['protocol']['headerClaimsPages'], 21)
        self.assertEqual(row['protocol']['templateTotalsMinutes'], [60, 60, 60])
        self.assertFalse(row['clinicalBenefitEstablishedByProtocol'])

    def test_device_and_marine_context_not_removed(self):
        vr = self.reading['vrCaregiver2025']
        marine = self.reading['stabilizationCaregivers2022']
        self.assertFalse(vr['programme']['removeRequiredDeviceAndPreserveTestedProgramme'])
        self.assertFalse(vr['results']['stressOrPainImprovementStatisticallyProven'])
        self.assertFalse(marine['programme']['fiveMinutesMeansContinuousUnbrokenHold'])
        self.assertFalse(marine['setting']['urbanProgrammeAutomaticallyExcludedForNotBeingAtHome'])
        self.assertFalse(marine['setting']['benefitOfMarineSettingMayBeAttributedToUnchangedExerciseAtHome'])

    def test_provenance_current_bodies_and_false_closure(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        records = {row['record'] for row in fiche['evidence']}
        self.assertTrue({row['record'] for row in self.inventory['sources'] if row['bodyUsable']}.issubset(records))
        self.assertIn('2026-10-08/n15c-protocolos-operacionais/leitura-fontes.json', fiche['dependencies'])
        self.assertFalse(fiche['researchClosureApproved'])
        self.assertFalse(self.reading['closureDecision']['n21Started'])


if __name__ == '__main__':
    unittest.main()
