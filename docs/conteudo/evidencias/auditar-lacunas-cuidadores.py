"""Verify the targeted caregiver execution audit offline; never create instructions."""
import importlib.util
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-13/n15c-lacunas-dirigidas'
SPEC = importlib.util.spec_from_file_location('caregiver_catalogue', ROOT.parent / 'consultar-cuidadores.py')
CATALOGUE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CATALOGUE)


def analyse(write=True):
    catalogue = CATALOGUE.validate()
    path = FOLDER / 'auditoria-conteudo.json'
    audit = json.loads(path.read_text(encoding='utf-8'))
    if audit['researchClosureApproved'] or audit['releaseApproved'] or audit['appImplemented']:
        raise ValueError('Unresolved targeted audit cannot approve niche or publication')
    packages = []
    for row in audit['items']:
        package_path = CATALOGUE.bounded_path(row['package'], FOLDER, ROOT)
        payload = package_path.read_bytes()
        package = json.loads(payload)
        if package['primarySourceId'] != row['sourceId']:
            raise ValueError('Different programme family')
        for pointer in row['sourcePointers']:
            CATALOGUE.pointer(package, pointer)
        pending = [x for x in row['remainingSourceResearch'] if not x['resolved']]
        if row['executableResearchClosedInDeclaredPath'] and pending:
            raise ValueError('Executable closure has unresolved source questions')
        packages.append({'id':row['id'], 'file':package_path.relative_to(ROOT).as_posix(),
                         'sha256':hashlib.sha256(payload).hexdigest(),
                         'sourcePointersChecked':len(row['sourcePointers']),
                         'pendingSourceQuestions':len(pending)})
    receipts = []
    for receipt_path in sorted(FOLDER.glob('*.evidencia.json')):
        record = json.loads(receipt_path.read_text(encoding='utf-8'))
        body_path = CATALOGUE.bounded_path(record['bodyFile'], receipt_path.parent, ROOT)
        body = body_path.read_bytes()
        if len(body) != record['bytes'] or hashlib.sha256(body).hexdigest() != record['sha256']:
            raise ValueError('New body integrity mismatch')
        row = {'record':receipt_path.relative_to(ROOT).as_posix(),
                         **{key:record.get(key) for key in ('id','url','resolvedUrl','collectedAtUtc','status','bytes','sha256')},
                         'usableBody':record['status']==200 and not record.get('error'),
                         'originalCaregiverExerciseInstructions':False}
        if row['usableBody'] and record['id'].endswith('atual-pdf'):
            from pypdf import PdfReader
            pdf = PdfReader(body_path)
            expected = 16 if 'ombro' in record['id'] else 10
            if not body.startswith(b'%PDF-') or len(pdf.pages) != expected:
                raise ValueError('Wrong auxiliary PDF representation')
            targets = [2,7,8,13,16] if expected == 16 else [2,3,4,5,10]
            row['pages'] = len(pdf.pages)
            row['textPagesChecked'] = [{'page':n,'textSha256':hashlib.sha256((pdf.pages[n-1].extract_text() or '').encode('utf-8')).hexdigest()} for n in targets]
            row['role'] = 'auxiliary_technique_comparison_not_original_caregiver_protocol'
        elif record['id']=='n15dir-cg04-handle-api-json' and row['usableBody']:
            data = json.loads(body)
            if data['responseCode']!=1 or data['handle']!='10810/68569':
                raise ValueError('Wrong thesis identifier')
            row['publishedUrls'] = [v['data']['value'] for v in data['values'] if v['type']=='URL']
            if row['publishedUrls'] != ['https://addi.ehu.eus/handle/10810/68569']:
                raise ValueError('Canonical thesis reference changed')
            row['role'] = 'identifier_metadata_not_thesis'
        if record['id']=='n15dir-cg04-tese-canonica-html':
            row['securityChallengeReceived'] = b'g-recaptcha' in body
            if not row['securityChallengeReceived']:
                raise ValueError('Expected access-boundary snapshot changed')
            row['role'] = 'security_challenge_not_pdf_or_metadata'
        receipts.append(row)
    requested = {x['id']:x['url'] for p in FOLDER.glob('requisicoes*.json') for x in json.loads(p.read_text(encoding='utf-8'))['requests']}
    if set(requested)!=set(x['id'] for x in receipts) or any(requested[x['id']]!=x['url'] for x in receipts):
        raise ValueError('Requests and preserved receipts disagree')
    if len(receipts) != 9 or sum(x['usableBody'] for x in receipts) != 5:
        raise ValueError('Targeted collector snapshot changed')
    both = [x['id'] for x in audit['items'] if x['executableResearchClosedInDeclaredPath']]
    if both != audit['summary']['bothResearchGatesMetItems'] or audit['allFiveExecutableResearchClosed'] != (len(both)==5):
        raise ValueError('Aggregate executable flags disagree')
    result = {'date':'2026-10-13','itemsChecked':len(packages),
              'sourceQuestionsStillPending':sum(x['pendingSourceQuestions'] for x in packages),
              'bothResearchGatesMetItems':both,
              'factualResearchClosedItems':catalogue['researchClosedItems'],
              'catalogueFieldsChecked':catalogue['mappedFields'],
              'previousSelectedPrimaryBodiesRevalidated':catalogue['verifiedPrimaryReceipts'],
              'newCollectorCalls':9,'newUsableGeneralRightsBodies':2,
              'newUsableMetadataBodies':1,'newUsableAuxiliaryTechniqueBodies':2,
              'newOriginalCaregiverInstructionBodies':0,'newFailedBodies':4,
              'receiptBodiesHashed':catalogue['verifiedPrimaryReceipts']+len(receipts),
              'nonEmptyNewBodiesHashed':sum(x['bytes']>0 for x in receipts),
              'networkCallsDuringAnalysis':0,'mechanicalChecksAreClinicalOrLegalApproval':False,
              'n15GlobalClosed':False,'n21Allowed':False,'releaseApproved':False,'appImplemented':False,
              'auditSha256':hashlib.sha256(path.read_bytes()).hexdigest(),
              'catalogueSha256':hashlib.sha256(CATALOGUE.CATALOGUE.read_bytes()).hexdigest(),
              'packages':packages,'newReceipts':receipts,
              'comparisonSha256':hashlib.sha256((FOLDER/'cotejo-g4.json').read_bytes()).hexdigest()}
    if write:
        (FOLDER / 'inventario-lacunas.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__ == '__main__':
    result = analyse()
    print(json.dumps({k:v for k,v in result.items() if k not in ('packages','newReceipts')},ensure_ascii=False))
