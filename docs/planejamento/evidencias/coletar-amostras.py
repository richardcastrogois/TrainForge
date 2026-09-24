"""Pesquisa somente leitura. Sem credenciais privadas, retries ou escrita em APIs.
Reutiliza respostas locais; remover arquivos de evidencia exige decisao explicita.
Nao e integracao do aplicativo. DEMO_KEY e a chave publica de demonstracao USDA.
"""
import json
import time
import hashlib
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlencode
from urllib.error import HTTPError

ROOT = Path(__file__).resolve().parent
UA = 'TrainForgeResearch/0.1 (public data feasibility study)'

def fetch(name, url):
    dest = ROOT / (name + '.json')
    if dest.exists():
        saved = json.loads(dest.read_text(encoding='utf-8'))
        if '--retry-network-denied' in sys.argv and saved.get('status') is None and '10013' in saved.get('error', ''):
            dest.rename(ROOT / (name + '.sandbox-denied.json'))
        else:
            print(name, 'cached', saved.get('status'), flush=True)
            return saved
    started = time.monotonic()
    record = {'url': url, 'collectedAtUtc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'method': 'GET'}
    try:
        with urlopen(Request(url, headers={'User-Agent': UA, 'Accept': 'application/json'}), timeout=25) as response:
            raw = response.read(4000000)
            record.update(status=response.status, bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest(), data=json.loads(raw))
    except HTTPError as exc:
        record.update(status=exc.code, error=exc.reason)
    except Exception as exc:
        record.update(status=None, error=str(exc)[:300])
    record['elapsedSeconds'] = round(time.monotonic() - started, 3)
    dest.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
    print(name, record.get('status'), record['elapsedSeconds'], flush=True)
    return record

if __name__ == '__main__':
    from concurrent.futures import ThreadPoolExecutor
    # Um pedido por origem em paralelo; sem carga ou varredura exaustiva.
    urls = [
        ('wger-25', 'https://wger.de/api/v2/exerciseinfo/?limit=25&ordering=id'),
        ('free-exercise-db', 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json'),
        ('off-portugal-20', 'https://world.openfoodfacts.org/api/v3.6/search?' + urlencode({'countries_tags':'en:portugal','page_size':20,'fields':'code,product_name,product_name_pt,brands,nutriments,serving_size,nutrition_data_per,countries_tags,last_modified_t,lang','sort_by':'unique_scans_n'})),
    ]
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda item: fetch(*item), urls))
    # 3 buscas, 5 resultados por categoria; nao e uma amostra representativa de Portugal.
    for food in ['rice', 'milk', 'egg']:
        fetch('usda-' + food, 'https://api.nal.usda.gov/fdc/v1/foods/search?' + urlencode({'api_key':'DEMO_KEY','query':food,'pageSize':5,'dataType':'Foundation,SR Legacy'}))
