"""Confere os retornos N15-C de 06/10, sem rede ou montagem de treino."""
import argparse
import hashlib
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-06/n15c-fechamento'
PDF_CHECKS = {
    'c15-cbt-livro': (366, {
        5: ['excluding the cover', 'third party material', 'CC BY-NC-ND'],
        12: ['only by appropriately qualified'],
        187: ['9 group sessions'],
        198: ['20 minutes', '2-3 times per week'],
        199: ['recording', 'at home'],
        359: ['Tausch, 1993'],
        360: ['demonstrate each muscle'],
        362: ['1-3 minutes'],
    }),
    'c15-va-workbook-modulo1': (54, {
        1: ['Family Caregiver'],
        9: ['20 minutes a day', '30 minutes'],
        21: ['independently or in combination'],
        23: ['10 seconds', 'Muscle Relaxation'],
    }),
    'c15-pmr-indonesia-pdf': (9, {
        1: ['Ramadia', '40'],
        4: ['5 detik', '15 detik', '14'],
        5: ['3-6', '09.00-11.00'],
        9: ['Tobing', 'modul relaksasi otot progresif'],
    }),
}
VISUAL_PAGES = {
    'c15-cbt-livro': [5, 12, 187, 198, 199, 348, 349, 359, 360, 361, 362, 363],
    'c15-va-workbook-modulo1': [1, 9, 21, 22, 23],
    'c15-pmr-indonesia-pdf': [1, 4, 5, 6, 7],
}


def check_receipt(path, root=ROOT):
    record = json.loads(path.read_text(encoding='utf-8'))
    item = {key: record.get(key) for key in
            ('id', 'url', 'resolvedUrl', 'collectedAtUtc', 'status', 'error', 'bytes', 'sha256')}
    item['record'] = path.relative_to(root).as_posix()
    item['bodyVerified'] = False
    if record.get('bodyFile'):
        body = (path.parent / record['bodyFile']).resolve()
        body.relative_to(root.resolve())
        with body.open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        if digest != record.get('sha256') or body.stat().st_size != record.get('bytes'):
            raise ValueError('Body hash/size mismatch')
        item['bodyVerified'] = True
    item['usable'] = (record.get('status') == 200 and not record.get('error')
                      and item['bodyVerified'])
    return item


def analyse(render=False):
    entries = []
    checks = []
    for path in sorted(ROUND.glob('*.evidencia.json')):
        item = check_receipt(path)
        record = json.loads(path.read_text(encoding='utf-8'))
        if item['usable'] and item['id'] in PDF_CHECKS:
            body = (path.parent / record['bodyFile']).resolve()
            pdf = PdfReader(body)
            count, pages = PDF_CHECKS[item['id']]
            if len(pdf.pages) != count:
                raise ValueError('Unexpected PDF version/page count')
            item['pdfPages'] = count
            item['anchorCheckedPdfPages'] = list(pages)
            for number, anchors in pages.items():
                text = ' '.join((pdf.pages[number-1].extract_text() or '').split()).casefold()
                for anchor in anchors:
                    if anchor.casefold() not in text:
                        raise ValueError(f'Missing anchor: {item["id"]} p{number} {anchor}')
                    checks.append({'record': item['record'], 'pdfPageOneBased': number,
                                   'anchor': anchor, 'matched': True})
            if render:
                import pypdfium2 as pdfium
                doc = pdfium.PdfDocument(body)
                try:
                    for number in VISUAL_PAGES[item['id']]:
                        page = doc[number-1]
                        bitmap = page.render(scale=1.5)
                        try:
                            bitmap.to_pil().save(body.with_name(f'{item["id"]}-p{number}.png'))
                        finally:
                            bitmap.close()
                            page.close()
                finally:
                    doc.close()
        entries.append(item)
    summary = {
        'date': '2026-10-06', 'scope': ['N15-C'], 'networkPerformedByThisScript': False,
        'collectorCalls': len(entries),
        'usableBodies': sum(e['usable'] for e in entries),
        'verifiedBodiesIncludingErrors': sum(e['bodyVerified'] for e in entries),
        'entries': entries,
        'limits': 'Hash e ancora nao validam clinica/direitos nem convertem artigo em programa.',
    }
    (ROUND / 'inventario.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    (ROUND / 'verificacoes.json').write_text(json.dumps({
        'checks': checks, 'renderedPages': VISUAL_PAGES if render else {},
        'visualInspectionConfirmedByScript': False,
        'researchClosureApproved': False, 'releaseApproved': False, 'appImplemented': False,
    }, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in summary.items() if k != 'entries'}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
