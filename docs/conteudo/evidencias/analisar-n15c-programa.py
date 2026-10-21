"""Auditoria offline ReViEEW: protocolo e resultados separados, sem criar treino."""
import argparse
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-programa'
spec = importlib.util.spec_from_file_location('programme_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
SOURCES = [('protocol', 'c15-revieew-protocolo-pdf', 11),
           ('results', 'c15-revieew-resultados-pdf', 12)]


def analyse(render=False):
    sources = []
    for role, identifier, page_count in SOURCES:
        path = ROUND / f'{identifier}.evidencia.json'
        entry = receipts.check_receipt(path, ROOT)
        if not entry['usable']:
            raise ValueError('Required primary body not received')
        record = json.loads(path.read_text(encoding='utf-8'))
        body = (path.parent / record['bodyFile']).resolve()
        reader = PdfReader(body)
        if len(reader.pages) != page_count:
            raise ValueError('Unexpected page count/version')
        pages = list(range(1, page_count + 1))
        entry.update(sourceId='PR68', role=role, pdfPages=page_count,
                     readPdfPagesOneBased=pages,
                     receipt=str(path.relative_to(ROOT)).replace('\\', '/'))
        for number, page in enumerate(reader.pages, 1):
            text = ' '.join((page.extract_text() or '').split())
            if not text:
                raise ValueError('Unexpected empty text page')
            print(f'{role} page{number}: {text}')
        if render:
            import pypdfium2 as pdfium
            doc = pdfium.PdfDocument(body)
            try:
                for number in pages:
                    page = doc[number - 1]
                    bitmap = page.render(scale=1.5)
                    try:
                        bitmap.to_pil().save(ROUND.parent / 'raw' / f'PR68-{role}-p{number}.png')
                    finally:
                        bitmap.close()
                        page.close()
            finally:
                doc.close()
        sources.append(entry)
    output = dict(date='2026-10-07', scope=['N15-C'], networkPerformed=False,
                  sources=sources, newCollectorCalls=2, reusedBodies=0,
                  renderedPagesThisRun=sum(s[2] for s in SOURCES) if render else 0,
                  visualInspectionConfirmedByScript=False,
                  researchClosureApproved=False, releaseApproved=False, appImplemented=False)
    (ROUND / 'inventario.json').write_text(json.dumps(output, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(dict(verifiedBodies=len(sources), newCollectorCalls=2)))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
