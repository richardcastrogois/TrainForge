import importlib.util
import json
from collections import Counter
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-fisico-relaxamento'


class CaregiverPhysicalRelaxationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {s['sourceId']: s for s in cls.reading['sources']}
        cls.movements = {m['id']: m for m in cls.reading['exerciseRecords']}
        spec = importlib.util.spec_from_file_location('physical_test_analysis', ROOT / 'analisar-n15c-fisico-relaxamento.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_receipts_distinguish_received_errors_and_tls(self):
        plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
        checked = [self.module.receipts.check_receipt(ROUND / (r['id'] + '.evidencia.json'), ROOT) for r in plan['requests']]
        self.assertEqual((len(checked), sum(r['usable'] for r in checked), sum(r['bodyVerified'] for r in checked)), (11, 8, 9))
        failures = {r['id']: r for r in checked if not r['usable']}
        self.assertEqual(failures['c15-alzoc-termos']['status'], 500)
        for ident in ('c15-cardoso2024-metadados', 'c15-cardoso2024-tese-pdf'):
            self.assertIsNone(failures[ident]['status'])
            self.assertFalse(failures[ident]['bodyVerified'])

    def test_records_keep_population_and_source_locators(self):
        records = self.reading['exerciseRecords']
        self.assertEqual(len(records), 41)
        self.assertEqual(len(self.movements), 41)
        fedema = [r for r in records if r['sourceId'] == 'PR71']
        self.assertEqual(Counter(r['category'] for r in fedema), {'respiracao': 2, 'flexibilidade': 21, 'fortalecimento': 14})
        for record in records:
            self.assertIn(record['sourceId'], self.sources)
            self.assertTrue(record['locator'])
        self.assertEqual(self.sources['PR71']['population']['practitioner'], 'cuidador_para_si')
        self.assertEqual(len(self.sources['PR71']['excludedFromOwnExercise']), 4)

    def test_fedema_no_dose_transfer(self):
        self.assertEqual(self.movements['FEDEMA-F01']['sourceHoldSeconds'], 10)
        for ident in ('FEDEMA-F02', 'FEDEMA-F03'):
            self.assertIsNone(self.movements[ident]['sourceHoldSeconds'])
        for ident in ('FEDEMA-F06', 'FEDEMA-F07', 'FEDEMA-F14'):
            self.assertIsNone(self.movements[ident]['sourceLoadKg'])
        programme = self.sources['PR71']['programme']
        for field in ('sets', 'repetitions', 'restSeconds', 'weeklyProgression', 'dumbbellKg'):
            self.assertIsNone(programme[field])
        self.assertFalse(self.sources['PR71']['sectionGuidance']['numericGuidanceAutomaticallyAssignedToEveryDynamicPhase'])

    def test_received_fedema_rights_do_not_release_manual(self):
        parser = self.module.PlainText()
        parser.feed((ROUND.parent / 'raw/c15-fedema-avisos-legales.html').read_text(encoding='utf-8'))
        self.assertIn('consentimiento expreso y por escrito', ' '.join(parser.parts))
        rights = self.sources['PR71']['rights']
        self.assertFalse(rights['manualCommercialAdaptationGrantReceived'])
        self.assertFalse(rights['importAllowed'])
        self.assertEqual(len(self.sources['PR71']['ambiguities']), 3)

    def test_alzoc_units_and_shoulder_motion_not_invented(self):
        timed = self.movements['ALZOC-R01']
        counted = self.movements['ALZOC-R02']
        self.assertEqual((timed['sourceUnits'], timed['phaseValues']), ('seconds', [4, 7, 8]))
        self.assertEqual((counted['sourceUnits'], counted['phaseValues']), ('count', [2, 4]))
        self.assertFalse(counted['countConvertedToSeconds'])
        self.assertFalse(self.movements['ALZOC-R04']['circularShoulderMovementInvented'])
        self.assertFalse(self.sources['PR72']['rights']['errorBodyIsLicence'])

    def test_innes_variant_dyads_and_design(self):
        source = self.sources['PR73']
        programme = source['programme']
        self.assertEqual(sum(b['minutes'] for b in programme['timedBlocks']), 11)
        self.assertEqual(programme['sessionsPerDay'] * programme['daysPerWeek'] * programme['weeks'], 112)
        self.assertEqual(source['population']['completedCaregivers'], 5)
        self.assertFalse(source['evidenceBasis']['randomizedControlledTrial'])
        self.assertFalse(source['evidenceBasis']['stressPDiscrepancyResolved'])
        self.assertFalse(source['mixedWithOtherTwelveMinuteTrials'])

    def test_innes_keeps_teaching_assets_and_unspecified_licence_version(self):
        source = self.sources['PR73']
        self.assertEqual(source['programme']['weeklyGuidedCdMinimum'], 1)
        self.assertFalse(source['externalAssets']['received'])
        self.assertFalse(source['programme']['apkTextReplacesInitialTeaching'])
        self.assertIsNone(source['rights']['version'])
        self.assertFalse(source['rights']['articleLicenceTransferredToAbsentAssets'])

    def test_sajadi_result_not_an_unpublished_pmr_sequence(self):
        source = self.sources['PR74']
        self.assertEqual((source['evidenceBasis']['enrolled'], source['evidenceBasis']['analysed']), (70, 66))
        self.assertEqual(source['programme']['sessionsPerWeek'] * source['programme']['weeksInMethod'], 12)
        self.assertTrue(source['programme']['weeklyPhoneSupportRequired'])
        self.assertIsNone(source['programme']['muscleSequence'])
        self.assertFalse(source['rights']['articleLicenceCreatesMissingMuscleInstructions'])
        self.assertEqual(source['visuallyInspectedPdfPages'], [1, 3, 4, 6, 7, 8])

    def test_cardoso_web_reading_not_local_hash_or_validated_programme(self):
        source = self.sources['PR75']
        self.assertFalse(source['localBodiesReceived'])
        self.assertIsNone(source['localSha256'])
        self.assertEqual(source['webPdfPageCount'], 119)
        self.assertEqual(source['visuallyInspectedPdfPages'], [])
        self.assertFalse(source['evidenceBasis']['clinicalValidationOfProposedProgrammeReceived'])
        self.assertFalse(source['rights']['grantFromReview2025Transferred'])

    def test_madruga_annex_is_not_complete_nine_month_delivery(self):
        source = self.reading['existingFamilySupplement']
        self.assertEqual(source['sourceId'], 'PR17')
        self.assertEqual(source['pdfPages'], 221)
        self.assertEqual(sum(source['publishedStructure']['blockMinutes']), source['sessionMinutes'])
        self.assertEqual(source['publishedStructure']['strengthRepetitions'], [8, 15])
        self.assertFalse(source['musicBpmIsPrescribedHeartRate'])
        self.assertFalse(source['namedStrengthMovementsHaveCompleteIndividualInstructions'])
        self.assertFalse(source['firstFourWeeksEqualWholeNineMonthProgramme'])
        self.assertFalse(source['rights']['priorCcByArticleLicenceTransferred'])
        self.assertFalse(source['book']['fullBookReceived'])

    def test_authoritative_status_and_traceability_do_not_release_content(self):
        for flag in ('researchClosureApproved', 'releaseApproved', 'appImplemented', 'contactWithAuthors'):
            self.assertFalse(self.reading[flag])
        self.assertFalse(self.reading['apkTraceability']['agentCreatesMissingDose'])
        self.assertFalse(self.reading['apkTraceability']['mixSourcesIntoNewProgramme'])
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-07/n15c-fisico-relaxamento/leitura-fontes.json', fiche['dependencies'])
        self.assertFalse(fiche['researchClosureApproved'])
        queue = json.loads((ROOT / '2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json').read_text(encoding='utf-8'))
        self.assertEqual(queue['activeComplement'], 'N15-C')
        self.assertFalse(queue['n21Allowed'])


if __name__ == '__main__':
    unittest.main()
