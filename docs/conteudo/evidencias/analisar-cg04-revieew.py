"""Revalidate ReViEEW primary bodies and extract the new registry without networking."""
import hashlib
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-12/cg04-revieew'
ORIGINALS = [
    ('2026-10-07/n15c-programa', 'c15-revieew-protocolo-pdf'),
    ('2026-10-07/n15c-programa', 'c15-revieew-resultados-pdf'),
    ('2026-10-07/n15c-revieew-suplementos', 'c15-revieew-si1-tif'),
    ('2026-10-07/n15c-revieew-suplementos', 'c15-revieew-si2-tif'),
    ('2026-10-07/n15c-revieew-suplementos', 'c15-revieew-si3-tif'),
    ('2026-10-07/n15c-revieew-suplementos', 'c15-revieew-si4-docx'),
    ('2026-10-07/n15c-ufpb', 'c15-revieew-autoria-ehu'),
    ('2026-10-07/n15c-ufpb', 'c15-revieew-professor-ehu'),
    ('2026-10-07/n15c-teses-seguimento', 'c15-revieew-seguimento-europepmc'),
    ('2026-10-07/n15c-teses-seguimento', 'c15-revieew-aderencia2026-html'),
]
PDF_PAGES = {
    'c15-revieew-protocolo-pdf': [1,3,4,5,6,7,9,10,11],
    'c15-revieew-resultados-pdf': [1,2,3,4,5,6,7,8,9,11],
}


def analyse(write=True):
    paths = [ROOT / folder / (identifier + '.evidencia.json') for folder, identifier in ORIGINALS]
    paths.append(FOLDER / 'cg04-revieew-registro-json.evidencia.json')
    rows = []
    registry = None
    for path in paths:
        receipt = json.loads(path.read_text(encoding='utf-8'))
        body_path = (path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = body_path.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body integrity mismatch: ' + receipt['id'])
        if receipt['status'] != 200 or receipt.get('error'):
            raise ValueError('Primary body unusable: ' + receipt['id'])
        row = {key:receipt.get(key) for key in ['id','url','resolvedUrl','collectedAtUtc','status','bytes','sha256']}
        row['record'] = path.relative_to(ROOT).as_posix()
        if receipt['id'] in PDF_PAGES:
            reader = PdfReader(body_path)
            expected = 11 if 'protocolo' in receipt['id'] else 12
            if len(reader.pages) != expected:
                raise ValueError('Unexpected PDF version')
            row['pdfPages'] = len(reader.pages)
            row['selectedPagesText'] = {str(n):reader.pages[n-1].extract_text() for n in PDF_PAGES[receipt['id']]}
        if receipt['id'] == 'cg04-revieew-registro-json':
            data = json.loads(body)
            p = data['protocolSection']
            if p['identificationModule']['nctId'] != 'NCT05050526':
                raise ValueError('Wrong study registry')
            registry = {
                'id':'NCT05050526',
                'status':p['statusModule']['overallStatus'],
                'lastUpdatePostDate':p['statusModule']['lastUpdatePostDateStruct']['date'],
                'enrollment':p['designModule']['enrollmentInfo'],
                'interventionDescription':p['armsInterventionsModule']['interventions'][0]['description'],
                'eligibility':p['eligibilityModule'],
                'hasResults':data.get('hasResults', False),
                'hasResultsSection':bool(data.get('resultsSection')),
                'hasDocumentSection':bool(data.get('documentSection')),
                'publishedReferences':p.get('referencesModule', {}).get('references', []),
                'registryNoInterventionControlOverridesExecutedPaper':False,
                'completionDateProvesClinicalEfficacy':False,
            }
        rows.append(row)
    result = {
        'date':'2026-10-12', 'primarySourceId':'PR68', 'originalBodiesRevalidated':len(ORIGINALS),
        'newCollectorCalls':1, 'preflightFailureBeforeNetworking':{'unsupportedAccept':True,'networkCalls':0},
        'newUsableBodies':1, 'receiptBodiesHashed':len(rows), 'receipts':rows, 'registry':registry,
        'networkCallsDuringAnalysis':0, 'mechanicalAnalysisApprovesClosure':False,
        'visualReviewIsNotScriptConfirmed':True, 'releaseApproved':False, 'appImplemented':False,
    }
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    audit = analyse()
    print(json.dumps({key:value for key,value in audit.items() if key not in ('receipts','registry')}))
