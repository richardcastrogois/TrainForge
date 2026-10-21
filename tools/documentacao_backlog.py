"""Validação e leitura do backlog canônico, sem serviço local."""

def validate(backlog, plan, root):
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
            if not (root / entry).exists():
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
    lines = ["# Backlog V1", "", "> Gerado de `backlog.json` por `tools/gerar_documentacao.py --write`. Edite o JSON.", "",
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
