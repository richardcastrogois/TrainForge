"""Confere os originais N15-C; protocolo recebido nao significa rotina aprovada."""
import argparse
import importlib.util
import json
import logging
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-sequencias'
RAW = ROUND.parent / 'raw'
spec = importlib.util.spec_from_file_location('sequence_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
VISUAL_PAGES = [1, 2, 20, 21, *range(57, 68)]


def analyse(render=False):
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (item['id'] + '.evidencia.json'), ROOT)
               for item in plan['requests']]
    for item in entries:
        if item['id'] == 'c15-transfe-tese-metadados':
            shell = (RAW / 'c15-transfe-tese-metadados.html').read_text(encoding='utf-8')
            assert '<ds-app></ds-app>' in shell and 'TRANSFE' not in shell
            item.update(usable=False, reason='HTTP200 apenas shell Angular; nao metadados/tese recebidos.')
    licences = {}
    for ident, required in [('c15-pouraboli2019-xml', 'licenses/by/3.0'),
                            ('c15-umadevi2013-xml', 'licenses/by-nc-sa/3.0'),
                            ('c15-transfe2024-xml', 'licenses/by/4.0')]:
        root = ET.parse(RAW / (ident + '.xml')).getroot()
        licence = ET.tostring(root.find('.//permissions'), encoding='unicode')
        assert required in licence
        licences[ident] = licence
    metadata = json.loads((RAW / 'c15-transfe-osf-metadados.json').read_text(encoding='utf-8'))['data']
    files = json.loads((RAW / 'c15-transfe-osf-arquivos.json').read_text(encoding='utf-8'))
    assert metadata['attributes']['public'] is True
    assert metadata['attributes']['node_license'] is None
    assert files['links']['next'] is None and files['links']['meta']['total'] == 1
    file = files['data'][0]
    assert file['attributes']['name'] == 'Protocolo-2.pdf'
    pdf = next(item for item in entries if item['id'] == 'c15-transfe-osf-protocolo-pdf')
    assert pdf['sha256'] == file['attributes']['extra']['hashes']['sha256']
    assert pdf['bytes'] == file['attributes']['size'] == 11057370
    logging.getLogger('pypdf').setLevel(logging.ERROR)
    reader = PdfReader(RAW / 'c15-transfe-osf-protocolo-pdf.pdf')
    assert len(reader.pages) == 73
    pdf.update(pdfPages=73, renderedPdfPages=VISUAL_PAGES if render else [],
               textReadPdfPages=[1, 2, *range(9, 26), 30, *range(57, 68)],
               osfPublishedHashMatches=True, osfPublishedBytesMatch=True,
               parserWarnings='pypdf recupera referencias de objetos com offsets incorretos; nao reparou/modificou o original.')
    assert '20' in (reader.pages[61].extract_text() or '')
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(RAW / 'c15-transfe-osf-protocolo-pdf.pdf')
        try:
            for number in VISUAL_PAGES:
                page = document[number - 1]
                bitmap = page.render(scale=1.6)
                try:
                    bitmap.to_pil().save(RAW / f'c15-transfe-osf-protocolo-pdf-p{number}.png')
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
              'licenceStatements':licences, 'osfNodeLicence':None,
              'visualInspectionConfirmedByScript':False,
              'researchClosureApproved':False, 'releaseApproved':False, 'appImplemented':False}
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key:result[key] for key in ('newCollectorCalls','http200Bodies','usableBodies','hashedBodies')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
