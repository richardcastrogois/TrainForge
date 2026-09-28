"""N02: inventario nutricional reproduzivel. Somente arquivos locais, sem rede.

Pesquisa de dados, nao integracao ou prescricao. O normalizado integral fica
em raw ignorado; o dicionario, as contagens e 30 exemplos sao revisaveis.
"""
from collections import Counter
from decimal import Decimal, InvalidOperation
import hashlib
import importlib.util
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
DAY = HERE / "2026-09-26"
OUT = DAY / "n02-composicao"
CORE = {
    "K": "energyKcalEu", "J": "energyKjEu", "P": "proteinNx625G",
    "Q": "carbohydrateG", "R": "fatG", "S": "sugarsG",
    "AA": "fibreG", "AF": "saturatedFatG", "AX": "saltG", "BI": "sodiumMg",
}
METHODS = {"J": "EU1169_Nx6.25", "K": "EU1169_Nx6.25",
           "L": "Jones_with_fibre", "M": "Jones_with_fibre",
           "O": "nitrogen_times_Jones", "P": "nitrogen_times_6.25"}
STATES = ("numeric", "unknown", "trace", "below_limit")


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def numeric(value):
    if not re.fullmatch(r"\d+(?:[.,]\d+)?", value):
        raise ValueError("Unsupported numeric token: " + value)
    result = Decimal(value.replace(",", "."))
    if not result.is_finite() or result < 0:
        raise ValueError("Invalid nutrition quantity")
    return format(result, "f")


def parse_cell(raw):
    value = " ".join((raw or "").split())
    out = {"raw": raw, "status": None, "valueDecimal": None, "limitDecimal": None}
    if value in ("", "-"):
        out["status"] = "unknown"
    elif value.lower() == "traces":
        out["status"] = "trace"
    elif value.startswith("<"):
        out.update(status="below_limit", limitDecimal=numeric(value[1:].strip()))
    else:
        out.update(status="numeric", valueDecimal=numeric(value))
    return out


def compare_contracts():
    usda_path = HERE.parents[1] / "planejamento/evidencias/usda-egg-detail.json"
    usda = read(usda_path)["data"]
    entries = usda["foodNutrients"]
    labels = [r for r in entries if r["nutrient"].get("isNutrientLabel")]
    absent = [r for r in entries if "amount" not in r and not r["nutrient"].get("isNutrientLabel")]
    selected_ids = {1003, 1004, 1005, 1008, 1079, 1093, 2000, 2047, 2048}
    examples = [{"nutrientId": r["nutrient"]["id"], "name": r["nutrient"]["name"],
                 "unitOriginal": r["nutrient"]["unitName"], "amount": r.get("amount"),
                 "derivationCode": r.get("foodNutrientDerivation", {}).get("code")}
                for r in entries if r["nutrient"]["id"] in selected_ids]
    assert labels and all("amount" not in r for r in labels)
    assert any(r["nutrientId"] == 1008 and r["amount"] == 148 for r in examples)
    cofid_path = HERE / "cofid-amostra.json"
    cofid = read(cofid_path)
    return {
        "scope": "Observed local records, not automatic cross-source food or nutrient equivalence",
        "ciqual": {"format": "XLSX", "idPath": "column G", "valuePathExample": "column K",
                   "basis": "100 g as declared in nutrient headers", "decimalSeparator": ",",
                   "nutrientIdsInWorkbook": False},
        "usda": {"format": "JSON originally nested by our collector under data",
                 "artifactSha256": digest(usda_path), "artifactHashIsOriginalHttpBodyHash": False,
                 "foodId": usda["fdcId"], "dataType": usda["dataType"],
                 "nutrientPath": "foodNutrients[].nutrient.id", "valuePath": "foodNutrients[].amount",
                 "rows": len(entries), "groupLabelRows": len(labels), "nonLabelRowsWithoutAmount": len(absent),
                 "samples": examples, "warning": "Carbohydrate by difference and available carbohydrate are not equivalent labels"},
        "cofid": {"format": "XLSX", "sampleArtifactSha256": digest(cofid_path),
                  "quantityBasisRecorded": cofid["quantityBasis"], "specialValuesRecorded": cofid["specialValues"],
                  "warning": "Do not apply the Ciqual comma/sentinel parser or assume all workbook sheets use the same basis"},
    }


def main():
    evidence = read(HERE / "ciqual-2025-windows.evidencia.json")
    workbook = HERE / "ciqual-2025.xlsx"
    if digest(workbook) != evidence["sha256"]:
        raise ValueError("Workbook differs from collected bytes")
    n01 = read(DAY / "n01-alimentos/raw/identidades-normalizadas.json")
    identity = {r["sourceFoodId"]: r for r in n01["records"]}
    spec = importlib.util.spec_from_file_location("ciqual_reader", HERE / "analisar-expansao.py")
    reader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reader)
    sheet = reader.read_sheet(workbook, "xl/worksheets/sheet1.xml")
    headers = sheet[0]
    definitions = []
    for column, raw in headers.items():
        label = " ".join(raw.split())
        unit = re.search(r"\((kJ|kcal|g|mg|µg) 100 g\)", label)
        if not unit:
            continue
        definitions.append({
            "sourceColumn": column, "sourceNutrientId": None,
            "sourceHeaderRaw": raw, "nameOriginal": label,
            "unit": unit[1], "basis": {"quantity": "100", "unit": "g"},
            "method": METHODS.get(column, "as_described_by_source_header"),
            "proposedAppKey": CORE.get(column),
        })
    if len(definitions) != 74:
        raise ValueError("Unexpected number of composition columns")
    foods = [r for r in sheet[1:] if r.get("G", "").isdigit()]
    if len(foods) != len(identity) or {r["G"] for r in foods} != set(identity):
        raise ValueError("N01 / N02 food identities differ")
    counts = {d["sourceColumn"]: Counter() for d in definitions}
    normalized, zero_counts = [], Counter()
    for row in foods:
        values = {d["sourceColumn"]: parse_cell(row.get(d["sourceColumn"])) for d in definitions}
        for col, value in values.items():
            counts[col][value["status"]] += 1
            if value["valueDecimal"] is not None and Decimal(value["valueDecimal"]) == 0:
                zero_counts[col] += 1
        normalized.append({"sourceKey": identity[row["G"]]["sourceKey"],
                           "sourceFoodId": row["G"], "nameOriginal": row["H"],
                           "valuesBySourceColumn": values, "jonesFactorOriginal": row.get("CF"),
                           "publicationStatus": "research_only"})
    for d in definitions:
        col = d["sourceColumn"]
        d["coverage"] = {s: counts[col][s] for s in STATES}
        d["coverage"]["zeroNumericSubset"] = zero_counts[col]
        assert sum(d["coverage"][s] for s in STATES) == len(foods)
    selected_ids = [r["sourceFoodId"] for r in read(DAY / "n01-alimentos/amostra-identidades.json")["records"]]
    by_id = {r["sourceFoodId"]: r for r in normalized}
    complete_core = sum(all(r["valuesBySourceColumn"][c]["status"] == "numeric" for c in CORE) for r in normalized)
    energy_and_macros = ("K", "P", "Q", "R")
    complete_macros = sum(all(r["valuesBySourceColumn"][c]["status"] == "numeric" for c in energy_and_macros) for r in normalized)
    total = Counter()
    for c in counts.values():
        total.update(c)
    # Fixtures exercise distinct scientific meanings; no silent imputation.
    assert parse_cell("0")["valueDecimal"] == "0"
    assert parse_cell("-")["valueDecimal"] is None
    assert parse_cell("traces")["status"] == "trace"
    assert parse_cell("< 0,08")["limitDecimal"] == "0.08"
    assert parse_cell(None)["status"] == "unknown"
    rejected = 0
    for token in ("NaN", "inf", "-1", "1 g", "1,2,3"):
        try:
            parse_cell(token)
        except (ValueError, InvalidOperation):
            rejected += 1
    assert rejected == 5
    assert by_id["9100"]["valuesBySourceColumn"]["K"]["valueDecimal"] == "350"
    assert by_id["9100"]["valuesBySourceColumn"]["M"]["valueDecimal"] == "348"
    assert by_id["9104"]["valuesBySourceColumn"]["K"]["valueDecimal"] == "155"
    common = {"sourceId": "AL04", "sourceVersion": n01["sourceVersion"],
              "inputSha256": evidence["sha256"], "license": n01["license"],
              "scope": "research_only; column coordinates are not provider nutrient IDs"}
    save(OUT / "dicionario-composicao.json", {**common, "definitions": definitions})
    save(OUT / "amostra-composicao.json", {**common, "selection": "Same 30 explicit food IDs as N01; not a representative sample of Portugal",
                                          "records": [by_id[i] for i in selected_ids]})
    save(DAY / "raw/n02-composicao-normalizada.json", {**common, "records": normalized})
    summary = {
        "niche": "N02", "researchStatus": "completed_with_explicit_scope_limits", "releaseApproved": False,
        "foods": len(foods), "matchedN01Ids": len(identity), "compositionFields": len(definitions),
        "cells": len(foods) * len(definitions), "cellStates": dict(total),
        "numericZeroCells": sum(zero_counts.values()), "completeNumericEnergyAndMacros": complete_macros,
        "completeNumericTenProposedFields": complete_core,
        "coreFieldCoverage": {CORE[d["sourceColumn"]]: d["coverage"] for d in definitions if d["sourceColumn"] in CORE},
        "checks": {"inputWorkbookHashVerified": True, "sameFoodIdsAsN01": True, "sampleIds": len(selected_ids),
                   "allCellsParsedWithoutFallback": True, "statusFixtures": 5, "invalidFixturesRejected": rejected,
                   "rawAndCookedRiceAndDistinctEnergyMethods": True},
        "limits": ["No per-food nutrient bibliography from composition XML", "No silent nutrient completion from another food/source",
                   "Measured/estimated provenance not available per cell in this workbook", "No serving or millilitre conversion in N02",
                   "Food names not localized to Portuguese; no individual nutrition targets", "No app or database integration"],
    }
    save(OUT / "resumo-composicao.json", summary)
    save(OUT / "comparacao-contratos.json", compare_contracts())
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
