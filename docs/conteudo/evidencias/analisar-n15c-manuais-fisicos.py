"""Audit the received physical-programme originals without network or embargo access."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-manuais-fisicos'
PDF_ID = 'c15-sun2025-artigo-pdf'
TARGETS = [1, 5, 8, 9, 10]


class TextReader(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.hidden += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.hidden -= 1

    def handle_data(self, value):
        if not self.hidden:
            self.parts.append(value)


def analyse(render=False):
    rows, pdf_path, reader = [], None, None
    for name in ['requisicoes.json', 'requisicoes-originais.json']:
        plan = json.loads((FOLDER / name).read_text(encoding='utf-8'))
        for request in plan['requests']:
            path = FOLDER / (request['id'] + '.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if request['url'] != receipt['url']:
                raise ValueError('Manifest/receipt URL mismatch')
            usable = receipt['status'] == 200 and not receipt.get('error')
            if receipt.get('bodyFile'):
                body_path = (FOLDER / receipt['bodyFile']).resolve()
                if not body_path.is_relative_to(ROOT.resolve()):
                    raise ValueError('Body outside evidence root')
                body = body_path.read_bytes()
                if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                    raise ValueError('Body integrity mismatch')
                if usable and request['extension'] == 'pdf':
                    if not body.startswith(b'%PDF-'):
                        raise ValueError('Expected actual PDF')
                    pdf_path, reader = body_path, PdfReader(body_path)
                elif usable:
                    parser = TextReader()
                    parser.feed(body.decode('utf-8'))
                    text = ' '.join(' '.join(parser.parts).split())
                    anchors = ['115', '230', 'Single-group', '4fvfn2p'] if 'rebec' in request['id'] else ['03881-5', 'rehabilitation doctor', 'NoDerivatives', '96', '46']
                    if not all(term in text for term in anchors):
                        raise ValueError('Original HTML anchors absent')
            elif any(receipt.get(key) is not None for key in ['sha256', 'bytes']):
                raise ValueError('Failed retrieval must not acquire an invented body hash')
            rows.append({'id':request['id'], 'record':path.relative_to(ROOT).as_posix(),
                         'url':receipt['url'], 'status':receipt['status'],
                         'bytes':receipt.get('bytes'), 'sha256':receipt.get('sha256'),
                         'usableForReading':usable, 'error':receipt.get('error')})
    if reader is None or len(reader.pages) != 13:
        raise ValueError('Original Sun publication length mismatch')
    anchors = {1:['03881-5', 'NoDerivatives'], 5:['Table 1', '90 min', '60 min', 'rehabilitation doctor'],
               9:['Table 3', '0.032', '0.019', '45.52', '49.85'],
               10:['Table 4', '5.087', '-2.232', '-3.550', '-13.235']}
    for number, terms in anchors.items():
        text = ' '.join(reader.pages[number-1].extract_text().split())
        if not all(term in text for term in terms):
            raise ValueError('PDF anchors absent: ' + str(number))
    rendered = []
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER / 'paginas'
        folder.mkdir(exist_ok=True)
        document = pdfium.PdfDocument(str(pdf_path))
        for number in TARGETS:
            page = document[number-1]
            bitmap = page.render(scale=1.5)
            bitmap.to_pil().save(folder / f'sun-pagina-{number}.png')
            bitmap.close()
            page.close()
            rendered.append(number)
        document.close()
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'http200':sum(row['status']==200 for row in rows),
              'hashedBodies':sum(row['sha256'] is not None for row in rows),
              'usableBodies':sum(row['usableForReading'] for row in rows),
              'pdfPages':len(reader.pages), 'receipts':rows, 'renderedPages':rendered,
              'renderingIsVisualInspection':False, 'embargoedThesisDownloaded':False,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    result = analyse(parser.parse_args().render)
    print(json.dumps({key:result[key] for key in ['collectorCalls','http200','hashedBodies','usableBodies','pdfPages']}))
