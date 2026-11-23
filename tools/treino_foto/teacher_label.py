# Professor: SigLIP 2 marca, para cada foto, a probabilidade de cada um dos alimentos da lista.
# Uso: python teacher_label.py classes_final.json <raiz_fotos> <saida_dir> [modelo]
import json, os, sys, glob
import numpy as np, torch
from PIL import Image
from transformers import AutoModel, AutoProcessor

classes = json.load(open(sys.argv[1], encoding="utf-8"))
root, out = sys.argv[2], sys.argv[3]
model_id = sys.argv[4] if len(sys.argv) > 4 else "google/siglip2-so400m-patch14-384"
os.makedirs(out, exist_ok=True)
GRID = os.environ.get("GRID") == "1"; GRID_PENALTY = float(os.environ.get("GRID_PENALTY", "1.0"))
dev = "cuda"
model = AutoModel.from_pretrained(model_id, dtype=torch.float16).to(dev).eval()
proc = AutoProcessor.from_pretrained(model_id)

templates = ["a photo of {}.", "a photo of {}, a type of food.", "a close-up photo of a plate with {}.", "{} served on a plate."]
with torch.no_grad():
    embs = []
    for c in classes:
        t = proc(text=[tp.format(c["en"]) for tp in templates], padding="max_length", max_length=64, return_tensors="pt").to(dev)
        e = model.get_text_features(**t)
        e = getattr(e, 'pooler_output', e)
        e = e / e.norm(dim=-1, keepdim=True)
        e = e.mean(0)
        embs.append(e / e.norm())
    T = torch.stack(embs)  # [C, D]
    scale, bias = model.logit_scale.exp(), model.logit_bias

files = sorted(p for ext in ("jpg", "jpeg", "png", "webp") for p in glob.glob(os.path.join(root, "**", f"*.{ext}"), recursive=True))
files = [f for f in files if not os.path.basename(f).startswith(("depth", "rgb_depth"))]
print("fotos", len(files), flush=True)
probs, kept, B = [], [], (8 if GRID else 32)
for i in range(0, len(files), B):
    ims, names = [], []
    for f in files[i:i + B]:
        try:
            im = Image.open(f).convert("RGB"); names.append(os.path.relpath(f, root))
            ims.append(im)
            if GRID:
                w, h = im.size
                for (x0, y0) in ((0, 0), (0.4, 0), (0, 0.4), (0.4, 0.4)):
                    ims.append(im.crop((int(x0 * w), int(y0 * h), int((x0 + 0.6) * w), int((y0 + 0.6) * h))))
        except Exception:
            pass
    if not ims:
        continue
    with torch.no_grad():
        x = proc(images=ims, return_tensors="pt").to(dev)
        v = model.get_image_features(pixel_values=x["pixel_values"].half())
        v = getattr(v, 'pooler_output', v)
        v = v / v.norm(dim=-1, keepdim=True)
        p = v @ T.T * scale + bias  # logits (sigmoid = probabilidade)
        if GRID:
            p = p.view(-1, 5, p.shape[-1])
            p = torch.maximum(p[:, 0], p[:, 1:].max(1).values - GRID_PENALTY)
    probs.append(p.float().cpu().numpy().astype(np.float16)); kept += names
    if i % 3200 == 0:
        print(i, len(files), flush=True)
np.save(os.path.join(out, "logits.npy"), np.concatenate(probs))
json.dump({"model": model_id, "templates": templates, "classes": [c["slug"] for c in classes], "files": kept},
          open(os.path.join(out, "index.json"), "w", encoding="utf-8"))
print("DONE", len(kept))
