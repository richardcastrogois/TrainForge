import importlib.util
import io
import json
from pathlib import Path
import unittest
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-grupo'


class GroupYogaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location('group_yoga',ROOT/'analisar-n15c-yoga-grupo.py')
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)
        cls.inventory = cls.module.analyse()
        cls.reading = json.loads((FOLDER/'leitura-fontes.json').read_text(encoding='utf-8'))
        cls.source = cls.reading['sources'][0]
        cls.supplement = json.loads((FOLDER/'leitura-suplemento.json').read_text(encoding='utf-8'))

    def test_bodies_and_nested_docx_integrity(self):
        self.assertEqual([self.inventory[k] for k in ['collectorCalls','http200','hashedBodies','usableBodies']],[2,2,2,2])
        self.assertEqual(self.supplement['memberBytes'],19943)
        self.assertEqual(self.supplement['memberSha256'],self.source['curricula']['memberSha256'])
        self.assertFalse(self.supplement['ooxmlAudit']['externalReferencesFetched'])
        self.assertTrue(any(p['text']=='Close with deep relaxation (Savasana)' for p in self.supplement['paragraphs']))

    def test_unsafe_paths_are_rejected_before_member_reading(self):
        data = io.BytesIO()
        with ZipFile(data,'w') as archive:
            archive.writestr('../bad.docx',b'x')
        with ZipFile(io.BytesIO(data.getvalue())) as archive:
            with self.assertRaises(ValueError):
                self.module.bounded_members(archive)

    def test_own_caregiver_results_not_controlled_or_sleep_superiority(self):
        self.assertEqual(self.source['clinicalDesign']['caregiversPrePostGds'],48)
        self.assertFalse(self.source['caregiverResults']['controlledCausalBenefitConfirmed'])
        self.assertEqual(self.source['classComparison']['sleepBetweenP'],0.0541)
        self.assertTrue(self.source['classComparison']['notLowIntensitySuperiorityProven'])
        self.assertFalse(self.source['caregiverResults']['isolatedPoseEfficacyClaim'])

    def test_curriculum_is_not_pose_script_or_release(self):
        self.assertTrue(self.source['operational']['originalCurriculumReceived'])
        self.assertFalse(self.source['curricula']['fullPerGestureStepDoseSafetyReceived'])
        self.assertTrue(self.source['operational']['liveInstructorCannotBeReplacedByApkText'])
        for k in ['researchClosureApproved','releaseApproved','appImplemented']:
            self.assertFalse(self.reading[k])


if __name__=='__main__':
    unittest.main()
