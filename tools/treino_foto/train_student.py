# Aluno: modelo pequeno treinado com as marcações do professor + rótulos reais das bases.
# Uso: python train_student.py <classes_final.json> <raiz .local/fotos-alimentos> <saida> [arquitetura] [epocas]
import csv, json, os, random, re, sys, time
import numpy as np, torch, timm
from PIL import Image
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as T

# Rótulos do Open Images -> classe, quando o nome em inglês não coincide.
OI_MAP = {"Rice": "arroz_branco", "Bread": "pao_forma", "Egg": "ovo_cozido", "Cheese": "mussarela", "Chicken": "frango_assado", "Meat": "bife",
             "Fish": "peixe_grelhado", "Cake": "bolo_simples", "Cookie": "cookie", "Juice": "suco_fruta", "Tea": "cha", "Wine": "vinho",
             "Beer": "cerveja", "Coffee": "cafe", "Soup": "sopa", "Salad": "salada_verde", "Hamburger": "hamburguer_lanche", "Hot dog": "cachorro_quente",
             "Noodle": "macarrao", "Pasta": "macarrao", "Potato": "batata_cozida", "Apple": "maca", "Grape": "uva", "Carrot": "cenoura",
             "Tomato": "tomate", "Banana": "banana", "Doughnut": "donut", "Ice cream": "sorvete", "Pancake": "panqueca", "Sausage": "linguica",
             "Corn": "milho_verde", "Bean": "feijao_carioca", "Mushroom": "cogumelo", "Pumpkin": "abobora", "Cucumber": "pepino", "Onion": "cebola",
             "Cabbage": "repolho", "Pear": "pera", "Peach": "pessego", "Mango": "manga", "Pineapple": "abacaxi", "Watermelon": "melancia",
             "Strawberry": "morango", "Lemon": "limao", "Orange": "laranja", "Coconut": "coco", "Pomegranate": "roma", "Shrimp": "camarao",
             "Prawn": "camarao", "Crab": "caranguejo", "Lobster": "lagosta", "Oyster": "ostra", "Sushi": "sushi", "Pizza": "pizza", "Waffle": "waffle",
             "Muffin": "muffin", "Croissant": "croissant", "Bagel": "bagel", "Pretzel": "pretzel", "Popcorn": "pipoca", "Guacamole": "guacamole",
             "Burrito": "burrito", "Taco": "taco", "Omelette": "omelete", "Fried egg": "ovo_frito", "French fries": "batata_frita",
             "Broccoli": "brocolis", "Cauliflower": "couve_flor", "Zucchini": "abobrinha", "Eggplant": "berinjela", "Artichoke": "alcachofra",
             "Lettuce": "alface", "Radish": "rabanete", "Garlic": "alho", "Pea": "ervilha", "Peanut": "amendoim", "Butter": "manteiga",
             "Milk": "leite", "Chocolate": "chocolate", "Candy": "bala", "Curry": "curry", "Papaya": "mamao", "Kiwifruit": "kiwi",
             "Cantaloupe": "melao", "Grapefruit": "toranja", "Potato chip": "batata_chips", "Soft drink": "refrigerante", "Cocktail": "coquetel",
             "Beetroot": "beterraba", "Yam": "cara", "Feijoada": "feijoada", "Farofa": "farofa", "Moqueca": "moqueca", "Tapioca": "tapioca",
             "Couscous": "cuscuz_marroquino", "Lasagne": "lasanha", "Polenta": "polenta", "Steak": "bife", "Fried chicken": "frango_frito",
             "Barbecue": "churrasco", "Guava": "goiaba", "Empanada": "pastel", "Biscuit": "biscoito_maisena", "Cracker": "cream_cracker",
             "Waffles": "waffle", "Coriander": "coentro", "Octopus": "polvo", "Brownie": "brownie", "Cheesecake": "cheesecake"}


class DS(Dataset):
    def __init__(s, xs, tf, C, TEMP): s.xs, s.tf, s.C, s.TEMP = xs, tf, C, TEMP
    def __len__(s): return len(s.xs)
    def __getitem__(s, i):
        p, v, pos, _ = s.xs[i]
        y = torch.sigmoid(torch.tensor(v) / s.TEMP)
        m = torch.zeros(s.C)
        for k in pos:
            y[k] = 1.0; m[k] = 1.0
        return s.tf(Image.open(p).convert("RGB")), y, m


def main():
    classes = json.load(open(sys.argv[1], encoding="utf-8")); C = len(classes)
    root, out = sys.argv[2], sys.argv[3]
    arch = sys.argv[4] if len(sys.argv) > 4 else "tf_efficientnet_lite0.in1k"
    epochs = int(sys.argv[5]) if len(sys.argv) > 5 else 12
    os.makedirs(out, exist_ok=True)
    random.seed(7); torch.manual_seed(7)
    slug_idx = {c["slug"]: i for i, c in enumerate(classes)}
    TEMP = 2.0  # suaviza o professor
    TEACHER = os.environ.get("TEACHER", "grid")  # "probe" = professor ajustado

    def load_teacher(name, base):
        d = os.path.join(root, "rotulos", name)
        if not os.path.exists(os.path.join(d, "index.json")):
            return {}
        idx = json.load(open(os.path.join(d, "index.json"), encoding="utf-8"))
        lg = np.load(os.path.join(d, "logits.npy")).astype(np.float32)
        return {os.path.normpath(os.path.join(base, f)): lg[i] for i, f in enumerate(idx["files"])}

    items = []  # (caminho, vetor professor, positivos reais, grupo)
    # Nutrition5k: ingredientes reais
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from n5k_map import build  # noqa: E402
    en2slug = build(classes)
    n5k_base = os.path.join(root, "nutrition5k", "imagery")
    tn = load_teacher("n5k_" + TEACHER, n5k_base)
    gt = {}
    for fn in ("dish_metadata_cafe1.csv", "dish_metadata_cafe2.csv"):
        for row in csv.reader(open(os.path.join(root, "nutrition5k", "metadata", fn), encoding="utf-8")):
            ings = row[6:]; pos = set()
            for j in range(0, len(ings) - 6, 7):
                s = en2slug.get(ings[j + 1].strip().lower())
                if s and float(ings[j + 2] or 0) >= 15:
                    pos.add(slug_idx[s])
            gt[row[0]] = pos
    dishes = sorted({re.search(r"(dish_\d+)", p).group(1) for p in tn})
    random.shuffle(dishes); val_dishes = set(dishes[: len(dishes) // 5])
    for p, v in tn.items():
        d = re.search(r"(dish_\d+)", p).group(1)
        items.append((p, v, gt.get(d, set()), "val" if d in val_dishes else "train"))
    # Open Images: rótulos humanos mapeados por nome
    oi = json.load(open(os.path.join(root, "openimages", "manifest.json"), encoding="utf-8")) if os.path.exists(os.path.join(root, "openimages", "manifest.json")) else {"images": []}
    name2slug = {}
    for c in classes:
        name2slug.setdefault(c["en"].lower(), c["slug"])
    for k, v in OI_MAP.items():
        name2slug[k.lower()] = v
    to = load_teacher("openimages_" + TEACHER, os.path.join(root, "openimages"))
    for r in oi["images"]:
        p = os.path.normpath(os.path.join(root, "openimages", r["file"]))
        pos = {slug_idx[name2slug[l.lower()]] for l in r["labels"] if l.lower() in name2slug}
        if p in to:
            items.append((p, to[p], pos, "train"))
    tc = load_teacher("commons_" + TEACHER, os.path.join(root, "commons"))
    held_p = os.path.join(root, "rotulos", "br_holdout.json")  # fotos brasileiras só para medir
    # Fotos do Commons cuja categoria é o nome de uma classe: o rótulo conta como humano. Metade (ímpares) fica só
    # para medir; separar todas tira do aluno quase todos os exemplos desses pratos (medido em 23/11: 5,5% na 1ª).
    held_list = json.load(open(held_p, encoding="utf-8")) if os.path.exists(held_p) else []
    held = {os.path.normpath(os.path.join(root, "commons", h["file"])): (set(h["classes"]), j % 2 == 1) for j, h in enumerate(held_list)}
    for p, v in tc.items():
        pos, measure = held.get(p, (set(), False))
        items.append((p, v, pos, "br" if measure else "train"))
    if os.environ.get('LIMIT'): random.shuffle(items); items = items[:int(os.environ['LIMIT'])]
    train = [x for x in items if x[3] == "train"]; val = [x for x in items if x[3] == "val"]; br = [x for x in items if x[3] == "br"]
    print("treino", len(train), "validacao", len(val), "brasileiras", len(br), "professor", TEACHER, flush=True)

    model = timm.create_model(arch, pretrained=True, num_classes=C)
    cfg = timm.data.resolve_data_config({}, model=model)
    norm = T.Normalize(cfg["mean"], cfg["std"])
    tr_tf = T.Compose([T.RandomResizedCrop(224, scale=(0.5, 1.0)), T.RandomHorizontalFlip(), T.ColorJitter(0.3, 0.3, 0.2, 0.03), T.ToTensor(), norm])
    ev_tf = T.Compose([T.Resize(256), T.CenterCrop(224), T.ToTensor(), norm])

    dl = DataLoader(DS(train, tr_tf, C, TEMP), batch_size=64, shuffle=True, num_workers=6, persistent_workers=True, pin_memory=True)
    vl = DataLoader(DS(val, ev_tf, C, TEMP), batch_size=128, num_workers=4)
    bl = DataLoader(DS(br, ev_tf, C, TEMP), batch_size=128, num_workers=2) if br else None
    dev = "cuda"; model.to(dev)
    opt = torch.optim.AdamW(model.parameters(), lr=1e-3, weight_decay=0.02)
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, max_lr=1e-3, total_steps=epochs * len(dl), pct_start=0.1)
    scaler = torch.amp.GradScaler()
    bce = torch.nn.BCEWithLogitsLoss(reduction="none")

    def evaluate(loader=None):
        # 1/5: cada ingrediente; p1: 1ª sugestão é um alimento do prato; p3: algum acerto nas 3 primeiras
        model.eval(); hit = {1: 0, 5: 0, "p1": 0, "p3": 0}; tot = 0; fotos = 0
        with torch.no_grad():
            for x, y, m in (loader or vl):
                with torch.autocast("cuda", dtype=torch.float16):
                    o = model(x.to(dev)).float().cpu()
                top = o.topk(5, dim=1).indices
                for b in range(len(x)):
                    pos = set(m[b].nonzero().flatten().tolist())
                    if pos:
                        fotos += 1; t = top[b].tolist(); hit["p1"] += t[0] in pos; hit["p3"] += any(k in pos for k in t[:3])
                    for k in pos:
                        tot += 1; hit[5] += k in top[b].tolist(); hit[1] += k == top[b][0].item()
        model.train()
        return {k: v / max(tot if k in (1, 5) else fotos, 1) for k, v in hit.items()}, tot

    best = 0
    for ep in range(epochs):
        t0 = time.time()
        for x, y, m in dl:
            x, y, m = x.to(dev, non_blocking=True), y.to(dev), m.to(dev)
            with torch.autocast("cuda", dtype=torch.float16):
                o = model(x)
            loss = (bce(o.float(), y) * (1 + 4 * m)).mean()  # rótulos reais pesam mais
            opt.zero_grad(set_to_none=True); scaler.scale(loss).backward(); scaler.step(opt); scaler.update(); sched.step()
        r, tot = evaluate()
        print(f"epoca {ep + 1}/{epochs} perda {loss.item():.4f} val 1a no prato {r['p1']:.1%} algum nas 3 {r['p3']:.1%} ingredientes top-5 {r[5]:.1%} (n={tot}) {time.time() - t0:.0f}s", flush=True)
        if r["p1"] >= best:
            best = r["p1"]; torch.save(model.state_dict(), os.path.join(out, "student_best.pt"))
    if bl:
        model.load_state_dict(torch.load(os.path.join(out, "student_best.pt"))); rb, _ = evaluate(bl)
        print(f"brasileiras (fora do treino): 1a {rb['p1']:.1%} algum nas 3 {rb['p3']:.1%}", flush=True)
    json.dump({"arch": arch, "classes": [c["slug"] for c in classes], "best_val_p1": best, "teacher": TEACHER, "train": len(train), "val": len(val)},
              open(os.path.join(out, "student_meta.json"), "w", encoding="utf-8"), indent=1)
    print("DONE melhor 1a sugestao", f"{best:.1%}")

if __name__ == "__main__":
    main()
