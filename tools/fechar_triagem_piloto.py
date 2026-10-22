"""Fecha a triagem documental: cada ativo fica permitido por operacao ou excluido."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
from revisar_conteudo_local import digest, review_bundle

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = "content/manifests/pilot-dispositions.json"
SOURCES = {
 "PR42": ("support_path_not_available", "Final localized presentation not professionally reviewed; conservative supported route has no actual provider."),
 "PR68": ("live_physiotherapist_not_available", "Source requires live two-way physiotherapist support; thesis expression is not licensed by the article and final presentation is unreviewed."),
 "PR261": ("facilitated_delivery_not_available", "Facilitated learning/review and final localized presentation are not available; federal hosting is not a universal asset licence."),
 "PR28": ("screening_and_localized_delivery_pending", "Original 2019 protocol retained; study screening/familiarization and final localized rights/review are not an app delivery already implemented."),
 "PR256": ("equipment_population_and_expression_pending", "Specific OFE model/population and final localized presentation not cleared for arbitrary public-park machines."),
 "PR244": ("equipment_variant_and_expression_pending", "Textual research mapping is not a complete reviewed instruction for the machine available to the user."),
 "PR167": ("population_variant_and_expression_pending", "Military-source mapping does not automatically establish the user's population, machine variant or reviewed final localized presentation."),
 "CI05": ("localized_presentation_pending", "Institutional source facts retained; final translated/adapted instruction and appropriate delivery are not professionally reviewed.")}


def classify(candidate, decisions):
    reviewed = review_bundle(candidate, decisions)
    allow = {a["id"]: a["allowedOperations"] for a in reviewed["assets"]}
    findings = {r["assetId"]:r for r in decisions["portugueseInstructionFindings"]}
    rows=[]
    for a in candidate["assets"]:
        reasons=[]; codes=[]
        def add(code, reason):
            if code not in codes:codes.append(code);reasons.append(reason)
        if a["id"] not in allow:
            if a["sourceId"] == "EX01":
                add("professional_authorship_not_verified", "Community attribution/licence is recorded; relevant professional qualification linked to this exercise is not verified.")
                if a["kind"]=="instruction" and a["locale"]!="pt":add("localization_not_reviewed", "Original source language preserved; no reviewed Portuguese instruction selected.")
                if a["kind"]=="media":
                    add("media_not_cleared_for_pilot", "Media has no cleared matching professionally authored instruction in this pilot; no media copied or used as teaching.")
                    if a["content"].get("aiGenerated") is True:add("ai_generated_media_excluded", "Source flags this media as AI-generated.")
                if not a["rights"].get("attribution"):add("attribution_unresolved", "Credit for this individual asset is missing in the snapshot.")
                if a["content"].get("movementRef")=="wger:movement:1022" or a["id"]=="wger:movement:1022":add("semantic_conflict", "Existing ID1022 semantic conflict retained; no variant silently selected.")
                if a["id"] in findings:add("portuguese_text_finding", findings[a["id"]]["reason"])
                if a["id"]=="wger:movement:1670":add("variant_conflict", findings["wger:translations:2794"]["reason"])
            else:
                code, reason = SOURCES[a["sourceId"]];add(code,reason)
                if a["kind"] in {"instruction","program","collection"}:add("final_presentation_not_cleared", "Research closure and source author evidence do not approve the final app expression, population or delivery.")
                if a["kind"]=="collection":add("not_a_prescribed_program", "Documentary component collection; no new session, numerical prescription or efficacy inherited.")
        rows.append({"assetId":a["id"],"assetSha256":digest(a),"kind":a["kind"],"sourceId":a["sourceId"],"evidence":a["evidence"],
                     "decision":"metadata_consultation" if a["id"] in allow else "excluded_from_pilot", "allowedOperations":allow.get(a["id"],[]),
                     "exclusionCodes":codes,"reasons":reasons,"practiceAllowed":False,"reviewer":decisions["reviewer"]})
    if len(rows)!=len({r["assetId"] for r in rows}) or {r["assetId"] for r in rows}!={a["id"] for a in candidate["assets"]}:raise ValueError("Cobertura incompleta")
    if any(not r["allowedOperations"] and not r["exclusionCodes"] for r in rows):raise ValueError("Exclusao sem motivo")
    return {"schemaVersion":"1.0.0","date":"2026-10-21","reviewComplete":True,"allAssetsPublishable":False,"clinicalApproval":False,
            "scope":"Completed documentary disposition; excluded assets remain excluded. Not professional review, clinical clearance, app or release testing.",
            "candidateDigest":digest(candidate),"reviewDecisionsDigest":digest(decisions),"counts":dict(Counter(r["decision"] for r in rows)),
            "totalAssets":len(rows),"practiceAllowed":0,"rows":rows}


def main():
    ap=argparse.ArgumentParser();ap.add_argument("--write",action="store_true");ap.add_argument("--check",action="store_true");args=ap.parse_args()
    if not(args.write or args.check):ap.error("Use --write ou --check")
    def read(p):return json.loads((ROOT/p).read_text(encoding="utf-8-sig"))
    decisions=read("content/manifests/pilot-review-decisions.json")
    if hashlib.sha256((ROOT/decisions["sourceBundle"]["path"]).read_bytes()).hexdigest()!=decisions["sourceBundle"]["sha256"]:raise ValueError("Lote mudou")
    result=classify(read(decisions["sourceBundle"]["path"]),decisions)
    text=json.dumps(result,ensure_ascii=False,indent=2)+"\n"
    if args.write:(ROOT/OUTPUT).write_text(text,encoding="utf-8")
    if args.check and (ROOT/OUTPUT).read_text(encoding="utf-8")!=text:raise ValueError("Triagem desatualizada")
    print(json.dumps({k:result[k] for k in ("reviewComplete","allAssetsPublishable","totalAssets","counts","practiceAllowed")}))


if __name__=="__main__":main()
