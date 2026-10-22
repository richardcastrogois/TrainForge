"""Project reviewed food snapshots into a versioned local import artifact, never a diet."""
from __future__ import annotations

from collections import Counter, defaultdict
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

from alimentos_lote import canonical, digest, identity, local_input, normalize_row, read_json
from preparar_alimentos_v1 import ROOT, PREPARED, check as check_preflight

DECISIONS = "content/manifests/food-review-decisions.json"
MANIFEST = "content/manifests/food-approved.json"
OUTPUT = "content/local/food-approved-v1.jsonl"
REPORT = "docs/execucao/v1/food-review-verification.json"
OPERATIONS = ["food_catalog", "food_composition", "food_quantity_scale"]


def source_basis(source_id, row, group_policy):
    original = row["quantityBasis"]
    if source_id == "AL-CIQUAL-2025":
        if original["kind"] != "food" or original["quantity"] != 100 or original["unit"] != "g":
            raise ValueError("Base Ciqual diverge da versão revisada")
        return {"quantity": "100", "unit": "g"}, None
    context = row.get("sourceContext")
    if not isinstance(context, list) or len(context) < 4:
        raise ValueError("Grupo CoFID sem proveniência")
    group = context[3]
    if group not in group_policy["knownGroups"]:
        return {"quantity": None, "unit": None}, group
    return {"quantity": "100", "unit": "ml" if group in group_policy["alcoholGroups"] else "g"}, group


def project_food(source_id, original_rows, columns, policy, review_sha):
    first = original_rows[0]
    ident = identity(first)
    if any(identity(r) != ident for r in original_rows):
        raise ValueError("Tentativa de misturar nome/preparo/fonte na mesma identidade")
    basis, group = source_basis(source_id, first, policy["cofidGroupPolicy"])
    rights = next(s for s in policy["sources"] if s["sourceId"] == source_id)
    if ident[0] != source_id or ident[1] != rights["sourceVersion"]:
        raise ValueError("Fonte/versão não corresponde à revisão")
    nutrients, references = [], []
    excluded = Counter()
    groups = set()
    for row in sorted(original_rows, key=lambda r: r["sourceRowKey"]):
        _, current_group = source_basis(source_id, row, policy["cofidGroupPolicy"])
        groups.add(current_group)
        descriptors = columns[row["sheet"]]
        by_id = {c["id"]: c for c in descriptors}
        normalized = normalize_row(row, descriptors, False)
        references.append(row["sourceRowKey"])
        for measurement in normalized["measurements"]:
            descriptor = by_id[measurement["columnId"]]
            declared = descriptor["columnBasisDeclaration"]
            if descriptor["kind"] == "factor":
                excluded["factor"] += 1
                continue
            if row["quantityBasis"]["kind"] == "fatty_acids" or (declared or {}).get("kind") == "fatty_acids":
                excluded["fatty_acids_basis"] += 1
                continue
            reasons = []
            effective = dict(basis)
            if effective["unit"] is None:
                reasons.append("food_basis_unresolved")
            elif effective["unit"] == "ml" and (
                (declared or {}).get("kind") == "food" or row["quantityBasis"]["kind"] == "food"):
                # A column/table explicitly labelled 100g food must not silently become 100ml.
                effective = {"quantity": None, "unit": None}
                reasons.append("source_basis_declarations_conflict")
            if not descriptor["unit"]:
                reasons.append("nutrient_unit_unresolved")
            if measurement["state"] != "numeric":
                reasons.append("no_exact_numeric_quantity")
            nutrients.append({"sourceColumnKey": descriptor["id"], "sourceRowKey": row["sourceRowKey"],
                              "nameOriginal": descriptor["headerOriginal"], "unit": descriptor["unit"],
                              "state": measurement["state"], "value": measurement["valueDecimal"],
                              "upperBound": measurement["upperBoundDecimal"], "raw": measurement["raw"],
                              "basisQuantity": effective["quantity"], "basisUnit": effective["unit"],
                              "declaredColumnBasis": declared, "scalingAllowed": not reasons,
                              "reasons": reasons})
    if len(groups) != 1:
        raise ValueError("Grupo diverge entre tabelas da mesma identidade")
    nutrients.sort(key=lambda n: n["sourceColumnKey"])
    allowed = OPERATIONS[:2]
    if any(n["scalingAllowed"] for n in nutrients):
        allowed = OPERATIONS[:]
    return {"schemaVersion": "1.0.0",
            "foodId": "food:" + hashlib.sha256((source_id + "\0" + first["sourceFoodId"]).encode()).hexdigest(),
            "sourceId": source_id, "sourceFoodId": first["sourceFoodId"],
            "sourcePublishedVersion": first["sourceVersion"], "nameOriginal": first["nameOriginal"],
            "nameLocale": first["nameLocale"], "namePt": None, "preparation": None, "basis": basis,
            "allowedOperations": allowed, "nutrients": nutrients,
            "provenance": {"reviewSha256": review_sha, "sourceSnapshotSha256": rights["snapshotSha256"],
                           "preparedSha256": rights["preparedSha256"], "sourceGroup": group,
                           "sourceRows": references, "auxiliaryCellsExcluded": dict(sorted(excluded.items())),
                           "rights": {k: rights[k] for k in ("name", "publisher", "sourceUrl", "licenseLabel",
                                      "licenseUrl", "attribution", "publishedAt", "changes", "warrantyNotice", "conditions")},
                           "preparationRule": "Preparo preservado no nome; campo separado não inferido",
                           "portionRule": "Somente base declarada g/ml; sem porção caseira ou densidade inferida",
                           "clinicalApproval": False}}


def review_policy(root, preflight):
    path = root / DECISIONS
    policy = read_json(path)
    if policy.get("contract") != "trainforge.food-review/1" or policy.get("stage") != "reviewed_source_operations" or policy.get("scope") != "isolated_development_food_consultation" or policy.get("clinicalApproval") is not False or not policy.get("reviewer"):
        raise ValueError("Revisão alimentar ausente/inválida")
    indexed = {s["sourceId"]: s for s in preflight["sources"]}
    if len(policy["sources"]) != len(indexed) or {s["sourceId"] for s in policy["sources"]} != set(indexed):
        raise ValueError("Cobertura da revisão diverge dos snapshots")
    for source in policy["sources"]:
        if not source.get("rightsVerified") or not source.get("fidelityChecked") or any(source["operations"].get(op) != "allowed" for op in OPERATIONS):
            raise ValueError("Fonte sem revisão/grants específicos")
        for key in ("licenseLabel", "licenseUrl", "sourceUrl", "attribution", "publishedAt", "changes", "warrantyNotice", "conditions"):
            if not source.get(key):
                raise ValueError("Atribuição/condições incompletas")
        evidence = indexed[source["sourceId"]]["inputs"]
        if source["preparedSha256"] != evidence[0]["sha256"] or source["snapshotSha256"] != evidence[1]["sha256"]:
            raise ValueError("Revisão não corresponde ao arquivo preparado")
    for evidence in policy["evidence"]:
        if digest(local_input(root, evidence["path"])) != evidence["sha256"]:
            raise ValueError("Evidência documental mudou")
    groups = policy["cofidGroupPolicy"]
    if len(groups["knownGroups"]) != len(set(groups["knownGroups"])) or not set(groups["alcoholGroups"]) <= set(groups["knownGroups"]):
        raise ValueError("Política de grupos inválida")
    return policy, digest(path)


def indexed_food_rows(path):
    positions, names = defaultdict(list), defaultdict(set)
    with path.open("rb") as stream:
        while True:
            offset = stream.tell()
            line = stream.readline()
            if not line:
                break
            if not line.strip():
                continue
            row = json.loads(line)
            ident = identity(row)
            positions[ident].append(offset)
            names[ident[2]].add(ident[3])
    return positions, {code for code, values in names.items() if len(values) > 1}


def atomic_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n", prefix="food-reviewed-",
                                         suffix=".tmp", dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(text)
        os.replace(temporary, path)
    finally:
        if temporary and temporary.exists():
            temporary.unlink()


def build(root=ROOT, write=False):
    preflight_path = root / "docs/execucao/v1/food-preflight-verification.json"
    preflight_sha = digest(preflight_path)
    preflight = check_preflight(root)
    policy, review_sha = review_policy(root, preflight)
    private_path = local_input(root, preflight["localManifest"]["path"])
    if digest(private_path) != preflight["localManifest"]["sha256"]:
        raise ValueError("Manifesto candidato mudou após checagem")
    private = read_json(private_path)
    prepared = read_json(root / PREPARED)
    source_contracts = {s["sourceId"]: s["columnsByTable"] for s in private["sources"]}
    output = root / OUTPUT
    if write:
        output.parent.mkdir(parents=True, exist_ok=True)
    handle = None
    temporary = None
    body_sha = hashlib.sha256()
    count, source_results, seen_ids = 0, [], set()
    try:
        if write:
            handle = tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                                                prefix="food-reviewed-", suffix=".tmp", dir=output.parent, delete=False)
            temporary = Path(handle.name)
        for source in sorted(prepared["food"], key=lambda s: s["sourceId"]):
            path = local_input(root, source["path"])
            positions, conflicts = indexed_food_rows(path)
            result = {"sourceId": source["sourceId"], "inputIdentities": len(positions), "importCandidates": 0,
                      "excludedCodeConflict": 0, "excludedConflictCells": 0, "unknownGroupIdentities": 0, "basisGrams": 0, "basisMillilitres": 0,
                      "nutrientCells": 0, "auxiliaryCellsExcluded": 0, "nutrientStates": {}, "scalingBlockedReasons": {}}
            states, blocks = Counter(), Counter()
            with path.open("rb") as stream:
                for ident in sorted(positions):
                    original = []
                    for offset in positions[ident]:
                        stream.seek(offset)
                        original.append(json.loads(stream.readline()))
                    if ident[2] in conflicts:
                        result["excludedCodeConflict"] += 1
                        result["excludedConflictCells"] += sum(len(r["values"]) for r in original)
                        continue
                    if len({r["sourceRowKey"] for r in original}) != len(original):
                        raise ValueError("Linha repetida no insumo revisado")
                    food = project_food(source["sourceId"], original, source_contracts[source["sourceId"]], policy, review_sha)
                    if food["foodId"] in seen_ids:
                        raise ValueError("Identidade editorial duplicada")
                    seen_ids.add(food["foodId"])
                    line = canonical(food) + "\n"
                    body_sha.update(line.encode())
                    if handle:
                        handle.write(line)
                    result["importCandidates"] += 1
                    result["unknownGroupIdentities"] += food["basis"]["unit"] is None
                    result["basisGrams"] += food["basis"]["unit"] == "g"
                    result["basisMillilitres"] += food["basis"]["unit"] == "ml"
                    result["nutrientCells"] += len(food["nutrients"])
                    result["auxiliaryCellsExcluded"] += sum(food["provenance"]["auxiliaryCellsExcluded"].values())
                    for nutrient in food["nutrients"]:
                        states[nutrient["state"]] += 1
                        blocks.update(nutrient["reasons"])
                    count += 1
            if digest(path) != source["sha256"]:
                raise ValueError("Arquivo preparado mudou durante projeção")
            expected_cells = next(s["cells"] for s in preflight["sources"] if s["sourceId"] == source["sourceId"])
            if result["nutrientCells"] + result["auxiliaryCellsExcluded"] + result["excludedConflictCells"] != expected_cells:
                raise ValueError("Células sem destino explícito na projeção")
            result["nutrientStates"] = dict(sorted(states.items()))
            result["scalingBlockedReasons"] = dict(sorted(blocks.items()))
            source_results.append(result)
        manifest = {"schemaVersion": "1.0.0", "stage": "approved_food_consultation_operations",
                    "importScope": "isolated_development_food_consultation", "bundleId": "TF-FOOD-20261022-v1",
                    "review": {"path": DECISIONS, "sha256": review_sha},
                    "preflight": {"path": "docs/execucao/v1/food-preflight-verification.json",
                                  "sha256": preflight_sha},
                    "output": {"path": OUTPUT, "sha256": body_sha.hexdigest(), "rows": count},
                    "sourceResults": source_results, "clinicalApproval": False}
        report = {"date": "2026-10-22", "scope": "reviewed-food-projection", "sources": source_results,
                  "outputSha256": body_sha.hexdigest(), "reviewSha256": review_sha, "approvedImportCandidates": count,
                  "databaseWrites": 0, "runtimeFoodsImported": 0, "clinicalApproval": False,
                  "otherFamilies": "Inventariadas no preflight, não aprovadas por herança destas duas fontes"}
        if digest(preflight_path) != preflight_sha or digest(private_path) != preflight["localManifest"]["sha256"]:
            raise ValueError("Preflight/cabeçalhos mudaram durante projeção")
        if digest(root / DECISIONS) != review_sha:
            raise ValueError("Decisão editorial mudou durante projeção")
        if handle:
            handle.close()
            handle = None
            if digest(temporary) != body_sha.hexdigest():
                raise ValueError("Artefato revisado diverge da projeção")
            os.replace(temporary, output)
            atomic_text(root / MANIFEST, json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
            atomic_text(root / REPORT, json.dumps(report, ensure_ascii=False, indent=2) + "\n")
        return manifest, report
    finally:
        if handle:
            handle.close()
        if temporary and temporary.exists():
            temporary.unlink()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    try:
        manifest, report = build(write=args.write)
        print(canonical({"scope": report["scope"], "approvedImportCandidates": report["approvedImportCandidates"],
                         "databaseWrites": 0, "outputSha256": report["outputSha256"]}))
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SystemExit("Projeção alimentar não concluída: " + str(error))
