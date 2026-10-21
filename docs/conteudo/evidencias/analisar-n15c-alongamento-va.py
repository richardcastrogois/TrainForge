"""Confere originais N15-C de alongamento/VA CARES, offline e sem prescricao."""
import argparse
import importlib.util
import json
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-08/n15c-alongamento-va'
spec = importlib.util.spec_from_file_location('previous_n15', ROOT / 'analisar-n15c-teses-seguimento.py')
previous = importlib.util.module_from_spec(spec)
spec.loader.exec_module(previous)
CHECKS = {
    'c15-jstage-alongamento-pdf': (8, {
        1: ['Toshiya Nagamatsu', 'Forty subjects', 'weekly seminar'],
        3: ['Intervention group, n = 20', 'Control group, n = 20'],
        4: ['Figure 2', 'Relax'],
        6: ['Interaction', '0.038', '0.964', '0.002'],
    }, [2, 3, 4, 6, 7]),
    'c15-va-cares-protocolo-pdf': (20, {
        1: ['NCT02106065', '06.03.20'],
        5: ['Yesavage, MD', 'Kinoshita, PhD'],
        10: ['90-minute', '3 and 9 months'],
        12: ['Appendix 4', 'MP3 download', 'deep breathing', '20 minutes'],
        13: ['progressive muscle relaxation', 'Dr. Scanlon'],
        20: ['Recruitment', 'Potential'],
    }, [5, 12, 13, 20]),
}


def analyse(render=False):
    records = [previous.receipts.check_receipt(p, ROOT)
               for p in sorted(FOLDER.glob('*.evidencia.json'))]
    assert len(records) == 4
    result = {
        'date': '2026-10-08', 'niche': 'N15-C', 'networkPerformed': False,
        'collectorCalls': len(records), 'usableBodies': sum(r['usable'] for r in records),
        'hashedBodies': sum(r['bodyVerified'] for r in records),
        'sources': records, 'pdfs': {}, 'registry': {},
        'researchClosureApproved': False, 'releaseApproved': False,
        'visualInspectionNotDeterminedByScript': True,
    }
    for record in records:
        assert record['usable'], record['id']
        body = previous.body_for(record)
        if record['id'] in CHECKS:
            count, checks, pages_to_render = CHECKS[record['id']]
            pdf = PdfReader(body)
            assert len(pdf.pages) == count
            texts = [p.extract_text() or '' for p in pdf.pages]
            for number, anchors in checks.items():
                normalized = ' '.join(texts[number - 1].split()).casefold()
                for anchor in anchors:
                    assert anchor.casefold() in normalized, (record['id'], number, anchor)
            result['pdfs'][record['id']] = {
                'pages': count, 'allPagesTextExtracted': True,
                'pageTextLengths': [len(t) for t in texts],
                'anchorChecks': checks, 'renderedPages': [],
            }
            if render:
                import pypdfium2 as pdfium
                with pdfium.PdfDocument(body) as doc:
                    for number in pages_to_render:
                        page = doc[number - 1]
                        try:
                            bitmap = page.render(scale=1.5)
                            try:
                                bitmap.to_pil().save(body.with_name(f'{record["id"]}-p{number}.png'))
                            finally:
                                bitmap.close()
                        finally:
                            page.close()
                result['pdfs'][record['id']]['renderedPages'] = pages_to_render
        elif record['id'] == 'c15-va-cares-registro-json':
            data = json.loads(body.read_text(encoding='utf-8'))
            protocol = data['protocolSection']
            assert protocol['identificationModule']['nctId'] == 'NCT02106065'
            assert data['hasResults'] is True
            outcomes = data['resultsSection']['outcomeMeasuresModule']['outcomeMeasures']
            assert len(outcomes) == 4
            assert 'analyses' not in outcomes[0]
            result['registry'] = {
                'nctId': 'NCT02106065', 'hasResults': True,
                'enrollment': protocol['designModule']['enrollmentInfo']['count'],
                'flow': data['resultsSection']['participantFlowModule'],
                'outcomes': outcomes,
                'adverseEvents': data['resultsSection']['adverseEventsModule'],
                'documents': data['documentSection']['largeDocumentModule']['largeDocs'],
                'pValueForPrimaryOutcomePublished': False,
                'isolatedRelaxationEffectEstablished': False,
            }
    (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render', action='store_true')
    result = analyse(parser.parse_args().render)
    print(json.dumps({k: result[k] for k in ['collectorCalls', 'usableBodies', 'hashedBodies']}))
