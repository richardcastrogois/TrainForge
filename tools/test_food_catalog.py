"""Meaningful offline contract tests; synthetic data is never a release catalog."""
from __future__ import annotations

import base64
import csv
import hashlib
import gzip
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from food_catalog import (CatalogWriter, canonical, canonical_cells, community_foods, decimal_text, decode_storage_json,
                          folded, legacy_foods, make_food, normalized_barcode,
                          off_foods, parse_value, portion, sign_manifest,
                          verify_bundle, storage_json, sha_file)
from food_catalog_resume import metric_off_count, trim_export, gzip_members


SOURCE={"name":"Synthetic source","publisher":"Test fixture","url":"https://example.invalid/food",
        "licenseLabel":"CC0 1.0","licenseUrl":"https://creativecommons.org/publicdomain/zero/1.0/",
        "attribution":"Synthetic test data","version":"1","conditions":[]}


def cell(value="20",name="Proteína",unit="g",key="fixture:protein",**extra):
    return {"sourceColumnKey":key,"nameOriginal":name,"unit":unit,**parse_value(value),
            "basisQuantity":"100","basisUnit":"g","scalingAllowed":True,**extra}


class FoodCatalogTests(unittest.TestCase):
    def test_export_recovery_preserves_committed_gzip_members_and_trims_only_tail(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);path=root/"source.jsonl.gz"
            with gzip.GzipFile(filename=str(path),mode="wb",mtime=0) as out:out.write(b'1\n2\n')
            first=path.read_bytes()
            with gzip.GzipFile(filename=str(path),mode="ab",mtime=0) as out:out.write(b'3\n4\n5\n')
            original=path.read_bytes()
            self.assertEqual([m[2] for m in gzip_members(path)],[2,3])
            trim_export(path,4,root/"backup")
            self.assertEqual(gzip.decompress(path.read_bytes()),b'1\n2\n3\n4\n')
            self.assertTrue(path.read_bytes().startswith(first))
            self.assertEqual((root/"backup/source.jsonl.gz").read_bytes(),original)

    def test_export_recovery_can_repair_missing_last_footer_without_inventing_rows(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);path=root/"source.jsonl.gz"
            with gzip.GzipFile(filename=str(path),mode="wb",mtime=0) as out:out.write(b'1\n2\n')
            with gzip.GzipFile(filename=str(path),mode="ab",mtime=0) as out:out.write(b'3\n4\n')
            path.write_bytes(path.read_bytes()[:-8])
            self.assertFalse(gzip_members(path)[-1][3])
            trim_export(path,3,root/"backup")
            self.assertEqual(gzip.decompress(path.read_bytes()),b'1\n2\n3\n')

    def test_off_coverage_uses_same_parser_even_when_optional_columns_missing(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d)/"off.csv.gz"
            with gzip.open(path,"wt",encoding="utf-8",newline="") as stream:
                stream.write("code\tproduct_name\tquantity\textra\n")
                stream.write("6291041500213\tFood with missing optional tail\t100 g\n")
                stream.write("012345678905\tAnother food\t100 g\t\n")
                stream.write("0000000000000\t   \t100 g\t\n")
            total,usable=metric_off_count(path)
            self.assertEqual((total,usable),(3,2))
            self.assertEqual(len(list(off_foods(path,"snapshot"))),usable)

    def test_storage_compression_is_lossless_for_originals_and_decimals(self):
        value=[cell("0.00000000000000000001") for _ in range(30)]
        encoded=storage_json(value)
        self.assertTrue(encoded.startswith("zlib:"))
        self.assertLess(len(encoded),len(canonical(value)))
        self.assertEqual(decode_storage_json(encoded),value)
    def test_community_export_requires_explicit_consent_and_review(self):
        row={"contract":"trainforge.food-contribution-export/1","sourceId":"TF-COMMUNITY-1",
             "sourceFoodId":"12345678-1234-1234-1234-123456789012","reviewedAt":"2026-11-17T12:00:00Z",
             "consent":{"accepted":True,"version":"trainforge.food-contribution/1","license":"CC0-1.0"},
             "food":{"name":"Contribuição de teste","basis":{"quantity":"100","unit":"g"},
                     "nutrients":[{"name":"Proteína","unit":"g","value":"8"}]}}
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"approved.jsonl";p.write_text(canonical(row)+"\n",encoding="utf-8")
            result=next(community_foods(p))
            self.assertEqual(result["sourceId"],"TF-COMMUNITY-1")
            self.assertEqual(result["canonicalNutrients"][0]["value"],"8")
            self.assertNotIn("userId",canonical(result))
            row["consent"]["accepted"]=False
            p.write_text(canonical(row)+"\n",encoding="utf-8")
            with self.assertRaisesRegex(ValueError,"consent"):next(community_foods(p))

    def test_decimal_strings_do_not_round_through_binary_float(self):
        self.assertEqual(decimal_text("0.1000000000000000000000000001"),"0.1000000000000000000000000001")
        self.assertEqual(decimal_text("1,500"),"1.5")
        for value in [None,True,"NaN","Infinity","-1","not a number"]:
            self.assertIsNone(decimal_text(value))

    def test_unknown_trace_bound_and_zero_are_distinct(self):
        for value,state in [("", "missing"),("NA","missing"),("Tr","trace"),("N","present_quantity_unknown"),("<0.1","less_than"),("0","numeric"),("invalid","unparsed")]:
            self.assertEqual(parse_value(value)["state"],state)
        self.assertEqual(parse_value("0")["value"],"0")
        self.assertIsNone(parse_value("Tr")["value"])
        self.assertEqual(parse_value("<0.1")["upperBound"],"0.1")

    def test_canonical_totals_choose_only_one_energy_method(self):
        a=cell("100","Energy (Atwater General)","kcal","energy:a")
        b=cell("101","Energy (Atwater Specific)","kcal","energy:b")
        result=canonical_cells([a,b],"source")
        self.assertEqual([r["primaryForTotals"] for r in result],[True,False])
        self.assertNotEqual(result[0]["methodId"],result[1]["methodId"])
        self.assertEqual([r["value"] for r in result],["100","101"])

    def test_incompatible_energy_units_never_get_added(self):
        original=[cell("418","Energy","kJ","kj"),cell("100","Energy","kcal","kcal")]
        result=canonical_cells(original,"source")
        self.assertEqual(len(result),1)
        self.assertEqual(result[0]["nutrientId"],"energy_kcal")

    def test_metric_conversion_keeps_original_cell_unchanged(self):
        original=cell("0.002","Sodium","g","sodium",nutrientId="sodium_mg")
        self.assertEqual(canonical_cells([original],"source")[0]["value"],"2")
        self.assertEqual(original["value"],"0.002")
        self.assertEqual(original["unit"],"g")

    def test_missing_basis_blocks_canonical_scaling(self):
        result=canonical_cells([cell(basisQuantity=None,basisUnit=None)],"source")
        self.assertFalse(result[0]["primaryForTotals"])

    def test_gtin_preserves_original_and_normalizes_only_valid_digits(self):
        self.assertEqual(normalized_barcode("6291041500213"),"06291041500213")
        self.assertEqual(normalized_barcode("012345678905"),normalized_barcode("0012345678905"))
        for code in ["6291041500214","1.234E12","abc","123"]:
            self.assertIsNone(normalized_barcode(code))

    def test_portion_requires_a_documented_metric_amount(self):
        self.assertIsNone(portion("food","colher",None,"g","source"))
        self.assertIsNone(portion("food","colher","1","spoon","source"))
        p=portion("food","Colher rasa","12,5","g","source","cooked")
        self.assertEqual(p["quantity"],"12.5")
        self.assertEqual(p,portion("food","Colher rasa","12.5","g","source","cooked"))
        self.assertNotEqual(p["id"],portion("food","Colher cheia","12.5","g","source","cooked")["id"])

    def test_identity_stays_stable_but_composition_version_changes(self):
        args=("source","42","Rice","en","2026",{"quantity":"100","unit":"g"})
        a=make_food(*args,[cell("20")]);b=make_food(*args,[cell("21")])
        self.assertEqual(a["foodId"],b["foodId"])
        self.assertNotEqual(a["versionId"],b["versionId"])
        self.assertEqual(a,make_food(*args,[cell("20")]))

    def test_legacy_identity_and_version_are_not_rewritten(self):
        row={"foodId":"food:"+"a"*64,"sourceId":"legacy","sourceFoodId":"1","nameOriginal":"Original","nameLocale":"fr","sourcePublishedVersion":"2025","basis":{"quantity":"100","unit":"g"},"nutrients":[{**cell(),"raw":"20"}],"provenance":{}}
        raw=canonical(row).encode()
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"source.jsonl";p.write_bytes(raw+b"\n")
            result=next(legacy_foods(p))
        self.assertEqual(result["foodId"],row["foodId"])
        self.assertEqual(result["versionId"],hashlib.sha256(raw).hexdigest())

    def test_off_reader_retains_unknown_basis_and_empty_nutrients(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"off.tsv"
            with p.open("w",encoding="utf-8",newline="") as f:
                writer=csv.DictWriter(f,fieldnames=["code","product_name","quantity","serving_size","sodium_100g","energy-kcal_100g"],delimiter="\t")
                writer.writeheader()
                writer.writerow({"code":"6291041500213","product_name":"Labelled food","quantity":"500 g","serving_size":"1 spoon (10g)","sodium_100g":"0.002","energy-kcal_100g":"20"})
                writer.writerow({"code":"012345678905","product_name":"Unknown unit","energy-kcal_100g":"0"})
            a,b=list(off_foods(p,"snapshot"))
        self.assertEqual(a["portions"][0]["quantity"],"10")
        self.assertEqual(a["canonicalNutrients"][0]["value"],"2")
        self.assertIsNone(b["basis"]["unit"])
        self.assertFalse(any(n["primaryForTotals"] for n in b["canonicalNutrients"]))

    def test_search_normalization_preserves_display_name(self):
        self.assertEqual(folded("  Pão FRANCÊS  "),"pao frances")

    def make_bundle(self,root,*,fixture=False,complete=True):
        writer=CatalogWriter(root/"catalog.sqlite",{"fixture":SOURCE})
        food=make_food("fixture","1","Pão francês","pt-BR","1",{"quantity":"100","unit":"g"},[cell()],barcodes=["6291041500213"])
        writer.add(food)
        payload=writer.finish()
        payload.update({"fixture":fixture,"complete":complete,"missingSources":[]})
        sign_manifest(payload,root/"private-key",root)
        return food,payload

    def test_sqlite_dictionary_and_barcode_index_are_consistent(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);food,payload=self.make_bundle(root)
            result=verify_bundle(root)
            self.assertEqual(result["counts"]["foods"],1)
            db=sqlite3.connect(root/"catalog.sqlite")
            stored=db.execute("SELECT name_original,original_nutrients_json FROM foods").fetchone()
            self.assertEqual(stored[0],food["nameOriginal"])
            columns=dict(db.execute("SELECT column_id,source_column_key FROM nutrient_columns"))
            self.assertEqual(columns[json.loads(stored[1])[0][0]],"fixture:protein")
            refs=decode_storage_json(db.execute("SELECT canonical_nutrients_json FROM foods").fetchone()[0])
            self.assertEqual(refs,[[next(iter(columns)),True,"20",None]])
            self.assertEqual(db.execute("SELECT code FROM barcodes WHERE normalized_code=?",("06291041500213",)).fetchone()[0],"6291041500213")
            self.assertEqual(db.execute("SELECT food_id FROM foods_fts WHERE search_name MATCH 'pao'").fetchone()[0],food["foodId"])
            db.close()

    def test_fixture_and_incomplete_catalogs_cannot_pass_release_verification(self):
        for fixture,complete in [(True,True),(False,False)]:
            with self.subTest(fixture=fixture,complete=complete),tempfile.TemporaryDirectory() as d:
                root=Path(d);self.make_bundle(root,fixture=fixture,complete=complete)
                with self.assertRaisesRegex(ValueError,"fixture or is incomplete"):verify_bundle(root)

    def test_tampered_payload_is_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);self.make_bundle(root)
            p=root/"manifest.json";envelope=json.loads(p.read_text(encoding="utf-8"))
            payload=json.loads(base64.b64decode(envelope["payload"]))
            payload["counts"]["foods"]=999
            envelope["payload"]=base64.b64encode(canonical(payload).encode()).decode()
            p.write_text(canonical(envelope),encoding="utf-8")
            with self.assertRaises(Exception):verify_bundle(root)

    def test_tampered_database_is_rejected_before_queries(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);self.make_bundle(root)
            with (root/"catalog.sqlite").open("ab") as f:f.write(b"tamper")
            with self.assertRaisesRegex(ValueError,"size/hash"):verify_bundle(root)

    def test_gzip_asset_is_verified_without_an_uncompressed_database_copy(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);_,payload=self.make_bundle(root)
            original=root/"catalog.sqlite";compressed=root/"catalog.sqlite.gz"
            with original.open("rb") as stream,gzip.GzipFile(filename=str(compressed),mode="wb",mtime=0) as output:
                output.write(stream.read())
            payload.update({"databaseFile":"catalog.sqlite","databaseBytes":payload["bytes"],"databaseSha256":payload["sha256"],"file":"catalog.sqlite.gz","bytes":compressed.stat().st_size,"sha256":sha_file(compressed)})
            sign_manifest(payload,root/"private-key",root)
            original.unlink()
            self.assertEqual(verify_bundle(root)["databaseBytes"],payload["databaseBytes"])
            payload["databaseBytes"]-=1
            sign_manifest(payload,root/"private-key",root)
            with self.assertRaisesRegex(ValueError,"exceeds signed size"):verify_bundle(root)


if __name__=="__main__":unittest.main()
