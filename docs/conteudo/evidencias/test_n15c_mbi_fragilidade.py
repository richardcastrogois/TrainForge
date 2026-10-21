import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-mbi-fragilidade'
spec = importlib.util.spec_from_file_location('mbi_frailty', ROOT / 'analisar-n15c-mbi-fragilidade.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class FrailtyMbiTests(unittest.TestCase):
    def test_original_bodies_and_registry(self):
        result = module.analyse()
        self.assertEqual((result['collectorCalls'], result['usableBodies']), (3, 3))
        self.assertEqual([r.get('pdfPages') for r in result['receipts'][:2]], [19, 8])
        self.assertFalse(result['receipts'][2]['hasResults'])
        self.assertEqual(result['networkCallsDuringAnalysis'], 0)

    def test_time_effect_is_not_interaction(self):
        source = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))['sources'][0]
        burden = source['clinical']['burden']
        self.assertEqual(burden['mbiVsPsyTimeEffectT1P'], .025)
        self.assertEqual(source['clinical']['mbiVsPsyInteractionT0T1']['burdenP'], .972)
        self.assertFalse(burden['timeEffectIsComparativeSuperiority'])
        self.assertFalse(source['clinical']['isolatedStretchOrBreathEffectConfirmed'])

    def test_no_script_or_release_inferred(self):
        reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        source = reading['sources'][0]
        self.assertFalse(reading['researchClosureApproved'])
        self.assertFalse(reading['releaseApproved'])
        self.assertEqual(source['operational']['instructionRecords'], [])
        self.assertTrue(source['dose']['liveSupportRetained'])
        self.assertTrue(source['design']['flowArithmeticExplainedByVisualReview'])


if __name__ == '__main__':
    unittest.main()
