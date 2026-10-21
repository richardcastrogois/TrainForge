"""Audit receipts and original bodies without merging clinical versions."""
import argparse
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-protocolos-operacionais'
XLINK = '{http://www.w3.org/1999/xlink}href'


class HtmlText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text, self.links = [], []
        self.inputs = {}
        self.hidden = 0

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ('script', 'style'):
            self.hidden += 1
        if tag == 'a':
            href = attrs.get('href')
            if href:
                self.links.append(href)
        if tag == 'input' and attrs.get('id'):
            self.inputs[attrs['id']] = attrs.get('value')

    def handle_endtag(self, tag):
        if tag in ('script', 'style') and self.hidden:
            self.hidden -= 1

    def handle_data(self, data):
        if not self.hidden:
            self.text.append(data)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def analyse(render=False):
    rows, bodies, receipts = [], {}, {}
    manifests = sorted(FOLDER.glob('requisicoes*.json')) + [FOLDER / 'consulta-disponibilidade.json']
    identities = []
    for path in manifests:
        identities.extend(item['id'] for item in json.loads(path.read_text(encoding='utf-8'))['requests'])
    require(len(identities) == len(set(identities)), 'Duplicate collection IDs')
    for identity in identities:
        path = FOLDER / (identity + '.evidencia.json')
        receipt = json.loads(path.read_text(encoding='utf-8'))
        receipts[identity] = receipt
        row = {'record': path.relative_to(ROOT).as_posix(), 'url': receipt['url'],
               'status': receipt['status'], 'sha256': receipt.get('sha256'),
               'bytes': receipt.get('bytes'), 'error': receipt.get('error'),
               'bodyUsable': False}
        if receipt.get('bodyFile'):
            body_path = (path.parent / receipt['bodyFile']).resolve()
            require(body_path.is_relative_to(ROOT.resolve()), 'Body outside evidence directory')
            body = body_path.read_bytes()
            require(len(body) == receipt['bytes'], 'Byte mismatch: ' + identity)
            require(hashlib.sha256(body).hexdigest() == receipt['sha256'], 'Hash mismatch: ' + identity)
            usable = receipt['status'] == 200 and not receipt.get('error') and bool(body)
            row['bodyUsable'] = usable
            if usable:
                bodies[identity] = body_path
        rows.append(row)

    html = {}
    for identity, path in bodies.items():
        if identity.endswith('html'):
            parser = HtmlText()
            parser.feed(path.read_text(encoding='utf-8'))
            html[identity] = parser
    preprint = ' '.join(html['c15-dogan-preprint-html'].text)
    require('CC BY 4.0' in preprint and 'practice guide' in preprint, 'Preprint identity/license/guide')
    require('every day' in preprint and '3 days a week' in preprint, 'Preprint dose/support anchors')
    issue_links = html['c15-dogan2025-edicao-html'].links
    require(any('/licenses/by-nc-sa/4.0' in link for link in issue_links), 'Exact issue license missing')

    json_bodies = {key: json.loads(path.read_text(encoding='utf-8')) for key, path in bodies.items()
                   if key.endswith('json')}
    crea = json_bodies['c15-crea2026-registro-json']
    require(crea['protocolSection']['identificationModule']['nctId'] == 'NCT07388186', 'CREA identity')
    require(crea['hasResults'] is False, 'CREA results changed')
    dogan = json_bodies['c15-dogan2025-registro-json']
    require(dogan['protocolSection']['identificationModule']['nctId'] == 'NCT05988320', 'Dogan identity')
    gyyb = json_bodies['c15-gyyb-registro-json']
    require(gyyb['protocolSection']['designModule']['enrollmentInfo']['count'] == 50, 'Main plus supplement sample')
    require(gyyb['hasResults'] is True, 'GYBB registry results missing')
    lite = json_bodies['c15-one-stretch2019-resumo-json']['resultList']['result'][0]
    core = json_bodies['c15-one-stretch2019-core-json']['resultList']['result'][0]
    require('abstractText' not in lite and 'abstractText' in core, 'LITE/CORE distinction lost')

    sui = ET.parse(bodies['c15-sui2023-xml']).getroot()
    require(any(node.text == '10.2196/42861' for node in sui.iter('article-id')), 'Sui DOI mismatch')
    supplements = [{'id': node.get('id'), 'title': ' '.join(node.itertext()),
                    'files': [media.get(XLINK) for media in node.iter('media')]}
                   for node in sui.iter('supplementary-material')]
    require(len(supplements) == 5, 'Sui published supplement count')
    vr = ET.parse(bodies['c15-vr2025-xml']).getroot()
    require(any(node.text == '10.3390/jfmk10030353' for node in vr.iter('article-id')), 'VR DOI mismatch')
    chinese = json.loads(html['c15-baduanjin-avc2023-cn-html'].inputs['article_metaJson'])
    require(chinese['article']['doi'] == '10.13517/j.cnki.ccm.2023.08.001', 'Baduanjin identity')
    require('70' in chinese['article']['zhaiyao_en'] and not chinese['article']['copyrightStatement_en'],
            'Abstract and missing rights distinction')
    availability_text = bodies['c15-baduanjin-acesso-pdf'].read_text(encoding='utf-8')
    require(availability_text.startswith('[json]'), 'Unexpected PDF availability wrapper')
    availability = json.loads(availability_text[len('[json]'):])
    require(availability['status'] == 1, 'Public PDF availability not confirmed')
    require(receipts['c15-baduanjin-acesso-pdf']['method'] == 'POST', 'Read-only query method lost')
    qigong = json_bodies['c15-qigong-registro-json']
    require(qigong['protocolSection']['identificationModule']['nctId'] == 'NCT04019301', 'Qigong family identity')
    require(qigong['hasResults'] is False, 'Qigong registry changed')
    policy = ' '.join(html['c15-baduanjin-politica-html'].text)
    require('2026' in policy and 'CC BY-NC-ND' in policy, 'Published policy version/license')
    marine = ET.parse(bodies['c15-estabilizacao2022-xml']).getroot()
    require(any(node.text == '10.3390/ijerph19106025' for node in marine.iter('article-id')),
            'Caregiver stabilization identity')
    require(not list(marine.iter('supplementary-material')), 'Previously unannounced supplement requires review')

    pdfs, rendered = [], []
    pdf_expected = {'c15-dogan2025-artigo-pdf': (13, [1, 3, 4, 5, 8, 10, 13]),
                    'c15-nagamatsu2012-antecedente-pdf': (7, [1, 3, 4]),
                    'c15-gyyb-protocolo-pdf': (34, [1, 3, 8, 12, 13, 29, 30]),
                    'c15-one-stretch2015-relatorio-mhlw-pdf': (802, [235, 236, 237, 238, 239, 240, 798]),
                    'c15-qigong-protocolo-pdf': (26, [1, 6, 10, 12, 14, 22, 26]),
                    'c15-baduanjin-avc2023-pdf': (6, [1, 2, 3, 4, 5, 6])}
    for identity, (count, visual_targets) in pdf_expected.items():
        pages = PdfReader(bodies[identity]).pages
        require(len(pages) == count, 'Unexpected pages: ' + identity)
        text = [page.extract_text() or '' for page in pages]
        if identity == 'c15-dogan2025-artigo-pdf':
            require('Cancer Patient Caregivers' in text[0], 'PDF title, not web parser title')
            require('daily basis' in text[4] and 'Sundays' in text[4], 'Full methods dose')
            require('replaced' in text[3] and '112,750' in text[7], 'Attrition/results')
        if identity == 'c15-nagamatsu2012-antecedente-pdf':
            require('Eight women' in text[0] and 'Warrior' in text[2], 'Not a caregiver trial')
        if identity == 'c15-gyyb-protocolo-pdf':
            require('RN' in text[0] and 'Supplemental ARM 4' in text[7], 'Caregiver protocol identity')
        if identity == 'c15-one-stretch2015-relatorio-mhlw-pdf':
            require('10.1179/2042618614Y.0000000100' in text[235], 'Original reprint DOI')
            require('Figure 1' in text[236] and '30-minute seminar' in text[236], 'Figure and supported delivery')
            require('136' in text[237] or 'n564' in text[237], 'Original caregiver analysis')
        if identity == 'c15-qigong-protocolo-pdf':
            require('RN' in text[0] and 'Table 1' in text[11], 'Qigong professional/programme anchors')
        if identity == 'c15-baduanjin-avc2023-pdf':
            require('10.13517/j.cnki.ccm.2023.08.001' in ''.join(text[0].split()), 'Original Chinese programme DOI')
            require('0.091' in text[3] and '0.075' in text[3], 'Sleep interaction table, not abstract alone')
        pdfs.append({'id': identity, 'pages': count, 'allPagesTextExtracted': True})
        if render:
            import pypdfium2 as pdfium
            directory = FOLDER / 'paginas' / identity
            directory.mkdir(parents=True, exist_ok=True)
            document = pdfium.PdfDocument(str(bodies[identity]))
            for number in visual_targets:
                page = document[number - 1]
                bitmap = page.render(scale=1.25)
                bitmap.to_pil().save(directory / f'pagina-{number}.png')
                bitmap.close()
                page.close()
                rendered.append({'id': identity, 'page': number})
            document.close()
    output = {'date': '2026-10-08', 'niche': 'N15-C', 'collectorCalls': len(rows),
              'usableBodies': sum(row['bodyUsable'] for row in rows),
              'hashedBodies': sum(bool(row['sha256']) for row in rows),
              'sources': rows, 'pdfs': pdfs, 'pdfPages': sum(row['pages'] for row in pdfs),
              'suiPublishedSupplements': supplements,
              'baduanjinMetadataParsedNotTemplateOnly': True,
              'publicPdfAvailabilityConfirmed': True,
              'oneStretchPdfLinks': [link for link in html['c15-one-stretch2015-pmc-html'].links
                                     if '.pdf' in link],
              'renderedPages': rendered, 'visualInspectionNotDeterminedByScript': True,
              'researchClosureApproved': False, 'releaseApproved': False}
    (FOLDER / 'inventario.json').write_text(json.dumps(output, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return output


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--render', action='store_true')
    result = analyse(cli.parse_args().render)
    print(json.dumps({key: result[key] for key in ['collectorCalls', 'usableBodies', 'hashedBodies', 'pdfPages', 'oneStretchPdfLinks']}))
