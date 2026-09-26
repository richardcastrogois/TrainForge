"""N01: identidades alimentares Ciqual. Sem rede, nutrientes ou prescricao.

Confere corpos contra hashes de coleta e checksums do deposito; verifica
identidade/classificacao e cruza com a planilha da mesma edicao. O normalizado
integral fica local; resumo e exemplos selecionados podem ser revisados no Git.
"""
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
OUT = HERE / "2026-09-26/n01-alimentos"
FIELDS = ("alim_grp_code", "alim_ssgrp_code", "alim_ssssgrp_code")
SAMPLE_IDS = ["9100", "9104", "25088", "22000", "22010", "22013", "19023", "19024", "26024", "26043", "17270", "20359", "20360", "20507", "20516", "20532", "36017", "36018", "36029", "13005", "13089", "9313", "32140", "4003", "4008", "20048", "20137", "26034", "26040", "24999"]
# Fixtures checked against the actual source names; no translated search aliases.
PAIR_CHECKS = [
    ("9100", "9104", "raw", "cooked"),
    ("22000", "22010", "raw", "hard-boiled"),
    ("26043", "26024", "raw", "salted"),
    ("20359", "20360", "dried", "boiled"),
    ("20516", "20507", "dried", "boiled"),
    ("36017", "36018", "raw", "grilled"),
    ("13005", "13089", "raw", "dried"),
    ("4008", "4003", "raw", "boiled"),
    ("20048", "20137", "drained", "solids and liquids"),
]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def clean(value):
    return " ".join((value or "").split())


def verified_xml(name, metadata_file):
    record = read_json(OUT / (name + ".evidencia.json"))
    if record.get("status") != 200 or record.get("error"):
        raise ValueError("No successful verified response for " + name)
    raw = (OUT / record["bodyFile"]).read_bytes()
    if hashlib.sha256(raw).hexdigest() != record["sha256"]:
        raise ValueError("SHA-256 mismatch: " + name)
    checksum = metadata_file["checksum"]
    if checksum["type"] != "MD5" or hashlib.md5(raw).hexdigest() != checksum["value"]:
        raise ValueError("Deposited version checksum mismatch: " + name)
    if b"<!DOCTYPE" in raw.upper() or b"<!ENTITY" in raw.upper():
        raise ValueError("Do not parse documents declaring entities")
    root = ET.fromstring(raw)
    if root.tag != "TABLE":
        raise ValueError("Unexpected XML root")
    return [{child.tag: clean(child.text) for child in row} for row in root], record


def main():
    meta_path = HERE / "ciqual-2025-metadata.json"
    meta_record = read_json(HERE / "ciqual-2025-metadata.evidencia.json")
    if hashlib.sha256(meta_path.read_bytes()).hexdigest() != meta_record["sha256"]:
        raise ValueError("Pinned metadata changed")
    version = read_json(meta_path)["data"]["latestVersion"]
    files = {f["dataFile"]["id"]: f["dataFile"] for f in version["files"]}
    foods, food_record = verified_xml("ciqual-alimentos", files[666252])
    groups, group_record = verified_xml("ciqual-grupos", files[666250])
    by_id = {f["alim_code"]: f for f in foods}
    by_group = {tuple(g[k] for k in FIELDS): g for g in groups}
    if len(by_id) != len(foods) or len(by_group) != len(groups):
        raise ValueError("Duplicate identity or classification tuple")
    if any(not f["alim_code"].isdigit() or not f["alim_nom_fr"] or not f["alim_nom_eng"] for f in foods):
        raise ValueError("Missing or invalid core identity")
    for row in foods:
        if any(not row[k].isdigit() or len(row[k]) != width for k, width in zip(FIELDS, (2, 4, 6))):
            raise ValueError("Classification codes lost padding")
    spec = importlib.util.spec_from_file_location("expansao_local", HERE / "analisar-expansao.py")
    expansion = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(expansion)
    workbook = HERE / "ciqual-2025.xlsx"
    workbook_evidence = read_json(HERE / "ciqual-2025-windows.evidencia.json")
    if hashlib.sha256(workbook.read_bytes()).hexdigest() != workbook_evidence["sha256"]:
        raise ValueError("Workbook version changed")
    sheet = expansion.read_sheet(workbook, "xl/worksheets/sheet1.xml")
    sheet_foods = {r["G"]: r for r in sheet[1:] if r.get("G", "").isdigit()}
    if set(sheet_foods) != set(by_id):
        raise ValueError("XML and XLSX food identities differ")
    mismatches = []
    for code, food in by_id.items():
        row = sheet_foods[code]
        for column, field in (("H", "alim_nom_fr"), ("I", "alim_nom_sci"), ("A", FIELDS[0]), ("B", FIELDS[1]), ("C", FIELDS[2])):
            if clean(row.get(column)) != food[field]:
                mismatches.append({"id": code, "field": field})
    if mismatches:
        raise ValueError("XML and XLSX identity fields differ: " + str(mismatches[:5]))
    records, unclassified = [], []
    for f in foods:
        key = tuple(f[k] for k in FIELDS)
        group = by_group.get(key)
        if group is None:
            unclassified.append(f["alim_code"])
        records.append({
            "sourceKey": "ciqual:2025:" + f["alim_code"], "sourceFoodId": f["alim_code"],
            "names": {"fr": f["alim_nom_fr"], "en": f["alim_nom_eng"]},
            "scientificName": f["alim_nom_sci"] or None,
            "classificationCodes": {k: f[k] for k in FIELDS},
            "classification": group,
            "classificationStatus": "matched" if group else "not_listed_in_group_file",
            "preparationStructured": None,
            "preparationNote": "Preparation/variant is embedded in the original names. No separate preparation field was supplied.",
            "portugueseName": None, "publicationStatus": "research_only",
        })
    for left, right, a, b in PAIR_CHECKS:
        if left == right or a not in by_id[left]["alim_nom_eng"].lower() or b not in by_id[right]["alim_nom_eng"].lower():
            raise ValueError("Preparation fixture changed")
    if "Cantonese" not in by_id["25088"]["alim_nom_eng"] or "white" not in by_id["9104"]["alim_nom_eng"]:
        raise ValueError("Compound dish identity lost")
    normalized = {"sourceId": "AL04", "sourceVersion": "Ciqual 2025; DOI 10.57745/RDMHWY V1", "license": version["license"], "records": records}
    dump(OUT / "raw/identidades-normalizadas.json", normalized)
    selected = {r["sourceFoodId"]: r for r in records}
    dump(OUT / "amostra-identidades.json", {**{k: v for k, v in normalized.items() if k != "records"}, "selection": "Thirty explicit IDs, including nine preparation pairs, a compound dish and the unclassified average dessert; convenience fixtures, not a Portugal coverage claim.", "records": [selected[i] for i in SAMPLE_IDS]})
    summary = {
        "niche": "N01", "researchStatus": "completed_with_explicit_scope_limits", "releaseApproved": False,
        "sourceId": "AL04", "sourceVersion": normalized["sourceVersion"],
        "foods": len(foods), "uniqueFoodIds": len(by_id), "classificationRows": len(groups),
        "groupLevelsUniqueNonzero": [len({g[k] for g in groups if int(g[k]) != 0}) for k in FIELDS],
        "namesFrench": sum(bool(f["alim_nom_fr"]) for f in foods), "namesEnglish": sum(bool(f["alim_nom_eng"]) for f in foods),
        "scientificNames": sum(bool(f["alim_nom_sci"]) for f in foods), "namesPortugueseSupplied": 0,
        "duplicateFrenchNames": sum(n > 1 for n in Counter(f["alim_nom_fr"] for f in foods).values()),
        "unclassifiedFoodIds": unclassified,
        "checks": {"inputHashesVerified": 4, "depositMd5Verified": 2, "xmlXlsxIdentityMatches": len(by_id), "classificationPaddingPreserved": True, "preparationPairs": len(PAIR_CHECKS), "compoundDishSeparated": True, "sampleRecords": len(SAMPLE_IDS)},
        "provenance": [{k: r[k] for k in ("url", "collectedAtUtc", "sha256")} for r in (food_record, group_record)],
        "limits": ["Not all foods or brands sold in Portugal", "No Portuguese names in source", "Preparation embedded in names, not structured field", "One unclassified generic dessert; retain unknown classification", "No calories, serving sizes, photos, recommendations or diets assessed in this niche", "Normalized full dataset kept locally, not seeded into the app"],
    }
    dump(OUT / "resumo-identidades.json", summary)
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
