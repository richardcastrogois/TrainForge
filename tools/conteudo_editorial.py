"""Contrato editorial local: estrutura, proveniencia e decisoes por operacao."""
from __future__ import annotations
import math

KINDS = {"movement", "instruction", "media", "program", "collection"}
UNITS = {"s", "min", "m", "km", "cm", "kg", "repetitions", "sets"}
OPERATIONS = {"catalog_metadata", "instruction_text", "media_display", "guided_practice", "export_dataset"}


def validate_bundle(bundle):
    errors = []
    if bundle.get("schemaVersion") != "1.0.0":
        errors.append("schemaVersion invalida")
    if bundle.get("stage") not in {"candidate", "approved_operations"}:
        errors.append("stage invalido")
    sources = {s.get("id") for s in bundle.get("sources", [])}
    if None in sources or len(sources) != len(bundle.get("sources", [])):
        errors.append("sourceId ausente ou duplicado")
    ids = set()
    for asset in bundle.get("assets", []):
        ident = asset.get("id")
        if not isinstance(ident, str) or not ident or ident in ids:
            errors.append("assetId ausente ou duplicado")
        ids.add(ident)
        if asset.get("kind") not in KINDS:
            errors.append(str(ident) + ": kind invalido")
        if asset.get("sourceId") not in sources:
            errors.append(str(ident) + ": fonte desconhecida")
        refs = asset.get("evidence", [])
        if not refs or any(not x.get("path") or not isinstance(x.get("pointer"), str) or len(x.get("snapshotSha256", "")) != 64 for x in refs):
            errors.append(str(ident) + ": proveniencia ausente")
        for key in ("authors", "rights", "audience", "dose", "content", "review", "allowedOperations"):
            if key not in asset:
                errors.append(str(ident) + ": campo ausente " + key)
        for key in ("sourceVersion", "locale", "title"):
            if asset.get(key) is not None and not isinstance(asset[key], str):
                errors.append(str(ident) + ": campo textual invalido " + key)
        for key in ("label", "licenseUrl", "attribution"):
            value = asset.get("rights", {}).get(key)
            if value is not None and not isinstance(value, str):
                errors.append(str(ident) + ": campo de direitos invalido " + key)
        if any(not isinstance(x, str) for x in asset.get("authors", [])):
            errors.append(str(ident) + ": autoria invalida")
        if not set(asset.get("allowedOperations", [])) <= OPERATIONS:
            errors.append(str(ident) + ": operacao desconhecida")
        if bundle.get("stage") == "candidate" and asset.get("allowedOperations"):
            errors.append(str(ident) + ": candidato nao pode autorizar operacao")
        for measure in asset.get("dose", {}).get("measurements", []):
            q = measure.get("quantity")
            if measure.get("unit") not in UNITS or not measure.get("sourceField"):
                errors.append(str(ident) + ": unidade/origem de dose invalida")
            if q is not None and (isinstance(q, bool) or not isinstance(q, (int, float)) or not math.isfinite(q) or q < 0):
                errors.append(str(ident) + ": quantidade invalida")
        if asset.get("kind") == "collection" and asset.get("content", {}).get("inheritsSourceEfficacy") is not False:
            errors.append(str(ident) + ": colecao nao herda eficacia")
    for asset in bundle.get("assets", []):
        content = asset.get("content", {})
        references = list(content.get("itemRefs", [])) + [content[k] for k in ("movementRef", "instructionRef") if content.get(k)]
        for ref in references:
            if ref not in ids:
                errors.append(asset["id"] + ": referencia editorial ausente " + ref)
    for asset in bundle.get("assets", []):
        for op in asset.get("allowedOperations", []):
            _, reasons = authorize(bundle, asset["id"], op)
            errors += [asset["id"] + ": " + reason for reason in reasons]
    return errors


def authorize(bundle, asset_id, operation, support_available=False):
    asset = next((x for x in bundle.get("assets", []) if x.get("id") == asset_id), None)
    if asset is None or operation not in OPERATIONS:
        return False, ["ativo/operacao desconhecido"]
    reasons = []
    applicable = {"instruction_text": {"instruction"}, "media_display": {"media"}, "guided_practice": {"movement", "program"}}
    if operation in applicable and asset.get("kind") not in applicable[operation]:
        reasons.append("operacao incompativel com o tipo do ativo")
    if asset.get("rights", {}).get("operationGrants", {}).get(operation) != "allowed":
        reasons.append("direito especifico da operacao nao confirmado")
    if bundle.get("stage") != "approved_operations":
        reasons.append("lote candidato, sem liberacao")
    if operation not in asset.get("allowedOperations", []):
        reasons.append("operacao fora da allowlist")
    if asset.get("review", {}).get("state") == "blocked":
        reasons.append("ativo bloqueado")
    review = asset.get("review", {})
    if review.get("state") != "reviewed":
        reasons.append("revisao ainda nao concluida")
    if not review.get("rightsVerified") or not review.get("fidelityChecked") or not review.get("reviewer"):
        reasons.append("direitos/fidelidade/responsavel pendentes")
    if operation in {"instruction_text", "media_display", "guided_practice"} and not asset.get("rights", {}).get("attribution"):
        reasons.append("atribuicao ausente")
    if operation == "guided_practice":
        if not review.get("safetyUseReviewed") or not review.get("instructionSufficient"):
            reasons.append("uso/instrucao pendente")
        required = asset.get("audience", {}).get("supportRequired")
        if required is None:
            reasons.append("apoio da fonte ainda desconhecido")
        elif required and not support_available:
            reasons.append("apoio exigido pela fonte indisponivel")
    return not reasons, reasons
