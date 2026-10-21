"""Valida a evidencia local do N11 sem rede."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
FOLDER = ROOT / 'docs/conteudo/evidencias/2026-10-02/n11-manutencao-habitos'
RAW = FOLDER.parent / 'raw'


def load_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def check_evidence(name):
    record = load_json(FOLDER / name)
    assert record['status'] == 200, name
    body = RAW / Path(record['bodyFile']).name
    assert body.exists(), str(body)
    assert hashlib.sha256(body.read_bytes()).hexdigest() == record['sha256'], name
    return record


evidence_files = [
    'n11-niddk-maintain.evidencia.json',
    'n11-niddk-adults.evidencia.json',
    'n11-cdc-healthy-eating.evidencia.json',
    'n11-dgs-10-passos.evidencia.json',
    'n11-niddk-copyright.evidencia.json',
    'n11-cdc-rights.evidencia.json',
]
records = [check_evidence(name) for name in evidence_files]
content = load_json(FOLDER / 'conteudo-guiado.json')
summary = load_json(FOLDER / 'resumo-manutencao-habitos.json')

assert content['status'] == 'concluido_para_pesquisa'
assert summary['status'] == 'concluido_para_pesquisa'
assert len(content['guides']) == summary['sourceCount'] == 4
assert len(content['rightsRecords']) == summary['rightsRecordCount'] == 2
assert len(content['lessons']) == summary['lessonDrafts'] == 6
assert len(records) == summary['calls'] == summary['http200'] == summary['bodyHashes'] == 6
assert all(item['releaseApproved'] is False for item in content['guides'])
assert all(item['releaseApproved'] is False for item in content['lessons'])

print(json.dumps({
    'niche': 'N11',
    'guides': len(content['guides']),
    'rightsRecords': len(content['rightsRecords']),
    'lessons': len(content['lessons']),
    'http200': len(records),
    'bodyHashes': len(records),
    'releaseApproved': False
}, ensure_ascii=False))
