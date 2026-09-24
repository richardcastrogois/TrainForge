"""Reduz as amostras locais a evidencias consultaveis, sem rede ou dependencias."""
import collections
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parent
NS = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def read_sheet(path, sheet_file):
    with zipfile.ZipFile(path) as archive:
        strings = ["".join(t.text or "" for t in item.iter("{" + NS["s"] + "}t")) for item in ET.fromstring(archive.read("xl/sharedStrings.xml"))]
        rows = ET.fromstring(archive.read(sheet_file)).find("s:sheetData", NS)
        result=[]
        for row in rows:
            cells={}
            for cell in row:
                value=cell.find("s:v", NS)
                if value is not None:
                    cells[re.sub(r"\d", "", cell.get("r"))] = strings[int(value.text)] if cell.get("t")=="s" else value.text
            result.append(cells)
        return result


def dump(name, data):
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def cofid():
    rows=read_sheet(ROOT/"cofid-2021.xlsx", "xl/worksheets/sheet4.xml")
    foods=[row for row in rows if re.fullmatch(r"\d{2}-\d{3}",row.get("A",""))]
    patterns={"arroz":r"^Rice, (white|brown)", "leite":r"^Milk, (whole|semi-skimmed|skimmed)", "ovo":r"^Eggs, chicken, whole", "bacalhau":r"^Cod,", "azeite":r"^Oil, olive", "lentilhas":r"^Lentils,", "frango":r"^Chicken, breast", "pao":r"^Bread, (white|wholemeal)", "banana":r"^Bananas,", "aveia":r"^Oats,", "iogurte":r"^Yogurt, (plain|natural)", "queijo":r"^Cheese, (Cheddar|cottage)", "feijao":r"^Beans, (kidney|butter)", "batata":r"^Potatoes, (old|new)", "tomate":r"^Tomatoes,", "sardinha":r"^Sardines,"}
    fields={"A":"sourceId","B":"nameOriginal","C":"descriptionOriginal","D":"groupOriginal","F":"dataReferencesOriginal","G":"footnoteOriginal","J":"proteinG","K":"fatG","L":"carbohydrateG","M":"energyKcal","N":"energyKj","Z":"fibreAoacG"}
    samples=[];coverage={}
    for term,pattern in patterns.items():
        matches=[row for row in foods if re.search(pattern,row.get("B",""),re.I)]
        coverage[term] = {"pattern":pattern,"matches":len(matches),"sampleIds":[row["A"] for row in matches[:2]]}
        for row in matches[:2]:
            samples.append({"queryPt":term,"matchedPattern":pattern,"valuesOriginal":{label:row.get(col) for col,label in fields.items()}})
    all_core=lambda row:all(re.fullmatch(r"\d+(\.\d+)?",row.get(k,"")) for k in ("J","K","L","M"))
    out={"source":"CoFID 2021, Public Health England", "license":"Open Government Licence v3.0, subject to stated exceptions", "sheet":"1.3 Proximates", "parsedFoods":len(foods), "sampleMethod":"First up to two matching records per declared regex. Convenience sample; not Portugal coverage validation.", "quantityBasis":"Per 100 g except alcoholic drinks per 100 ml; certain FA sheets per 100 g fatty acids. These exceptions must be kept when importing.", "specialValues":{"Tr":"trace, not zero","N":"present but reliable quantity unavailable, not zero","blank":"not supplied, not zero"}, "coreNumericInSample":sum(all_core(row) for row in foods if any(row["A"] in c["sampleIds"] for c in coverage.values())), "queries":coverage,"sample":samples}
    dump("cofid-amostra.json",out)
    return {"parsedFoods":len(foods),"queryGroups":len(coverage),"queryGroupsWithMatch":sum(bool(c["matches"]) for c in coverage.values()),"selectedRecords":len(samples),"coreNumericInSample":out["coreNumericInSample"]}


def wger():
    paths=[ROOT.parents[1]/"planejamento"/"evidencias"/"wger-25.json",ROOT/"wger-offset-300.json",ROOT/"wger-offset-600.json"]
    pages=[]; all_records={}
    for path in paths:
        obj=json.loads(path.read_text(encoding="utf-8")); obj=obj.get("data",obj)
        records=obj["results"]
        def metrics(records):
            return {"records":len(records),"portuguese":sum(any(t.get("language")==7 for t in e.get("translations",[])) for e in records),"withImages":sum(bool(e.get("images")) for e in records),"withVideos":sum(bool(e.get("videos")) for e in records),"imagesFlaggedAi":sum(i.get("is_ai_generated") is True for e in records for i in e.get("images",[])),"licenses":dict(collections.Counter(e.get("license",{}).get("short_name") for e in records))}
        pages.append({"file":path.name,"reportedCatalogCount":obj.get("count"),**metrics(records)})
        all_records.update({e["id"]:e for e in records})
    suspect=all_records.get(1022,{})
    example={"exerciseId":1022,"finding":"Translations within one ID appear to describe different movements. Manual editorial finding, not automated clinical diagnosis.","namesByLanguage":[{"languageId":t["language"],"name":t["name"]} for t in suspect.get("translations",[])],"publicationStatus":"hold_for_semantic_review"}
    out={"method":"25 records each at offsets 0, 300, 600; convenience sample, not random or exhaustive; two collection dates may differ.","pages":pages,"combinedUnique":metrics(list(all_records.values())),"editorialExample":example}
    dump("wger-amostra-ampliada.json",out)
    return out


def ciqual():
    rows=read_sheet(ROOT/"ciqual-2025.xlsx", "xl/worksheets/sheet1.xml")
    foods=[row for row in rows[1:] if row.get("G","").isdigit()]
    patterns={"arroz":r"^Riz ","leite":r"^Lait demi", "ovo":r"^(Oeuf|Œuf)","bacalhau":r"^(Cabillaud|Morue)","azeite":r"^Huile d'olive", "lentilhas":r"^Lentille", "frango":r"^Poulet, filet", "pao":r"^Pain ", "banana":r"^Banane", "aveia":r"^Flocon d'avoine", "iogurte":r"^Yaourt", "queijo":r"^Fromage", "feijao":r"^Haricot", "batata":r"^Pomme de terre", "tomate":r"^Tomate", "sardinha":r"^Sardine"}
    fields={"G":"sourceId","H":"nameOriginal","I":"scientificName","K":"energyKcalEU1169","M":"energyKcalJones","O":"proteinJonesG","P":"proteinNx625G","Q":"carbohydrateG","R":"fatG","AA":"fibreG","AX":"saltG","BI":"sodiumMg"}
    sample=[];coverage={}
    for term,pattern in patterns.items():
        matches=[r for r in foods if re.search(pattern,r.get("H",""),re.I)]
        coverage[term]={"pattern":pattern,"matches":len(matches),"sampleIds":[r["G"] for r in matches[:2]]}
        sample += [{"queryPt":term,"matchedPattern":pattern,"valuesOriginal":{label:r.get(col) for col,label in fields.items()}} for r in matches[:2]]
    special=collections.Counter()
    for row in foods:
        for column in ("K","O","P","Q","R","AA"):
            val=row.get(column,"").strip()
            if val=="-":special["dashMissing"]+=1
            elif val.startswith("<"):special["lessThanBound"]+=1
            elif val.lower()=="traces":special["trace"]+=1
            elif not val:special["blank"]+=1
    result={"source":"Anses, Table Ciqual 2025; Recherche Data Gouv V1, doi:10.57745/RDMHWY", "license":"Licence Ouverte Etalab 2.0", "parsedFoods":len(foods),"method":"Up to first two rows matching each declared regex; not reviewed equivalences to Portuguese foods.","units":"Values per 100 g as specified in headers; preserve each nutrient's unit and method.","sourceColumns":{label:rows[0].get(col) for col,label in fields.items()},"caution":"Excel lacks per-food/per-nutrient source records available in XML; large composition XML was not downloaded.","specialCellsInSixSelectedColumns":dict(special),"queries":coverage,"sample":sample}
    dump("ciqual-amostra.json",result)
    return {"parsedFoods":len(foods),"queryGroups":len(patterns),"queryGroupsWithMatch":sum(bool(v["matches"]) for v in coverage.values()),"selectedRecords":len(sample),"specialCellsInSixSelectedColumns":dict(special)}


if __name__=="__main__":
    summary={"cofid":cofid(),"ciqual":ciqual(),"wger":wger()}
    collected=json.loads((ROOT/"coleta-resumo.json").read_text(encoding="utf-8"))
    native=ROOT/"ciqual-2025-windows.evidencia.json"
    if native.exists(): collected.append(json.loads(native.read_text(encoding="utf-8-sig")))
    summary["requests"]={"total":len(collected),"http200":sum(r.get("status")==200 for r in collected),"failures":[{"id":r["id"],"status":r.get("status"),"error":r.get("error")} for r in collected if r.get("status")!=200]}
    summary["compendium"]={"pages":5,"selectedActivities":sum(len(r.get("sample",[])) for r in collected),"note":"Official original codes, MET values and descriptions retained; no physiological validation or translation implied."}
    dump("resumo-expansao.json",summary)
    manifest=[]
    for path in sorted(ROOT.iterdir()):
        if path.is_file() and path.name!="manifesto.json":
            raw=path.read_bytes();manifest.append({"file":path.name,"bytes":len(raw),"sha256":hashlib.sha256(raw).hexdigest()})
    dump("manifesto.json",manifest)
    print(json.dumps(summary,ensure_ascii=True))
