"""Verifica originais digitais de N15-C, sem converter leitura em aprovacao."""
import argparse
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-domestico-digital'
RAW = ROUND.parent / 'raw'
spec = importlib.util.spec_from_file_location('digital_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
PDF_PAGES = {
    'c15-roshid2024-protocolo-pdf': (8, [1, 3, 4, 5]),
    'c15-rutgers-autocuidado-familiar-pdf': (36, [2, 12, 13, 20, 21, 22, 24, 35, 36]),
    'c15-rutgers-autocuidado-profissional-pdf': (36, [2, 12, 13, 20, 21, 22, 24, 35, 36]),
}


def analyse(render=False):
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (item['id'] + '.evidencia.json'), ROOT)
               for item in plan['requests']]
    root = ET.parse(RAW / 'c15-roshid2024-protocolo-xml.xml').getroot()
    licence = ET.tostring(root.find('.//permissions'), encoding='unicode')
    assert 'licenses/by/4.0' in licence
    for ident, (count, pages) in PDF_PAGES.items():
        reader = PdfReader(RAW / (ident + '.pdf'))
        assert len(reader.pages) == count
        entry = next(item for item in entries if item['id'] == ident)
        entry.update(pdfPages=count, renderedPdfPages=pages if render else [])
        if 'rutgers' in ident:
            dose_text = ' '.join(reader.pages[19].extract_text().split())
            assert '3 to 5' in dose_text
            assert '10 minutes' in dose_text
            assert 'permission' in reader.pages[34].extract_text()
            assert '2019 Rutgers' in reader.pages[35].extract_text()
        if render:
            import pypdfium2 as pdfium
            document = pdfium.PdfDocument(RAW / (ident + '.pdf'))
            try:
                for number in pages:
                    page = document[number - 1]
                    bitmap = page.render(scale=1.4)
                    try:
                        bitmap.to_pil().save(RAW / f'{ident}-p{number}.png')
                    finally:
                        bitmap.close()
                        page.close()
            finally:
                document.close()
    result = {'date':'2026-10-07', 'niche':'N15-C', 'networkPerformed':False,
              'sources':entries, 'newCollectorCalls':len(entries),
              'http200Bodies':sum(item['status'] == 200 for item in entries),
              'usableBodies':sum(item['usable'] for item in entries),
              'hashedBodies':sum(item['bodyVerified'] for item in entries),
              'protocolLicence':licence, 'visualInspectionConfirmedByScript':False,
              'researchClosureApproved':False, 'releaseApproved':False, 'appImplemented':False}
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key:result[key] for key in ('newCollectorCalls','http200Bodies','usableBodies','hashedBodies')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
