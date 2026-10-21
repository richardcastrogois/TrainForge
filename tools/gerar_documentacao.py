"""Gera documentação Markdown/Mermaid versionada, sem servidor ou dependências.

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
GENERATED = "docs/arquitetura/gerado"
BACKLOG_PATH = "docs/execucao/v1/backlog.json"
PLAN_PATH = "docs/arquitetura/plano.json"
REFERENCE = "docs/arquitetura/referencias/backend-fastify.json"


def label(text):
    # Labels Mermaid não incorporam sintaxe/HTML fornecidos em comentários.
    return str(text).replace('"', "'").replace("\n", " ").replace("<", "(").replace(">", ")").replace("`", "'")


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


def mermaid(lines):
    return "```mermaid\n" + "\n".join(lines) + "\n```\n"


def flow(nodes, edges):
    ids = {n[0]: f"node{i}" for i, n in enumerate(nodes)}
    lines = ["flowchart LR"] + [f'    {ids[key]}["{label(text)}"]' for key, text in nodes]
    for a, b, description in edges:
        if a not in ids or b not in ids:
            raise ValueError("Aresta com nó não declarado: " + str((a, b)))
        lines.append(f'    {ids[a]} -->|"{label(description)}"| {ids[b]}')
    return mermaid(lines)


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
    revision, backend, coverage = data["inputRevision"], data["backend"], data["coverage"]
    result = {"docs/arquitetura/inventario-atual.json": json.dumps(data, ensure_ascii=False, indent=2) + "\n",
              "docs/execucao/v1/backlog.md": backlog_markdown(backlog)}
    doc = "docs/arquitetura/README.md"
    text = header("Arquitetura do TrainForge — comece aqui", revision)
    text += "**Leia este arquivo e os links abaixo no GitHub ou no editor. Não é necessário iniciar Python, Go, API, banco ou servidor para consultar.** Os diagramas Mermaid são texto versionado e renderizado pelo GitHub.\n\n"
    text += "## O que existe e o que é proposta\n\n"
    text += table(["Área", "Evidência e limite"], [
        ["Flutter neste clone", f"{coverage['dartFiles']} arquivos Dart; análise estática, sem teste runtime"],
        ["Backend Fastify externo", f"Referência auditada em {backend['capturedOn']}, commit `{backend['commit'][:12]}`; {coverage['legacyRoutes']} rotas extraídas. O clone não contém esse código"],
        ["Go neste clone", f"{coverage['goFiles']} arquivos Go de aplicação; {coverage['goRegistrations']} registros net/http detectados"],
        ["Produto", "Android e iOS; primeiro desenvolvimento/teste em Android"],
        ["Conteúdo", "Pesquisa concluída nos recortes; publicação/prática/direitos continuam por item"],
    ])
    text += "\n## Mapa atual: estrutura e correspondências\n\n"
    nodes = [(g["id"], f"{g['label']} ({len(g['files'])} arquivos)") for g in data["groups"]]
    edges = [(e["from"], e["to"], "importação estática") for e in data["imports"]]
    if coverage["legacyMatches"]:
        nodes.append(("legacy", "Fastify: referência externa versionada"))
        edges.append(("http", "legacy", f"{coverage['legacyMatches']} métodos e paths compatíveis"))
    if nodes:
        text += flow(nodes, edges)
    text += "\nSetas de importação não são traces. Correspondência HTTP não confirma autenticação, DTO completo ou resposta em execução.\n\n"
    text += "## Arquitetura proposta: ainda a implementar\n\n"
    text += flow([(n["id"], n["label"]) for n in plan["nodes"]], [(e["from"], e["to"], e["label"]) for e in plan["edges"]])
    text += "\nA proposta Go não vira código atual por estar no desenho. Detalhes, camadas e limites de capacidade estão nos documentos revisados.\n\n"
    topics = [("Telas, destinos e jornadas", "telas-e-fluxos.md"), ("Quem chama quem, entradas e respostas", "chamadas-http.md"),
              ("Modelos e relações do banco", "banco.md"), ("Go: comentários, registros e especificação", "go-e-swagger.md"),
              ("Progresso, dependências e tarefas", "progresso.md")]
    text += "## Explorar por assunto\n\n" + "\n".join(f"- [{title}](gerado/{path})" for title, path in topics)
    text += "\n\n- [Camadas do backend Go](camadas-go.md)\n- [Como a documentação se atualiza](documentacao-dinamica.md)\n- [Swagger por comentários](swagger-go.md)\n- [Arquitetura proposta e decisões](arquitetura-alvo.md)\n- [Diagnóstico e achados](diagnostico-atual.md)\n- [Plano macro da V1](../execucao/v1/plano-macro.md)\n"
    result[doc] = text

    doc = f"{GENERATED}/telas-e-fluxos.md"
    text = header("Telas e fluxos", revision)
    text += "## Atual: referências entre widgets\n\nConstrutor referenciado é evidência estática. Condições, botão voltar, clique e transição real não foram executados pelo gerador.\n\n"
    if data["screens"]:
        text += flow([(s["id"], s["id"]) for s in data["screens"]], [(e["from"], e["to"], "referencia widget") for e in data["navigation"]])
    text += "\n" + table(["Tela/widget", "Localização"], [[s["id"], evidence(s["source"], doc, backend)] for s in data["screens"]])
    text += "\n## Chamadas usadas por cada feature\n\n"
    groups = {}
    for call in data["calls"]:
        parts = Path(call["source"]["path"]).parts
        feature = parts[parts.index("features") + 1] if "features" in parts else "core"
        groups.setdefault(feature, []).append(f"`{call['method']} {call['path']}`")
    text += table(["Feature", "Literais HTTP"], [[k, "; ".join(v)] for k, v in sorted(groups.items())])
    text += "\n## Planejado: jornadas da V1\n\n"
    for journey in plan["flows"]:
        text += f"### {journey['title']}\n\n"
        text += flow([(str(i), s) for i, s in enumerate(journey["steps"])], [(str(i), str(i + 1), "próximo estado proposto") for i in range(len(journey["steps"]) - 1)])
    text += "\n[Voltar ao mapa](../README.md) · [Responsabilidade de cada tela](../fluxos.md)\n"
    result[doc] = text

    doc = f"{GENERATED}/chamadas-http.md"
    text = header("Chamadas, entradas e respostas", revision)
    text += "## Atual: Flutter → referência Fastify\n\nChaves de data/query e nomes de schemas são detectados em padrões literais; schema inline pode ficar apenas como `z.object`. O backend é o retrato versionado, não uma leitura online nem um teste de rede.\n\n"
    rows = []
    for call in data["calls"]:
        matches = call["legacyMatches"]
        rows.append([f"`{call['method']} {call['path']}`", ", ".join(call["keys"]) or "sem chaves literais detectadas",
                     "; ".join(f"{r['path']} / body={r['requestType'] or 'ausente/inline'} / query={r['queryType'] or 'ausente'}" for r in matches) or "sem correspondência na referência",
                     "; ".join(json.dumps(r["responses"], ensure_ascii=False) for r in matches) or "não detectado", evidence(call["source"], doc, backend)])
    text += table(["Flutter", "Envia: chaves detectadas", "Backend: path e tipos", "Recebe: status e schemas", "Evidência Flutter"], rows)
    text += "\n## Referência Fastify: rotas e processamento\n\n"
    text += table(["Rota", "Entrada", "Saída", "Casos de uso instanciados", "Fonte externa"], [
        [f"`{r['method']} {r['path']}`", f"body={r['requestType'] or 'ausente/inline'}; query={r['queryType'] or 'ausente'}",
         json.dumps(r["responses"], ensure_ascii=False), ", ".join(r["usecases"]) or "não detectado", evidence(r["source"], doc, backend)] for r in backend["routes"]])
    text += "\n## Planejado: contratos da API v1\n\nEstas rotas são decisões propostas, ainda sem implementação Go validada. `swagger-go.md` define a geração futura; esta tabela não substitui o contrato gerado nem cria endpoints.\n\n"
    text += table(["Método", "Path", "Envia", "Recebe"], [[c["method"], f"`{c['path']}`", c["input"], c["output"]] for c in plan["contracts"]])
    text += "\n[Voltar ao mapa](../README.md) · [Contrato proposto completo](../contratos-v1.md)\n"
    result[doc] = text

    doc = f"{GENERATED}/banco.md"
    text = header("Banco: referência e modelo proposto", revision)
    text += "## Referência atual: schema Prisma externo\n\nRelações são lidas do schema capturado. Este diagrama não comprova que migrations foram aplicadas. Cardinalidade representa o tipo declarado; regras de negócio e índices estão na fonte.\n\n"
    lines, seen = ["erDiagram"], set()
    for model in backend["models"]:
        lines.append(f"    {model['name']} {{")
        for field in model["fields"]:
            if not field["relation"]:
                lines.append(f"        {field['type'].replace('?', '').replace('[]', '')} {field['name']}")
        lines.append("    }")
        for field in model["fields"]:
            if not field["relation"]:
                continue
            target = field["type"].replace("[]", "").replace("?", "")
            key = tuple(sorted((model["name"], target)))
            if key in seen:
                continue
            seen.add(key)
            if field["type"].endswith("[]"):
                lines.append(f'    {model["name"]} ||--o{{ {target} : "{field["name"]}"')
            elif field["type"].endswith("?"):
                lines.append(f'    {target} |o--o{{ {model["name"]} : "{field["name"]}"')
            else:
                lines.append(f'    {target} ||--o{{ {model["name"]} : "{field["name"]}"')
    text += mermaid(lines)
    for model in backend["models"]:
        text += f"\n### {model['name']}\n\n{evidence(model['source'], doc, backend)}\n\n"
        text += table(["Campo", "Tipo", "Relação"], [[f["name"], f"`{f['type']}`", "sim" if f["relation"] else "não"] for f in model["fields"]])
    text += "\n## Proposto: responsabilidades do domínio novo\n\n"
    text += table(["Entidades propostas", "Responsabilidade"], [[e["name"], e["description"]] for e in plan["entities"]])
    text += "\n[Modelo lógico e invariantes](../dominio-e-banco.md) · [Voltar ao mapa](../README.md)\n"
    result[doc] = text

    doc = f"{GENERATED}/go-e-swagger.md"
    text = header("Go e Swagger: evidência de código", revision)
    text += f"Arquivos Go de aplicação encontrados: **{len(data['go']['files'])}**. Registros net/http literais: **{len(data['go']['registrations'])}**.\n\n"
    if not data["go"]["files"]:
        text += "**O backend Go ainda não foi implementado.** Não há Swagger real do TrainForge Go para abrir ou executar; a configuração é trabalho da história V1-008. A proposta está documentada separadamente.\n\n"
    text += "## Anotações encontradas\n\n"
    text += table(["@Router", "@Param", "@Success / @Failure", "Registro compatível detectado", "Fonte"], [
        [f"`{r['method']} {r['path']}`", "; ".join(r["params"]), "; ".join(" ".join(v) for v in r["responses"]), "sim" if r["registrationDetected"] else "não — verificar", evidence(r["source"], doc, backend)] for r in data["go"]["annotations"]])
    text += "\n## Registros HTTP encontrados\n\n" + table(["Rota", "Fonte"], [[f"`{r['method']} {r['path']}`", evidence(r["source"], doc, backend)] for r in data["go"]["registrations"]])
    text += "\n## Operações da especificação gerada\n\n" + table(["Rota", "operationId", "Envia: parâmetros/body", "Recebe: status e schemas", "Fonte"], [[f"`{r['method']} {r['path']}`", r["operationId"], json.dumps(r["parameters"], ensure_ascii=False), json.dumps(r["responses"], ensure_ascii=False), evidence(r["source"], doc, backend)] for r in data["go"]["specificationOperations"]])
    text += "\nAnotação, registro de rota e operação na especificação são evidências distintas. A CI do futuro serviço deve comparar as três e testar resposta/autorização. O extrator documental não executa Go nem substitui o gerador Swaggo.\n\n[Decisão e rotina Swagger](../swagger-go.md) · [Voltar ao mapa](../README.md)\n"
    result[doc] = text

    doc = f"{GENERATED}/progresso.md"
    stories = [s for e in backlog["epics"] for s in e["stories"]]
    text = header("Progresso e dependências", revision)
    text += f"**{sum(s['status'] == 'done' for s in stories)}/{len(stories)} histórias concluídas**, em {len(backlog['epics'])} épicos. Próxima história: **{backlog['next']}**. Status vem do backlog revisado, não da existência de arquivo ou de um desenho.\n\n"
    text += table(["Épico", "Objetivo", "Histórias", "Concluídas"], [[e["id"], e["title"], len(e["stories"]), sum(s["status"] == "done" for s in e["stories"])] for e in backlog["epics"]])
    text += "\n## Dependências por história\n\n"
    for epic in backlog["epics"]:
        text += f"### {epic['id']} — {epic['title']}\n\n"
        local_ids = {s["id"] for s in epic["stories"]}
        dep_ids = {dep for s in epic["stories"] for dep in s["dependsOn"]}
        labels = [(id, id + (" (pré-requisito externo ao épico)" if id not in local_ids else "")) for id in sorted(local_ids | dep_ids)]
        text += flow(labels, [(dep, s["id"], "requer") for s in epic["stories"] for dep in s["dependsOn"]])
        text += "\n" + table(["História", "Status", "Entrega", "Depende de"], [[s["id"], s["status"], s["title"], ", ".join(s["dependsOn"]) or "nenhuma"] for s in epic["stories"]])
    text += "\n[Backlog completo: aceite, tarefas, subtarefas e testes](../../execucao/v1/backlog.md) · [Voltar ao mapa](../README.md)\n"
    result[doc] = text
    return result, data


def check_links(root, documents):
    failures = []
    for relative in documents:
        path = root / relative
        if not path.exists() or path.suffix != ".md":
            continue
        text = re.sub(r"```.*?```", "", read(path), flags=re.S)
        for match in re.finditer(r"\]\(([^)]+)\)", text):
            target = match[1].strip("<>")
            if re.match(r"^[a-z]+:|^#", target, re.I):
                continue
            from urllib.parse import unquote
            target = unquote(target.split("#")[0])
            if target and not (path.parent / target).exists():
                failures.append(relative + " → " + target)
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
    parser.add_argument("--export-mermaid", type=Path, help="exportar fontes dos diagramas para validação")
    args = parser.parse_args()
    if args.capture_backend:
        capture(ROOT, args.capture_backend)
    expected, data = outputs(ROOT)
    if args.write:
        for relative, content in expected.items():
            path = ROOT / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
    if args.export_mermaid:
        args.export_mermaid.mkdir(parents=True, exist_ok=True)
        count = 0
        for relative, content in expected.items():
            for i, syntax in enumerate(re.findall(r"```mermaid\n(.*?)```", content, re.S)):
                target = args.export_mermaid / (Path(relative).stem + f"-{i + 1:02}.mmd")
                target.write_text(syntax, encoding="utf-8")
                count += 1
        print(f"Diagramas exportados: {count}")
    if args.check:
        stale = [p for p, text in expected.items() if not (ROOT / p).exists() or read(ROOT / p) != text]
        active_docs = list(expected) + [p.relative_to(ROOT).as_posix() for p in (ROOT / "docs/arquitetura").glob("*.md")]
        active_docs += ["README.md", "AGENTS.md", "guia-do-projeto.md", "documentacao-tecnica.md", "docs/README.md",
                        "docs/execucao/v1/handoff.md", "docs/execucao/v1/plano-macro.md", "docs/execucao/v1/diario.md"]
        broken = check_links(ROOT, active_docs)
        if stale or broken:
            raise SystemExit("Documentação divergente: " + "; ".join(stale + broken) + ". Execute --write e revise.")
        print("OK: geração reproduzível, backlog, dependências, requisitos, entradas e links locais.")
    print(json.dumps(data["coverage"], ensure_ascii=False))


if __name__ == "__main__":
    main()
