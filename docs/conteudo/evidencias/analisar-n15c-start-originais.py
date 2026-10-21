"""Audit START originals offline; raster manual pages are not extracted instructions."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-start-originais'
REPORT = 'c15-start2014-nihr-relatorio-pdf'
TARGETS = [5, 37, 38, 39, 41, 57, 65, 101, 102, 103,
           119, 120, 121, 122, 138, 139, 140, 141,
           155, 156, 157, 158, 159, *range(175,182), *range(196,202),
           *range(222,228), 243, 244, 245, 246, 247, 248, 249, 250, *range(262,271)]


def analyse(render=False):
    rows, pdfs, paths, articles = [], {}, {}, {}
    for filename in ['requisicoes.json', 'requisicoes-nihr.json']:
        plan = json.loads((FOLDER / filename).read_text(encoding='utf-8'))
        for request in plan['requests']:
            receipt_path = FOLDER / (request['id'] + '.evidencia.json')
            receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
            if receipt['url'] != request['url']:
                raise ValueError('Manifest/receipt URL mismatch')
            path = (FOLDER / receipt['bodyFile']).resolve()
            if not path.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Body integrity mismatch')
            usable = receipt['status'] == 200 and not receipt.get('error')
            role = 'original'
            if not usable:
                role = 'http_error_not_article_or_manual'
            elif request['extension'] == 'html':
                if b'recaptcha' not in body.lower() and b'Checking your browser' not in body:
                    raise ValueError('Expected retained challenge response')
                usable, role = False, 'browser_challenge_not_rights_page'
            elif request['extension'] == 'xml':
                article = ET.fromstring(body)
                ids = {element.attrib.get('pub-id-type'): element.text for element in article.findall('.//article-id')}
                if ids.get('doi') != '10.1136/bmj.f6276':
                    raise ValueError('START result DOI mismatch')
                articles[request['id']] = article
            elif request['extension'] == 'pdf':
                if not body.startswith(b'%PDF-'):
                    raise ValueError('Expected PDF')
                reader = PdfReader(path)
                pdfs[request['id']] = reader
                paths[request['id']] = path
            rows.append({'id': request['id'], 'record': receipt_path.relative_to(ROOT).as_posix(),
                         'url': receipt['url'], 'status': receipt['status'], 'bytes': len(body),
                         'sha256': receipt['sha256'], 'usableForReading': usable, 'role': role})
    report = pdfs[REPORT]
    if len(report.pages) != 272 or len(pdfs['c15-start2014-nihr-resumo-pdf'].pages) != 10:
        raise ValueError('Original publication length mismatch')
    anchors = {13: ['Appendix 3', 'The START manual', '73'],
               37: ['Dolores Gallagher-Thompson', 'permission', 'eight'],
               38: ['preferred location', 'compact disc', 'stretching'],
               39: ['psychology graduates', 'clinical psychologist', '1.5 hours'],
               41: ['Ensuring safe practice', 'risk'],
               57: ['1.80', '3.29', '0.02']}
    for number, terms in anchors.items():
        text = ' '.join((report.pages[number - 1].extract_text() or '').split())
        if not all(term in text for term in terms):
            raise ValueError('Report anchors absent: ' + str(number))
    article = articles['c15-start2013-rct-xml']
    permission = ' '.join(article.find('.//permissions').itertext())
    if 'CC BY-NC 3.0' not in permission:
        raise ValueError('Original result license absent')
    namespace = '{http://www.w3.org/1999/xlink}href'
    supplements = sorted({element.get(namespace) for element in article.findall('.//supplementary-material/media')})
    if supplements != ['livg009049.ww1_default.pdf', 'livg009049.ww2_default.pdf']:
        raise ValueError('Original supplementary identifiers changed')
    rendered = []
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER / 'paginas'
        folder.mkdir(exist_ok=True)
        document = pdfium.PdfDocument(str(paths[REPORT]))
        for number in TARGETS:
            page = document[number - 1]
            bitmap = page.render(scale=1.5)
            bitmap.to_pil().save(folder / f'start-pagina-{number}.png')
            bitmap.close()
            page.close()
            rendered.append(number)
        document.close()
    inventory = {'niche': 'N15-C', 'date': '2026-10-11', 'collectorCalls': len(rows),
                 'http200': sum(row['status'] == 200 for row in rows), 'hashedBodies': len(rows),
                 'usableBodies': sum(row['usableForReading'] for row in rows), 'receipts': rows,
                 'pdfPages': sum(len(reader.pages) for reader in pdfs.values()),
                 'manualIncludedInReport': True, 'manualIsRaster': True,
                 'originalBmjSupplementIdentifiers': supplements, 'renderedPages': rendered,
                 'renderingIsVisualInspection': False, 'networkCallsDuringAnalysis': 0,
                 'researchClosureApproved': False, 'releaseApproved': False, 'appImplemented': False}
    (FOLDER / 'inventario.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return inventory


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    result = analyse(parser.parse_args().render)
    print(json.dumps({key: result[key] for key in ['collectorCalls', 'http200', 'hashedBodies', 'usableBodies', 'pdfPages']}))
