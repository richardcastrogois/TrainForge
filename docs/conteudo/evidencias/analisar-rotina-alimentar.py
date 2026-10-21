"""Valida proveniencia, dependencias e delimitacao documental da N14."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n14-rotina-alimentar'
content = json.loads((FOLDER / 'rotina-proposta.json').read_text(encoding='utf-8'))
record = json.loads((FOLDER / content['source']['evidence']).read_text(encoding='utf-8'))
body = (FOLDER / record['bodyFile']).resolve()
body.relative_to(ROOT)
payload = body.read_bytes()
assert record['status'] == 200
assert record['url'] == content['source']['url']
assert len(payload) == record['bytes']
assert hashlib.sha256(payload).hexdigest() == record['sha256'] == content['source']['sha256']
assert 'Meal Planning' in payload.decode('utf-8')
for dependency in content['dependencies']:
    path = (FOLDER / dependency['evidence']).resolve()
    path.relative_to(ROOT)
    json.loads(path.read_text(encoding='utf-8'))
assert len(content['operations']) == 7
assert len({x['id'] for x in content['operations']}) == 7
assert len(content['scenarios']) == 6
assert all(x['fictional'] is True for x in content['scenarios'])
assert content['releaseApproved'] is False
summary = {'niche': 'N14', 'date': '2026-10-03', 'status': 'concluido_para_pesquisa',
           'calls': 1, 'http200': 1, 'bodyHashes': 1, 'dependencies': 6,
           'proposedOperations': 7, 'documentedFictionalScenarios': 6,
           'appImplemented': False, 'appTestsRun': False, 'releaseApproved': False,
           'next': 'N15 — programas em casa sem equipamento'}
(FOLDER / 'resumo-rotina.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
