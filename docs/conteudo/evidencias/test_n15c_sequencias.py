import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-sequencias'


class CaregiverOriginalSequenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {s['sourceId']: s for s in cls.reading['sources']}
        cls.inventory = json.loads((ROUND / 'inventario.json').read_text(encoding='utf-8'))
        spec = importlib.util.spec_from_file_location('sequences_test_analysis', ROOT / 'analisar-n15c-sequencias.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_actual_receipts_and_non_content_are_separate(self):
        plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
        checked = [self.module.receipts.check_receipt(ROUND / (r['id'] + '.evidencia.json'), ROOT) for r in plan['requests']]
        self.assertEqual((len(checked), sum(r['status'] == 200 for r in checked), sum(r['bodyVerified'] for r in checked)), (8, 7, 8))
        self.assertEqual(self.inventory['usableBodies'], 6)
        shell = next(r for r in self.inventory['sources'] if r['id'] == 'c15-transfe-tese-metadados')
        self.assertFalse(shell['usable'])
        self.assertEqual(shell['status'], 200)

    def test_pouraboli_dose_does_not_create_missing_cd_steps_or_home_setting(self):
        source = self.sources['PR76']
        self.assertEqual((source['programme']['practiceMinutes'], source['programme']['sessionsPerDay']), (20, 2))
        self.assertFalse(source['programme']['cdReceived'])
        self.assertFalse(source['programme']['pamphletReceived'])
        self.assertIsNone(source['programme']['completeMuscleOrRespiratorySteps'])
        self.assertFalse(source['population']['homePracticeExplicitlyEstablished'])

    def test_umadevi_nc_and_training_are_not_confused(self):
        source = self.sources['PR77']
        self.assertIn('NC', source['rights']['articleLicence'])
        self.assertFalse(source['rights']['commercialUseAllowedByReceivedLicence'])
        self.assertEqual(source['professionalAuthorship']['instructor'], 'primeira autora')
        self.assertEqual(source['programme']['teachingDays'] + source['programme']['ownPracticeDays'], 30)
        self.assertEqual(source['evidenceBasis']['interventionCompleted'] + source['evidenceBasis']['controlCompleted'], 43)
        self.assertFalse(source['programme']['appendixImageReceivedAndViewed'])

    def test_transfe_original_hash_matches_actual_receipt_and_metadata(self):
        source = self.sources['PR78']['protocol']
        receipt = json.loads((ROUND / 'c15-transfe-osf-protocolo-pdf.evidencia.json').read_text(encoding='utf-8'))
        checked = self.module.receipts.check_receipt(ROUND / 'c15-transfe-osf-protocolo-pdf.evidencia.json', ROOT)
        metadata = json.loads((ROUND.parent / 'raw/c15-transfe-osf-arquivos.json').read_text(encoding='utf-8'))['data'][0]['attributes']
        self.assertTrue(checked['bodyVerified'])
        self.assertEqual(source['sha256'], receipt['sha256'])
        self.assertEqual(source['sha256'], metadata['extra']['hashes']['sha256'])
        self.assertEqual(source['bytes'], metadata['size'])
        self.assertIsNone(receipt['maxBytes'])
        self.assertEqual(source['pdfPages'], 73)

    def test_transfe_null_license_not_inherited_from_article(self):
        rights = self.sources['PR78']['rights']
        metadata = json.loads((ROUND.parent / 'raw/c15-transfe-osf-metadados.json').read_text(encoding='utf-8'))['data']['attributes']
        self.assertTrue(metadata['public'])
        self.assertIsNone(metadata['node_license'])
        self.assertFalse(rights['articleLicenceTransferredToProtocolOrScales'])
        self.assertFalse(rights['externalStretchBook']['licenceReceived'])
        self.assertFalse(rights['importAllowed'])

    def test_transfe_announced_twenty_is_not_eight_approved_cards(self):
        programme = self.sources['PR78']['programme']
        self.assertEqual(programme['announcedSelfStretchExercises'], 20)
        self.assertEqual(len(self.reading['exerciseRecords']), 8)
        self.assertEqual(programme['observedSelfStretchSlideGroups'], 8)
        self.assertFalse(programme['observedGroupsAreTwentyCompleteExerciseCards'])
        self.assertFalse(programme['completeIndividualPreparationExecutionEnding'])
        self.assertTrue(self.reading['recordDefaults']['recordsAreSourceSlideGroupsNotPrescribedMovements'])

    def test_transfe_teaching_time_not_daily_practice_dose(self):
        programme = self.sources['PR78']['programme']
        self.assertEqual(sum(programme['teachingBlockMinutes']), programme['sessionMinutes'])
        self.assertFalse(programme['teachingMinutesAreHomeExerciseDose'])
        self.assertFalse(programme['apkTextReplacesResearcher'])
        for field in ('homeStretchHoldSeconds', 'homeStretchRepetitions', 'homeWeeklyFrequency', 'homeRestSeconds', 'weeklyProgression'):
            self.assertIsNone(programme[field])

    def test_transfe_design_and_recipient_are_not_relabelled(self):
        source = self.sources['PR78']
        self.assertFalse(source['evidenceBasis']['articleIsRandomizedControlledTrial'])
        self.assertFalse(source['evidenceBasis']['designDiscrepancy']['resolved'])
        self.assertFalse(source['evidenceBasis']['benefitOfIsolatedSelfStretchEstablished'])
        self.assertTrue(source['population']['homeDeliveryExplicit'])
        self.assertEqual(len(source['excludedFromOwnExercise']), 4)
        self.assertEqual(source['population']['meanCaregiverAge'], 59.75)

    def test_visual_pages_and_slide_locators_are_specific(self):
        source = self.sources['PR78']
        self.assertEqual(source['visuallyInspectedPdfPages'], [1, 2, 20, 21, *range(57, 68)])
        self.assertFalse(source['wholePdfVisuallyReviewed'])
        self.assertFalse(self.inventory['visualInspectionConfirmedByScript'])
        for record in self.reading['exerciseRecords']:
            self.assertEqual(record['sourceId'], 'PR78')
            self.assertTrue(record['locator'].startswith(('PDF62', 'PDF63')))

    def test_madruga_version_conflict_not_book_received(self):
        supplement = self.reading['existingFamilySupplement']
        self.assertEqual((supplement['localUsalRecordYear'], supplement['primaryWebCvnYear']), (2016, 2014))
        self.assertFalse(supplement['bookEditionYearDiscrepancyResolved'])
        self.assertTrue(supplement['webOnlyNoLocalReceipt'])

    def test_no_approval_or_synthetic_prescription(self):
        for flag in ('researchClosureApproved', 'releaseApproved', 'appImplemented', 'contactWithAuthors'):
            self.assertFalse(self.reading[flag])
        self.assertFalse(self.reading['apkTraceability']['agentCreatesMissingDose'])
        self.assertFalse(self.reading['apkTraceability']['mixSourcesIntoNewProgramme'])
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-07/n15c-sequencias/leitura-fontes.json', fiche['dependencies'])
        self.assertFalse(fiche['researchClosureApproved'])


if __name__ == '__main__':
    unittest.main()
