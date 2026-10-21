"""Audita originais adicionais N15-C sem rede, prescricao ou importacao."""
import argparse
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('n15_previous', ROOT / 'analisar-n15c-teses-seguimento.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
ROUNDS = ['n15c-moreira-cuidadores', 'n15c-kirtan-original']
PDF_CHECKS = {
    'c15-moreira-granada-pdf': (134, {
        1: ['Karen', '2018'],
        54: ['cuatro meses', 'no ser remunerado'],
        57: ['tres fisioterapeutas', '60', '12 semanas'],
        63: ['45 minutos', 'Grupo de'],
        67: ['33 cuidadores', '54.64'],
        76: ['Regi', '0.101'],
        79: ['PSS', '0.128'],
        88: ['no se observaron diferencias'],
        128: ['CONSENTIMIENTO'],
        130: ['CORLETT'],
        131: ['INSPECCI'],
        134: ['Dispositivos de seguridad'],
    }),
    'c15-kirtan-arpf-instrucoes-pdf': (1, {
        1: ['all rights reserved', 'two minutes', 'four minutes', 'To end', 'index fingers'],
    }),
}
VISUAL_PAGES = {
    'c15-moreira-granada-pdf': [54, 57, 70, 79, 128, 129, 131],
    'c15-kirtan-arpf-instrucoes-pdf': [1],
}


class PlainHtml(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.links = []

    def handle_data(self, data):
        self.parts.append(data)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'a' and attrs.get('href'):
            self.links.append(attrs['href'])

    def text(self):
        return ' '.join(' '.join(self.parts).split())


def analyse(round_name, render=False):
    assert round_name in ROUNDS
    folder = ROOT / '2026-10-08' / round_name
    records = [previous.receipts.check_receipt(p, ROOT)
               for p in sorted(folder.glob('*.evidencia.json'))]
    result = {
        'date': '2026-10-08', 'niche': 'N15-C', 'networkPerformed': False,
        'collectorCalls': len(records),
        'usableBodies': sum(r['usable'] for r in records),
        'hashedBodies': sum(r['bodyVerified'] for r in records),
        'sources': records, 'pdfs': {}, 'anchorChecks': [],
        'publicLinks': {}, 'registry': {},
        'researchClosureApproved': False, 'releaseApproved': False,
    }
    for record in records:
        assert record['usable'], record['id']
        path = previous.body_for(record)
        if record['id'] in PDF_CHECKS:
            pdf = PdfReader(path)
            pages, checks = PDF_CHECKS[record['id']]
            assert len(pdf.pages) == pages
            texts = [p.extract_text() or '' for p in pdf.pages]
            for number, anchors in checks.items():
                text = ' '.join(texts[number - 1].split()).casefold()
                for anchor in anchors:
                    assert anchor.casefold() in text, (record['id'], number, anchor)
                    result['anchorChecks'].append({
                        'id': record['id'], 'pdfPageOneBased': number,
                        'anchor': anchor, 'matched': True,
                    })
            result['pdfs'][record['id']] = {
                'pages': pages, 'allPagesTextExtracted': True,
                'textPageLengths': [len(t) for t in texts],
                'renderedPages': [], 'wholePdfVisuallyReviewed': None,
                'visualInspectionNotDeterminedByScript': True,
            }
            if render:
                import pypdfium2 as pdfium
                with pdfium.PdfDocument(path) as doc:
                    for number in VISUAL_PAGES[record['id']]:
                        page = doc[number - 1]
                        try:
                            bitmap = page.render(scale=1.5)
                            try:
                                bitmap.to_pil().save(path.with_name(f'{record["id"]}-p{number}.png'))
                            finally:
                                bitmap.close()
                        finally:
                            page.close()
                result['pdfs'][record['id']]['renderedPages'] = VISUAL_PAGES[record['id']]
        elif path.suffix == '.html':
            parser = PlainHtml()
            parser.feed(path.read_text(encoding='utf-8'))
            result['publicLinks'][record['id']] = sorted(set(parser.links))
            anchors = {
                'c15-moreira-granada-handle': [
                    'NoComercial-SinDerivadas 3.0', '54876', '2018-07-20'],
                'c15-kirtan-lavretsky-html': [
                    '10.1002/gps.3790', 'Helen Lavretsky, MD, MS',
                    '11 minutes', '1 minute', '45 were randomized',
                    'one-sided p-values', 'psychoeducation'],
            }[record['id']]
            for anchor in anchors:
                assert anchor in parser.text(), (record['id'], anchor)
                result['anchorChecks'].append({'id': record['id'], 'anchor': anchor, 'matched': True})
        elif record['id'] == 'c15-kirtan-lavretsky-registro-json':
            data = json.loads(path.read_text(encoding='utf-8'))
            protocol = data['protocolSection']
            assert protocol['identificationModule']['nctId'] == 'NCT01537679'
            description = protocol['armsInterventionsModule']['interventions'][0]['description']
            assert 'Helen Lavretsky, M.D' in description
            assert '12 minutes' in description
            assert 'documentSection' not in data
            result['registry'] = {
                'nctId': 'NCT01537679', 'enrollment': protocol['designModule']['enrollmentInfo']['count'],
                'hasResults': data['hasResults'], 'documentSectionPresent': False,
                'teachingByNamedPhysicianConfirmed': True,
            }
    (folder / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args()
    for name in ROUNDS:
        result = analyse(name, args.render)
        print(json.dumps({k: result[k] for k in ['collectorCalls', 'usableBodies', 'hashedBodies']}))
