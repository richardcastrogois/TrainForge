"""Audit received frailty-caregiver originals offline; do not infer clinical content."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-mbi-fragilidade'
PAGES = {'artigo': [6, 7, 12, 16], 'protocolo': [3, 5, 7, 8]}


def analyse(render=False):
    from pypdf import PdfReader
    rows = []
    for request in json.loads((FOLDER / 'requisicoes.json').read_text(encoding='utf-8'))['requests']:
        receipt_path = FOLDER / (request['id'] + '.evidencia.json')
        receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        source = (FOLDER / receipt['bodyFile']).resolve()
        if request['url'] != receipt['url'] or not source.is_relative_to(ROOT.resolve()):
            raise ValueError('Receipt identity/path mismatch')
        body = source.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body integrity mismatch')
        usable = receipt['status'] == 200 and not receipt.get('error') and bool(body)
        row = {'id':request['id'], 'record':receipt_path.relative_to(ROOT).as_posix(),
               'url':receipt['url'], 'status':receipt['status'], 'bytes':len(body),
               'sha256':receipt['sha256'], 'usableForReading':usable}
        if usable and request['extension'] == 'pdf':
            reader = PdfReader(source)
            row['pdfPages'] = len(reader.pages)
            row['pdfText'] = [p.extract_text() for p in reader.pages]
            label = 'protocolo' if 'protocolo' in request['id'] else 'artigo'
            row['renderedThisRun'] = render
            row['selectedRenderPages'] = PAGES[label]
            row['renderIsVisualReview'] = False
            if render:
                import pypdfium2 as pdfium
                target = FOLDER / 'raw-render'
                target.mkdir(exist_ok=True)
                document = pdfium.PdfDocument(source)
                for number in PAGES[label]:
                    page = document[number - 1]
                    bitmap = page.render(scale=1.5)
                    bitmap.to_pil().save(target / (label + '-page-' + str(number) + '.png'))
                    bitmap.close()
                    page.close()
                document.close()
        if usable and request['extension'] == 'json':
            study = json.loads(body)
            row['nctId'] = study['protocolSection']['identificationModule']['nctId']
            row['hasResults'] = study.get('hasResults')
            row['lastUpdate'] = study['protocolSection']['statusModule']['lastUpdatePostDateStruct']['date']
            row['largeDocs'] = study.get('documentSection', {}).get('largeDocumentModule', {}).get('largeDocs', [])
        rows.append(row)
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'http200':sum(r['status'] == 200 for r in rows),
              'hashedBodies':sum(bool(r['sha256']) for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows), 'receipts':rows,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    print(json.dumps(analyse(parser.parse_args().render), ensure_ascii=False))
