import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
CONTENT = ROOT.parent


class ExercisePolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.policy = json.loads((CONTENT / 'criterios-exercicios-apk.json').read_text(encoding='utf-8'))
        cls.programme = json.loads((ROOT / '2026-10-07/n15c-programa/leitura-programa.json').read_text(encoding='utf-8'))

    def test_global_scope_and_both_paths(self):
        self.assertEqual(self.policy['scope'], 'todos_os_exercicios_e_programas_do_apk')
        self.assertTrue(self.policy['appliesToPreviousResearch'])
        self.assertTrue(self.policy['appliesToFutureResearch'])
        self.assertEqual(self.policy['userDecision']['acceptedDeliveryPaths'], ['autonomo', 'com_orientacao_profissional'])
        self.assertFalse(self.policy['userDecision']['allExercisesRequireSupervision'])
        self.assertFalse(self.policy['userDecision']['allExercisesMayStartWithoutSupervision'])

    def test_professional_authorship_and_source_scope(self):
        self.assertTrue(self.policy['professionalAuthorship']['qualificationMissingBlocksApproval'])
        self.assertFalse(self.policy['professionalAuthorship']['humanAuthorshipAloneSufficient'])
        self.assertFalse(self.policy['professionalAuthorship']['journalPublicationAloneProvesProfessionalQualification'])
        self.assertFalse(self.policy['evidenceScope']['programmeEvidenceProvesEachMovementInIsolation'])
        self.assertFalse(self.policy['evidenceScope']['randomizedTrialRequiredForEveryIsolatedMovement'])

    def test_instructions_do_not_replace_live_supervision(self):
        delivery = self.policy['delivery']
        self.assertFalse(delivery['apkInstructionsReplaceRequiredLiveSupervision'])
        self.assertFalse(delivery['userSelectsPathRegardlessOfSource'])
        self.assertTrue(delivery['autonomous']['priorTrainingRequiredWhenSourceRequiresIt'])
        self.assertFalse(delivery['professional']['requiredProfessionalServiceAssumedAvailable'])
        self.assertTrue(delivery['clearInstructionsRequiredForBothPaths'])

    def test_no_automatic_approval_or_scope_progression(self):
        for field in ('existingContentAutomaticallyApproved', 'allPriorItemsAuditedAgainstPolicy',
                      'researchClosureAutomaticallyChanged', 'releaseApproved', 'appImplemented'):
            self.assertFalse(self.policy[field])
        fiche_path = ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json'
        fiche = json.loads(fiche_path.read_text(encoding='utf-8'))
        self.assertEqual((fiche_path.parent / fiche['deliveryDecision']['policy']).resolve(), CONTENT / 'criterios-exercicios-apk.json')
        self.assertFalse(fiche['researchClosureApproved'])
        queue_path = ROOT / '2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json'
        queue = json.loads(queue_path.read_text(encoding='utf-8'))
        self.assertEqual((queue_path.parent / queue['exercisePolicy']).resolve(), CONTENT / 'criterios-exercicios-apk.json')
        self.assertEqual(queue['activeComplement'], 'N15-C')
        self.assertFalse(queue['n21Allowed'])

    def test_revieew_hashes_and_catalogue_link(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location('policy_receipts', ROOT / 'analisar-n15c-manuais.py')
        receipts = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(receipts)
        for body in self.programme['sourceBodies']:
            checked = receipts.check_receipt(ROOT / body['receipt'], ROOT)
            self.assertTrue(checked['usable'])
            self.assertEqual(checked['sha256'], body['sha256'])
        catalogue = json.loads((CONTENT / 'fontes.json').read_text(encoding='utf-8'))
        rows = [r for r in catalogue['sources'] if r['id'] == 'PR68']
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['status'], 'condicional')

    def test_revieew_not_synthetic_or_domestic_approval(self):
        rows = self.programme['sourceWeeklyWorkRestSeconds']
        self.assertEqual([r['week'] for r in rows], list(range(1, 13)))
        self.assertTrue(all(r['work'] + r['rest'] == 60 for r in rows))
        self.assertEqual(self.programme['sourceProgrammeDose']['minimumPreviousLevelSessionsBeforeProgression'], 4)
        self.assertEqual(len(self.programme['movementPool']), 9)
        self.assertTrue(all(len(m['levels']) == 3 for m in self.programme['movementPool']))
        examples = self.programme['originalExamples']
        self.assertEqual(examples['week'], 7)
        self.assertEqual(len(examples['sessions']), 2)
        self.assertEqual(examples['syntheticSessionsCreated'], 0)
        self.assertFalse(examples['examplesAreComplete24SessionCalendar'])
        self.assertFalse(self.programme['delivery']['homeSettingVerified'])
        self.assertTrue(self.programme['delivery']['liveBidirectionalProfessionalSupervision'])
        self.assertFalse(self.programme['resultsScope']['autonomousHomeEfficacyDemonstrated'])
        self.assertFalse(self.programme['professionalQualificationIndependentlyVerified'])
        self.assertFalse(self.programme['releaseApproved'])
        self.assertFalse(self.programme['importAllowed'])
        assets = self.programme['assetRights']
        self.assertEqual(sum(a['commercialReuseSupported'] for a in assets), 4)
        self.assertTrue(all(not a['commercialReuseSupported'] for a in assets if a.get('received') is False))


if __name__ == '__main__':
    unittest.main()
