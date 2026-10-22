"""Aplica decisoes documentais explicitas; nao faz rede, pratica ou importacao."""
from __future__ import annotations
import argparse
from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
from conteudo_editorial import authorize, validate_bundle

ROOT = Path(__file__).resolve().parents[1]
DECISIONS = "content/manifests/pilot-review-decisions.json"
TARGET = "content/local/editorial-v1-reviewed.json"
REPORT = "content/manifests/pilot-approved.json"
OPERATIONS = ("catalog_metadata", "instruction_text", "media_display", "guided_practice", "export_dataset")
LICENSES = {"https://creativecommons.org/licenses/by-sa/3.0/deed.en", "https://creativecommons.org/licenses/by-sa/4.0/deed.en"}


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))


def file_sha(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def review_bundle(candidate, decisions):
    if validate_bundle(candidate) or candidate.get("stage") != "candidate":
        raise ValueError("Lote candidato invalido")
    assets = {a["id"]: a for a in candidate["assets"]}
    approved_ids = {row["assetId"] for row in decisions["approvedOperations"]}
    if len(approved_ids) != len(decisions["approvedOperations"]):
        raise ValueError("Decisao duplicada")
    result = {k: copy.deepcopy(v) for k, v in candidate.items() if k != "assets"}
    result.update(stage="approved_operations", bundleId=candidate["bundleId"] + "-consultation", runtimeSeed=False,
                  useScope="Consulta documental: sem prescricao, execucao guiada ou distribuicao ja realizada", assets=[])
    for row in decisions["approvedOperations"]:
        original = assets.get(row["assetId"])
        if original is None or digest(original) != row["assetSha256"]:
            raise ValueError("Ativo alterado ou desconhecido: " + row["assetId"])
        if original["review"]["state"] == "blocked" or original["sourceId"] != "EX01":
            raise ValueError("Ativo fora do recorte revisado")
        if original["rights"]["licenseUrl"] not in LICENSES:
            raise ValueError("Licenca nao conferida")
        op = row["operation"]
        if original["kind"] == "instruction" and decisions.get("publicationPolicy", {}).get("professionalAuthorshipRequiredForTeaching") and not row.get("professionalAuthorshipEvidence"):
            raise ValueError("Autoria profissional do ensino nao comprovada")
        expected = "catalog_metadata" if original["kind"] == "movement" else "instruction_text" if original["kind"] == "instruction" else None
        if op != expected or not row.get("credits") or not row.get("conditions") or not decisions.get("reviewer"):
            raise ValueError("Operacao/credito/condicao/responsavel ausente")
        credit = row["credits"]
        if any(not credit.get(k) for k in ("title", "creators", "sourceUrl", "licenseUrl", "changes", "warrantyNotice")):
            raise ValueError("Credito incompleto")
        if credit["licenseUrl"] != original["rights"]["licenseUrl"]:
            raise ValueError("Licenca do credito diverge do objeto")
        a = copy.deepcopy(original)
        if a["kind"] == "movement":
            content = a["content"]
            content["sourceAvailability"] = {k:content[k] for k in ("instructionsAvailable", "imageReferencesAvailable", "videoReferencesAvailable")}
            if content.get("instructionRef") not in approved_ids:
                content["instructionRef"] = None
            content.update(instructionsAvailable=int(content.get("instructionRef") is not None), imageReferencesAvailable=0, videoReferencesAvailable=0,
                           availabilityScope="Somente ativos liberados para consulta neste lote; disponibilidade original separada")
        a["allowedOperations"] = [op]
        a["rights"]["operationGrants"] = {key:"allowed" if key == op else "unknown" for key in OPERATIONS}
        a["rights"].update(attribution="; ".join(credit["creators"]) + " via wger", displayCredits=credit, deliveryConditions=row["conditions"])
        a["review"].update(state="reviewed", reviewer=decisions["reviewer"], rightsVerified=True, fidelityChecked=True,
                           safetyUseReviewed=False, instructionSufficient=False,
                           reasons=["Revisao documental para consulta; requisitos de pratica e entrega no app pendentes"])
        result["assets"].append(a)
    errors = validate_bundle(result)
    if errors:
        raise ValueError("; ".join(errors[:5]))
    for a in result["assets"]:
        if authorize(result, a["id"], "guided_practice")[0] or authorize(result, a["id"], "export_dataset")[0]:
            raise ValueError("Pratica/exportacao inesperadamente liberada")
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if not args.write and not args.check:
        parser.error("Use --write ou --check")
    decisions = read(DECISIONS)
    if file_sha(decisions["sourceBundle"]["path"]) != decisions["sourceBundle"]["sha256"]:
        raise ValueError("Lote mudou; conferir decisoes antes de reconstruir")
    candidate = read(decisions["sourceBundle"]["path"])
    for source in candidate.get("inputs", []):
        if file_sha(source["path"]) != source["sha256"]:
            raise ValueError("Insumo da revisao alterado: " + source["path"])
    bundle = review_bundle(candidate, decisions)
    encoded = json.dumps(bundle, ensure_ascii=False, indent=2) + "\n"
    summary = {"schemaVersion":"1.0.0", "date":"2026-10-21", "stage":"approved_consultation_operations", "runtimeSeed":False,
               "importScope":"isolated_development_consultation", "publishScope":"delivery_conditions_not_yet_verified_in_app",
               "sourceBundle":decisions["sourceBundle"], "decisions":{"path":DECISIONS, "sha256":file_sha(DECISIONS)},
               "toolSha256":file_sha("tools/revisar_conteudo_local.py"),
               "output":{"path":TARGET, "sha256":hashlib.sha256(encoded.encode()).hexdigest()},
               "counts":dict(Counter(a["kind"] for a in bundle["assets"])), "practiceApproved":0, "mediaApproved":0,
               "sourceBodiesIncludedInThisManifest":False, "appDeliveryVerified":False, "reviewer":decisions["reviewer"],
               "rows":[{"assetId":a["id"], "sourceId":a["sourceId"], "allowedOperations":a["allowedOperations"], "evidence":a["evidence"],
                        "credits":a["rights"]["displayCredits"], "deliveryConditions":a["rights"]["deliveryConditions"]} for a in bundle["assets"]]}
    if args.write:
        (ROOT / TARGET).write_bytes(encoded.encode("utf-8"))
        (ROOT / REPORT).write_text(json.dumps(summary,ensure_ascii=False,indent=2)+"\n", encoding="utf-8")
    if args.check:
        if (ROOT / TARGET).read_text(encoding="utf-8") != encoded or read(REPORT) != summary:
            raise ValueError("Revisao/manifesto fora de sincronia")
        print(json.dumps({"result":"PASS", "counts":summary["counts"], "practiceApproved":0, "appDeliveryVerified":False}))


if __name__ == "__main__":
    main()
