import importlib.util
import json
from pathlib import Path
import unittest

from PIL import Image

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-revieew-suplementos'
RAW = ROUND.parent / 'raw'


class ReViEEWSupplementTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reading = json.loads((ROUND / 'leitura-anexos.json').read_text(encoding='utf-8'))
        spec = importlib.util.spec_from_file_location('revieew_si_analysis', ROOT / 'analisar-n15c-revieew-suplementos.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_five_originals_rehash_within_non_pdf_limit(self):
        plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
        rows = [self.module.receipts.check_receipt(ROUND / (s['id'] + '.evidencia.json'), ROOT)
                for s in plan['requests']]
        self.assertEqual((len(rows), sum(r['usable'] for r in rows), sum(r['bodyVerified'] for r in rows)), (5, 5, 5))
        self.assertTrue(all(r['bytes'] < 2097152 for r in rows))

    def test_transparent_figure_labels_not_black_on_black(self):
        ident = 'c15-revieew-si2-tif'
        with Image.open(RAW / (ident + '.tif')) as original, Image.open(RAW / (ident + '.png')) as preview:
            self.assertEqual(original.format, 'TIFF')
            self.assertEqual(original.size, (1083, 1569))
            self.assertEqual(preview.size, original.size)
            self.assertEqual(original.getpixel((0, 0)), (0, 0, 0, 0))
            self.assertEqual(preview.getpixel((0, 0)), (255, 255, 255))
        self.assertEqual(self.reading['visualAudit']['numberOfFigures'], 3)
        self.assertTrue(self.reading['visualAudit']['originalTifsUnchanged'])

    def test_effect_table_structured_not_movement_recipe(self):
        paragraphs, tables, security = self.module.docx_text(RAW / 'c15-revieew-si4-docx.docx')
        self.assertEqual((len(tables), security['members'], security['uncompressedBytes']), (1, 11, 162763))
        self.assertEqual(tables[0][2], ['Average intensity', 'Medium', 'Medium', 'Medium', 'n.s.'])
        self.assertTrue(any('non-statistically significant' in p and 'p<0.05' in p for p in paragraphs))
        self.assertFalse(self.reading['tableSI1']['containsExerciseExecutionSteps'])
        for key in ['embeddedObjectsExecuted', 'macrosExecuted', 'externalReferencesFetched', 'extractedToDisk']:
            self.assertFalse(security[key])

    def test_squat_final_variant_keeps_isometric_pause(self):
        programme = json.loads((ROOT / '2026-10-07/n15c-programa/leitura-programa.json').read_text(encoding='utf-8'))
        squat = next(r for r in programme['movementPool'] if r['id'] == 'squat')
        self.assertEqual(squat['levels'][2], '3s_isometric_pause_plus_elastic_band_2.6kg')
        dose = self.reading['figures'][2]
        self.assertEqual([a + b for a, b in zip(dose['weeklyWorkSeconds'], dose['weeklyRestSeconds'])], [60] * 12)

    def test_published_figures_not_missing_videos_or_closure(self):
        self.assertEqual(self.reading['newIndependentProgrammeFamilies'], 0)
        self.assertTrue(self.reading['clinicalReevaluation']['singlePhysicalTherapistDeliveredSessionsExplicit'])
        self.assertFalse(self.reading['clinicalReevaluation']['homeCareEmploymentIsExercisePerformedAtParticipantsHome'])
        self.assertFalse(self.reading['rights']['externalVideosOrManualRightsInherited'])
        self.assertFalse(self.reading['researchClosureApproved'])
        self.assertFalse(self.reading['releaseApproved'])


if __name__ == '__main__':
    unittest.main()
