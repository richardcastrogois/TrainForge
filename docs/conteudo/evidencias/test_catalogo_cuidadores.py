"""Keep modular caregiver curation traceable and distinct from published prescriptions."""
import copy
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('caregiver_catalogue', ROOT / 'consultar-cuidadores.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CaregiverCatalogueTests(unittest.TestCase):
    def test_real_catalogue_has_five_families_and_ninety_fields(self):
        audit = module.validate()
        self.assertEqual(audit['items'], 5)
        self.assertEqual(audit['mappedFields'], 90)
        self.assertEqual(audit['exerciseOrTechniqueComponentsIndexed'], 19)
        self.assertEqual(audit['programmePhasesIndexed'], 3)
        self.assertEqual(audit['networkCalls'], 0)
        self.assertEqual(audit['publishedItems'], 0)
        self.assertFalse(audit['researchClosureApproved'])

    def test_different_programme_cannot_fill_missing_instructions(self):
        data = module.load_catalogue()
        data['items'][1]['sources']['original'] = copy.deepcopy(data['items'][0]['sources']['static'])
        with self.assertRaisesRegex(ValueError, 'different programme'):
            module.validate(data)

    def test_documentary_consolidation_does_not_approve_publication(self):
        data = module.load_catalogue()
        data['releaseApproved'] = True
        with self.assertRaisesRegex(ValueError, 'silently approve'):
            module.validate(data)

    def test_programme_result_cannot_validate_component_in_isolation(self):
        data = module.load_catalogue()
        data['items'][0]['components'][0]['standaloneClaimApproved'] = True
        with self.assertRaisesRegex(ValueError, 'isolated component'):
            module.validate(data)

    def test_paths_cannot_escape_documentation_root(self):
        with self.assertRaisesRegex(ValueError, 'outside documentation'):
            module.bounded_path('../../AGENTS.md')


if __name__ == '__main__':
    unittest.main()
