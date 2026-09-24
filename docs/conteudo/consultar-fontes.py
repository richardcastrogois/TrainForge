"""Consulta pequena da base editorial local, sem LLM, rede ou dependencias."""
import argparse
import collections
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument("--id")
parser.add_argument("--tema")
parser.add_argument("--estado")
parser.add_argument("--limite", type=int, default=10)
parser.add_argument("--gerar-indice", action="store_true")
args=parser.parse_args()
base=json.loads((ROOT/"fontes.json").read_text(encoding="utf-8"))
rows=base["sources"]
assert len({r["id"] for r in rows})==len(rows), "IDs duplicados"
assert all(r["status"] in base["statusDefinitions"] for r in rows), "Estado desconhecido"
assert all(r["urls"] and all(u.startswith("https://") for u in r["urls"]) for r in rows), "URL invalida"
for row in rows:
    if row.get("localEvidence"):
        assert (ROOT/row["localEvidence"]).is_file(), row["id"]+": evidencia local ausente"
if args.gerar_indice:
    labels={"exercicios":"Exercícios e demonstrações","programas":"Programas humanos e modalidades","ciencia":"Ciência, educação e triagem","atividades":"Atividades e gasto energético","alimentos":"Composição de alimentos e produtos","alimentacao_editorial":"Receitas, alimentação e educação","midia":"Imagens e vídeos"}
    out=["# Catálogo comparativo de fontes", "", "Gerado de [fontes.json](fontes.json) em "+base["updatedAt"]+". "+str(len(rows))+" fontes/famílias; não é uma contagem de APIs nem de fornecedores aprovados. Não editar esta tabela separadamente: atualizar o JSON e executar `consultar-fontes.py --gerar-indice`.","", "Todas as ligações remetem a fontes primárias. Para nível de evidência, amostras, data e próxima ação por fonte, consultar o JSON pelo ID. A primeira rodada é de 22/09; esta expansão é de 23/09. Páginas bloqueadas ou apenas indexadas estão identificadas no JSON.", ""]
    for status,meaning in base["statusDefinitions"].items():out.append("- **"+status+"**: "+meaning)
    for topic,title in labels.items():
        out += ["", "## "+title,"", "| ID / fonte | Situação | Direitos e operação | Achado |", "|---|---|---|---|"]
        for row in rows:
            if row["topic"]!=topic:continue
            cells=[f'**{row["id"]}** · [{row["name"]}]({row["urls"][0]})',row["status"],row["rights"],row["finding"]]
            out.append("| "+" | ".join(c.replace("|", " / ").replace("\n", " ") for c in cells)+" |")
    (ROOT/"catalogo-fontes.md").write_text("\n".join(out)+"\n",encoding="utf-8")
    print(json.dumps({"fontes":len(rows),"estados":dict(collections.Counter(r['status'] for r in rows)),"gerado":"catalogo-fontes.md"},ensure_ascii=True))
else:
    if args.id: rows=[r for r in rows if r["id"]==args.id]
    if args.tema: rows=[r for r in rows if r["topic"]==args.tema]
    if args.estado: rows=[r for r in rows if r["status"]==args.estado]
    if not any((args.id,args.tema,args.estado)):
        output={"total":len(rows),"temas":dict(collections.Counter(r["topic"] for r in rows)),"estados":dict(collections.Counter(r["status"] for r in rows))}
    else:
        output={"total":len(rows),"mostrando":min(max(args.limite,0),len(rows)),"sources":rows[:max(args.limite,0)]}
    print(json.dumps(output,ensure_ascii=True,indent=2))
