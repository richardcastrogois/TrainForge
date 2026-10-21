"""Confere registro/correcao Gary e preserva falha de texto integral, sem rede."""
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-gary-insuficiencia'
spec = importlib.util.spec_from_file_location('n15_previous', ROOT / 'analisar-n15c-teses-seguimento.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)


def analyse():
    records = [previous.receipts.check_receipt(p, ROOT)
               for p in sorted(FOLDER.glob('*.evidencia.json'))]
    assert len(records) == 3
    result = {
        'date':'2026-10-08', 'niche':'N15-C', 'networkPerformed':False,
        'collectorCalls':len(records), 'usableBodies':sum(r['usable'] for r in records),
        'hashedBodies':sum(r['bodyVerified'] for r in records), 'sources':records,
        'researchClosureApproved':False, 'releaseApproved':False,
    }
    for record in records:
        if record['id'] == 'c15-gary-artigo-xml':
            assert record['status'] == 500 and not record['usable']
            result['fullTextReceived'] = False
        elif record['id'] == 'c15-gary-registro-json':
            data = json.loads(previous.body_for(record).read_text(encoding='utf-8'))
            protocol = data['protocolSection']
            assert protocol['identificationModule']['nctId'] == 'NCT01188070'
            assert protocol['designModule']['enrollmentInfo']['count'] == 354
            assert data['hasResults'] is False and 'documentSection' not in data
            result['registry'] = {
                'nctId':'NCT01188070', 'enrollmentActual':354, 'hasResults':False,
                'documentSectionPresent':False,
                'twoCaregiverPopulations':protocol['descriptionModule']['briefSummary'],
                'interventions':protocol['armsInterventionsModule']['interventions'],
                'eligibility':protocol['eligibilityModule'],
            }
        else:
            data = json.loads(previous.body_for(record).read_text(encoding='utf-8'))
            assert data['hitCount'] == 1
            correction = data['resultList']['result'][0]
            assert correction['id'] == '29708007'
            assert 'funding statement was missing' in correction['abstractText']
            result['erratum'] = {
                'pmid':correction['id'], 'doi':correction['doi'],
                'subject':'Financiamento omitido, corrigido; nao alteracao clinica/dose declarada.',
                'abstractReceived':True, 'publisherFullTextReceived':False,
            }
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    result = analyse()
    print(json.dumps({k:result[k] for k in ['collectorCalls','usableBodies','hashedBodies']}))
