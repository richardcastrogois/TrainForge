"""Inventário estático e painel local do TrainForge. Só biblioteca padrão Python.

Não executa app, migrações, npm ou Graphify; não lê .env, tokens ou banco.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import threading
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_API = ROOT.parent.parent / "bootcamp-treinos-api"
PANEL = ROOT / "docs/painel"
BACKLOG = ROOT / "docs/execucao/v1/backlog.json"
PLAN = ROOT / "docs/arquitetura/plano.json"


def read(path):
    return Path(path).read_text(encoding="utf-8-sig")


def source(path, line=1):
    return {"path": str(path.resolve()).replace("\\", "/"), "line": line}


def line_at(text, offset):
    return text.count("\n", 0, offset) + 1


def normalized(path):
    path = re.sub(r"\$\{[^}]+\}|\$[A-Za-z_]\w*|:[A-Za-z_]\w*|\{[^}]+\}", ":param", path)
    return "/" + path.strip("/") if path.strip("/") else "/"


def dart_calls(path):
    text = read(path)
    result = []
    # Apenas literais de path passados diretamente ao Dio; chamadas dinâmicas não são inferidas.
    pattern = r"\b(?:dio|_dio)\.(get|post|put|patch|delete)\s*(?:<[^;()]+>)?\s*\(\s*(['\"])(.*?)\2"
    matches = list(re.finditer(pattern, text, re.S))
    for i, match in enumerate(matches):
        # Limitar a região ao próximo método/chamada para não misturar payloads.
        end = text.find("\n  }", match.end())
        segment = text[match.end():end if end >= 0 else match.end() + 800]
        result.append({"method": match[1].upper(), "path": match[3],
                       "bodyKeys": sorted(set(re.findall(r"['\"]([\w]+)['\"]\s*:", segment))),
                       "source": source(path, line_at(text, match.start()))})
    return result


def route_inventory(api):
    index = api / "src/index.ts"
    if not index.exists():
        return [], [], []
    registrations = {}
    for m in re.finditer(r"app\.register\(\s*(\w+)\s*,\s*\{(.*?)\}\s*\)", read(index), re.S):
        prefix = re.search(r'prefix:\s*[\'"]([^\'"]+)', m[2])
        if prefix:
            registrations[m[1]] = prefix[1]
    routes, unresolved, schema_refs = [], [], []
    schema_path = api / "src/schemas/index.ts"
    if schema_path.exists():
        schema_text = read(schema_path)
        schema_refs = [{"name": m[1], "source": source(schema_path, line_at(schema_text, m.start()))}
                       for m in re.finditer(r"export\s+const\s+(\w+Schema)\b", schema_text)]
    for path in sorted((api / "src/routes").glob("*.ts")):
        text = read(path)
        exported = re.search(r"export\s+const\s+(\w+)", text)
        prefix = registrations.get(exported[1] if exported else "")
        starts = list(re.finditer(r"method:\s*['\"](GET|POST|PATCH|PUT|DELETE)['\"]\s*,\s*url:\s*['\"]([^'\"]+)['\"]", text))
        for i, m in enumerate(starts):
            chunk = text[m.end(): starts[i + 1].start() if i + 1 < len(starts) else len(text)]
            if prefix is None:
                unresolved.append({"file": path.name, "reason": "prefixo não resolvido", "source": source(path, line_at(text, m.start()))})
                continue
            body = re.search(r"\bbody:\s*([\w.]+)", chunk)
            query = re.search(r"\bquerystring:\s*(\w+)", chunk)
            responses = re.search(r"\bresponse:\s*\{(.*?)\n\s*\},", chunk, re.S)
            response_types = dict(re.findall(r"\b(\d{3}):\s*([\w.]+)", responses[1])) if responses else {}
            routes.append({"method": m[1], "path": prefix.rstrip("/") + (m[2] if m[2] != "/" else ""),
                           "group": path.stem, "requestType": body[1] if body else None,
                           "queryType": query[1] if query else None, "responses": response_types,
                           "usecases": sorted(set(re.findall(r"new\s+([A-Z]\w+)\(", chunk))),
                           "source": source(path, line_at(text, m.start())),
                           "evidence": "declaração estática; execução não testada"})
    return routes, unresolved, schema_refs


def schema_inventory(api):
    path = api / "prisma/schema.prisma"
    if not path.exists():
        return []
    text = read(path)
    models = []
    names = set(re.findall(r"^model\s+(\w+)", text, re.M))
    for m in re.finditer(r"^model\s+(\w+)\s*\{(.*?)^\}", text, re.M | re.S):
        fields = []
        for field in re.finditer(r"^\s*(\w+)\s+(\w+)(\[\]|\?)?([^\n]*)", m[2], re.M):
            if field[1].startswith("@@"):
                continue
            fields.append({"name": field[1], "type": field[2] + (field[3] or ""), "relation": field[2] in names})
        models.append({"name": m[1], "fields": fields, "source": source(path, line_at(text, m.start()))})
    return models


def scan(api=DEFAULT_API):
    dart = sorted((ROOT / "lib").rglob("*.dart"))
    ts = sorted(p for p in (api / "src").rglob("*.ts") if "generated" not in p.parts) if api.exists() else []
    routes, unresolved, schemas = route_inventory(api)
    calls = [c for p in dart for c in dart_calls(p)]
    for call in calls:
        call["matches"] = [r for r in routes if r["method"] == call["method"] and normalized(r["path"]) == normalized(call["path"])]
        call["evidence"] = "literal HTTP e correspondência por método/path; não prova resposta em runtime"
    screens = []
    nav_edges = []
    for path in dart:
        text = read(path)
        classes = re.findall(r"class\s+(\w+(?:Page|Gate|Shell))\s+extends\s+(?:StatefulWidget|StatelessWidget)", text)
        for name in classes:
            screens.append({"id": name, "label": name, "layer": "Flutter", "source": source(path), "kind": "tela/widget"})
    for screen in screens:
        path = Path(screen["source"]["path"])
        text = read(path)
        for target in screens:
            if target["id"] == screen["id"]:
                continue
            m = re.search(r"\b" + re.escape(target["id"]) + r"\s*\(", text)
            if m:
                nav_edges.append({"from": screen["id"], "to": target["id"], "label": "referência de widget/navegação",
                                  "source": source(path, line_at(text, m.start())), "evidence": "estático; condição e interação não executadas"})
    groups = [
        ("ui", "Telas Flutter", "Interface", [p for p in dart if "presentation" in p.parts or "shared" in p.parts]),
        ("repositories", "Repositories", "Flutter", [p for p in dart if p.stem.endswith("repository")]),
        ("http", "APIs / Dio", "HTTP", [p for p in dart if p.stem.endswith("api") or p.stem == "app_dio"]),
        ("models", "Modelos Dart", "Flutter", [p for p in dart if "domain" in p.parts]),
        ("routes", "Rotas Fastify", "Backend", [p for p in ts if "routes" in p.parts]),
        ("usecases", "Casos de uso TS", "Backend", [p for p in ts if "usecases" in p.parts]),
        ("dbaccess", "Prisma / conexão", "Persistência", [p for p in ts if p.stem == "db"]),
    ]
    nodes = [{"id": key, "label": label, "layer": layer, "files": [source(p) for p in files],
              "evidence": "arquivos presentes; análise estática"} for key, label, layer, files in groups if files]
    membership = {p.resolve(): key for key, _, _, files in groups for p in files}
    edge_map = {}
    # As arestas importadas preservam arquivo/linha; não são chamadas runtime.
    for path in dart + ts:
        a = membership.get(path.resolve())
        if not a:
            continue
        text = read(path)
        for m in re.finditer(r"(?:import\s*(?:[^;]*?\sfrom\s*)?['\"])([^'\"]+)['\"]", text):
            ref = m[1]
            if ref.startswith("package:trainforge/"):
                target = ROOT / "lib" / ref.removeprefix("package:trainforge/")
            elif ref.startswith("."):
                target = path.parent / (ref[:-3] + ".ts" if ref.endswith(".js") else ref)
            else:
                continue
            b = membership.get(target.resolve())
            if b and a != b:
                e = edge_map.setdefault((a, b), {"from": a, "to": b, "label": "import estático", "sources": []})
                e["sources"].append(source(path, line_at(text, m.start())))
    if any(c["matches"] for c in calls):
        edge_map[("http", "routes")] = {"from": "http", "to": "routes", "label": "HTTP: literais compatíveis",
                                          "sources": [c["source"] for c in calls if c["matches"]]}
    findings = json.loads(read(ROOT / "docs/arquitetura/achados.json"))
    for finding in findings:
        finding["exists"] = (ROOT / finding["evidence"]).exists() if not finding["evidence"].startswith("backend:") else (api / finding["evidence"][8:]).exists()
    return {"generatedAt": datetime.now(timezone.utc).isoformat(), "project": "TrainForge",
            "coverage": {"flutterRoot": str(ROOT), "apiRoot": str(api), "apiAvailable": (api / "src/index.ts").exists(),
                         "dartFiles": len(dart), "tsFiles": len(ts), "routes": len(routes), "httpCalls": len(calls),
                         "matchedCalls": sum(bool(c["matches"]) for c in calls), "models": len(schema_inventory(api))},
            "limitations": ["Análise por padrões estáticos, sem executar app/API/banco.",
                            "Paths dinâmicos, plugins e navegação condicional podem ficar fora do mapa.",
                            "Prefixos e schemas inline não resolvidos permanecem explícitos; não são inventados.",
                            "Achados e intenção arquitetural exigem revisão humana; alteração de arquivo não fecha tarefa."],
            "nodes": nodes, "edges": list(edge_map.values()), "screens": screens, "screenEdges": nav_edges,
            "routes": routes, "calls": calls, "models": schema_inventory(api), "schemas": schemas,
            "unresolved": unresolved, "findings": findings}


def validate(backlog, plan):
    issues, ids = [], set()
    stories = [s for e in backlog["epics"] for s in e["stories"]]
    for story in stories:
        if story["id"] in ids:
            issues.append("ID duplicado: " + story["id"])
        ids.add(story["id"])
        for key in ("acceptance", "validation", "deliverables", "tasks"):
            if not story.get(key):
                issues.append(story["id"] + ": sem " + key)
        for entry in story.get("inputs", []):
            if not (ROOT / entry).exists():
                issues.append(story["id"] + ": entrada ausente " + entry)
        if story["status"] not in ("todo", "doing", "blocked", "done"):
            issues.append(story["id"] + ": status inválido")
        if story["status"] == "done" and not story.get("completionEvidence"):
            issues.append(story["id"] + ": conclusão sem evidência")
        for task in story["tasks"]:
            if not task.get("subtasks"):
                issues.append(story["id"] + ": tarefa sem subtarefa")
    graph = {s["id"]: s["dependsOn"] for s in stories}
    visiting, visited = set(), set()
    def visit(node):
        if node in visiting:
            issues.append("Dependência cíclica: " + node)
            return
        if node in visited:
            return
        visiting.add(node)
        for dep in graph.get(node, []):
            if dep not in ids:
                issues.append(node + ": dependência ausente " + dep)
            else:
                visit(dep)
        visiting.remove(node)
        visited.add(node)
    for node in graph:
        visit(node)
    if backlog.get("next") not in ids:
        issues.append("Próxima história inexistente")
    requirements = {r for s in stories for r in s.get("requirements", [])}
    if requirements != {f"R{i:02}" for i in range(1, 19)}:
        issues.append("Cobertura R01–R18 divergente")
    node_ids = {n["id"] for n in plan["nodes"]}
    for edge in plan["edges"]:
        if edge["from"] not in node_ids or edge["to"] not in node_ids:
            issues.append("Aresta planejada sem nó")
    return issues


def backlog_markdown(backlog):
    lines = ["# Backlog V1", "", "> Gerado de `backlog.json` por `tools/painel_projeto.py --snapshot`. Edite o JSON.", "",
             "Status: todo = não iniciado; done exige evidência. Não confundir planejamento com implementação.", ""]
    for epic in backlog["epics"]:
        lines += [f"## {epic['id']} — {epic['title']}", "", epic["outcome"], ""]
        for story in epic["stories"]:
            lines += [f"### {story['id']} — {story['title']}", "", f"**{story['status']} · {story['release']} · {story['size']}**", "",
                      story["userStory"], "", "Dependências: " + (", ".join(story["dependsOn"]) or "nenhuma"), "",
                      "Entradas: " + "; ".join(story["inputs"]), "", "Critérios de aceite:", ""]
            lines += ["- " + v for v in story["acceptance"]]
            lines += ["", "Tarefas e subtarefas:", ""]
            for task in story["tasks"]:
                lines += ["- " + task["id"] + " — " + task["title"]]
                lines += ["  - " + sub for sub in task["subtasks"]]
            lines += ["", "Validação: " + "; ".join(story["validation"]), "", "Entregas: " + "; ".join(story["deliverables"]), "",
                      "Handoff: " + story["handoff"], ""]
    return "\n".join(lines)


class ProjectState:
    def __init__(self, api):
        self.api, self.lock = api, threading.Lock()
        self.fingerprint, self.payload = None, None

    def get(self):
        with self.lock:
            paths = list((ROOT / "lib").rglob("*.dart")) + list((self.api / "src").rglob("*.ts"))
            paths = [p for p in paths if "generated" not in p.parts]
            paths += [self.api / "prisma/schema.prisma", BACKLOG, PLAN, ROOT / "docs/arquitetura/achados.json"]
            stamp = hashlib.sha256("|".join(f"{p}:{p.stat().st_mtime_ns}:{p.stat().st_size}" for p in sorted(paths) if p.exists()).encode()).hexdigest()
            if stamp != self.fingerprint:
                backlog, plan = json.loads(read(BACKLOG)), json.loads(read(PLAN))
                issues = validate(backlog, plan)
                if issues:
                    raise ValueError("; ".join(issues))
                self.payload = {"revision": stamp, "actual": scan(self.api), "planned": plan, "backlog": backlog}
                self.fingerprint = stamp
            return self.payload


def handler(state):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass

        def do_GET(self):
            # Bloquear DNS rebinding e leitura por outro site; apenas localhost explícito.
            host = self.headers.get("Host", "").split(":")[0].lower()
            if host not in ("127.0.0.1", "localhost"):
                self.send_error(403)
                return
            origin = self.headers.get("Origin")
            if origin and origin not in (f"http://127.0.0.1:{self.server.server_port}", f"http://localhost:{self.server.server_port}"):
                self.send_error(403)
                return
            path = unquote(urlparse(self.path).path)
            allowed = {"/": (PANEL / "index.html", "text/html; charset=utf-8"),
                       "/painel.js": (PANEL / "painel.js", "text/javascript; charset=utf-8"),
                       "/painel.css": (PANEL / "painel.css", "text/css; charset=utf-8")}
            try:
                if path in ("/api/mapa", "/api/health"):
                    payload = state.get() if path == "/api/mapa" else {"project": "TrainForge", "service": "project-map", "root": str(ROOT).replace("\\", "/")}
                    data, mime = json.dumps(payload, ensure_ascii=False).encode(), "application/json; charset=utf-8"
                elif path in allowed:
                    file, mime = allowed[path]
                    data = file.read_bytes()
                else:
                    self.send_error(404)
                    return
                self.send_response(200)
                self.send_header("Content-Type", mime)
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Cache-Control", "no-store")
                self.send_header("X-Content-Type-Options", "nosniff")
                self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'none'; form-action 'none'")
                self.end_headers()
                self.wfile.write(data)
            except (ValueError, OSError) as error:
                data = json.dumps({"error": "Inventário indisponível; confira arquivos locais e validação.", "kind": type(error).__name__}).encode()
                self.send_response(503)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)
    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api-root", type=Path, default=DEFAULT_API)
    parser.add_argument("--port", type=int, default=8787)
    parser.add_argument("--serve", action="store_true")
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    state = ProjectState(args.api_root.resolve())
    payload = state.get()
    if args.snapshot:
        (ROOT / "docs/arquitetura/inventario-atual.json").write_text(json.dumps(payload["actual"], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        (BACKLOG.parent / "backlog.md").write_text(backlog_markdown(payload["backlog"]), encoding="utf-8")
        print(json.dumps(payload["actual"]["coverage"], ensure_ascii=False))
    if args.check:
        expected = backlog_markdown(payload["backlog"])
        if not (BACKLOG.parent / "backlog.md").exists() or read(BACKLOG.parent / "backlog.md") != expected:
            raise SystemExit("Backlog Markdown divergente; execute --snapshot.")
        print("OK: IDs, dependências, critérios, tarefas, mapa e backlog gerado.")
    if args.serve:
        server = ThreadingHTTPServer(("127.0.0.1", args.port), handler(state))
        print(f"TrainForge: http://127.0.0.1:{args.port} — Ctrl+C para parar", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            server.server_close()


if __name__ == "__main__":
    main()
