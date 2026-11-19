"""Reproducible source-backed food catalog; no network is used by builders.

Amounts are decimal strings. Original cells, unknowns and source versions survive
normalization. A canonical nutrient is a presentation/aggregation mapping, never
an assertion that measurements from different analytical methods are identical.
"""
from __future__ import annotations

from collections import Counter
from contextlib import contextmanager
from decimal import Decimal, InvalidOperation
import base64
import csv
from functools import lru_cache
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sqlite3
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = "trainforge.food-catalog/1"
SCHEMA_VERSION = 1
csv.field_size_limit(2**31 - 1)


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True,
                      separators=(",", ":"), allow_nan=False)


def storage_json(value):
    """Compress repetitive per-food metadata without changing its JSON meaning."""
    text=canonical(value)
    if len(text)<512:return text
    compressed="zlib:"+base64.b64encode(zlib.compress(text.encode("utf-8"),1)).decode("ascii")
    return compressed if len(compressed)<len(text) else text


def decode_storage_json(value):
    if value.startswith("zlib:"):
        value=zlib.decompress(base64.b64decode(value[5:],validate=True)).decode("utf-8")
    return json.loads(value)


def sha_file(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


@lru_cache(maxsize=8192)
def folded(value):
    return " ".join("".join(c for c in unicodedata.normalize("NFKD", str(value))
                            if not unicodedata.combining(c)).lower().split())


def decimal_text(value):
    if value is None or isinstance(value, bool):
        return None
    try:
        number = Decimal(str(value).strip().replace(",", "."))
    except (InvalidOperation, ValueError):
        return None
    if not number.is_finite() or number < 0:
        return None
    text = format(number, "f")
    return text.rstrip("0").rstrip(".") if "." in text else text


def parse_value(raw):
    token = "" if raw is None else str(raw).strip()
    key = folded(token)
    if key in {"", "-", "na", "n/a", "nan", "null", "not available"}:
        return {"state": "missing", "value": None, "upperBound": None, "rawText": token}
    if key in {"tr", "trace", "traces", "traco", "tracos"}:
        return {"state": "trace", "value": None, "upperBound": None, "rawText": token}
    if key == "n":
        return {"state": "present_quantity_unknown", "value": None,
                "upperBound": None, "rawText": token}
    bound = token.startswith("<")
    value = decimal_text(token[1:].strip() if bound else token)
    return {"state": "less_than" if bound and value is not None else
            "numeric" if value is not None else "unparsed",
            "value": None if bound else value,
            "upperBound": value if bound else None, "rawText": token}


CANONICAL_UNITS = {
    "energy_kcal": "kcal", "protein_g": "g", "carbohydrate_g": "g",
    "fat_g": "g", "fiber_g": "g", "sugars_g": "g",
    "saturated_fat_g": "g", "sodium_mg": "mg", "cholesterol_mg": "mg",
    "calcium_mg": "mg", "iron_mg": "mg", "potassium_mg": "mg",
    "magnesium_mg": "mg", "phosphorus_mg": "mg", "zinc_mg": "mg",
    "copper_mg": "mg", "manganese_mg": "mg", "vitamin_c_mg": "mg",
    "thiamin_mg": "mg", "riboflavin_mg": "mg", "niacin_mg": "mg",
    "vitamin_b6_mg": "mg", "vitamin_b12_ug": "µg", "vitamin_d_ug": "µg",
}

# Ordered mappings: retain all original cells and select only one eligible cell
# per nutrient for a descriptive total. Incompatible methods stay distinguishable.
NAME_RULES = [
    ("energy_kcal", r"^(energy|energie|energia)", "kcal"),
    ("protein_g", r"^(protein|proteine|proteina)", "g"),
    ("carbohydrate_g", r"^(carbohydrate|glucide|carboidrato|hidratos de carbono)", "g"),
    ("fat_g", r"^(fat\b|lipid|lipide|lipideo|gordura total|total lipid)", "g"),
    ("fiber_g", r"^(fibre|fiber|fibra)", "g"),
    ("sugars_g", r"^(sugars|sucres|acucares)", "g"),
    ("saturated_fat_g", r"^(fatty acids, total saturated|saturated|ag satures|acidos graxos saturados)", "g"),
    ("sodium_mg", r"^(sodium|sodio)", "mg"),
    ("cholesterol_mg", r"^cholesterol|^colesterol", "mg"),
    ("calcium_mg", r"^calcium|^calcio", "mg"),
    ("iron_mg", r"^iron|^fer\b|^ferro", "mg"),
    ("potassium_mg", r"^potassium|^potassio", "mg"),
    ("magnesium_mg", r"^magnesium|^magnesio", "mg"),
    ("phosphorus_mg", r"^phosphorus|^phosphore|^fosforo", "mg"),
    ("zinc_mg", r"^zinc|^zinco", "mg"),
    ("copper_mg", r"^copper|^cuivre|^cobre", "mg"),
    ("manganese_mg", r"^manganese|^manganes", "mg"),
    ("vitamin_c_mg", r"^vitamin c|^vitamine c|^vitamina c", "mg"),
    ("thiamin_mg", r"^thiamin|^tiamina", "mg"),
    ("riboflavin_mg", r"^riboflavin|^riboflavina", "mg"),
    ("niacin_mg", r"^niacin|^niacine|^niacina", "mg"),
    ("vitamin_b6_mg", r"^vitamin b.?6|^vitamine b.?6|^piridoxina", "mg"),
    ("vitamin_b12_ug", r"^vitamin b.?12|^vitamine b.?12", "µg"),
    ("vitamin_d_ug", r"^vitamin d\b|^vitamine d\b", "µg"),
]


@lru_cache(maxsize=8192)
def nutrient_id(name, unit):
    name = folded(name)
    unit = (unit or "").replace("μ", "µ").replace("mcg", "µg").replace("ug", "µg")
    for key, pattern, expected in NAME_RULES:
        if unit == expected and re.search(pattern, name):
            return key
    return None


def canonical_cells(original, source_id):
    result, selected = [], set()
    # Source-listed order is deterministic and expresses the documented primary
    # method. Energy alternatives (e.g. Jones vs EU label) never get summed.
    for cell in original:
        key = cell.get("nutrientId") or nutrient_id(cell["nameOriginal"], cell.get("unit"))
        if key is None:
            continue
        eligible = (cell["state"] == "numeric" and cell.get("value") is not None
                    and cell.get("basisQuantity") is not None
                    and cell.get("basisUnit") in {"g", "ml"}
                    and cell.get("scalingAllowed", True))
        primary = eligible and key not in selected
        target_unit = CANONICAL_UNITS[key]
        source_unit = (cell.get("unit") or "").replace("μ", "µ")
        scales = {"g": Decimal(1), "mg": Decimal("0.001"), "µg": Decimal("0.000001")}
        factor = Decimal(1)
        if source_unit != target_unit:
            if source_unit in scales and target_unit in scales:
                factor = scales[source_unit] / scales[target_unit]
            else:
                primary = False
        if primary:
            selected.add(key)
        value = cell.get("value")
        bound = cell.get("upperBound")
        if value is not None:
            value = decimal_text(Decimal(value) * factor)
        if bound is not None:
            bound = decimal_text(Decimal(bound) * factor)
        result.append({"nutrientId": key, "unit": target_unit,
                       "value": value, "state": cell["state"],
                       "upperBound": bound,
                       "methodId": cell.get("methodId", source_id + ":" + cell["sourceColumnKey"]),
                       "primaryForTotals": primary,
                       "basisQuantity": cell.get("basisQuantity"),
                       "basisUnit": cell.get("basisUnit"),
                       "sourceColumnKey": cell["sourceColumnKey"]})
    return result


def normalized_barcode(code):
    code = str(code).strip()
    if not re.fullmatch(r"[0-9]{8}|[0-9]{12,14}", code):
        return None
    weighted = sum(int(c) * (3 if i % 2 == 0 else 1)
                   for i, c in enumerate(reversed(code[:-1])))
    if (10 - weighted % 10) % 10 != int(code[-1]):
        return None
    return code.zfill(14)


def portion(food_id, label, quantity, unit, source_id, condition=""):
    quantity = decimal_text(quantity)
    if quantity is None or Decimal(quantity) <= 0 or unit not in {"g", "ml"}:
        return None
    payload = {"label": str(label).strip(), "quantity": quantity, "unit": unit,
               "condition": condition, "sourceId": source_id}
    return {"id": hashlib.sha256((food_id + "\0" + canonical(payload)).encode()).hexdigest(), **payload}


def make_food(source_id, source_food_id, name, locale, source_version, basis,
              original, *, brand=None, preparation=None, portions=None,
              barcodes=None, provenance=None, food_id=None, version_id=None):
    if not str(name).strip():
        raise ValueError("Food requires an original name")
    ident = food_id or "food:" + hashlib.sha256((source_id + "\0" + str(source_food_id)).encode()).hexdigest()
    record = {"contract": CONTRACT, "foodId": ident, "sourceId": source_id,
              "sourceFoodId": str(source_food_id), "sourcePublishedVersion": str(source_version),
              "nameOriginal": str(name).strip(), "nameLocale": locale,
              "basis": basis, "preparation": preparation, "brand": brand,
              "canonicalNutrients": canonical_cells(original, source_id),
              "originalNutrients": original, "portions": portions or [],
              "barcodes": sorted(set(str(v) for v in (barcodes or []) if str(v).strip())),
              "allowedOperations": ["food_catalog", "food_composition"],
              "provenance": provenance or {"sourceId": source_id}}
    if any(c["primaryForTotals"] for c in record["canonicalNutrients"]):
        record["allowedOperations"].append("food_quantity_scale")
    record["versionId"] = version_id or hashlib.sha256(canonical(record).encode()).hexdigest()
    return record


def legacy_foods(path):
    with Path(path).open("rb") as stream:
        for raw in stream:
            if not raw.strip():
                raise ValueError("Blank legacy food row")
            row = json.loads(raw)
            cells = [{**cell, "rawText": str(cell.get("raw") if cell.get("raw") is not None else "")}
                     for cell in row["nutrients"]]
            yield make_food(row["sourceId"], row["sourceFoodId"], row["nameOriginal"],
                            row["nameLocale"], row["sourcePublishedVersion"], row["basis"], cells,
                            preparation=row.get("preparation"), provenance=row["provenance"],
                            food_id=row["foodId"], version_id=hashlib.sha256(raw.rstrip(b"\r\n")).hexdigest())


def community_foods(path):
    """Consume only the maintainer's approved, explicitly licensed export."""
    with Path(path).open(encoding="utf-8") as stream:
        for text in stream:
            record=json.loads(text)
            consent=record.get("consent",{})
            if (record.get("contract")!="trainforge.food-contribution-export/1"
                    or record.get("sourceId")!="TF-COMMUNITY-1"
                    or consent.get("accepted") is not True
                    or consent.get("license")!="CC0-1.0"
                    or consent.get("version")!="trainforge.food-contribution/1"
                    or not record.get("reviewedAt")):
                raise ValueError("Community contribution lacks approval or explicit CC0 consent")
            source_id="TF-COMMUNITY-1"
            source_food_id=record.get("sourceFoodId","")
            if not re.fullmatch(r"[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}",source_food_id):
                raise ValueError("Community contribution requires stable approved identity")
            food=record["food"];basis=food["basis"]
            if basis.get("quantity") is not None and (decimal_text(basis["quantity"]) is None
                    or Decimal(basis["quantity"])<=0 or basis.get("unit") not in {"g","ml"}):
                raise ValueError("Invalid community composition basis")
            original=[]
            for index,n in enumerate(food.get("nutrients",[])):
                original.append({"sourceColumnKey":source_id+":"+folded(n["name"])+":"+n["unit"],
                                 "nameOriginal":n["name"],"unit":n["unit"],**parse_value(n.get("value")),
                                 "basisQuantity":basis.get("quantity"),"basisUnit":basis.get("unit"),
                                 "scalingAllowed":basis.get("quantity") is not None,
                                 "methodId":"community:declared-label"})
            ident="food:"+hashlib.sha256((source_id+"\0"+source_food_id).encode()).hexdigest()
            portions=[]
            for p in food.get("portions",[]):
                normalized=portion(ident,p["label"],p.get("quantity"),p.get("unit"),source_id,p.get("condition",""))
                if normalized:portions.append(normalized)
            yield make_food(source_id,source_food_id,food["name"],food.get("nameLocale","und"),"1",basis,original,
                            brand=food.get("brand"),preparation=food.get("preparation"),portions=portions,
                            barcodes=food.get("barcodes",[]),
                            provenance={"reviewedAt":record["reviewedAt"],"consent":consent})


def xlsx_rows(archive, sheet):
    ns = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
    shared = []
    if "xl/sharedStrings.xml" in archive.namelist():
        with archive.open("xl/sharedStrings.xml") as stream:
            for _, elem in ET.iterparse(stream, events=("end",)):
                if elem.tag.endswith("}si"):
                    shared.append("".join(t.text or "" for t in elem.findall(".//m:t", ns)))
                    elem.clear()
    with archive.open(sheet) as stream:
        for _, row in ET.iterparse(stream, events=("end",)):
            if not row.tag.endswith("}row"):
                continue
            values = {}
            for cell in row.findall("m:c", ns):
                ref = re.sub(r"[0-9]", "", cell.attrib["r"])
                value = cell.find("m:v", ns)
                text = "" if value is None else value.text or ""
                if cell.get("t") == "s":
                    text = shared[int(text)]
                elif cell.get("t") == "inlineStr":
                    text = "".join(t.text or "" for t in cell.findall(".//m:t", ns))
                values[ref] = text
            yield values
            row.clear()


TACO_COLUMNS = {
    "C": ("Umidade", "%"), "D": ("Energia", "kcal"), "E": ("Energia", "kJ"),
    "F": ("Proteína", "g"), "G": ("Lipídeos", "g"), "H": ("Colesterol", "mg"),
    "I": ("Carboidrato", "g"), "J": ("Fibra alimentar", "g"), "K": ("Cinzas", "g"),
    "L": ("Cálcio", "mg"), "M": ("Magnésio", "mg"), "O": ("Manganês", "mg"),
    "P": ("Fósforo", "mg"), "Q": ("Ferro", "mg"), "R": ("Sódio", "mg"),
    "S": ("Potássio", "mg"), "T": ("Cobre", "mg"), "U": ("Zinco", "mg"),
    "V": ("Retinol", "µg"), "W": ("RE", "µg"), "X": ("RAE", "µg"),
    "Y": ("Tiamina", "mg"), "Z": ("Riboflavina", "mg"), "AA": ("Piridoxina", "mg"),
    "AB": ("Niacina", "mg"), "AC": ("Vitamina C", "mg"),
}


def taco_foods(path, version="2011"):
    source = "AL-TACO"
    # The official XLSX has three source tables. Preserve fatty acids and amino
    # acids as additional original cells; the first table defines food identity.
    extras = {}
    with zipfile.ZipFile(path) as archive:
        for sheet in ("xl/worksheets/sheet2.xml", "xl/worksheets/sheet3.xml"):
            table_rows = iter(xlsx_rows(archive, sheet))
            headers = [next(table_rows, {}) for _ in range(3)]
            for row in table_rows:
                if not row.get("A", "").isdigit() or not row.get("B"):
                    continue
                cells = extras.setdefault(row["A"], [])
                for col, raw in row.items():
                    if col in ({"A", "B", "M"} if sheet.endswith("sheet2.xml") else {"A", "B", "L"}):
                        continue
                    header = " ".join(dict.fromkeys(h.get(col, "").strip() for h in headers if h.get(col, "").strip()))
                    if not header or header.lower().startswith("numero"):
                        continue
                    if sheet.endswith("sheet2.xml") and col == "C":
                        header = "Ácidos graxos saturados " + header
                    cells.append({"sourceColumnKey": source + ":" + sheet + ":" + col,
                                  "nameOriginal": header, "unit": "g", **parse_value(raw),
                                  "basisQuantity": "100", "basisUnit": "g",
                                  "methodId": "taco-2011:additional-source-table", "scalingAllowed": True})
        for row in xlsx_rows(archive, "xl/worksheets/sheet1.xml"):
            if not row.get("A", "").isdigit() or not row.get("B"):
                continue
            cells = [{"sourceColumnKey": source + ":composition:" + col,
                      "nameOriginal": label, "unit": unit, **parse_value(row.get(col)),
                      "basisQuantity": "100", "basisUnit": "g",
                      "methodId": "taco-2011:composition", "scalingAllowed": True}
                     for col, (label, unit) in TACO_COLUMNS.items()]
            cells.extend(extras.get(row["A"], []))
            yield make_food(source, row["A"], row["B"], "pt-BR", version,
                            {"quantity": "100", "unit": "g"}, cells,
                            provenance={"table": "TACO 4ª edição", "foodNumber": row["A"]})


OFF_COLUMNS = {
    "energy-kcal_100g": ("Energia", "kcal", "energy_kcal"),
    "proteins_100g": ("Proteína", "g", "protein_g"),
    "carbohydrates_100g": ("Carboidrato", "g", "carbohydrate_g"),
    "fat_100g": ("Gordura total", "g", "fat_g"),
    "fiber_100g": ("Fibra", "g", "fiber_g"),
    "sugars_100g": ("Açúcares", "g", "sugars_g"),
    "saturated-fat_100g": ("Ácidos graxos saturados", "g", "saturated_fat_g"),
    "sodium_100g": ("Sódio", "mg", "sodium_mg"),
    "calcium_100g": ("Cálcio", "mg", "calcium_mg"),
    "iron_100g": ("Ferro", "mg", "iron_mg"),
    "potassium_100g": ("Potássio", "mg", "potassium_mg"),
    "magnesium_100g": ("Magnésio", "mg", "magnesium_mg"),
    "cholesterol_100g": ("Colesterol", "mg", "cholesterol_mg"),
}


def off_foods(path, version, report=None):
    report = report if report is not None else Counter()
    opener = gzip.open if str(path).endswith(".gz") else open
    with opener(path, "rt", encoding="utf-8-sig", newline="") as stream:
        for row in csv.DictReader(stream, delimiter="\t"):
            report["inputRows"] += 1
            code, name = row.get("code", "").strip(), row.get("product_name", "").strip()
            if not code or not name:
                report["excludedMissingIdentityOrName"] += 1
                continue
            # OFF's _100g convention covers both 100 g and 100 ml. The CSV
            # omits nutrition_data_per; only an unambiguous metric label unit
            # supports scaling. Unknown/mixed units remain unknown, not density.
            quantity_label=row.get("quantity", "")
            serving_label=row.get("serving_size", "")
            volume=bool(re.search(r"\d\s*(ml|cl|dl|l)\b",quantity_label+" "+serving_label,re.I))
            mass=bool(re.search(r"\d\s*(g|kg)\b",quantity_label+" "+serving_label,re.I))
            basis_unit="ml" if volume and not mass else "g" if mass and not volume else None
            if basis_unit is None:report["unknownBasis"]+=1
            cells = []
            for col, raw in row.items():
                if not col.endswith("_100g") or raw in (None, ""):
                    continue
                mapped=OFF_COLUMNS.get(col)
                label,unit,key = mapped if mapped else (col[:-5],None,None)
                if mapped:unit="kcal" if key=="energy_kcal" else "g"
                elif col in {"energy-kj_100g", "energy_100g"}:unit="kJ"
                value = parse_value(raw)
                cells.append({"sourceColumnKey": "AL-OFF:" + col, "nameOriginal": label,
                              "unit": unit, "nutrientId": key, **value,
                              "basisQuantity": "100" if basis_unit else None,"basisUnit": basis_unit,
                              "methodId": "off:declared-label", "scalingAllowed": basis_unit is not None})
            ident = "food:" + hashlib.sha256(("AL-OFF\0" + code).encode()).hexdigest()
            portions = []
            label = row.get("serving_size", "").strip()
            # Only parse an explicit metric weight/volume; never a bare spoon.
            match = re.search(r"(?:^|[ (])([0-9]+(?:[.,][0-9]+)?)\s*(g|ml)\b", label, re.I)
            if match:
                p = portion(ident, label, match[1], match[2].lower(), "AL-OFF", "declared serving")
                if p:
                    portions.append(p)
            yield make_food("AL-OFF", code, name, row.get("lang", "") or "und", version,
                            {"quantity": "100" if basis_unit else None,"unit": basis_unit}, cells,
                            brand=row.get("brands", "").strip() or None, portions=portions,
                            barcodes=[code], provenance={"lastModified": row.get("last_modified_t"),
                                                       "countries": row.get("countries_tags", ""),
                                                       "dataQualityErrors": row.get("data_quality_errors_tags", ""),
                                                       "basisDeclaration": "OFF CSV _100g convention; metric label unit or unknown; no density conversion"})


def zip_csv(archive, basename):
    names = [name for name in archive.namelist() if name.rsplit("/", 1)[-1] == basename]
    if len(names) != 1:
        raise ValueError("USDA archive requires exactly one " + basename)
    return io.TextIOWrapper(archive.open(names[0]), encoding="utf-8-sig", newline="")


USDA_NUTRIENTS = {
    "1008": "energy_kcal", "2048": "energy_kcal", "2047": "energy_kcal",
    "1003": "protein_g", "1005": "carbohydrate_g", "1004": "fat_g",
    "1079": "fiber_g", "2000": "sugars_g", "1063": "sugars_g",
    "1258": "saturated_fat_g", "1093": "sodium_mg", "1253": "cholesterol_mg",
    "1087": "calcium_mg", "1089": "iron_mg", "1092": "potassium_mg",
    "1090": "magnesium_mg", "1091": "phosphorus_mg", "1095": "zinc_mg",
    "1098": "copper_mg", "1101": "manganese_mg", "1162": "vitamin_c_mg",
    "1165": "thiamin_mg", "1166": "riboflavin_mg", "1167": "niacin_mg",
    "1175": "vitamin_b6_mg", "1178": "vitamin_b12_ug", "1114": "vitamin_d_ug",
}


def usda_foods(path, staging, version="2026-10-29", report=None):
    """Join the complete CSV archive on disk, not in a Python object graph."""
    report = report if report is not None else Counter()
    stage = sqlite3.connect(staging)
    stage.executescript("PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF; PRAGMA temp_store=FILE; PRAGMA cache_size=-131072;"
                       "CREATE TABLE food(id INTEGER PRIMARY KEY,kind TEXT,name TEXT,publication TEXT);"
                       "CREATE TABLE cell(food INTEGER,nutrient TEXT,amount TEXT);"
                       "CREATE TABLE serving(food INTEGER,label TEXT,weight TEXT);"
                       "CREATE TABLE brand(food INTEGER PRIMARY KEY,brand TEXT,code TEXT,label TEXT,amount TEXT,unit TEXT);"
                       "CREATE TABLE nd(id TEXT PRIMARY KEY,name TEXT,unit TEXT);")
    try:
        with zipfile.ZipFile(path) as archive:
            measure_units={}
            with zip_csv(archive,"measure_unit.csv") as stream:
                for row in csv.DictReader(stream):
                    measure_units[row["id"]]=row.get("name","")

            def serving_row(row):
                description=row.get("portion_description") or row.get("modifier") or measure_units.get(row.get("measure_unit_id"),"") or "Source portion"
                amount=decimal_text(row.get("amount"))
                label=((amount+" ") if amount and amount!="1" else "")+description
                return row["fdc_id"],label,row.get("gram_weight")

            with zip_csv(archive, "nutrient.csv") as stream:
                stage.executemany("INSERT INTO nd VALUES(?,?,?)", ((r["id"], r["name"], r["unit_name"])
                                  for r in csv.DictReader(stream)))
            stage.commit()
            for table, sql, convert in [
                ("food.csv", "INSERT INTO food VALUES(?,?,?,?)", lambda r: (r["fdc_id"],r["data_type"],r["description"],r.get("publication_date",""))),
                ("food_nutrient.csv", "INSERT INTO cell VALUES(?,?,?)", lambda r: (r["fdc_id"],r["nutrient_id"],r.get("amount"))),
                ("food_portion.csv", "INSERT INTO serving VALUES(?,?,?)", serving_row),
                ("branded_food.csv", "INSERT OR REPLACE INTO brand VALUES(?,?,?,?,?,?)", lambda r: (r["fdc_id"],r.get("brand_owner") or r.get("brand_name"),r.get("gtin_upc"),r.get("household_serving_fulltext"),r.get("serving_size"),r.get("serving_size_unit"))),
            ]:
                with zip_csv(archive, table) as stream:
                    batch = []
                    for row in csv.DictReader(stream):
                        batch.append(convert(row))
                        if len(batch) >= 10000:
                            stage.executemany(sql,batch);stage.commit();batch.clear()
                    if batch:
                        stage.executemany(sql,batch);stage.commit()
            stage.executescript("CREATE INDEX cell_food ON cell(food);CREATE INDEX serving_food ON serving(food);")
            nutrient_defs = {row[0]: (row[1], row[2]) for row in stage.execute("SELECT * FROM nd")}
            for fdc_id, kind, name, published in stage.execute("SELECT * FROM food ORDER BY id"):
                report["inputRows"] += 1
                if not name:
                    report["excludedMissingName"] += 1
                    continue
                source = "AL-USDA-" + {"foundation_food": "FOUNDATION", "sr_legacy_food": "SR-LEGACY",
                    "survey_fndds_food": "FNDDS", "branded_food": "BRANDED", "experimental_food": "EXPERIMENTAL"}.get(kind, kind.upper())
                ident = "food:" + hashlib.sha256((source + "\0" + str(fdc_id)).encode()).hexdigest()
                cells = []
                for nd, amount in stage.execute("SELECT nutrient,amount FROM cell WHERE food=? ORDER BY CAST(nutrient AS INTEGER)",(fdc_id,)):
                    label, unit = nutrient_defs[nd]
                    unit = unit.replace("UG", "µg").replace("MG", "mg").replace("KCAL", "kcal").replace("KJ", "kJ")
                    if unit == "G":unit="g"
                    cells.append({"sourceColumnKey": source+":nutrient:"+nd,"nameOriginal":label,"unit":unit,
                                  "nutrientId":USDA_NUTRIENTS.get(nd),**parse_value(amount),
                                  "basisQuantity":"100","basisUnit":"g","scalingAllowed":True,
                                  "methodId":"usda:nutrient:"+nd})
                portions=[]
                for label, weight in stage.execute("SELECT label,weight FROM serving WHERE food=?",(fdc_id,)):
                    p=portion(ident,label,weight,"g",source,"USDA documented portion")
                    if p:portions.append(p)
                brand=stage.execute("SELECT brand,code,label,amount,unit FROM brand WHERE food=?",(fdc_id,)).fetchone()
                if brand:
                    p=portion(ident,brand[2] or "Declared serving",brand[3],(brand[4] or "").lower(),source,"declared serving")
                    if p:portions.append(p)
                yield make_food(source,fdc_id,name,"en",version,{"quantity":"100","unit":"g"},cells,
                                brand=brand[0] if brand else None,portions=portions,
                                barcodes=[brand[1]] if brand and brand[1] else [],
                                provenance={"fdcDataType":kind,"publicationDate":published})
    finally:
        stage.close()


FOOD_COLUMNS=("food_id","version_id","source_id","source_food_id","source_version",
              "name_original","name_locale","basis_quantity","basis_unit","preparation",
              "brand","search_name","canonical_nutrients_json","original_nutrients_json","portions_json")
STORAGE_LAYOUT="row-key-external-fts/1"


def create_compact_schema(db, *, deferred_identity_index=False):
    """Same public SQL columns, integer internal links and external-content FTS."""
    identity="" if deferred_identity_index else ",UNIQUE(food_id,version_id)"
    db.executescript("""
      CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);
      CREATE TABLE sources(source_id TEXT PRIMARY KEY,name TEXT,publisher TEXT,url TEXT,license_label TEXT,license_url TEXT,attribution TEXT,version TEXT,conditions_json TEXT);
      CREATE TABLE foods(row_key INTEGER PRIMARY KEY,food_id TEXT,version_id TEXT,source_id TEXT,source_food_id TEXT,source_version TEXT,name_original TEXT,name_locale TEXT,basis_quantity TEXT,basis_unit TEXT,preparation TEXT,brand TEXT,search_name TEXT,canonical_nutrients_json TEXT,original_nutrients_json TEXT,portions_json TEXT"""+identity+""");
      CREATE TABLE nutrient_columns(column_id INTEGER PRIMARY KEY,source_column_key TEXT UNIQUE,source_id TEXT,name_original TEXT,unit TEXT,nutrient_id TEXT,method_id TEXT);
      CREATE TABLE barcode_links(food_row_key INTEGER NOT NULL REFERENCES foods(row_key),code TEXT NOT NULL,normalized_code TEXT NOT NULL,format TEXT,PRIMARY KEY(food_row_key,code)) WITHOUT ROWID;
      CREATE VIEW barcodes AS SELECT b.code,b.normalized_code,b.format,f.food_id,f.version_id FROM barcode_links b JOIN foods f ON f.row_key=b.food_row_key;
      CREATE VIRTUAL TABLE foods_fts USING fts4(food_id,version_id,search_name,content='foods',notindexed=food_id,notindexed=version_id);
    """)


class CatalogWriter:
    """Compact local projection plus per-source machine-readable exports."""
    def __init__(self, path, sources, exports=None, resume=False):
        self.path=Path(path);self.path.parent.mkdir(parents=True,exist_ok=True)
        self.db=sqlite3.connect(self.path)
        self.sources=sources;self.exports=Path(exports) if exports else None
        self.streams={};self.counts=Counter();self.columns={};self.digest=hashlib.sha256()
        if self.exports:self.exports.mkdir(parents=True,exist_ok=True)
        if resume:
            if self.db.execute("PRAGMA quick_check").fetchone()[0]!="ok":
                raise ValueError("Interrupted catalog failed SQLite integrity check")
            self.db.executescript("PRAGMA journal_mode=OFF;PRAGMA synchronous=OFF;PRAGMA cache_size=-131072;"
                                 "CREATE INDEX IF NOT EXISTS foods_source_identity ON foods(source_id,source_food_id);")
            self.columns=dict(self.db.execute("SELECT source_column_key,column_id FROM nutrient_columns"))
            self.counts.update(dict(self.db.execute("SELECT source_id,count(*) FROM foods GROUP BY source_id")))
            self.counts["foods"]=sum(self.counts.values())
            self.resumed=True
            self.compact_layout=any(r[1]=="row_key" for r in self.db.execute("PRAGMA table_info(foods)"))
            return
        self.resumed=False
        self.compact_layout=True
        self.db.executescript("""
          PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF; PRAGMA temp_store=FILE;
          PRAGMA cache_size=-131072; PRAGMA mmap_size=268435456;
        """)
        create_compact_schema(self.db)
        for source_id,s in sorted(sources.items()):
            self.db.execute("INSERT INTO sources VALUES(?,?,?,?,?,?,?,?,?)",(source_id,s["name"],s["publisher"],s["url"],s["licenseLabel"],s["licenseUrl"],s["attribution"],s["version"],canonical(s.get("conditions",[]))))

    def add(self,food):
        source=food["sourceId"]
        if source not in self.sources:raise ValueError("Source missing from registry: "+source)
        if not re.fullmatch(r"food:[a-f0-9]{64}",food["foodId"]) or not re.fullmatch(r"[a-f0-9]{64}",food["versionId"]):
            raise ValueError("Invalid stable identity")
        compact=[]
        for n in food["originalNutrients"]:
            key=n["sourceColumnKey"]
            if key not in self.columns:
                cursor=self.db.execute("INSERT INTO nutrient_columns(source_column_key,source_id,name_original,unit,nutrient_id,method_id) VALUES(?,?,?,?,?,?)",(key,source,n["nameOriginal"],n.get("unit"),n.get("nutrientId") or nutrient_id(n["nameOriginal"],n.get("unit")),n.get("methodId",source+":"+key)))
                self.columns[key]=cursor.lastrowid
            compact.append([self.columns[key],n["state"],n.get("value"),n.get("upperBound"),n.get("rawText",""),n.get("basisQuantity"),n.get("basisUnit"),n.get("scalingAllowed",False)])
        basis=food["basis"]
        search=folded(food["nameOriginal"]+" "+(food.get("brand") or ""))
        canonical_refs=[[self.columns[n["sourceColumnKey"]],n["primaryForTotals"],n.get("value"),n.get("upperBound")]
                        for n in food["canonicalNutrients"]]
        cursor=self.db.execute("INSERT INTO foods("+",".join(FOOD_COLUMNS)+") VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",(food["foodId"],food["versionId"],source,food["sourceFoodId"],food["sourcePublishedVersion"],food["nameOriginal"],food["nameLocale"],basis.get("quantity"),basis.get("unit"),food.get("preparation"),food.get("brand"),search,storage_json(canonical_refs),storage_json(compact),canonical(food["portions"])))
        food_row_key=cursor.lastrowid
        for code in food["barcodes"]:
            normalized=normalized_barcode(code)
            if normalized:
                barcode_format={8:"EAN-8",12:"UPC-A",13:"EAN-13",14:"GTIN-14"}[len(code)]
                if self.compact_layout:
                    self.db.execute("INSERT OR IGNORE INTO barcode_links VALUES(?,?,?,?)",(food_row_key,code,normalized,barcode_format))
                else:
                    self.db.execute("INSERT OR IGNORE INTO barcodes VALUES(?,?,?,?,?)",(code,normalized,barcode_format,food["foodId"],food["versionId"]))
            else:self.counts["invalidBarcodes"]+=1
        text=canonical(food)+"\n"
        self.digest.update(text.encode())
        if self.exports:
            if source not in self.streams:
                self.streams[source]=gzip.GzipFile(filename=str(self.exports/(source+".jsonl.gz")),mode="ab" if self.resumed else "wb",compresslevel=1,mtime=0)
            self.streams[source].write(text.encode())
        self.counts[source]+=1;self.counts["foods"]+=1
        if self.counts["foods"]%5000==0:self.db.commit()

    def finish(self):
        snapshot=hashlib.sha256(b"trainforge.food-catalog-snapshot/2\n")
        for food_id,version_id in self.db.execute("SELECT food_id,version_id FROM foods ORDER BY food_id,version_id"):
            snapshot.update((food_id+"\0"+version_id+"\n").encode())
        version=snapshot.hexdigest()
        for k,v in {"contract":CONTRACT,"schema_version":str(SCHEMA_VERSION),"version":version,"mapping_version":"canonical-nutrients/1","json_encoding":"zlib-base64-or-json/1","canonical_nutrients_encoding":"column-ref/1","nutrient_units":canonical(CANONICAL_UNITS)}.items():
            self.db.execute("INSERT OR REPLACE INTO metadata VALUES(?,?)",(k,v))
        if self.compact_layout:self.db.execute("INSERT OR REPLACE INTO metadata VALUES('storage_layout',?)",(STORAGE_LAYOUT,))
        self.db.commit()
        if self.compact_layout:
            self.db.executescript("CREATE INDEX IF NOT EXISTS foods_search ON foods(search_name);"
                                 "CREATE INDEX IF NOT EXISTS foods_source ON foods(source_id);"
                                 "DROP INDEX IF EXISTS foods_source_identity;"
                                 "CREATE INDEX IF NOT EXISTS barcodes_normalized ON barcode_links(normalized_code);"
                                 "INSERT INTO foods_fts(foods_fts) VALUES('rebuild');")
        else:
            self.db.executescript("CREATE INDEX IF NOT EXISTS foods_search ON foods(search_name);"
                                 "CREATE INDEX IF NOT EXISTS foods_source ON foods(source_id,food_id);"
                                 "CREATE INDEX IF NOT EXISTS barcodes_normalized ON barcodes(normalized_code);"
                                 "DELETE FROM foods_fts;"
                                 "INSERT INTO foods_fts SELECT food_id,version_id,search_name FROM foods;")
        self.db.execute("INSERT INTO foods_fts(foods_fts) VALUES('optimize')")
        self.db.commit()
        if self.db.execute("PRAGMA integrity_check").fetchone()[0]!="ok":raise ValueError("SQLite integrity check failed")
        self.db.close()
        for stream in self.streams.values():stream.close()
        return {"contract":CONTRACT,"schemaVersion":SCHEMA_VERSION,"version":version,
                "file":self.path.name,"sha256":sha_file(self.path),"bytes":self.path.stat().st_size,
                "counts":dict(sorted(self.counts.items())),
                **({"storageLayout":STORAGE_LAYOUT} if self.compact_layout else {}),
                "jsonEncoding":"zlib-base64-or-json/1",
                "canonicalNutrientsEncoding":"column-ref/1","nutrientUnits":CANONICAL_UNITS,
                "sources":[{**self.sources[k],"sourceId":k,"foods":self.counts[k]} for k in sorted(self.sources) if self.counts[k]],
                "originalNutrientsEncoding":["column_id","state","value","upperBound","rawText","basisQuantity","basisUnit","scalingAllowed"]}


def sign_manifest(payload, signing_dir, assets_dir):
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    signing_dir=Path(signing_dir);signing_dir.mkdir(parents=True,exist_ok=True)
    key_path=signing_dir/"catalog-ed25519.pem"
    if key_path.exists():
        key=serialization.load_pem_private_key(key_path.read_bytes(),password=None)
    else:
        key=Ed25519PrivateKey.generate()
        key_path.write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
        try:os.chmod(key_path,0o600)
        except OSError:pass
    public=key.public_key().public_bytes(serialization.Encoding.Raw,serialization.PublicFormat.Raw)
    key_id="trainforge-food-"+hashlib.sha256(public).hexdigest()[:16]
    message=canonical(payload).encode()
    envelope={"keyId":key_id,"payload":base64.b64encode(message).decode(),"signature":base64.b64encode(key.sign(message)).decode()}
    assets_dir=Path(assets_dir);assets_dir.mkdir(parents=True,exist_ok=True)
    (assets_dir/"manifest.json").write_text(canonical(envelope)+"\n",encoding="utf-8")
    (assets_dir/"trust.json").write_text(canonical({"contract":"trainforge.food-catalog-trust/1","keys":[{"keyId":key_id,"algorithm":"Ed25519","publicKey":base64.b64encode(public).decode()}]})+"\n",encoding="utf-8")
    return envelope


def verify_bundle(assets_dir):
    """Verify an actual signed complete catalog without network or writes."""
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    assets_dir=Path(assets_dir).resolve()
    envelope=json.loads((assets_dir/"manifest.json").read_text(encoding="utf-8"))
    trust=json.loads((assets_dir/"trust.json").read_text(encoding="utf-8"))
    if trust.get("contract")!="trainforge.food-catalog-trust/1":raise ValueError("Invalid catalog trust contract")
    keys=[k for k in trust["keys"] if k["keyId"]==envelope["keyId"] and k["algorithm"]=="Ed25519"]
    if len(keys)!=1:raise ValueError("Unknown catalog signing key")
    message=base64.b64decode(envelope["payload"],validate=True)
    Ed25519PublicKey.from_public_bytes(base64.b64decode(keys[0]["publicKey"],validate=True)).verify(base64.b64decode(envelope["signature"],validate=True),message)
    payload=json.loads(message)
    if payload.get("contract")!=CONTRACT or payload.get("schemaVersion")!=SCHEMA_VERSION:
        raise ValueError("Incompatible catalog contract")
    if payload.get("fixture") is not False or payload.get("complete") is not True or payload.get("missingSources"):
        raise ValueError("Catalog is a fixture or is incomplete")
    filename=payload["file"]
    if filename not in {"catalog.sqlite","catalog.sqlite.gz"}:raise ValueError("Unexpected catalog filename")
    target=assets_dir/filename
    if not target.is_file() or target.stat().st_size!=payload["bytes"] or sha_file(target)!=payload["sha256"]:
        raise ValueError("Catalog asset failed size/hash verification")
    if filename.endswith(".gz"):
        digest=hashlib.sha256();total=0;header=b""
        with gzip.open(target,"rb") as stream:
            for block in iter(lambda:stream.read(1024*1024),b""):
                if not header:header=block[:16]
                digest.update(block);total+=len(block)
                if total>payload["databaseBytes"]:raise ValueError("Catalog decompression exceeds signed size")
        if (header!=b"SQLite format 3\x00" or total!=payload["databaseBytes"]
                or digest.hexdigest()!=payload["databaseSha256"]):
            raise ValueError("Decompressed catalog failed signature-bound database verification")
        return {"contract":CONTRACT,"complete":True,"fixture":False,"version":payload["version"],
                "sha256":payload["sha256"],"bytes":payload["bytes"],"databaseSha256":payload["databaseSha256"],
                "databaseBytes":payload["databaseBytes"],"counts":payload["counts"],"sourceCount":len(payload["sources"])}
    db=sqlite3.connect(target.as_uri()+"?mode=ro",uri=True)
    try:
        metadata=dict(db.execute("SELECT key,value FROM metadata"))
        if metadata.get("contract")!=CONTRACT or metadata.get("version")!=payload["version"]:
            raise ValueError("Catalog SQLite metadata mismatch")
        counts=dict(db.execute("SELECT source_id,count(*) FROM foods GROUP BY source_id"))
        if sum(counts.values())!=payload["counts"]["foods"]:raise ValueError("Catalog coverage mismatch")
        for source,count in counts.items():
            if payload["counts"].get(source)!=count:raise ValueError("Source coverage mismatch")
        if db.execute("PRAGMA quick_check").fetchone()[0]!="ok":raise ValueError("Catalog SQLite integrity failed")
    finally:db.close()
    return {"contract":CONTRACT,"complete":True,"fixture":False,"version":payload["version"],"sha256":payload["sha256"],"bytes":payload["bytes"],"counts":payload["counts"],"sourceCount":len(counts)}
