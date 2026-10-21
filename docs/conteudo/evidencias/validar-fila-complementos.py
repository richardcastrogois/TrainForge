"""Check the research queue and prevent N21 while earlier complements remain open."""
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PATH = ROOT / "2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json"


def read(relative):
    path = (ROOT / relative).resolve()
    path.relative_to(ROOT)
    payload = path.read_bytes()
    return json.loads(payload), hashlib.sha256(payload).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(queue):
    rows = queue["niches"]
    require([r["niche"] for r in rows] == [f"N{i:02}" for i in range(1, 21)],
            "Expected all N01-N20")
    states = {"reuso_documentado_sem_nova_coleta", "pendente", "em_andamento",
              "concluido_para_pesquisa"}
    require(all(r["complementStatus"] in states and bool(r["findingOrRequiredScope"])
                and r["researchApprovedForPublication"] is False for r in rows),
            "Invalid scope/status or unsupported publication approval")
    active = [r for r in rows if r["complementStatus"] == "em_andamento"]
    require(len(active) <= 1, "Only one active niche")
    require(bool(active) == bool(queue["activeComplement"]), "Active pointer contradicts queue")
    order = queue["researchOrder"]
    require(len(order) == len(set(order)) and all(
        c.split("-")[0] in {r["niche"] for r in rows} for c in order),
        "Duplicate complement or N21 in earlier-complement queue")
    for row in rows:
        if row["complementStatus"] == "reuso_documentado_sem_nova_coleta":
            require(row["niche"] in {"N01", "N02", "N03", "N04", "N05", "N14"}
                    and row["newCollectionRequired"] is False, "Reuse scope changed silently")
        elif row["complementStatus"] == "concluido_para_pesquisa":
            refs = row.get("closureEvidence", [])
            expected = {c for c in order if c.split("-")[0] == row["niche"]}
            require(bool(refs), "Closure needs evidence")
            found = set()
            for ref in refs:
                spec, _ = read(ref)
                require(spec["status"] == "concluido_para_pesquisa"
                        and spec["researchClosureApproved"] is True
                        and bool(spec["researchClosureCriteria"])
                        and all(c["met"] is True for c in spec["researchClosureCriteria"]),
                        "Partial evidence cannot close research")
                found.add(spec["niche"])
            require(found == expected, "Some complements of this niche remain unclosed")
    closed = not any(r["complementStatus"] in {"pendente", "em_andamento"} for r in rows)
    require(queue["allPreviousComplementsResearchClosed"] is closed
            and queue["n21Allowed"] is closed, "N21 release flag contradicts queue")
    require(queue["n21Status"] == ("liberada_para_pesquisa" if closed else
            "aguardando_fechamento_dos_complementos"), "N21 status contradicts gate")
    active_spec = None
    active_hash = None
    if active:
        active_spec, active_hash = read(queue["activeEvidence"])
        require(active_spec["niche"] == queue["activeComplement"]
                and active_spec["niche"].split("-")[0] == active[0]["niche"],
                "Active complement/source mismatch")
        require(active_spec["status"] == "parcial"
                and active_spec["researchClosureApproved"] is False
                and any(c["met"] is False for c in active_spec["researchClosureCriteria"]),
                "Open complement cannot imply closure")
    return {
        "scope": queue["scope"], "date": queue["date"], "nichesChecked": len(rows),
        "states": dict(Counter(r["complementStatus"] for r in rows)),
        "activeComplement": queue["activeComplement"],
        "n21Allowed": closed, "allPreviousComplementsResearchClosed": closed,
        "activeEvidenceArtifactSha256": active_hash,
        "testType": "Documentary consistency, not clinical/app validation"
    }


def main():
    queue = json.loads(PATH.read_text(encoding="utf-8"))
    summary = validate(queue)
    summary["queueArtifactSha256"] = hashlib.sha256(PATH.read_bytes()).hexdigest()
    PATH.with_name("resumo-fila-complementos.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
