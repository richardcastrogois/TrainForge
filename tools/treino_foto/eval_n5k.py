# Mede o professor (ou aluno) contra os ingredientes anotados no Nutrition5k.
# Uso: python eval_n5k.py classes_final.json <metadata_dir> <rotulos_dir>
import csv, json, os, sys, re
import numpy as np

classes = json.load(open(sys.argv[1], encoding="utf-8"))
meta, lab = sys.argv[2], sys.argv[3]
slug_idx = {c["slug"]: i for i, c in enumerate(classes)}
from n5k_map import build
en2slug = build(classes)
idx = json.load(open(os.path.join(lab, "index.json"), encoding="utf-8"))
logits = np.load(os.path.join(lab, "logits.npy")).astype(np.float32)
row_of = {}
for i, f in enumerate(idx["files"]):
    m = re.search(r"(dish_\d+)", f)
    if m:
        row_of[m.group(1)] = i
hits = {1: 0, 3: 0, 5: 0, 10: 0}; fam = {1: 0, 3: 0, 5: 0}; total = 0; per = {}
famof = lambda s: s.split('_')[0]
for fn in ("dish_metadata_cafe1.csv", "dish_metadata_cafe2.csv"):
    for row in csv.reader(open(os.path.join(meta, fn), encoding="utf-8")):
        d = row[0]
        if d not in row_of:
            continue
        r = logits[row_of[d]]; order = list(np.argsort(-r))
        ings = row[6:]
        seen = set()
        for j in range(0, len(ings) - 6, 7):
            name, grams = ings[j + 1].strip().lower(), float(ings[j + 2] or 0)
            s = en2slug.get(name)
            if not s or grams < 15 or s in seen:
                continue
            seen.add(s); total += 1
            rank = order.index(slug_idx[s]) + 1
            for k in hits:
                hits[k] += rank <= k
            top = [classes[o]['slug'] for o in order[:5]]
            for k in fam:
                fam[k] += any(famof(t) == famof(s) for t in top[:k])
            p = per.setdefault(s, [0, 0]); p[0] += 1; p[1] += rank <= 5
print("itens avaliados", total)
for k in fam:
    print(f"familia top-{k}: {fam[k] / max(total, 1):.1%}")
for k in hits:
    print(f"top-{k}: {hits[k] / max(total, 1):.1%}")
worst = sorted(((v[1] / v[0], s, v[0]) for s, v in per.items() if v[0] >= 15))[:15]
print("piores (top-5, n>=15):", ", ".join(f"{s} {a:.0%} (n={n})" for a, s, n in worst))
