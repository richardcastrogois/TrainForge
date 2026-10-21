"""Ensaio top-down de pose; caixa manual, sem detecção/identidade/exercício."""
import os
import pathlib
import json
import sys
import time
import hashlib

ROOT = pathlib.Path(r"C:\dev\TrainForge\.research-runtime\n43")
HERE = pathlib.Path(__file__).resolve().parent
os.environ.update({"HF_HOME": str(ROOT / "hf-cache"), "HF_HUB_OFFLINE": "1",
                   "TRANSFORMERS_OFFLINE": "1", "HF_HUB_DISABLE_TELEMETRY": "1",
                   "OMP_NUM_THREADS": "4", "MKL_NUM_THREADS": "4"})
attempts = []
def block_network(event, args):
    if event == "socket.connect":
        attempts.append(str(args[1]))
        raise RuntimeError("No network in pose experiment")
sys.addaudithook(block_network)
import torch
import numpy as np
import scipy
from PIL import Image
import transformers
from transformers import VitPoseConfig, VitPoseForPoseEstimation, VitPoseImageProcessor
from safetensors.torch import load_file


def main():
    torch.set_num_threads(4)
    torch.set_num_interop_threads(1)
    config = VitPoseConfig.from_dict(json.loads((ROOT / "model/config.json").read_text(encoding="utf-8")))
    processor = VitPoseImageProcessor.from_pretrained(str(ROOT / "model"), local_files_only=True)
    model = VitPoseForPoseEstimation(config).eval()
    weight = ROOT / "model/model.safetensors"
    digest = hashlib.sha256(weight.read_bytes()).hexdigest()
    assert digest == "f7bad8ed09eeeb2a7de6b38faaa8a88d07838e23e9c06a2a782099bca7467cb9"
    loaded = model.load_state_dict(load_file(str(weight)), strict=True)
    with Image.open(ROOT / "fixtures/nasa.jpg") as image:
        photo = image.convert("RGB")
    # Caixa selecionada manualmente após inspeção da foto, não saída de detector.
    boxes = [np.array([[100, 20, 750, 650]], dtype=np.float32)]
    rows = []
    with torch.inference_mode():
        for name, image in [("NASA-public-factual-photo", photo),
                            ("synthetic-black-no-person", Image.new("RGB", photo.size))]:
            inputs = processor(images=image, boxes=boxes, return_tensors="pt")
            start = time.perf_counter()
            outputs = model(**inputs, dataset_index=torch.tensor([0]))
            elapsed = time.perf_counter() - start
            poses = processor.post_process_pose_estimation(outputs, boxes=boxes, threshold=0.0)
            pose = poses[0][0]
            points = []
            for point, label, score in zip(pose["keypoints"], pose["labels"], pose["scores"]):
                idx = int(label)
                if idx < 5:
                    continue  # Não reter coordenadas de olhos/nariz/orelhas, desnecessárias ao recorte.
                points.append({"id": idx, "landmark": config.id2label[idx],
                               "x": float(point[0]), "y": float(point[1]), "score": float(score)})
            rows.append({"case": name, "inputDimensions": list(image.size),
                         "manualBoxCOCO": boxes[0].tolist(), "detectorExecuted": False,
                         "pixelValuesShape": list(inputs["pixel_values"].shape),
                         "heatmapsShape": list(outputs.heatmaps.shape), "inferenceSeconds": elapsed,
                         "bodyLandmarksExcludingFace": points,
                         "actionClass": None, "repetitions": None, "duration": None,
                         "loadKg": None, "calories": None, "techniqueApproved": False})
            print(json.dumps({"case": name, "heatmapsShape": list(outputs.heatmaps.shape),
                              "retainedBodyPoints": len(points), "seconds": elapsed}), flush=True)
    result = {"date": "2026-10-15", "niche": "N43", "model": "usyd-community/vitpose-plus-small",
              "revision": "0c30b6534bb621af0162b481176742577264e36e", "weightSha256": digest,
              "weightFormat": "safetensors", "strictLoadMissing": list(loaded.missing_keys),
              "strictLoadUnexpected": list(loaded.unexpected_keys), "device": "cpu", "threads": 4,
              "versions": {"torch": torch.__version__, "transformers": transformers.__version__,
                           "scipy": scipy.__version__, "numpy": np.__version__},
              "connectionsPrevented": True, "networkAttempts": attempts, "cases": rows,
              "sourceImage": "https://www.nasa.gov/image-article/exercising-t2-treadmill/",
              "sourceUse": "Private factual non-promotional evaluation; NASA acknowledged, no endorsement, no image publication/app reuse. Image removed after test.",
              "imageVisuallyInspectedByAgent": True, "independentKeypointGroundTruth": False,
              "exerciseClassifierTested": False, "videoOrRepetitionCounterTested": False,
              "olderPeopleOrCaregiversTested": False, "clinicalValidation": False,
              "appImplemented": False, "releaseApproved": False}
    (HERE / "resultado-pose-local.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
