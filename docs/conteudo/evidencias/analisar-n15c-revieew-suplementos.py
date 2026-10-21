"""Verifica anexos cientificos PR68 e extrai XML sem executar conteudo."""
import importlib.util
import json
from pathlib import Path, PurePosixPath
import warnings
import xml.etree.ElementTree as ET
from zipfile import ZipFile

from PIL import Image

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-revieew-suplementos'
RAW = ROUND.parent / 'raw'
spec = importlib.util.spec_from_file_location('si_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)
MAX_PIXELS = 40000000


def docx_text(path):
    with ZipFile(path) as archive:
        members = archive.infolist()
        if len(members) > 500 or sum(m.file_size for m in members) > 20000000:
            raise ValueError('OOXML extraction exceeds limits')
        for member in members:
            name = PurePosixPath(member.filename)
            if name.is_absolute() or '..' in name.parts or '\\' in member.filename:
                raise ValueError('Unsafe archive member')
            if member.file_size / max(member.compress_size, 1) > 200:
                raise ValueError('OOXML compression ratio exceeds limit')
        document = ET.fromstring(archive.read('word/document.xml'))
        ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
        rows = [' '.join(''.join(p.itertext()).split()) for p in document.findall('.//w:p', ns)]
        tables = [[[' '.join(''.join(cell.itertext()).split()) for cell in row.findall('w:tc', ns)]
                   for row in table.findall('w:tr', ns)] for table in document.findall('.//w:tbl', ns)]
        return rows, tables, {'members': len(members), 'uncompressedBytes': sum(m.file_size for m in members),
                      'embeddedObjectsExecuted': False, 'macrosExecuted': False,
                      'externalReferencesFetched': False, 'extractedToDisk': False}


def analyse():
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (s['id'] + '.evidencia.json'), ROOT)
               for s in plan['requests']]
    result = {'date': '2026-10-07', 'sourceId': 'PR68', 'networkPerformed': False,
              'sources': entries, 'newCollectorCalls': len(entries),
              'usableBodies': sum(s['usable'] for s in entries),
              'hashedBodies': sum(s['bodyVerified'] for s in entries),
              'figures': [], 'visualInspectionConfirmedByScript': False,
              'researchClosureApproved': False, 'releaseApproved': False}
    # Decode only bounded scientific figures; rendering does not assert inspection.
    Image.MAX_IMAGE_PIXELS = MAX_PIXELS
    with warnings.catch_warnings():
        warnings.simplefilter('error', Image.DecompressionBombWarning)
        for number in [1, 2, 3]:
            ident = f'c15-revieew-si{number}-tif'
            with Image.open(RAW / (ident + '.tif')) as picture:
                if picture.format != 'TIFF' or picture.width * picture.height > MAX_PIXELS or picture.n_frames != 1:
                    raise ValueError('Unexpected or excessive scientific figure')
                picture.load()
                preview = Image.new('RGBA', picture.size, 'white')
                preview.alpha_composite(picture.convert('RGBA'))
                preview.convert('RGB').save(RAW / (ident + '.png'))
                result['figures'].append({'id': ident, 'formatVerified': 'TIFF',
                    'size': list(picture.size), 'frames': picture.n_frames,
                    'inspectionFile': '../raw/' + ident + '.png',
                    'sourceMode': picture.mode, 'transparentPixelsDisplayedOnWhite': True,
                    'originalScientificFileUnchanged': True,
                    'conversionChangedPixelsGeometry': False})
    paragraphs, tables, security = docx_text(RAW / 'c15-revieew-si4-docx.docx')
    result['tableSI1'] = {'paragraphs': paragraphs, 'tables': tables, 'security': security}
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'calls': len(entries), 'usable': result['usableBodies'],
                     'hashes': result['hashedBodies'], 'figures': result['figures'],
                     'tableCount': len(tables), 'tableSecurity': security}))


if __name__ == '__main__':
    analyse()
