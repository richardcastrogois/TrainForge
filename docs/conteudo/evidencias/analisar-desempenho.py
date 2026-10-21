"""Confere corpos, proveniencia e limites da pesquisa N12, sem rede."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n12-desempenho'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


def verify(record_path):
    record = load(record_path)
    body = (record_path.parent / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    payload = body.read_bytes()
    assert len(payload) == record['bytes'], record_path
    assert hashlib.sha256(payload).hexdigest() == record['sha256'], record_path
    return record, payload.decode('utf-8')


content = load(FOLDER / 'conteudo-guiado.json')
summary = load(FOLDER / 'resumo-desempenho.json')
plan = load(FOLDER / 'requisicoes.json')
records = {}
for item in plan['requests']:
    record, body = verify(FOLDER / (item['id'] + '.evidencia.json'))
    assert record['url'] == item['url']
    records[item['id']] = (record, body)

assert len(records) == summary['calls'] == summary['bodyHashes'] == 4
assert sum(r['status'] == 200 for r, _ in records.values()) == summary['http200'] == 2
assert sum(r['status'] == 403 for r, _ in records.values()) == summary['http403'] == 2
for guide in content['guides']:
    record, body = records[Path(guide['evidence']).stem.replace('.evidencia', '')]
    assert record['url'] == guide['sourceUrl']
    if 'sha256' in guide:
        assert record['status'] == 200 and guide['sha256'] == record['sha256']
    else:
        assert guide['transportStatus'] == 403 and guide['webReadAt']
    assert guide['releaseApproved'] is False

article = records['n12-issn-protein'][1]
assert 'Creative Commons Attribution 4.0' in article
assert '1.4' in article and '2.0' in article
assert content['guides'][0]['sourceRange']['individualTarget'] is False
assert 'A.D.A.M.' in records['n12-medline-athletic'][1]
rights_path = FOLDER / content['rights'][2]['reusedEvidence']
rights_record, rights_body = verify(rights_path)
assert rights_record['url'] == content['rights'][2]['url']
assert 'copyright' in rights_body.lower() and 'A.D.A.M.' in rights_body
assert len(content['guides']) == summary['guidesReviewed'] == 3
assert len(content['lessons']) == summary['lessonDrafts'] == 3
assert all(x['releaseApproved'] is False for x in content['lessons'])
print(json.dumps(summary, ensure_ascii=False))
