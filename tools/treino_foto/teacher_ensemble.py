# Professor final: média do zero-shot (recortes) com o ajustado. Medido em 23/11: o ajustado sozinho ganha 18 pontos
# nos refeitórios do Nutrition5k, mas perde 9 nos pratos brasileiros do Commons; a média equilibra (76% / 66%).
# Também grava a lista das fotos brasileiras usadas só para medir (fora do treino do aluno).
# Uso: python teacher_ensemble.py classes_final.json <raiz .local/fotos-alimentos> [peso_ajustado]
import json, os, sys, unicodedata
import numpy as np

classes = json.load(open(sys.argv[1], encoding="utf-8")); root = sys.argv[2]
alpha = float(sys.argv[3]) if len(sys.argv) > 3 else 0.5
for src in ("n5k", "openimages", "commons"):
    gi = json.load(open(os.path.join(root, "rotulos", f"{src}_grid", "index.json"), encoding="utf-8"))
    g = np.load(os.path.join(root, "rotulos", f"{src}_grid", "logits.npy")).astype(np.float32)
    pi = json.load(open(os.path.join(root, "rotulos", f"{src}_probe", "index.json"), encoding="utf-8"))["files"]
    p = np.load(os.path.join(root, "rotulos", f"{src}_probe", "logits.npy")).astype(np.float32)
    at = {os.path.normpath(f): k for k, f in enumerate(pi)}
    rows = [(k, at[os.path.normpath(f)]) for k, f in enumerate(gi["files"]) if os.path.normpath(f) in at]
    out = os.path.join(root, "rotulos", f"{src}_ens"); os.makedirs(out, exist_ok=True)
    np.save(os.path.join(out, "logits.npy"), np.stack([alpha * p[j] + (1 - alpha) * g[k] for k, j in rows]).astype(np.float16))
    json.dump({"teacher": f"{alpha} ajustado + {1 - alpha} zero-shot", "files": [gi["files"][k] for k, _ in rows]},
              open(os.path.join(out, "index.json"), "w", encoding="utf-8"))
    print(src, len(rows), "de", len(gi["files"]))
norm = lambda t: unicodedata.normalize("NFKD", t.lower()).encode("ascii", "ignore").decode()
names = [(i, norm(c["pt"])) for i, c in enumerate(classes) if len(c["pt"]) > 4]
held = []
for f in json.load(open(os.path.join(root, "commons", "manifest.json"), encoding="utf-8"))["files"]:
    k = norm(f.get("category", "").replace("Category:", "").replace("_", " "))
    pos = [i for i, n in names if k and (k == n or k.startswith(n + " "))]
    if pos:
        held.append({"file": f["file"], "classes": pos})
json.dump(held, open(os.path.join(root, "rotulos", "br_holdout.json"), "w", encoding="utf-8"))
print("fotos brasileiras só para medir:", len(held))
