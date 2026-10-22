"""Decisoes de consulta em fixtures isoladas; nao produz dados do piloto."""
import copy
import unittest
import hashlib
import io
import json
import tempfile
from pathlib import Path
from unittest.mock import patch
from contextlib import redirect_stdout
import revisar_conteudo_local as review_tool
from conteudo_editorial import authorize
from preparar_conteudo_local import asset
from revisar_conteudo_local import digest, review_bundle
from fechar_triagem_piloto import classify


class ConsultationReviewTests(unittest.TestCase):
    def fixture(self):
        ref = {"path":"fixture-only.json", "pointer":"", "snapshotSha256":"a"*64}
        rights = {"label":"CC-BY-SA 4", "licenseUrl":"https://creativecommons.org/licenses/by-sa/4.0/deed.en", "attribution":"fixture", "scope":"movement_metadata"}
        m = asset("fixture:movement", "movement", "EX01", ref, title="fixture-only", rights=rights,
                  content={"instructionRef":"fixture:instruction", "instructionsAvailable":1, "imageReferencesAvailable":3, "videoReferencesAvailable":1})
        t = asset("fixture:instruction", "instruction", "EX01", ref, rights=dict(rights,scope="instruction_text"), content={"movementRef":m["id"]})
        b = {"schemaVersion":"1.0.0", "bundleId":"fixture-only", "stage":"candidate", "sources":[{"id":"EX01"}], "assets":[m,t]}
        d = {"reviewer":"fixture-only reviewer", "approvedOperations":[{"assetId":m["id"], "assetSha256":digest(m), "operation":"catalog_metadata", "conditions":["fixture condition"],
             "credits":{"title":"fixture-only", "creators":["fixture"], "sourceUrl":"https://example.invalid/fixture", "licenseUrl":rights["licenseUrl"], "changes":"fixture", "warrantyNotice":"fixture"}}]}
        return b,d

    def test_projection_has_only_approved_relations_and_never_enables_practice(self):
        b,d=self.fixture(); r=review_bundle(b,d); a=r["assets"][0]
        self.assertEqual(len(r["assets"]),1);self.assertIsNone(a["content"]["instructionRef"])
        self.assertEqual(a["content"]["imageReferencesAvailable"],0)
        self.assertEqual(a["content"]["sourceAvailability"]["imageReferencesAvailable"],3)
        self.assertTrue(authorize(r,a["id"],"catalog_metadata")[0])
        self.assertFalse(authorize(r,a["id"],"guided_practice",support_available=True)[0])
        self.assertFalse(authorize(r,a["id"],"export_dataset")[0])
        self.assertFalse(r["runtimeSeed"])

    def test_full_disposition_covers_exclusions_without_inventing_practice(self):
        b,d=self.fixture();d["portugueseInstructionFindings"]=[]
        result=classify(b,d)
        self.assertEqual(result["totalAssets"],2)
        self.assertEqual(result["counts"],{"metadata_consultation":1,"excluded_from_pilot":1})
        self.assertEqual(result["practiceAllowed"],0)
        self.assertTrue(result["rows"][1]["exclusionCodes"])
        self.assertFalse(result["allAssetsPublishable"])

    def test_licence_does_not_prove_professional_authorship(self):
        b,d=self.fixture();t=b["assets"][1]
        d["publicationPolicy"]={"professionalAuthorshipRequiredForTeaching":True}
        d["approvedOperations"].append(dict(d["approvedOperations"][0],assetId=t["id"],assetSha256=digest(t),operation="instruction_text"))
        with self.assertRaises(ValueError):review_bundle(b,d)

    def test_written_payload_hash_matches_actual_bytes_on_windows(self):
        b,d=self.fixture()
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder)
            for sub in ["content/local","content/manifests","tools"]:(root/sub).mkdir(parents=True,exist_ok=True)
            candidate=root/"content/local/candidate.json"
            candidate.write_text(json.dumps(b),encoding="utf-8")
            d["sourceBundle"]={"path":"content/local/candidate.json","sha256":hashlib.sha256(candidate.read_bytes()).hexdigest()}
            (root/review_tool.DECISIONS).write_text(json.dumps(d),encoding="utf-8")
            (root/"tools/revisar_conteudo_local.py").write_text("fixture tool",encoding="utf-8")
            with patch.object(review_tool,"ROOT",root),patch("sys.argv",["fixture","--write","--check"]),redirect_stdout(io.StringIO()):review_tool.main()
            report=json.loads((root/review_tool.REPORT).read_text(encoding="utf-8"))
            raw=(root/review_tool.TARGET).read_bytes()
            self.assertNotIn(b"\r\n",raw)
            self.assertEqual(report["output"]["sha256"],hashlib.sha256(raw).hexdigest())

    def test_original_candidate_not_modified(self):
        b,d=self.fixture(); before=copy.deepcopy(b); review_bundle(b,d); self.assertEqual(b,before)

    def test_changed_asset_or_new_id_requires_new_review(self):
        b,d=self.fixture(); b["assets"][0]["title"]="changed"
        with self.assertRaises(ValueError):review_bundle(b,d)
        b,d=self.fixture();d["approvedOperations"][0]["assetId"]="unknown"
        with self.assertRaises(ValueError):review_bundle(b,d)

    def test_no_practice_escalation_from_metadata_review(self):
        b,d=self.fixture();d["approvedOperations"][0]["operation"]="guided_practice"
        with self.assertRaises(ValueError):review_bundle(b,d)

    def test_attribution_and_license_must_match(self):
        b,d=self.fixture();d["approvedOperations"][0]["credits"]["sourceUrl"]=""
        with self.assertRaises(ValueError):review_bundle(b,d)
        b,d=self.fixture();d["approvedOperations"][0]["credits"]["licenseUrl"]="another license"
        with self.assertRaises(ValueError):review_bundle(b,d)

    def test_blocked_asset_cannot_enter_the_approved_projection(self):
        b,d=self.fixture(); b["assets"][0]["review"]["state"]="blocked"
        d["approvedOperations"][0]["assetSha256"]=digest(b["assets"][0])
        with self.assertRaises(ValueError):review_bundle(b,d)


if __name__ == "__main__":
    unittest.main()
