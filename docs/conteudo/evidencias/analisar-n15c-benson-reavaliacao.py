"""Verify the received original and its distinct methods/asset-rights records offline."""
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-benson-reavaliacao'


def analyse():
    spec = importlib.util.spec_from_file_location('guide_html', ROOT / 'analisar-n15c-guias-clinicos.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    rows, documents = [], {}

    def received(path):
        receipt = json.loads(path.read_text(encoding='utf-8'))
        body_path = (path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = body_path.read_bytes()
        if receipt.get('status') != 200 or receipt.get('error'):
            raise ValueError('Receipt is not usable: ' + path.name)
        if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Body integrity mismatch: ' + path.name)
        parser = module.HtmlText()
        parser.feed(body.decode('utf-8'))
        return receipt, parser, ' '.join(' '.join(parser.text).split())

    manifest = json.loads((FOLDER / 'requisicoes.json').read_text(encoding='utf-8'))
    for request in manifest['requests']:
        path = FOLDER / (request['id'] + '.evidencia.json')
        receipt, parser, content = received(path)
        documents[request['id']] = content
        rows.append({'id': request['id'], 'record': path.relative_to(ROOT).as_posix(),
                     'sha256': receipt['sha256'], 'bytes': receipt['bytes'], 'status': 200,
                     'usable': True, 'resolvedUrl': receipt['resolvedUrl']})
    article = documents['c15-benson2022-original-html']
    for anchor in ('Nurse Instructor, M.Sc.', '24 caregivers', '28 in the control group',
                   '15 minutes', 'do not get up for a few minutes',
                   'CD together with an educational pamphlet', 'performed the exercises independently'):
        if anchor not in article:
            raise ValueError('Original anchor absent: ' + anchor)
    law = documents['c15-direito-cientifico-lei9610-html']
    for anchor in ('conteúdo científico ou técnico', 'Art. 8', 'Art. 29', 'tradução'):
        if anchor not in law:
            raise ValueError('Official law anchor absent: ' + anchor)
    rights_path = ROOT / '2026-10-05/programas-manuais-02/c15-benson-hemodialise-direitos.evidencia.json'
    rights, parser, content = received(rights_path)
    if not any('/licenses/by-nc-sa/4.0' in link for link in parser.links):
        raise ValueError('Publisher asset license absent')
    inventory = {'niche': 'N15-C', 'auditedAt': '2026-10-11', 'collectionCount': len(rows),
                 'usefulBodies': len(rows), 'bodiesWithVerifiedHashes': len(rows), 'receipts': rows,
                 'priorLicenseReceipt': rights_path.relative_to(ROOT).as_posix(),
                 'priorLicenseSha256': rights['sha256'], 'publisherAssetLicense': 'CC BY-NC-SA 4.0',
                 'licenseReplacedByGenericBy': False, 'scientificFactsBlanketProhibited': False,
                 'assetCopyApproved': False, 'legalReviewPerformed': False,
                 'researchClosureApproved': False, 'releaseApproved': False, 'appImplemented': False,
                 'networkCallsDuringAnalysis': 0}
    (FOLDER / 'inventario.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return inventory


if __name__ == '__main__':
    print(json.dumps(analyse(), ensure_ascii=False, indent=2))
