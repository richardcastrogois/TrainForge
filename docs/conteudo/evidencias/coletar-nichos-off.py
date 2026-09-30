"""Coleta GET limitada por manifesto; preserva sucessos/falhas, sem retries.

Uso: python coletar-nichos-off.py 2026-09-28/n04-fechamento/requisicoes.json
Corpos ficam no raw local ignorado; o manifesto deve usar apenas fontes publicas.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import time
import urllib.error
import urllib.request
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
UA = 'TrainForgeResearch/0.8 (+https://github.com/richardcastrogois/TrainForge; public-source research)'


def collect(plan_path):
    plan_path = (ROOT / plan_path).resolve()
    plan_path.relative_to(ROOT)
    plan = json.loads(plan_path.read_text(encoding='utf-8'))
    raw = (plan_path.parent.parent / 'raw').resolve()
    raw.relative_to(ROOT)
    raw.mkdir(parents=True, exist_ok=True)
    for item in plan['requests']:
        ident, url = item['id'], item['url']
        assert ident.replace('-', '').isalnum(), 'Unsafe evidence identifier'
        assert urlparse(url).scheme == 'https', 'Only HTTPS public sources'
        dest = plan_path.parent / (ident + '.evidencia.json')
        if dest.exists():
            prior = json.loads(dest.read_text(encoding='utf-8'))
            assert prior['url'] == url, 'Cached URL differs; preserve the original'
            print(json.dumps({'id': ident, 'cached': True, 'status': prior['status']}), flush=True)
            continue
        accept = item.get('accept', 'application/json,text/html,text/plain')
        assert accept in ('application/json,text/html,text/plain', 'application/pdf'), 'Unsupported Accept override'
        headers = {'User-Agent': UA, 'Accept': accept, 'Accept-Encoding': 'identity'}
        result = {'id': ident, 'url': url, 'method': 'GET',
                  'collectedAtUtc': datetime.now(timezone.utc).isoformat(),
                  'requestHeaders': headers, 'status': None, 'use': 'research_only',
                  'purpose': item['purpose'], 'client': 'urllib; default TLS; timeout 25s; max 2 MiB; no retries'}
        response = None
        try:
            try:
                response = urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=25)
            except urllib.error.HTTPError as error:
                response = error
            result['status'] = response.status
            result['resolvedUrl'] = response.geturl()
            result['contentType'] = response.headers.get('Content-Type')
            result['retryAfter'] = response.headers.get('Retry-After')
            body = response.read(2 * 1024 * 1024 + 1)
            if len(body) > 2 * 1024 * 1024:
                raise ValueError('Response exceeds 2 MiB: body not stored, no retry')
            target = raw / (ident + '.' + item.get('extension', 'json'))
            if target.exists():
                raise ValueError('Body filename already exists: refusing overwrite')
            target.write_bytes(body)
            result.update(bytes=len(body), bodyFile='../raw/' + target.name,
                          sha256=hashlib.sha256(body).hexdigest())
            if result['status'] != 200:
                result['error'] = 'HTTP ' + str(result['status'])
        except (OSError, ValueError) as error:
            result['error'] = str(error)
        finally:
            if response is not None:
                response.close()
        dest.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(json.dumps({k: result.get(k) for k in ('id', 'status', 'bytes', 'error')}), flush=True)
        if urlparse(url).hostname == 'world.openfoodfacts.org':
            time.sleep(7)  # below both documented per-IP product/search request limits


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plan')
    collect(parser.parse_args().plan)
