"""Leitura estática portátil. Não executa aplicativo, servidor, banco ou código Go."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path


def read(path):
    return Path(path).read_text(encoding="utf-8-sig").replace("\r\n", "\n")


def digest(path):
    return hashlib.sha256(read(path).encode()).hexdigest()


def source(path, root, repository="trainforge", line=1):
    return {"repository": repository, "path": path.relative_to(root).as_posix(), "line": line}


def line_at(text, offset):
    return text.count("\n", 0, offset) + 1


def normalized(path):
    path = re.sub(r"\$\{[^}]+\}|\$[A-Za-z_]\w*|:[A-Za-z_]\w*|\{[^}]+\}", ":param", path)
    return "/" + path.strip("/") if path.strip("/") else "/"


def dart_calls(path, root):
    text, result = read(path), []
    pattern = r"\b(?:dio|_dio)\.(get|post|put|patch|delete)\s*(?:<[^;()]+>)?\s*\(\s*(['\"])(.*?)\2"
    for match in re.finditer(pattern, text, re.S):
        end = text.find("\n  }", match.end())
        segment = text[match.end():end if end >= 0 else match.end() + 800]
        result.append({"method": match[1].upper(), "path": match[3],
                       "keys": sorted(set(re.findall(r"['\"]([\w]+)['\"]\s*:", segment))),
                       "source": source(path, root, line=line_at(text, match.start()))})
    return result


def backend_inventory(api):
    """Captura explícita: apenas metadados, sem valores .env, logs ou banco."""
    index = api / "src/index.ts"
    if not index.exists() or not (api / "prisma/schema.prisma").exists():
        raise ValueError("Backend Fastify/Prisma não encontrado no caminho fornecido")
    registrations = {}
    for match in re.finditer(r"app\.register\(\s*(\w+)\s*,\s*\{(.*?)\}\s*\)", read(index), re.S):
        prefix = re.search(r'prefix:\s*[\'"]([^\'"]+)', match[2])
        if prefix:
            registrations[match[1]] = prefix[1]
    routes, unresolved = [], []
    for path in sorted((api / "src/routes").glob("*.ts")):
        text = read(path)
        exported = re.search(r"export\s+const\s+(\w+)", text)
        prefix = registrations.get(exported[1] if exported else "")
        starts = list(re.finditer(r"method:\s*['\"](GET|POST|PATCH|PUT|DELETE)['\"]\s*,\s*url:\s*['\"]([^'\"]+)['\"]", text))
        for i, match in enumerate(starts):
            loc = source(path, api, "backend-reference", line_at(text, match.start()))
            if prefix is None:
                unresolved.append({"source": loc, "reason": "prefixo não resolvido"})
                continue
            chunk = text[match.end():starts[i + 1].start() if i + 1 < len(starts) else len(text)]
            body = re.search(r"\bbody:\s*([\w.]+)", chunk)
            query = re.search(r"\bquerystring:\s*(\w+)", chunk)
            response = re.search(r"\bresponse:\s*\{(.*?)\n\s*\},", chunk, re.S)
            routes.append({"method": match[1], "path": prefix.rstrip("/") + (match[2] if match[2] != "/" else ""),
                           "group": path.stem, "requestType": body[1] if body else None,
                           "queryType": query[1] if query else None,
                           "responses": dict(re.findall(r"\b(\d{3}):\s*([\w.]+)", response[1])) if response else {},
                           "usecases": sorted(set(re.findall(r"new\s+([A-Z]\w+)\(", chunk))), "source": loc})
    schema = api / "prisma/schema.prisma"
    text = read(schema)
    names = set(re.findall(r"^model\s+(\w+)", text, re.M))
    models = []
    for match in re.finditer(r"^model\s+(\w+)\s*\{(.*?)^\}", text, re.M | re.S):
        fields = [{"name": f[1], "type": f[2] + (f[3] or ""), "relation": f[2] in names}
                  for f in re.finditer(r"^\s*(\w+)\s+(\w+)(\[\]|\?)?([^\n]*)", match[2], re.M)]
        models.append({"name": match[1], "fields": fields,
                       "source": source(schema, api, "backend-reference", line_at(text, match.start()))})
    files = sorted(p for p in (api / "src").rglob("*.ts") if "generated" not in p.parts) + [schema]
    return {"routes": routes, "models": models, "unresolved": unresolved,
            "files": {p.relative_to(api).as_posix(): digest(p) for p in files},
            "tsFiles": len(files) - 1,
            "limitations": ["Snapshot de código externo, sem validação runtime.",
                            "Rotas de plugins, Swagger e health raiz não são extraídas.",
                            "Schemas inline conservam o nome detectado, sem inventar seu conteúdo."]}


def go_inventory(root):
    paths = sorted(p for p in (root / "services/api").rglob("*.go")
                   if not p.name.endswith("_test.go") and "vendor" not in p.parts and "generated" not in p.parts)
    annotations, registrations = [], []
    for path in paths:
        text = read(path)
        for match in re.finditer(r"^\s*//\s*@Router\s+(\S+)\s+\[(\w+)\]", text, re.M | re.I):
            before = text[:match.start()].split("\n\n")[-1]
            annotations.append({"method": match[2].upper(), "path": match[1],
                                "params": re.findall(r"//\s*@Param\s+(.+)", before),
                                "responses": re.findall(r"//\s*@(Success|Failure)\s+(.+)", before),
                                "source": source(path, root, line=line_at(text, match.start()))})
        for match in re.finditer(r'\b(?:Handle|HandleFunc)\(\s*"(GET|POST|PUT|PATCH|DELETE)\s+([^"\s]+)"', text):
            registrations.append({"method": match[1], "path": match[2],
                                  "source": source(path, root, line=line_at(text, match.start()))})
    for item in annotations:
        item["registrationDetected"] = any(x["method"] == item["method"] and normalized(x["path"]) == normalized(item["path"]) for x in registrations)
    specifications = []
    for path in sorted((root / "contracts/generated").glob("*.json")):
        spec = json.loads(read(path))
        if not (spec.get("swagger") or spec.get("openapi")):
            continue
        for route, operations in spec.get("paths", {}).items():
            for method, operation in operations.items():
                if method.upper() not in {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}:
                    continue
                specifications.append({"method": method.upper(), "path": spec.get("basePath", "").rstrip("/") + route,
                                       "operationId": operation.get("operationId"), "parameters": operation.get("parameters", []),
                                       "responses": operation.get("responses", {}), "source": source(path, root)})
    return {"files": [p.relative_to(root).as_posix() for p in paths], "annotations": annotations,
            "registrations": registrations, "specificationOperations": specifications,
            "limitations": ["Anotação não prova registro de rota, autorização ou execução.",
                            "Registro Go detecta literais net/http com método; routers dinâmicos podem ficar fora."]}


def scan(root):
    ref_path = root / "docs/arquitetura/referencias/backend-fastify.json"
    backend = json.loads(read(ref_path))
    dart = sorted((root / "lib").rglob("*.dart"))
    calls = [c for path in dart for c in dart_calls(path, root)]
    go = go_inventory(root)
    for call in calls:
        call["legacyMatches"] = [r for r in backend["routes"] if r["method"] == call["method"] and normalized(r["path"]) == normalized(call["path"])]
        call["goMatches"] = [r for r in go["registrations"] if r["method"] == call["method"] and normalized(r["path"]) == normalized(call["path"])]
    screens, navigation = [], []
    for path in dart:
        text = read(path)
        for match in re.finditer(r"class\s+(\w+(?:Page|Gate|Shell))\s+extends\s+(?:StatefulWidget|StatelessWidget)", text):
            screens.append({"id": match[1], "source": source(path, root, line=line_at(text, match.start()))})
    for screen in screens:
        text = read(root / screen["source"]["path"])
        for target in screens:
            match = re.search(r"\b" + re.escape(target["id"]) + r"\s*\(", text)
            if match and target["id"] != screen["id"]:
                navigation.append({"from": screen["id"], "to": target["id"],
                                   "source": source(root / screen["source"]["path"], root, line=line_at(text, match.start()))})
    groups = [("ui", "Telas e widgets", [p for p in dart if "presentation" in p.parts or "shared" in p.parts]),
              ("repositories", "Repositories Flutter", [p for p in dart if p.stem.endswith("repository")]),
              ("http", "HTTP Dio", [p for p in dart if p.stem.endswith("api") or p.stem == "app_dio"]),
              ("models", "Modelos Dart", [p for p in dart if "domain" in p.parts])]
    membership = {p.resolve(): name for name, _, paths in groups for p in paths}
    imports = {}
    for path in dart:
        a = membership.get(path.resolve())
        if not a:
            continue
        text = read(path)
        for match in re.finditer(r"import\s+['\"]([^'\"]+)['\"]", text):
            ref = match[1]
            target = root / "lib" / ref.removeprefix("package:trainforge/") if ref.startswith("package:trainforge/") else path.parent / ref
            b = membership.get(target.resolve())
            if b and b != a:
                imports.setdefault((a, b), []).append(source(path, root, line=line_at(text, match.start())))
    inputs = dart + [root / f for f in go["files"]]
    inputs += sorted((root / "contracts/generated").glob("*.json"))
    inputs += [ref_path, root / "docs/arquitetura/plano.json", root / "docs/execucao/v1/backlog.json", root / "docs/arquitetura/achados.json"]
    fingerprints = {p.relative_to(root).as_posix(): digest(p) for p in inputs}
    revision = hashlib.sha256(json.dumps(fingerprints, sort_keys=True).encode()).hexdigest()
    return {"schemaVersion": 2, "inputRevision": revision, "inputs": fingerprints,
            "coverage": {"dartFiles": len(dart), "backendMode": "versioned-reference", "backendCommit": backend["commit"],
                         "backendTsFiles": backend["tsFiles"], "legacyRoutes": len(backend["routes"]),
                         "httpCalls": len(calls), "legacyMatches": sum(bool(c["legacyMatches"]) for c in calls),
                         "goFiles": len(go["files"]), "goRegistrations": len(go["registrations"]), "modelsInReference": len(backend["models"])},
            "groups": [{"id": name, "label": label, "files": [source(p, root) for p in paths]} for name, label, paths in groups],
            "imports": [{"from": a, "to": b, "sources": refs} for (a, b), refs in sorted(imports.items())],
            "screens": screens, "navigation": navigation, "calls": calls, "backend": backend, "go": go,
            "limitations": ["Somente análise estática dos padrões suportados; não executa app/API/DB.",
                            "Backend externo é retrato explícito versionado, não código recebido no clone.",
                            "Comentários Go, rotas e especificação são evidências diferentes; não confundem com runtime.",
                            "Intenção arquitetural, direitos, revisão e conclusão de tarefa não são inferidos."]}
