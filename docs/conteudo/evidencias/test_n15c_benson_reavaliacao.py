import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-benson-reavaliacao'


class BensonReevaluationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('benson', ROOT / 'analisar-n15c-benson-reavaliacao.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))

    def test_original_integrity_without_new_collection(self):
        self.assertEqual(self.inventory['usefulBodies'], 2)
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'], 0)
        self.assertTrue(self.reading['authorship']['qualificationIsExplicit'])

    def test_not_other_benson_or_pmr_dose(self):
        self.assertEqual(self.reading['dose']['minutesPerPractice'], 15)
        self.assertEqual(self.reading['dose']['practicesPerDay'], 2)
        self.assertEqual(self.reading['dose']['cycle'], 'one month')
        self.assertIsNone(self.reading['dose']['minimumHoursBetweenPractices'])
        self.assertFalse(self.reading['instructionRecords'][2]['forcefulMuscleTensingPrescribed'])
        self.assertTrue(self.reading['safety']['routineEndingPresent'])

    def test_sample_conflict_and_support_preserved(self):
        self.assertEqual(self.reading['clinicalEvidence']['analysedArms'], [24, 28])
        self.assertFalse(self.reading['conflicts'][0]['resolvedByAuthor'])
        self.assertTrue(self.reading['delivery']['independentPracticeAfterTrainingExplicit'])
        self.assertTrue(self.reading['delivery']['trainingRequiredByStudiedDelivery'])
        self.assertFalse(self.reading['delivery']['externalAssetsProvedDispensable'])

    def test_scientific_facts_not_asset_grant_or_closure(self):
        self.assertFalse(self.inventory['licenseReplacedByGenericBy'])
        self.assertFalse(self.inventory['scientificFactsBlanketProhibited'])
        self.assertFalse(self.inventory['assetCopyApproved'])
        self.assertEqual(self.reading['reclassification']['to'], 'condicional')
        self.assertFalse(self.reading['researchClosureApproved'])
        self.assertFalse(self.reading['apkRecovery']['programmeImportApproved'])


if __name__ == '__main__':
    unittest.main()
