"""Audita recibos e metadados N15-C, sem rede ou prescricao de treino."""
import argparse
from html.parser import HTMLParser
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-teses-seguimento'
spec = importlib.util.spec_from_file_location('n15_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


class PublicHtml(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.json_scripts = []
        self._script = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'a' and attrs.get('href'):
            self.links.append(attrs['href'])
        if tag == 'script':
            self._script = [] if attrs.get('type') == 'application/json' else None

    def handle_data(self, data):
        if self._script is not None:
            self._script.append(data)

    def handle_endtag(self, tag):
        if tag == 'script' and self._script is not None:
            self.json_scripts.append(json.loads(''.join(self._script)))
            self._script = None


def body_for(record):
    path = ROOT / record['record']
    receipt = json.loads(path.read_text(encoding='utf-8'))
    return (path.parent / receipt['bodyFile']).resolve()


def analyse(render=False):
    entries = [receipts.check_receipt(p, ROOT) for p in sorted(ROUND.glob('*.evidencia.json'))]
    result = {
        'date': '2026-10-07', 'continuedAt': '2026-10-08',
        'niche': 'N15-C', 'networkPerformed': False,
        'newCollectorCalls': len(entries),
        'http200Responses': sum(e['status'] == 200 for e in entries),
        'http200Bodies': sum(e['status'] == 200 and e['bodyVerified'] for e in entries),
        'usableBodies': sum(e['usable'] for e in entries),
        'hashedBodies': sum(e['bodyVerified'] for e in entries),
        'sources': entries, 'htmlPublicLinks': {}, 'pdfs': {}, 'jats': {},
        'researchClosureApproved': False, 'releaseApproved': False,
    }
    for entry in entries:
        if not entry['usable']:
            continue
        path = body_for(entry)
        if path.suffix == '.pdf':
            pdf = PdfReader(path)
            result['pdfs'][entry['id']] = {
                'pages': len(pdf.pages), 'wholePdfVisuallyReviewed': False,
                'allPagesTextExtracted': True,
                'textPageLengths': [len(p.extract_text() or '') for p in pdf.pages],
                'renderedPages': [],
            }
            selected = {
                'c15-va-walking-caregiver-pdf': [3, 8, 9],
                'c15-va-walking-facilitator-pdf': [27, 30],
                'c15-va-walking-workbook-pdf': [14, 23],
                'c15-va-walking-mindful-pdf': [6, 8],
                'c15-niva-faixas-cartaz-pdf': [1],
            }.get(entry['id'], [])
            if render:
                import pypdfium2 as pdfium
                out = ROUND.parent / 'raw/n15c-teses-seguimento-render'
                out.mkdir(exist_ok=True)
                with pdfium.PdfDocument(path) as doc:
                    for page in selected:
                        surface = doc[page - 1]
                        try:
                            bitmap = surface.render(scale=1.5)
                            try:
                                bitmap.to_pil().save(out / f'{entry["id"]}-p{page}.png')
                            finally:
                                bitmap.close()
                        finally:
                            surface.close()
                result['pdfs'][entry['id']]['renderedPages'] = selected
        elif path.suffix == '.xml':
            root = ET.parse(path).getroot()
            plain = lambda n: ' '.join(' '.join(n.itertext()).split()) if n is not None else None
            result['jats'][entry['id']] = {
                'title': plain(root.find('.//article-title')),
                'doi': root.findtext('.//article-id[@pub-id-type="doi"]'),
                'permissions': plain(root.find('.//permissions')),
                'supplements': [dict(n.attrib) for n in root.findall('.//supplementary-material')],
                'tableLabels': [plain(n.find('label')) for n in root.findall('.//table-wrap')],
            }
        elif path.suffix == '.html':
            parser = PublicHtml()
            parser.feed(path.read_text(encoding='utf-8'))
            result['htmlPublicLinks'][entry['id']] = sorted({
                s for s in parser.links if any(word in s.lower()
                    for word in ['hdl.handle', 'bitstream', '.pdf', 'supplement'])})
            if entry['id'] == 'c15-crea2026-suplementos-pagina':
                # Nuxt publishes a reference-indexed JSON array, not executable code.
                arrays = [j for j in parser.json_scripts if isinstance(j, list)]
                result['frontiersJsonInventory'] = [
                    {'index': i, 'value': v} for values in arrays for i, v in enumerate(values)
                    if (isinstance(v, str) and any(word in v.lower()
                        for word in ['data_sheet', '.pdf', 'supplement', '1944170']))
                    or (isinstance(v, dict) and any(word in str(k).lower()
                        for k in v for word in ['supplement', 'download', 'attachment']))]
        elif entry['id'] == 'c15-revieew-seguimento-europepmc':
            records = json.loads(path.read_text(encoding='utf-8'))['resultList']['result']
            assert len(records) == 1 and records[0]['pmid'] == '40561221'
            article = records[0]
            result['followupMetadata'] = {key: article.get(key) for key in
                ['pmid', 'doi', 'title', 'firstPublicationDate', 'pubYear',
                 'abstractText', 'isOpenAccess', 'inEPMC', 'hasPDF', 'hasSuppl', 'fullTextUrlList']}
            assert 'P = 0.140' in article['abstractText']
            assert 'negative effect' in article['abstractText']
        elif entry['id'] == 'c15-heartfocused2021-metadados':
            records = json.loads(path.read_text(encoding='utf-8'))['resultList']['result']
            assert len(records) == 1 and records[0]['pmid'] == '33639543'
            result['heartFocusedMetadata'] = {k: records[0].get(k) for k in
                ['pmid', 'doi', 'title', 'abstractText', 'isOpenAccess', 'hasPDF']}
            assert 'worsened' in records[0]['abstractText']
        elif entry['id'] == 'c15-benson478-alzheimer-registro':
            data = json.loads(path.read_text(encoding='utf-8'))
            result['benson478Registry'] = {
                'hasResults': data.get('hasResults'),
                'resultsSectionPresent': 'resultsSection' in data,
                'protocolSection': data['protocolSection'],
            }
            assert data['protocolSection']['identificationModule']['nctId'] == 'NCT06997523'
    output = ROUND / 'inventario.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: result[k] for k in
                     ['newCollectorCalls', 'http200Responses', 'http200Bodies', 'usableBodies', 'hashedBodies']}))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
