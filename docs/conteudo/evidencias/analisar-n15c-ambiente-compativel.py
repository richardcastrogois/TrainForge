"""Verifica recibos e trechos Montero, sem rede; nao homologa exercicios."""
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
ROUND = ROOT / '2026-10-07/n15c-ambiente-compativel'
spec = importlib.util.spec_from_file_location('setting_receipts', ROOT / 'analisar-n15c-manuais.py')
receipts = importlib.util.module_from_spec(spec)
spec.loader.exec_module(receipts)


def analyse():
    plan = json.loads((ROUND / 'requisicoes.json').read_text(encoding='utf-8'))
    entries = [receipts.check_receipt(ROUND / (s['id'] + '.evidencia.json'), ROOT)
               for s in plan['requests']]
    root = ET.parse(ROUND.parent / 'raw/c15-montero2020-xml.xml').getroot()
    ids = ['sec2dot1-ijerph-17-07359', 'sec2dot5dot2-ijerph-17-07359',
           'sec3dot3-ijerph-17-07359', 'sec3dot4-ijerph-17-07359',
           'app1-ijerph-17-07359']
    plain = lambda n: ' '.join(' '.join(n.itertext()).split())
    result = {'date': '2026-10-07', 'niche': 'N15-C', 'networkPerformed': False,
              'sources': entries, 'newCollectorCalls': len(entries),
              'http200Bodies': sum(s['status'] == 200 for s in entries),
              'usableBodies': sum(s['usable'] for s in entries),
              'hashedBodies': sum(s['bodyVerified'] for s in entries),
              'monteroSections': [{'locator': s.attrib['id'], 'text': plain(s)}
                                  for s in root.findall('.//sec') if s.attrib.get('id') in ids],
              'monteroLicence': plain(root.find('.//permissions')),
              'supplementElementsCount': len(root.findall('.//supplementary-material')),
              'unlinkedDocumentAbsenceGloballyProven': False,
              'researchClosureApproved': False, 'releaseApproved': False}
    assert 'licenses/by/4.0' in result['monteroLicence']
    assert len(result['monteroSections']) == 5
    (ROUND / 'inventario.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: result[k] for k in ['newCollectorCalls', 'http200Bodies', 'usableBodies', 'hashedBodies']}))


if __name__ == '__main__':
    analyse()
