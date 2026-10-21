import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-guias-clinicos'


def read(name):
    return json.loads((FOLDER / name).read_text(encoding='utf-8'))


class GuideEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('guides', ROOT / 'analisar-n15c-guias-clinicos.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = read('leitura-fontes.json')
        cls.sources = {item['sourceId']: item for item in cls.reading['sources']}

    def test_bodies_and_failure_are_distinct(self):
        self.assertEqual(self.inventory['collectionCount'], 8)
        self.assertEqual(self.inventory['hashedBodies'], 7)
        self.assertEqual(self.inventory['usefulBodies'], 7)
        self.assertEqual(self.inventory['pdfPages'], 653)
        failed = next(row for row in self.inventory['receipts'] if 'egito2024' in row['id'])
        self.assertFalse(failed['usable'])
        self.assertIsNone(failed['sha256'])

    def test_annex_is_received_without_clinical_cards(self):
        index = read('indice-anexo-montero.json')
        self.assertEqual(index['referenceCount'], 147)
        self.assertFalse(index['referenceIdsAreIsolatedClinicallyProvenExercises'])
        self.assertTrue(all(not row['isApprovedExerciseCard'] for row in index['references']))
        self.assertEqual([row['session'] for row in index['sessions']], list(range(1, 37)))
        self.assertEqual(index['sessions'][-1]['pdfPage'], 362)
        self.assertTrue(all(not row['timerImportApproved'] for row in index['sessions']))

    def test_professional_individualisation_and_conflicts_preserved(self):
        thesis = self.sources['PR85']
        self.assertTrue(thesis['fullAnnexReceived'])
        self.assertTrue(thesis['authorshipAndDelivery']['professionallyDesignedExplicit'])
        self.assertTrue(thesis['authorshipAndDelivery']['professionallyIndividualisedDose'])
        self.assertFalse(thesis['authorshipAndDelivery']['apkInstructionsReplaceProfessional'])
        conflicts = {row['field']: row for row in thesis['conflicts']}
        self.assertEqual(conflicts['aerobicIntensity']['methodsHrmaxFinalRange'], [70, 80])
        self.assertIn('94', conflicts['aerobicIntensity']['annexPrintedRange'])
        self.assertFalse(conflicts['aerobicIntensity']['resolved'])
        self.assertFalse(thesis['rights']['laterArticleCcByAutomaticallyLicensesThesis'])
        self.assertFalse(thesis['rights']['factsAndCitationsBanned'])

    def test_visual_inspection_does_not_claim_all_653_pages(self):
        inspection = self.reading['inspection']
        numbers = inspection['visuallyInspectedPdfPagesOneBased']
        self.assertEqual(sum(len(pages) for pages in numbers.values()), 46)
        self.assertEqual(inspection['visuallyInspectedPageCount'], 46)
        self.assertNotIn('c15-fedema2022-manual-pdf', numbers)

    def test_duplicate_and_closure(self):
        self.assertFalse(self.inventory['duplicateOriginal']['newClinicalFamily'])
        self.assertEqual(self.inventory['duplicateOriginal']['sourceId'], 'PR71')
        for key in ['researchClosureApproved', 'releaseApproved', 'appImplemented']:
            self.assertFalse(self.reading[key])

    def test_integration_does_not_start_next_niche(self):
        main = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertEqual(main['latestGuideReading'], '2026-10-08/n15c-guias-clinicos/leitura-fontes.json')
        self.assertFalse(main['researchClosureApproved'])
        self.assertFalse(main['settingDecision']['studyStrictlyAtHomeRequired'])
        self.assertFalse(main['deliveryDecision']['apkInstructionsReplaceRequiredSupervision'])


if __name__ == '__main__':
    unittest.main()
