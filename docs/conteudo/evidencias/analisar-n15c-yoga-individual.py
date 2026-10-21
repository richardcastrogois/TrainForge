"""Verify original yoga receipts and expose structured locators without network access."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-individual'
MANIFESTS = ['requisicoes.json', 'requisicoes-protocolo.json',
             'requisicoes-protocolo-integral.json', 'requisicoes-credencial.json']


def analyse(render=False):
    rows = []
    for name in MANIFESTS:
        for request in json.loads((FOLDER/name).read_text(encoding='utf-8'))['requests']:
            path = FOLDER/(request['id']+'.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if request['url'] != receipt['url']:
                raise ValueError('Manifest/receipt mismatch')
            source = (FOLDER/receipt['bodyFile']).resolve()
            if not source.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = source.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Body integrity mismatch')
            usable = receipt['status'] == 200 and not receipt.get('error') and len(body) > 0
            row = {'id':request['id'], 'record':path.relative_to(ROOT).as_posix(),
                   'url':receipt['url'], 'status':receipt['status'], 'bytes':len(body),
                   'sha256':receipt['sha256'], 'usableForReading':usable}
            if usable and request['extension'] == 'xml':
                article = ET.fromstring(body)
                row['sections'] = [{'id':s.get('id'), 'title':''.join(s.find('title').itertext())}
                                   for s in article.findall('.//sec') if s.find('title') is not None]
                row['supplementFiles'] = [m.get('{http://www.w3.org/1999/xlink}href')
                                         for m in article.findall('.//supplementary-material/media')]
            if usable and request['extension'] == 'pdf':
                from pypdf import PdfReader
                reader = PdfReader(source)
                row['pdfPages'] = len(reader.pages)
                row['pdfText'] = [page.extract_text() for page in reader.pages]
                row['renderedThisRun'] = render
                if render:
                    import pypdfium2 as pdfium
                    target = FOLDER/'raw-render'
                    target.mkdir(exist_ok=True)
                    document = pdfium.PdfDocument(source)
                    for index in range(len(document)):
                        page = document[index]
                        bitmap = page.render(scale=1.4)
                        bitmap.to_pil().save(target/('bio-page-'+str(index+1)+'.png'))
                        bitmap.close()
                        page.close()
                    document.close()
            rows.append(row)
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'http200':sum(r['status'] == 200 for r in rows),
              'hashedBodies':sum(bool(r['sha256']) for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows), 'receipts':rows,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render',action='store_true')
    print(json.dumps(analyse(parser.parse_args().render),ensure_ascii=False))
