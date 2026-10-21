"""Auditoria offline N39; não instala bibliotecas nem executa modelo de ML.

Compara recibos, taxonomias e resultados publicados. O ensaio de entrada usa
somente matrizes sintéticas próprias, Pillow/NumPy já existentes e a fórmula
documentada pelo Transformers v4.8.1 (Apache 2.0, Hugging Face/contribuidores).
Não é teste de reconhecimento, reprodução de benchmark ou validação clínica.
"""
import hashlib
import ast
import json
import pathlib
import re
import sys

import numpy as np
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
RAW = HERE.parent / "raw"


def read_json(name):
    return json.loads((RAW / name).read_text(encoding="utf-8"))


def main():
    checks = []

    def check(name, passed, detail=None):
        checks.append({"check": name, "passed": bool(passed), "detail": detail})

    receipts = []
    for path in sorted(HERE.glob("*.evidencia.json")):
        receipt = json.loads(path.read_text(encoding="utf-8"))
        body = (path.parent / receipt["bodyFile"]).resolve()
        matches = hashlib.sha256(body.read_bytes()).hexdigest() == receipt["sha256"]
        check("Corpo original: " + path.name, matches)
        receipts.append({"receipt": path.name, "httpStatus": receipt.get("status"),
                         "bytes": receipt.get("bytes"), "hashMatches": matches})

    config = read_json("n39-nateraw-config.json")
    labels = config["id2label"]
    check("101 IDs contíguos", set(labels) == {str(i) for i in range(101)})
    check("Mapa inverso após normalizar IDs textuais", all(int(config["label2id"][v]) == int(k) for k, v in labels.items()))
    check("Cabeça alimentar e entrada RGB", config["architectures"] == ["ViTForImageClassification"]
          and config["num_channels"] == 3 and config["image_size"] == 224)
    source = read_json("n39-nateraw-api.json")
    check("Revisão preservada", source["sha"] == "8991abd49ea01ebf502aeda51d4f12a59c603e01")
    evaluation = read_json("n39-nateraw-eval-results.json")
    all_results = read_json("n39-nateraw-all-results.json")
    check("Resultados repetidos concordam", all(all_results[k] == v for k, v in evaluation.items()))
    loader_tree = ast.parse((RAW / "n39-nateraw-food101-loader.txt").read_text(encoding="utf-8"))
    loader_labels = next(ast.literal_eval(node.value) for node in loader_tree.body
                         if isinstance(node, ast.Assign)
                         and any(isinstance(t, ast.Name) and t.id == "_NAMES" for t in node.targets))
    check("Loader contém os mesmos 101 nomes", set(loader_labels) == set(labels.values()))
    loader_differences = [{"id": i, "loaderLabel": name, "modelLabel": labels[str(i)]}
                          for i, name in enumerate(loader_labels) if labels[str(i)] != name]

    prep = read_json("n39-nateraw-preprocessor.json")
    check("Pré-processador publicado", prep["size"] == 224 and prep["resample"] == 2
          and prep["image_mean"] == [0.5] * 3 and prep["image_std"] == [0.5] * 3
          and prep["do_normalize"] and prep["do_resize"])

    def adapter(image):
        # Contrato de teste deliberadamente aceita só PIL RGB de 8 bits.
        # Não afirma que o treino usou exatamente esta transformação.
        if not isinstance(image, Image.Image) or image.mode != "RGB":
            raise ValueError("É necessária uma imagem RGB explícita")
        a = np.asarray(image.resize((224, 224), resample=Image.Resampling.BILINEAR),
                       dtype=np.float32).transpose(2, 0, 1) / 255.0
        return ((a - np.float32(0.5)) / np.float32(0.5))[None, ...]

    black = adapter(Image.new("RGB", (300, 150), (0, 0, 0)))
    white = adapter(Image.new("RGB", (9, 13), (255, 255, 255)))
    rgb = adapter(Image.new("RGB", (10, 20), (255, 128, 0)))
    check("Formato NCHW", black.shape == (1, 3, 224, 224))
    check("Tipo float32", black.dtype == np.float32)
    check("Preto -> -1", np.all(black == -1))
    check("Branco -> +1", np.all(white == 1))
    check("Ordem RGB", np.allclose(rgb[0, :, 0, 0], [1, 128 / 127.5 - 1, -1], atol=1e-7))
    try:
        adapter(Image.new("L", (10, 10)))
        rejected = False
    except ValueError:
        rejected = True
    check("Escala cinzenta não aceita silenciosamente", rejected)

    swin = read_json("n39-swin-onnx-config.json")
    swin_labels = swin["id2label"]
    check("Alternativa: 101 classes", len(swin_labels) == 101)
    check("Alternativa: mesmos nomes, sem pressupor IDs iguais",
          set(labels.values()) == set(swin_labels.values()))
    swin_prep = read_json("n39-swin-onnx-preprocessor.json")
    check("Não transferir média do ViT ao Swin", swin_prep["image_mean"] != prep["image_mean"])

    accuracy = (RAW / "n39-nutrilens-accuracy.md").read_text(encoding="utf-8")
    segment = accuracy.split("## Confidence calibration")[1].split("## Hardest")[0]
    bins = []
    for row in segment.splitlines():
        a = [x.strip() for x in row.strip("|").split("|")]
        if len(a) == 4 and re.fullmatch(r"\d+", a[1]):
            bins.append({"n": int(a[1]), "meanConfidence": float(a[2].strip("%")) / 100,
                         "accuracy": float(a[3].strip("%")) / 100})
    n = sum(x["n"] for x in bins)
    ece = sum(x["n"] * abs(x["meanConfidence"] - x["accuracy"]) for x in bins) / n
    check("Bins do relatório somam 2523", n == 2523)
    check("ECE arredondado compatível com 0.015", abs(ece - 0.015) < 0.001)

    vision = (RAW / "n39-nutrilens-vision-bench.md").read_text(encoding="utf-8")
    segment = vision.split("## Per photo")[1].split("<!-- /generated:")[0]
    photo_rows = []
    for row in segment.splitlines():
        a = [x.strip() for x in row.strip("|").split("|")]
        if len(a) == 5 and re.fullmatch(r"\d+/\d+", a[3]):
            matched, total = map(int, a[3].split("/"))
            photo_rows.append({"id": a[0], "matched": matched, "expected": total})
    truth = read_json("n39-nutrilens-vision-truth.json")["images"]
    check("39 linhas e 39 anotações", len(photo_rows) == len(truth) == 39)
    check("Mesmos identificadores nas anotações", {x["id"] for x in photo_rows} == set(truth))
    matched = sum(x["matched"] for x in photo_rows)
    expected = sum(x["expected"] for x in photo_rows)

    result = {
        "date": "2026-10-15", "niche": "N39", "researchClosed": False,
        "scope": "Auditoria documental e ensaio sintético de entrada; nenhuma inferência",
        "checks": checks, "passed": sum(x["passed"] for x in checks),
        "failed": sum(not x["passed"] for x in checks), "receipts": receipts,
        "naterawPublishedEvaluation": evaluation,
        "naterawEvaluationLimit": "Não publica contagem explícita, predições individuais, matriz de confusão, calibração, abstenção ou teste português. Não inferir n exato da velocidade arredondada.",
        "datasetLoaderOrderDifferences": loader_differences,
        "datasetLoaderOrderLimit": "Config e loader publicado usam ordem diferente em dois nomes. O loader atual não comprova a revisão usada no treino; preservar ambas as ordens e conferir os dois casos antes de decidir a decodificação. Não corrigir pesos ou taxonomia silenciosamente.",
        "nutrilensPublishedEvaluationAudit": {
            "source": "n39-nutrilens-accuracy.evidencia.json", "inferenceRerun": False,
            "food101ReportedSamples": 2523, "nominal25Times101": 2525,
            "sampleDifferenceNeedsExplanation": 2, "calibrationCount": n,
            "eceFromRoundedBins": ece,
            "calibrationAppliesTo": "Fusão com melhores parâmetros; não transferir ao Swin isolado, nateraw, parâmetros padrão ou culinária portuguesa.",
            "nonfoodCaveat": "Falso não-alimento em fotos de comida não mede a aceitação de fotos sem comida. Não há especificidade não-alimento demonstrada nesta tabela.",
            "visionRows": len(photo_rows), "matchedCountFromTable": matched,
            "expectedCountFromTable": expected, "microRecallFromDisplayedRows": matched / expected,
            "headerRecallPercent": 80.6,
            "discrepancy": "Linhas exibidas dão 53/66 = 80,303%, não 80,6%. Agregação ou versão deve ser conferida antes de adotar a manchete; não se sabe a causa só pela tabela.",
            "truthLimit": "Faixas e porções estimadas visualmente, não pesagens independentes ou validação clínica. Fotos não obtidas."
        },
        "modelInferencePerformed": False, "runtimeInstalled": False,
        "syntheticInputAdapterOnly": True, "clinicalValidation": False,
        "releaseApproved": False
    }
    (HERE / "avaliacao-publicada.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": result["passed"], "failed": result["failed"],
                      "localReceipts": len(receipts), "modelInferencePerformed": False,
                      "microRecallFromTable": matched / expected}, ensure_ascii=False))
    return bool(result["failed"])


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    raise SystemExit(main())
