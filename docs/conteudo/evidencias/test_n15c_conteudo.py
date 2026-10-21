import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-conteudo'
spec = importlib.util.spec_from_file_location('content_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


class CaregiverContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.content = json.loads((ROUND / 'conteudo-documentado.json').read_text(encoding='utf-8'))
        cls.inventory = json.loads((ROUND / 'inventario.json').read_text(encoding='utf-8'))
        cls.records = {row['id']: row for row in cls.content['records']}

    def test_source_bodies_and_hashes(self):
        for source in self.inventory['sources']:
            checked = receipts.check_receipt(ROOT / source['record'], ROOT)
            self.assertTrue(checked['usable'])
            self.assertEqual(checked['sha256'], source['sha256'])
            self.assertEqual(checked['bytes'], source['bytes'])

    def test_own_caregiver_content_not_approved(self):
        self.assertEqual(self.content['actor'], 'cuidador_praticando_para_si')
        self.assertEqual(self.content['setting'], 'casa')
        for field in ('researchClosureApproved', 'releaseApproved', 'appImplemented'):
            self.assertFalse(self.content[field])
        self.assertFalse(self.content['apkHandoff']['importAllowed'])
        self.assertEqual(len(self.records), 11)
        self.assertEqual(len(self.content['records']), len(self.records))
        self.assertTrue(all(not r['releaseApproved'] for r in self.records.values()))

    def test_locators_and_source_links(self):
        sources = {s['sourceId']: s for s in self.inventory['sources']}
        containers = {c['id']: c for c in self.content['sourceContainers']}
        self.assertEqual(set(sources), {s['id'] for s in self.content['sources']})
        for row in self.records.values():
            self.assertEqual(containers[row['containerId']]['sourceId'], row['sourceId'])
            self.assertIn(row['locator']['pdfPage'], sources[row['sourceId']]['readPdfPagesOneBased'])
            self.assertLessEqual(row['locator']['pdfPage'], sources[row['sourceId']]['pdfPages'])
            self.assertTrue(row['missing'])

    def test_counts_not_converted_to_seconds(self):
        bridge = self.records['C15-ELA-PONTE']['sourceDose']
        self.assertEqual(bridge['holdCount'], 5)
        self.assertIsNone(bridge['holdSeconds'])
        breath = self.records['C15-VA-RESPIRACAO']['sourceDose']
        self.assertEqual(breath['inhaleCount'], 10)
        self.assertIsNone(breath['inhaleSeconds'])
        self.assertIsNone(breath['exhaleSeconds'])
        previous = json.loads((ROOT / '2026-10-04/n15c-retomada/leitura-cartilha-ela.json').read_text(encoding='utf-8'))
        old_bridge = next(r for r in previous['instructionInventory'] if r['section'] == 'Ponte')
        self.assertIn('contar ate5', old_bridge['dose'])
        self.assertNotIn('sustentar5s', old_bridge['dose'])

    def test_no_synthetic_session_or_transferred_rest(self):
        self.assertEqual(self.content['audit']['syntheticSessionsCreated'], 0)
        self.assertEqual(len(self.content['sourceContainers']), 3)
        self.assertTrue(all(not c['completeExecutableSession'] for c in self.content['sourceContainers']))
        self.assertIsNone(self.records['C15-ELA-PERNA-LATERAL']['sourceDose']['restSeconds'])
        for container in self.content['sourceContainers']:
            ids = container.get('originalSourceOrder', container.get('documentedSubsetInSourceOrder', container.get('separateRoutines')))
            self.assertTrue(all(self.records[i]['sourceId'] == container['sourceId'] for i in ids))

    def test_rights_and_next_niches_not_inherited(self):
        self.assertTrue(all(not s['commercialAdaptationApproved'] for s in self.content['sources']))
        self.assertFalse(self.content['sectionContract']['otherNichesResearchedThisRound'])
        self.assertEqual(self.content['sectionContract']['squareResearchDeferredTo'], 'N21')
        self.assertEqual(sum(len(p) for p in self.content['audit']['visuallyInspectedPages'].values()), 9)
        self.assertEqual(self.inventory['newCollectorCalls'], 1)
        self.assertEqual(self.inventory['reusedBodies'], 2)


if __name__ == '__main__':
    unittest.main()
