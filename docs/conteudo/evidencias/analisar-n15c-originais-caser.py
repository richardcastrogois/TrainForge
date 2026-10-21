"""Verifica originais N15-C de 08/10 sem rede, montagem ou liberacao de treino."""
import argparse
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-08/n15c-originais-caser'
spec = importlib.util.spec_from_file_location('n15_inventory', ROOT / 'analisar-n15c-teses-seguimento.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
PDF_CHECKS = {
    'c15-caser2018-pdf': (24, {
        1: ['Doctor en Fisioterapia', 'Fisioterapeuta'],
        5: ['68 mujeres', 'Microsoft Excel'],
        6: ['36 sesiones', 'graduados en fisioterapia', '>18'],
        7: ['MODELO DE SESI', '10 - 15', '35 - 40'],
        8: ['62 cuidadoras', '30 GC', '32 GI'],
        9: ['47', '76', '72,58%'],
        10: ['1,52', '1,37'],
    }),
    'c15-usc-cuidate-capitulo-pdf': (38, {
        1: ['Attribution 4.0', '10.35985/9789585147164.3'],
        13: ['cualitativo', 'descriptivo', '60 personas', '24 y 84'],
        14: ['respiración y relajación'],
        24: ['relajación y respiración'],
        29: ['decálogo'],
    }),
}
VISUAL_PAGES = {
    'c15-caser2018-pdf': [1, 6, 7, 10],
    'c15-usc-cuidate-capitulo-pdf': [1, 13, 24],
}


def analyse(render=False):
    records = [previous.receipts.check_receipt(p, ROOT)
               for p in sorted(ROUND.glob('*.evidencia.json'))]
    result = {
        'date': '2026-10-08', 'niche': 'N15-C', 'networkPerformed': False,
        'newCollectorCalls': len(records),
        'http200Responses': sum(r['status'] == 200 for r in records),
        'usableBodies': sum(r['usable'] for r in records),
        'hashedBodies': sum(r['bodyVerified'] for r in records),
        'sources': records, 'pdfs': {}, 'anchorChecks': [], 'publicLinks': {},
        'fastMetadataChecks': {},
        'dbeMetadataChecks': {},
        'researchClosureApproved': False, 'releaseApproved': False,
    }
    for item in records:
        if not item['usable']:
            continue
        path = previous.body_for(item)
        if item['id'] in PDF_CHECKS:
            pdf = PdfReader(path)
            pages, checks = PDF_CHECKS[item['id']]
            assert len(pdf.pages) == pages, 'Unexpected PDF version'
            texts = [p.extract_text() or '' for p in pdf.pages]
            for page, anchors in checks.items():
                text = ' '.join(texts[page - 1].split()).casefold()
                for anchor in anchors:
                    assert anchor.casefold() in text, (item['id'], page, anchor)
                    result['anchorChecks'].append({
                        'id': item['id'], 'pdfPageOneBased': page,
                        'anchor': anchor, 'matched': True,
                    })
            result['pdfs'][item['id']] = {
                'pages': pages, 'allPagesTextExtracted': True,
                'textPageLengths': [len(t) for t in texts],
                'renderedPages': [], 'wholePdfVisuallyReviewed': False,
            }
            if render:
                import pypdfium2 as pdfium
                with pdfium.PdfDocument(path) as doc:
                    for number in VISUAL_PAGES[item['id']]:
                        page = doc[number - 1]
                        try:
                            bitmap = page.render(scale=1.5)
                            try:
                                bitmap.to_pil().save(path.with_name(f'{item["id"]}-p{number}.png'))
                            finally:
                                bitmap.close()
                        finally:
                            page.close()
                result['pdfs'][item['id']]['renderedPages'] = VISUAL_PAGES[item['id']]
        elif path.suffix == '.html':
            parser = previous.PublicHtml()
            html = path.read_text(encoding='utf-8')
            parser.feed(html)
            result['publicLinks'][item['id']] = sorted(set(parser.links))
            if item['id'] == 'c15-caser2018-pagina':
                assert '/sites/default/files/adjuntos/2206.pdf' in parser.links
            if item['id'] == 'c15-fast-caplin-2021-html':
                for anchor in ['NCT01993082', 'heart rate reserve', 'Society for Affective Science']:
                    assert anchor in html, anchor
                    result['anchorChecks'].append({'id': item['id'], 'anchor': anchor, 'matched': True})
        elif item['id'] == 'c15-revieew-registro-json':
            data = json.loads(path.read_text(encoding='utf-8'))
            assert data['protocolSection']['identificationModule']['nctId'] == 'NCT05050526'
            assert 'documentSection' not in data
            result['revieewRegistryHasPostedManual'] = False
        elif path.suffix == '.json' and item['id'].startswith('c15-dbe2026-'):
            data = json.loads(path.read_text(encoding='utf-8'))
            if item['id'] == 'c15-dbe2026-resumo-json':
                article = data['resultList']['result'][0]
                assert article['id'] == '41704158'
                assert article['doi'] == '10.1080/01942638.2026.2628830'
                result['dbeMetadataChecks']['abstract'] = {
                    'isOpenAccess': article['isOpenAccess'],
                    'fullTextReceived': False,
                }
            else:
                assert data['protocolSection']['identificationModule']['nctId'] == 'NCT06970769'
                arms = data['protocolSection']['armsInterventionsModule']['interventions']
                breathing = next(a for a in arms if a['name'] == 'Deep Breathing Exercises')
                assert 'semi-sitting' in breathing['description']
                result['dbeMetadataChecks']['registry'] = {
                    'documentSectionPresent': 'documentSection' in data,
                    'hasResults': data.get('hasResults'),
                    'breathingDescriptionPresent': True,
                }
        elif path.suffix == '.json' and item['id'].startswith('c15-fast-'):
            data = json.loads(path.read_text(encoding='utf-8'))
            if item['id'] == 'c15-fast-registro-json':
                assert data['protocolSection']['identificationModule']['nctId'] == 'NCT01993082'
                result['fastMetadataChecks']['registry'] = {
                    'documentSectionPresent': 'documentSection' in data,
                    'hasResults': data.get('hasResults'),
                }
            elif item['id'] == 'c15-fast-osf-projeto-json':
                assert data['data']['id'] == 'gc9qa'
                result['fastMetadataChecks']['osfLicense'] = data['data']['attributes']['node_license']
            else:
                rows = data['data']
                assert data['links']['next'] is None, 'Incomplete OSF listing'
                result['fastMetadataChecks'][item['id']] = {
                    'count': len(rows),
                    'names': [r['attributes'].get('name', r['attributes'].get('title')) for r in rows],
                    'paginationComplete': True,
                }
    (ROUND / 'inventario.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: result[k] for k in
        ['newCollectorCalls', 'http200Responses', 'usableBodies', 'hashedBodies']}))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
