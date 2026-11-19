"""Lossless migration tests against the previously shipped SQL projection."""
from pathlib import Path
import base64
import gzip
import json
import sqlite3
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from food_catalog import CONTRACT, FOOD_COLUMNS, STORAGE_LAYOUT, CatalogWriter, make_food, sha_file, sign_manifest
from food_catalog_compact import compact_database, package_compacted, prove_equivalence
from food_catalog_package import write_update_archive
from test_food_catalog import SOURCE, cell


def legacy_fixture(root):
    """Synthetic legacy-layout data, including nonsequential rowids and multi-GTIN."""
    modern=root/"fixture-modern.sqlite";source=root/"fixture-legacy.sqlite"
    writer=CatalogWriter(modern,{"fixture":SOURCE})
    for number,name,codes in [(1,"Pão francês",["6291041500213","012345678905"]),
                              (2,"Feijão cozido",[]),(3,"Água\nmineral",["0012345678905"])]:
        writer.add(make_food("fixture",str(number),name,"pt-BR","1",{"quantity":"100","unit":"g"},
                            [cell("0.000000000000000000001"),cell("Tr",key="fixture:trace")],barcodes=codes))
    writer.finish()
    db=sqlite3.connect(source);db.execute("ATTACH DATABASE ? AS original",(str(modern),))
    for table in ("metadata","sources","nutrient_columns"):
        sql=db.execute("SELECT sql FROM original.sqlite_master WHERE name=?",(table,)).fetchone()[0]
        db.execute(sql);db.execute("INSERT INTO "+table+" SELECT * FROM original."+table)
    sql=db.execute("SELECT sql FROM original.sqlite_master WHERE name='foods'").fetchone()[0]
    sql=sql.replace("row_key INTEGER PRIMARY KEY,","").replace("UNIQUE(food_id,version_id)","PRIMARY KEY(food_id,version_id)")
    db.execute(sql)
    db.execute("INSERT INTO foods(rowid,"+",".join(FOOD_COLUMNS)+") SELECT row_key*7,"+",".join(FOOD_COLUMNS)+" FROM original.foods")
    db.execute("CREATE TABLE barcodes(code TEXT,normalized_code TEXT,format TEXT,food_id TEXT,version_id TEXT,PRIMARY KEY(code,food_id,version_id)) WITHOUT ROWID")
    db.execute("INSERT INTO barcodes SELECT * FROM original.barcodes")
    db.execute("CREATE INDEX foods_source ON foods(source_id,food_id)")
    db.execute("CREATE INDEX foods_source_identity ON foods(source_id,source_food_id)")
    db.execute("CREATE VIRTUAL TABLE foods_fts USING fts4(food_id,version_id,search_name,notindexed=food_id,notindexed=version_id)")
    db.execute("INSERT INTO foods_fts SELECT food_id,version_id,search_name FROM foods")
    db.execute("DELETE FROM metadata WHERE key='storage_layout'")
    db.commit();db.close()
    return source


class CatalogCompactionTests(unittest.TestCase):
    def test_packaging_preserves_content_exports_and_trust_and_supports_deferred_zip(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);distribution=root/".local/food-catalog/distribution"
            assets=root/"assets/food_catalog";public=root/"content/food_catalog"
            distribution.mkdir(parents=True);assets.mkdir(parents=True);public.mkdir(parents=True)
            source=distribution/"catalog.sqlite";legacy_fixture(root).rename(source)
            target=root/"compact/catalog.sqlite"
            report=compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None)
            previous=assets/"catalog.sqlite.gz";previous.write_bytes(gzip.compress(source.read_bytes(),mtime=0))
            exports=[{"file":"fixture.jsonl.gz","sourceId":"fixture","sha256":"a"*64,"bytes":123,"rows":3,"license":"CC0 1.0"}]
            payload={"contract":CONTRACT,"schemaVersion":1,"complete":True,"fixture":False,"missingSources":[],
                     "version":report["version"],"sources":[SOURCE],"counts":{"foods":3,"fixture":3},"exports":exports,
                     "file":"catalog.sqlite.gz","bytes":previous.stat().st_size,"sha256":sha_file(previous),
                     "databaseFile":"catalog.sqlite","databaseBytes":source.stat().st_size,"databaseSha256":sha_file(source)}
            signing=root/"signing";sign_manifest(payload,signing,assets);trust=(assets/"trust.json").read_bytes()
            (public/"build-report.json").write_text(json.dumps({"complete":True}),encoding="utf-8")
            with patch("food_catalog_compact.ROOT",root),patch("food_catalog_package.ROOT",root):
                package_compacted(source,target,assets,signing,report,create_archive=False)
            current=json.loads(base64.b64decode(json.loads((assets/"manifest.json").read_text())["payload"]))
            self.assertEqual(current["version"],payload["version"])
            self.assertEqual(current["exports"],exports)
            self.assertEqual(current["sources"],payload["sources"])
            self.assertEqual(current["databaseSha256"],report["sha256"])
            self.assertEqual((assets/"trust.json").read_bytes(),trust)
            self.assertTrue((distribution/"catalog.baseline.sqlite").is_file())
            self.assertTrue((distribution/"catalog.baseline.sqlite.gz").is_file())
            self.assertFalse((distribution/"catalog-update.zip").exists())
            write_update_archive(assets,distribution)
            with zipfile.ZipFile(distribution/"catalog-update.zip") as archive:
                self.assertEqual(archive.namelist(),["manifest.json","catalog.sqlite.gz"])
                self.assertTrue(all(info.compress_type==zipfile.ZIP_STORED for info in archive.infolist()))

    def test_full_cells_barcodes_and_existing_fts_queries_survive_compaction_and_vacuum(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=legacy_fixture(root);target=root/"compact.sqlite"
            baseline_hash=sha_file(source)
            report=compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None)
            self.assertEqual(report["equivalence"]["foodCells"]["rows"],3)
            self.assertEqual(report["equivalence"]["barcodes"],3)
            self.assertEqual(sha_file(source),baseline_hash)
            db=sqlite3.connect(target)
            self.assertEqual(db.execute("SELECT row_key FROM foods ORDER BY row_key").fetchall(),[(7,),(14,),(21,)])
            food_id,version_id=db.execute("SELECT food_id,version_id FROM foods WHERE row_key=7").fetchone()
            self.assertEqual(db.execute("SELECT code FROM barcodes WHERE food_id=? AND version_id=? ORDER BY code",(food_id,version_id)).fetchall(),[("012345678905",),("6291041500213",)])
            self.assertEqual(db.execute("SELECT food_id,version_id FROM foods_fts WHERE search_name MATCH 'pao'").fetchone(),(food_id,version_id))
            actual_query="SELECT f.* FROM foods f JOIN foods_fts ft ON ft.food_id=f.food_id AND ft.version_id=f.version_id WHERE foods_fts MATCH ? ORDER BY f.search_name LIMIT 60"
            self.assertEqual(db.execute(actual_query,("pao*",)).fetchone()[0],7)
            plan=" ".join(r[3] for r in db.execute("EXPLAIN QUERY PLAN SELECT code FROM barcodes WHERE food_id=? AND version_id=?",(food_id,version_id)))
            self.assertIn("SEARCH b USING PRIMARY KEY (food_row_key=?)",plan)
            normalized=" ".join(r[3] for r in db.execute("EXPLAIN QUERY PLAN SELECT food_id FROM barcodes WHERE normalized_code=?",("00012345678905",)))
            self.assertIn("barcodes_normalized",normalized)
            self.assertIsNone(db.execute("SELECT 1 FROM sqlite_master WHERE name='foods_fts_content'").fetchone())
            self.assertIsNone(db.execute("SELECT 1 FROM sqlite_master WHERE name='foods_source_identity'").fetchone())
            self.assertEqual(db.execute("PRAGMA index_info(foods_source)").fetchall(),[(0,3,"source_id")])
            self.assertEqual(db.execute("SELECT value FROM metadata WHERE key='storage_layout'").fetchone()[0],STORAGE_LAYOUT)
            with self.assertRaises(sqlite3.IntegrityError):
                db.execute("INSERT INTO foods(food_id,version_id) VALUES(?,?)",(food_id,version_id))
            db.rollback();db.execute("PRAGMA foreign_keys=ON")
            with self.assertRaises(sqlite3.IntegrityError):
                db.execute("INSERT INTO barcode_links VALUES(999,'123','123','test')")
            db.rollback();db.execute("VACUUM")
            self.assertEqual(db.execute("SELECT row_key FROM foods ORDER BY row_key").fetchall(),[(7,),(14,),(21,)])
            self.assertEqual(db.execute("SELECT food_id FROM foods_fts WHERE search_name MATCH 'pao'").fetchone()[0],food_id)
            db.close()

    def test_equivalence_proof_rejects_changed_cells_and_changed_barcode_format(self):
        for mutation,error in [("UPDATE foods SET original_nutrients_json='[]' WHERE row_key=7","food fields"),
                               ("UPDATE barcode_links SET format='wrong' WHERE food_row_key=7","barcode association")]:
            with self.subTest(mutation=mutation),tempfile.TemporaryDirectory() as directory:
                root=Path(directory);source=legacy_fixture(root);target=root/"compact.sqlite"
                compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None)
                db=sqlite3.connect(target);db.execute("ATTACH DATABASE ? AS baseline",(str(source),))
                db.execute(mutation)
                with self.assertRaisesRegex(ValueError,error):prove_equivalence(db,lambda _:None)
                db.close()

    def test_an_existing_target_is_never_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=legacy_fixture(root);target=root/"keep.sqlite"
            target.write_bytes(b"preserved")
            with self.assertRaises(FileExistsError):compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None)
            self.assertEqual(target.read_bytes(),b"preserved")

    def test_resume_reuses_committed_foods_and_recovers_a_stale_barcode_cursor(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);source=legacy_fixture(root);target=root/"compact.sqlite"
            initial=compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None)
            db=sqlite3.connect(target)
            db.execute("DELETE FROM barcode_links WHERE code='012345678905'")
            db.execute("CREATE TRIGGER reject_food_recopy BEFORE INSERT ON foods BEGIN SELECT RAISE(ABORT,'food copy repeated');END")
            db.commit();db.close()
            # Saved rows=3 no longer match rows=2. Re-read source from the start,
            # insert the missing association, and retain already committed rows.
            resumed=compact_database(source,target,cache_mib=8,mmap_gib=0,notify=lambda _:None,resume_from="barcodes")
            self.assertEqual(resumed["equivalence"],initial["equivalence"])


if __name__=="__main__":unittest.main()
