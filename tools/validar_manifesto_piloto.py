"""Confere o inventario documental do piloto; nao aprova pratica ou publicacao."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def main():
    checks = 0

    def require(condition, message):
        nonlocal checks
        checks += 1
        if not condition:
            raise ValueError(message)

    def local(name):
        target = (ROOT / name).resolve()
        target.relative_to(ROOT)
        require(target.is_file(), "Arquivo ausente: " + name)
        return target

    def load(name):
        return json.loads(local(name).read_text(encoding="utf-8-sig"))

    def pointer(document, path):
        for token in path.split("/")[1:]:
            token = token.replace("~1", "/").replace("~0", "~")
            document = document[int(token)] if isinstance(document, list) else document[token]
        return document

    name = "content/manifests/pilot-candidates.json"
    manifest = load(name)
    catalog = load("docs/conteudo/fontes.json")
    for item in manifest["inputs"]:
        require(hashlib.sha256(local(item["path"]).read_bytes()).hexdigest() == item["sha256"], "Hash divergente: " + item["path"])
    source_ids = {s["id"] for s in catalog["sources"]}
    families = manifest["sourceFamilies"]
    require({s["sourceId"] for s in families} == source_ids, "Cobertura do catalogo divergente")
    require(len(families) == len(source_ids) == manifest["counts"]["sourceFamilies"], "Familias duplicadas/contagem divergente")
    coverage = manifest["researchCoverage"]
    require({n["niche"] for n in coverage} == {f"N{i:02}" for i in range(1, 47)}, "Cobertura N01-N46 divergente")
    require(len(coverage) == manifest["counts"]["researchNiches"] == 46, "Contagem de recortes divergente")
    for item in coverage:
        require(hashlib.sha256(local(item["evidence"]).read_bytes()).hexdigest() == item["evidenceSha256"], "Evidencia N divergente")
    for item in families:
        original = pointer(catalog, item["catalogPointer"])
        require(original["id"] == item["sourceId"], "Ponteiro de fonte divergente")
        require(original["status"] == item["researchStatus"], "Classificacao historica alterada")
        require(item["runtimeImportApproved"] is False and item["appPracticeState"] == "bloqueado", "Inventario de familia nao pode liberar runtime")
    components = manifest["selectedDocumentaryComponents"]
    require(len(components) == len({x["componentId"] for x in components}) == manifest["counts"]["selectedDocumentaryComponents"], "Componentes duplicados/contagem divergente")
    for item in components:
        require(item["sourceId"] in source_ids, "Fonte de componente ausente")
        original = pointer(load(item["evidence"]), item["pointer"])
        require(original.get("id", original.get("component")) in (item["componentId"], item["componentId"].removeprefix("N21-")), "Ponteiro de componente divergente")
        require(item["releaseApproved"] is False and item["mediaCopiedToApp"] is False, "Referencia documental nao libera pratica/midia")
    matrix = local(manifest["scenarioMatrix"]).read_text(encoding="utf-8")
    rows = "\n".join(line for line in matrix.splitlines() if line.startswith("| C"))
    require(set(re.findall(r"\| C(\d\d) ", rows)) == {f"{i:02}" for i in range(1, 25)}, "Cenarios C01-C24 divergentes")
    require({f"R{i:02}" for i in range(1, 19)} <= set(re.findall(r"R\d\d", rows)), "Requisito sem cenario")
    require(sum(x["topic"] == "alimentos" for x in families) == manifest["counts"]["foodSourceFamilies"], "Fontes alimentares divergentes")
    require(manifest["counts"]["runtimeApprovedItems"] == 0 and not manifest["runtimeSeed"] and not manifest["releaseApproved"], "Manifesto candidato tratado como aprovado")
    require(not manifest["paidContentPolicy"]["purchaseApproved"], "Compra nao aprovada")
    print(json.dumps({"result": "PASS", "checks": checks, **manifest["counts"], "scenarios": 24, "manifestSha256": hashlib.sha256(local(name).read_bytes()).hexdigest()}, ensure_ascii=True))


if __name__ == "__main__":
    main()
