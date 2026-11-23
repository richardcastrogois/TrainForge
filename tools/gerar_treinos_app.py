"""Gera assets/training/sessions.json para o app a partir da pesquisa de treinos.

Só entram as sessões com `prontaComprovada`; cada uma leva a fonte (nome, responsável, link e licença
observada), a recomendação da fonte e as restrições de público. Nada é escrito à mão: o app mostra o que a
pesquisa registrou. Uso: python tools/gerar_treinos_app.py [--check]
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / "docs/conteudo/pesquisa-treinos"
OUT = ROOT / "assets/training/sessions.json"
PLACES = {"casa": "Casa", "praca": "Praça ou parque", "academia": "Academia", "pausa": "Pausa do cuidador"}


def source_for(session: dict, sources: dict) -> dict:
    src = sources.get(session["fonte"])
    if src:
        return {"id": session["fonte"], "name": src.get("nome"), "responsible": src.get("responsavel"),
                "url": src.get("url"), "license": src.get("licenca"), "locator": session.get("localizador")}
    # Composições e fontes citadas só no exercício: a origem de cada exercício fica no próprio exercício.
    cited = sorted({e["fonte"] for e in session.get("exercicios", []) if e.get("fonte")})
    name = "Composição de exercícios de fontes citadas" if session["fonte"] == "COMPOSICAO" else (cited[0] if cited else session["fonte"])
    return {"id": session["fonte"], "name": name, "responsible": None, "url": None, "license": None,
            "locator": session.get("localizador")}


def build() -> dict:
    data = json.loads((RESEARCH / "sessoes.json").read_text(encoding="utf-8"))
    library = json.loads((RESEARCH / "biblioteca.json").read_text(encoding="utf-8"))
    sources = {**library["fontes"], **data["fontesNovas"]}
    sessions = []
    for s in data["sessoes"]:
        if not s.get("prontaComprovada"):
            continue
        exercises = [{"name": e.get("nome") or e["descricao"], "dose": e.get("dose"), "source": e.get("fonte"), "benefit": e.get("beneficio")}
                     for e in s.get("exercicios", [])]
        assert exercises, s["id"]
        sessions.append({
            "id": s["id"], "name": s["nome"], "cells": s["celulas"], "minutes": s.get("duracaoMin"),
            "equipment": s.get("equipamento"), "benefit": s.get("beneficio"), "dose": s.get("dose"),
            "schedule": s.get("agendaFonte"), "sourceAdvice": s.get("recomendacaoProfissionalDaFonte"),
            "audience": s.get("publicoRestrito"), "requiresEquipment": s.get("requerMaterialDeclarado"),
            "noLoad": bool(s.get("semCarga")), "exercises": exercises, "source": source_for(s, sources),
        })
    cells = data["celulas"]
    return {
        "contract": "trainforge.training-library/1",
        "generatedFrom": "docs/conteudo/pesquisa-treinos/sessoes.json",
        "researchUpdatedAt": data.get("atualizadoEm"),
        "places": [{"id": p, "name": n, "cells": [{"id": c, "name": cells[c]} for c in cells if c.split("-")[0] == p]}
                   for p, n in PLACES.items()],
        "sessions": sessions,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="só confere se o arquivo está atualizado")
    args = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, indent=1) + "\n"
    if args.check:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != text:
            print("assets/training/sessions.json desatualizado: rode python tools/gerar_treinos_app.py")
            return 1
        print("OK: biblioteca de treinos do app igual à pesquisa")
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(text, encoding="utf-8", newline="\n")
    data = json.loads(text)
    print(f"{len(data['sessions'])} sessões prontas gravadas em {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
