"""Confere recibos, extrai e renderiza o guia raster da dissertacao, sem rede."""
import argparse
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-ufpb'
spec = importlib.util.spec_from_file_location('ufpb_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
PDF_ID = 'c15-ufpb-dissertacao-2018'
RENDER_PAGES = [2, 4, 48, 52, 53, *range(68, 84), 85]


def analyse(render=False):
    entries = []
    for request in json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))['requests']:
        path = ROUND / (request['id'] + '.evidencia.json')
        entry = receipts.check_receipt(path, ROOT)
        entries.append(entry)
    path = ROUND / (PDF_ID + '.evidencia.json')
    record = json.loads(path.read_text(encoding='utf-8'))
    body = (path.parent / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    reader = PdfReader(body)
    if len(reader.pages) != 108:
        raise ValueError('Unexpected source version/page count')
    for number in [2, 4, 48, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 85]:
        print(f'PDF page{number}: ' + ' '.join((reader.pages[number - 1].extract_text() or '').split()))
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(body)
        try:
            for number in RENDER_PAGES:
                page = document[number - 1]
                bitmap = page.render(scale=1.6)
                try:
                    bitmap.to_pil().save(ROUND.parent / 'raw' / f'PR69-thesis-p{number}.png')
                finally:
                    bitmap.close()
                    page.close()
        finally:
            document.close()
    result = dict(date='2026-10-07', niche='N15-C', networkPerformed=False,
                  sources=entries, newCollectorCalls=5,
                  usableBodies=sum(e['usable'] for e in entries),
                  hashedBodies=len(entries), pdfPages=108,
                  guideRasterPdfPages=list(range(68, 84)),
                  renderedPages=RENDER_PAGES if render else [],
                  visualInspectionConfirmedByScript=False,
                  researchClosureApproved=False, releaseApproved=False, appImplemented=False)
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: result[k] for k in ('newCollectorCalls', 'usableBodies', 'hashedBodies')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
