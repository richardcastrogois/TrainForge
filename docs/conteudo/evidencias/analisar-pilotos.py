"""Confere pilotos de pesquisa com entradas locais; nao publica conteudo no app.

Nao faz chamadas de rede. Mantem dose/sequencia da fonte; nao completa campos
ausentes nem inventa prescricao. Os resultados numericos sao acompanhados de
proveniencia e bloqueios de publicacao.
"""
import hashlib
import html
import json
from decimal import Decimal, InvalidOperation
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "2026-09-26"
NETWORK = OUT / "network"


def dump(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def text(markup):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]*>", " ", markup))).strip()


def verified_body(source_id):
    record = json.loads((NETWORK / (source_id + ".evidencia.json")).read_text(encoding="utf-8"))
    if record["status"] != 200:
        raise ValueError("No successful response: " + source_id)
    raw = (NETWORK / record["bodyFile"]).read_bytes()
    if hashlib.sha256(raw).hexdigest() != record["sha256"]:
        raise ValueError("Input hash mismatch: " + source_id)
    return raw, {k: record[k] for k in ("url", "collectedAtUtc", "sha256")}


def seconds(value):
    value = value.removesuffix(" walk").strip()
    match = re.fullmatch(r"(\d+) minutes?(?: (?:and )?(\d+) seconds?)?", value)
    if not match:
        raise ValueError("Unrecognised duration: " + value)
    return int(match[1]) * 60 + int(match[2] or 0)


def running():
    raw, provenance = verified_body("nhs-c25k")
    _, pdf_provenance = verified_body("nhs-c25k-table")
    for name in ("nhs-terms", "nhs-exclusions"):
        verified_body(name)
    patterns, sessions = [], []
    for detail in re.findall(r"<details\b.*?</details>", raw.decode("utf-8"), re.S):
        heading = re.search(r"<summary\b.*?</summary>", detail, re.S)
        if not heading:
            continue
        identity = re.fullmatch(r"Week (\d+): Run (\d+)", text(heading[0]))
        if not identity:
            continue
        declared = re.search(r"Total time: (.*?) \(excluding stretches\)", text(detail))
        if not declared:
            raise ValueError("Missing declared time: " + text(heading[0]))
        rows = re.findall(r"<dt\b[^>]*>(.*?)</dt>\s*<dd\b[^>]*>(.*?)</dd>", detail, re.S)
        blocks, stretches = [], []
        for raw_label, raw_value in rows:
            label, value = text(raw_label).rstrip(":"), text(raw_value)
            if label == "Stretch":
                stretches.append(value)
                continue
            repeat = re.fullmatch(r"Run for (.*?) and walk for (.*?)\. Do this (\d+) times in total", value)
            if repeat:
                if label != "Run":
                    raise ValueError("Unexpected repetition label")
                for _ in range(int(repeat[3])):
                    blocks.extend([
                        {"phase": "main", "activity": "run", "seconds": seconds(repeat[1])},
                        {"phase": "main", "activity": "walk", "seconds": seconds(repeat[2])},
                    ])
            else:
                phases = {"Warm-up": "warm_up", "Cool-down": "cool_down", "Run": "main", "Walk": "main", "Final run": "main"}
                if label not in phases:
                    raise ValueError("Unrecognised interval: " + label)
                blocks.append({"phase": phases[label], "activity": "run" if label in ("Run", "Final run") else "walk", "seconds": seconds(value)})
        total = sum(b["seconds"] for b in blocks)
        if total != seconds(declared[1]) or stretches != ["Before run", "After run"]:
            raise ValueError("Mismatch in session: " + text(heading[0]))
        if blocks not in patterns:
            patterns.append(blocks)
        sessions.append({"week": int(identity[1]), "run": int(identity[2]), "patternId": patterns.index(blocks) + 1, "declaredSecondsExcludingStretches": total})
    expected_ids = [(w, r) for w in range(1, 10) for r in range(1, 4)]
    if [(s["week"], s["run"]) for s in sessions] != expected_ids:
        raise ValueError("Incomplete or reordered program")
    # Independent numeric cross-check against both pages of the official PDF.
    # Positive = running, negative = walking. Warm-up/cool-down added separately.
    pdf_main = {
        1: [[60, -90] * 7 + [60]] * 3,
        2: [[90, -120] * 5 + [90]] * 3,
        3: [[90, -90, 180, -180, 90, -90, 180]] * 3,
        4: [[180, -90, 300, -150, 180, -90, 300]] * 3,
        5: [[300, -180, 300, -180, 300], [480, -300, 480], [1200]],
        6: [[300, -180, 480, -180, 300], [600, -180, 600], [1500]],
        7: [[1500]] * 3, 8: [[1680]] * 3, 9: [[1800]] * 3,
    }
    for session in sessions:
        blocks = patterns[session["patternId"] - 1]
        observed = [b["seconds"] * (1 if b["activity"] == "run" else -1) for b in blocks if b["phase"] == "main"]
        if observed != pdf_main[session["week"]][session["run"] - 1]:
            raise ValueError("HTML differs from independently transcribed PDF")
        if blocks[0] != {"phase": "warm_up", "activity": "walk", "seconds": 300} or blocks[-1] != {"phase": "cool_down", "activity": "walk", "seconds": 300}:
            raise ValueError("Warm-up or cool-down mismatch")
    result = {
        "kind": "existing_human_running_program_research_pilot", "sourceId": "PR06",
        "source": provenance, "crossCheckSource": pdf_provenance,
        "method": "27 HTML session tables parsed; duration sums checked; every interval compared to numeric transcription visually checked against both PDF pages on 2026-09-26.",
        "rights": "Eligible NHS text: OGL v3.0 subject to NHS terms and exclusions. No audio, app, logos, photos or video included.",
        "attribution": "Contains public sector information licensed under the Open Government Licence v3.0.",
        "releaseStatus": "research_only_not_release_approved",
        "weeks": 9, "sessionsPerWeek": 3, "restDaysBetweenRunsMinimum": 1,
        "endTarget": {"runningMinutes": 30, "guaranteedDistanceKm": None},
        "stretchDurationSeconds": None,
        "publicationGaps": ["Reviewed Portuguese instructions, warm-up/cool-down guidance and applicability", "Exact dated-copy or refresh/attribution workflow under NHS terms", "App integration, recovery states and on-device tests"],
        "patterns": [{"id": i + 1, "blocks": blocks} for i, blocks in enumerate(patterns)],
        "sessions": sessions,
    }
    dump(OUT / "corrida-piloto.json", result)
    return {"sessions": len(sessions), "weeks": 9, "uniqueIntervalPatterns": len(patterns), "durationChecksPassed": 27, "pdfIntervalChecksPassed": 27, "releaseApproved": False}


def strength():
    raw, provenance = verified_body("nhs-strength")
    sections = re.split(r"<h2\b[^>]*>", raw.decode("utf-8"))[1:]
    sections = {text(s.split("</h2>", 1)[0]): text(s.split("</h2>", 1)[1]) for s in sections}
    # Values transcribed from the selected human-authored source, not generated.
    spec = [
        ("Sit-to-stand", "sentar_e_levantar", None, 5, 5, None, None, r"5 repetitions"),
        ("Mini-squats", "mini_agachamentos", None, 5, 5, None, None, r"5 times"),
        ("Calf raises", "elevacao_dos_calcanhares", None, 5, 5, None, None, r"5 times"),
        ("Sideways leg lift", "elevacao_lateral_da_perna", None, 5, 5, "each_leg", None, r"each leg 5 times"),
        ("Leg extension", "extensao_da_perna", None, 5, 5, "each_leg", 5, r"5 times with each leg"),
        ("Wall press-up", "flexao_na_parede", 3, 5, 10, None, None, r"3 sets of 5 to 10 repetitions"),
        ("Biceps curls", "flexao_dos_cotovelos", 3, 5, 5, "each_arm", None, r"3 sets of 5 curls with each arm"),
    ]
    exercises = []
    for order, (name, key, sets, low, high, side, hold, guard) in enumerate(spec, 1):
        section = sections[name]
        if not re.search(guard, section, re.I):
            raise ValueError("Source quantity changed: " + name)
        steps = len(re.findall(r"(?:^|\s)[ABC]\.\s", section))
        if steps not in (2, 3):
            raise ValueError("Unexpected instruction structure: " + name)
        exercises.append({"sourceOrder": order, "sourceName": name, "ptDraftKey": key, "sets": sets, "repetitionsMin": low, "repetitionsMax": high, "perSide": side, "holdSecondsMaximum": hold, "restSeconds": None, "instructionStepsInSource": steps, "sourceTextSha256": hashlib.sha256(section.encode()).hexdigest()})
    result = {
        "kind": "existing_human_introductory_strength_routine_research_pilot", "sourceId": "PR05", "source": provenance,
        "method": "Published sequence and quantities transcribed and guarded against cached page text; original instructions retained in local HTML. Missing sets/rest/duration remain null.",
        "attribution": "Contains public sector information licensed under the Open Government Licence v3.0.",
        "releaseStatus": "research_only_not_release_approved", "minimumDaysPerWeek": 2,
        "programWeeks": None, "sessionMinutes": None,
        "exercises": exercises,
        "publicationGaps": ["Portuguese instruction and applicability review", "No periodized gym program or diagnosis-based selection established", "No photo or video rights released", "App integration and use tests"],
    }
    dump(OUT / "forca-piloto.json", result)
    return {"exercises": len(exercises), "sourceInstructionsCount": sum(x["instructionStepsInSource"] for x in exercises), "periodizedProgram": False, "releaseApproved": False}


def nutrient(value, grams):
    raw = "" if value is None else str(value).strip()
    if raw == "Tr":
        return {"status": "trace", "amount": None}
    if raw in ("", "N", "-"):
        return {"status": "unavailable", "amount": None}
    if raw.startswith("<"):
        try:
            upper = Decimal(raw[1:]) * grams / 100
        except InvalidOperation as error:
            raise ValueError("Unknown bound: " + raw) from error
        return {"status": "less_than", "amount": str(upper.normalize())}
    try:
        number = Decimal(raw)
    except InvalidOperation as error:
        raise ValueError("Unknown nutrient token: " + raw) from error
    return {"status": "quantified", "amount": str((number * grams / 100).quantize(Decimal("0.01")))}


def food():
    path = ROOT / "cofid-amostra.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    records = {x["valuesOriginal"]["sourceId"]: x["valuesOriginal"] for x in data["sample"]}
    # Deliberately paired raw/cooked, flesh/skin and trace/zero cases.
    # The masses exercise arithmetic; they are NOT recommended portions or diet.
    chosen = [("11-867", 150), ("11-866", 150), ("12-940", 100), ("16-490", 120), ("16-373", 120), ("17-038", 10), ("13-661", 160), ("13-089", 160), ("14-318", 100), ("14-347", 100), ("16-424", 100), ("16-440", 100)]
    output = []
    fields = ("energyKcal", "proteinG", "carbohydrateG", "fatG", "fibreAoacG")
    for code, grams in chosen:
        source = records[code]
        output.append({"sourceId": code, "sourceName": source["nameOriginal"], "demonstrationInputGrams": grams,
                       "originalPer100g": {key: source[key] for key in fields},
                       "calculatedForInputMass": {key: nutrient(source[key], Decimal(grams)) for key in fields}})
    if output[0]["calculatedForInputMass"]["energyKcal"]["amount"] != "196.50" or output[1]["calculatedForInputMass"]["energyKcal"]["amount"] != "532.50":
        raise ValueError("Raw/cooked mass conversion regression")
    if nutrient("Tr", Decimal(100))["amount"] is not None or nutrient("0", Decimal(100))["amount"] != "0.00":
        raise ValueError("Trace conflated with zero")
    if nutrient("N", Decimal(100))["amount"] is not None or nutrient("<0.1", Decimal(50)) != {"status": "less_than", "amount": "0.05"}:
        raise ValueError("Missing or bound semantics lost")
    result = {
        "kind": "food_quantity_and_preparation_research_pilot", "sourceId": "AL05",
        "source": "CoFID 2021, Public Health England; local sample collected 2026-09-23",
        "inputSha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "attribution": "Contains public sector information licensed under the Open Government Licence v3.0.",
        "releaseStatus": "research_only_not_release_approved", "foodCount": len(output),
        "scope": "Mass conversion and preservation of preparation state, trace/missing/zero/bounds. No daily energy target, diet, medical suitability, barcode coverage or approved Portuguese equivalence.",
        "records": output,
    }
    dump(OUT / "alimentacao-piloto.json", result)
    return {"foods": len(output), "numericOrSemanticChecks": "passed", "portugalCoverageValidated": False, "releaseApproved": False}


if __name__ == "__main__":
    summary = {"running": running(), "strength": strength(), "food": food()}
    dump(OUT / "pilotos-resumo.json", summary)
    print(json.dumps(summary, ensure_ascii=False))
