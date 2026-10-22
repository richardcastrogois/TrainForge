"""Casos isolados; nenhum dado sintetico e exportado para o piloto."""
import copy
import unittest
from conteudo_editorial import validate_bundle, authorize
from preparar_conteudo_local import asset, numeric_cell


class EditorialTests(unittest.TestCase):
    def bundle(self):
        item = asset("fixture:movement", "movement", "fixture:source", {"path": "fixture-only.json", "pointer": "", "snapshotSha256": "a"*64}, title="fixture")
        return {"schemaVersion": "1.0.0", "bundleId": "fixture-only", "stage": "candidate", "sources": [{"id": "fixture:source"}], "assets": [item]}

    def approved(self, operation="catalog_metadata"):
        b = self.bundle(); b["stage"] = "approved_operations"
        a = b["assets"][0];a["allowedOperations"] = [operation]
        a["rights"].update(attribution="fixture attribution", operationGrants={operation:"allowed"})
        a["review"].update(state="reviewed", reviewer="fixture reviewer", rightsVerified=True, fidelityChecked=True, safetyUseReviewed=True, instructionSufficient=True)
        a["audience"]["supportRequired"] = False
        return b

    def test_candidate_valid_but_no_operation_allowed(self):
        b=self.bundle();self.assertEqual(validate_bundle(b),[])
        self.assertFalse(authorize(b,"fixture:movement","catalog_metadata")[0])

    def test_candidate_cannot_self_approve(self):
        b=self.bundle();b["assets"][0]["allowedOperations"]=["catalog_metadata"]
        self.assertTrue(validate_bundle(b))

    def test_missing_provenance_rejected(self):
        b=self.bundle();b["assets"][0]["evidence"]=[]
        self.assertTrue(validate_bundle(b))

    def test_duplicate_and_unknown_source_rejected(self):
        b=self.bundle();b["assets"].append(copy.deepcopy(b["assets"][0]));self.assertTrue(validate_bundle(b))
        b=self.bundle();b["assets"][0]["sourceId"]="missing";self.assertTrue(validate_bundle(b))

    def test_missing_reference_rejected(self):
        b=self.bundle();b["assets"][0]["content"]["itemRefs"]=["missing"]
        self.assertTrue(validate_bundle(b))

    def test_dose_requires_valid_unit_and_origin(self):
        for measure in [{"quantity":30,"unit":"minutes?","sourceField":"x"},{"quantity":-1,"unit":"s","sourceField":"x"},{"quantity":True,"unit":"s","sourceField":"x"},{"quantity":float("nan"),"unit":"s","sourceField":"x"},{"quantity":30,"unit":"s"}]:
            b=self.bundle();b["assets"][0]["dose"]["measurements"]=[measure];self.assertTrue(validate_bundle(b))

    def test_absent_dose_stays_null(self):
        b=self.bundle();b["assets"][0]["dose"]["measurements"]=[{"quantity":None,"unit":"cm","sourceField":"known_missing"}]
        self.assertEqual(validate_bundle(b),[])
        self.assertIsNone(b["assets"][0]["dose"]["measurements"][0]["quantity"])

    def test_collection_cannot_inherit_efficacy(self):
        b=self.bundle();a=b["assets"][0];a["kind"]="collection";a["content"]["inheritsSourceEfficacy"]=True
        self.assertTrue(validate_bundle(b));a["content"]["inheritsSourceEfficacy"]=False;self.assertEqual(validate_bundle(b),[])

    def test_rights_for_one_operation_do_not_grant_another(self):
        b=self.approved();a=b["assets"][0];a["allowedOperations"].append("export_dataset")
        self.assertFalse(authorize(b,a["id"],"export_dataset")[0]);self.assertTrue(validate_bundle(b))

    def test_reviewed_metadata_operation(self):
        b=self.approved();self.assertTrue(authorize(b,"fixture:movement","catalog_metadata")[0]);self.assertEqual(validate_bundle(b),[])

    def test_review_not_pretended_when_missing(self):
        b=self.approved();b["assets"][0]["review"]["reviewer"]=None
        self.assertFalse(authorize(b,"fixture:movement","catalog_metadata")[0])
        b=self.approved();b["assets"][0]["review"]["state"]="pending"
        self.assertFalse(authorize(b,"fixture:movement","catalog_metadata")[0])

    def test_kind_and_attribution_required_for_text(self):
        b=self.approved("instruction_text");a=b["assets"][0]
        self.assertFalse(authorize(b,a["id"],"instruction_text")[0])
        a["kind"]="instruction";a["rights"]["attribution"]=None
        self.assertFalse(authorize(b,a["id"],"instruction_text")[0])

    def test_source_support_cannot_be_silently_removed(self):
        b=self.approved("guided_practice");a=b["assets"][0];a["audience"]["supportRequired"]=True
        self.assertFalse(authorize(b,a["id"],"guided_practice")[0])
        self.assertTrue(authorize(b,a["id"],"guided_practice",support_available=True)[0])
        a["audience"]["supportRequired"]=None
        self.assertFalse(authorize(b,a["id"],"guided_practice",support_available=True)[0])

    def test_zero_is_not_missing_or_trace(self):
        self.assertEqual(numeric_cell("0")["value"],0)
        self.assertEqual(numeric_cell("0")["state"],"numeric")
        for v in [None,"","-"]:self.assertEqual(numeric_cell(v)["state"],"missing")
        self.assertEqual(numeric_cell("Tr")["state"],"trace");self.assertIsNone(numeric_cell("Tr")["value"])

    def test_unknown_present_value_not_zero(self):
        self.assertEqual(numeric_cell("N")["state"],"present_quantity_unknown")
        self.assertIsNone(numeric_cell("N")["value"])

    def test_less_than_is_bound_not_measurement(self):
        x=numeric_cell("< 0,25");self.assertEqual(x["state"],"less_than");self.assertEqual(x["upperBound"],.25);self.assertIsNone(x["value"])

    def test_unexpected_values_preserved_not_coerced(self):
        for raw in ["NaN","Infinity","1e10000","-1","not a value"]:
            x=numeric_cell(raw);self.assertEqual(x["raw"],raw);self.assertEqual(x["state"],"unparsed");self.assertIsNone(x["value"])


if __name__ == "__main__":
    unittest.main()
