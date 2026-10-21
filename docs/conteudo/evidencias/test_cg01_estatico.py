"""Verify first-component evidence and keep later caregiver items on hold."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('cg01_stretch', ROOT / 'analisar-cg01-estatico.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StaticFirstComponentTests(unittest.TestCase):
    def test_four_original_auxiliary_bodies_have_integrity(self):
        audit = module.analyse(render=False, write=False)
        self.assertEqual(audit['usableBodies'], 4)
        self.assertEqual(audit['collectorCalls'], 4)
        self.assertEqual(audit['networkCallsDuringAnalysis'], 0)
        self.assertFalse(audit['auxiliaryGuidesAreAtacProtocol'])
        self.assertFalse(audit['doseChanged'])

    def test_primary_static_dose_and_finite_endpoint_are_preserved(self):
        data = json.loads((module.FOLDER / 'leitura-complementar.json').read_text(encoding='utf-8'))
        self.assertEqual(data['primaryBaseline']['dose']['repetitionsPerLeg'], 8)
        self.assertEqual(data['primaryBaseline']['dose']['holdSeconds'], 30)
        self.assertTrue(data['gapRevalidation']['sessionEndpointDefinedByDose'])
        self.assertFalse(data['gapRevalidation']['numericStepHeightRequired'])
        self.assertFalse(data['gapRevalidation']['weeklyProgressionForAcuteRequired'])
        self.assertFalse(data['gapRevalidation']['pnfTeachingAutomaticallyTransferredToStatic'])

    def test_auxiliary_layers_require_recorded_decision_and_compatibility(self):
        data = json.loads((module.FOLDER / 'leitura-complementar.json').read_text(encoding='utf-8'))
        self.assertTrue(all(not s['sameProgrammeAsAtac'] for s in data['auxiliarySources']))
        self.assertTrue(data['selection']['researchItemClosed'])
        self.assertFalse(data['selection']['releaseApproved'])
        self.assertFalse(data['selection']['nextComponentStarted'])
        self.assertFalse(data['complementDecision']['explicitNewApprovalAssumed'])
        self.assertTrue(data['complementDecision']['answerReceived'])
        package = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        self.assertEqual(package['userDecision']['answer'], data['complementDecision']['answer'])
        selected = [c['auxiliary'] for c in package['compatibilityReview'] if c['selectedPart']]
        self.assertEqual(selected, ['Worc', 'CSP'])
        self.assertTrue(package['closureEvidence']['sourceLayersKeptSeparate'])
        self.assertFalse(package['closureEvidence']['wholeNewCombinationTrialTested'])

    def test_catalogue_sequence_only_advances_after_closed_prefix(self):
        queue = json.loads((ROOT.parent / 'fila-cuidadores.json').read_text(encoding='utf-8'))
        self.assertTrue(queue['advanceOnlyAfterPreviousItemClosed'])
        first_open = next((n for n, i in enumerate(queue['items']) if not i['researchItemClosed']), len(queue['items']))
        self.assertTrue(all(i['researchItemClosed'] for i in queue['items'][:first_open]))
        self.assertTrue(all(not i['researchItemClosed'] for i in queue['items'][first_open:]))
        if queue['activeItem'] is None:
            self.assertFalse(any(i['status']=='em_andamento' for i in queue['items']))
            if first_open < len(queue['items']):
                self.assertEqual(queue['nextItem'], queue['items'][first_open]['id'])
                self.assertEqual(queue['items'][first_open]['status'], 'aguardando_inicio')
        else:
            self.assertEqual(queue['activeItem'], queue['items'][first_open]['id'])
        self.assertTrue(all(i['status']=='aguardando_anterior' for i in queue['items'][first_open+1:]))
        self.assertFalse(queue['n21Started'])

    def test_professional_path_is_not_falsely_attributed_to_static_trial(self):
        package = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        delivery = package['delivery']
        self.assertTrue(package['researchItemClosed'])
        self.assertFalse(package['releaseApproved'])
        self.assertFalse(package['appImplemented'])
        self.assertTrue(delivery['supportDuringApplicationRequiredByThisSelectedPath'])
        self.assertTrue(delivery['supportRuleIsConservativeApkRestrictionNotObservedAtacStaticRequirement'])
        self.assertFalse(delivery['atacStaticTeachingOrLiveSupervisionExplicitlyPublished'])
        self.assertFalse(delivery['firstUseWithoutProfessionalSupported'])
        dose = package['primaryProtocol']['dose']
        self.assertEqual((dose['holdSeconds'], dose['repetitionsPerLeg'], dose['legs']), (30, 8, 2))
        self.assertEqual(dose['activeHoldSeconds'], 480)
        self.assertIsNone(dose['restSeconds'])
        self.assertIsNone(dose['weeklyFrequency'])
        self.assertTrue(package['sessionCompletion']['notAutonomousStepByStepExitClaim'])
        self.assertIsNone(package['sessionCompletion']['originalExactExitSequence'])
        self.assertTrue(package['safety']['noOaPainAllowanceBorrowed'])
        self.assertTrue(package['safety']['noPnf65PercentBorrowed'])

    def test_catalogue_core_and_auxiliary_receipts_are_integrity_checked(self):
        spec = importlib.util.spec_from_file_location('caregiver_catalogue', ROOT.parent / 'consultar-cuidadores.py')
        catalogue = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(catalogue)
        audit = catalogue.validate()
        item = next(i for i in audit['resolvedItems'] if i['id'] == 'CG-01')
        self.assertTrue(all('cg01-estatico/pacote-factual.json' in r['file'] for r in item['fields']['initialPreparation']))
        records = [r for r in audit['receiptAudit'] if 'cg01-estatico' in r]
        self.assertEqual(len(records), 2)


if __name__ == '__main__':
    unittest.main()
