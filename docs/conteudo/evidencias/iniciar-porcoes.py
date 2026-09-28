"""N03: primeiro piloto local de massa/porcao; pesquisa ainda em andamento."""
from decimal import Decimal
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
DAY = HERE / "2026-09-26"
read = lambda p: json.loads(p.read_text(encoding="utf-8-sig"))


def main():
    n02 = read(DAY / "n02-composicao/resumo-composicao.json")
    assert n02["researchStatus"] == "completed_with_explicit_scope_limits"
    rows = read(DAY / "n02-composicao/amostra-composicao.json")
    rice = next(r for r in rows["records"] if r["sourceFoodId"] == "9104")
    fields = read(DAY / "n02-composicao/dicionario-composicao.json")["definitions"]
    assert all(d["basis"] == {"quantity": "100", "unit": "g"} for d in fields)
    # Fictitious input mass for arithmetic verification, not a suggested portion.
    grams, basis = Decimal("150"), Decimal("100")
    result = {}
    for col in ("K", "P", "Q", "R", "S", "T"):
        cell = rice["valuesBySourceColumn"][col]
        result[col] = {"status": cell["status"], "valueDecimal": None, "limitDecimal": None}
        for field in ("valueDecimal", "limitDecimal"):
            if cell[field] is not None:
                result[col][field] = format(Decimal(cell[field]) * grams / basis, "f")
    assert Decimal(result["K"]["valueDecimal"]) == Decimal("232.5")
    assert result["S"]["status"] == "trace" and result["S"]["valueDecimal"] is None
    assert result["T"]["status"] == "below_limit" and Decimal(result["T"]["limitDecimal"]) == Decimal("0.12")
    path = HERE.parents[1] / "planejamento/evidencias/usda-egg-detail.json"
    data = read(path)["data"]
    portion = next(p for p in data["foodPortions"] if p.get("modifier") == "whole without shell")
    assert Decimal(str(portion["gramWeight"])) == Decimal("50.3")
    mass = Decimal("2") / Decimal(str(portion["amount"])) * Decimal(str(portion["gramWeight"]))
    assert mass == Decimal("100.6")
    out = {
        "niche": "N03", "researchDate": "2026-09-27", "researchStatus": "in_progress", "releaseApproved": False,
        "inputQuantitiesAreTestFixturesNotRecommendations": True,
        "ciqual": {"foodId": "9104", "inputMassG": "150", "basisMassG": "100",
                   "inputWorkbookSha256": rows["inputSha256"], "calculatedBySourceColumn": result},
        "usda": {"foodId": data["fdcId"], "artifactSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                 "artifactHashIsOriginalHttpBodyHash": False, "portionAsReceived": portion,
                 "inputCount": "2", "calculatedMassG": str(mass),
                 "otherPortionsAsReceived": [p for p in data["foodPortions"] if p != portion]},
        "passed": ["150 g scales known values", "trace is not zero", "exclusive bound stays a bound",
                   "count uses amount and gramWeight of the selected food-specific portion"],
        "remaining": ["Reject invalid or unsupported quantities/units", "ml requires food-specific density or a volume basis",
                      "Household measures need source/food/preparation-specific mass", "Edible portion and preparation yields",
                      "Aggregation and missing values", "Rounding/display rules", "Coverage beyond these two cases"],
    }
    target = HERE / "2026-09-27/n03-porcoes/piloto-inicial.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"niche": "N03", "status": "in_progress", "cases": 2, "checks": 4}))


if __name__ == "__main__":
    main()
