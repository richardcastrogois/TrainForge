# Professor ajustado, passo 2: parte dos vetores de texto do SigLIP (zero-shot) e ajusta uma camada linear
# com os rótulos humanos (Nutrition5k de treino + Open Images), presa ao ponto de partida por regularização.
# Mede contra a validação do Nutrition5k (mesmos pratos separados do aluno) e grava novas marcações "*_probe".
# Uso: python teacher_probe.py classes_final.json <raiz .local/fotos-alimentos>
import csv, json, os, random, re, sys, unicodedata
import numpy as np, torch

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from n5k_map import build  # noqa: E402
from train_student import OI_MAP  # noqa: E402

PENALTY = 1.0  # recortes valem um pouco menos que a foto inteira, como no professor original


def grid(logits):  # [N,V,C] -> [N,C]; V=1 quando só a foto inteira foi guardada
    if logits.shape[1] == 1:
        return logits[:, 0]
    return torch.maximum(logits[:, 0], logits[:, 1:].max(1).values - PENALTY)


def metrics(scores, positives):
    p1 = p3 = hit5 = tot = n = old = 0
    for s, pos in zip(scores, positives):
        if not pos:
            continue
        top = np.argsort(-s)[:5]; n += 1
        p1 += top[0] in pos; p3 += any(t in pos for t in top[:3])
        hit5 += len(pos & set(top)); tot += len(pos); old += top[0] in pos and 1 or 0
    return {"fotos": n, "primeira_no_prato": round(p1 / n, 4), "algum_nas_3": round(p3 / n, 4),
            "ingredientes_top5": round(hit5 / tot, 4)}


def main():
    classes = json.load(open(sys.argv[1], encoding="utf-8")); C = len(classes); root = sys.argv[2]
    si = {c["slug"]: i for i, c in enumerate(classes)}
    emb_root = os.path.join(root, "emb")
    text = np.load(os.path.join(emb_root, "text.npz"))
    # Medido em 22/11: textos em português derrubam o zero-shot (8% sozinhos, 53% misturados, contra 65% em inglês).
    W0 = text["en"].astype(np.float32)
    scale, bias = float(text["scale"]), float(text["bias"])

    def load(src):
        idx = json.load(open(os.path.join(emb_root, src, "index.json"), encoding="utf-8"))["files"]
        return idx, np.load(os.path.join(emb_root, src, "emb.npy"), mmap_mode="r")

    # Nutrition5k: ingredientes >= 15 g, mesma divisão por prato do aluno (seed 7, 20%)
    en2slug = build(classes); gt = {}
    for fn in ("dish_metadata_cafe1.csv", "dish_metadata_cafe2.csv"):
        for row in csv.reader(open(os.path.join(root, "nutrition5k", "metadata", fn), encoding="utf-8")):
            ings = row[6:]; pos = set()
            for j in range(0, len(ings) - 6, 7):
                s = en2slug.get(ings[j + 1].strip().lower())
                if s and float(ings[j + 2] or 0) >= 15:
                    pos.add(si[s])
            gt[row[0]] = pos
    n_files, n_emb = load("nutrition5k")
    dish = [re.search(r"(dish_\d+)", f).group(1) for f in n_files]
    random.seed(7); dishes = sorted(set(dish)); random.shuffle(dishes); val_d = set(dishes[: len(dishes) // 5])
    rest = [d for d in dishes if d not in val_d]; dev_d = set(rest[: len(rest) // 10])  # escolha da regularização
    n_pos = [gt.get(d, set()) for d in dish]
    n_split = ["val" if d in val_d else "dev" if d in dev_d else "train" for d in dish]

    # Open Images: rótulos humanos positivos mapeados por nome (somente positivos são confiáveis)
    name2slug = {c["en"].lower(): c["slug"] for c in reversed(classes)}
    name2slug.update({k.lower(): v for k, v in OI_MAP.items()})
    oi_lab = {r["file"].replace("\\", "/"): {si[name2slug[l.lower()]] for l in r["labels"] if l.lower() in name2slug}
              for r in json.load(open(os.path.join(root, "openimages", "manifest.json"), encoding="utf-8"))["images"]}
    o_files, o_emb = load("openimages")
    o_pos = [oi_lab.get(f.replace("\\", "/"), set()) for f in o_files]

    # Commons: rótulo fraco quando a categoria da foto é o nome de uma classe (pratos brasileiros).
    # Metade escolhe a regularização, metade só mede. Sem isso o ajuste rebaixa o que nunca teve rótulo.
    norm = lambda t: unicodedata.normalize("NFKD", t.lower()).encode("ascii", "ignore").decode()
    base = lambda f: os.path.basename(f.replace(chr(92), "/"))
    cat = {base(f["file"]): norm(f.get("category", "").replace("Category:", "").replace("_", " "))
           for f in json.load(open(os.path.join(root, "commons", "manifest.json"), encoding="utf-8"))["files"]}
    names = [(i, norm(c["pt"])) for i, c in enumerate(classes) if len(c["pt"]) > 4]
    c_files, c_emb = load("commons"); c_rows, c_pos = [], []
    for r, f in enumerate(c_files):
        k = cat.get(base(f), "")
        pos = {i for i, n in names if k and (k == n or k.startswith(n + " "))}
        if pos:
            c_rows.append(r); c_pos.append(pos)
    c_dev, c_test = [j for j in range(len(c_rows)) if j % 2 == 0], [j for j in range(len(c_rows)) if j % 2 == 1]

    dev = "cuda" if torch.cuda.is_available() else "cpu"
    def tens(a, rows): return torch.tensor(np.asarray(a[rows], np.float32), device=dev)
    tr_n = [i for i, s in enumerate(n_split) if s == "train"]; dv_n = [i for i, s in enumerate(n_split) if s == "dev"]
    va_n = [i for i, s in enumerate(n_split) if s == "val"]
    tr_o = [i for i, p in enumerate(o_pos) if p]
    Xn, Xd, Xv = tens(n_emb, tr_n), tens(n_emb, dv_n), tens(n_emb, va_n)
    def target(pos_list):
        y = torch.zeros(len(pos_list), C, device=dev)
        for r, p in enumerate(pos_list):
            y[r, list(p)] = 1
        return y
    Yn = target([n_pos[i] for i in tr_n])
    Yo = target([o_pos[i] for i in tr_o])
    # Só ajusta classes com rótulo humano; as demais ficam exatamente no zero-shot.
    covered = ((Yn.sum(0) + Yo.sum(0)) > 0).float()
    Xc = tens(c_emb, c_rows)

    def logits(W, b, X):  # X [N,5,D]
        return grid(scale * torch.einsum("nvd,cd->nvc", X, W) + b)

    def fit(lam, epochs=30):
        W = torch.tensor(W0, device=dev, requires_grad=True); b = torch.full((C,), bias, device=dev, requires_grad=True)
        Wref = torch.tensor(W0, device=dev); opt = torch.optim.Adam([W, b], lr=2e-4)
        bce = torch.nn.BCEWithLogitsLoss(reduction="none"); g = torch.Generator().manual_seed(7)
        for _ in range(epochs):
            for part in torch.randperm(len(tr_o), generator=g).split(1024):
                xo = tens(o_emb, [tr_o[i] for i in part.tolist()])
                nb = torch.randint(len(tr_n), (256,), generator=g)
                lo = bce(logits(W, b, xo), Yo[part.to(dev)])
                lo = (lo * (Yo[part.to(dev)] + 0.05 * (1 - Yo[part.to(dev)])) * covered).mean()  # OI: negativos fracos
                ln = (bce(logits(W, b, Xn[nb.to(dev)]), Yn[nb.to(dev)]) * covered).mean()
                loss = lo + ln + lam * ((W - Wref) ** 2).sum()
                opt.zero_grad(); loss.backward()
                W.grad *= covered[:, None]; b.grad *= covered
                opt.step()
        return W.detach(), b.detach()

    def score(W, b, X):
        with torch.no_grad():
            return torch.cat([logits(W, b, X[i:i + 512]) for i in range(0, len(X), 512)]).cpu().numpy()

    W0t = torch.tensor(W0, device=dev); b0 = torch.full((C,), bias, device=dev)
    def br(W, b, part):
        sc = score(W, b, Xc); return metrics(sc[part], [c_pos[j] for j in part])
    report = {"classes_com_rotulo": int(covered.sum().item()), "fotos_br": len(c_rows),
              "zero_shot_en": metrics(score(W0t, b0, Xv), [n_pos[i] for i in va_n]), "zero_shot_br": br(W0t, b0, c_test)}
    print(report, flush=True)
    best = None
    # offset: desconto nas classes ajustadas, para não passarem por cima das brasileiras parecidas (picanha x bife)
    for lam in (3e-2, 1e-2, 3e-3, 1e-3):
        W, b_fit = fit(lam)
        for off in (0.0, 1.0, 2.0, 3.0, 4.0):
            b = b_fit - off * covered
            m = metrics(score(W, b, Xd), [n_pos[i] for i in dv_n]); mb = br(W, b, c_dev)
            crit = (m["primeira_no_prato"] + mb["primeira_no_prato"]) / 2
            print("lambda", lam, "offset", off, "dev", m["primeira_no_prato"], "br", mb["primeira_no_prato"], "criterio", round(crit, 4), flush=True)
            if best is None or crit > best[0]:
                best = (crit, (lam, off), W, b)
    _, (lam, off), W, b = best
    report["lambda"] = lam; report["offset"] = off
    report["probe_val"] = metrics(score(W, b, Xv), [n_pos[i] for i in va_n])
    report["probe_br"] = br(W, b, c_test)
    print(report, flush=True)
    json.dump(report, open(os.path.join(root, "modelo", "teacher_probe_eval.json"), "w"), indent=1)
    # novas marcações, com caminhos relativos às mesmas bases que train_student usa
    bases = {"nutrition5k": ("n5k_probe", os.path.join(root, "nutrition5k", "imagery")),
             "openimages": ("openimages_probe", os.path.join(root, "openimages")),
             "commons": ("commons_probe", os.path.join(root, "commons"))}
    for src, (name, base) in bases.items():
        files, emb = load(src); out = os.path.join(root, "rotulos", name); os.makedirs(out, exist_ok=True)
        lg = np.concatenate([score(W, b, tens(emb, list(range(i, min(i + 2048, len(files)))))) for i in range(0, len(files), 2048)])
        rel = [os.path.relpath(os.path.join(root, src, f), base) for f in files]
        np.save(os.path.join(out, "logits.npy"), lg.astype(np.float16))
        json.dump({"teacher": "siglip2 + camada ajustada", "lambda": lam, "offset": off, "files": rel}, open(os.path.join(out, "index.json"), "w", encoding="utf-8"))
        print("marcado", src, len(files), flush=True)
    print("DONE")


if __name__ == "__main__":
    main()
