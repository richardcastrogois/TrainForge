"""N03: evidencias e regras de conversao. Pesquisa local, sem integrar o app."""
from collections import Counter
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP, ROUND_CEILING
import hashlib
import importlib.util
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
OUT = HERE / "2026-09-27/n03-porcoes"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def positive(value):
    if isinstance(value, bool):
        raise ValueError("invalid_quantity")
    try:
        number = Decimal(str(value).replace(",", "."))
    except InvalidOperation as error:
        raise ValueError("invalid_quantity") from error
    if not number.is_finite() or number <= 0:
        raise ValueError("invalid_quantity")
    return number


def cell(raw):
    value = " ".join((raw or "").split())
    if value in ("", "-", "N"):
        return {"status": "unknown", "value": None}
    if value.lower() in ("tr", "traces"):
        return {"status": "trace", "value": None}
    if value.startswith("<"):
        return {"status": "below_limit", "value": format(positive(value[1:].strip()), "f")}
    n = Decimal(value.replace(",", "."))
    if not n.is_finite() or n < 0:
        raise ValueError("invalid_nutrient")
    return {"status": "numeric", "value": format(n, "f")}


def scale(raw, quantity, unit="g", basis_unit="g"):
    multipliers = {"g": ("g", "1"), "kg": ("g", "1000"), "ml": ("ml", "1"), "l": ("ml", "1000")}
    if unit not in multipliers or multipliers[unit][0] != basis_unit:
        raise ValueError("needs_source_conversion")
    ratio = positive(quantity) * Decimal(multipliers[unit][1]) / Decimal(100)
    value = cell(raw)
    if value["value"] is not None:
        value["value"] = format(Decimal(value["value"]) * ratio, "f")
    return value


def portion_mass(portion, food_key, expected_key, quantity_in_source_units):
    if food_key != expected_key:
        raise ValueError("portion_food_mismatch")
    return positive(quantity_in_source_units) / positive(portion["amount"]) * positive(portion["gramWeight"])


def subtotal(values):
    known = sum((Decimal(v["value"]) for v in values if v["status"] == "numeric"), Decimal(0))
    result = {"status": "complete" if all(v["status"] == "numeric" for v in values) else "incomplete",
              "knownSubtotal": format(known, "f"), "unknownCount": sum(v["status"] == "unknown" for v in values),
              "traceCount": sum(v["status"] == "trace" for v in values), "upperExclusive": None}
    if any(v["status"] == "below_limit" for v in values) and all(v["status"] in ("numeric", "below_limit") for v in values):
        upper = known + sum((Decimal(v["value"]) for v in values if v["status"] == "below_limit"), Decimal(0))
        result["upperExclusive"] = format(upper, "f")
    return result


def main():
    n02 = read(HERE / "2026-09-26/n02-composicao/resumo-composicao.json")
    assert n02["researchStatus"] == "completed_with_explicit_scope_limits"
    ciqual_sample_path = HERE / "2026-09-26/n02-composicao/amostra-composicao.json"
    ciqual_sample = read(ciqual_sample_path)
    assert sha(HERE / "ciqual-2025.xlsx") == ciqual_sample["inputSha256"]
    rice = next(r for r in ciqual_sample["records"] if r["sourceFoodId"] == "9104")
    rice_energy = rice["valuesBySourceColumn"]["K"]["raw"]
    rice_trace = rice["valuesBySourceColumn"]["S"]["raw"]
    rice_bound = rice["valuesBySourceColumn"]["T"]["raw"]
    assert rice_energy == "155" and rice_trace == "traces" and rice_bound == "< 0,08"
    records = {}
    for name in ("usda-rice-drink", "cofid-guide", "usda-foundation-guide"):
        metadata = read(OUT / (name + ".evidencia.json"))
        body = (OUT / metadata["bodyFile"]).resolve()
        assert metadata["status"] == 200 and not metadata.get("error") and sha(body) == metadata["sha256"]
        records[name] = (metadata, body)
    from pypdf import PdfReader
    pdf = PdfReader(records["cofid-guide"][1])
    p7 = " ".join(pdf.pages[6].extract_text().split())
    p9 = " ".join(pdf.pages[8].extract_text().split())
    assert "100ml" in p7 and "alcoholic" in p7 and "Specific gravity" in p9 and "weighed with" in p9
    html = records["usda-foundation-guide"][1].read_text(encoding="utf-8")
    assert "N = (V*W)/100" in html and "edible portion" in html
    # CoFID values/factors from the same hashed workbook; no repeated download.
    workbook = HERE / "cofid-2021.xlsx"
    assert sha(workbook) == read(HERE / "cofid-2021.evidencia.json")["sha256"]
    spec = importlib.util.spec_from_file_location("xlsx_reader", HERE / "analisar-expansao.py")
    reader = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reader)
    factor_rows = reader.read_sheet(workbook, "xl/worksheets/sheet3.xml")
    nutrient_rows = reader.read_sheet(workbook, "xl/worksheets/sheet4.xml")
    assert factor_rows[0]["H"] == "Edible proportion" and factor_rows[0]["I"] == "Specific gravity"
    food_list = [r for r in nutrient_rows if re.fullmatch(r"\d{2}-\d{3}", r.get("A", ""))]
    factor_list = [r for r in factor_rows if re.fullmatch(r"\d{2}-\d{3}", r.get("A", ""))]
    food_counts = Counter(r["A"] for r in food_list)
    factor_counts = Counter(r["A"] for r in factor_list)
    duplicates_food = sorted(k for k,v in food_counts.items() if v > 1)
    duplicates_factor = sorted(k for k,v in factor_counts.items() if v > 1)
    print(json.dumps({"foodRows": len(food_list), "factorRows": len(factor_list),
                      "foodUniqueIds": len(food_counts), "factorUniqueIds":len(factor_counts),
                      "duplicateFoodIds":duplicates_food, "duplicateFactorIds":duplicates_factor}))
    save("duplicidades-cofid.json", {"sourceId": "AL05", "workbookSha256": sha(workbook),
         "policy": "Exclude repeated IDs in this pilot; do not silently choose the first/last row",
         "proximates": [{k:r.get(k) for k in ("A","B","C","D","J","K","L","M")}
                        for r in food_list if r["A"] in duplicates_food],
         "factors": [{k:r.get(k) for k in ("A","B","C","D","H","I")}
                     for r in factor_list if r["A"] in duplicates_factor]})
    # Ambiguous IDs are recorded and excluded, never overwritten by a dict.
    foods = {r["A"]: r for r in food_list if food_counts[r["A"]] == 1}
    factors = {r["A"]: r for r in factor_list if factor_counts[r["A"]] == 1}
    assert foods and factors
    print(json.dumps({"cofidFoodRows": len(foods), "cofidFactorRows": len(factors),
                      "foodsWithoutFactors": sorted(set(foods) - set(factors)),
                      "factorsWithoutFoods": sorted(set(factors) - set(foods))}))
    coverage = {k: Counter(cell(r.get(col))["status"] for r in factors.values())
                for k, col in (("edibleProportion", "H"), ("specificGravity", "I"))}
    assert all(Decimal(r["H"]) <= 1 for r in factors.values() if cell(r.get("H"))["status"] == "numeric")
    selected = ["14-898", "14-896", "17-506", "12-313"]
    examples = [{"foodId": i, "name": foods[i]["B"], "description": foods[i].get("C"),
                 "edibleProportion": factors[i].get("H"), "specificGravity": factors[i].get("I"),
                 "energyKcalAsPublished": foods[i]["M"]} for i in selected]
    assert foods["14-898"]["C"] == "Calculated from 14-896"
    assert foods["14-898"]["M"] == "205" and foods["14-896"]["M"] == "554"
    assert abs(Decimal("554") * Decimal(factors["14-898"]["H"]) - Decimal("205")) < 1
    assert foods["17-506"]["M"] == "30" and factors["12-313"]["I"] == "1.03"
    drink = read(records["usda-rice-drink"][1])
    egg_path = HERE.parents[1] / "planejamento/evidencias/usda-egg-detail.json"
    egg = read(egg_path)["data"]
    assert egg["fdcId"] == 748967
    racc = next(p for p in egg["foodPortions"] if p["id"] == 312625)
    assert racc["amount"] == 1 and racc["gramWeight"] == 50
    dp = drink["foodPortions"][0]
    ep = next(p for p in egg["foodPortions"] if p.get("modifier") == "whole without shell")
    assert drink["fdcId"] == 171942 and dp["amount"] == 8 and dp["gramWeight"] == 240
    assert dp["measureUnit"]["name"] == "undetermined" and "approximate" in dp["modifier"]
    half_mass = portion_mass(dp, "usda:171942", "usda:171942", "4")
    assert half_mass == Decimal(120)
    energy = next(x["amount"] for x in drink["foodNutrients"] if x["nutrient"]["id"] == 1008)
    assert Decimal(scale(str(energy), half_mass)["value"]) == Decimal("56.4")
    assert portion_mass(ep, "usda:748967", "usda:748967", "2") == Decimal("100.6")
    tests = []
    def check(name, condition):
        assert condition, name
        tests.append(name)
    def reject(name, operation):
        try:
            operation()
        except (ValueError, InvalidOperation):
            tests.append(name)
        else:
            raise AssertionError(name)
    check("grams", scale(rice_energy, "150")["value"] == "232.5")
    check("kilograms", scale(rice_energy, "0,15", "kg")["value"] == "232.50")
    check("native_ml", scale("30", "250", "ml", "ml")["value"] == "75.0")
    check("litres", scale("30", "0.25", "l", "ml")["value"] == "75.00")
    check("explicit_zero", scale("0", "150")["value"] == "0.0")
    check("trace", scale(rice_trace, "150")["status"] == "trace")
    check("unknown", scale("-", "150")["value"] is None)
    check("upper_exclusive", scale(rice_bound, "150") == {"status": "below_limit", "value": "0.120"})
    for value in ("0", "-1", "NaN", "Infinity", "abc", "1,2,3", True):
        reject("invalid_quantity_" + str(value), lambda v=value: scale("155", v))
    reject("ml_to_g_without_density", lambda: scale("155", "150", "ml", "g"))
    reject("g_to_ml_without_density", lambda: scale("30", "150", "g", "ml"))
    reject("generic_cup", lambda: scale("155", "1", "cup", "g"))
    reject("wrong_food_portion", lambda: portion_mass(dp, "usda:171942", "ciqual:9104", "1"))
    reject("portion_zero_denominator", lambda: portion_mass({**dp, "amount": 0}, "x", "x", "1"))
    check("complete_subtotal", subtotal([cell("1"), cell("2")])["status"] == "complete")
    check("incomplete_subtotal", subtotal([cell("1"), cell("-")]) == {"status":"incomplete", "knownSubtotal":"1", "unknownCount":1, "traceCount":0, "upperExclusive":None})
    check("trace_no_fake_upper", subtotal([cell("1"), cell("Tr")])["upperExclusive"] is None)
    check("bounded_subtotal", subtotal([cell("1"), cell("< 0.08")])["upperExclusive"] == "1.08")
    check("round_only_display", Decimal("4.965").quantize(Decimal("0.01"), rounding=ROUND_HALF_UP) == Decimal("4.97"))
    check("bound_round_outwards", Decimal("0.004").quantize(Decimal("0.01"), rounding=ROUND_CEILING) == Decimal("0.01"))
    # Explicit negative findings, not undocumented conversion factors.
    cases = {"rice150g": scale(rice_energy, "150"), "beer250ml": scale(foods["17-506"]["M"], "250", "ml", "ml"),
             "twoEggsMassG": "100.6", "drinkSourceUnits4MassG": str(half_mass),
             "drinkSourceUnits4Kcal": scale(str(energy), half_mass), "almonds100gWithShellKcal": "205",
             "almondsDoubleAppliedFactorWrongKcal": format(Decimal("205") * Decimal("0.37"), "f")}
    save("casos-porcoes.json", {"inputsAreArithmeticFixturesNotServingRecommendations": True,
         "ciqualSampleArtifactSha256": sha(ciqual_sample_path), "ciqualWorkbookSha256":ciqual_sample["inputSha256"],
         "ciqualRice": {"sourceKey":rice["sourceKey"],"nameOriginal":rice["nameOriginal"],
                        "valuesBySourceColumn":{k:rice["valuesBySourceColumn"][k] for k in ("K","S","T")}},
         "cofidWorkbookSha256": sha(workbook), "cofidExamples": examples,
         "usdaDrink": {"foodId":171942,"dataType":drink["dataType"],"portionAsReceived":dp},
         "usdaEgg": {"foodId":748967,"dataType":egg["dataType"],"portionsAsReceived":egg["foodPortions"]},
         "eggArtifactSha256":sha(egg_path), "eggArtifactIsNotOriginalBody":True, "cases":cases,
         "methodReferences":[records[x][0]["url"] for x in ("cofid-guide", "usda-foundation-guide")]})
    save("validacao-porcoes.json", {"passed":len(tests),"cases":tests,"testScope":"research data/semantics, not application integration"})
    summary = {"niche":"N03", "researchDate":"2026-09-27", "researchStatus":"completed_with_explicit_scope_limits",
               "releaseApproved":False, "cofidFoodIdsMatched":len(set(foods) & set(factors)),
               "cofidFoodRows":len(food_list), "cofidFoodUniqueIds":len(food_counts),
               "duplicateFoodIdsExcluded":duplicates_food, "duplicateFactorIdsExcluded":duplicates_factor,
               "cofidFactorRows":len(factors), "foodsWithoutFactors":sorted(set(foods)-set(factors)),
               "factorsWithoutFoods":sorted(set(factors)-set(foods)), "factorCoverage":{k:dict(v) for k,v in coverage.items()},
               "providerPortionRecordsAudited":len(egg["foodPortions"])+len(drink["foodPortions"]),
               "httpBodiesVerified":3, "cofidWorkbookHashVerified":True, "checksPassed":len(tests),
               "limits":["No universal household-measure catalogue approved for Portugal", "No matching across provider food IDs",
                         "Specific gravity is dimensionless, not measured density in g/ml; no automatic conversion without reference conditions",
                         "No general raw/cooked yield or nutrient-retention table obtained; use the actual preparation entry",
                         "No portion suggestions or personal nutrition targets", "No app/bank integration; local research only"]}
    save("resumo-porcoes.json", summary)
    print(json.dumps(summary,ensure_ascii=False))


if __name__ == "__main__":
    main()
