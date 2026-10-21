"""Exercita contrato de pesquisa sobre saídas reais, sem ML ou app instalado.

O simulador torna explícito o que depende de decisão humana. Não é uma UI
validada com idosos/cuidadores nem código de produto.
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent


def confirm(candidate, *, person=None, reporter=None, chosen_food=None, explicit=False):
    if not explicit:
        return {"status": "requires_confirmation", "food": None, "person": None}
    if not person or not reporter:
        raise ValueError("Pessoa da refeição e autor são obrigatórios e distintos como campos")
    if not chosen_food:
        return {"status": "manual_or_no_food", "food": None, "person": person,
                "reporter": reporter, "quantity": None, "nutritionTarget": None}
    return {"status": "confirmed_by_reporter", "food": chosen_food,
            "person": person, "reporter": reporter, "modelSuggestion": candidate["top5"],
            "quantity": None, "nutritionTarget": None,
            "correctionApplied": chosen_food != candidate["top5"][0]["label"]}


def main():
    source = json.loads((HERE / "resultado-ensaio-local.json").read_text(encoding="utf-8"))
    by_id = {x["id"]: x for x in source["cases"]}
    checks = []
    for case in [x for x in source["cases"] if "top5" in x]:
        result = confirm(case)
        checks.append({"case": case["id"], "check": "Sem ação explícita, não confirmar nem atribuir pessoa",
                       "passed": result["status"] == "requires_confirmation" and result["person"] is None})
    for context in ["idoso_casa", "idoso_academia", "idoso_praca", "cuidador_casa_proprio"]:
        self_report = confirm(by_id["5"], person="test-person-A", reporter="test-person-A",
                              chosen_food="pizza", explicit=True)
        checks.append({"context": context, "check": "Relato próprio explícito, sem quantidade ou objetivo inferidos",
                       "passed": self_report["person"] == self_report["reporter"]
                       and self_report["quantity"] is None and self_report["nutritionTarget"] is None})
    corrected = confirm(by_id["1"], person="test-person-A", reporter="test-person-B",
                        chosen_food="caldo_verde", explicit=True)
    checks.append({"check": "Corrigir ramen observado para alimento manual, com assistido/autor separados",
                   "passed": corrected["correctionApplied"] and corrected["person"] != corrected["reporter"]
                   and corrected["food"] == "caldo_verde"})
    chair = confirm(by_id["2"], person="test-person-A", reporter="test-person-A", explicit=True)
    checks.append({"check": "Nenhuma destas na foto sem comida, sem forçar gnocchi", "passed": chair["food"] is None})
    for args in [{"reporter": "test-person-B"}, {"person": "test-person-A"}]:
        try:
            confirm(by_id["5"], chosen_food="pizza", explicit=True, **args)
            rejected = False
        except ValueError:
            rejected = True
        checks.append({"check": "Ausência de pessoa ou autor não é preenchida pelo modelo", "passed": rejected})
    result = {"date": "2026-10-15", "niche": "N39", "kind": "Research contract simulator over actual model outputs",
              "checks": checks, "passed": sum(x["passed"] for x in checks),
              "failed": sum(not x["passed"] for x in checks), "correctedExample": corrected,
              "actualUserInteractionTested": False, "appImplemented": False,
              "caregiverIdentityInferred": False, "sourceImageUploaded": False,
              "nutritionPrescribed": False, "releaseApproved": False}
    (HERE / "confirmacao-conferida.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "failed": result["failed"], "appTested": False}))
    assert result["failed"] == 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
