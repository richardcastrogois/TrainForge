"""Confere originais de duas pistas N15-C, sem rede ou executar ativos externos."""
import argparse
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
DAY = ROOT / '2026-10-07'
RAW = DAY / 'raw'
spec = importlib.util.spec_from_file_location('n15c_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
PAGES = {
    'c15-dancecare-handbook-pdf': [1, 2, 8, 11, 14, 15, 17, 18, 19, 56],
    'c15-dancecare-guidelines-pdf': [1, 3, 6, 7, 8, 10, 11, 12],
}


def plain(node):
    return ' '.join(' '.join(node.itertext()).split())


def analyse(render=False):
    for folder in ['n15c-alongamento-profissional', 'n15c-dancecare']:
        round_path = DAY / folder
        plan = json.loads((round_path / 'requisicoes.json').read_text(encoding='utf-8'))
        entries = [receipts.check_receipt(round_path / (item['id'] + '.evidencia.json'), ROOT)
                   for item in plan['requests']]
        result = {'date': '2026-10-07', 'niche': 'N15-C', 'networkPerformed': False,
                  'sources': entries, 'newCollectorCalls': len(entries),
                  'http200Bodies': sum(s['status'] == 200 for s in entries),
                  'usableBodies': sum(s['usable'] for s in entries),
                  'hashedBodies': sum(s['bodyVerified'] for s in entries),
                  'researchClosureApproved': False, 'releaseApproved': False,
                  'appImplemented': False, 'visualInspectionConfirmedByScript': False}
        if folder == 'n15c-alongamento-profissional':
            root = ET.parse(RAW / 'c15-atac2024-xml.xml').getroot()
            procedure = root.find('.//sec[@id="sec2dot3-ijerph-21-01361"]')
            correction = ET.parse(RAW / 'c15-atac2026-correcao-xml.xml').getroot()
            result['originalProcedure'] = {'locator': 'sec2dot3-ijerph-21-01361',
                                           'text': plain(procedure)}
            result['correctionBodyParagraphs'] = [plain(p) for p in correction.findall('./body/p')]
            result['permissionStatements'] = [plain(root.find('.//permissions')),
                                              plain(correction.find('.//permissions'))]
            assert 'licenses/by/4.0' in result['permissionStatements'][0]
            assert 'scientific conclusions are unaffected' in result['correctionBodyParagraphs'][-1]
        else:
            result['pdfs'] = []
            for ident, selected in PAGES.items():
                reader = PdfReader(RAW / (ident + '.pdf'))
                texts = [' '.join(page.extract_text().split()) for page in reader.pages]
                result['pdfs'].append({'id': ident, 'pages': len(texts),
                    'selectedTextPages': [{'oneBasedPage': n, 'text': texts[n - 1]} for n in selected],
                    'licenceTextHits': [{'oneBasedPage': i + 1, 'term': term}
                        for i, text in enumerate(texts)
                        for term in ['creativecommons', 'license', 'licence', 'copyright', 'CC BY']
                        if term.lower() in text.lower()],
                    'textSearchIsNotLegalPermission': True,
                    'renderedPages': selected if render else []})
                if render:
                    import pypdfium2 as pdfium
                    document = pdfium.PdfDocument(RAW / (ident + '.pdf'))
                    try:
                        for number in selected:
                            page = document[number - 1]
                            bitmap = page.render(scale=1.2)
                            try:
                                bitmap.to_pil().save(RAW / f'{ident}-p{number}.png')
                            finally:
                                bitmap.close()
                                page.close()
                    finally:
                        document.close()
        (round_path / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
        print(json.dumps({key: result[key] for key in
                          ['newCollectorCalls', 'http200Bodies', 'usableBodies', 'hashedBodies']}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
