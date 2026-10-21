"""Confere artigo e anuncio de manual MCM, sem rede ou prescricao nova."""
import argparse
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-mcm'
spec = importlib.util.spec_from_file_location('mcm_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


class ArticleMetadata(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.payload = ''
        self.download_links = []

    def handle_starttag(self, tag, attributes):
        attributes = dict(attributes)
        if tag == 'script' and attributes.get('id') == '__NUXT_DATA__':
            self.active = True
        href = attributes.get('href', '')
        if tag == 'a' and href.startswith('https://') and any(
            word in href.lower() for word in ('datasheet', 'supplementary-file', 'supplementary_material')
        ):
            self.download_links.append(href)

    def handle_data(self, data):
        if self.active:
            self.payload += data

    def handle_endtag(self, tag):
        if tag == 'script':
            self.active = False

    def supplement_state(self):
        # Nuxt's public page payload uses a flattened reference table.
        slots = json.loads(self.payload)
        flags = [slots[node['hasSupplementalData']] for node in slots
                 if isinstance(node, dict) and 'hasSupplementalData' in node]
        sections = [slots[node['supplementary-material']] for node in slots
                    if isinstance(node, dict) and 'supplementary-material' in node]
        if not flags or not sections:
            raise ValueError('Expected published supplement metadata missing')
        return {'hasSupplementalDataFlags': flags,
                'supplementarySectionNodeCounts': [len(section) for section in sections],
                'publishedSupplementDownloadLinks': self.download_links,
                'absenceOnReceivedPageProvesGlobalNonexistence': False}


def analyse(render=False):
    requests = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))['requests']
    entries = [receipts.check_receipt(ROUND / (item['id'] + '.evidencia.json'), ROOT)
               for item in requests]
    if not all(item['usable'] for item in entries):
        raise ValueError('Original received bodies must be usable before analysis')
    parser = ArticleMetadata()
    parser.feed((ROUND.parent / 'raw/c15-mcm-artigo-html.html').read_text(encoding='utf-8'))
    reader = PdfReader(ROUND.parent / 'raw/c15-mcm-artigo-pdf.pdf')
    if len(reader.pages) != 13:
        raise ValueError('Unexpected PDF version/page count')
    anchors = {1: ['Creative Commons', '16 March 2026'],
               5: ['multidisciplinary team', 'Supplementary material D'],
               8: ['Mindfulness stretching', 'TABLE 3'],
               9: ['did not include a pilot application'],
               10: ['0.97', '0.92'], 11: ['Generative AI was not used']}
    for number, values in anchors.items():
        text = ' '.join((reader.pages[number - 1].extract_text() or '').split())
        for value in values:
            if value.casefold() not in text.casefold():
                raise ValueError(f'Missing source anchor: PDF{number} {value}')
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(ROUND.parent / 'raw/c15-mcm-artigo-pdf.pdf')
        try:
            for number in anchors:
                page = document[number - 1]
                bitmap = page.render(scale=1.6)
                try:
                    bitmap.to_pil().save(ROUND.parent / 'raw' / f'PR70-mcm-p{number}.png')
                finally:
                    bitmap.close()
                    page.close()
        finally:
            document.close()
    result = {'date':'2026-10-07', 'niche':'N15-C', 'networkPerformed':False,
              'sources':entries, 'newCollectorCalls':len(entries),
              'usableBodies':len(entries), 'hashedBodies':len(entries),
              'pdfPages':13, 'anchorCheckedPdfPages':list(anchors),
              'renderedPdfPages':list(anchors) if render else [],
              'supplementMetadata':parser.supplement_state(),
              'visualInspectionConfirmedByScript':False,
              'finalManualReceived':False, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key:result[key] for key in ('newCollectorCalls','usableBodies','pdfPages','supplementMetadata')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
