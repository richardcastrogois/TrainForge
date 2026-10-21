"""Project the published gym table without filling missing dose cells."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-04/n18i-academia'
FIELDS = ('weeks', 'goal', 'session', 'movement', 'sets', 'reps',
          'percent1RM', 'tempo', 'interSetRest')


class Table(HTMLParser):
    def __init__(self):
        super().__init__()
        self.depth = 0
        self.done = False
        self.rows = []
        self.cells = []
        self.parts = None

    def handle_starttag(self, tag, attrs):
        if tag == 'table' and not self.done:
            self.depth += 1
        if self.depth and tag == 'tr':
            self.cells = []
        if self.depth and tag in ('td', 'th'):
            self.parts = []

    def handle_data(self, data):
        if self.parts is not None:
            self.parts.append(data)

    def handle_endtag(self, tag):
        if self.depth and tag in ('td', 'th'):
            self.cells.append(' '.join(' '.join(self.parts or []).split()) or None)
            self.parts = None
        if self.depth and tag == 'tr':
            self.rows.append(self.cells)
        if tag == 'table' and self.depth:
            self.depth -= 1
            self.done = not self.depth


def project(html):
    parser = Table()
    parser.feed(html)
    rows = []
    weeks = goal = session = None
    for cells in parser.rows[1:]:
        if not any(cells):
            continue
        if len(cells) != 9:
            raise ValueError('Unexpected column count')
        raw = dict(zip(FIELDS, cells))
        if raw['weeks']:
            weeks, goal, session = raw['weeks'], raw['goal'], None
        if raw['session']:
            session = raw['session']
        if not weeks or not goal or not session or not raw['movement']:
            raise ValueError('Missing table group or movement')
        rows.append({'id': f'I18-W{len(rows)+1:03}', 'sourceCells': raw,
                     'editorialGroupContext': {'weeks': weeks, 'goal': goal, 'session': session}})
    return rows


def main():
    record = json.loads((ROUND / 'i18-walker-forca.evidencia.json').read_text(encoding='utf-8'))
    body = ROUND / record['bodyFile']
    payload = body.read_bytes()
    if record['status'] != 200 or len(payload) != record['bytes'] or hashlib.sha256(payload).hexdigest() != record['sha256']:
        raise ValueError('Invalid source provenance')
    rows = project(payload.decode('utf-8'))
    groups = {(r['editorialGroupContext']['weeks'], r['editorialGroupContext']['session']) for r in rows}
    result = {'date': '2026-10-04', 'sourceId': 'PR25', 'doi': '10.3389/fphys.2018.01933',
              'sourceSha256': record['sha256'], 'programmeWeeks': 14, 'tablePhaseCount': 6,
              'sessionTemplateCount': len(groups), 'movementRowCount': len(rows),
              'uniqueMovementCount': len({r['sourceCells']['movement'] for r in rows}),
              'policy': 'Group context identifies the printed phase/session; blank dose cells stay null. No load conversion, new programme, clinical approval or media permission inferred.',
              'rows': rows, 'releaseApproved': False, 'appImplemented': False}
    (ROUND / 'amostra-walker-tabela.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='rows'}, ensure_ascii=False))


if __name__ == '__main__':
    main()
