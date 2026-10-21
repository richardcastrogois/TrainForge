"""Ensaio CPU autorizado, sem rede: executado só no ambiente temporário N39.

Preserva métricas/atribuição, não imagens ou pesos no repositório. Não mede
acurácia populacional e não é código do aplicativo. Remover o ambiente após uso.
"""
import hashlib
import json
import os
import pathlib
import sys
import time

ROOT = pathlib.Path(r"C:\dev\TrainForge\.research-runtime\n39")
HERE = pathlib.Path(__file__).resolve().parent
os.environ.update({"HF_HUB_OFFLINE": "1", "TRANSFORMERS_OFFLINE": "1",
                   "HF_HUB_DISABLE_TELEMETRY": "1", "DO_NOT_TRACK": "1",
                   "HF_HOME": str(ROOT / "hf-cache"),
                   "OMP_NUM_THREADS": "4", "MKL_NUM_THREADS": "4"})
network_attempts = []


def prevent_network(event, args):
    if event == "socket.connect":
        network_attempts.append(str(args[1]))
        raise RuntimeError("Network disabled in the evaluation process")


sys.addaudithook(prevent_network)
import numpy as np
import PIL
from PIL import Image, ImageOps
import torch
import transformers
from transformers import ViTConfig, ViTForImageClassification, ViTImageProcessor


def legacy_input(image):
    a = np.asarray(image.resize((224, 224), Image.Resampling.BILINEAR),
                   dtype=np.float32).transpose(2, 0, 1) / 255
    return ((a - np.float32(0.5)) / np.float32(0.5))[None, ...]


def main():
    torch.set_num_threads(4)
    torch.set_num_interop_threads(1)
    torch.manual_seed(1337)
    torch.use_deterministic_algorithms(True)
    cfg = json.loads((ROOT / "model/config.json").read_text(encoding="utf-8"))
    weight = ROOT / "model/pytorch_model.bin"
    digest = hashlib.file_digest(weight.open("rb"), "sha256").hexdigest()
    assert digest == "33d6b7d44c0bb524fbb6f6d3b7d1f7c8d7c703b58882bf2a845355d9411f566d"
    model = ViTForImageClassification(ViTConfig.from_dict(cfg)).eval()
    state = torch.load(weight, weights_only=True, map_location="cpu")
    load_result = model.load_state_dict(state, strict=True)
    del state
    processor = ViTImageProcessor(do_resize=True, size={"height": 224, "width": 224},
                                 resample=Image.Resampling.BILINEAR, do_rescale=True,
                                 rescale_factor=1 / 255, do_normalize=True,
                                 image_mean=[0.5] * 3, image_std=[0.5] * 3)
    manifest = json.loads((HERE / "lote-ensaio-proposto.json").read_text(encoding="utf-8"))
    supplemental = "--supplemental" in sys.argv
    if supplemental:
        manifest = json.loads((HERE / "lote-ensaio-suplementar.json").read_text(encoding="utf-8"))
    inputs = []
    for i, case in enumerate(manifest["cases"]):
        if supplemental:
            i = 6
        path = ROOT / "fixtures" / f"{i}.jpg"
        if not path.is_file():
            inputs.append((str(i), case, None, {"error": "Temporary fixture not received"}))
            continue
        with Image.open(path) as original:
            original.verify()
        with Image.open(path) as original:
            dimensions = list(original.size)
            image = ImageOps.exif_transpose(original).convert("RGB")
        inputs.append((str(i), case, image,
                       {"sourceFileDimensions": dimensions,
                        "inputMode": "RGB", "inputDimensions": list(image.size),
                        "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}))
    controls = [] if supplemental else [("synthetic-black", (0, 0, 0)), ("synthetic-white", (255, 255, 255))]
    for name, color in controls:
        inputs.append((name, {"fileTitle": name, "expectedClassProposal": None,
                              "purpose": "Synthetic non-food control; not a photograph"},
                       Image.new("RGB", (224, 224), color), {"synthetic": True}))
    rows = []
    with torch.inference_mode():
        for identifier, case, image, details in inputs:
            row = {"id": identifier, "fileTitle": case["fileTitle"],
                   "purpose": case["purpose"], "expectedClassProposal": case.get("expectedClassProposal"),
                   "author": case.get("author"), "license": case.get("license"),
                   "licenseUrl": case.get("licenseUrl"), "descriptionPage": case.get("descriptionPage"),
                   **details}
            if image is None:
                rows.append(row)
                continue
            a = legacy_input(image)
            modern = processor(images=image, return_tensors="np")["pixel_values"]
            max_difference = float(np.max(np.abs(a - modern)))
            row["preprocessingMaxAbsDifference"] = max_difference
            row["preprocessingMatchesWithin1eMinus6"] = max_difference < 1e-6
            t0 = time.perf_counter()
            logits = model(pixel_values=torch.from_numpy(a)).logits
            row["inferenceSeconds"] = time.perf_counter() - t0
            scores = torch.softmax(logits, dim=-1)[0]
            values, indices = torch.topk(scores, k=5)
            row["top5"] = [{"id": int(i), "label": cfg["id2label"][str(int(i))],
                             "score": float(v)} for v, i in zip(values, indices)]
            row["score16CheesePlateInConfig"] = float(scores[16])
            row["score17CheesecakeInConfig"] = float(scores[17])
            expected = case.get("expectedClassProposal")
            row["matchesProposedLabelTop1"] = row["top5"][0]["label"] == expected if expected else None
            row["matchesProposedLabelTop5"] = expected in [x["label"] for x in row["top5"]] if expected else None
            if identifier == "5":
                repeated = model(pixel_values=torch.from_numpy(a)).logits
                row["sameInputRepeatedMaxLogitDifference"] = float(torch.max(torch.abs(logits - repeated)))
            row["confirmedFoodWritten"] = False
            row["personAssignedAutomatically"] = False
            rows.append(row)
            print(json.dumps({"id": identifier, "top1": row["top5"][0],
                              "seconds": row["inferenceSeconds"], "preprocessingDelta": max_difference}), flush=True)
    result = {
        "date": "2026-10-15", "niche": "N39", "kind": "Small controlled local CPU experiment",
        "model": "nateraw/food", "revision": "8991abd49ea01ebf502aeda51d4f12a59c603e01",
        "weightSha256": digest, "weightsOnlyLoad": True, "strictStateLoad": True,
        "missingKeys": list(load_result.missing_keys), "unexpectedKeys": list(load_result.unexpected_keys),
        "versions": {"python": sys.version, "torch": torch.__version__,
                     "transformers": transformers.__version__, "numpy": np.__version__, "Pillow": PIL.__version__},
        "device": "cpu", "cudaBuild": torch.version.cuda, "threads": torch.get_num_threads(),
        "networkAudit": {"connectionsPreventedByAuditHook": True, "attempts": network_attempts},
        "cases": rows, "inferencePerformed": True, "appTested": False, "clinicalValidation": False,
        "populationAccuracyEstimated": False, "confidenceCalibrated": False,
        "automaticNonfoodRejectionImplemented": False, "mealIdentityUIImplemented": False,
        "rights": "Apache 2.0 declared for model; each image has its own recorded license. No Food101 photograph downloaded.",
        "limitations": ["Six preselected public images and two synthetic controls are not population validation.",
                        "Image labels require visual review; metadata alone is not verified truth.",
                        "Config/loader label order 16/17 needs source and empirical interpretation.",
                        "A softmax score is not calibrated confidence and closed-set classifier has no unknown class.",
                        "No food, quantity, meal person or nutrition target written to the app."],
        "temporaryEnvironmentMustBeDeleted": True, "releaseApproved": False}
    result["supplementalOnly"] = supplemental
    output_name = "resultado-ensaio-suplementar.json" if supplemental else "resultado-ensaio-local.json"
    (HERE / output_name).write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
