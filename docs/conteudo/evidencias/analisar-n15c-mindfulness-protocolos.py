"""Verify originals without treating abstracts, blocked HTML or SPIRIT as a manual."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-mindfulness-protocolos'
PDF_ID = 'c15-benson-autismo2025-pdf'


def analyse(render=False):
    spec = importlib.util.spec_from_file_location('original_html', ROOT / 'analisar-n15c-guias-clinicos.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    manifest = json.loads((FOLDER / 'requisicoes.json').read_text(encoding='utf-8'))
    rows, texts, metadata, paths = [], {}, {}, {}
    for request in manifest['requests']:
        receipt_path = FOLDER / (request['id'] + '.evidencia.json')
        receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        if receipt['url'] != request['url']:
            raise ValueError('Manifest/receipt URL mismatch')
        path = (receipt_path.parent / receipt['bodyFile']).resolve()
        if not path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence tree')
        body = path.read_bytes()
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body hash/length mismatch: ' + request['id'])
        usable = receipt['status'] == 200 and not receipt.get('error')
        role = 'original'
        paths[request['id']] = path
        if not usable:
            role = 'blocked_response_not_article'
        elif request['extension'] == 'doc':
            if not body.startswith(bytes.fromhex('d0cf11e0a1b11ae1')):
                raise ValueError('Expected compound binary DOC, not DOCX')
            audit = json.loads((FOLDER / 'leitura-doc.json').read_text(encoding='utf-8'))
            extracted_path = (FOLDER / audit['extractedTextFile']).resolve()
            if not extracted_path.is_relative_to(ROOT.resolve()):
                raise ValueError('Extracted DOC text outside evidence tree')
            extracted = extracted_path.read_bytes()
            if audit['sourceSha256'] != receipt['sha256'] or len(extracted) != audit['extractedTextBytes'] or hashlib.sha256(extracted).hexdigest() != audit['extractedTextSha256']:
                raise ValueError('DOC extraction audit mismatch')
            parts = json.loads(extracted)
            if 'SPIRIT 2013 Checklist' not in parts['body'] or 'Attribution-NonCommercial-NoDerivs 3.0 Unported' not in parts['body']:
                raise ValueError('SPIRIT checklist or its own license absent')
            if audit['officeOrMacrosExecuted'] or audit['parserVersion'] != '1.0.4':
                raise ValueError('Unexpected DOC parser/macro audit')
            role = 'spirit_reporting_checklist_not_exercise_instruction_manual'
        elif request['extension'] == 'json':
            result = json.loads(body)
            if result.get('hitCount') != 1 or len(result['resultList']['result']) != 1:
                raise ValueError('Metadata query does not identify exactly one record')
            article = result['resultList']['result'][0]
            if article.get('source') != 'MED' or not article.get('abstractText'):
                raise ValueError('Expected indexed primary abstract, not full text')
            metadata[request['id']] = article
            role = 'indexed_primary_abstract_not_instruction_manual'
        elif request['extension'] == 'html':
            parser = module.HtmlText()
            parser.feed(body.decode('utf-8'))
            texts[request['id']] = ' '.join(' '.join(parser.text).split())
            texts['supplement_links'] = [link for link in parser.links if 'MOESM' in link]
        elif request['extension'] == 'pdf':
            reader = PdfReader(path)
            if len(reader.pages) != 10:
                raise ValueError('Unexpected original PDF length')
            texts[PDF_ID] = [' '.join((page.extract_text() or '').split()) for page in reader.pages]
        rows.append({'id': request['id'], 'record': receipt_path.relative_to(ROOT).as_posix(),
                     'url': receipt['url'], 'status': receipt['status'], 'bytes': len(body),
                     'sha256': receipt['sha256'], 'usableForReading': usable, 'role': role})
    protocol = texts['c15-most2023-protocolo-html']
    for anchor in ('seven 2-h group sessions', 'mindfulness practitioner',
                   'no specific criteria for discontinuing', 'Creative Commons Attribution 4.0'):
        if anchor not in protocol:
            raise ValueError('Protocol anchor absent: ' + anchor)
    pages = texts[PDF_ID]
    for index, anchors in {0: ['by-nc/4.0', '45-54'],
                           2: ['30 to 50 years', 'permuted block'],
                           3: ['psychologist', 'twice a day for 30', 'phone calls'],
                           4: ['20 min', 'mouth or stomach', 'headphones'],
                           5: ['10.69', '52.76', '25.38', '33.04']}.items():
        if not all(anchor in pages[index] for anchor in anchors):
            raise ValueError('PDF anchors absent: page ' + str(index + 1))
    for identity, pmid in [('c15-tan20-caregivers-core-json', '31854193'),
                           ('c15-tan5-misto-core-json', '25632044'),
                           ('c15-yildirim-breath-music-core-json', '39158927')]:
        if metadata[identity].get('pmid') != pmid:
            raise ValueError('Indexed PMID mismatch')
    inventory = {'niche': 'N15-C', 'date': '2026-10-11', 'collectorCalls': len(rows),
                 'http200': sum(row['status'] == 200 for row in rows), 'hashedBodies': len(rows),
                 'usableBodies': sum(row['usableForReading'] for row in rows), 'receipts': rows,
                 'supplementLinksObserved': texts['supplement_links'], 'pdfPages': 10,
                 'unparsedBinaryDocCount': 0, 'spiritReportingChecklistCount': 1, 'blockedOriginalCount': 1,
                 'abstractCount': len(metadata), 'pdfInconsistentBreathingNotRepaired': True,
                 'professionalDeliveryNotRemoved': True,
                 'visualInspectionNotDeterminedByScript': True,
                 'networkCallsDuringAnalysis': 0, 'researchClosureApproved': False,
                 'releaseApproved': False, 'appImplemented': False}
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(str(paths[PDF_ID]))
        folder = FOLDER / 'paginas'
        folder.mkdir(exist_ok=True)
        numbers = [1, 3, 4, 5, 6, 7]
        for number in numbers:
            page = document[number - 1]
            bitmap = page.render(scale=1.5)
            bitmap.to_pil().save(folder / f'autismo-pagina-{number}.png')
            bitmap.close()
            page.close()
        document.close()
        inventory['renderedPages'] = numbers
    (FOLDER / 'inventario.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return inventory


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    output = analyse(parser.parse_args().render)
    print(json.dumps({key: output[key] for key in ['collectorCalls', 'http200', 'hashedBodies', 'usableBodies', 'pdfPages']}))
