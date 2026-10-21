"""Audita originais do proprio cuidador; nao cria dose, licenca ou prescricao."""
import argparse
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-fisico-relaxamento'
RAW = ROUND.parent / 'raw'
spec = importlib.util.spec_from_file_location('physical_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


class PlainText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.skip = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.skip += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style') and self.skip:
            self.skip -= 1

    def handle_data(self, data):
        if not self.skip and data.strip():
            self.parts.append(data.strip())


PDFS = {
    'c15-fedema-manual-2022': (236, [4, *range(131, 150)], [4, *range(131, 150)]),
    'c15-alzoc-respiracao-pdf': (2, [1, 2], [1, 2]),
    'c15-jacobson-hemodialise2024-pdf': (8, [1, 3, 4, 6, 7, 8], [1, 3, 4, 6, 7, 8]),
    'c15-madruga-tese-2021': (221, [1, 14, 126, 127, 138, 139, 140, 214, 215, 216, 217, 218, 219, 220], [1, 214, 216, 217, 218, 219, 220]),
}


def analyse(render=False):
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (request['id'] + '.evidencia.json'), ROOT)
               for request in plan['requests']]
    for item in entries:
        if item['usable'] and item['id'] in PDFS:
            count, read_pages, visual_pages = PDFS[item['id']]
            body = RAW / (item['id'] + '.pdf')
            reader = PdfReader(body)
            if len(reader.pages) != count:
                raise ValueError('Unexpected PDF version/page count')
            item.update(pdfPages=count, textReadPdfPages=read_pages,
                        renderedPdfPages=visual_pages if render else [])
            if render:
                import pypdfium2 as pdfium
                document = pdfium.PdfDocument(body)
                try:
                    for number in visual_pages:
                        page = document[number - 1]
                        bitmap = page.render(scale=1.6)
                        try:
                            bitmap.to_pil().save(RAW / f'{item["id"]}-p{number}.png')
                        finally:
                            bitmap.close()
                            page.close()
                finally:
                    document.close()
    fedema = PdfReader(RAW / 'c15-fedema-manual-2022.pdf')
    checks = {131: ['Fisioterapeutas'], 132: ['30-45'], 134: ['6 a 10'],
              143: ['10 segundos'], 155: ['2 kg']}
    for number, anchors in checks.items():
        text = ' '.join((fedema.pages[number - 1].extract_text() or '').split())
        for anchor in anchors:
            if anchor.casefold() not in text.casefold():
                raise ValueError(f'Missing source anchor: PDF{number} {anchor}')
    legal = PlainText()
    legal.feed((RAW / 'c15-fedema-avisos-legales.html').read_text(encoding='utf-8'))
    legal_text = ' '.join(legal.parts)
    if 'consentimiento expreso y por escrito' not in legal_text:
        raise ValueError('Published rights restriction missing')
    jats = ET.parse(RAW / 'c15-kirtan2012-xml.xml')
    article_text = ' '.join(jats.getroot().itertext())
    for anchor in ('11-minute', '112', 'meditation CD', '2 minutes', '3 minutes'):
        if anchor.casefold() not in article_text.casefold():
            raise ValueError(f'Missing Kirtan original anchor: {anchor}')
    result = {
        'date':'2026-10-07', 'niche':'N15-C', 'networkPerformed':False,
        'sources':entries, 'newCollectorCalls':len(entries),
        'usableBodies':sum(item['usable'] for item in entries),
        'hashedBodies':sum(item['bodyVerified'] for item in entries),
        'rightsRestrictionVerifiedInReceivedFedemaHtml':True,
        'kirtanLicenceText':' '.join(jats.find('.//permissions/license').itertext()),
        'kirtanLicenceVersionSpecified':False,
        'visualInspectionConfirmedByScript':False,
        'researchClosureApproved':False, 'releaseApproved':False,
        'appImplemented':False,
    }
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key:result[key] for key in ('newCollectorCalls','usableBodies','hashedBodies')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
