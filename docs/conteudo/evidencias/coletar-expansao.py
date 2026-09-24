"""Coleta publica limitada, idempotente e sem credenciais para pesquisa editorial.

Executar explicitamente; nunca e dependencia do app. Reexecucao usa arquivos locais,
inclusive falhas, para evitar tentativas repetidas. TLS permanece validado.
"""
import concurrent.futures
import datetime as dt
import hashlib
import json
from pathlib import Path
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parent
MAX_BYTES = 10 * 1024 * 1024
TARGETS = [
    ("cofid-2021", "https://assets.publishing.service.gov.uk/media/60538b91e90e07527df82ae4/McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx", ".xlsx"),
    ("ciqual-2025-metadata", "https://entrepot.recherche.data.gouv.fr/api/datasets/:persistentId/?persistentId=doi:10.57745/RDMHWY", ".json"),
    ("ciqual-2025", "https://entrepot.recherche.data.gouv.fr/api/access/datafile/666260", ".xlsx"),
    ("fineli-food-11060", "https://fineli.fi/fineli/api/v1/foods/11060", ".json"),
    ("compendium-running", "https://pacompendium.com/running/", ".html"),
    ("compendium-walking", "https://pacompendium.com/walking/", ".html"),
    ("compendium-bicycling", "https://pacompendium.com/bicycling/", ".html"),
    ("compendium-conditioning", "https://pacompendium.com/conditioning-exercise/", ".html"),
    ("compendium-water", "https://pacompendium.com/water-activities/", ".html"),
    ("wger-offset-300", "https://wger.de/api/v2/exerciseinfo/?limit=25&offset=300", ".json"),
    ("wger-offset-600", "https://wger.de/api/v2/exerciseinfo/?limit=25&offset=600", ".json"),
]


def fetch(target):
    name, url, suffix = target
    record = ROOT / (name + ".evidencia.json")
    if record.exists():
        return json.loads(record.read_text(encoding="utf-8"))
    result = {"id": name, "url": url, "method": "GET", "collectedAtUtc": dt.datetime.now(dt.timezone.utc).isoformat(), "status": None}
    start = time.monotonic()
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "TrainForgeResearch/0.2 (public source feasibility research)", "Accept": "*/*"})
        with urllib.request.urlopen(req, timeout=30) as response:
            body = response.read(MAX_BYTES + 1)
            if len(body) > MAX_BYTES:
                raise ValueError("Response exceeds explicit 10 MiB research limit")
            result.update(status=response.status, finalUrl=response.url, bytes=len(body), sha256=hashlib.sha256(body).hexdigest(), contentType=response.headers.get("Content-Type"))
            # Save public licensed data only; HTML is hashed, then reduce to table rows.
            if suffix == ".html":
                from html.parser import HTMLParser
                class Rows(HTMLParser):
                    def __init__(self):
                        super().__init__(); self.rows=[]; self.row=None; self.cell=None
                    def handle_starttag(self, tag, attrs):
                        if tag=="tr": self.row=[]
                        if tag in ("td","th") and self.row is not None: self.cell=""
                    def handle_data(self, data):
                        if self.cell is not None: self.cell+=data
                    def handle_endtag(self, tag):
                        if tag in ("td","th") and self.cell is not None:
                            self.row.append(self.cell.strip()); self.cell=None
                        if tag=="tr" and self.row is not None:
                            self.rows.append(self.row); self.row=None
                parser=Rows(); parser.feed(body.decode("utf-8", "replace"))
                rows=[r for r in parser.rows if len(r)>=3 and r[0].strip().isdigit()]
                result["tableRowCount"] = len(rows)
                # Keep selected entries, not the complete webpage or its media.
                selected = rows[:4]
                if name=="compendium-water": selected=[r for r in rows if "swimming" in r[2].lower()][:4]
                if name=="compendium-conditioning": selected=[r for r in rows if any(k in r[2].lower() for k in ("weight lifting", "resistance", "calisthenics"))][:4]
                result["sample"] = [{"activityCode": r[0], "metOriginal": r[1], "descriptionOriginal": r[2]} for r in selected]
            else:
                dest = ROOT / (name + suffix)
                dest.write_bytes(body)
                result["bodyFile"] = dest.name
    except urllib.error.HTTPError as error:
        result.update(status=error.code, error=str(error))
    except Exception as error:
        result["error"] = str(error)
    result["elapsedSeconds"] = round(time.monotonic() - start, 3)
    record.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return result


if __name__ == "__main__":
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        results=list(executor.map(fetch, TARGETS))
    (ROOT/"coleta-resumo.json").write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    for result in results:
        print(json.dumps({k:result.get(k) for k in ("id","status","bytes","tableRowCount","error")},ensure_ascii=True))
