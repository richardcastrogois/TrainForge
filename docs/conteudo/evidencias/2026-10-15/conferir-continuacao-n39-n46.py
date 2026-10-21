"""Offline documentary integrity checks; no app, clinical or accuracy certification."""
from pathlib import Path
from collections import Counter
import hashlib, json, re, subprocess
from urllib.parse import unquote

REPO = Path(__file__).resolve().parents[4]
BASE = Path(__file__).resolve().parent
checks = []
def read(p):
    return json.loads(Path(p).read_text(encoding="utf-8-sig"))
def check(name, condition):
    checks.append({"check": name, "passed": bool(condition)})
    if not condition:
        raise AssertionError(name)

folders = {n: next(p for p in BASE.iterdir() if p.is_dir() and p.name.startswith(f"n{n}-")) for n in range(39,47)}
for n,p in folders.items():
    state, audit = read(p/"estado.json"), read(p/"auditoria-fechamento.json")
    check(f"N{n} research-only closure", state["researchClosed"] and audit["researchClosed"] and not state.get("appImplemented",False) and not audit.get("releaseApproved",False))
    if n>39:
        check(f"N{n} started after prior closure", state.get(f"startedAfterN{n-1}ResearchClosure") is True)
    check(f"N{n} JSON parses", all(read(x) is not None for x in p.glob("*.json")))

n18=BASE/"n18i-retomada"
check("N18 modular research closed", read(n18/"estado.json")["researchClosed"] and read(n18/"auditoria-pendencias.json")["researchClosed"])
check("N18 all current criteria documented", all(c["met"] for c in read(n18/"auditoria-pendencias.json")["criteria"]))
queue=read(REPO/"docs/conteudo/evidencias/2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json")
check("No active niche; N15 current modular research closed", queue["currentActiveNiche"] is None and queue["activeComplement"] is None and not queue["pausedNiches"] and all(x["researchClosed"] for x in queue["niches"] if x["niche"]=="N15"))
check("N19/N20 modular closure, N21 closed", all(x["complementStatus"]=="concluido_pesquisa_modular" for x in queue["niches"] if x["niche"] in ["N19","N20"]) and queue["n21Allowed"] and queue["n21Status"]=="concluida_pesquisa_modular")
check("All current scoped research closed without publication", queue["allPreviousComplementsResearchClosed"] and queue["allAnalysesClosed"] and queue["allAnalysesExceptPausedN15ResearchClosed"] and not queue["currentExecutionAudit"]["releaseApproved"])
consolidated=read(BASE/"consolidacao-n01-n46.json")
check("46 unique niches accounted for", len(consolidated["items"])==46 and {x["niche"] for x in consolidated["items"]}=={f"N{i:02d}" for i in range(1,47)})
check("40 closed scopes, six documented reuses, N15 modular", sum(x["researchState"]=="concluida_no_recorte" for x in consolidated["items"])==40 and sum(x["researchState"]=="reuso_documentado" for x in consolidated["items"])==6 and not [x for x in consolidated["items"] if not x["researchClosed"]])
for x in consolidated["items"]:
    check("Consolidated evidence exists: "+x["niche"],(REPO/"docs/conteudo/evidencias"/x["evidence"]).is_file())
for x in queue["niches"]:
    if 6<=int(x["niche"][1:])<=17 and x["niche"] not in ["N14","N15"]:
        for f in x.get("closureEvidence",[]):
            older=read(REPO/"docs/conteudo/evidencias"/f)
            check("Prior original closure confirmed: "+x["niche"],older["researchClosureApproved"] and older["status"]=="concluido_para_pesquisa" and not older["releaseApproved"] and not older["appImplemented"])
for n,folder in [(19,"n19i-retomada"),(20,"n20i-retomada"),(21,"n21-praca")]:
    d=read(BASE/folder/"auditoria-fechamento.json")
    check(f"N{n} modular closure and no release", d["researchClosed"] and all(x["met"] for x in d["criteria"]) and not d["releaseApproved"] and not d["appImplemented"])
p18=read(n18/"pacote-modular-academia.json")
p21=read(BASE/"n21-praca/pacote-modular-praca.json")
check("N18 nine components and no invented numeric prescription",len(p18["items"])==9 and not p18["numericalPrescriptionInvented"] and not p18["newCompositionReviewedByClinician"])
check("N20 nine textual maps",len(read(BASE/"n20i-retomada/mapa-instrucao-textual.json")["maps"])==9)
check("N21 nine selected, two excluded ambiguous methods",len(p21["items"])==9 and len(p21["notSelected"])==2 and not p21["sourceProgramme"]["wholeProgrammeOperationallyReplicated"])
check("N21 no generated calendar or clinical certification",not p21["newFixedSessionSequenceCreated"] and not p21["numericalPrescriptionInvented"] and not p21["newCombinationClinicallyValidated"] and not p21["newCompositionReviewedByClinician"] and not p21["releaseApproved"])
check("N21 source doses not universal mapping",all(i["doseSourceExample"]["concentricSeconds"]==1 and i["doseSourceExample"]["eccentricSeconds"]==1 and not i["automaticDeliveryApproved"] and not i["rights"]["mediaSelected"] for i in p21["items"]))
for f in [BASE/"n21-praca/n21-marcos2024-pdf.evidencia.json",BASE/"n21-praca/n21-chow2021-pdf.evidencia.json",BASE/"n21-praca/n21-pereira2017-manual.evidencia.json",BASE/"n20i-retomada/n20r-sousa2025-pdf.evidencia.json"]:
    d=read(f);body=(f.parent/d["bodyFile"]).read_bytes()
    check("Actual PDF body and original hash: "+f.stem,d["status"]==200 and body.startswith(b"%PDF-") and hashlib.sha256(body).hexdigest()==d["sha256"])
check("N21 excluded restricted sources not selected components",all(i["sourceId"]=="PR256" for i in p21["items"]))

cleanup_files=[folders[39]/"limpeza-ensaio.json",folders[41]/"limpeza-ensaio.json",folders[43]/"limpeza-ensaio.json",n18/"limpeza-leitura.json",n18/"limpeza-apex.json",n18/"limpeza-usu.json",BASE/"n20i-retomada/limpeza-sousa.json",BASE/"n21-praca/limpeza-barbosa.json",BASE/"n21-praca/limpeza-leitura.json"]
removed=0
for f in cleanup_files:
    d=read(f); target=Path(d.get("exactPath", d.get("path",d.get("absoluteTarget"))))
    check("Cleanup absent: "+target.name, d.get("directoryAbsentVerified",d.get("verifiedAbsent",d.get("absent",False))) and not target.exists())
    removed+=int(d.get("deletedBytes",d.get("fileBytesRemoved",d.get("bytes",0))))
check("Nine cleanup receipts including final N21 reading", len(cleanup_files)==9 and removed==2665357099)

r39=read(folders[39]/"resultado-ensaio-local.json")
s39=read(folders[39]/"resultado-ensaio-suplementar.json")
cases=r39["cases"]+s39["cases"]
executed=[c for c in cases if "top5" in c]
check("N39 seven actual inferences, two unavailable originals",len(executed)==7 and sum("error" in c for c in cases)==2)
check("N39 known erroneous soup and blank outputs retained", any(c["top5"][0]["label"]=="ramen" for c in executed) and any(c.get("id")=="synthetic-black" and c["top5"][0]["label"]=="breakfast_burrito" for c in executed))
check("N39 no population accuracy or calibration claim", not r39["populationAccuracyEstimated"] and not r39["confidenceCalibrated"] and not r39["appTested"])
check("N39 strict CPU load", r39["device"]=="cpu" and r39["weightsOnlyLoad"] and r39["strictStateLoad"] and not r39["missingKeys"] and not r39["unexpectedKeys"])

rp=read(folders[43]/"resultado-pose-local.json")
check("N43 two inputs with manual person boxes",len(rp["cases"])==2 and all(not c["detectorExecuted"] and c["heatmapsShape"]==[1,17,64,48] for c in rp["cases"]))
check("N43 no temporal/exercise/clinical validation claim",not rp["exerciseClassifierTested"] and not rp["videoOrRepetitionCounterTested"] and not rp["clinicalValidation"] and not rp["independentKeypointGroundTruth"])
check("N43 no face landmarks persisted",all(len(c["bodyLandmarksExcludingFace"])==12 and all(k["id"]>=5 for k in c["bodyLandmarksExcludingFace"]) for c in rp["cases"]))

reports=[(39,"confirmacao-conferida.json",14),(40,"verificacoes-quantidade.json",17),(41,"verificacoes-parser.json",11),(42,"verificacoes-gtin.json",9),(43,"verificacoes-pose.json",6),(44,"conferencia-documental.json",3)]
for n,name,count in reports:
    d=read(folders[n]/name)
    check(f"N{n} retained report: {count} checks",len(d["checks"])==count and all(x["passed"] for x in d["checks"]))
check("N42 text validation is not optical scan",read(folders[42]/"verificacoes-gtin.json")["opticalDecodeTested"] is False)
check("N45 no actual participants",read(folders[45]/"auditoria-fechamento.json")["actualParticipants"]==0)

cards=read(n18/"fichas-pesos-livres-nia2018.json")
check("Historical N18 three-card snapshot preserved, current package separate",len(cards["items"])==3 and not cards["essentialMachineInstructionsResolved"] and not cards["n18ResearchClosed"])
check("N18 no invented rest or photographic grant",all(i["dose"]["betweenSetRestSeconds"] is None and not i["photoSelected"] for i in cards["items"]) and not cards["rights"]["photoOrVideoGrantObtained"])
rp18=(n18/cards["reusedSource"]["receipt"]).resolve();receipt=read(rp18)
check("Reused NIA original hash",hashlib.sha256((rp18.parent/receipt["bodyFile"]).read_bytes()).hexdigest()==cards["reusedSource"]["bodySha256"])
for entry in read(folders[44]/"contrato-acompanhamento.json")["sourceBasis"]:
    for f in [entry.get("file")]+entry.get("files",[]):
        if f:check("N44 source exists: "+f,(folders[44]/f).is_file())

catalog=read(REPO/"docs/conteudo/fontes.json")["sources"]
check("Catalogue source IDs unique",len({s["id"] for s in catalog})==len(catalog))
for s in catalog:
    if s["id"].startswith("PR") and 211<=int(s["id"][2:])<=258:
        check("Source evidence exists: "+s["id"],(REPO/"docs/conteudo"/s["localEvidence"]).is_file())
index=read(REPO/"docs/conteudo/evidencias/retornos-observados.json")["records"]
check("No mismatched index hashes",all(x.get("originalBodyHashMatches") is not False for x in index))

md=[BASE/"continuacao-n39-n46.md",n18/"relatorio.md",BASE/"n19i-retomada/relatorio.md",BASE/"n20i-retomada/relatorio.md",BASE/"n21-praca/relatorio.md"]+[folders[n]/"relatorio.md" for n in range(40,47)]
links=0
for f in md:
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)",f.read_text(encoding="utf-8")):
        if target.startswith(("http://","https://","#")):continue
        target=unquote(target.split("#",1)[0].strip("<>"))
        check("Local Markdown target: "+str(f.relative_to(BASE))+" -> "+target,(f.parent/target).exists());links+=1
app_paths=["lib","android","ios","web","windows","linux","macos","test","pubspec.yaml","pubspec.lock"]
cmd=["git","-c","safe.directory=C:/dev/TrainForge/trainforge","status","--short","--"]+app_paths
result=subprocess.run(cmd,cwd=REPO,check=True,capture_output=True,text=True)
check("No changed functional app paths in git status",not result.stdout.strip())
output={"date":"2026-10-21","scope":"Offline documentary integrity; not app tests, accuracy certification, user study or clinical approval. N15 current selection separately checked in2026-10-21/n15c-composicao.","checks":checks,"passed":len(checks),"failed":0,"catalogueFamilies":len(catalog),"catalogueStatuses":dict(Counter(s["status"] for s in catalog)),"historicalGetCalls":len(index),"http200":sum(x["httpStatus"]==200 for x in index),"retainedBodyHashesMatching":sum(x.get("originalBodyHashMatches",False) for x in index),"temporaryFileBytesRemovedInHistoricalNineReceipts":removed,"localMarkdownLinksChecked":links,"currentActiveNiche":None,"n15Paused":False,"n15ResearchClosed":True,"allAnalysesClosedInDeclaredScopes":True,"graphifyScope":"lib code only; no semantic document indexing; current result in2026-10-21/n15c-composicao/graphify-resultado.json","releaseApproved":False}
(BASE/"verificacoes-continuacao-n39-n46.json").write_text(json.dumps(output,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({k:v for k,v in output.items() if k!="checks"},ensure_ascii=False))
