"""Validate the local population/environment audit; no clinical or app tests."""
import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / "2026-10-03/revisao-publicos-ambientes"
CONTEXTS = ["idoso_casa", "idoso_academia_praca", "idoso_academia", "cuidador_casa_proprio"]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_artifact(relative):
    path = (ROOT / relative).resolve()
    path.relative_to(ROOT)
    payload = path.read_bytes()
    parsed = json.loads(payload)
    return parsed, {"file": relative, "artifactSha256": hashlib.sha256(payload).hexdigest()}


def audit_matrix(audit):
    require([c["id"] for c in audit["contexts"]] == CONTEXTS, "Four distinct contexts required")
    require([n["niche"] for n in audit["niches"]] ==
            [f"N{i:02}" for i in range(1, 21)], "Expected all N01-N20")
    require([n["niche"] for n in audit["nextNiches"]] ==
            [f"N{i:02}" for i in range(21, 47)], "Expected all N21-N46")
    for flag in ["appImplemented", "releaseApproved", "clinicalValidationPerformed", "userTestsPerformed"]:
        require(audit[flag] is False, f"Unsupported approval: {flag}")
    require(audit["newCalls"] == 0 and audit["generalResearchStatusPreserved"] is True,
            "Local audit must preserve closures and not count new calls")
    snapshots = []
    counts = Counter()
    specific = []
    for row in audit["niches"]:
        source, snapshot = read_artifact(row["evidence"])
        require(source["niche"] == row["niche"], "Niche/source mismatch")
        require([c["id"] for c in row["contexts"]] == CONTEXTS, "Missing or duplicate context")
        require(row["releaseApproved"] is False and bool(row["finding"]), "Unproven coverage")
        require(row["generalStatus"] == ("concluido_no_recorte_geral" if
                int(row["niche"][1:]) <= 14 else "parcial"), "General closure changed")
        for cell in row["contexts"]:
            require(cell["status"] in audit["statusDefinitions"] and bool(cell["gap"]),
                    "Unknown coverage or missing gap")
            counts[cell["status"]] += 1
            if cell["status"] == "parcial_especifica":
                specific.append((row["niche"], cell["id"]))
        snapshots.append(snapshot)
    require(specific == [("N15", "idoso_casa"), ("N16", "idoso_casa")],
            "Specific exercise coverage exceeded existing evidence")
    require([s["id"] for s in audit["supplements"]] ==
            ["N14-C", "N15-I", "N16-I", "N17-I", "N11-I"], "Five supplements required")
    for sub in audit["supplements"]:
        source, snapshot = read_artifact(sub["evidence"])
        require(source["niche"] == sub["id"] and source["status"] == sub["status"],
                "Supplement/source mismatch")
        require(sub["caregiverOwnHomeProgrammeDemonstrated"] is False and bool(sub["finding"]),
                "Accompaniment cannot prove own caregiver training")
        snapshots.append(snapshot)
    for row in audit["nextNiches"]:
        require(row["contextsToAssess"] == CONTEXTS and row["status"] == "na_fila",
                "Future scope missing or started without evidence")
        require(bool(row["criterion"]) and bool(row["closureRule"]) and
                row["releaseApproved"] is False, "Future criteria incomplete")
    _, initial = read_artifact(audit["initialSnapshotPreserved"])
    snapshots.append(initial)
    require(audit["next"] == "N21", "Queue changed")
    return {
        "scope": audit["scope"], "date": audit["date"], "auditCompleted": True,
        "nichesReviewed": 20, "supplementsReviewed": 5, "contexts": CONTEXTS,
        "contextAssessments": sum(counts.values()), "coverageCounts": dict(counts),
        "nextNichesWithCriteria": 26, "newCalls": 0,
        "hashType": "Local JSON artifact snapshots, not freshly verified HTTP bodies",
        "appImplemented": False, "appTestsRun": False, "userTestsPerformed": False,
        "clinicalValidationPerformed": False, "releaseApproved": False,
        "evidenceSnapshots": snapshots, "next": audit["next"]
    }


def main():
    path = FOLDER / "matriz-publicos-ambientes.json"
    audit = json.loads(path.read_text(encoding="utf-8"))
    summary = audit_matrix(audit)
    summary["matrixArtifactSha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
    (FOLDER / "resumo-revisao.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k != "evidenceSnapshots"},
                     ensure_ascii=False))


if __name__ == "__main__":
    main()
