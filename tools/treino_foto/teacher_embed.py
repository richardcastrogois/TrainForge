# Professor ajustado, passo 1: guarda os vetores de imagem do SigLIP 2 (foto inteira + 4 recortes de 60%)
# e os vetores de texto das classes (inglês e português), para treinar uma camada de ajuste sem reprocessar fotos.
# Uso: python teacher_embed.py classes_final.json <raiz_fotos> <saida_dir> [modelo]
import glob, json, os, sys, time
import numpy as np, torch
from PIL import Image
from torch.utils.data import DataLoader, Dataset
from transformers import AutoModel, AutoProcessor

MODEL = "google/siglip2-so400m-patch14-384"
VIEWS = ((0, 0), (0.4, 0), (0, 0.4), (0.4, 0.4))
EN = ["a photo of {}.", "a photo of {}, a type of food.", "a close-up photo of a plate with {}.", "{} served on a plate."]
PT = ["uma foto de {}.", "uma foto de {}, um tipo de comida.", "um prato com {}.", "{} servido no prato."]


class Photos(Dataset):
    def __init__(s, files, proc, views): s.files, s.proc, s.views = files, proc, views
    def __len__(s): return len(s.files)
    def __getitem__(s, i):
        try:
            im = Image.open(s.files[i]).convert("RGB"); w, h = im.size
            ims = [im] + [im.crop((int(x * w), int(y * h), int((x + 0.6) * w), int((y + 0.6) * h))) for x, y in VIEWS][: s.views - 1]
            return s.proc(images=ims, return_tensors="pt")["pixel_values"], i
        except Exception:
            return None, i


def collate(batch):
    ok = [(x, i) for x, i in batch if x is not None]
    return (torch.cat([x for x, _ in ok]) if ok else None), [i for _, i in ok]


def main():
    classes = json.load(open(sys.argv[1], encoding="utf-8"))
    root, out = sys.argv[2], sys.argv[3]
    model_id = sys.argv[4] if len(sys.argv) > 4 else MODEL
    os.makedirs(out, exist_ok=True)
    model = AutoModel.from_pretrained(model_id, dtype=torch.float16).to("cuda").eval()
    proc = AutoProcessor.from_pretrained(model_id)
    text_p = os.path.join(out, "..", "text.npz")
    if not os.path.exists(text_p):
        with torch.no_grad():
            def enc(templates, key):
                rows = []
                for c in classes:
                    t = proc(text=[tp.format(c[key]) for tp in templates], padding="max_length", max_length=64, return_tensors="pt").to("cuda")
                    e = model.get_text_features(**t); e = getattr(e, "pooler_output", e)
                    e = (e / e.norm(dim=-1, keepdim=True)).mean(0); rows.append((e / e.norm()).float().cpu().numpy())
                return np.stack(rows)
            np.savez(text_p, en=enc(EN, "en"), pt=enc(PT, "pt"), scale=model.logit_scale.exp().item(), bias=model.logit_bias.item())
    files = sorted(p for ext in ("jpg", "jpeg", "png", "webp") for p in glob.glob(os.path.join(root, "**", f"*.{ext}"), recursive=True))
    files = [f for f in files if not os.path.basename(f).startswith(("depth", "rgb_depth"))]
    # Open Images costuma ter um alimento por foto: só a foto inteira (5x mais rápido). VIEWS=5 força os recortes.
    views = int(os.environ.get("VIEWS", "1" if os.path.basename(os.path.normpath(root)) == "openimages" else "5"))
    print("fotos", len(files), "vistas", views, flush=True)
    emb = np.zeros((len(files), views, model.config.vision_config.hidden_size), np.float16); ok = np.zeros(len(files), bool)
    dl = DataLoader(Photos(files, proc, views), batch_size=40 // views, num_workers=6, collate_fn=collate, persistent_workers=False)
    bs = 40 // views
    t0 = time.time()
    with torch.no_grad():
        for n, (x, idx) in enumerate(dl):
            if x is None:
                continue
            v = model.get_image_features(pixel_values=x.to("cuda").half()); v = getattr(v, "pooler_output", v)
            v = (v / v.norm(dim=-1, keepdim=True)).view(len(idx), views, -1)
            emb[idx] = v.cpu().numpy(); ok[idx] = True
            if n % 200 == 0:
                print(f"{n * bs}/{len(files)} {time.time() - t0:.0f}s", flush=True)
    keep = np.flatnonzero(ok)
    np.save(os.path.join(out, "emb.npy"), emb[keep])
    json.dump({"model": model_id, "files": [os.path.relpath(files[i], root) for i in keep]}, open(os.path.join(out, "index.json"), "w", encoding="utf-8"))
    print("DONE", len(keep), f"{time.time() - t0:.0f}s", flush=True)


if __name__ == "__main__":
    main()
