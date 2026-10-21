"""Inspect only CG-01 sources offline; auxiliary guidance never replaces the trial."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-12/cg01-estatico'


class TextReader(HTMLParser):
    def __init__(self):
        super().__init__()
        self.skip = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in ('script', 'style'):
            self.skip += 1

    def handle_endtag(self, tag):
        if tag in ('script', 'style') and self.skip:
            self.skip -= 1

    def handle_data(self, text):
        if not self.skip and text.strip():
            self.parts.append(' '.join(text.split()))


def analyse(render=False, write=True):
    rows = []
    for record in sorted(FOLDER.glob('*.evidencia.json')):
        receipt = json.loads(record.read_text(encoding='utf-8'))
        row = {key:receipt.get(key) for key in ('id', 'url', 'resolvedUrl', 'collectedAtUtc', 'status', 'bytes', 'sha256', 'error')}
        row['record'] = record.relative_to(ROOT).as_posix()
        row['usableForReading'] = receipt.get('status') == 200 and not receipt.get('error') and bool(receipt.get('bytes'))
        if receipt.get('bodyFile'):
            path = (FOLDER / receipt['bodyFile']).resolve()
            if not path.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Integrity mismatch')
            if row['usableForReading'] and row['id'].endswith('pdf'):
                from pypdf import PdfReader
                if not body.startswith(b'%PDF-'):
                    raise ValueError('Not a PDF body')
                reader = PdfReader(path)
                row.update(pdfPages=len(reader.pages), pdfText=[page.extract_text() for page in reader.pages],
                           selectedRenderPages=[1,2,9,11,12], renderedThisRun=render, renderIsVisualReview=False)
                if render:
                    import pypdfium2 as pdfium
                    target = FOLDER / 'raw-render'
                    target.mkdir(exist_ok=True)
                    document = pdfium.PdfDocument(path)
                    for number in row['selectedRenderPages']:
                        page = document[number-1]
                        bitmap = page.render(scale=1.5)
                        bitmap.to_pil().save(target / ('worcs-page-'+str(number)+'.png'))
                        bitmap.close()
                        page.close()
                    document.close()
            elif row['usableForReading'] and row['id'].endswith('html'):
                parser = TextReader()
                parser.feed(body.decode('utf-8'))
                row['textEncoding'] = 'utf-8'
                row['htmlText'] = '\n'.join(parser.parts)
                row['htmlTextIsFullInstructionOrLicenseApproval'] = False
        rows.append(row)
    result = {'date':'2026-10-12', 'activeComponent':'CG-01-STATIC', 'targetSourceId':'PR42',
              'collectorCalls':len(rows), 'usableBodies':sum(r['usableForReading'] for r in rows),
              'receipts':rows, 'networkCallsDuringAnalysis':0,
              'auxiliaryGuidesAreAtacProtocol':False, 'doseChanged':False,
              'mechanicalAnalysisApprovesClosure':False, 'releaseApproved':False,
              'closureDecisionFile':'pacote-factual.json'}
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    result = analyse(render=parser.parse_args().render)
    print(json.dumps({key:value for key,value in result.items() if key != 'receipts'}))
