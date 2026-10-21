"""Audit Pilates originals and new metadata; failed publisher bodies stay failures."""
import hashlib
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-12/cg05-pilates'
ORIGINALS = [
    ('2026-10-11/n15c-pilates-cuidadores','c15-pilates-pediatrico2019-tese-pdf'),
    ('2026-10-11/n15c-pilates-cuidadores','c15-pilates-pediatrico2019-tese-html'),
    ('2026-10-11/n15c-pilates-cuidadores','c15-pilates-pediatrico2021-registro-json'),
    ('2026-10-11/n15c-pilates-cuidadores','c15-kirmizigil-bio-pdf'),
    ('2026-10-11/n15c-pilates-cuidadores','c15-pilates-pediatrico2019-licenca-txt'),
    ('2026-10-11/n15c-pilates-2021','c15-pilates-pediatrico2021-core-json'),
]
NEW = ['cg05-cer-crossref-json','cg05-bmr2021-core-json','cg05-cer2021-editor-html','cg05-cer2021-editor-pdf']


def analyse(write=True):
    paths = [ROOT / folder / (identifier+'.evidencia.json') for folder,identifier in ORIGINALS]
    paths += [FOLDER / (identifier+'.evidencia.json') for identifier in NEW]
    rows = []
    for path in paths:
        receipt = json.loads(path.read_text(encoding='utf-8'))
        body_path = (path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = body_path.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body integrity mismatch: '+receipt['id'])
        usable = receipt['status']==200 and not receipt.get('error')
        if path in paths[:len(ORIGINALS)] and not usable:
            raise ValueError('Original unusable')
        row = {key:receipt.get(key) for key in ['id','url','resolvedUrl','collectedAtUtc','status','bytes','sha256','error']}
        row.update(record=path.relative_to(ROOT).as_posix(), usableForReading=usable)
        if not usable:
            row.update(failedBodyIsInstruction=False, fullArticleReceived=False)
        elif receipt['id']=='c15-pilates-pediatrico2019-tese-pdf':
            reader = PdfReader(body_path)
            if len(reader.pages)!=152:
                raise ValueError('Thesis version differs')
            row['pdfPages'] = 152
            row['selectedPagesText'] = {str(n):reader.pages[n-1].extract_text() for n in [34,35,36,49,50,51,52,53,54,65,68,71,119]}
        elif receipt['id']=='cg05-cer-crossref-json':
            message = json.loads(body)['message']
            if message['DOI']!='10.2217/cer-2020-0108':
                raise ValueError('Wrong publication')
            row['metadata'] = {key:message.get(key) for key in ['DOI','publisher','resource','link','license']}
            row['metadataIsFullArticle'] = False
        elif receipt['id']=='cg05-bmr2021-core-json':
            data = json.loads(body)['resultList']['result'][0]
            if data['id']!='33935055' or data['doi'].lower()!='10.3233/bmr-191649':
                raise ValueError('Wrong complementary paper')
            row['metadata'] = {key:data.get(key) for key in ['id','doi','title','clinicalTrialList','isOpenAccess','inPMC','hasPDF']}
            row.update(bodyScope='metadata_and_abstract_not_full_methods', exactSameCohortNctConfirmed=False)
        rows.append(row)
    result = {
        'date':'2026-10-12','primarySourceId':'PR136','originalBodiesRevalidated':len(ORIGINALS),
        'newCollectorCalls':len(NEW),'newUsableBodies':sum(r['usableForReading'] for r in rows[len(ORIGINALS):]),
        'receiptBodiesHashed':len(rows),'receipts':rows,'networkCallsDuringAnalysis':0,
        'publisherFullArticleBodyLocallyReceived':False,'webReadingIsLocalRawArticle':False,
        'mechanicalAnalysisApprovesClosure':False,'visualReviewIsNotScriptConfirmed':True,
        'releaseApproved':False,'appImplemented':False,
    }
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__=='__main__':
    audit = analyse()
    print(json.dumps({key:value for key,value in audit.items() if key!='receipts'}))
