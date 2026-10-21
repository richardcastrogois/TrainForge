"""Read the exact public PDF-availability query published by the article button."""
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-protocolos-operacionais'
URL = 'https://www.zglyyx.com/CN/article/showArticleFile.do'
FORM = {'attachType': 'PDF', 'id': '7307', 'json': 'true'}
ID = 'c15-baduanjin-acesso-pdf'
spec = importlib.util.spec_from_file_location('collector', ROOT / 'coletar-nichos-off.py')
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)


def collect():
    destination = FOLDER / (ID + '.evidencia.json')
    if destination.exists():
        return json.loads(destination.read_text(encoding='utf-8'))
    headers = {'User-Agent': collector.UA, 'Accept': 'application/json,text/html,text/plain',
               'Content-Type': 'application/x-www-form-urlencoded', 'Accept-Encoding': 'identity'}
    record = {'id': ID, 'url': URL, 'method': 'POST', 'requestForm': FORM,
              'publishedRequestOrigin': 'c15-baduanjin-download-helper.evidencia.json / lsdy1',
              'requestHeaders': headers, 'collectedAtUtc': datetime.now(timezone.utc).isoformat(),
              'status': None, 'use': 'research_only', 'maxBytes': 2097152,
              'purpose': 'Consulta publica de disponibilidade do PDF, sem compra/conta/download automatico.',
              'client': 'urllib; TLS padrao; timeout25s;2MiB; sem retries; nao executar o helperJS'}
    response = None
    try:
        request = urllib.request.Request(URL, data=urllib.parse.urlencode(FORM).encode('ascii'), headers=headers)
        try:
            response = urllib.request.urlopen(request, timeout=25)
        except urllib.error.HTTPError as error:
            response = error
        record.update(status=response.status, resolvedUrl=response.geturl(),
                      contentType=response.headers.get('Content-Type'))
        target = FOLDER.parent / 'raw' / (ID + '.txt')
        size, digest = collector.store_body(response, target, 2097152)
        record.update(bytes=size, sha256=digest, bodyFile='../raw/' + target.name)
        if record['status'] != 200:
            record['error'] = 'HTTP ' + str(record['status'])
    except (OSError, ValueError) as error:
        record['error'] = str(error)
    finally:
        if response is not None:
            response.close()
    destination.write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return record


if __name__ == '__main__':
    result = collect()
    print(json.dumps({k: result.get(k) for k in ('id', 'status', 'bytes', 'error')}))
    if result.get('bodyFile'):
        body = (FOLDER / result['bodyFile']).read_text(encoding='utf-8')
        if result['status'] == 200 and body.startswith('[json]'):
            availability = json.loads(body[len('[json]'):])
            print(json.dumps({'publicPdfAvailable': availability.get('status') == 1}))
            if availability.get('status') == 1:
                url = availability['pdfUrl']
                parsed = urllib.parse.urlparse(url)
                if (parsed.scheme, parsed.netloc, parsed.path) != (
                        'https', 'www.zglyyx.com', '/CN/PDF/10.13517/j.cnki.ccm.2023.08.001'):
                    raise ValueError('Unexpected published PDF route')
                plan = {'date': '2026-10-08', 'scope': 'Primeiro PDF autorizado pela consulta publica; sem retry.',
                        'publishedUrlFrom': ID + '.evidencia.json', 'requests': [
                            {'id': 'c15-baduanjin-avc2023-pdf', 'url': url, 'extension': 'pdf',
                             'accept': 'application/pdf', 'purpose': 'Artigo original6p, metodo/dose/autoria/seguranca/direitos. URL efemera emitida pela consulta publica sem conta; nao reutilizar apos barreira.'}]}
                destination = FOLDER / 'requisicoes-baduanjin-pdf.json'
                if not destination.exists():
                    destination.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
