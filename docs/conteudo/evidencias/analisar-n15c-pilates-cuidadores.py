"""Audit public caregiver Pilates returns offline; render is not visual review."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-pilates-cuidadores'
PDFS = {
    'c15-ms-pilates2024-pdf': ('ms', [1, 4, 5, 6, 7]),
    'c15-pilates-pediatrico2019-tese-pdf': ('tese', [2, 36, 49, 50, 51, 52, 53, 54, 59, 65, 68, 71, 119]),
    'c15-kirmizigil-bio-pdf': ('bio', [1]),
}


def analyse(render=False, write=True):
    from pypdf import PdfReader
    rows = []
    for receipt_path in sorted(FOLDER.glob('*.evidencia.json')):
        receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        source = (FOLDER / receipt['bodyFile']).resolve()
        if not source.is_relative_to(ROOT.resolve()):
            raise ValueError('Body path outside evidence root')
        body = source.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body integrity mismatch')
        usable = receipt['status'] == 200 and not receipt.get('error') and bool(body)
        row = {k: receipt[k] for k in ('id', 'url', 'status', 'bytes', 'sha256')}
        row.update(record=receipt_path.relative_to(ROOT).as_posix(), usableForReading=usable)
        if usable and receipt['id'] in PDFS:
            label, selected = PDFS[receipt['id']]
            if not body.startswith(b'%PDF-'):
                raise ValueError('Not a PDF')
            reader = PdfReader(source)
            row.update(pdfPages=len(reader.pages), pdfText=[] if label == 'bio' else [page.extract_text() for page in reader.pages],
                       selectedRenderPages=selected, renderedThisRun=render, renderIsVisualReview=False)
            if render:
                import pypdfium2 as pdfium
                target = FOLDER / 'raw-render'
                target.mkdir(exist_ok=True)
                document = pdfium.PdfDocument(source)
                for number in selected:
                    page = document[number - 1]
                    bitmap = page.render(scale=1.7)
                    bitmap.to_pil().save(target / (label + '-page-' + str(number) + '.png'))
                    bitmap.close()
                    page.close()
                document.close()
        elif usable and receipt['id'].endswith('registro-json'):
            study = json.loads(body)
            row.update(nctId=study['protocolSection']['identificationModule']['nctId'],
                       hasResults=study.get('hasResults'),
                       largeDocs=study.get('documentSection', {}).get('largeDocumentModule', {}).get('largeDocs', []))
        elif usable and receipt['id'].endswith('tese-html'):
            from html.parser import HTMLParser

            class Links(HTMLParser):
                def __init__(self):
                    super().__init__()
                    self.links = []

                def handle_starttag(self, tag, attrs):
                    if tag == 'a':
                        attr = dict(attrs)
                        if attr.get('href'):
                            self.links.append({'href': attr['href'], 'rel': attr.get('rel')})

            parser = Links()
            parser.feed(body.decode('utf-8'))
            row['licenseAndOriginalLinks'] = [link for link in parser.links
                if link['rel'] == 'license' or '/bitstreams/' in link['href']]
            row['siteLicenseIsItemLicense'] = False
        rows.append(row)
    result = {'niche': 'N15-C', 'date': '2026-10-11', 'collectorCalls': len(rows),
              'http200': sum(row['status'] == 200 for row in rows),
              'hashedBodies': sum(bool(row['sha256']) for row in rows),
              'usableBodies': sum(row['usableForReading'] for row in rows), 'receipts': rows,
              'networkCallsDuringAnalysis': 0, 'researchClosureApproved': False,
              'releaseApproved': False, 'appImplemented': False,
              'manifestInterruption': 'Unsupported application/json Accept rejected before registry GET; first PDF received once. Remaining first GETs in requisicoes-registros.json; no retry or overwrite.'}
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    result = analyse(parser.parse_args().render)
    print(json.dumps({k: v for k, v in result.items() if k != 'receipts'}, ensure_ascii=False))
