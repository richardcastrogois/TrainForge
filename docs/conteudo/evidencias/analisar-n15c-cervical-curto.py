"""Audit a public DOCX received under a PDF request, without another GET."""
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-cervical-curto'


def analyse():
    spec = importlib.util.spec_from_file_location('bounded_docx', ROOT / 'analisar-n15c-revieew-suplementos.py')
    bounded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(bounded)
    manifest = json.loads((FOLDER / 'requisicoes.json').read_text(encoding='utf-8'))
    rows, paths = [], {}
    for item in manifest['requests']:
        receipt_path = FOLDER / (item['id'] + '.evidencia.json')
        receipt = json.loads(receipt_path.read_text(encoding='utf-8'))
        row = {'id': item['id'], 'record': receipt_path.relative_to(ROOT).as_posix(),
               'status': receipt.get('status'), 'bytes': receipt.get('bytes'),
               'sha256': receipt.get('sha256'), 'error': receipt.get('error'),
               'usableByCollector': receipt.get('status') == 200 and not receipt.get('error'),
               'offlineFormatRecovery': False}
        if receipt.get('bodyFile'):
            path = (receipt_path.parent / receipt['bodyFile']).resolve()
            if not path.is_relative_to(ROOT.resolve()):
                raise ValueError('Body outside evidence root')
            body = path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Receipt hash or byte mismatch')
            paths[item['id']] = path
        rows.append(row)
    identity = 'c15-cervical2026-suplemento-pdf'
    paragraphs, tables, limits = bounded.docx_text(paths[identity])
    text = '\n'.join(paragraphs)
    for anchor in ['elderly-care workers', 'S1 Appendix', 'S2 Appendix', 'S3 Appendix', 'physiotherapist', '90 seconds']:
        if anchor not in text:
            raise ValueError('Supplement anchor missing: ' + anchor)
    recovered = next(row for row in rows if row['id'] == identity)
    recovered['offlineFormatRecovery'] = True
    recovered['verifiedActualFormat'] = 'DOCX_OOXML_not_PDF'
    recovered['receiptModified'] = False
    recovered['docxLimits'] = limits
    recovered['tableCount'] = len(tables)
    recovered['fullTextRedistributed'] = False
    study = json.loads(paths['c15-cervical2026-registro-json'].read_text(encoding='utf-8'))
    if study['protocolSection']['identificationModule']['nctId'] != 'NCT06346249':
        raise ValueError('Wrong trial')
    result = {'collectionCount': len(rows), 'hashedBodies': sum(bool(row['sha256']) for row in rows),
              'usableByCollector': sum(row['usableByCollector'] for row in rows),
              'usefulAfterOfflineRecovery': sum(row['usableByCollector'] or row['offlineFormatRecovery'] for row in rows),
              'newNetworkCallsForRecovery': 0, 'receipts': rows,
              'registryHasResults': study['hasResults'], 'researchClosureApproved': False,
              'releaseApproved': False, 'appImplemented': False}
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    result = analyse()
    print(json.dumps({key: value for key, value in result.items() if key != 'receipts'}, ensure_ascii=False))
