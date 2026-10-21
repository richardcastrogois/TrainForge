"""Reproduz inventario local desta rodada; nao prescreve nem faz rede."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-05/programas-manuais-02'
W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


def verify_body(record_path, root=ROOT):
    record = json.loads(record_path.read_text(encoding='utf-8'))
    body = (record_path.parent / record['bodyFile']).resolve()
    body.relative_to(root.resolve())
    with body.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    if record['status'] != 200 or record.get('error'):
        raise ValueError('Not a usable HTTP 200 receipt')
    if digest != record['sha256'] or body.stat().st_size != record['bytes']:
        raise ValueError('Body hash/size mismatch')
    return record, body


def docx_inventory(path, max_expanded=16 * 1024 * 1024):
    # Read only XML, never unpack or execute document content/relationships.
    with zipfile.ZipFile(path) as archive:
        members = archive.infolist()
        names = [m.filename for m in members]
        if len(members) > 200 or len(set(names)) != len(names):
            raise ValueError('Too many or duplicate ZIP members')
        if any(n.startswith(('/', '\\')) or '..' in Path(n.replace('\\', '/')).parts for n in names):
            raise ValueError('Unsafe ZIP path')
        total = sum(m.file_size for m in members)
        if total > max_expanded or any(m.file_size / max(m.compress_size, 1) >= 1000 for m in members):
            raise ValueError('Expanded ZIP budget exceeded')
        if any(m.flag_bits & 1 for m in members):
            raise ValueError('Encrypted content not inspected')
        document = ET.fromstring(archive.read('word/document.xml'))
        paragraphs = [''.join(t.text or '' for t in p.iter(W + 't')) for p in document.iter(W + 'p')]
        text = ' '.join(' '.join(paragraphs).split())
        return {
            'members': len(members), 'expandedBytes': total,
            'paragraphs': len(list(document.iter(W + 'p'))),
            'tables': len(list(document.iter(W + 'tbl'))),
            'embeddedImages': [n for n in names if n.startswith('word/media/')],
            'textBoxes': len(list(document.iter(W + 'txbxContent'))),
            'hasInterventionManualReference': 'Intervention Manual' in text,
            'hasIntervenerWorksheetReference': 'Intervener' in text and 'Work Sheet' in text,
            'hasBlankGoalAndPlanLabels': 'GOAL:' in text and 'PLAN:' in text,
            'hasWalkingExampleNotPrescription': 'Walking outdoors' in text and 'Example:' in text,
            'containsTextAnchor': text,
        }


def analyse():
    entries = []
    for receipt in sorted(ROUND.glob('*.evidencia.json')):
        record, body = verify_body(receipt)
        item = {k: record[k] for k in ('id', 'url', 'resolvedUrl', 'bytes', 'sha256')}
        item['record'] = receipt.relative_to(ROOT).as_posix()
        if body.suffix == '.docx':
            docx = docx_inventory(body)
            assert 'Supplementary File' in docx.pop('containsTextAnchor')
            item['docx'] = docx
        elif body.suffix == '.pdf':
            pdf = PdfReader(body)
            texts = [page.extract_text() or '' for page in pdf.pages]
            item['pdf'] = {'pages': len(pdf.pages), 'textExtractedPages': len(texts),
                           'pagesWithoutExtractableText': [i+1 for i,t in enumerate(texts) if not t.strip()]}
            if record['id'] == 'i18-react-nihr-protocolo':
                assert len(texts) == 161 and '16' in texts[0] and 'May 2018' in texts[0]
                assert 'Appendix 4' in texts[62] and 'Sample' in texts[62]
            if record['id'] == 'c15-myten-pdf':
                assert len(texts) == 22 and 'Article in Press' in texts[0]
            if record['id'] == 'c15-benson-cancer-pdf':
                assert 'Attribution-NonCommercial' in texts[0]
        entries.append(item)
    assert len(entries) == 13, 'Incomplete round'
    result = {'date': '2026-10-05', 'networkCallsByThisScript': 0,
              'verifiedBodies': len(entries), 'entries': entries,
              'readExtent': 'PDF text extraction is not visual validation. DOCX text/structure only; no content executed.',
              'researchClosureApproved': False, 'releaseApproved': False, 'appImplemented': False}
    output = ROUND / 'inventario-manuais.json'
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'verifiedBodies': len(entries), 'output': output.relative_to(ROOT).as_posix()}))


if __name__ == '__main__':
    analyse()
