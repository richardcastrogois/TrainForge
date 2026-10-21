"""Verify breathing/counselling originals offline without creating an APK routine."""
import hashlib
import json
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-respiracao-oncologia'


class Text(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.ignored = 0

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.ignored += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style'):
            self.ignored = max(0, self.ignored - 1)

    def handle_data(self, text):
        if not self.ignored:
            self.parts.append(text)


def analyse(write=True):
    rows = []
    for record_path in sorted(FOLDER.glob('*.evidencia.json')):
        receipt = json.loads(record_path.read_text(encoding='utf-8'))
        source = (FOLDER / receipt['bodyFile']).resolve()
        if not source.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = source.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Original integrity mismatch')
        parser = Text()
        # JCDR declares legacy Latin-1 HTML; browsers interpret its smart quotes as Windows-1252.
        parser.feed(body.decode('cp1252'))
        text = ' '.join(' '.join(parser.parts).split())
        expected = ('diaphragmatic', 'pursed lip', '25 minutes', '77 participants') if 'oncologia' in receipt['id'] else ('NonCommercial', 'NoDerivatives')
        if receipt['status'] != 200 or receipt.get('error') or any(word.casefold() not in text.casefold() for word in expected):
            raise ValueError('Not the expected original')
        rows.append({**{key: receipt[key] for key in ('id', 'url', 'status', 'bytes', 'sha256')},
                     'record': record_path.relative_to(ROOT).as_posix(),
                     'verifiedAnchors': list(expected), 'textEncoding': 'cp1252', 'usableForReading': True})
    result = {'niche': 'N15-C', 'date': '2026-10-11', 'collectorCalls': len(rows),
              'usableBodies': len(rows), 'receipts': rows, 'networkCallsDuringAnalysis': 0,
              'pdfReceived': False, 'researchClosureApproved': False,
              'releaseApproved': False, 'appImplemented': False}
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    print(json.dumps(analyse()))
