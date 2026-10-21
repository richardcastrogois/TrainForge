import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-cervical-curto'


class CervicalEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('cervical', ROOT / 'analisar-n15c-cervical-curto.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))

    def test_offline_recovery_does_not_hide_wrong_requested_format(self):
        self.assertEqual(self.inventory['collectionCount'], 4)
        self.assertEqual(self.inventory['usableByCollector'], 1)
        self.assertEqual(self.inventory['usefulAfterOfflineRecovery'], 2)
        self.assertEqual(self.inventory['newNetworkCallsForRecovery'], 0)
        recovered = next(row for row in self.inventory['receipts'] if row['offlineFormatRecovery'])
        self.assertFalse(recovered['receiptModified'])
        self.assertEqual(recovered['verifiedActualFormat'], 'DOCX_OOXML_not_PDF')
        self.assertFalse(recovered['docxLimits']['externalReferencesFetched'])

    def test_registry_completion_is_not_posted_results(self):
        source = self.reading['sources'][0]
        self.assertEqual(source['registry']['overallStatus'], 'COMPLETED')
        self.assertFalse(source['registry']['hasResults'])
        self.assertFalse(source['clinicalEvidence']['evidenceForIsolatedSelfStretching'])
        self.assertTrue(source['delivery']['professionalManualTherapyRequired'])
        self.assertFalse(source['delivery']['apkGuidanceReplacesPhysiotherapist'])

    def test_web_negative_and_failures_are_not_received_effective_programme(self):
        source = self.reading['sources'][1]
        self.assertFalse(source['xmlReceived'])
        self.assertFalse(source['leafletAndDvdReceived'])
        self.assertEqual(source['classification'], 'triagem_negativa_nao_programa_eficaz')
        self.assertFalse(self.reading['researchClosureApproved'])
        self.assertFalse(self.reading['apkRecovery']['programmeImportApproved'])


if __name__ == '__main__':
    unittest.main()
