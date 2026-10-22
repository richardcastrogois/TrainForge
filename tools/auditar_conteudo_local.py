"""Auditoria independente de valores brutos e referencias contra os originais locais."""
import hashlib
import json
from pathlib import Path
from preparar_conteudo_local import ROOT, pointer
from conteudo_editorial import validate_bundle


def main():
    import openpyxl
    report = json.loads((ROOT / "content/manifests/pilot-prepared.json").read_text(encoding="utf-8"))
    editorial = json.loads((ROOT / report["editorial"]["path"]).read_text(encoding="utf-8"))
    if validate_bundle(editorial):
        raise ValueError("Contrato editorial invalido")
    source_docs = {}
    references = 0
    for item in editorial["assets"]:
        for ref in item["evidence"]:
            if ref["path"] not in source_docs:
                path = ROOT / ref["path"]
                source_docs[ref["path"]] = (hashlib.sha256(path.read_bytes()).hexdigest(), json.loads(path.read_text(encoding="utf-8-sig")))
            digest, document = source_docs[ref["path"]]
            if digest != ref["snapshotSha256"]:
                raise ValueError("Hash de evidencia divergente")
            original = pointer(document, ref["pointer"])
            if item["sourceId"] == "EX01":
                if item["kind"] == "instruction" and item["content"]["originalDescription"] != original.get("description"):
                    raise ValueError("Texto original foi alterado")
                if item["kind"] == "media" and item["content"]["remoteUrl"] != original.get("image", original.get("video")):
                    raise ValueError("Referencia de midia foi alterada")
            for measure in item["dose"]["measurements"]:
                if pointer(document, measure["sourceField"]) != measure["quantity"]:
                    raise ValueError("Dose foi alterada")
            references += 1
    totals = []
    for food in report["food"]:
        original = ROOT / food["sourceFile"]
        if hashlib.sha256(original.read_bytes()).hexdigest() != food["sourceSha256"]:
            raise ValueError("Planilha original foi alterada")
        workbook = openpyxl.load_workbook(original, read_only=True, data_only=True)
        rows_by_sheet = {name:list(workbook[name].iter_rows(values_only=True)) for name in food["columnsByTable"]}
        count = cells = conflicts = 0
        keys = set()
        with (ROOT / food["path"]).open(encoding="utf-8") as f:
            for line in f:
                item = json.loads(line)
                row = rows_by_sheet[item["sheet"]][item["row"] - 1]
                ciqual = food["sourceId"] == "AL-CIQUAL-2025"
                code_i, name_i = (6,7) if ciqual else (0,1)
                if str(row[code_i]).strip() != item["sourceFoodId"] or row[name_i] != item["nameOriginal"]:
                    raise ValueError("Identidade/nome do alimento alterado")
                for val in item["values"]:
                    if row[val["column"] - 1] != val["raw"]:
                        raise ValueError("Valor bruto da planilha alterado")
                    cells += 1
                if item.get("sourceRowKey") in keys:
                    raise ValueError("Chave de linha repetida")
                keys.add(item.get("sourceRowKey"))
                count += 1
                conflicts += bool(item.get("sourceCodeConflict"))
        workbook.close()
        if count != food["tableRecords"]:
            raise ValueError("Contagem de tabela divergente")
        totals.append({"sourceId":food["sourceId"],"tableRowsChecked":count,"sourceCellsChecked":cells,"conflictingRowsPreserved":conflicts})
    result = {"result":"PASS","editorialAssetsChecked":len(editorial["assets"]),"evidencePointersChecked":references,"food":totals,
              "scope":"Fidelidade documental e integridade dos arquivos locais; nao revisao clinica/editorial humana ou teste do app"}
    target = ROOT / "docs/execucao/v1/verificacao-preparacao-local.json"
    target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,ensure_ascii=True))


if __name__ == "__main__":
    main()
