# Exporta o aluno: PyTorch -> ONNX -> TFLite (fp16 e int8) e mede top-5 de cada um na validação Nutrition5k.
# Uso: python export_student.py <classes_final.json> <raiz .local/fotos-alimentos> <dir modelo>
import csv, json, os, random, re, subprocess, sys
import numpy as np, torch, timm
from PIL import Image

classes = json.load(open(sys.argv[1], encoding="utf-8")); C = len(classes)
root, mdir = sys.argv[2], sys.argv[3]
meta = json.load(open(os.path.join(mdir, "student_meta.json"), encoding="utf-8"))
model = timm.create_model(meta["arch"], pretrained=False, num_classes=C)
model.load_state_dict(torch.load(os.path.join(mdir, "student_best.pt"), map_location="cpu")); model.eval()
cfg = timm.data.resolve_data_config({}, model=model)
mean, std = np.array(cfg["mean"], np.float32), np.array(cfg["std"], np.float32)

def prep(p):  # Resize 256 + CenterCrop 224, RGB 0..1, NHWC
    im = Image.open(p).convert("RGB"); w, h = im.size; s = 256 / min(w, h)
    im = im.resize((round(w * s), round(h * s)), Image.BILINEAR); w, h = im.size
    l, t = (w - 224) // 2, (h - 224) // 2
    return np.asarray(im.crop((l, t, l + 224, t + 224)), np.float32) / 255.0

# validação idêntica ao treino (seed 7, 20% dos pratos)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from n5k_map import build
en2slug = build(classes); slug_idx = {c["slug"]: i for i, c in enumerate(classes)}
idx = json.load(open(os.path.join(root, "rotulos", "n5k_grid", "index.json"), encoding="utf-8"))
base = os.path.join(root, "nutrition5k", "imagery")
files = [os.path.normpath(os.path.join(base, f)) for f in idx["files"]]
gt = {}
for fn in ("dish_metadata_cafe1.csv", "dish_metadata_cafe2.csv"):
    for row in csv.reader(open(os.path.join(root, "nutrition5k", "metadata", fn), encoding="utf-8")):
        ings = row[6:]; pos = set()
        for j in range(0, len(ings) - 6, 7):
            s = en2slug.get(ings[j + 1].strip().lower())
            if s and float(ings[j + 2] or 0) >= 15:
                pos.add(slug_idx[s])
        gt[row[0]] = pos
random.seed(7)
dishes = sorted({re.search(r"(dish_\d+)", p).group(1) for p in files}); random.shuffle(dishes)
vd = set(dishes[: len(dishes) // 5])
val = [(p, gt.get(re.search(r"(dish_\d+)", p).group(1), set())) for p in files if re.search(r"(dish_\d+)", p).group(1) in vd]
X = np.stack([prep(p) for p, _ in val])

def score(logits):
    # 1/5: cada ingrediente; p1: 1ª sugestão é um alimento do prato; p3: algum acerto nas 3 primeiras
    hit = {1: 0, 5: 0}; tot = 0; p1 = p3 = n = 0
    for o, (_, pos) in zip(logits, val):
        top = list(np.argsort(-o)[:5])
        if pos:
            n += 1; p1 += top[0] in pos; p3 += any(t in pos for t in top[:3])
        for k in pos:
            tot += 1; hit[5] += k in top; hit[1] += k == top[0]
    return {**{k: round(v / tot, 4) for k, v in hit.items()}, "p1": round(p1 / n, 4), "p3": round(p3 / n, 4)}

with torch.no_grad():
    ref = model(torch.from_numpy(((X - mean) / std).transpose(0, 3, 1, 2))).numpy()
res = {"pytorch_fp32": score(ref)}; print("pytorch", res["pytorch_fp32"], flush=True)

# modelo exportado (onnx NCHW; tflite fica NHWC) recebe RGB 0..1 e normaliza dentro (o app só redimensiona e divide por 255)
class Wrap(torch.nn.Module):
    def __init__(s, m): super().__init__(); s.m = m; s.register_buffer("mu", torch.tensor(mean).view(1, 3, 1, 1)); s.register_buffer("sd", torch.tensor(std).view(1, 3, 1, 1))
    def forward(s, x): return torch.sigmoid(s.m((x - s.mu) / s.sd))
onnx_p = os.path.join(mdir, "student.onnx")
torch.onnx.export(Wrap(model).eval(), torch.zeros(1, 3, 224, 224), onnx_p, input_names=["image"], output_names=["probs"], opset_version=17, dynamo=False)
calib = os.path.join(mdir, "calib.npy")
rng = np.random.default_rng(0)
train_imgs = [p for p in files if re.search(r"(dish_\d+)", p).group(1) not in vd]
oi = json.load(open(os.path.join(root, "openimages", "manifest.json"), encoding="utf-8"))["images"]
cal = [train_imgs[i] for i in rng.choice(len(train_imgs), 150, replace=False)] + [os.path.join(root, "openimages", oi[i]["file"]) for i in rng.choice(len(oi), 150, replace=False)]
np.save(calib, np.stack([prep(p) for p in cal]))
tfl = os.path.join(mdir, "tflite")
smp = np.stack([np.asarray(Image.fromarray((x * 255).astype(np.uint8)).resize((128, 128)), np.float32) / 255.0 for x in np.load(calib)[:20]])
np.save(os.path.join(mdir, "calibration_image_sample_data_20x128x128x3_float32.npy"), smp)  # evita o download do pickle do GitHub
env = dict(os.environ, PATH=os.path.dirname(sys.executable) + os.pathsep + os.environ["PATH"])
subprocess.run([sys.executable, "-m", "onnx2tf", "-i", onnx_p, "-o", tfl, "-oiqt", "-qt", "per-channel", "-cind", "image", calib, "[[[[0,0,0]]]]", "[[[[1,1,1]]]]", "-osd"], check=True, cwd=mdir, env=env)

from ai_edge_litert.interpreter import Interpreter
for f in sorted(os.listdir(tfl)):
    if not f.endswith(".tflite"):
        continue
    it = Interpreter(model_path=os.path.join(tfl, f)); it.allocate_tensors()
    i, o = it.get_input_details()[0], it.get_output_details()[0]; outs = []
    for x in X:
        xi = x[None]
        if i["dtype"] != np.float32:
            sc, zp = i["quantization"]; xi = np.clip(np.round(xi / sc + zp), np.iinfo(i["dtype"]).min, np.iinfo(i["dtype"]).max).astype(i["dtype"])
        it.set_tensor(i["index"], xi); it.invoke(); y = it.get_tensor(o["index"])[0].astype(np.float32)
        if o["dtype"] != np.float32:
            sc, zp = o["quantization"]; y = (y - zp) * sc
        outs.append(y)
    res[f] = {"bytes": os.path.getsize(os.path.join(tfl, f)), **score(np.stack(outs))}; print(f, res[f], flush=True)
json.dump(res, open(os.path.join(mdir, "export_eval.json"), "w"), indent=1)
print("DONE")
