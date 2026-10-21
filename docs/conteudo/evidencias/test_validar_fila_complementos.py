"""Local regression checks for the complement queue gate; no network or app."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

PATH = Path(__file__).with_name("validar-fila-complementos.py")
SPEC = importlib.util.spec_from_file_location("complement_gate", PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ComplementGateTests(unittest.TestCase):
    def setUp(self):
        self.queue = json.loads(MODULE.PATH.read_text(encoding="utf-8"))

    def test_current_queue_keeps_n21_closed(self):
        summary = MODULE.validate(self.queue)
        self.assertFalse(summary["n21Allowed"])
        self.assertEqual(summary["nichesChecked"], 20)
        self.assertEqual(summary["activeComplement"], "N15-C")
        active, _ = MODULE.read(self.queue["activeEvidence"])
        self.assertEqual(active["audienceDecision"]["selection"], "especifico_para_cuidadores_em_casa")
        self.assertFalse(active["audienceDecision"]["genericProgrammeAsSubstituteAccepted"])
        self.assertFalse(active["researchClosureApproved"])
        self.assertEqual(summary["states"],
                         {"reuso_documentado_sem_nova_coleta": 6,
                          "concluido_para_pesquisa": 10, "pendente": 3,
                          "em_andamento": 1})

    def test_research_closures_do_not_approve_publication(self):
        for index in (12, 15, 16):
            row = self.queue["niches"][index]
            self.assertEqual(row["complementStatus"], "concluido_para_pesquisa")
            self.assertFalse(row["researchApprovedForPublication"])
            for ref in row["closureEvidence"]:
                spec, _ = MODULE.read(ref)
                self.assertTrue(spec["researchClosureApproved"])
                self.assertFalse(spec["releaseApproved"])
                self.assertFalse(spec["appImplemented"])

    def test_new_partial_rounds_cannot_close_n17_to_n20(self):
        refs = {
            16: "2026-10-03/n17i-instrucao/pesquisa-complemento.json",
            17: "2026-10-04/n18i-academia/pesquisa-complemento.json",
            18: "2026-10-04/n19i-percursos/pesquisa-complemento.json",
            19: "2026-10-04/n20i-instrucao/pesquisa-complemento.json",
        }
        for index, ref in refs.items():
            with self.subTest(niche=self.queue["niches"][index]["niche"]):
                queue = copy.deepcopy(self.queue)
                queue["niches"][index].update(
                    complementStatus="concluido_para_pesquisa", closureEvidence=[ref])
                # Keep the pointer coherent so this mutation tests the closure gate.
                if queue["activeComplement"].split("-")[0] == queue["niches"][index]["niche"]:
                    queue["activeComplement"] = None
                    queue["activeEvidence"] = None
                with self.assertRaisesRegex(ValueError, "Partial evidence"):
                    MODULE.validate(queue)

    def test_reject_unproven_release_and_inconsistent_queue(self):
        cases = [
            ("release_n21", lambda q: q.update(n21Allowed=True)),
            ("close_all", lambda q: q.update(allPreviousComplementsResearchClosed=True)),
            ("missing_niche", lambda q: q["niches"].pop()),
            ("two_active", lambda q: q["niches"][16].update(complementStatus="em_andamento")),
            ("wrong_actor", lambda q: q.update(activeComplement="N14-C")),
            ("missing_active", lambda q: next(
                row for row in q["niches"]
                if row["niche"] == q["activeComplement"].split("-")[0]
            ).update(complementStatus="pendente")),
            ("unproven_closure", lambda q: q["niches"][17].update(
                complementStatus="concluido_para_pesquisa")),
            ("reuse_changed", lambda q: q["niches"][0].update(newCollectionRequired=True)),
            ("duplicate_complement", lambda q: q["researchOrder"].append("N15-C")),
            ("closed_without_evidence", lambda q: q["niches"][5].update(closureEvidence=[])),
            ("wrong_closure_actor", lambda q: q["niches"][5].update(
                closureEvidence=q["niches"][6]["closureEvidence"])),
            ("partial_n15_cannot_close", lambda q: q["niches"][14].update(
                complementStatus="concluido_para_pesquisa",
                closureEvidence=["2026-10-04/n15c-retomada/pesquisa-complemento.json"])),
            ("only_n15i_cannot_close_parent", lambda q: q["niches"][14].update(
                complementStatus="concluido_para_pesquisa",
                closureEvidence=["2026-10-04/n15i-funcional/pesquisa-complemento.json"]))
        ]
        for name, mutate in cases:
            with self.subTest(case=name):
                queue = copy.deepcopy(self.queue)
                mutate(queue)
                with self.assertRaises(ValueError):
                    MODULE.validate(queue)


if __name__ == "__main__":
    unittest.main()
