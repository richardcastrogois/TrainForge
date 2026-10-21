"""Coleta GET por manifesto; preserva sucessos/falhas, sem retries.

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
DOCX = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
REACT_SUPPLEMENT = 'https://pmc.ncbi.nlm.nih.gov/articles/instance/10420051/bin/Table_1.DOCX'


def byte_limit(item, accept):
    # User authorization of 2026-10-05 applies to research PDFs, not archives.
    if accept == 'application/pdf' and item.get('extension') == 'pdf':
        return None
    limit = item.get('maxBytes', 2 * 1024 * 1024)
    assert type(limit) is int and limit in (2097152, 16777216), 'Unsupported byte limit'
    if limit > 2097152:
        assert accept == DOCX and item.get('extension') == 'docx', 'Larger limit only for authorized REACT DOCX'
        assert item['url'] == REACT_SUPPLEMENT, 'DOCX authorization is source-specific'
    return limit


def store_body(response, target, limit):
    """Stream to disk without loading an unlimited PDF into memory."""
    if target.exists():
        raise ValueError('Body filename already exists: refusing overwrite')
    partial = target.with_name(target.name + '.part')
    if partial.exists():
        raise ValueError('Partial filename already exists: refusing overwrite')
    digest, size = hashlib.sha256(), 0
    try:
        with partial.open('xb') as output:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                size += len(chunk)
                if limit is not None and size > limit:
                    raise ValueError(f'Response exceeds {limit // 1048576} MiB: body not stored, no retry')
                digest.update(chunk)
                output.write(chunk)
        partial.rename(target)
    except (OSError, ValueError):
        partial.unlink(missing_ok=True)
        raise
    return size, digest.hexdigest()


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
        assert accept in ('application/json,text/html,text/plain', 'application/pdf', 'application/xml', 'application/zip', DOCX), 'Unsupported Accept override'
        max_bytes = byte_limit(item, accept)
        limit_description = 'no byte ceiling for research PDF' if max_bytes is None else f'max {max_bytes // 1048576} MiB'
        headers = {'User-Agent': UA, 'Accept': accept, 'Accept-Encoding': 'identity'}
        result = {'id': ident, 'url': url, 'method': 'GET',
                  'collectedAtUtc': datetime.now(timezone.utc).isoformat(),
                  'requestHeaders': headers, 'status': None, 'use': 'research_only',
                  'purpose': item['purpose'], 'maxBytes': max_bytes,
                  'sizePolicy': 'research_pdf_unlimited_2026-10-05' if max_bytes is None else 'bounded_non_pdf',
                  'client': f'urllib; default TLS; timeout 25s per blocking operation; streaming; {limit_description}; no retries'}
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
            target = raw / (ident + '.' + item.get('extension', 'json'))
            size, digest = store_body(response, target, max_bytes)
            result.update(bytes=size, bodyFile='../raw/' + target.name, sha256=digest)
            if accept in ('application/pdf', DOCX):
                with target.open('rb') as saved:
                    prefix = saved.read(512)
                matches = b'%PDF-' in prefix if accept == 'application/pdf' else prefix.startswith(b'PK\x03\x04')
                result['bodyFormatMatchesRequest'] = matches
                if result['status'] == 200 and not matches:
                    result['error'] = 'HTTP 200 body is not the requested binary format; retained for audit, no retry'
            if result['status'] == 200 and 'expectedBytes' in item:
                result['expectedBytes'] = item['expectedBytes']
                result['expectedBytesMatch'] = size == item['expectedBytes']
                if not result['expectedBytesMatch']:
                    result['error'] = 'Body size differs from known metadata; retained for audit, not approved'
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
