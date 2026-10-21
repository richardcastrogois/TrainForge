"""Casos sintéticos do contrato N40, sem estimador visual ou prescrição."""
import decimal
import json
import pathlib
import statistics
import sys

HERE = pathlib.Path(__file__).resolve().parent


def consumed(served, remaining, *, same_person, same_food, no_transfers):
    if not (same_person and same_food and no_transfers):
        return {"status": "unknown", "grams": None}
    if served is None or remaining is None:
        return {"status": "unknown", "grams": None}
    values = [decimal.Decimal(str(x)) for x in [served, remaining]]
    if any(not x.is_finite() or x < 0 for x in values) or values[1] > values[0]:
        return {"status": "inconsistent", "grams": None}
    return {"status": "derived_from_confirmed_masses", "grams": str(values[0] - values[1])}


def main():
    checks = []
    scenarios = [
        ("300 servidos, 100 restantes, mesma base", 300, 100, True, True, True, "derived_from_confirmed_masses", "200"),
        ("Restante desconhecido não é zero", 300, None, True, True, True, "unknown", None),
        ("Servido desconhecido", None, 10, True, True, True, "unknown", None),
        ("Prato compartilhado", 300, 100, False, True, True, "unknown", None),
        ("Transferências não registradas", 300, 100, True, True, False, "unknown", None),
        ("Comidas diferentes", 300, 100, True, False, True, "unknown", None),
        ("Não clamp de restos maiores", 100, 200, True, True, True, "inconsistent", None),
        ("Valor negativo", -1, 0, True, True, True, "inconsistent", None),
        ("Zero explicitamente confirmado", 300, 300, True, True, True, "derived_from_confirmed_masses", "0"),
        ("Decimal conservado", "150.5", "20.2", True, True, True, "derived_from_confirmed_masses", "130.3"),
        ("NaN recusado", "NaN", 0, True, True, True, "inconsistent", None)]
    for title, served, remaining, person, food, transfers, status, amount in scenarios:
        out = consumed(served, remaining, same_person=person, same_food=food, no_transfers=transfers)
        checks.append({"check": title, "result": out, "passed": out["status"] == status and out["grams"] == amount})
    truth = [100, 400]
    prediction = [200, 400]
    mae = statistics.mean(abs(a - b) for a, b in zip(truth, prediction))
    relative_mae = 100 * mae / statistics.mean(truth)
    mape = statistics.mean(100 * abs(a - b) / a for a, b in zip(truth, prediction))
    checks.append({"check": "MAE normalizado pela média não é MAPE individual", "passed": mae == 50 and relative_mae == 20 and mape == 50})
    projection1 = 10 / 20
    projection2 = 20 / 40
    checks.append({"check": "Mesmo tamanho projetado com volume 8x em exemplo geométrico", "passed": projection1 == projection2 and (20 / 10) ** 3 == 8})
    for context in ["idoso_casa", "idoso_academia", "idoso_praca", "cuidador_casa_proprio"]:
        checks.append({"context": context, "check": "Foto/label sozinhos não fornecem massa consumida", "passed": consumed(None, None, same_person=True, same_food=True, no_transfers=True)["grams"] is None})
    result = {"date": "2026-10-15", "niche": "N40", "kind": "Synthetic contract/arithmetic verification, no image estimator",
              "checks": checks, "passed": sum(x["passed"] for x in checks), "failed": sum(not x["passed"] for x in checks),
              "maeExample": {"truth": truth, "prediction": prediction, "maeGrams": mae, "maePercentOfMean": relative_mae, "mapePercent": mape},
              "notAClaim": "O exemplo geométrico não infere massa real. Subtração exige massas com base/identidade confirmadas. Não há estimador visual instalado/testado.",
              "appTested": False, "visualMassModelTested": False, "clinicalValidation": False, "releaseApproved": False}
    (HERE / "verificacoes-quantidade.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "failed": result["failed"], "visualMassModelTested": False}))
    assert result["failed"] == 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
