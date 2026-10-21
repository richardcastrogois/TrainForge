"""Keep Benson's procedure distinct from its teaching assets and general safety."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('benson_reader', ROOT / 'analisar-cg02-benson.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BensonDeliveryTests(unittest.TestCase):
    def test_primary_bodies_and_native_transcript_integrity(self):
        audit = module.analyse(write=False)
        self.assertEqual(audit['usableHttpBodies'], 5)
        self.assertEqual(audit['collectorCallsThisFolder'], 3)
        self.assertEqual(audit['networkCallsDuringAnalysis'], 0)
        self.assertFalse(audit['browserTranscript']['identityAsTrialCdVerified'])
        self.assertFalse(audit['browserTranscript']['wholeVideoWatched'])
        self.assertTrue(audit['browserTranscript']['transcriptRead'])

    def test_teaching_and_material_not_silently_removed(self):
        data = json.loads((module.FOLDER / 'leitura-complementar.json').read_text(encoding='utf-8'))
        delivery = data['deliveryRevalidation']
        self.assertTrue(delivery['practicalPerformanceCheckedBySkilledResearcher'])
        self.assertTrue(delivery['independentAfterTrainingPublished'])
        self.assertTrue(delivery['cdAndPamphletSupplied'])
        self.assertFalse(delivery['videoOrCdRequiredToPlayEveryPracticeExplicit'])
        self.assertTrue(delivery['cdNecessityAtEachPracticeUnknownDoesNotProveDispensability'])
        self.assertFalse(delivery['originalCdOrPamphletVersionAndContentReceived'])
        self.assertFalse(delivery['apkReplacesTrainingOrResearcherFollowup'])

    def test_core_dose_and_auxiliary_layer_preserved(self):
        data = json.loads((module.FOLDER / 'leitura-complementar.json').read_text(encoding='utf-8'))
        primary = data['primaryArticle']
        self.assertEqual((primary['activeMinutesPerPractice'], primary['practicesPerDay'], primary['stepsPublished']), (15, 2, 6))
        self.assertFalse(primary['doseReducedForFatigueOrTime'])
        self.assertTrue(data['auxiliarySafety']['auxiliaryLayerSeparateFromStudy'])
        self.assertFalse(data['auxiliarySafety']['newPmrtensingOrDeepBreathInstructionTransferred'])
        self.assertFalse(data['auxiliarySafety']['wholeCombinationTestedClaim'])
        self.assertTrue(data['researchItemClosed'])
        self.assertFalse(data['releaseApproved'])

    def test_pdf_text_supports_no_extra_teaching_attribution(self):
        audit = module.analyse(write=False)
        pdf = next(s for s in audit['sources'] if s['record'].endswith('cg02-benson-artigo-pdf.evidencia.json'))
        self.assertEqual(pdf['pages'], 14)
        text = ' '.join(pdf['pageTexts'][6].split())
        self.assertIn('educational pamphlet', text)
        self.assertIn('twice a day for 15 minutes', text)
        self.assertIn('SMS', text)
        queue = json.loads((ROOT.parent / 'fila-cuidadores.json').read_text(encoding='utf-8'))
        self.assertTrue(queue['items'][0]['researchItemClosed'])
        self.assertTrue(queue['items'][1]['researchItemClosed'])
        if queue['activeItem'] is not None:
            index = next(i for i, item in enumerate(queue['items']) if item['id']==queue['activeItem'])
            self.assertTrue(all(item['researchItemClosed'] for item in queue['items'][:index]))
        else:
            pending = next((item for item in queue['items'] if not item['researchItemClosed']), None)
            self.assertEqual(queue['nextItem'], pending['id'] if pending else None)

    def test_factual_closure_does_not_approve_unknown_assets_or_apk_delivery(self):
        package = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        self.assertTrue(package['researchItemClosed'])
        self.assertFalse(package['releaseApproved'])
        self.assertFalse(package['appImplemented'])
        materials = package['materialsDecision']
        self.assertFalse(materials['originalCdIdentityOrContentsResolved'])
        self.assertFalse(materials['externalAssetsProvedDispensable'])
        self.assertFalse(materials['learningMediaRoleSilentlyRemoved'])
        self.assertFalse(materials['substituteCdOrLeafletCompatibilityApproved'])
        self.assertEqual(materials['futureInstructionalAssetsReadiness'], 'nao_demonstrada')
        self.assertTrue(package['delivery']['instructionalMediaRoleMustBePreservedBeforeRelease'])
        self.assertTrue(package['delivery']['retainInitialTeachingAndReinforcement'])
        self.assertFalse(package['clinicalClaim']['newApkDeliveryClinicalEfficacyEstablished'])
        self.assertTrue(package['publicationPrerequisites'])

    def test_method_dose_and_six_source_ids_match_original_reading(self):
        package = json.loads((module.FOLDER / 'pacote-factual.json').read_text(encoding='utf-8'))
        original = json.loads((ROOT / '2026-10-08/n15c-benson-reavaliacao/leitura-fontes.json').read_text(encoding='utf-8'))
        dose = package['primaryProtocol']['dose']
        self.assertEqual(dose['minutesPerPractice'], original['dose']['minutesPerPractice'])
        self.assertEqual(dose['practicesPerDay'], original['dose']['practicesPerDay'])
        self.assertFalse(dose['monthConvertedToExactDays'])
        self.assertIsNone(dose['postPracticeRestNumericSeconds'])
        self.assertEqual([i['sourceInstructionId'] for i in package['instructionRecords']], [i['id'] for i in original['instructionRecords']])
        self.assertTrue(all(i['layer']=='primary_protocol' for i in package['instructionRecords']))
        self.assertFalse(package['comparisonNotSelected']['doseEndingOtherWordsOrMealTimesTransferred'])

    def test_catalogue_resolves_closed_method_and_distinct_publication_requirements(self):
        spec = importlib.util.spec_from_file_location('caregiver_catalogue', ROOT.parent / 'consultar-cuidadores.py')
        catalogue = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(catalogue)
        audit = catalogue.validate()
        self.assertGreaterEqual(audit['researchClosedItems'], 2)
        item = next(i for i in audit['resolvedItems'] if i['id']=='CG-02')
        self.assertTrue(item['researchItemClosed'])
        self.assertEqual(item['publicationState'], 'pendente')
        self.assertFalse(item['releaseApproved'])
        self.assertTrue(all(r['pointer']=='/instructionRecords' for r in item['fields']['instructions']))
        self.assertIn('antes depublicar', ' '.join(item['blockingReasons']).lower())


if __name__ == '__main__':
    unittest.main()
