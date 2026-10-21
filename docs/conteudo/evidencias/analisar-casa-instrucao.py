"""Extrai identificadores e revisoes NHS; nao baixa nem homologa videos."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n17-casa-instrucao'

def read(path):
    record = json.loads(path.read_text(encoding='utf-8'))
    body = (path.parent / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    payload = body.read_bytes()
    assert record['status'] == 200 and len(payload) == record['bytes']
    assert hashlib.sha256(payload).hexdigest() == record['sha256']
    return record, payload.decode('utf-8')

class Media(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.heading = None
        self.current = None
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'h2':
            self.heading = []
        elif tag == 'video' and self.current:
            self.current['videoId'] = attrs['data-video-id']
            self.current['account'] = attrs['data-account']
            self.current['player'] = attrs['data-player']
    def handle_data(self, text):
        if self.heading is not None:
            self.heading.append(text)
        if self.current:
            self.current['text'].append(text)
    def handle_endtag(self, tag):
        if tag == 'h2' and self.heading is not None:
            title = ' '.join(''.join(self.heading).split())
            self.heading = None
            self.current = None
            if title.startswith('Video: NHS Strength and flexibility - '):
                self.current = {'title': title, 'text': []}
                self.parts.append(self.current)

record, html = read(FOLDER / 'n17-nhs-videos.evidencia.json')
rights_record, rights = read(ROOT / '2026-09-29/n08-receitas/n08-nhs-termos.evidencia.json')
assert 'identifiable people' in rights and 'videos and audio' in rights
parser = Media()
parser.feed(html)
expected = ['warm-up', 'posture', 'standing press-up', 'thigh stretch', 'squat', 'calf stretch',
            'chest stretch', 'upper back stretch', 'tricep stretch', 'sit to stand', 'wide squat',
            'pull-up', 'bench dip', 'wide pull-up', 'sit to stand with calf raise']
assert len(parser.parts) == 15
assets = []
for index, (part, name) in enumerate(zip(parser.parts, expected), start=1):
    assert part['title'].endswith(' - ' + name)
    text = ' '.join(part['text'])
    last = re.search(r'Media last reviewed:\s*(3 (?:April|May) 2025)', text)
    due = re.search(r'Media review due:\s*(3 (?:April|May) 2028)', text)
    assert last and due
    assets.append({'id': 'N17-' + str(index).zfill(2), 'sourceId': 'MI02', 'sourceMovement': name,
                   'sourcePageUrl': record['url'], 'provider': 'Brightcove',
                   'videoId': part['videoId'], 'accountId': part['account'], 'playerId': part['player'],
                   'reviewedDateText': last.group(1), 'reviewDueText': due.group(1),
                   'downloaded': False, 'playbackVerified': False, 'durationSeconds': None,
                   'licensePerAssetDemonstrated': False, 'releaseApproved': False,
                   'matchesN15N16ProgramAutomatically': False})
assert len({a['videoId'] for a in assets}) == 15
assert '19 August 2026' in html
data = {'niche': 'N17', 'date': '2026-10-03', 'status': 'parcial', 'researchRoundComplete': True,
        'sourceSha256': record['sha256'], 'rightsSha256': rights_record['sha256'], 'assets': assets,
        'textInstructionReuse': 'texto elegivel sujeito a OGL/termos; traducao exige revisao propria',
        'mediaReuse': 'pessoas identificaveis e terceiros excluidos da licenca geral; permissao especifica nao obtida',
        'audience': 'exercicios gerais para boa saude/condicionamento razoavel; nao tratamentos clinicos',
        'mappingPolicy': 'Nomes sugerem candidatos; confirmar gesto, variante, dose e aparelho antes de ligar programas',
        'localizationLimit': 'Nao copiar servicos/numeros britanicos para Portugal; educacao local N32/N45',
        'otherVisualEvidence': 'figuras Tufts/CDC inspecionadas N16, com direitos de terceiros/sem alteracoes',
        'releaseApproved': False}
summary = {'niche': 'N17', 'date': '2026-10-03', 'status': 'parcial', 'researchRoundComplete': True,
           'calls': 1, 'http200': 1, 'bodyHashes': 1, 'videoMetadataRecords': 15,
           'distinctVideoIds': 15, 'playbackVerified': 0, 'mediaApproved': 0, 'next': 'N18 - academia iniciante'}
for name, value in [('amostra-midia.json', data), ('resumo-instrucao.json', summary)]:
    (FOLDER / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
