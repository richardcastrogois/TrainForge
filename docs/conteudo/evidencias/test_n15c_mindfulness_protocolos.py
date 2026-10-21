import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-mindfulness-protocolos'


class MindfulnessOriginalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('mindfulness_original', ROOT / 'analisar-n15c-mindfulness-protocolos.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.sources = {row['sourceId']: row for row in cls.reading['sources']}

    def test_bodies_hashes_and_roles(self):
        self.assertEqual(self.inventory['collectorCalls'], 7)
        self.assertEqual(self.inventory['http200'], 6)
        self.assertEqual(self.inventory['hashedBodies'], 7)
        self.assertEqual(self.inventory['usableBodies'], 6)
        self.assertEqual(self.inventory['abstractCount'], 3)
        self.assertEqual(self.inventory['networkCallsDuringAnalysis'], 0)

    def test_doc_and_blocked_response_are_not_manuals(self):
        most = self.sources['PR110']
        self.assertTrue(most['supplementInterpreted'])
        self.assertEqual(self.inventory['spiritReportingChecklistCount'], 1)
        self.assertIn('SPIRIT', most['supplementContents'])
        self.assertFalse(most['resultsReceiptIsArticle'])
        self.assertFalse(most['operational']['homeInstructionTextReceived'])
        self.assertEqual(most['operational']['minutesPerGroupSession'], 120)

    def test_autism_complete_table_does_not_repair_breathing(self):
        study = self.sources['PR111']
        self.assertEqual(len(study['instructionRecords']), 8)
        self.assertTrue(study['instructionRecords'][-1]['operationallyBlocked'])
        self.assertFalse(study['safety']['sourceBreathingErrorCorrected'])
        self.assertEqual(study['dose']['positionMaintenanceMinutes'], 20)
        self.assertEqual(study['dose']['days'], 30)
        self.assertTrue(study['dose']['phoneEncouragement'])

    def test_caregiver_and_mixed_population_not_merged(self):
        self.assertFalse(self.sources['PR113']['results']['caregiverOnlyEffectDemonstrated'])
        self.assertFalse(self.sources['PR112']['results']['bisIsDirectPerceivedStressScale'])
        self.assertFalse(self.sources['PR112']['manual']['exactScriptReceived'])

    def test_breath_music_result_not_isolated_or_control_dose(self):
        self.assertFalse(self.sources['PR114']['results']['isolatedBreathingEffectClaimed'])
        self.assertFalse(self.sources['PR114']['musicReceivedOrLicensed'])
        self.assertFalse(self.sources['PR114']['exactScriptReceived'])

    def test_no_research_or_apk_approval_by_counts(self):
        for value in (self.inventory, self.reading):
            self.assertFalse(value['researchClosureApproved'])
            self.assertFalse(value['releaseApproved'])
            self.assertFalse(value['appImplemented'])
        self.assertEqual(self.reading['recoveryForApk']['assetsImported'], [])


if __name__ == '__main__':
    unittest.main()
