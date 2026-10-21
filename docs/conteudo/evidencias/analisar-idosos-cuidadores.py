"""Confere referencias da auditoria idosos/cuidadores; nao testa adequacao clinica ou app."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/revisao-idosos-cuidadores'
audit = json.loads((FOLDER / 'matriz-cobertura.json').read_text(encoding='utf-8'))
expected = ['N' + str(i).zfill(2) for i in range(1, 18)]
assert [row['niche'] for row in audit['niches']] == expected
snapshots = []
for row in audit['niches']:
    path = (ROOT / row['evidence']).resolve()
    path.relative_to(ROOT)
    payload = path.read_bytes()
    json.loads(payload)
    assert row['caregiverCoverage'] == 'nao_demonstrada' and not row['releaseApproved']
    snapshots.append({'niche': row['niche'], 'evidence': row['evidence'],
                      'artifactSha256': hashlib.sha256(payload).hexdigest()})

def read(path):
    record = json.loads(path.read_text(encoding='utf-8'))
    body = (path.parent / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    payload = body.read_bytes()
    assert record['status'] == 200 and len(payload) == record['bytes']
    assert hashlib.sha256(payload).hexdigest() == record['sha256']
    parser = HTMLParser()
    parts = []
    parser.handle_data = parts.append
    parser.feed(payload.decode('utf-8'))
    return record, ' '.join(' '.join(parts).split())

who, who_text = read(FOLDER / 'ic-who-later-adulthood.evidencia.json')
cdc, cdc_text = read(FOLDER / 'ic-cdc-caregivers.evidencia.json')
rights, _ = read(ROOT / '2026-09-30/n10-perda-peso/n10-cdc-direitos.evidencia.json')
assert '30 September 2022' in who_text
assert 'physical condition' in who_text
assert 'caregivers' in cdc_text.lower()
assert 'current physical ability' in cdc_text
assert 'healthcare provider' in cdc_text
n15 = json.loads((ROOT / '2026-10-03/n15-casa-sem-equipamento/amostra-programas.json').read_text(encoding='utf-8'))
assert n15['program']['journal'] == 'Healthcare (Basel)'
assert not n15['program']['caregiverWorkflowDemonstrated']
assert len(audit['subniches']) == 5
assert len({x['id'] for x in audit['subniches']}) == 5
assert all(s['fictional'] for s in audit['fictionalScenarios'])
substatuses = [s['status'] for s in audit['subniches']]
assert all(s in ('na_fila', 'parcial', 'concluido_para_pesquisa') for s in substatuses)
for sub in audit['subniches']:
    if sub.get('researchRoundComplete'):
        spec = json.loads((ROOT / sub['evidence']).read_text(encoding='utf-8'))
        assert spec['niche'] == sub['id'] and spec['status'] == sub['status']
        assert not spec['releaseApproved'] and not spec['appImplemented']
summary = {'scope': audit['scope'], 'date': audit['date'], 'auditCompleted': True,
           'nichesReviewed': 17, 'olderSpecificPartialEvidence': ['N15', 'N16'],
           'caregiverProgrammeDemonstrated': False, 'newCalls': 2, 'http200': 2, 'bodyHashes': 2,
           'reusedPolicyRecords': 1, 'subnichesQueued': substatuses.count('na_fila'),
           'subnichesPartial': substatuses.count('parcial'),
           'subnichesResearchClosed': substatuses.count('concluido_para_pesquisa'),
           'fictionalScenarios': 7,
           'appTestsRun': False, 'clinicalValidationPerformed': False, 'releaseApproved': False,
           'evidenceSnapshots': snapshots, 'next': audit['next']}
(FOLDER / 'resumo-revisao.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k != 'evidenceSnapshots'}, ensure_ascii=False))
