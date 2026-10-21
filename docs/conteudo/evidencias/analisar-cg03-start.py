"""Audit START's original evidence and failed new representations without networking."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-12/cg03-start'
ORIGINAL = ROOT / '2026-10-11/n15c-start-originais'
ORIGINAL_NAMES = ['c15-start2013-rct-xml', 'c15-start2014-nihr-relatorio-pdf', 'c15-start2014-nihr-resumo-pdf']
METHOD_PAGES = [37,38,39,41]


def analyse(write=True):
    paths = [ORIGINAL / (name+'.evidencia.json') for name in ORIGINAL_NAMES]
    paths += sorted(FOLDER.glob('*.evidencia.json'))
    rows = []
    for path in paths:
        receipt = json.loads(path.read_text(encoding='utf-8'))
        body_path = (path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = body_path.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Integrity mismatch')
        usable = receipt['status']==200 and not receipt.get('error')
        row = {key:receipt.get(key) for key in ['id','url','resolvedUrl','collectedAtUtc','status','bytes','sha256','error']}
        row.update(record=path.relative_to(ROOT).as_posix(), usableForReading=usable)
        if usable and receipt['id'].endswith('xml'):
            article = ET.fromstring(body)
            doi = next(e.text for e in article.findall('.//article-id') if e.get('pub-id-type')=='doi')
            if doi != '10.1136/bmj.f6276':
                raise ValueError('Wrong trial family')
            row['doi'] = doi
            row['therapyBoxText'] = ' '.join(article.find('.//boxed-text').itertext())
            row['methodsText'] = '\n'.join(' '.join(p.itertext()) for p in article.findall('.//p')
                                         if any(word in ' '.join(p.itertext()).lower() for word in
                                                ['psychology graduates','at least weekly','8-14 weeks']))
        elif usable and body.startswith(b'%PDF-'):
            from pypdf import PdfReader
            pdf = PdfReader(body_path)
            row['pdfPages'] = len(pdf.pages)
            if 'relatorio' in receipt['id']:
                if len(pdf.pages)!=272:
                    raise ValueError('Original report length changed')
                row['methodPagesText'] = {str(n):pdf.pages[n-1].extract_text() for n in METHOD_PAGES}
        else:
            row['notParsedAsInstructions'] = True
            row['failureCountsAsDocxOrClinicalEvidence'] = False
        rows.append(row)
    result = {
        'date':'2026-10-12', 'primarySourceId':'PR115', 'originalBodiesRevalidated':3,
        'newCollectorCalls':3, 'newUsableBodies':sum(r['usableForReading'] for r in rows[3:]),
        'receiptBodiesHashed':len(rows), 'receipts':rows, 'networkCallsDuringAnalysis':0,
        'wholeReportVisuallyReviewed':False, 'mechanicalAnalysisApprovesClosure':False,
        'closureDecisionFile':'pacote-factual.json', 'releaseApproved':False, 'appImplemented':False,
    }
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    audit = analyse()
    print(json.dumps({key:value for key,value in audit.items() if key!='receipts'}))
