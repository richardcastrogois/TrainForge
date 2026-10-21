"""Extrai candidatos conservadores da saída OCR real; não código do app."""
import json
import pathlib
import re
import sys
from decimal import Decimal

HERE = pathlib.Path(__file__).resolve().parent


def number_with_unit(text, unit):
    m = re.search(r"(?<![\w.,])([0-9]+(?:[,.][0-9]+)?)\s*" + re.escape(unit) + r"(?!\w|/)", text, re.I)
    return str(Decimal(m.group(1).replace(",", "."))) if m else None


def main():
    source = json.loads((HERE / "resultado-windows-ocr.json").read_text(encoding="utf-8-sig"))
    text = {x["file"]: x["text"] for x in source["results"]}
    checks = []
    def ck(name, ok): checks.append({"check": name, "passed": bool(ok)})
    ck("Rótulo preserva base100g e porção30g separadas", "100 g" in text["rotulo.png"] and "30 g" in text["rotulo.png"])
    ck("840kJ não200kcal", number_with_unit(text["rotulo.png"], "kJ") == "840" and number_with_unit(text["rotulo.png"], "kcal") == "200")
    ck("Vírgula decimal preservada", number_with_unit("Gordura 10,5 g", "g") == "10.5")
    ck("Distância efetivamente lida", number_with_unit(text["visor.png"], "km") == "1.25")
    ck("Carga omitida não vira8ou0kg", number_with_unit(text["visor.png"], "kg") is None)
    ck("Velocidade omitida não vira5km/h", number_with_unit(text["visor.png"], "km/h") is None)
    ck("Não usar km de km/h como distância", number_with_unit("5 km/h", "km") is None)
    ck("Número sem unidade permanece desconhecido", number_with_unit(text["ambiguo.png"], "kg") is None)
    ck("Não substituir O por0silenciosamente", number_with_unit("O,5 kg", "kg") is None)
    ck("Resistência em level não ékg", number_with_unit("LEVEL 8", "kg") is None)
    ck("Pausa/sem visor não fornece calorias", number_with_unit("SEM VISOR", "kcal") is None)
    out = {"date": "2026-10-15", "niche": "N41", "kind": "Conservative candidate parsing over actual Windows OCR output",
           "checks": checks, "passed": sum(x["passed"] for x in checks), "failed": sum(not x["passed"] for x in checks),
           "observedErrors": ["O0 l1 became OO II in the ambiguous synthetic fixture", "Time, load and speed numbers were omitted on synthetic display; preserved as unknown"],
           "realEquipmentPhotographed": False, "androidMLKitTested": False, "appImplemented": False,
           "automaticRegistrationAllowed": False, "releaseApproved": False}
    (HERE / "verificacoes-parser.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": out["passed"], "failed": out["failed"]}))
    assert out["failed"] == 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
