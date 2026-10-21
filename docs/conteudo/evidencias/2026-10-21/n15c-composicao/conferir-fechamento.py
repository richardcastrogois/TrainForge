"""Offline source/selection integrity; never a clinical, legal or app certification."""
from pathlib import Path
from collections import Counter
from urllib.parse import unquote
import hashlib
import importlib.util
import json
import re
import subprocess
from pypdf import PdfReader

BASE = Path(__file__).resolve().parent
CONTENT = BASE.parents[2]
REPO = CONTENT.parents[1]
checks = []


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    if not condition:
        raise AssertionError(name)


library = read(BASE / 'biblioteca-cuidadores.json')
audit = read(BASE / 'auditoria-fechamento.json')
decision = read(BASE / 'decisao-de-recorte.json')
reading = read(BASE / 'leitura-fontes.json')
check('All seven documentary research criteria recorded; no release',
      len(audit['criteria']) == 7 and all(row['met'] for row in audit['criteria'])
      and audit['researchClosed'] and not audit['releaseApproved'] and not audit['appImplemented'])
check('Eleven unique components, three separate source groups',
      len(library['components']) == 11 and len({c['id'] for c in library['components']}) == 11
      and Counter(c['group'] for c in library['components']) == {'CG01': 1, 'CG04': 8, 'CG06': 2})
check('Concrete preparation/movement/ending with source locators',
      all(all(c.get(k) for k in ['preparation', 'movement', 'ending', 'locator'])
          and c['group'] in library['sourceGroups'] for c in library['components']))
check('No new numerical prescription, clinical effect, review or app claimed',
      all(not library[k] for k in ['newNumericalPrescriptionInvented', 'newCombinationClinicallyValidated',
                                  'humanReviewOfNewPresentationPerformed', 'releaseApproved', 'appImplemented']))
check('Five original candidates explicitly considered; not five completed courses',
      {x['item'] for x in decision['originalCandidates']} == {f'CG-0{i}' for i in range(1, 6)}
      and not library['allFiveOriginalProgrammesExecutable']
      and not audit['allFiveOriginalProgrammesExecutableResearchClosed'])
for row in decision['originalCandidates']:
    for q in row.get('originalQuestions', []):
        if 'answeredForOriginalPath' in q:
            check('Unreceived original path not falsely resolved: ' + q['id'],
                  not q['answeredForOriginalPath'] and not q['requiredForSelectedLibrary'])
old = read(CONTENT / 'evidencias/2026-10-13/n15c-lacunas-dirigidas/auditoria-conteudo.json')
check('Historical five-programme execution audit preserved open',
      not old['allFiveExecutableResearchClosed'] and old['summary']['bothResearchGatesMetItems'] == ['CG-01'])

receipts = [read(p) for p in BASE.glob('*.evidencia.json')]
check('Seven actual collector records, five bodies, no hidden retries',
      len(receipts) == 7 and sum(r['status'] == 200 for r in receipts) == 5
      and reading['collection']['collectorAttempts'] == 7 and reading['collection']['retryAttempts'] == 0)
pdf_pages = {}
for r in receipts:
    if r['status'] != 200:
        check('Failed collection has no invented body/hash: ' + r['id'],
              not r.get('bodyFile') and not r.get('sha256') and bool(r.get('error')))
        continue
    p = (BASE / r['bodyFile']).resolve()
    body = p.read_bytes()
    check('Primary body bytes/hash: ' + r['id'],
          len(body) == r['bytes'] and hashlib.sha256(body).hexdigest() == r['sha256'])
    ignored = subprocess.run(['git', '-c', 'safe.directory=C:/dev/TrainForge/trainforge',
                              'check-ignore', '-q', '--', str(p.relative_to(REPO))], cwd=REPO)
    check('Third party raw body ignored: ' + r['id'], ignored.returncode == 0)
    if p.suffix == '.pdf':
        check('Actual PDF header: ' + r['id'], body.startswith(b'%PDF-'))
        pdf_pages[r['id']] = len(PdfReader(p).pages)
check('Three PDFs actually contain 8,138,7 pages',
      pdf_pages == {'n15m-nccih2016-publicdomain': 8,
                    'n15m-caregiversfirst-workbook2022': 138,
                    'n15m-first-credencial-newsletter2022': 7})

primary04 = read(CONTENT / 'evidencias/2026-10-12/cg04-revieew/pacote-factual.json')
thesis_path = CONTENT / 'evidencias/2026-10-14/raw/TESIS_ESPIN_ELORZA_ANDER.pdf'
check('Reused thesis original hash', hashlib.sha256(thesis_path.read_bytes()).hexdigest()
      == library['sourceGroups']['CG04']['thesisSha256'])
thesis = PdfReader(thesis_path)
check('Eight actual instruction sheets text present at primary locators',
      all(token in thesis.pages[page-1].extract_text() for page, token in
          [(264,'SENTADILLA'), (265,'PUENTE'), (266,'ZANCADA'), (267,'MUERTO'),
           (268,'PERRO'), (269,'LATERAL'), (271,'HORIZONTAL'), (272,'CODO')]))
check('CG04 dose remains source contextual data, not eight-item circuit',
      library['sourceGroups']['CG04']['sourceDoseContext']['weeklyWorkRestInEachFourWeekBlock']
      == primary04['progression']['weeklyWorkRestSeconds'][:4]
      and not library['sourceGroups']['CG04']['sourceDoseContext']['eightSelectedItemsAreNewEightMovementCircuit'])
check('Ambiguous arm line excluded and no advanced variant selected',
      all('ARM_RAISE' not in c['id'] and c['id'].endswith('-1') for c in library['components'] if c['group']=='CG04')
      and any(c['id']=='CG04-ARM_RAISE' for c in library['notSelected']))
check('Live professional support and private-media limit retained',
      primary04['delivery']['liveBidirectionalAudioAndVideoRequired']
      and not library['sourceGroups']['CG04']['rights']['privateVideosSelected']
      and not library['sourceGroups']['CG04']['rights']['copyrightGrantForAllThesisAssetsClaimed'])

first = PdfReader(CONTENT / 'evidencias/2026-10-21/raw/n15m-caregiversfirst-workbook2022.pdf')
signal = ' '.join(first.pages[11].extract_text().split())
visual = ' '.join(first.pages[48].extract_text().split())
check('Signal dose supported by actual primary text', '3 or 4 seconds' in signal and '2 or 3 times' in signal)
check('Visualization short-time option is primary instruction, not invented reduction',
      '3' in visual and '5 minutes' in visual and 'pressed for time' in visual)
check('Triangle contradiction retained, not selected',
      'repeat 4 times' in first.pages[77].extract_text()
      and 'two more times' in first.pages[78].extract_text()
      and not any('TRIANGLE' in c['id'] for c in library['components']))
check('PMR alternative acknowledged but not completed by AI',
      'do not have access to a computer' in ' '.join(first.pages[26].extract_text().split())
      and not any('PMR' in c['id'] for c in library['components']))
check('No blanket workbook licence or transferred article licence',
      not library['sourceGroups']['CG06']['rights']['wholeWorkbookOpenLicenceClaimed']
      and not library['sourceGroups']['CG06']['rights']['researchArticleCcByTransferredToWorkbook']
      and not library['sourceGroups']['CG06']['rights']['finalCommercialExpressionApproved'])

older = read(CONTENT / 'evidencias/2026-10-04/n15i-funcional/pacote-apk-snacking-2019.json')
check('Five older-adult movements still separate and unpublished',
      len(older['movements']) == 5 and older['id']=='ES2019-DOM-01'
      and not older['identity']['caregiverOwnProgrammeDemonstrated']
      and not older['releaseApproved'] and not older['appImplemented'])
for label in ['article', 'supplements']:
    prov = older['provenance']
    p = CONTENT / 'evidencias' / prov[label+'Record']
    r = read(p)
    check('Older-adult primary original hash retained: ' + label,
          hashlib.sha256((p.parent/r['bodyFile']).read_bytes()).hexdigest() == prov[label+'Sha256'])

removed = count = 0
for name in ['limpeza-leitura-01.json', 'limpeza-credencial.json']:
    d = read(BASE / name)
    check('Temporary renders absent: ' + name, d['absent'] and not Path(d['exactPath']).exists())
    removed += int(d['bytes']); count += d['count']
check('Nineteen temporary files removed with source receipts preserved', count == 19 and removed == 5289326)

consolidated = read(CONTENT / 'evidencias/2026-10-15/consolidacao-n01-n46.json')
queue = read(CONTENT / 'evidencias/2026-10-03/revisao-publicos-ambientes/fila-complementos-anteriores.json')
state = read(BASE / 'estado.json')
caregiver_queue = read(CONTENT / 'fila-cuidadores.json')
check('Current state and caregiver queue agree on scoped closure with no active item',
      state['researchClosed'] and state['activeItem'] is None and not state['allFiveOriginalProgrammesExecutable']
      and caregiver_queue['researchClosed'] and caregiver_queue['executionSequence']['activeItem'] is None
      and caregiver_queue['executionSequence']['selectedLibraryResearchClosed'])
check('46 accounted for, 40 scoped closures and six reuses, no open niche',
      len(consolidated['items']) == 46 and consolidated['closedResearch'] == 40
      and consolidated['documentedReuse'] == 6 and all(x['researchClosed'] for x in consolidated['items'])
      and consolidated['activeNiche'] is None and not consolidated['pausedOpen'])
check('Canonical queue current research closure without implementation',
      queue['allAnalysesClosed'] and queue['currentActiveNiche'] is None and not queue['pausedNiches']
      and not queue['currentExecutionAudit']['appImplemented'] and not queue['currentExecutionAudit']['releaseApproved'])
index = read(CONTENT / 'evidencias/retornos-observados.json')['records']
check('Global receipts actual counts and no hash mismatch',
      len(index)==840 and sum(x['httpStatus']==200 for x in index)==694
      and sum(x.get('originalBodyHashMatches', False) for x in index)==780
      and all(x.get('originalBodyHashMatches') is not False for x in index))
sources = read(CONTENT / 'fontes.json')['sources']
check('331 source families with unique IDs; three actual new families',
      len(sources)==331 and len({x['id'] for x in sources})==331
      and {x['sourceId'] for x in reading['sources']}=={'PR259','PR260','PR261'})
for source in reading['sources']:
    check('New family receipt exists: '+source['sourceId'], (BASE/source['receipt']).is_file())

spec = importlib.util.spec_from_file_location('caregivers', CONTENT / 'consultar-cuidadores.py')
module = importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
result = module.validate()
check('Historical 90 fields still resolve; new library separately accessible',
      result['mappedFields']==90 and result['verifiedPrimaryReceipts']==28
      and not result['researchClosureApproved'] and result['currentSelection']['researchClosed']
      and module.selected_library()['selectedComponents']==11)
email = read(BASE / 'respostas-solicitacoes.json')
check('Only prior three request threads checked, no new contact/grant claimed',
      len(email['threads'])==3 and email['targetedInboundSearchResults']==0
      and email['newMessagesSent']==0 and not email['permissionsOrReuseGrantsReceived'])

links = 0
generated_report_link = False
for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', (BASE/'relatorio.md').read_text(encoding='utf-8')):
    if target.startswith(('http://','https://','#')):
        continue
    target = unquote(target.split('#',1)[0].strip('<>'))
    if target == 'verificacoes.json':
        generated_report_link = True
        continue  # Its actual existence is checked after this run writes it.
    check('Report local target: '+target, (BASE/target).exists());links += 1
app_paths = ['lib','android','ios','web','windows','linux','macos','test','pubspec.yaml','pubspec.lock']
changed = subprocess.run(['git','-c','safe.directory=C:/dev/TrainForge/trainforge','status','--short','--']+app_paths,
                         cwd=REPO, check=True, capture_output=True, text=True)
check('No functional app path changed', not changed.stdout.strip())
output = {'date':'2026-10-21','scope':'Documentary integrity; no clinical/legal approval or app/user tests',
          'passed':len(checks),'failed':0,'checks':checks,'selectedCaregiverComponents':11,
          'olderAdultMovements':5,'collectorAttempts':7,'http200ThisRound':5,
          'globalGetAttempts':840,'globalHttp200':694,'globalVerifiedHashes':780,
          'catalogueFamilies':331,'localReportLinksChecked':links,'temporaryFilesDeleted':count,
          'temporaryBytesDeleted':removed,'n15ResearchClosed':True,'allFiveOriginalProgrammesExecutable':False,
          'releaseApproved':False,'appImplemented':False}
(BASE/'verificacoes.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if generated_report_link:
    check('Report generated verification target exists', (BASE/'verificacoes.json').is_file())
    output['passed'] = len(checks)
    output['localReportLinksChecked'] += 1
    (BASE/'verificacoes.json').write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in output.items() if k!='checks'},ensure_ascii=False))
