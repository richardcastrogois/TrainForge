"""Validação textual de códigos N04, não teste de scanner óptico."""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
EVIDENCE = HERE.parents[1]


def valid_check_digit(code):
    if not isinstance(code, str) or len(code) not in [8, 12, 13, 14] or not re.fullmatch(r"[0-9]+", code):
        return False
    total = sum(int(d) * (3 if i % 2 == 0 else 1) for i, d in enumerate(reversed(code[:-1])))
    return int(code[-1]) == (-total) % 10


def main():
    checks = []
    def ck(name, value): checks.append({"check": name, "passed": bool(value)})
    ck("Exemplo publicado GS1: soma57, dígito3", valid_check_digit("6291041500213"))
    ck("Dígito alterado é rejeitado", not valid_check_digit("6291041500214"))
    ck("Zeros preservados em string", valid_check_digit("06291041500213") and "6291041500213".zfill(14) == "06291041500213")
    ck("URL não é GTIN", not valid_check_digit("https://example.org/6291041500213"))
    ck("Inteiro não remove zeros silenciosamente", not valid_check_digit(6291041500213))
    ck("Dígitos não ASCII não aceitos automaticamente", not valid_check_digit("６２９１０４１５００２１３"))
    ck("Código incompleto rejeitado", not valid_check_digit("629104150021"))
    codes = {}
    date_root = EVIDENCE / "2026-09-28"
    for path in date_root.rglob("*.evidencia.json"):
        if not any(x.startswith("n04") for x in path.parts):
            continue
        record = json.loads(path.read_text(encoding="utf-8-sig"))
        if record.get("status") != 200:
            continue
        m = re.search(r"/product/([0-9]{8,14})(?:[/?\.]|$)", record.get("url", ""))
        if m:
            codes[m.group(1)] = str(path.relative_to(EVIDENCE))
    for code, receipt in codes.items():
        ck("Código de produto N04 " + code, valid_check_digit(code))
    result = {"date": "2026-10-15", "niche": "N42", "checks": checks,
              "passed": sum(x["passed"] for x in checks), "failed": sum(not x["passed"] for x in checks),
              "reusedProductCodesAndReceipts": codes, "newProductLookups": 0,
              "opticalDecodeTested": False, "cameraUsed": False, "androidSDKInstalled": False,
              "validChecksumProvesProductAuthenticity": False, "scanningProvesConsumption": False,
              "appImplemented": False, "releaseApproved": False}
    (HERE / "verificacoes-gtin.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "failed": result["failed"], "reusedCodes": len(codes)}))
    assert result["failed"] == 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
