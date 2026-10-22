"""Fixtures are temporary candidates; never inserted in runtime or shipped food data."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from alimentos_lote import (analyze_source, cell_value, column_contract, digest,
                            index_rows, local_input, normalize_row)
from preparar_alimentos_v1 import analyze, check, PREPARED, CANDIDATES, REPORT


def fixture_row(source="AL-CIQUAL-2025", code="fixture-only", name="Fixture raw"):
    sheet = "composition nutritionnelle" if source == "AL-CIQUAL-2025" else "1.3 Proximates"
    return {"sourceId": source, "sourceVersion": "2025" if source == "AL-CIQUAL-2025" else "2021",
            "sourceFoodId": code, "nameOriginal": name, "nameLocale": "fr", "namePt": None,
            "sourceRowKey": f"{source}:{sheet}:2", "sheet": sheet, "row": 2,
            "sourceCodeConflict": False, "calculationsApproved": False, "runtimeImportApproved": False,
            "quantityBasis": {"quantity": 100, "unit": "g", "kind": "food", "source": "fixture"},
            "values": [{"column": 10, "raw": "0", "state": "numeric", "value": 0, "upperBound": None}]}


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False) + "\n", encoding="utf-8")


def fixture_snapshot(root, source="AL-CIQUAL-2025"):
    row = fixture_row(source)
    path = root / "content/local" / (source.lower() + ".jsonl")
    write_json(path, row)
    original = root / (source + ".fixture")
    original.write_bytes(b"isolated fixture, not food data")
    receipt = root / (source + ".receipt.json")
    write_json(receipt, {"status": 200, "sha256": digest(original)})
    return {"sourceId": source, "path": path.relative_to(root).as_posix(), "sha256": digest(path),
            "sourceFile": original.relative_to(root).as_posix(), "sourceSha256": digest(original),
            "receipt": receipt.relative_to(root).as_posix(), "receiptSha256": digest(receipt),
            "columnsByTable": {row["sheet"]: [{"column": 10, "header": "Water (g)"}]},
            "tables": 1, "tableRecords": 1, "uniqueFoods": 1, "uniqueSourceCodes": 1,
            "valueStates": {"numeric": 1}, "credits": "Fixture only; no runtime permission"}


class FoodStagingTests(unittest.TestCase):
    def test_zero_unknown_trace_and_upper_bound_are_distinct(self):
        for raw, state in ((None, "missing"), ("-", "missing"), ("Tr", "trace"), ("N", "present_quantity_unknown"),
                           ("0", "numeric"), ("<0,01", "less_than"), ("(0.07)", "unparsed"), ("-0.01", "unparsed")):
            with self.subTest(raw=raw):
                cell = {"raw": raw, "state": state, "value": 0 if state == "numeric" else None,
                        "upperBound": 0.01 if state == "less_than" else None}
                result = cell_value(cell)
                self.assertEqual(result["state"], state)
                if state == "less_than":
                    self.assertIsNone(result["valueDecimal"])
                    self.assertEqual(result["upperBoundDecimal"], "0.01")
                if state not in {"numeric", "less_than"}:
                    self.assertIsNone(result["valueDecimal"])
                    self.assertIsNone(result["upperBoundDecimal"])

    def test_changed_parsed_state_or_quantity_is_rejected(self):
        for cell in ({"raw": "Tr", "state": "numeric", "value": 0},
                     {"raw": "0.5", "state": "numeric", "value": 50},
                     {"raw": "", "state": "missing", "value": 0},
                     {"raw": "1", "state": "numeric", "value": True},
                     {"raw": "NaN", "state": "numeric", "value": 0}):
            with self.subTest(cell=cell), self.assertRaises(ValueError):
                cell_value(cell)

    def test_jones_factor_never_becomes_a_nutrient(self):
        row = fixture_row()
        row["values"][0]["column"] = 84
        columns = [column_contract(row["sourceId"], row["sheet"], {"column": 84, "header": "Facteur\nde\nJones"})]
        item = normalize_row(row, columns, False)
        cell = item["measurements"][0]
        self.assertEqual(columns[0]["kind"], "factor")
        self.assertFalse(cell["technicalCalculationCandidate"])
        self.assertIn("factor_is_not_food_nutrient", cell["blockingReasons"])

    def test_per_fatty_acid_denominator_is_detected_inside_proximates(self):
        row = fixture_row("AL-COFID-2021")
        columns = [column_contract(row["sourceId"], row["sheet"],
                                   {"column": 10, "header": "Satd FA /100g FA (g)"})]
        result = normalize_row(row, columns, False)
        self.assertIn("basis_is_fatty_acids_not_food", result["measurements"][0]["blockingReasons"])
        self.assertFalse(result["measurements"][0]["technicalCalculationCandidate"])

    def test_alcohol_exception_does_not_receive_grams_from_column_label(self):
        row = fixture_row("AL-COFID-2021")
        row["quantityBasis"].update(unit=None, kind="food_or_alcohol_exception")
        columns = [column_contract(row["sourceId"], row["sheet"], {"column": 10, "header": "Fat /100g food (g)"})]
        result = normalize_row(row, columns, False)
        self.assertIsNone(result["quantityBasis"]["unit"])
        self.assertIn("food_basis_unresolved", result["measurements"][0]["blockingReasons"])
        self.assertIsNone(result["preparation"])
        self.assertIsNone(result["namePt"])
        self.assertFalse(result["calculationsApproved"])

    def test_exact_numeric_candidate_still_has_no_permission(self):
        row = fixture_row()
        columns = [column_contract(row["sourceId"], row["sheet"], {"column": 10, "header": "Eau (g 100 g)"})]
        result = normalize_row(row, columns, False)
        self.assertTrue(result["measurements"][0]["technicalCalculationCandidate"])
        self.assertEqual(result["measurements"][0]["valueDecimal"], "0")
        self.assertFalse(result["runtimeImportApproved"])
        self.assertFalse(result["calculationsApproved"])

    def test_duplicate_code_preserves_two_names_and_quarantines_both(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.jsonl"
            one, two = fixture_row(name="Fixture raw"), fixture_row(name="Fixture cooked")
            two["row"] = 3
            two["sourceRowKey"] = f"{two['sourceId']}:{two['sheet']}:3"
            path.write_text("\n".join(json.dumps(r) for r in (one, two)), encoding="utf-8")
            index = index_rows(path, one["sourceId"], "2025", {one["sheet"]: []})
            self.assertEqual(len(index["identities"]), 2)
            self.assertEqual(index["conflicts"]["fixture-only"], {"Fixture raw", "Fixture cooked"})
            columns = [column_contract(one["sourceId"], one["sheet"], {"column": 10, "header": "Water (g)"})]
            first, second = [normalize_row(r, columns, True) for r in (one, two)]
            self.assertNotEqual(first["candidateIdentity"], second["candidateIdentity"])
            self.assertTrue(all("source_code_conflict" in r["measurements"][0]["blockingReasons"] for r in (first, second)))

    def test_same_source_row_conflict_is_not_silently_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fixture.jsonl"
            one, two = fixture_row(), fixture_row(name="Another preparation")
            path.write_text("\n".join(json.dumps(r) for r in (one, two)), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "conteúdos divergentes"):
                index_rows(path, one["sourceId"], "2025", {one["sheet"]: []})
            path.write_text("\n".join(json.dumps(one) for _ in range(2)), encoding="utf-8")
            self.assertEqual(index_rows(path, one["sourceId"], "2025", {one["sheet"]: []})["duplicates"], 1)

    def test_missing_or_duplicate_columns_and_nonfinite_basis_are_rejected(self):
        columns = [column_contract("AL-CIQUAL-2025", "composition nutritionnelle", {"column": 10, "header": "Water (g)"})]
        one = fixture_row()
        for values in ([], [one["values"][0]] * 2):
            row = copy.deepcopy(one)
            row["values"] = values
            with self.assertRaises(ValueError):
                normalize_row(row, columns, False)
        one["quantityBasis"]["quantity"] = float("inf")
        with self.assertRaises(ValueError):
            normalize_row(one, columns, False)

    def test_snapshot_tamper_and_approval_promotion_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = fixture_snapshot(root)
            output = []
            report = analyze_source(root, source, output.append)
            self.assertEqual(report["cells"], 1)
            self.assertFalse(report["runtimeImportApproved"])
            path = root / source["path"]
            row = json.loads(path.read_text())
            row["runtimeImportApproved"] = True
            write_json(path, row)
            with self.assertRaisesRegex(ValueError, "Hash"):
                analyze_source(root, source)
            source["sha256"] = digest(path)
            with self.assertRaisesRegex(ValueError, "não aprovados"):
                analyze_source(root, source)

    def test_relocated_clone_has_identical_candidate_and_checks_header_integrity(self):
        reports = []
        for _ in range(2):
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                entries = [fixture_snapshot(root, source) for source in ("AL-CIQUAL-2025", "AL-COFID-2021")]
                write_json(root / PREPARED, {"food": entries})
                families = [{"topic": "alimentos", "sourceId": family, "name": "Fixture", "researchStatus": "candidato",
                             "catalogRef": "fixture.json", "catalogPointer": "/0"} for family in ("AL04", "AL05")]
                families.append({"topic": "alimentos", "sourceId": "PR211", "name": "Image reference", "researchStatus": "referencia",
                                 "catalogRef": "fixture.json", "catalogPointer": "/1"})
                write_json(root / CANDIDATES, {"sourceFamilies": families})
                (root / REPORT).parent.mkdir(parents=True, exist_ok=True)
                report = analyze(root, write=True)
                self.assertEqual(report, check(root))
                self.assertEqual(report["familyCount"], 3)
                self.assertEqual(report["runtimeFoodsImported"], 0)
                self.assertNotIn("Water (g)", json.dumps(report))
                reports.append(report)
                metadata = root / report["localManifest"]["path"]
                metadata.write_text(metadata.read_text().replace('"g"', '"mg"'))
                with self.assertRaisesRegex(ValueError, "alterado"):
                    check(root)
        self.assertEqual(reports[0], reports[1])

    def test_structured_cell_and_missing_table_are_rejected(self):
        with self.assertRaises(ValueError):
            cell_value({"raw": {"quantity": 0}, "state": "unparsed"})
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = fixture_snapshot(root)
            source["tables"] = 2
            source["columnsByTable"]["absent"] = [{"column": 10, "header": "Water (g)"}]
            with self.assertRaisesRegex(ValueError, "Tabela preparada ausente"):
                analyze_source(root, source)

    def test_paths_cannot_escape_clone(self):
        with tempfile.TemporaryDirectory() as directory:
            for relative in ("../elsewhere", "C:/outside", "/outside"):
                with self.assertRaises(ValueError):
                    local_input(Path(directory), relative)


if __name__ == "__main__":
    unittest.main()
