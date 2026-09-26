"""Pesquisa publica limitada da etapa 01; nao e importador de producao.

Usa fontes explicitas, TLS normal, respostas de ate 5 MiB e cache inclusive
de falhas. Nao usa credenciais, nao envia dados pessoais nem baixa midia
instrucional. Executar outra rodada exige uma nova pasta/data.
"""
import argparse
import concurrent.futures
import datetime as dt
import hashlib
import json
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parent / "2026-09-26"
RAW = ROOT / "raw"
MAX_BYTES = 5 * 1024 * 1024
OFF_FIELDS = (
    "code,product_name,product_name_pt,brands,nutriments,serving_size,"
    "serving_quantity,nutrition_data_per,countries_tags,last_modified_t,lang,"
    "image_front_url,image_nutrition_url,ingredients_text,allergens_tags"
)
OFF_URL = "https://world.openfoodfacts.org/api/v2/search?" + urllib.parse.urlencode({
    "countries_tags": "en:portugal", "page_size": 30, "fields": OFF_FIELDS,
    "sort_by": "unique_scans_n",
})
TARGETS = [
    ("nhs-c25k", "https://www.nhs.uk/better-health/get-active/get-running-with-couch-to-5k/couch-to-5k-running-plan/", ".html"),
    ("nhs-c25k-table", "https://digitalcampaignsstorage.blob.core.windows.net/campaigns-cms-prod/documents/c25k_printable_plan.pdf", ".pdf"),
    ("nhs-strength", "https://www.nhs.uk/live-well/exercise/strength-exercises/", ".html"),
    ("nhs-terms", "https://www.nhs.uk/our-policies/terms-and-conditions/", ".html"),
    ("nhs-exclusions", "https://www.nhs.uk/our-policies/terms-and-conditions/content-not-licensed-for-re-use/", ".html"),
    ("off-portugal-30", OFF_URL, ".json"),
    ("nhlbi-walking", "https://www.nhlbi.nih.gov/health/healthdisp/pdf/tipsheets/Sample-Walking-Program.pdf", ".pdf"),
]


def fetch(target):
    name, url, suffix = target
    record = ROOT / (name + ".evidencia.json")
    if record.exists():
        return json.loads(record.read_text(encoding="utf-8"))
    result = {
        "id": name, "url": url, "method": "GET",
        "collectedAtUtc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "status": None, "use": "local_research_not_production",
    }
    start = time.monotonic()
    try:
        request = urllib.request.Request(url, headers={
            "User-Agent": "TrainForgeResearch/0.3 (content feasibility; local research)",
            "Accept": "application/json,text/html,application/pdf;q=0.9,*/*;q=0.5",
        })
        with urllib.request.urlopen(request, timeout=25) as response:
            body = response.read(MAX_BYTES + 1)
            if len(body) > MAX_BYTES:
                raise ValueError("Response exceeds the 5 MiB research limit")
            destination = RAW / (name + suffix)
            destination.write_bytes(body)
            result.update(
                status=response.status, finalUrl=response.url, bytes=len(body),
                sha256=hashlib.sha256(body).hexdigest(),
                contentType=response.headers.get("Content-Type"),
                bodyFile="raw/" + destination.name,
            )
    except urllib.error.HTTPError as error:
        result.update(status=error.code, error=str(error))
    except Exception as error:
        result["error"] = str(error)
    result["elapsedSeconds"] = round(time.monotonic() - start, 3)
    record.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--attempt", choices=["network"], help="Separate an approved network attempt from sandbox failures")
    args = parser.parse_args()
    if args.attempt:
        ROOT = ROOT / args.attempt
        RAW = ROOT / "raw"
    RAW.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        results = list(executor.map(fetch, TARGETS))
    (ROOT / "coleta-resumo.json").write_text(
        json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    for result in results:
        print(json.dumps({k: result.get(k) for k in ("id", "status", "bytes", "error")}, ensure_ascii=False))
