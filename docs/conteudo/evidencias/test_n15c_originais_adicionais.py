"""Protege identidade, dose e limites dos originais adicionais N15-C."""
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('n15_additional', ROOT / 'analisar-n15c-originais-adicionais.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AdditionalOriginalsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.inventories = {name: module.analyse(name) for name in module.ROUNDS}
        cls.moreira = json.loads((ROOT / '2026-10-08/n15c-moreira-cuidadores/leitura-fontes.json').read_text())
        cls.kirtan = json.loads((ROOT / '2026-10-08/n15c-kirtan-original/leitura-fontes.json').read_text())

    def test_five_actual_bodies_and_hashes(self):
        for name, count in zip(module.ROUNDS, [2, 3]):
            inventory = self.inventories[name]
            self.assertEqual(inventory['collectorCalls'], count)
            self.assertEqual(inventory['usableBodies'], count)
            self.assertEqual(inventory['hashedBodies'], count)

    def test_caregiver_dose_is_not_patient_dose(self):
        self.assertEqual(self.moreira['dose']['sessionMinutes'], 60)
        self.assertEqual(self.moreira['differentPatientStudy']['sessionMinutesInSpecificMethods'], 45)
        self.assertFalse(self.moreira['differentPatientStudy']['patientBedTransfersOrGaitCanBeImportedAsCaregiverExercise'])

    def test_annex_not_invented_as_manual(self):
        self.assertTrue(self.moreira['annexes']['consentExplicitlyMentionsExternalManual'])
        self.assertFalse(self.moreira['annexes']['externalManualBodyReceived'])
        self.assertIsNone(self.moreira['dose']['perExerciseSetsRepetitionsHoldOrRest'])

    def test_actual_negative_results_retained(self):
        self.assertFalse(self.moreira['results']['caregiverStressImprovementEstablished'])
        self.assertFalse(self.moreira['results']['lumbarPainImprovementEstablished'])
        self.assertEqual(self.kirtan['results']['hamdMeanChangeOneSidedP'], 0.06)
        self.assertFalse(self.kirtan['results']['biomarkerShowsLongevityOrPreventsAlzheimer'])

    def test_flyer_has_ending_but_is_not_trial_exact_version(self):
        self.assertTrue(self.kirtan['operationalFlyer']['ending'])
        self.assertEqual(sum(self.kirtan['operationalFlyer']['chantStagesMinutes']), 12)
        self.assertEqual(self.kirtan['doseAndDelivery']['chantMinutesReported'], 11)
        self.assertFalse(self.kirtan['operationalFlyer']['exact2011TrialFlyerOrCdIdentityConfirmed'])

    def test_professional_creation_and_support_not_assumed(self):
        self.assertTrue(self.moreira['professionalAuthorship']['sourceDeclaredProfessionalTeamVerified'])
        self.assertTrue(self.kirtan['professionalAuthorship']['initialTeachingAndSupervisionByNamedPhysician'])
        self.assertFalse(self.kirtan['professionalAuthorship']['medicalResearchersCreatedAncientTradition'])

    def test_register_does_not_overwrite_published_trial(self):
        self.assertEqual(self.kirtan['registryDifferences']['enrollmentActual'], 40)
        self.assertEqual(self.kirtan['registryDifferences']['articleRandomized'], 45)
        self.assertFalse(self.kirtan['registryDifferences']['automaticVersionMergeAllowed'])

    def test_no_release_no_other_niche(self):
        for reading in [self.moreira, self.kirtan]:
            self.assertFalse(reading['researchClosureApproved'])
            self.assertFalse(reading['releaseApproved'])
            self.assertFalse(reading['n21Started'])
            self.assertEqual(reading['newProgrammesApproved'], 0)

    def test_aggregate_preserves_additional_provenance(self):
        fiche = json.loads((ROOT / '2026-10-04/n15c-retomada/pesquisa-complemento.json').read_text(encoding='utf-8'))
        self.assertGreaterEqual(len(fiche['evidence']), 126)
        self.assertGreaterEqual(len(fiche['dependencies']), 63)
        received = {r['record'] for inv in self.inventories.values() for r in inv['sources']}
        self.assertTrue(received.issubset({r['record'] for r in fiche['evidence']}))
        for name in module.ROUNDS:
            self.assertIn(f'2026-10-08/{name}/leitura-fontes.json', fiche['dependencies'])
            self.assertIn(f'2026-10-08/{name}/inventario.json', fiche['dependencies'])


if __name__ == '__main__':
    unittest.main()
