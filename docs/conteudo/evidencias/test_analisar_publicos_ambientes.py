"""Regression checks for the documentary audit, with no network or app execution."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

PATH = Path(__file__).with_name("analisar-publicos-ambientes.py")
SPEC = importlib.util.spec_from_file_location("publics_audit", PATH)
AUDITOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDITOR)


class PopulationAuditTests(unittest.TestCase):
    def setUp(self):
        self.audit = json.loads(
            (AUDITOR.FOLDER / "matriz-publicos-ambientes.json").read_text(encoding="utf-8"))

    def test_complete_local_matrix(self):
        summary = AUDITOR.audit_matrix(self.audit)
        self.assertEqual(summary["contextAssessments"], 80)
        self.assertEqual(summary["nextNichesWithCriteria"], 26)
        self.assertEqual(summary["coverageCounts"],
                         {"base_generica": 56, "parcial_especifica": 2, "nao_demonstrado": 22})
        self.assertEqual(len(summary["evidenceSnapshots"]), 26)
        self.assertFalse(summary["releaseApproved"])
        self.assertEqual(summary["newCalls"], 0)

    def test_reject_incomplete_or_unproven_coverage(self):
        mutations = [
            ("missing_niche", lambda d: d["niches"].pop()),
            ("missing_context", lambda d: d["niches"][0]["contexts"].pop()),
            ("missing_future", lambda d: d["nextNiches"].pop()),
            ("caregiver_programme", lambda d: d["supplements"][0].update(
                caregiverOwnHomeProgrammeDemonstrated=True)),
            ("outdoor_coverage", lambda d: d["niches"][14]["contexts"][1].update(
                status="parcial_especifica")),
            ("release", lambda d: d.update(releaseApproved=True)),
            ("missing_gap", lambda d: d["niches"][0]["contexts"][0].update(gap="")),
            ("missing_criterion", lambda d: d["nextNiches"][0].update(criterion=""))
        ]
        for name, mutate in mutations:
            with self.subTest(case=name):
                audit = copy.deepcopy(self.audit)
                mutate(audit)
                with self.assertRaises(ValueError):
                    AUDITOR.audit_matrix(audit)


if __name__ == "__main__":
    unittest.main()
