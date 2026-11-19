"""Build the entire local food catalog from verified official downloads.

Run: python tools/food_catalog_build.py --build
Verify without network: python tools/food_catalog_build.py --verify
Missing sources fail a production build; --allow-incomplete is explicitly marked.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import shutil
import time
import zipfile

from food_catalog import (ROOT, CatalogWriter, canonical, community_foods, legacy_foods, make_food,
                          off_foods, sha_file, sign_manifest, taco_foods,
                          usda_foods, verify_bundle, zip_csv)


def source_registry(root=ROOT, raw_dir=None):
    review=json.loads((root/"content/manifests/food-review-decisions.json").read_text(encoding="utf-8"))
    registry={}
    for s in review["sources"]:
        registry[s["sourceId"]]={"name":s["name"],"publisher":s["publisher"],"url":s["sourceUrl"],
            "licenseLabel":s["licenseLabel"],"licenseUrl":s["licenseUrl"],"attribution":s["attribution"],
            "version":s["sourceVersion"],"conditions":s.get("conditions",[])}
    registry["AL-TACO"]={"name":"Tabela Brasileira de Composição de Alimentos — TACO 4ª edição",
        "publisher":"NEPA / Universidade Estadual de Campinas","url":"https://nepa.unicamp.br/publicacoes/",
        "licenseLabel":"Reprodução permitida com citação da fonte",
        "licenseUrl":"https://www.nepa.unicamp.br/arquivo/uploads/taco-4-edicao-ampliada-e-revisada/taco_4_edicao_ampliada_e_revisada/",
        "attribution":"NEPA-UNICAMP. Tabela brasileira de composição de alimentos — TACO. 4ª ed. rev. e ampl. Campinas, 2011.",
        "version":"2011","conditions":["Preservar citação, origem, edição e informação sobre alterações.","Sem endosso da Unicamp ao aplicativo."]}
    off_version="unknown"
    if raw_dir:
        rp=Path(raw_dir)/"off-products.csv.gz.receipt.json"
        if rp.exists():off_version=json.loads(rp.read_text(encoding="utf-8")).get("lastModified") or "snapshot"
    registry["AL-OFF"]={"name":"Open Food Facts — global product CSV export","publisher":"Open Food Facts contributors",
        "url":"https://world.openfoodfacts.org/data","licenseLabel":"ODbL 1.0 / DbCL 1.0",
        "licenseUrl":"https://opendatacommons.org/licenses/odbl/1-0/",
        "attribution":"Contains information from Open Food Facts, made available under the Open Database License (ODbL). © Open Food Facts contributors.",
        "version":off_version,"conditions":["Atribuição e avisos preservados; base derivada oferecida em formato legível por máquina sob ODbL.","Dados colaborativos podem estar incompletos ou incorretos.","Imagens não integram este catálogo."]}
    for suffix in ["FOUNDATION","SR-LEGACY","FNDDS","BRANDED","EXPERIMENTAL"]:
        registry["AL-USDA-"+suffix]={"name":"USDA FoodData Central — "+suffix,"publisher":"U.S. Department of Agriculture, Agricultural Research Service",
            "url":"https://fdc.nal.usda.gov/download-datasets/","licenseLabel":"CC0 1.0 / Public domain",
            "licenseUrl":"https://creativecommons.org/publicdomain/zero/1.0/",
            "attribution":"U.S. Department of Agriculture, Agricultural Research Service. FoodData Central. Snapshot October 2026.",
            "version":"2026-10-29","conditions":["Fonte e versão preservadas; sem endosso do USDA ao aplicativo."]}
    registry["TF-COMMUNITY-1"]={"name":"TrainForge — contribuições aprovadas","publisher":"Contribuidores do TrainForge",
        "url":"https://creativecommons.org/publicdomain/zero/1.0/","licenseLabel":"CC0 1.0",
        "licenseUrl":"https://creativecommons.org/publicdomain/zero/1.0/","attribution":"Dados alimentares contribuídos voluntariamente e revisados pelo mantenedor do TrainForge.",
        "version":"1","conditions":["Somente contribuições com autorização CC0 explícita e revisão do mantenedor."]}
    return registry


def build(args):
    raw=args.raw_dir;output=args.output_dir
    inputs={"legacy":args.legacy,"taco":raw/"taco-4a-edicao.xlsx",
            "usda":raw/"usda-full-2026-10-29.zip","off":raw/"off-products.csv.gz"}
    missing=[k for k,p in inputs.items() if not p.is_file()]
    if missing and not args.allow_incomplete:raise ValueError("Production build requires complete sources: "+", ".join(missing))
    for name,path in inputs.items():
        if name in missing:continue
        if name in {"off","usda"}:
            receipt_path=path.with_name(path.name+".receipt.json")
            if not receipt_path.is_file():raise ValueError("Official download receipt missing: "+name)
            receipt=json.loads(receipt_path.read_text(encoding="utf-8"))
            if path.stat().st_size!=receipt["bytes"] or sha_file(path)!=receipt["sha256"]:
                raise ValueError("Official source snapshot no longer matches its receipt: "+name)
        elif name=="legacy":
            manifest=json.loads((ROOT/"content/manifests/food-approved.json").read_text(encoding="utf-8"))
            if sha_file(path)!=manifest["output"]["sha256"]:raise ValueError("Legacy approved snapshot changed")
    output.mkdir(parents=True,exist_ok=True)
    workspace=ROOT/".local/food-catalog/build";workspace.mkdir(parents=True,exist_ok=True)
    if shutil.disk_usage(workspace).free<12*1024**3:raise OSError("At least 12 GiB free required for the complete catalog preparation")
    registry=source_registry(raw_dir=raw)
    if inputs["usda"].exists():
        # Discover real USDA data types instead of assuming only five types.
        import csv
        with zipfile.ZipFile(inputs["usda"]) as archive:
            with zip_csv(archive,"food.csv") as stream:
                kinds={r["data_type"] for r in csv.DictReader(stream)}
        for kind in kinds:
            known={"foundation_food":"FOUNDATION","sr_legacy_food":"SR-LEGACY","survey_fndds_food":"FNDDS","branded_food":"BRANDED","experimental_food":"EXPERIMENTAL"}
            sid="AL-USDA-"+known.get(kind,kind.upper())
            if sid not in registry:registry[sid]={**registry["AL-USDA-FOUNDATION"],"name":"USDA FoodData Central — "+kind}
    temporary=workspace/"catalog.building.sqlite"
    if temporary.exists():raise FileExistsError("An interrupted private build already exists; preserve or recover it before a fresh build")
    exports=ROOT/".local/food-catalog/exports";exports.mkdir(parents=True,exist_ok=True)
    writer=CatalogWriter(temporary,registry,exports)
    reports={};start=time.monotonic()
    try:
        for name in ["legacy","taco","off","usda"]:
            if name in missing:continue
            print(canonical({"state":"ingesting","source":name}),flush=True)
            report=Counter();reports[name]=report
            if name=="legacy":foods=legacy_foods(inputs[name])
            elif name=="taco":foods=taco_foods(inputs[name])
            elif name=="off":foods=off_foods(inputs[name],registry["AL-OFF"]["version"],report)
            else:
                stage=workspace/"usda-stage.sqlite"
                if stage.exists():stage.unlink()
                foods=usda_foods(inputs[name],stage,report=report)
            count=0;last=time.monotonic()
            for food in foods:
                writer.add(food);count+=1
                if time.monotonic()-last>20:
                    print(canonical({"state":"ingesting","source":name,"foods":count,"elapsedSeconds":round(time.monotonic()-start)}),flush=True)
                    last=time.monotonic()
            report["outputFoods"]=count
            if count==0:raise ValueError("Official source produced zero usable foods: "+name)
            if name=="taco" and count!=597:raise ValueError("TACO fourth edition coverage differs from its 597 foods")
            print(canonical({"state":"source_complete","source":name,**dict(report)}),flush=True)
        if args.community and args.community.exists():
            for food in community_foods(args.community):writer.add(food)
        payload=writer.finish()
    except BaseException:
        writer.db.close()
        for stream in writer.streams.values():stream.close()
        raise
    distribution=ROOT/".local/food-catalog/distribution";distribution.mkdir(parents=True,exist_ok=True)
    final=distribution/"catalog.sqlite"
    if final.exists():raise FileExistsError("Refusing to overwrite an archived uncompressed catalog")
    temporary.rename(final)
    payload.update({"file":"catalog.sqlite","complete":not missing,"fixture":False,
                    "missingSources":missing,"sourceReports":{k:dict(v) for k,v in reports.items()},
                    "sourceArtifacts":[]})
    for name,path in inputs.items():
        if path.exists():
            receipt_path=path.with_name(path.name+".receipt.json")
            receipt=json.loads(receipt_path.read_text(encoding="utf-8")) if receipt_path.exists() else {}
            payload["sourceArtifacts"].append({"source":name,"file":path.name,"sha256":sha_file(path),"bytes":path.stat().st_size,
                                                **{k:receipt[k] for k in ["url","etag","lastModified"] if k in receipt}})
    export_report=[]
    for path in sorted(exports.glob("*.jsonl.gz")):
        source_id=path.name[:-9]
        if not payload["counts"].get(source_id):continue
        export_report.append({"file":path.name,"bytes":path.stat().st_size,"sha256":sha_file(path),
                              "rows":payload["counts"][source_id],"sourceId":source_id,
                              "license":registry[source_id]["licenseLabel"]})
    payload["exports"]=export_report
    sign_manifest(payload,args.signing_dir,output)
    public=ROOT/"content/food_catalog";public.mkdir(parents=True,exist_ok=True)
    (public/"sources.json").write_text(canonical(registry)+"\n",encoding="utf-8")
    (public/"catalog.lock.json").write_text(canonical({"contract":"trainforge.food-catalog-lock/1",**payload})+"\n",encoding="utf-8")
    report={"contract":"trainforge.food-catalog-build/1","complete":not missing,"counts":payload["counts"],"bytes":payload["bytes"],"sha256":payload["sha256"],"version":payload["version"],"elapsedSeconds":round(time.monotonic()-start),"sourceReports":payload["sourceReports"]}
    (public/"build-report.json").write_text(canonical(report)+"\n",encoding="utf-8")
    # Public per-source exports stay in a separate artifact folder, never private data.
    (public/"exports.json").write_text(canonical({"contract":"trainforge.food-catalog-exports/1","version":payload["version"],"artifacts":export_report})+"\n",encoding="utf-8")
    from food_catalog_package import package
    package(output,distribution,args.signing_dir)
    report=json.loads((public/"build-report.json").read_text(encoding="utf-8"))
    print(canonical(report),flush=True)
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    action=parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--build",action="store_true");action.add_argument("--verify",action="store_true")
    parser.add_argument("--raw-dir",type=Path,default=ROOT/".local/food-catalog/raw")
    parser.add_argument("--output-dir",type=Path,default=ROOT/"assets/food_catalog")
    parser.add_argument("--legacy",type=Path,default=ROOT/"content/local/food-approved-v1.jsonl")
    parser.add_argument("--signing-dir",type=Path,default=ROOT/".local/food-catalog/signing")
    parser.add_argument("--community",type=Path)
    parser.add_argument("--allow-incomplete",action="store_true")
    args=parser.parse_args()
    if args.verify:print(canonical(verify_bundle(args.output_dir)),flush=True)
    else:build(args)


if __name__=="__main__":main()
