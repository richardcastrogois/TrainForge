"""Valida proveniencia e consistencia documental dos complementos; sem rede ou app."""
import argparse
import hashlib
from html.parser import HTMLParser
from io import BytesIO
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.ignore_depth = 0
    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.ignore_depth += 1
    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.ignore_depth = max(0, self.ignore_depth - 1)
    def handle_data(self, text):
        if not self.ignore_depth:
            self.parts.append(text)

def local(relative):
    path = (ROOT / relative).resolve()
    path.relative_to(ROOT)
    assert path.is_file(), relative
    return path

def evidence_text(payload, content_type, text_encoding='utf-8'):
    # Public file hosts may deliver verified PDF bodies as octet-stream.
    if payload.startswith(b'%PDF-') or 'pdf' in content_type:
        from pypdf import PdfReader
        return ' '.join(p.extract_text() or '' for p in PdfReader(BytesIO(payload)).pages)
    parser = Text()
    parser.feed(payload.decode(text_encoding))
    return ' '.join(parser.parts)

def validate(relative):
    path = local(relative)
    spec = json.loads(path.read_text(encoding='utf-8'))
    assert spec['status'] in ('concluido_para_pesquisa', 'parcial')
    assert not spec['releaseApproved'] and not spec['appImplemented']
    evidence = []
    for item in spec['evidence']:
        record_path = local(item['record'])
        record = json.loads(record_path.read_text(encoding='utf-8'))
        body = (record_path.parent / record['bodyFile']).resolve()
        body.relative_to(ROOT)
        payload = body.read_bytes()
        assert record['status'] == 200 and len(payload) == record['bytes']
        assert hashlib.sha256(payload).hexdigest() == record['sha256']
        if item.get('anchors'):
            text = evidence_text(payload, record.get('contentType', ''), item.get('textEncoding', 'utf-8'))
            text = ' '.join(text.split()).casefold()
            for anchor in item['anchors']:
                assert anchor.casefold() in text, (item['record'], anchor)
        evidence.append({'record': item['record'], 'url': record['url'], 'sha256': record['sha256']})
    dependencies = []
    for ref in spec.get('dependencies', []):
        dep = local(ref)
        payload = dep.read_bytes()
        json.loads(payload)
        dependencies.append({'file': ref, 'artifactSha256': hashlib.sha256(payload).hexdigest()})
    for key in ('operations', 'scenarios', 'programmes', 'criteria'):
        rows = spec.get(key, [])
        ids = [row['id'] for row in rows]
        assert len(ids) == len(set(ids)), key
    assert all(row['fictional'] for row in spec.get('scenarios', []))
    summary = {'niche': spec['niche'], 'date': spec['date'], 'status': spec['status'],
               'researchRoundComplete': True, 'verifiedEvidenceBodies': len(evidence),
               'verifiedDependencies': len(dependencies), 'proposedOperations': len(spec.get('operations', [])),
               'fictionalScenarios': len(spec.get('scenarios', [])), 'releaseApproved': False,
               'appImplemented': False, 'appTestsRun': False, 'legalOrClinicalValidationPerformed': False,
               'sourceEvidence': evidence, 'dependencyEvidence': dependencies, 'next': spec['next']}
    (path.parent / 'resumo-complemento.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in summary.items() if k not in ('sourceEvidence', 'dependencyEvidence')}, ensure_ascii=False))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('spec')
    validate(parser.parse_args().spec)
