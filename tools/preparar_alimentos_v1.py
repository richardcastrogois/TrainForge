"""Validate existing food snapshots; never downloads, imports a DB or grants rights."""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import sys
import tempfile
from alimentos_lote import CONTRACT, SOURCE_FAMILIES, analyze_source, canonical, digest, local_input, read_json

ROOT = Path(__file__).resolve().parents[1]
PREPARED = "content/manifests/pilot-prepared.json"
CANDIDATES = "content/manifests/pilot-candidates.json"
REPORT = "docs/execucao/v1/food-preflight-verification.json"
LOCAL = "content/local"


def family_inventory(candidates):
    result = []
    for family in candidates["sourceFamilies"]:
        if family["topic"] != "alimentos":
            continue
        ident = family["sourceId"]
        state = "prepared_snapshot" if ident in SOURCE_FAMILIES.values() else (
            "dataset_not_prepared" if ident.startswith("AL") else "visual_method_or_tool_not_composition_dataset")
        if family["researchStatus"] == "incompativel_zero":
            state = "existing_rights_restriction"
        result.append({"familyId": ident, "name": family["name"], "state": state,
                       "catalogRef": family["catalogRef"], "catalogPointer": family["catalogPointer"],
                       "rightsReviewState": "pending", "runtimeImportApproved": False})
    return result


def analyze(root=ROOT, write=False):
    prepared = read_json(root / PREPARED)
    candidates = read_json(root / CANDIDATES)
    entries = prepared["food"]
    if {s["sourceId"] for s in entries} != set(SOURCE_FAMILIES) or len(entries) != len(SOURCE_FAMILIES):
        raise ValueError("Conjunto de snapshots mudou; adaptar explicitamente antes de processar")
    input_revision = [{"path": p, "sha256": digest(root / p)} for p in (PREPARED, CANDIDATES)]
    family_rows = family_inventory(candidates)
    families = {f["familyId"] for f in family_rows}
    if not set(SOURCE_FAMILIES.values()) <= families:
        raise ValueError("Família alimentar preparada não está no inventário")
    results, private_sources = [], []
    for source in sorted(entries, key=lambda s: s["sourceId"]):
        target = local_input(root, f"{LOCAL}/food-v1-{source['sourceId'].lower()}.staging.jsonl")
        temporary = None
        writer = None
        try:
            if write:
                target.parent.mkdir(parents=True, exist_ok=True)
                writer = tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", newline="\n",
                    prefix="food-v1-", suffix=".tmp", dir=target.parent, delete=False)
                temporary = Path(writer.name)
            result = analyze_source(root, source, writer.write if writer else None)
            if writer:
                writer.close()
                writer = None
                if digest(temporary) != result["normalizedSha256"]:
                    raise ValueError("Arquivo normalizado diverge do hash calculado")
                os.replace(temporary, target)
            private_sources.append(result)
            public = {key: value for key, value in result.items() if key not in {"columnsByTable", "creditsFromPreparedSnapshot"}}
            public["normalizedLocalPath"] = target.relative_to(root).as_posix()
            results.append(public)
        finally:
            if writer:
                writer.close()
            if temporary and temporary.exists() and temporary.is_relative_to((root / LOCAL).resolve()):
                temporary.unlink()
    for source in input_revision:
        if digest(root / source["path"]) != source["sha256"]:
            raise ValueError("Manifesto mudou durante processamento")
    report = {"contract": CONTRACT, "scope": "offline-food-staging-preflight",
              "story": "V1-019", "inputs": input_revision, "families": family_rows, "sources": results,
              "familyCount": len(family_rows), "preparedSources": len(results),
              "sourceIdentities": sum(s["sourceIdentities"] for s in results),
              "sourceTableRows": sum(s["inputRows"] for s in results),
              "compositionCellsPreserved": sum(s["cells"] for s in results),
              "runtimeFoodsImported": 0, "runtimeImportApproved": False, "calculationsApproved": False,
              "networkCalls": 0, "databaseWrites": 0,
              "limits": ["Rights review and source exceptions pending; no grant inferred from license names",
                         "Original language/preparation preserved; no Portuguese translation, portion or density invented",
                         "Technical candidate is not permission or nutritional/clinical validation",
                         "CoFID code collision and alcohol unit mapping remain unresolved",
                         "No search/register-consumption API or Flutter nutrition integration delivered"]}
    private_manifest = {"contract": CONTRACT, "stage": "candidate", "runtimeImportApproved": False,
                        "calculationsApproved": False, "inputs": input_revision, "sources": private_sources}
    manifest_text = json.dumps(private_manifest, ensure_ascii=False, indent=2) + "\n"
    import hashlib
    report["localManifest"] = {"path": LOCAL + "/food-v1-staging-manifest.json",
                               "sha256": hashlib.sha256(manifest_text.encode()).hexdigest()}
    if write:
        metadata = root / LOCAL / "food-v1-staging-manifest.json"
        metadata.write_text(manifest_text, encoding="utf-8", newline="\n")
        (root / REPORT).write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    return report


def check(root=ROOT):
    report = read_json(root / REPORT)
    if report.get("contract") != CONTRACT or report.get("runtimeImportApproved") is not False or report.get("calculationsApproved") is not False:
        raise ValueError("Relatório não é candidato técnico")
    metadata = local_input(root, report["localManifest"]["path"])
    if digest(metadata) != report["localManifest"]["sha256"]:
        raise ValueError("Manifesto local foi alterado; cabeçalhos/bases não conferidos")
    manifest = read_json(metadata)
    if manifest.get("stage") != "candidate" or manifest.get("contract") != CONTRACT or manifest.get("runtimeImportApproved") is not False or manifest.get("calculationsApproved") is not False:
        raise ValueError("Manifesto local não é candidato técnico")
    if manifest.get("inputs") != report["inputs"]:
        raise ValueError("Manifesto local e relatório não correspondem")
    private_sources = {s["sourceId"]: s for s in manifest["sources"]}
    if len(private_sources) != len(report["sources"]):
        raise ValueError("Fontes locais e relatório divergem")
    for source in report["inputs"]:
        if digest(local_input(root, source["path"])) != source["sha256"]:
            raise ValueError("Manifesto de entrada mudou; refazer preflight")
    for source in report["sources"]:
        if source["sourceId"] not in private_sources or source["normalizedSha256"] != private_sources[source["sourceId"]]["normalizedSha256"]:
            raise ValueError("Manifesto local diverge do relatório")
        for item in source["inputs"]:
            if digest(local_input(root, item["path"])) != item["sha256"]:
                raise ValueError("Snapshot de entrada mudou; não reutilizar staging")
        if digest(local_input(root, source["normalizedLocalPath"])) != source["normalizedSha256"]:
            raise ValueError("Staging local mudou; refazer preflight")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--write", action="store_true", help="Write ignored candidates and an aggregate verification receipt")
    group.add_argument("--check", action="store_true", help="Check all hashes against existing receipt; no recalculation/DB")
    args = parser.parse_args()
    try:
        report = check() if args.check else analyze(write=args.write)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("Preflight não concluído: " + str(error), file=sys.stderr)
        return 1
    print(canonical({key: report[key] for key in ("scope", "familyCount", "preparedSources",
          "sourceIdentities", "sourceTableRows", "compositionCellsPreserved", "runtimeFoodsImported",
          "runtimeImportApproved", "calculationsApproved", "networkCalls", "databaseWrites")}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
