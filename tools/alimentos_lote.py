"""Preflight alimentar offline. Candidato técnico, sem autorização de importação."""
from __future__ import annotations

from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation
import hashlib
import json
import math
from pathlib import Path
import re

SOURCE_FAMILIES = {"AL-CIQUAL-2025": "AL04", "AL-COFID-2021": "AL05"}
CONTRACT = "trainforge.food-staging/1"
NUMERIC_STATES = {"numeric", "less_than", "missing", "trace", "present_quantity_unknown", "unparsed"}


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)


def digest(path):
    result = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def local_input(root, relative):
    if not isinstance(relative, str) or Path(relative).is_absolute() or re.match(r"^[A-Za-z]:", relative):
        raise ValueError("Caminho de insumo deve ser relativo ao clone")
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError("Insumo fora do clone recusado")
    return path


def read_json(path):
    def reject_constant(_):
        raise ValueError("JSON não finito recusado")
    return json.loads(Path(path).read_text(encoding="utf-8-sig"), parse_constant=reject_constant)


def rows(path):
    with Path(path).open(encoding="utf-8-sig") as stream:
        for line in stream:
            if line.strip():
                def reject_constant(_):
                    raise ValueError("JSON não finito recusado")
                yield json.loads(line, parse_constant=reject_constant)


def cell_value(cell):
    """Preserve raw meaning and verify the previous parser using exact decimals."""
    raw = cell.get("raw")
    if raw is not None and type(raw) not in (str, int, float):
        raise ValueError("Célula de origem deve ser escalar")
    token = "" if raw is None else str(raw).strip()
    state, value, bound = "missing", None, None
    if token not in {"", "-"}:
        if token.lower() in {"tr", "trace", "traces"}:
            state = "trace"
        elif token.upper() == "N":
            state = "present_quantity_unknown"
        else:
            is_bound = token.startswith("<")
            number = token[1:].strip() if is_bound else token
            try:
                decimal = Decimal(number.replace(",", "."))
                if not decimal.is_finite() or decimal < 0:
                    raise InvalidOperation
                state = "less_than" if is_bound else "numeric"
                if is_bound:
                    bound = str(decimal)
                else:
                    value = str(decimal)
            except InvalidOperation:
                state = "unparsed"
    if cell.get("state") not in NUMERIC_STATES or state != cell["state"]:
        raise ValueError("Estado numérico diverge do valor original")
    for field, expected in (("value", value), ("upperBound", bound)):
        actual = cell.get(field)
        if expected is None:
            if actual is not None:
                raise ValueError("Marcador/ausência não pode virar número")
        else:
            if isinstance(actual, bool) or actual is None:
                raise ValueError("Número original ausente/inválido")
            try:
                if Decimal(str(actual)) != Decimal(expected):
                    raise ValueError("Valor preparado diverge do original")
            except InvalidOperation:
                raise ValueError("Número não finito recusado") from None
    return {"state": state, "valueDecimal": value, "upperBoundDecimal": bound, "raw": raw}


def column_contract(source_id, sheet, column):
    header = column["header"]
    compact = " ".join(header.split())
    factor = sheet == "1.2 Factors" or compact == "Facteur de Jones"
    match = re.search(r"\((g|mg|µg|μg|kcal|kJ)(?:\s+100\s+g)?\)\s*$", compact)
    unit = match.group(1).replace("μ", "µ") if match else None
    # Per-column FA denominators also exist inside the Proximates sheet.
    fatty_acids = bool(re.search(r"/\s*100\s*g?\s*FA\b", compact, re.I))
    food = bool(re.search(r"/\s*100\s*g\s*(?:food|fd)\b", compact, re.I))
    declared = {"quantity": 100, "unit": "g", "kind": "fatty_acids" if fatty_acids else "food"} if fatty_acids or food else None
    return {"id": f"{source_id}:{sheet}:{column['column']}", "column": column["column"],
            "headerOriginal": header, "unit": unit, "kind": "factor" if factor else "nutrient",
            "columnBasisDeclaration": declared}


def identity(row):
    values = [row.get(k) for k in ("sourceId", "sourceVersion", "sourceFoodId", "nameOriginal")]
    if any(not isinstance(v, str) or not v.strip() for v in values):
        raise ValueError("Identidade/nome de origem incompletos")
    return tuple(values)


def index_rows(path, source_id, expected_version, columns_by_table):
    """First pass identifies code collisions before considering any matching row."""
    by_code, row_hashes = defaultdict(set), {}
    identities, unique_tables = set(), Counter()
    input_rows, duplicates = 0, 0
    for row in rows(path):
        ident = identity(row)
        if ident[0] != source_id or ident[1] != expected_version:
            raise ValueError("Fonte/versão divergente no insumo")
        if row.get("calculationsApproved") is not False or row.get("runtimeImportApproved") is not False:
            raise ValueError("Este pipeline aceita somente candidatos não aprovados")
        sheet, number = row.get("sheet"), row.get("row")
        if sheet not in columns_by_table or type(number) is not int or number < 1:
            raise ValueError("Tabela/linha de origem inválida")
        key = f"{source_id}:{sheet}:{number}"
        if row.get("sourceRowKey") != key:
            raise ValueError("Chave da linha não corresponde à origem")
        fingerprint = hashlib.sha256(canonical(row).encode()).hexdigest()
        input_rows += 1
        if key in row_hashes:
            if row_hashes[key] != fingerprint:
                raise ValueError("Mesma linha de origem tem conteúdos divergentes")
            duplicates += 1
            continue
        row_hashes[key] = fingerprint
        unique_tables[sheet] += 1
        by_code[ident[2]].add(ident[3])
        identities.add(ident)
    conflicts = {code: names for code, names in by_code.items() if len(names) > 1}
    return {"byCode": by_code, "rowHashes": row_hashes, "identities": identities,
            "tables": unique_tables, "inputRows": input_rows, "duplicates": duplicates, "conflicts": conflicts}


def normalize_row(row, columns, conflict):
    ident = identity(row)
    expected_columns = {column["column"] for column in columns}
    values = row.get("values")
    if not isinstance(values, list) or any(not isinstance(v, dict) or type(v.get("column")) is not int for v in values):
        raise ValueError("Valores de composição inválidos")
    if len(values) != len(expected_columns) or {v["column"] for v in values} != expected_columns:
        raise ValueError("Coluna ausente/duplicada/inesperada")
    basis = row.get("quantityBasis")
    if not isinstance(basis, dict) or basis.get("kind") not in {"food", "factor", "fatty_acids", "food_or_alcohol_exception"}:
        raise ValueError("Base de composição inválida")
    if basis["kind"] in {"food", "fatty_acids"}:
        if type(basis.get("quantity")) not in (int, float) or not math.isfinite(basis["quantity"]) or basis["quantity"] <= 0 or basis.get("unit") not in {"g", "ml"}:
            raise ValueError("Base explícita sem quantidade/unidade válida")
    elif basis["kind"] == "food_or_alcohol_exception":
        if basis.get("quantity") != 100 or basis.get("unit") is not None:
            raise ValueError("Exceção alcoólica não resolvida não pode ganhar unidade")
    elif basis.get("quantity") is not None or basis.get("unit") is not None:
        raise ValueError("Fator não pode adquirir base de alimento")
    contracts = {c["column"]: c for c in columns}
    normalized = []
    for cell in sorted(values, key=lambda v: v["column"]):
        descriptor = contracts[cell["column"]]
        parsed = cell_value(cell)
        reasons = []
        if conflict:
            reasons.append("source_code_conflict")
        if descriptor["kind"] == "factor":
            reasons.append("factor_is_not_food_nutrient")
        if basis["kind"] == "fatty_acids" or (descriptor["columnBasisDeclaration"] or {}).get("kind") == "fatty_acids":
            reasons.append("basis_is_fatty_acids_not_food")
        elif basis["kind"] != "food":
            reasons.append("food_basis_unresolved")
        if descriptor["unit"] is None:
            reasons.append("nutrient_unit_unresolved")
        if parsed["state"] != "numeric":
            reasons.append("no_exact_numeric_quantity")
        normalized.append({"columnId": descriptor["id"], **parsed,
                           "technicalCalculationCandidate": not reasons, "blockingReasons": reasons})
    return {"contract": CONTRACT, "candidateIdentity": "food:" + hashlib.sha256(canonical(ident).encode()).hexdigest(),
            "sourceId": ident[0], "sourceVersion": ident[1], "sourceFoodId": ident[2],
            "nameOriginal": ident[3], "nameLocale": row.get("nameLocale"), "namePt": None,
            "preparation": None, "preparationRule": "Preserved in original name; not inferred",
            "sourceRowKey": row["sourceRowKey"], "sheet": row["sheet"], "row": row["row"],
            "sourceCodeConflict": conflict, "quantityBasis": basis,
            "measurements": normalized, "runtimeImportApproved": False, "calculationsApproved": False}


def analyze_source(root, source, emit=None):
    source_id = source["sourceId"]
    if source_id not in SOURCE_FAMILIES:
        raise ValueError("Sem adaptador para esta fonte")
    inputs = []
    for path_key, hash_key in (("path", "sha256"), ("sourceFile", "sourceSha256"), ("receipt", "receiptSha256")):
        path = local_input(root, source[path_key])
        expected = source[hash_key]
        if not re.fullmatch(r"[a-f0-9]{64}", expected) or digest(path) != expected:
            raise ValueError("Hash do insumo alimentar diverge: " + source[path_key])
        inputs.append({"path": source[path_key], "sha256": expected})
    receipt = read_json(local_input(root, source["receipt"]))
    if receipt.get("status") != 200 or receipt.get("sha256") != source["sourceSha256"]:
        raise ValueError("Recibo não comprova o arquivo original")
    tables = source["columnsByTable"]
    if not isinstance(tables, dict) or not tables or len(tables) != source["tables"]:
        raise ValueError("Cobertura de tabelas/cabeçalhos inválida")
    contracts = {}
    for sheet, descriptors in tables.items():
        if not isinstance(descriptors, list) or any(type(d.get("column")) is not int or not isinstance(d.get("header"), str) for d in descriptors):
            raise ValueError("Cabeçalho inválido")
        if len({d["column"] for d in descriptors}) != len(descriptors):
            raise ValueError("Cabeçalho com coluna duplicada")
        contracts[sheet] = [column_contract(source_id, sheet, d) for d in descriptors]
    path = local_input(root, source["path"])
    version = "2025" if source_id == "AL-CIQUAL-2025" else "2021"
    index = index_rows(path, source_id, version, tables)
    if set(index["tables"]) != set(tables):
        raise ValueError("Tabela preparada ausente no snapshot")
    if index["inputRows"] != source["tableRecords"] or len(index["identities"]) != source["uniqueFoods"] or len(index["byCode"]) != source["uniqueSourceCodes"]:
        raise ValueError("Cobertura de linhas/identidades diverge do preparo auditado")
    descriptors_by_id = {c["id"]: c for cs in contracts.values() for c in cs}
    states, classifications, blocked, seen, output_digest = Counter(), Counter(), Counter(), set(), hashlib.sha256()
    cells, eligible = 0, 0
    for row in rows(path):
        if row["sourceRowKey"] in seen:
            continue
        seen.add(row["sourceRowKey"])
        conflict = row["sourceFoodId"] in index["conflicts"] or row.get("sourceCodeConflict") is True
        normalized = normalize_row(row, contracts[row["sheet"]], conflict)
        for cell in normalized["measurements"]:
            states[cell["state"]] += 1
            descriptor = descriptors_by_id[cell["columnId"]]
            classifications[descriptor["kind"]] += 1
            blocked.update(cell["blockingReasons"])
            cells += 1
            eligible += cell["technicalCalculationCandidate"]
        line = canonical(normalized) + "\n"
        output_digest.update(line.encode())
        if emit:
            emit(line)
    if index["duplicates"] == 0 and dict(states) != source["valueStates"]:
        raise ValueError("Estados das células divergem da auditoria")
    # Refuse a file concurrently changed between fingerprint/index/normalization.
    if digest(path) != source["sha256"]:
        raise ValueError("Insumo mudou durante a leitura")
    return {"sourceId": source_id, "familyId": SOURCE_FAMILIES[source_id], "version": version,
            "inputs": inputs, "inputRows": index["inputRows"], "normalizedRows": len(seen),
            "exactDuplicateRows": index["duplicates"], "sourceIdentities": len(index["identities"]),
            "uniqueSourceCodes": len(index["byCode"]), "conflictingSourceCodes": len(index["conflicts"]),
            "conflictingIdentities": sum(len(names) for names in index["conflicts"].values()),
            "tableRows": dict(sorted(index["tables"].items())), "cells": cells,
            "valueStates": dict(sorted(states.items())), "measurementKinds": dict(sorted(classifications.items())),
            "technicalNumericCandidates": eligible, "blockingReasonCounts": dict(sorted(blocked.items())),
            "normalizedSha256": output_digest.hexdigest(), "columnsByTable": contracts,
            "creditsFromPreparedSnapshot": source["credits"], "reviewState": "pending",
            "runtimeImportApproved": False, "calculationsApproved": False}
