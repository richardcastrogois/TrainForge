"""Verify originals, preserve duplicate provenance, and render raster annexes."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-guias-clinicos'


class HtmlText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text, self.links = [], []
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.hidden += 1
        if tag == 'a' and dict(attrs).get('href'):
            self.links.append(dict(attrs)['href'])

    def handle_endtag(self, tag):
        if tag in ('script', 'style') and self.hidden:
            self.hidden -= 1

    def handle_data(self, data):
        if not self.hidden:
            self.text.append(data)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def analyse(render=False):
    rows, bodies, pdfs, html = [], {}, {}, {}
    for manifest in sorted(FOLDER.glob('requisicoes*.json')):
        for request in json.loads(manifest.read_text(encoding='utf-8'))['requests']:
            identity = request['id']
            receipt_path = FOLDER / (identity + '.evidencia.json')
            receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
            row = {'record': receipt_path.relative_to(ROOT).as_posix(), 'id': identity,
                   'sha256': receipt.get('sha256'), 'bytes': receipt.get('bytes'),
                   'status': receipt.get('status'), 'error': receipt.get('error')}
            if not receipt.get('bodyFile'):
                require(not receipt.get('sha256'), 'Hash claimed without body: ' + identity)
                row['usable'] = False
                rows.append(row)
                continue
            path = (receipt_path.parent / receipt['bodyFile']).resolve()
            require(path.is_relative_to(ROOT.resolve()), 'Body outside evidence root')
            body = path.read_bytes()
            require(len(body) == receipt['bytes'], 'Byte mismatch: ' + identity)
            require(hashlib.sha256(body).hexdigest() == receipt['sha256'], 'Hash mismatch: ' + identity)
            require(receipt['status'] == 200 and not receipt.get('error'), 'Unusable receipt: ' + identity)
            bodies[identity] = path
            row['usable'] = True
            if path.suffix == '.pdf':
                reader = PdfReader(path)
                pages = [page.extract_text() or '' for page in reader.pages]
                pdfs[identity] = {'pages': len(pages), 'text': pages}
                row['pdfPages'] = len(pages)
            else:
                parser = HtmlText()
                parser.feed(body.decode('utf-8'))
                html[identity] = parser
            rows.append(row)
    old = json.loads((ROOT / '2026-10-07/n15c-fisico-relaxamento/c15-fedema-manual-2022.evidencia.json').read_text(encoding='utf-8'))
    duplicate = next(row for row in rows if row['id'] == 'c15-fedema2022-manual-pdf')
    require(old['sha256'] == duplicate['sha256'], 'FEDEMA no longer a byte-identical duplicate')
    require(pdfs['c15-montero2017-tese-canonica-pdf']['pages'] == 362, 'Thesis page count')
    require(pdfs['c15-salamanca2025-tfg-pdf']['pages'] == 55, 'TFG page count')
    require(pdfs['c15-fedema2022-manual-pdf']['pages'] == 236, 'FEDEMA page count')
    thesis = pdfs['c15-montero2017-tese-canonica-pdf']['text']
    require('36 sesiones' in ' '.join(thesis[349].split()), 'Raster session annex lead missing')
    registry = html['c15-salamanca2025-registro-html']
    require(any('/licenses/by-nc-nd/4.0' in link for link in registry.links), 'TFG exact license missing')
    drive_text = ' '.join(html['c15-salamanca-video-listagem-html'].text)
    require('Video DIAS 1 Y 3.mov' in drive_text and 'Video DIAS 2 Y 4.mov' in drive_text, 'Public video listing missing')
    require('18,2 MB' in drive_text and '30,1 MB' in drive_text, 'Video listing sizes changed')
    page_ranges = [('A1', 1, 5, 332), ('A1', 6, 6, 333), ('A2', 1, 11, 333),
                   ('A2', 12, 27, 334), ('A2', 28, 43, 335), ('B1', 1, 2, 336),
                   ('B1', 3, 3, 337), ('B2', 1, 7, 339), ('B2', 8, 15, 340),
                   ('B2', 16, 21, 341), ('B2', 22, 27, 342), ('B2', 28, 34, 343),
                   ('B2', 35, 42, 344), ('B2', 43, 49, 345), ('B3', 1, 8, 346),
                   ('B3', 11, 20, 346), ('B3', 21, 23, 347), ('C1', 1, 4, 347),
                   ('C1', 5, 13, 348), ('C1', 14, 20, 349), ('C2', 1, 5, 350)]
    aliases = {'B2.49': '2.49', 'C1.18': 'C18', 'C1.19': 'C19', 'C1.20': 'C20'}
    references = [{'locatorId': prefix + '.' + str(number),
                   'sourcePrintedCode': aliases.get(prefix + '.' + str(number), prefix + '.' + str(number)),
                   'pdfPage': page, 'printedPage': page - 22,
                   'isApprovedExerciseCard': False}
                  for prefix, first, last, page in page_ranges for number in range(first, last + 1)]
    require(len(references) == 147, 'Reference count, not isolated exercise count')
    sessions = []
    for number in range(1, 37):
        later_friday = number >= 18 and number % 3 == 0
        sessions.append({'session': number, 'week': (number - 1) // 3 + 1,
                         'pdfPage': 351 + (number - 1) // 3,
                         'printedPage': 329 + (number - 1) // 3,
                         'tableFromTop': (number - 1) % 3 + 1,
                         'warmupMinutesRange': [5, 10] if later_friday else ([10, 15] if number <= 15 else [10, 10]),
                         'mainMinutesRange': [35, 40] if number <= 15 or later_friday else [40, 40],
                         'cooldownMinutesRange': [10, 15] if later_friday else [10, 10],
                         'timerImportApproved': False})
    index = {'sourceId': 'PR85', 'version': 'tese2017',
             'sourceReceipt': 'c15-montero2017-tese-canonica-pdf.evidencia.json',
             'kind': 'localizadores_de_pesquisa_nao_prescricao_ou_transcricao_das_tabelas',
             'referenceCount': 147, 'referenceIdsAreIsolatedClinicallyProvenExercises': False,
             'references': references, 'sessionCount': 36, 'sessions': sessions,
             'sourceAliasesChangeMovement': False, 'appImplemented': False}
    (FOLDER / 'indice-anexo-montero.json').write_text(json.dumps(index, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    rendered = []
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER / 'raw/rendered'
        folder.mkdir(parents=True, exist_ok=True)
        targets = {
            'c15-montero2017-tese-canonica-pdf': [1, 133, 136, 138, 139, 140, 141, 142, 143, 144, 145,
                                                   332, 333, 338, 342, 345, 346, 347, 349, 350, *range(351, 363)],
            'c15-salamanca2025-tfg-pdf': [1, 9, 10, 12, 17, 18, 19, 28, 29, 38, 39, 44, 45, 46],
        }
        for identity, numbers in targets.items():
            doc = pdfium.PdfDocument(bodies[identity])
            for number in numbers:
                page = doc[number - 1]
                bitmap = page.render(scale=1.8)
                target = folder / (identity + '-p' + str(number) + '.png')
                bitmap.to_pil().save(target)
                rendered.append({'sourceId': identity, 'page': number, 'file': target.relative_to(ROOT).as_posix()})
                bitmap.close()
                page.close()
            doc.close()
    result = {'collectionCount': len(rows), 'hashedBodies': len(bodies),
              'usefulBodies': sum(row['usable'] for row in rows),
              'pdfPages': sum(item['pages'] for item in pdfs.values()),
              'duplicateOriginal': {'sourceId': 'PR71', 'sha256': duplicate['sha256'],
                                    'newClinicalFamily': False},
              'receipts': rows, 'renderedPages': rendered, 'researchClosureApproved': False}
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args()
    result = analyse(args.render)
    print(json.dumps({key: value for key, value in result.items() if key not in ('receipts', 'renderedPages')}, ensure_ascii=False))
    print('Rendered pages:', len(result['renderedPages']))
