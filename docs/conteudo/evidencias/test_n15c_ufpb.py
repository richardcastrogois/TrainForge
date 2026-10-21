import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-ufpb'


class CaregiverGuideTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.guide = json.loads((ROUND / 'leitura-guia.json').read_text(encoding='utf-8'))

    def test_receipts_and_error_not_guide(self):
        spec = importlib.util.spec_from_file_location('ufpb_test_receipts', ROOT / 'analisar-n15c-manuais.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        requests = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))['requests']
        entries = [module.check_receipt(ROUND / (r['id'] + '.evidencia.json'), ROOT) for r in requests]
        self.assertEqual(len(entries), 5)
        self.assertEqual(sum(e['usable'] for e in entries), 4)
        self.assertEqual(entries[0]['status'], 404)
        self.assertFalse(entries[0]['usable'])
        for body in self.guide['sourceBodies']:
            checked = module.check_receipt(ROOT / body['receipt'], ROOT)
            self.assertTrue(checked['usable'])
            self.assertEqual(checked['sha256'], body['sha256'])

    def test_professional_authorship_and_validation_scope(self):
        authors = self.guide['professionalAuthorship']
        self.assertTrue(authors['sourceProfessionalQualificationExplicit'])
        self.assertIn('PDF70', authors['locator'])
        self.assertFalse(authors['legalProfessionalRegistrationChecked'])
        evidence = self.guide['evidenceBasis']
        self.assertEqual(evidence['caregivers'], 15)
        self.assertEqual(evidence['globalContentValidityIndex'], 0.9)
        self.assertFalse(evidence['clinicalEfficacyMeasured'])
        self.assertFalse(evidence['randomizedExerciseTrial'])

    def test_nd_not_nc_and_version_rights_not_transferred(self):
        rights = self.guide['rights']
        self.assertEqual(rights['thesis2018']['licence'], 'CC BY-ND 3.0 BR')
        self.assertFalse(rights['thesis2018']['nonCommercialRestriction'])
        self.assertTrue(rights['thesis2018']['unchangedCommercialRedistributionPotential'])
        self.assertFalse(rights['thesis2018']['modifiedDistributionAllowedByThisLicence'])
        self.assertFalse(rights['guide2020']['inherits2018Licence'])
        self.assertFalse(rights['guide2020']['localBodyReceived'])
        self.assertFalse(rights['releaseRightsApproved'])

    def test_units_and_absent_dose_not_invented(self):
        records = {r['id']: r for r in self.guide['records']}
        self.assertEqual(len(records), 12)
        dose = records['UF18-C12']['sourceDose']
        self.assertEqual((dose['inhaleCount'], dose['holdBreathSeconds'], dose['exhaleCount']), (10, 5, 10))
        self.assertIsNone(dose['inhaleSeconds'])
        self.assertIsNone(dose['exhaleSeconds'])
        self.assertIsNone(records['UF18-C05']['sourceDose']['repetitions'])
        self.assertIsNone(records['UF18-C06']['sourceDose']['seconds'])
        self.assertTrue(records['UF18-C03']['instructionConflict'])
        self.assertFalse(self.guide['programmeLimits']['missingSecondsFilledFromOtherProgrammes'])

    def test_actor_environment_and_visual_audit(self):
        self.assertEqual(self.guide['population']['practitioner'], 'cuidador_para_si')
        self.assertFalse(self.guide['population']['patientHandlingSectionsAreOwnExercise'])
        self.assertEqual(self.guide['audit']['visuallyInspectedPdfPages'], list(range(68, 84)))
        self.assertEqual(len(self.guide['audit']['renderedPdfPages']), 22)
        walk = next(r for r in self.guide['records'] if r['id'] == 'UF18-C09')
        self.assertEqual(walk['setting'], 'proximidades_da_residencia')

    def test_no_closure_or_synthetic_programme(self):
        for key in ('researchClosureApproved', 'releaseApproved', 'importAllowed', 'appImplemented'):
            self.assertFalse(self.guide[key])
        self.assertEqual(self.guide['programmeLimits']['newSessionsCreated'], 0)
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertIn('2026-10-07/n15c-ufpb/leitura-guia.json', fiche['dependencies'])
        queue = json.loads((ROOT / '2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json').read_text(encoding='utf-8'))
        self.assertEqual(queue['activeComplement'], 'N15-C')
        self.assertFalse(queue['n21Allowed'])
        catalogue = json.loads((ROOT.parent / 'fontes.json').read_text(encoding='utf-8'))
        self.assertEqual([r['status'] for r in catalogue['sources'] if r['id'] == 'PR69'], ['condicional'])


if __name__ == '__main__':
    unittest.main()
