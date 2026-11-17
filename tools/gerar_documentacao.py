"""Gera inventário e referência técnica; os guias de arquitetura são manuais.

Leitura: abrir docs/arquitetura/README.md. Manutenção/CI: --write / --check.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path
from urllib.parse import quote, urlparse

from documentacao_backlog import backlog_markdown, validate
from documentacao_inventario import backend_inventory, digest, read, scan

ROOT = Path(__file__).resolve().parents[1]
GENERATED = "docs/arquitetura/gerado/referencia.md"
BACKLOG_PATH = "docs/execucao/v1/backlog.json"
PLAN_PATH = "docs/arquitetura/plano.json"
REFERENCE = "docs/arquitetura/referencias/backend-fastify.json"


def cell(text):
    return str(text if text is not None else "não detectado").replace("|", " / ").replace("\n", " ")


def local_link(target, document, text=None):
    href = os.path.relpath(target, Path(document).parent).replace("\\", "/")
    return f"[{text or target}]({quote(href, safe='/.-_')})"


def evidence(ref, document, backend):
    title = f"{ref['path']}:{ref.get('line', 1)}"
    if ref["repository"] == "trainforge":
        return local_link(ref["path"], document, title)
    if backend.get("repository") and not backend.get("dirty"):
        url = f"{backend['repository']}/blob/{backend['commit']}/{quote(ref['path'], safe='/')}#L{ref.get('line', 1)}"
        return f"[{title}]({url})"
    return f"`{title}` (referência externa)"


def table(headers, rows):
    lines = ["| " + " | ".join(headers) + " |", "| " + " | ".join("---" for _ in headers) + " |"]
    lines += ["| " + " | ".join(cell(c) for c in row) + " |" for row in rows]
    return "\n".join(lines) + "\n"


def header(title, revision):
    return f"# {title}\n\n> Gerado de código e registros versionados por `tools/gerar_documentacao.py`. Não editar este arquivo à mão. Revisão das entradas: `{revision[:16]}`.\n\n"


def outputs(root):
    backlog = json.loads(read(root / BACKLOG_PATH))
    plan = json.loads(read(root / PLAN_PATH))
    errors = validate(backlog, plan, root)
    if errors:
        raise ValueError("; ".join(errors))
    data = scan(root)
    for path in sorted(list((root / "tools").glob("*.py")) + list((root / "tools").glob("*.mjs"))):
        data["inputs"][path.relative_to(root).as_posix()] = digest(path)
    data["inputRevision"] = hashlib.sha256(json.dumps(data["inputs"], sort_keys=True).encode()).hexdigest()
    backend, coverage, doc = data["backend"], data["coverage"], GENERATED
    text = header("Referência técnica extraída do código", data["inputRevision"])
    text += "[Arquitetura explicada](../README.md) · [APIs](../diagramas/apis.md) · [Banco e colunas](../diagramas/banco.md) · [Backlog](../../execucao/v1/backlog.md)\n\n"
    text += "Este inventário lê padrões estáticos de Dart, Go, SQL e Swagger. Não executa o aplicativo nem comprova navegação, autorização, migrations aplicadas ou aceite funcional. Os guias manuais explicam o sistema e as decisões; esta página concentra os detalhes extraídos.\n\n"
    text += table(["Entrada", "Quantidade detectada"], [
        ["Arquivos Dart", coverage["dartFiles"]], ["Telas/widgets", len(data["screens"])],
        ["Literais HTTP Flutter", coverage["httpCalls"]], ["Arquivos Go de produção", coverage["goFiles"]],
        ["Registros HTTP Go", coverage["goRegistrations"]],
        ["Operações em especificações versionadas", len(data["go"]["specificationOperations"])],
        ["Tabelas do núcleo declaradas em migrations", len(data["go"]["tables"])],
    ])
    text += "\n## Flutter: telas e referências\n\nUma referência de construtor não demonstra clique ou condição de navegação.\n\n"
    text += table(["Tela/widget", "Fonte"], [[s["id"], evidence(s["source"], doc, backend)] for s in data["screens"]])
    text += "\n" + table(["Origem", "Widget referenciado", "Fonte"], [
        [e["from"], e["to"], evidence(e["source"], doc, backend)] for e in data["navigation"]])
    text += "\n## Flutter: chamadas e registros Go\n\nMétodo e caminho compatíveis não garantem DTO, resposta ou autenticação. Expressões dinâmicas podem ficar fora da extração.\n\n"
    text += table(["Chamada Flutter", "Chaves literais", "Registro Go compatível", "Fonte Flutter"], [
        [f"`{c['method']} {c['path']}`", ", ".join(c["keys"]) or "não detectadas",
         "; ".join(evidence(r["source"], doc, backend) for r in c["goMatches"]) or "não resolvido estaticamente",
         evidence(c["source"], doc, backend)] for c in data["calls"]])
    text += "\n## Go: pacotes e imports\n\nImports indicam dependência de código; não são chamadas HTTP nem traces.\n\n"
    text += table(["Pacote", "Importa internamente"], [
        [p, ", ".join(b for a, b in data["go"]["imports"] if a == p) or "nenhum import interno detectado"]
        for p in data["go"]["packages"]])
    text += "\n## Go: anotações e registros HTTP\n\nAnotação, registro de rota e operação Swagger são evidências diferentes. Testes de handler e integração continuam necessários.\n\n"
    text += table(["Anotação @Router", "Parâmetros", "Respostas", "Registro compatível", "Fonte"], [
        [f"`{r['method']} {r['path']}`", "; ".join(r["params"]), "; ".join(" ".join(v) for v in r["responses"]),
         "sim" if r["registrationDetected"] else "não detectado", evidence(r["source"], doc, backend)] for r in data["go"]["annotations"]])
    text += "\n" + table(["Registro HTTP", "Fonte"], [
        [f"`{r['method']} {r['path']}`", evidence(r["source"], doc, backend)] for r in data["go"]["registrations"]])
    text += "\n## Swagger: parâmetros e respostas\n\n"
    text += table(["Operação", "operationId", "Parâmetros/body", "Status e schemas", "Fonte"], [
        [f"`{r['method']} {r['path']}`", r["operationId"], json.dumps(r["parameters"], ensure_ascii=False),
         json.dumps(r["responses"], ensure_ascii=False), evidence(r["source"], doc, backend)]
        for r in data["go"]["specificationOperations"]])
    text += "\n## SQL: criação das tabelas do núcleo\n\nA declaração não comprova aplicação no banco. ALTERs, índices, funções e grants permanecem nas migrations; o snapshot público de schema está na referência de banco.\n\n"
    text += table(["Tabela", "Migration fonte"], [[t["name"], evidence(t["source"], doc, backend)] for t in data["go"]["tables"]])
    text += "\n## Referência histórica do backend anterior\n\n"
    text += f"O snapshot Fastify/Prisma de {backend['capturedOn']}, commit `{backend['commit']}`, conserva {coverage['legacyRoutes']} rotas e {coverage['modelsInReference']} modelos para rastreabilidade da migração. Ele não descreve o backend atual. Metadados, hashes e links das fontes estão no [JSON histórico](../referencias/backend-fastify.json); a interpretação está nas [decisões](../decisoes.md).\n\n"
    text += "O estado das histórias permanece no backlog; o gerador não encerra achados ou libera conteúdo. [Como manter esta referência](../manutencao.md).\n"
    result = {"docs/arquitetura/inventario-atual.json": json.dumps(data, ensure_ascii=False, indent=2) + "\n",
              "docs/execucao/v1/backlog.md": backlog_markdown(backlog), GENERATED: text}
    return result, data


def check_links(root, documents):
    failures = []
    anchors, archive_entries = {}, {}
    def visible(text):
        return re.sub(r"```.*?```|~~~.*?~~~", "", text, flags=re.S)
    def ids(path):
        if path not in anchors:
            text = visible(read(path))
            found = set(re.findall(r'<a\s+id=[\"\x27]([^\"\x27]+)', text, re.I))
            counts = {}
            for name in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', text, re.M):
                name = re.sub(r'<[^>]+>', '', name)
                slug = '-'.join(re.sub(r'[^\w\s-]', '', name.lower()).split())
                n = counts.get(slug, 0)
                counts[slug] = n + 1
                found.add(slug + (f'-{n}' if n else ''))
            anchors[path] = found
        return anchors[path]
    for relative in documents:
        path = root / relative
        if not path.exists() or path.suffix != ".md":
            continue
        text = visible(read(path))
        for match in re.finditer(r"\]\(([^)]+)\)", text):
            target = match[1].strip("<>")
            if re.match(r"^[a-z]+:", target, re.I):
                continue
            from urllib.parse import unquote
            target, _, fragment = target.partition('#')
            target, fragment = unquote(target), unquote(fragment)
            destination = (path.parent / target).resolve() if target else path.resolve()
            if not destination.exists():
                failures.append(relative + " → " + target)
            elif fragment and destination.suffix == '.md' and fragment not in ids(destination):
                failures.append(relative + " → " + target + '#' + fragment)
            elif fragment and destination.suffix == '.zip':
                import zipfile
                if destination not in archive_entries:
                    with zipfile.ZipFile(destination) as bundle:
                        archive_entries[destination] = set(bundle.namelist())
                if fragment not in archive_entries[destination]:
                    failures.append(relative + " → " + target + '#' + fragment)
    return failures


def capture(root, api):
    api = api.resolve()
    base = ["git", "-c", "safe.directory=" + api.as_posix(), "-C", str(api)]
    if subprocess.check_output(base + ["status", "--porcelain"]):
        raise ValueError("Backend com alterações locais: revisar e registrar antes de capturar")
    commit = subprocess.check_output(base + ["rev-parse", "HEAD"], text=True).strip()
    origin = subprocess.check_output(base + ["config", "--get", "remote.origin.url"], text=True).strip()
    origin = origin.replace("git@github.com:", "https://github.com/")
    parsed = urlparse(origin)
    repository = "https://github.com" + parsed.path.removesuffix(".git") if parsed.hostname == "github.com" else None
    from datetime import datetime
    snapshot = backend_inventory(api)
    snapshot.update({"repository": repository, "commit": commit, "capturedOn": datetime.now().astimezone().date().isoformat(),
                     "dirty": False, "kind": "versioned-external-source-reference"})
    (root / REFERENCE).write_text(json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="regenerar arquivos derivados")
    parser.add_argument("--check", action="store_true", help="falhar se derivados estiverem desatualizados")
    parser.add_argument("--capture-backend", type=Path, help="atualizar explicitamente a referência externa")
    args = parser.parse_args()
    if args.capture_backend:
        capture(ROOT, args.capture_backend)
    expected, data = outputs(ROOT)
    if args.write:
        for relative, content in expected.items():
            path = ROOT / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
    if args.check:
        stale = [p for p, text in expected.items() if not (ROOT / p).exists() or read(ROOT / p) != text]
        active_docs = list(expected) + [p.relative_to(ROOT).as_posix() for p in (ROOT / "docs").rglob("*.md")
                                     if 'apresentacao-senas' not in p.parts]
        active_docs += ["README.md", "AGENTS.md", "guia-do-projeto.md", "documentacao-tecnica.md", "docs/README.md",
                        "docs/execucao/v1/handoff.md", "docs/execucao/v1/escopo.md", "docs/historico/README.md"]
        broken = check_links(ROOT, active_docs)
        if stale or broken:
            raise SystemExit("Documentação divergente: " + "; ".join(stale + broken) + ". Execute --write e revise.")
        print("OK: geração reproduzível, backlog, dependências, requisitos, entradas e links locais.")
    print(json.dumps(data["coverage"], ensure_ascii=False))


if __name__ == "__main__":
    main()
