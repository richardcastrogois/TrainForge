"""Read original caregiver self-care returns offline; keep failures and version limits."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-autocuidado-roteiros'


def analyse(render=False, write=True):
    rows = []
    for record_path in sorted(FOLDER.glob('*.evidencia.json')):
        receipt = json.loads(record_path.read_text(encoding='utf-8'))
        row = {key: receipt.get(key) for key in ('id', 'url', 'status', 'bytes', 'sha256', 'error')}
        row['record'] = record_path.relative_to(ROOT).as_posix()
        usable = receipt.get('status') == 200 and not receipt.get('error') and bool(receipt.get('bytes'))
        row['usableForReading'] = usable
        if receipt.get('bodyFile'):
            path = (FOLDER / receipt['bodyFile']).resolve()
            if not path.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Integrity mismatch')
            if usable and row['id'].endswith('xml'):
                article = ET.fromstring(body)
                row['doi'] = article.findtext('.//article-id[@pub-id-type="doi"]')
                row['permissions'] = [' '.join(p.itertext()) for p in article.findall('.//permissions')]
                row['sections'] = [{'id':s.get('id'), 'title':s.findtext('title'), 'text':' '.join(s.itertext())}
                                   for s in article.findall('.//sec') if s.find('title') is not None]
                row['tables'] = [{'id': t.get('id'), 'label': t.findtext('label'), 'text': ' '.join(t.itertext())}
                                 for t in article.findall('.//table-wrap')]
                row['supplementFiles'] = [m.get('{http://www.w3.org/1999/xlink}href')
                                          for m in article.findall('.//supplementary-material//media')]
            if usable and row['id'].endswith('pdf'):
                from pypdf import PdfReader
                if not body.startswith(b'%PDF-'):
                    raise ValueError('Not a PDF body')
                reader = PdfReader(path)
                row.update(pdfPages=len(reader.pages), pdfText=[p.extract_text() for p in reader.pages],
                           selectedRenderPages=[3,4,5,6,7], renderedThisRun=render, renderIsVisualReview=False)
                if render:
                    import pypdfium2 as pdfium
                    target = FOLDER / 'raw-render'
                    target.mkdir(exist_ok=True)
                    document = pdfium.PdfDocument(path)
                    for number in row['selectedRenderPages']:
                        page = document[number - 1]
                        bitmap = page.render(scale=1.6)
                        bitmap.to_pil().save(target / ('pfa-page-'+str(number)+'.png'))
                        bitmap.close()
                        page.close()
                    document.close()
        rows.append(row)
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'usableBodies':sum(r['usableForReading'] for r in rows), 'receipts':rows,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    result = analyse(parser.parse_args().render)
    print(json.dumps({k:v for k,v in result.items() if k != 'receipts'}))
