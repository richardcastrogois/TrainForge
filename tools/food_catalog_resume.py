"""Recover an interrupted global build, verify coverage, and finish privately.

Never treats a partial snapshot as complete. Existing source records and export
prefixes are kept; only the remaining USDA prefix is normalized after checking
that prior datasets are complete and the staged archive covers the official CSV.
"""
from __future__ import annotations

from collections import Counter
import csv
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import time
import zipfile
import zlib

from food_catalog import (ROOT,CatalogWriter,canonical,decimal_text,make_food,
                          parse_value,portion,sha_file,sign_manifest,USDA_NUTRIENTS,zip_csv)
from food_catalog_build import source_registry
from food_catalog_package import package


KINDS={"foundation_food":"FOUNDATION","sr_legacy_food":"SR-LEGACY","survey_fndds_food":"FNDDS","branded_food":"BRANDED","experimental_food":"EXPERIMENTAL"}


def event(state,**data):
    print(canonical({"state":state,**data}),flush=True)


def metric_off_count(path):
    # Deliberately use the SAME parser and identity predicate as off_foods.
    # OFF's actual TSV contains rows whose field counts Arrow rejects even
    # though csv.DictReader preserves them. No invalid-row skipping is allowed.
    total=usable=0
    with gzip.open(path,"rt",encoding="utf-8-sig",newline="") as stream:
        reader=csv.DictReader(stream,delimiter="\t")
        last=time.monotonic()
        for row in reader:
            total+=1
            if (row.get("code") or "").strip() and (row.get("product_name") or "").strip():usable+=1
            if time.monotonic()-last>30:event("verifying_off_coverage",inputRows=total,usable=usable);last=time.monotonic()
    return total,usable


def export_lines(path):
    return sum(member[2] for member in gzip_members(path))


def gzip_members(path):
    """Record boundaries/complete JSON lines; salvage only a truncated last tail."""
    members=[];start=position=rows=0;decoder=zlib.decompressobj(16+zlib.MAX_WBITS)
    with Path(path).open("rb") as source:
        for block in iter(lambda:source.read(256*1024),b""):
            data=block
            while data:
                output=decoder.decompress(data)
                rows+=output.count(b"\n")
                if decoder.eof:
                    consumed=len(data)-len(decoder.unused_data)
                    position+=consumed
                    members.append((start,position,rows,True))
                    data=decoder.unused_data;start=position;rows=0
                    decoder=zlib.decompressobj(16+zlib.MAX_WBITS)
                else:
                    position+=len(data);data=b""
    if position>start:members.append((start,position,rows,False))
    return members


def member_lines(path,offset):
    decoder=zlib.decompressobj(16+zlib.MAX_WBITS);buffer=b""
    with Path(path).open("rb") as source:
        source.seek(offset)
        for block in iter(lambda:source.read(256*1024),b""):
            buffer+=decoder.decompress(block)
            rows=buffer.split(b"\n");buffer=rows.pop()
            for row in rows:yield row+b"\n"
            if decoder.eof:return


def trim_export(path,count,backup):
    members=gzip_members(path)
    original_count=sum(m[2] for m in members)
    if original_count<count:raise ValueError("Export contains fewer records than committed database: "+path.name)
    if original_count==count and all(m[3] for m in members):return
    backup.mkdir(parents=True,exist_ok=True)
    archived=backup/path.name
    if not archived.exists():shutil.copy2(path,archived)
    temporary=path.with_name(path.name+".repair")
    committed=prefix_end=member_offset=0
    for start,end,rows,complete in members:
        if complete and committed+rows<=count:
            committed+=rows;prefix_end=end;member_offset=end
        else:member_offset=start;break
    with path.open("rb") as source,temporary.open("wb") as target:
        remaining=prefix_end
        while remaining:
            block=source.read(min(1024*1024,remaining));target.write(block);remaining-=len(block)
    if committed<count:
        with gzip.GzipFile(filename=str(temporary),mode="ab",compresslevel=1,mtime=0) as target:
            for row in member_lines(path,member_offset):
                if committed>=count:break
                target.write(row);committed+=1
    if committed!=count:raise ValueError("Recovered export prefix does not match committed SQLite coverage")
    temporary.replace(path)
    event("export_prefix_repaired",source=path.name,committed=count,uncommitted=original_count-count)


def main():
    started=time.monotonic()
    raw=ROOT/".local/food-catalog/raw";work=ROOT/".local/food-catalog/build"
    output=ROOT/"assets/food_catalog";exports=ROOT/".local/food-catalog/exports"
    recovery=ROOT/".local/food-catalog/recovery";recovery.mkdir(parents=True,exist_ok=True)
    interrupted=output/"catalog.building.sqlite"
    preserved=recovery/"catalog-interrupted.sqlite"
    if interrupted.exists():
        if preserved.exists():raise FileExistsError("Previous recovery snapshot already exists")
        interrupted.rename(preserved)
    if not preserved.exists():raise FileNotFoundError("Interrupted catalog unavailable")
    target=work/"catalog.resuming.sqlite"
    if not target.exists():
        event("preserving_interrupted_snapshot",bytes=preserved.stat().st_size)
        shutil.copy2(preserved,target)
    registry=source_registry(raw_dir=raw)
    stage=sqlite3.connect((work/"usda-stage.sqlite").as_uri()+"?mode=ro",uri=True)
    if stage.execute("SELECT count(*) FROM sqlite_master WHERE name IN ('cell_food','serving_food')").fetchone()[0]!=2:
        raise ValueError("USDA staging import is not complete")
    kinds=dict(stage.execute("SELECT kind,count(*) FROM food GROUP BY kind"))
    for kind in kinds:
        sid="AL-USDA-"+KINDS.get(kind,kind.upper())
        if sid not in registry:registry[sid]={**registry["AL-USDA-FOUNDATION"],"name":"USDA FoodData Central — "+kind}
    writer=CatalogWriter(target,registry,exports,resume=True)
    existing=dict(writer.counts);event("interrupted_coverage",counts=existing)
    if existing.get("AL-TACO")!=597 or existing.get("AL-CIQUAL-2025")!=3484 or existing.get("AL-COFID-2021")!=2885:
        raise ValueError("Prior source coverage incomplete; cannot use USDA-only resume")
    cache_path=recovery/"source-coverage.json"
    cache=json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.exists() else None
    inputs={}
    for name,filename in [("off","off-products.csv.gz"),("usda","usda-full-2026-10-29.zip")]:
        receipt=json.loads((raw/(filename+".receipt.json")).read_text(encoding="utf-8"))
        if sha_file(raw/filename)!=receipt["sha256"]:raise ValueError("Official raw snapshot differs from verified receipt")
        inputs[name]=receipt["sha256"]
    if cache is None:
        # A previous completed pass already compared BOTH raw sources against
        # staging and repaired all export prefixes before the USDA continuation.
        previous=ROOT/".local/food-catalog/build-resume.log"
        if previous.exists():
            for text in previous.read_text(encoding="utf-8").splitlines():
                try:record=json.loads(text)
                except json.JSONDecodeError:continue
                if record.get("state")=="resume_prefix_verified":
                    cache={"inputs":inputs,"offInputRows":record["offInputRows"],"offUsableFoods":record["offUsableFoods"],"usdaInputRows":record["usdaInputRows"],"evidence":"completed prior source coverage pass in build-resume.log"}
            if cache:cache_path.write_text(canonical(cache)+"\n",encoding="utf-8")
    if cache and cache.get("inputs")==inputs:
        off_total,off_usable=cache["offInputRows"],cache["offUsableFoods"]
        event("reusing_verified_source_coverage",inputHashes=inputs,offInputRows=off_total,offUsableFoods=off_usable)
    else:off_total,off_usable=metric_off_count(raw/"off-products.csv.gz")
    if off_usable!=existing.get("AL-OFF"):raise ValueError("OFF complete source coverage differs from interrupted database")
    usable_kinds=Counter();excluded_kinds=Counter()
    for kind,name in stage.execute("SELECT kind,name FROM food"):
        if name and name.strip():usable_kinds[kind]+=1
        else:excluded_kinds[kind]+=1
    if cache and cache.get("inputs")==inputs:
        if sum(kinds.values())!=cache["usdaInputRows"]:raise ValueError("USDA staged source coverage changed")
    else:
        archive_counts=Counter()
        with zipfile.ZipFile(raw/"usda-full-2026-10-29.zip") as archive:
            with zip_csv(archive,"food.csv") as stream:
                for row in csv.DictReader(stream):archive_counts[row["data_type"]]+=1
        if dict(archive_counts)!=kinds:raise ValueError("USDA staging does not cover the complete original food.csv")
    last_id=writer.db.execute("SELECT MAX(CAST(source_food_id AS INTEGER)) FROM foods WHERE source_id LIKE 'AL-USDA-%'").fetchone()[0] or 0
    prefix=Counter()
    for kind,name in stage.execute("SELECT kind,name FROM food WHERE id<=?",(last_id,)):
        if name and name.strip():prefix[kind]+=1
    for kind,count in prefix.items():
        if existing.get("AL-USDA-"+KINDS.get(kind,kind.upper()),0)!=count:raise ValueError("Interrupted USDA records are not an exact committed prefix")
    for path in sorted(exports.glob("*.jsonl.gz")):
        source=path.name[:-9]
        if existing.get(source):trim_export(path,existing[source],recovery/"exports")
    event("resume_prefix_verified",lastUsdaId=last_id,offInputRows=off_total,offUsableFoods=off_usable,usdaInputRows=sum(kinds.values()))
    definitions={r[0]:(r[1],r[2]) for r in stage.execute("SELECT * FROM nd")}
    added=0;last=time.monotonic()
    for fdc_id,kind,name,published in stage.execute("SELECT * FROM food WHERE id>? ORDER BY id",(last_id,)):
        if not name or not name.strip():continue
        source="AL-USDA-"+KINDS.get(kind,kind.upper())
        ident="food:"+hashlib.sha256((source+"\0"+str(fdc_id)).encode()).hexdigest()
        cells=[]
        for nutrient,amount in stage.execute("SELECT nutrient,amount FROM cell WHERE food=? ORDER BY CAST(nutrient AS INTEGER)",(fdc_id,)):
            label,unit=definitions[nutrient]
            unit=unit.replace("UG","µg").replace("MG","mg").replace("KCAL","kcal").replace("KJ","kJ")
            if unit=="G":unit="g"
            cells.append({"sourceColumnKey":source+":nutrient:"+nutrient,"nameOriginal":label,"unit":unit,"nutrientId":USDA_NUTRIENTS.get(nutrient),**parse_value(amount),"basisQuantity":"100","basisUnit":"g","scalingAllowed":True,"methodId":"usda:nutrient:"+nutrient})
        portions=[]
        for label,weight in stage.execute("SELECT label,weight FROM serving WHERE food=?",(fdc_id,)):
            p=portion(ident,label,weight,"g",source,"USDA documented portion")
            if p:portions.append(p)
        brand=stage.execute("SELECT brand,code,label,amount,unit FROM brand WHERE food=?",(fdc_id,)).fetchone()
        if brand:
            p=portion(ident,brand[2] or "Declared serving",brand[3],(brand[4] or "").lower(),source,"declared serving")
            if p:portions.append(p)
        writer.add(make_food(source,fdc_id,name,"en","2026-10-29",{"quantity":"100","unit":"g"},cells,
            brand=brand[0] if brand else None,portions=portions,barcodes=[brand[1]] if brand and brand[1] else [],
            provenance={"fdcDataType":kind,"publicationDate":published}))
        added+=1
        if time.monotonic()-last>30:event("resuming_usda",addedFoods=added,fdcId=fdc_id);last=time.monotonic()
    stage.close()
    expected_usda=sum(usable_kinds.values())
    actual_usda=sum(v for k,v in writer.counts.items() if k.startswith("AL-USDA-"))
    if actual_usda!=expected_usda:raise ValueError("USDA final coverage differs from complete original archive")
    event("finishing_complete_catalog",counts=dict(writer.counts))
    payload=writer.finish()
    distribution=ROOT/".local/food-catalog/distribution";distribution.mkdir(parents=True,exist_ok=True)
    final=output/"catalog.sqlite"
    if final.exists():raise FileExistsError("Final catalog already exists")
    target.rename(final)
    payload.update({"file":"catalog.sqlite","complete":True,"fixture":False,"missingSources":[],"exports":[],"sourceArtifacts":[],
        "sourceReports":{"legacy":{"outputFoods":6369},"taco":{"outputFoods":597},"off":{"inputRows":off_total,"outputFoods":off_usable,"excludedMissingIdentityOrName":off_total-off_usable},"usda":{"inputRows":sum(kinds.values()),"outputFoods":actual_usda,"excludedMissingName":sum(excluded_kinds.values()),"excludedByType":dict(excluded_kinds)}},"recovery":{"verifiedCommittedPrefix":True,"addedFoods":added}})
    for path in sorted(exports.glob("*.jsonl.gz")):
        source=path.name[:-9]
        if payload["counts"].get(source):payload["exports"].append({"file":path.name,"sourceId":source,"rows":payload["counts"][source],"sha256":sha_file(path),"bytes":path.stat().st_size,"license":registry[source]["licenseLabel"]})
    for name,filename in [("off","off-products.csv.gz"),("usda","usda-full-2026-10-29.zip"),("taco","taco-4a-edicao.xlsx")]:
        path=raw/filename;payload["sourceArtifacts"].append({"source":name,"file":filename,"bytes":path.stat().st_size,"sha256":sha_file(path)})
    sign_manifest(payload,ROOT/".local/food-catalog/signing",output)
    public=ROOT/"content/food_catalog";public.mkdir(parents=True,exist_ok=True)
    (public/"sources.json").write_text(canonical(registry)+"\n",encoding="utf-8")
    (public/"catalog.lock.json").write_text(canonical({"contract":"trainforge.food-catalog-lock/1",**payload})+"\n",encoding="utf-8")
    (public/"exports.json").write_text(canonical({"contract":"trainforge.food-catalog-exports/1","version":payload["version"],"artifacts":payload["exports"]})+"\n",encoding="utf-8")
    (public/"build-report.json").write_text(canonical({"contract":"trainforge.food-catalog-build/1","complete":True,"counts":payload["counts"],"bytes":payload["bytes"],"sha256":payload["sha256"],"version":payload["version"],"sourceReports":payload["sourceReports"],"recoverySeconds":round(time.monotonic()-started)})+"\n",encoding="utf-8")
    event("recovered_catalog_complete",counts=payload["counts"])
    package(output,distribution,ROOT/".local/food-catalog/signing")


if __name__=="__main__":main()
