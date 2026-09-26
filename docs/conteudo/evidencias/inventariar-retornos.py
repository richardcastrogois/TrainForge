"""Indice pequeno das chamadas de pesquisa preservadas. Somente leitura local.

Nao e contrato garantido de fornecedor; nao exporta os corpos de resposta.
Distancia hash do corpo HTTP original e hash do artefato local serializado.
"""
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
OUTPUT = HERE / "retornos-observados.json"
ROOTS = [REPO / "docs/planejamento/evidencias", HERE]


def walk_records():
    for root in ROOTS:
        for path in sorted(root.rglob("*.json")):
            if "raw" in path.parts or path == OUTPUT:
                continue
            value = json.loads(path.read_text(encoding="utf-8-sig"))
            if isinstance(value, dict) and value.get("url") and "status" in value:
                yield path, value


def inspect(path, record):
    uri = urlparse(record["url"])
    if uri.scheme != "https":
        raise ValueError("Unexpected source scheme")
    item = {
        "evidenceFile": path.relative_to(REPO).as_posix(),
        "artifactSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "request": {"method": record.get("method", "GET"), "url": record["url"], "methodBasis": "record" if record.get("method") else "Invoke-WebRequest GET client record"},
        "collectedAtUtc": record.get("collectedAtUtc"),
        "httpStatus": record["status"], "responseBytes": record.get("bytes"),
        "originalResponseSha256": record.get("sha256"),
    }
    if record.get("error"):
        item["error"] = record["error"]
    if record.get("requestHeaders"):
        item["request"]["configuredHeaders"] = record["requestHeaders"]
    if "data" in record:
        body = record["data"]
        item["bodyStorage"] = "data property of evidenceFile; this wrapper was created by the research collector"
        item["bodyKind"] = "array" if isinstance(body, list) else "object"
        if isinstance(body, dict):
            item["observedRootKeys"] = list(body)
        if isinstance(body, list):
            item["observedItems"] = len(body)
        for key in ("foods", "results", "foodPortions"):
            if isinstance(body, dict) and isinstance(body.get(key), list):
                item.setdefault("observedArraySizes", {})[key] = len(body[key])
        # Original bytes were parsed and reserialized in these old collectors.
        item["originalBodyHashRecheckable"] = False
    elif record.get("bodyFile"):
        body_path = path.parent / record["bodyFile"]
        item["bodyFile"] = body_path.relative_to(REPO).as_posix()
        item["bodyAvailableLocally"] = body_path.is_file()
        if body_path.is_file():
            measured = hashlib.sha256(body_path.read_bytes()).hexdigest()
            item["originalBodyHashRecheckable"] = True
            item["originalBodyHashMatches"] = measured == record["sha256"]
            if not item["originalBodyHashMatches"]:
                raise ValueError("Body hash mismatch: " + str(body_path))
    elif record.get("sample"):
        item["bodyStorage"] = "HTML was reduced by the collector; original HTML is not saved"
        item["observedItems"] = len(record["sample"])
        item["locallyExtractedFields"] = list(record["sample"][0])
        item["originalBodyHashRecheckable"] = False
    return item


if __name__ == "__main__":
    rows = [inspect(path, record) for path, record in walk_records()]
    output = {
        "schemaVersion": 1, "scope": "Observed research calls; no network; raw data remains local where excluded from Git.",
        "httpHeaders": "Configured request headers are retained where recorded; otherwise see collector version and integration dossier. Not a network packet capture.",
        "records": rows,
    }
    OUTPUT.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"calls": len(rows), "success200": sum(x["httpStatus"] == 200 for x in rows), "bodyHashesVerified": sum(x.get("originalBodyHashMatches", False) for x in rows), "output": OUTPUT.relative_to(REPO).as_posix()}))
