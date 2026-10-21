"""Tests of documentary boundaries, not medical suitability."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('domestic_package', ROOT / 'validar-pacote-domestico.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class DomesticPackageTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT / MODULE.PACKAGE).read_text(encoding='utf-8'))

    def test_research_fields(self):
        MODULE.validate_fields(self.data)

    def test_rejects_unsupported_mutations(self):
        mutations = [
            ('releaseApproved', True), ('appImplemented', True),
            ('identity.edition', '2026'), ('identity.environment', 'praca'),
            ('identity.caregiverOwnProgrammeDemonstrated', True),
            ('dose.secondsPerMovement', 30), ('dose.weeklyProgression', 'automatic'),
            ('dose.warmup', '5 min'), ('dose.repetitions', 10),
            ('delivery.initialResearchScreeningRequiredInStudy', False),
            ('delivery.dailyVideoSubmissionMandatoryInThisEdition', True),
            ('delivery.validatedAutonomousAppDelivery', True),
            ('cointervention.present', False), ('cointervention.exerciseOnlyEfficacyDemonstrated', True),
            ('rights.versionReportedInLocalArticle', '4.0'),
            ('coverage.stairs', True), ('coverage.stretchingRoutine', True),
            ('outcomesBoundary.fallsPreventionDemonstrated', True)
        ]
        for key, value in mutations:
            with self.subTest(key=key):
                data = copy.deepcopy(self.data)
                target = data
                parts = key.split('.')
                for part in parts[:-1]:
                    target = target[part]
                target[parts[-1]] = value
                with self.assertRaises(ValueError):
                    MODULE.validate_fields(data)

    def test_rejects_wrong_instruction_variant(self):
        for field, value in [('sourcePage', 1), ('support', 'sem_apoio'), ('alternating', True)]:
            with self.subTest(field=field):
                data = copy.deepcopy(self.data)
                data['movements'][4][field] = value
                with self.assertRaises(ValueError):
                    MODULE.validate_fields(data)

    def test_rejects_wrong_hash_or_outside_path(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'body').write_bytes(b'text')
            (root / 'record.json').write_text(json.dumps(
                {'status': 200, 'bytes': 4, 'bodyFile': 'body', 'sha256': 'wrong'}), encoding='utf-8')
            with self.assertRaises(ValueError):
                MODULE.verify_record('record.json', 'wrong', root)
            with self.assertRaises(ValueError):
                MODULE.verify_record('../outside.json', 'wrong', root)


if __name__ == '__main__':
    unittest.main()
