"""Confere recibos e protocolo NIH por OOXML, sem executar objetos incorporados."""
import argparse
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-nih-yoga'
RAW = ROUND.parent / 'raw'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
spec = importlib.util.spec_from_file_location('nih_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


def read_protocol(path):
    with zipfile.ZipFile(path) as archive:
        members = archive.infolist()
        total = sum(member.file_size for member in members)
        ratios = [member.file_size / max(member.compress_size, 1) for member in members]
        if len(members) > 200 or total > 16 * 1024 * 1024 or max(ratios) > 100:
            raise ValueError('DOCX exceeds safe XML inspection limits')
        document = ET.fromstring(archive.read('word/document.xml'))
        # Only visible text: field instructions include large EndNote metadata.
        paragraphs = [''.join(run.text or '' for run in paragraph.findall('.//w:t', NS))
                      for paragraph in document.findall('.//w:p', NS)]
        security = {'members': len(members), 'uncompressedBytes': total,
                    'maximumCompressionRatio': max(ratios), 'memberCeiling': 200,
                    'uncompressedByteCeiling': 16 * 1024 * 1024, 'ratioCeiling': 100,
                    'embeddedObjectPresent': any('/embeddings/' in m.filename for m in members),
                    'embeddedObjectExecuted': False, 'externalRelationshipsFetched': False,
                    'xmlVisibleTextOnly': True, 'paragraphIndexBase': 0}
    return paragraphs, security


def analyse(render=False):
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (item['id'] + '.evidencia.json'), ROOT)
               for item in plan['requests']]
    paragraphs, security = read_protocol(RAW / 'c15-nih-yoga2022-s2-docx.docx')
    assert 'February 14, 2018' in paragraphs[0]
    assert paragraphs[528] == 'SEQUENCE FOR YOGA PRACTICE AUDIO FILE'
    assert '15-20 seconds' in paragraphs[540] and 'to the right' in paragraphs[540]
    assert 'left' not in paragraphs[540].split('twist at the waist')[1]
    assert 'resume normal breathing' in paragraphs[544]
    reader = PdfReader(RAW / 'c15-nih-yoga2022-pdf.pdf')
    assert len(reader.pages) == 14
    assert 'CC0' in reader.pages[0].extract_text()
    root = ET.parse(RAW / 'c15-caremetoo2020-xml.xml').getroot()
    permission = ET.tostring(root.find('.//permissions'), encoding='unicode')
    assert 'licenses/by/4.0' in permission
    supplements = [{'label': s.findtext('label'), 'description': ' '.join(s.find('p').itertext())}
                   for s in root.findall('.//supplementary-material')]
    assert len(supplements) == 2
    pages = [1, 3, 4, 11, 12]
    if render:
        import pypdfium2 as pdfium
        document = pdfium.PdfDocument(RAW / 'c15-nih-yoga2022-pdf.pdf')
        try:
            for number in pages:
                page = document[number - 1]
                bitmap = page.render(scale=1.4)
                try:
                    bitmap.to_pil().save(RAW / f'c15-nih-yoga2022-pdf-p{number}.png')
                finally:
                    bitmap.close()
                    page.close()
        finally:
            document.close()
    result = {'date': '2026-10-07', 'niche': 'N15-C', 'networkPerformed': False,
              'sources': entries, 'newCollectorCalls': len(entries),
              'http200Bodies': sum(s['status'] == 200 for s in entries),
              'usableBodies': sum(s['usable'] for s in entries),
              'hashedBodies': sum(s['bodyVerified'] for s in entries),
              'pdfPages': 14, 'renderedPdfPages': pages if render else [],
              'visualInspectionConfirmedByScript': False, 'docxInspection': security,
              'appendixA': [{'zeroBasedParagraph': i, 'visibleText': paragraphs[i]}
                            for i in range(528, 548)],
              'careMeTooPermissions': permission, 'careMeTooSupplementDescriptions': supplements,
              'researchClosureApproved': False, 'releaseApproved': False, 'appImplemented': False}
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: result[key] for key in ('newCollectorCalls', 'http200Bodies', 'usableBodies', 'hashedBodies')}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    analyse(parser.parse_args().render)
