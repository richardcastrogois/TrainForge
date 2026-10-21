"""Offline integrity and bounded PDF-in-archive reading for caregiver curricula."""
import argparse
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-curriculos-adicionais'
SPEC = importlib.util.spec_from_file_location('curricula_zip', ROOT / 'analisar-n15c-yoga-grupo.py')
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)
MANIFESTS = ['requisicoes.json', 'requisicoes-suplementos.json', 'requisicoes-protocolo.json']


def read_archive(body, chain=(), depth=0, render=False, budget=None):
    from pypdf import PdfReader
    if depth > 1:
        raise ValueError('Nested archive depth limit')
    if budget is None:
        budget = {'bytes':0, 'members':0}
    rows = []
    with ZipFile(io.BytesIO(body)) as archive:
        members = GUARD.bounded_members(archive)
        budget['bytes'] += sum(m.file_size for m in members)
        budget['members'] += len(members)
        if budget['bytes'] > 20000000 or budget['members'] > 500:
            raise ValueError('Cumulative expansion limit')
        for member in members:
            location = (*chain, member.filename)
            row = {'chain':list(location), 'bytes':member.file_size, 'mediaViewedByAnalysis':False}
            if member.filename.lower().endswith(('.pdf', '.zip')):
                data = archive.read(member)
                row['sha256'] = hashlib.sha256(data).hexdigest()
                if member.filename.lower().endswith('.zip'):
                    row['members'] = read_archive(data, location, depth+1, render, budget)
                else:
                    reader = PdfReader(io.BytesIO(data))
                    row['pdfPages'] = len(reader.pages)
                    row['pdfText'] = [p.extract_text() for p in reader.pages]
                    row['renderedThisRun'] = render
                    if render:
                        import pypdfium2 as pdfium
                        target = FOLDER / 'raw-render'
                        target.mkdir(exist_ok=True)
                        document = pdfium.PdfDocument(data)
                        for index in range(len(document)):
                            page = document[index]
                            bitmap = page.render(scale=1.5)
                            bitmap.to_pil().save(target / (member.filename+'-page-'+str(index+1)+'.png'))
                            bitmap.close()
                            page.close()
                        document.close()
            rows.append(row)
    return rows


def analyse(render=False):
    rows, archives = [], []
    for manifest in MANIFESTS:
        for request in json.loads((FOLDER / manifest).read_text(encoding='utf-8'))['requests']:
            receipt_path = FOLDER / (request['id']+'.evidencia.json')
            receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
            source = (FOLDER / receipt['bodyFile']).resolve()
            if request['url'] != receipt['url'] or not source.is_relative_to(ROOT.resolve()):
                raise ValueError('Manifest/body identity mismatch')
            body = source.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Body integrity mismatch')
            row = {'id':receipt['id'], 'record':receipt_path.relative_to(ROOT).as_posix(),
                   'status':receipt['status'], 'url':receipt['url'], 'bytes':len(body), 'sha256':receipt['sha256'],
                   'usableForReading':receipt['status'] == 200 and not receipt.get('error') and bool(body)}
            if row['usableForReading'] and request['extension'] == 'xml':
                article = ET.fromstring(body)
                row['sections'] = [{'id':s.get('id'), 'title':''.join(s.find('title').itertext())}
                                   for s in article.findall('.//sec') if s.find('title') is not None]
                row['supplementFiles'] = [m.get('{http://www.w3.org/1999/xlink}href')
                                         for m in article.findall('.//supplementary-material/media')]
            if row['usableForReading'] and request['extension'] == 'zip':
                archives.append({'record':row['record'], 'containerSha256':row['sha256'],
                                 'members':read_archive(body, render=render), 'executesContent':False})
            rows.append(row)
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'http200':sum(r['status'] == 200 for r in rows), 'hashedBodies':sum(bool(r['sha256']) for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows), 'receipts':rows,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False, 'releaseApproved':False,
              'appImplemented':False}
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (FOLDER / 'leitura-suplementos.json').write_text(json.dumps(archives, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    print(json.dumps(analyse(parser.parse_args().render), ensure_ascii=False))
