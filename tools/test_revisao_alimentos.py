"""Reviewed food projection fixtures stay local to these tests."""
import copy
import unittest

from alimentos_lote import column_contract
from revisar_alimentos_v1 import project_food, source_basis


def row(code="fixture", name="Fixture raw", group="DG", source="AL-COFID-2021"):
    return {"sourceId": source, "sourceVersion": "2021" if source == "AL-COFID-2021" else "2025",
            "sourceFoodId": code, "nameOriginal": name, "nameLocale": "en",
            "sourceContext": [code, name, None, group], "sheet": "1.3 Proximates",
            "row": 4, "sourceRowKey": f"{source}:1.3 Proximates:4",
            "quantityBasis": {"kind": "food_or_alcohol_exception", "quantity": 100, "unit": None},
            "values": [{"column": 8, "raw": "0", "state": "numeric", "value": 0, "upperBound": None}]}


def policy():
    rights = {k: "fixture" for k in ("name", "publisher", "sourceUrl", "licenseLabel", "licenseUrl",
                                   "attribution", "publishedAt", "changes", "warrantyNotice")}
    rights.update(sourceId="AL-COFID-2021", sourceVersion="2021", snapshotSha256="a" * 64,
                  preparedSha256="b" * 64, conditions=["fixture"])
    return {"cofidGroupPolicy": {"knownGroups": ["DG", "Q", "QA"], "alcoholGroups": ["Q", "QA"]},
            "sources": [rights]}


def columns(value, header="Water (g)"):
    return {value["sheet"]: [column_contract(value["sourceId"], value["sheet"], {"column": 8, "header": header})]}


class ReviewedFoodTests(unittest.TestCase):
    def test_group_resolves_base_without_guessing_from_name(self):
        rule = policy()["cofidGroupPolicy"]
        self.assertEqual(source_basis("AL-COFID-2021", row(name="Alcohol-free", group="QA"), rule)[0]["unit"], "ml")
        self.assertEqual(source_basis("AL-COFID-2021", row(name="Beer", group="DG"), rule)[0]["unit"], "g")
        self.assertIsNone(source_basis("AL-COFID-2021", row(group="QX"), rule)[0]["unit"])

    def test_unknown_group_preserves_composition_and_blocks_scaling(self):
        item = row(group="BTM")
        food = project_food(item["sourceId"], [item], columns(item), policy(), "c" * 64)
        self.assertIsNone(food["basis"]["unit"])
        self.assertEqual(food["nutrients"][0]["value"], "0")
        self.assertFalse(food["nutrients"][0]["scalingAllowed"])
        self.assertNotIn("food_quantity_scale", food["allowedOperations"])
        self.assertFalse(food["provenance"]["clinicalApproval"])

    def test_per_100g_food_label_in_alcohol_does_not_silently_become_ml(self):
        item = row(group="QA")
        food = project_food(item["sourceId"], [item], columns(item, "Fat /100g food (g)"), policy(), "c" * 64)
        self.assertEqual(food["basis"]["unit"], "ml")
        nutrient = food["nutrients"][0]
        self.assertIsNone(nutrient["basisUnit"])
        self.assertEqual(nutrient["declaredColumnBasis"]["unit"], "g")
        self.assertIn("source_basis_declarations_conflict", nutrient["reasons"])

    def test_trace_and_unknown_are_retained_not_zero_or_scalable(self):
        item = row()
        item["values"][0].update(raw="Tr", state="trace", value=None)
        food = project_food(item["sourceId"], [item], columns(item), policy(), "c" * 64)
        self.assertEqual(food["nutrients"][0]["state"], "trace")
        self.assertIsNone(food["nutrients"][0]["value"])
        self.assertNotIn("food_quantity_scale", food["allowedOperations"])

    def test_factors_and_fatty_acid_denominators_are_not_imported_as_nutrients(self):
        item = row()
        food = project_food(item["sourceId"], [item], columns(item, "Satd FA /100g FA (g)"), policy(), "c" * 64)
        self.assertEqual(food["nutrients"], [])
        self.assertEqual(food["provenance"]["auxiliaryCellsExcluded"]["fatty_acids_basis"], 1)
        factor = copy.deepcopy(item)
        factor["sheet"] = "1.2 Factors"
        factor["sourceRowKey"] = f"{factor['sourceId']}:1.2 Factors:4"
        factor["quantityBasis"] = {"kind": "factor", "quantity": None, "unit": None}
        food = project_food(factor["sourceId"], [factor], columns(factor, "Specific gravity"), policy(), "c" * 64)
        self.assertEqual(food["nutrients"], [])
        self.assertEqual(food["provenance"]["auxiliaryCellsExcluded"]["factor"], 1)

    def test_mixed_preparation_or_group_and_wrong_version_are_rejected(self):
        one = row()
        for two in (row(name="Fixture cooked"), row(group="QA"), {**row(), "sourceVersion": "1999"}):
            with self.assertRaises(ValueError):
                project_food(one["sourceId"], [one, two], columns(one), policy(), "c" * 64)

    def test_food_identity_is_stable_for_same_source_code_and_provider_stays_separate(self):
        one = row()
        a = project_food(one["sourceId"], [one], columns(one), policy(), "c" * 64)
        renamed = row(name="A clearer source name")
        b = project_food(renamed["sourceId"], [renamed], columns(renamed), policy(), "c" * 64)
        self.assertEqual(a["foodId"], b["foodId"])
        self.assertNotEqual(a["nameOriginal"], b["nameOriginal"])
        self.assertEqual(a["sourceFoodId"], "fixture")
        self.assertTrue(a["nutrients"][0]["scalingAllowed"])


if __name__ == "__main__":
    unittest.main()
