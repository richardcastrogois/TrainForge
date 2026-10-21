import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-mcm'


class CaregiverMcmTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manual = json.loads((ROUND / 'leitura-manual.json').read_text(encoding='utf-8'))
        spec = importlib.util.spec_from_file_location('mcm_test_analysis', ROOT / 'analisar-n15c-mcm.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_received_article_bodies_have_valid_hashes(self):
        for source in self.manual['sourceBodies']:
            checked = self.module.receipts.check_receipt(ROOT / source['receipt'], ROOT)
            self.assertTrue(checked['usable'])
            self.assertEqual(checked['sha256'], source['sha256'])

    def test_published_metadata_not_global_absence_proof(self):
        parser = self.module.ArticleMetadata()
        parser.feed((ROUND.parent / 'raw/c15-mcm-artigo-html.html').read_text(encoding='utf-8'))
        actual = parser.supplement_state()
        self.assertEqual(actual['hasSupplementalDataFlags'], [False])
        self.assertEqual(actual['supplementarySectionNodeCounts'], [0])
        self.assertEqual(actual['publishedSupplementDownloadLinks'], [])
        self.assertFalse(actual['absenceOnReceivedPageProvesGlobalNonexistence'])
        self.assertFalse(self.manual['manualAvailability']['finalManualReceived'])

    def test_content_validation_not_clinical_trial_of_manual(self):
        evidence = self.manual['evidenceBasis']
        self.assertEqual((evidence['priorRandomizedTrialsSynthesized'], evidence['caregiverInterviewParticipants'], evidence['expertContentValidators']), (31, 8, 11))
        self.assertFalse(evidence['clinicalPilotOfThisManualPerformed'])
        self.assertFalse(evidence['randomizedTrialOfThisManualPerformed'])
        self.assertFalse(evidence['individualExerciseClinicalEfficacyProven'])

    def test_topic_names_do_not_become_instructions_or_doses(self):
        self.assertEqual(len(self.manual['curriculumTopics']), 3)
        for topic in self.manual['curriculumTopics']:
            self.assertIsNone(topic['completeInstructions'])
            self.assertIsNone(topic['sourceDose'])
        self.assertFalse(self.manual['apkTraceability']['topicNamesAreExerciseInstructions'])
        self.assertFalse(self.manual['apkTraceability']['instructionOrDoseCreatedByAgent'])

    def test_rights_and_declaration_not_transferred_to_absent_assets(self):
        rights = self.manual['rights']
        self.assertFalse(rights['manualLicenceVerified'])
        self.assertFalse(rights['articleLicenceTransferredToAbsentAssets'])
        self.assertFalse(self.manual['professionalAuthorship']['declarationProvesAllExternalAssetsNeverUsedAi'])
        self.assertEqual(self.manual['audit']['visuallyInspectedPdfPages'], [1, 5, 8, 9, 10, 11])

    def test_queue_and_fiche_keep_false_closure(self):
        for key in ('researchClosureApproved', 'releaseApproved', 'appImplemented', 'contactWithAuthors'):
            self.assertFalse(self.manual[key])
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-07/n15c-mcm/leitura-manual.json', fiche['dependencies'])
        gates = {g['id']: g['met'] for g in fiche['researchClosureCriteria']}
        self.assertFalse(gates['C15-G03'])
        self.assertFalse(gates['C15-G04'])
        queue = json.loads((ROOT / '2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json').read_text(encoding='utf-8'))
        self.assertEqual(queue['activeComplement'], 'N15-C')
        self.assertFalse(queue['n21Allowed'])
        catalogue = json.loads((ROOT.parent / 'fontes.json').read_text(encoding='utf-8'))
        self.assertEqual([s['status'] for s in catalogue['sources'] if s['id'] == 'PR70'], ['condicional'])


if __name__ == '__main__':
    unittest.main()
