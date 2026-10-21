"""Protege limites clinicos, dose e proveniencia das novas fontes N15-C."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-alongamento-va'
spec = importlib.util.spec_from_file_location('n15_stretch_va', ROOT / 'analisar-n15c-alongamento-va.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StretchVaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventory = module.analyse()
        cls.reading = json.loads((FOLDER / 'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.stretch, cls.va = cls.reading['sources']

    def test_four_actual_bodies_and_hashes(self):
        for key in ['collectorCalls', 'usableBodies', 'hashedBodies']:
            self.assertEqual(self.inventory[key], 4)

    def test_sequence_not_invented_as_timed_pose_instructions(self):
        self.assertEqual(self.stretch['figure']['panels'], 8)
        self.assertTrue(self.stretch['figure']['includesFinalRelaxation'])
        self.assertIsNone(self.stretch['figure']['poseHoldSeconds'])
        self.assertFalse(self.stretch['figure']['writtenPoseInstructions'])
        self.assertEqual(self.stretch['programme']['minutesApproximate'], 10)

    def test_no_unsupported_lumbar_sleep_or_male_benefit(self):
        results = self.stretch['results']
        self.assertEqual(results['womenFlexibilityInteractionP'], 0.002)
        self.assertEqual(results['womenLowBackPainInteractionP'], 0.964)
        self.assertEqual(results['womenSleepInteractionP'], 0.114)
        self.assertFalse(results['menSignificantInteractions'])

    def test_professional_teaching_and_monitoring_not_removed(self):
        self.assertTrue(self.stretch['professionalOrigin']['exerciseTeachingQualificationExplicit'])
        self.assertEqual(self.stretch['programme']['initialTeachingMinutesPerPerson'], 30)
        self.assertEqual(self.stretch['programme']['weeklyHealthSessionsDuringIntervention'], 4)

    def test_posted_results_are_not_claim_of_significance(self):
        self.assertTrue(self.va['results']['hasPostedResults'])
        self.assertEqual(self.va['results']['armsStarted'], [6, 11, 15])
        self.assertEqual(self.va['results']['armsCompletingSixMonths'], [3, 8, 5])
        self.assertIsNone(self.va['results']['primaryComparisonP'])
        self.assertFalse(self.va['results']['claimOfSignificantBurdenReductionApproved'])

    def test_cited_appendix_and_teaching_block_are_not_home_protocol(self):
        material = self.va['operationalMaterial']
        self.assertTrue(material['appendix4Cited'])
        self.assertFalse(material['appendix4IncludedInReceivedPdf'])
        self.assertTrue(material['teachingBlockIsNotHomeDose'])
        self.assertFalse(material['audioReceived'])

    def test_no_false_approval_or_blanket_rights_grant(self):
        for source in self.reading['sources']:
            self.assertFalse(source['selectedAsExecutableProgramme'])
        self.assertFalse(self.stretch['rights']['commercialAssetGrantIdentified'])
        self.assertIsNone(self.va['rights']['commercialGrantForMissingAppendixAndAudio'])
        for gate in ['G03', 'G04']:
            self.assertFalse(self.reading['closureDecision'][gate])
        self.assertFalse(self.reading['closureDecision']['n21Started'])

    def test_aggregate_contains_new_receipts_and_dependencies(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        records = {r['record'] for r in fiche['evidence']}
        self.assertTrue({r['record'] for r in self.inventory['sources']}.issubset(records))
        self.assertIn('2026-10-08/n15c-alongamento-va/leitura-fontes.json', fiche['dependencies'])
        self.assertIn('2026-10-08/n15c-alongamento-va/inventario.json', fiche['dependencies'])


if __name__ == '__main__':
    unittest.main()
