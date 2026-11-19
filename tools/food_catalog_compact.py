"""Losslessly compact an already signed food catalog, without provider ingestion.

All food cells are compared by a length-framed streaming digest in original row
order. Barcode equivalence is checked in both directions using indexed lookups.
The source database remains read-only; interruption never replaces the baseline.
"""
from __future__ import annotations

import argparse
import base64
import ctypes
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import threading
import time

from food_catalog import (CONTRACT, SCHEMA_VERSION, FOOD_COLUMNS, ROOT, STORAGE_LAYOUT, canonical,
                          create_compact_schema, sha_file, sign_manifest, verify_bundle)
from food_catalog_package import package, write_update_archive


def emit(event):
    print(canonical(event),flush=True)


def available_memory():
    if not hasattr(ctypes,"windll"):return None
    class MemoryStatus(ctypes.Structure):
        _fields_=[("length",ctypes.c_ulong),("load",ctypes.c_ulong),
                  ("total_physical",ctypes.c_ulonglong),("available_physical",ctypes.c_ulonglong),
                  ("total_pagefile",ctypes.c_ulonglong),("available_pagefile",ctypes.c_ulonglong),
                  ("total_virtual",ctypes.c_ulonglong),("available_virtual",ctypes.c_ulonglong),
                  ("available_extended_virtual",ctypes.c_ulonglong)]
    status=MemoryStatus();status.length=ctypes.sizeof(status)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
        raise OSError("Cannot inspect physical memory")
    return status.available_physical


def signed_payload(assets):
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    envelope=json.loads((assets/"manifest.json").read_text(encoding="utf-8"))
    trust=json.loads((assets/"trust.json").read_text(encoding="utf-8"))
    if trust.get("contract")!="trainforge.food-catalog-trust/1":raise ValueError("Invalid trust contract")
    keys=[k for k in trust["keys"] if k["keyId"]==envelope["keyId"] and k["algorithm"]=="Ed25519"]
    if len(keys)!=1:raise ValueError("Untrusted signing key")
    message=base64.b64decode(envelope["payload"],validate=True)
    Ed25519PublicKey.from_public_bytes(base64.b64decode(keys[0]["publicKey"],validate=True)).verify(
        base64.b64decode(envelope["signature"],validate=True),message)
    payload=json.loads(message)
    if payload.get("contract")!=CONTRACT or payload.get("schemaVersion")!=SCHEMA_VERSION:
        raise ValueError("Incompatible baseline catalog contract")
    if payload.get("complete") is not True or payload.get("fixture") is not False or payload.get("missingSources"):
        raise ValueError("Compaction requires a signed complete production snapshot")
    return payload


def digest_foods(db,table="foods",row_key="row_key",notify=emit):
    """Frame NULL and UTF-8 strings unambiguously; include row order and all cells."""
    if table not in {"foods","baseline.foods"} or row_key not in {"row_key","rowid"}:
        raise ValueError("Unsupported digest table")
    digest=hashlib.sha256(b"trainforge.food-catalog-cells/1\n");count=0;last=time.monotonic()
    query="SELECT "+row_key+","+",".join(FOOD_COLUMNS)+" FROM "+table+" ORDER BY "+row_key
    for row in db.execute(query):
        for value in row:
            if value is None:digest.update(b"N")
            else:
                encoded=str(value).encode("utf-8")
                digest.update(b"S"+len(encoded).to_bytes(8,"big"));digest.update(encoded)
        count+=1
        if time.monotonic()-last>=30:
            notify({"state":"verifying_food_cells","table":table,"rows":count});last=time.monotonic()
    return {"rows":count,"sha256":digest.hexdigest()}


def prove_equivalence(db,notify=emit):
    before=digest_foods(db,"baseline.foods","rowid",notify)
    after=digest_foods(db,"foods","row_key",notify)
    if before!=after:raise ValueError("Compaction changed food fields or row identities")
    original_count=db.execute("SELECT count(*) FROM baseline.barcodes").fetchone()[0]
    compact_count=db.execute("SELECT count(*) FROM barcode_links").fetchone()[0]
    if original_count!=compact_count:raise ValueError("Compaction changed barcode count")
    # A missing food association, code, format or normalized code fails explicitly.
    # Old barcodes are keyed by code + food identity; new links by integer + code.
    missing=db.execute("""SELECT 1 FROM barcode_links b JOIN foods f ON f.row_key=b.food_row_key
        WHERE NOT EXISTS (SELECT 1 FROM baseline.barcodes old
          WHERE old.code=b.code AND old.food_id=f.food_id AND old.version_id=f.version_id
            AND old.normalized_code IS b.normalized_code AND old.format IS b.format) LIMIT 1""").fetchone()
    if missing:raise ValueError("Compaction altered a barcode association")
    missing=db.execute("""SELECT 1 FROM baseline.barcodes old
        JOIN baseline.foods f ON f.food_id=old.food_id AND f.version_id=old.version_id
        WHERE NOT EXISTS (SELECT 1 FROM barcode_links b WHERE b.food_row_key=f.rowid
          AND b.code=old.code AND b.normalized_code IS old.normalized_code
          AND b.format IS old.format) LIMIT 1""").fetchone()
    if missing:raise ValueError("Compaction omitted a barcode association")
    if db.execute("PRAGMA foreign_key_check").fetchone():raise ValueError("Invalid compact barcode foreign key")
    for table in ("sources","nutrient_columns"):
        old=list(db.execute("SELECT * FROM baseline."+table+" ORDER BY 1"))
        new=list(db.execute("SELECT * FROM "+table+" ORDER BY 1"))
        if old!=new:raise ValueError("Compaction changed "+table)
    old_meta=dict(db.execute("SELECT key,value FROM baseline.metadata"))
    new_meta=dict(db.execute("SELECT key,value FROM metadata"))
    if {k:v for k,v in new_meta.items() if k!="storage_layout"}!={k:v for k,v in old_meta.items() if k!="storage_layout"}:
        raise ValueError("Compaction changed semantic metadata")
    return {"foodCells":after,"barcodes":compact_count,"sources":len(list(db.execute("SELECT 1 FROM sources"))),
            "barcodeEquivalence":"counts-and-bidirectional-indexed-not-exists",
            "foreignKeys":"ok","storageLayout":STORAGE_LAYOUT}


def copy_barcode_links(db,target,notify=emit):
    """Bounded, committed batches; persisted cursor never runs ahead of SQLite."""
    checkpoint=target.with_suffix(".barcodes.json")
    rows=db.execute("SELECT count(*) FROM barcode_links").fetchone()[0]
    version=db.execute("SELECT value FROM metadata WHERE key='version'").fetchone()[0]
    key=None
    if checkpoint.exists():
        saved=json.loads(checkpoint.read_text(encoding="utf-8"))
        if saved.get("version")==version and saved.get("rowsCommitted")==rows:key=saved["lastSourceKey"]
    predicate=" AND (b.code,b.food_id,b.version_id)>(?,?,?)" if key else ""
    query="""SELECT b.code,b.food_id,b.version_id,b.normalized_code,b.format,f.rowid
        FROM baseline.barcodes AS b NOT INDEXED CROSS JOIN baseline.foods AS f
        WHERE f.food_id=b.food_id AND f.version_id=b.version_id"""+predicate+" ORDER BY b.code,b.food_id,b.version_id"
    db.commit()
    db.execute("PRAGMA main.journal_mode=WAL")
    db.execute("PRAGMA main.synchronous=NORMAL")
    db.execute("PRAGMA main.wal_autocheckpoint=1000")
    reader=db.execute(query,tuple(key) if key else ())
    last=time.monotonic()
    try:
        while True:
            batch=reader.fetchmany(5000)
            if not batch:break
            changed=db.total_changes
            db.executemany("INSERT OR IGNORE INTO barcode_links VALUES(?,?,?,?)",
                           ((r[5],r[0],r[3],r[4]) for r in batch))
            rows+=db.total_changes-changed;db.commit()
            saved={"version":version,"rowsCommitted":rows,"lastSourceKey":list(batch[-1][:3])}
            temporary=checkpoint.with_suffix(".json.part")
            temporary.write_text(canonical(saved)+"\n",encoding="utf-8");temporary.replace(checkpoint)
            if time.monotonic()-last>=30:
                notify({"state":"copying_barcode_links","rowsCommitted":rows});last=time.monotonic()
    finally:reader.close()
    db.execute("PRAGMA main.wal_checkpoint(TRUNCATE)")
    db.execute("PRAGMA main.journal_mode=DELETE")
    notify({"state":"barcode_links_committed","rowsCommitted":rows})


def compact_database(source,target,*,cache_mib=2048,mmap_gib=8,notify=emit,resume_from=None):
    source=Path(source).resolve();target=Path(target).resolve()
    if not source.is_file():raise FileNotFoundError(source)
    if target.exists() and not resume_from:raise FileExistsError("Refusing to overwrite a compacting snapshot: "+str(target))
    if resume_from and (not target.is_file() or resume_from not in {"barcodes","indexes","fts","proof"}):
        raise ValueError("Resume requires an existing snapshot and a supported committed stage")
    if cache_mib<1 or mmap_gib<0:raise ValueError("Invalid process-local SQLite memory budget")
    free_memory=available_memory()
    if free_memory is not None and free_memory<(cache_mib+min(cache_mib,1024))*1024**2:
        raise ValueError("Insufficient available RAM for the selected SQLite cache budget")
    target.parent.mkdir(parents=True,exist_ok=True)
    db=sqlite3.connect(target.as_uri()+"?mode=rwc",uri=True)
    stage={"state":"opening_compaction","sourceBytes":source.stat().st_size,
           "freeBytes":shutil.disk_usage(target.parent).free,"availableMemory":free_memory,
           "cacheMiB":cache_mib,"mmapGiB":mmap_gib}
    stop=threading.Event();started=time.monotonic()
    def heartbeat():
        while not stop.wait(30):
            notify({**stage,"elapsedSeconds":round(time.monotonic()-started),
                    "outputBytes":target.stat().st_size if target.exists() else 0,
                    "freeBytes":shutil.disk_usage(target.parent).free})
    thread=threading.Thread(target=heartbeat,daemon=True);thread.start()
    def phase(name):
        stage.clear();stage["state"]=name
        target.with_suffix(".state.json").write_text(canonical({"state":name,"source":str(source),"target":str(target)})+"\n",encoding="utf-8")
        notify(dict(stage))
    try:
        db.execute("ATTACH DATABASE ? AS baseline",(source.as_uri()+"?mode=ro&immutable=1",))
        baseline_cache=max(1,cache_mib//4);main_cache=max(1,cache_mib-baseline_cache)
        db.executescript("PRAGMA main.journal_mode=DELETE;PRAGMA main.synchronous=NORMAL;PRAGMA temp_store=FILE;"
                         f"PRAGMA cache_size=-{main_cache*1024};PRAGMA baseline.cache_size=-{baseline_cache*1024};"
                         f"PRAGMA mmap_size={mmap_gib*1024**3};PRAGMA baseline.mmap_size={mmap_gib*1024**3};")
        if resume_from:
            phase("checking_committed_compact_prefix")
            if db.execute("PRAGMA quick_check").fetchone()[0]!="ok":raise ValueError("Interrupted compact snapshot is not safe to resume")
            if dict(db.execute("SELECT key,value FROM metadata")).get("storage_layout")!=STORAGE_LAYOUT:
                raise ValueError("Resume target has another storage layout")
            old=db.execute("SELECT count(*),max(rowid) FROM baseline.foods").fetchone()
            new=db.execute("SELECT count(*),max(row_key) FROM foods").fetchone()
            if old!=new:raise ValueError("Committed food prefix is incomplete")
            notify({"state":"committed_food_copy_verified","foods":new[0],"resumeFrom":resume_from})
        else:
            create_compact_schema(db,deferred_identity_index=True)
            phase("copying_food_cells")
            for table in ("metadata","sources","nutrient_columns"):
                db.execute("INSERT INTO "+table+" SELECT * FROM baseline."+table)
            db.execute("INSERT INTO foods(row_key,"+",".join(FOOD_COLUMNS)+") SELECT rowid,"+",".join(FOOD_COLUMNS)+" FROM baseline.foods ORDER BY rowid")
            db.execute("INSERT OR REPLACE INTO metadata VALUES('storage_layout',?)",(STORAGE_LAYOUT,));db.commit()
        if resume_from in {None,"barcodes"}:
            phase("copying_barcode_links")
            copy_barcode_links(db,target,notify)
        if resume_from in {None,"barcodes","indexes"}:
            phase("building_compact_indexes")
            db.executescript("CREATE UNIQUE INDEX IF NOT EXISTS foods_identity ON foods(food_id,version_id);"
                             "CREATE INDEX IF NOT EXISTS foods_search ON foods(search_name);"
                             "CREATE INDEX IF NOT EXISTS foods_source ON foods(source_id);"
                             "CREATE INDEX IF NOT EXISTS barcodes_normalized ON barcode_links(normalized_code);")
        if resume_from in {None,"barcodes","indexes","fts"}:
            phase("building_external_fts")
            db.execute("INSERT INTO foods_fts(foods_fts) VALUES('rebuild')")
            db.execute("INSERT INTO foods_fts(foods_fts) VALUES('optimize')");db.commit()
        phase("proving_full_equivalence")
        proof=prove_equivalence(db,notify)
        phase("checking_compact_integrity")
        if db.execute("PRAGMA integrity_check").fetchone()[0]!="ok":raise ValueError("Compacted database integrity failed")
        db.execute("INSERT INTO foods_fts(foods_fts) VALUES('integrity-check')");db.commit()
        version=db.execute("SELECT value FROM metadata WHERE key='version'").fetchone()[0]
        phase("hashing_compact_database")
        db.close();db=None
        report={"contract":"trainforge.food-catalog-compaction/1","complete":True,"version":version,
                "source":str(source),"target":str(target),"bytes":target.stat().st_size,
                "sha256":sha_file(target),"equivalence":proof,"elapsedSeconds":round(time.monotonic()-started)}
        target.with_suffix(".compaction.json").write_text(canonical(report)+"\n",encoding="utf-8")
        notify({"state":"compaction_verified",**report})
        return report
    finally:
        stop.set();thread.join(timeout=1)
        if db is not None:db.close()


def package_compacted(source,target,assets,signing,report,*,create_archive=True):
    """Re-sign only physical representation; preserve every provider export claim."""
    from cryptography.hazmat.primitives import serialization
    baseline_envelope=json.loads((assets/"manifest.json").read_text(encoding="utf-8"))
    baseline=signed_payload(assets)
    if baseline["version"]!=report["version"]:raise ValueError("Compaction changed content version")
    if target.stat().st_size!=report["bytes"] or sha_file(target)!=report["sha256"]:
        raise ValueError("Verified compact database changed")
    private_path=Path(signing)/"catalog-ed25519.pem"
    if not private_path.is_file():raise FileNotFoundError("Existing baseline signing key is required")
    key=serialization.load_pem_private_key(private_path.read_bytes(),password=None)
    public=key.public_key().public_bytes(serialization.Encoding.Raw,serialization.PublicFormat.Raw)
    if "trainforge-food-"+hashlib.sha256(public).hexdigest()[:16]!=baseline_envelope["keyId"]:
        raise ValueError("Compaction signing key differs from the trusted baseline key")
    distribution=ROOT/".local/food-catalog/distribution"
    archived=distribution/"catalog.baseline.sqlite"
    source=source.resolve()
    if source!=(distribution/"catalog.sqlite").resolve():raise ValueError("Unexpected production baseline path")
    if archived.exists():raise FileExistsError("An archived baseline already exists")
    previous=assets/"catalog.sqlite.gz"
    backup=distribution/"catalog.baseline.sqlite.gz"
    if previous.exists() and backup.exists():raise FileExistsError("An archived gzip baseline already exists")
    # No copy: preserve both baselines until compressed replacement is verified.
    source.rename(archived);target.rename(source)
    if previous.exists():
        previous.rename(backup)
    for name in ("manifest.json","trust.json"):
        shutil.copyfile(assets/name,distribution/("baseline-"+name))
    payload={**baseline,"file":"catalog.sqlite","sha256":report["sha256"],"bytes":report["bytes"],
             "storageLayout":STORAGE_LAYOUT,"compaction":{"foodCellsSha256":report["equivalence"]["foodCells"]["sha256"],
                                                          "barcodes":report["equivalence"]["barcodes"]}}
    for key in ("databaseFile","databaseBytes","databaseSha256","compression"):payload.pop(key,None)
    sign_manifest(payload,signing,assets)
    result=package(assets,distribution,signing,create_archive=False)
    verified=verify_bundle(assets)
    emit({"state":"compact_bundle_verified",**verified})
    if create_archive:write_update_archive(assets,distribution)
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",type=Path,default=ROOT/".local/food-catalog/distribution/catalog.sqlite")
    parser.add_argument("--target",type=Path,default=ROOT/".local/food-catalog/compact/catalog.sqlite")
    parser.add_argument("--assets",type=Path,default=ROOT/"assets/food_catalog")
    parser.add_argument("--signing",type=Path,default=ROOT/".local/food-catalog/signing")
    parser.add_argument("--cache-mib",type=int,default=2048)
    parser.add_argument("--mmap-gib",type=int,default=8)
    parser.add_argument("--resume-from",choices=["barcodes","indexes","fts","proof"],help="Reuse committed food copy, after quick_check and exact coverage verification")
    parser.add_argument("--package",action="store_true",help="Package a prior verified compaction without repeating it")
    parser.add_argument("--package-after",action="store_true",help="Package after the full equivalence proof")
    parser.add_argument("--defer-archive",action="store_true",help="Verify signed gzip first, then create ZIP separately after freeing derived baseline space")
    args=parser.parse_args()
    if args.package:
        report=json.loads(args.target.with_suffix(".compaction.json").read_text(encoding="utf-8"))
    else:
        payload=signed_payload(args.assets)
        expected=payload.get("databaseSha256",payload["sha256"])
        expected_bytes=payload.get("databaseBytes",payload["bytes"])
        emit({"state":"verifying_signed_baseline","bytes":expected_bytes})
        if args.source.stat().st_size!=expected_bytes or sha_file(args.source)!=expected:
            raise ValueError("Baseline does not match the signed database digest")
        emit({"state":"signed_baseline_verified","sha256":expected,"bytes":expected_bytes})
        report=compact_database(args.source,args.target,cache_mib=args.cache_mib,mmap_gib=args.mmap_gib,resume_from=args.resume_from)
        if report["equivalence"]["foodCells"]["rows"]!=payload["counts"]["foods"]:
            raise ValueError("Compaction coverage differs from signed baseline")
        report.update({"baselineDatabaseSha256":expected,"baselineDatabaseBytes":expected_bytes})
        args.target.with_suffix(".compaction.json").write_text(canonical(report)+"\n",encoding="utf-8")
    if args.package or args.package_after:
        package_compacted(args.source,args.target,args.assets,args.signing,report,create_archive=not args.defer_archive)


if __name__=="__main__":main()
