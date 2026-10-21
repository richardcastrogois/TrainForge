"""Confere o original UEM; musculos citados nao sao 17 instrucoes publicadas."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-pediatrico'


class TextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []
        self.links = []

    def handle_data(self, data):
        self.text.append(data)

    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            href = dict(attrs).get('href')
            if href:
                self.links.append(href)


def analyse(render=False):
    sources = []
    bodies = {}
    for identity in ['c15-pediatrico-uem-pagina', 'c15-pediatrico-uem-pdf']:
        path = FOLDER / (identity + '.evidencia.json')
        receipt = json.loads(path.read_text(encoding='utf-8'))
        body_path = (path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence tree')
        body = body_path.read_bytes()
        if receipt['status'] != 200 or len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Receipt/body mismatch')
        sources.append({'record': str(path.relative_to(ROOT)).replace('\\', '/'),
                        'url': receipt['url'], 'sha256': receipt['sha256'], 'bytes': len(body)})
        bodies[identity] = body_path
    parser = TextParser()
    parser.feed(bodies['c15-pediatrico-uem-pagina'].read_text(encoding='utf-8'))
    html_text = ' '.join(parser.text)
    for anchor in ['24358', 'Fisioterapeuta', 'Creative Commons Attribution 4.0']:
        if anchor not in html_text:
            raise ValueError('Missing editorial anchor: ' + anchor)
    pages = PdfReader(bodies['c15-pediatrico-uem-pdf']).pages
    text = [page.extract_text() or '' for page in pages]
    if len(pages) != 5:
        raise ValueError('Unexpected PDF length')
    for page, anchors in {0: ['24358'], 1: ['63', '17', '30 seconds', '20', '9:30'],
                          2: ['30.07', '35.50', '0.001'], 4: ['Creative Commons Attribution License']}.items():
        if not all(anchor in text[page] for anchor in anchors):
            raise ValueError('PDF anchor mismatch at page ' + str(page + 1))
    output = {'date': '2026-10-08', 'sourceId': 'PR100', 'collectorCalls': 2,
              'usableBodies': 2, 'hashedBodies': 2, 'sources': sources, 'pdfPages': 5,
              'editorialQualificationAndCcBy4AnchorsVerified': True,
              'pdfCcByDeclarationVerified': True,
              'exerciseFiguresObserved': False,
              'visualInspectionNotDeterminedByScript': True,
              'pdfDownloadLinks': [link for link in parser.links if '24358' in link and 'download' in link],
              'researchClosureApproved': False, 'releaseApproved': False}
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(str(bodies['c15-pediatrico-uem-pdf']))
        folder = FOLDER / 'paginas'
        folder.mkdir(exist_ok=True)
        rendered = []
        for number in range(5):
            page = document[number]
            bitmap = page.render(scale=1.25)
            bitmap.to_pil().save(folder / f'pagina-{number + 1}.png')
            bitmap.close()
            page.close()
            rendered.append(number + 1)
        document.close()
        output['renderedPages'] = rendered
    (FOLDER / 'inventario.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--render', action='store_true')
    result = analyse(cli.parse_args().render)
    print(json.dumps({key: result[key] for key in ['collectorCalls', 'usableBodies', 'hashedBodies', 'pdfPages']}))
