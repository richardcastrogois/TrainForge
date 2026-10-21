"""Inventory the two legitimate public antecedent returns without network calls."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-yoga-antecedentes'


def analyse(write=True):
    rows = []
    for record in sorted(FOLDER.glob('*.evidencia.json')):
        receipt = json.loads(record.read_text(encoding='utf-8'))
        row = {key: receipt.get(key) for key in ('id', 'url', 'status', 'bytes', 'sha256', 'error')}
        row['record'] = record.relative_to(ROOT).as_posix()
        row['usableForReading'] = receipt['status'] == 200 and not receipt.get('error') and bool(receipt.get('bytes'))
        if receipt.get('bodyFile'):
            path = (FOLDER / receipt['bodyFile']).resolve()
            if not path.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Integrity mismatch')
            if row['usableForReading'] and row['id'].endswith('xml'):
                article = ET.fromstring(body)
                row['doi'] = article.findtext('.//article-id[@pub-id-type="doi"]')
                row['permissions'] = [' '.join(p.itertext()) for p in article.findall('.//permissions')]
                row['sections'] = [{'id': s.get('id'), 'title': s.findtext('title'), 'text': ' '.join(s.itertext())}
                                   for s in article.findall('.//sec') if s.find('title') is not None]
                row['tables'] = [{'id':t.get('id'), 'text':' '.join(t.itertext()),
                                  'graphics':[g.get('{http://www.w3.org/1999/xlink}href') for g in t.findall('.//graphic')]}
                                 for t in article.findall('.//table-wrap')]
                row['supplementFiles'] = [m.get('{http://www.w3.org/1999/xlink}href')
                                          for m in article.findall('.//supplementary-material//media')]
            if row['usableForReading'] and row['id'].endswith('json'):
                row['results'] = json.loads(body).get('resultList', {}).get('result', [])
        rows.append(row)
    result = {'niche':'N15-C', 'date':'2026-10-11', 'collectorCalls':len(rows),
              'usableBodies':sum(r['usableForReading'] for r in rows), 'receipts':rows,
              'networkCallsDuringAnalysis':0, 'researchClosureApproved':False,
              'releaseApproved':False, 'appImplemented':False}
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    result = analyse()
    print(json.dumps({k:v for k,v in result.items() if k != 'receipts'}))
