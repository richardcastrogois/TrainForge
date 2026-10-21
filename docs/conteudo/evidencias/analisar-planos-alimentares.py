"""Confere as sete tabelas do menu DASH; texto integral derivado fica no raw."""
import hashlib
import json
from pathlib import Path
import re

import pdfplumber
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n13-planos-alimentares'
RAW = FOLDER.parent / 'raw'


def load(path):
    return json.loads(path.read_text(encoding='utf-8'))


def verify(path):
    record = load(path)
    body = (path.parent / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    payload = body.read_bytes()
    assert record['status'] == 200
    assert len(payload) == record['bytes']
    assert hashlib.sha256(payload).hexdigest() == record['sha256']
    return record, body


pdf_record, pdf_path = verify(FOLDER / 'n13-dash-week.evidencia.json')
page_record, _ = verify(FOLDER / 'n13-dash-resource.evidencia.json')
rights_path = ROOT / '2026-09-29/n08-receitas/n08-nhlbi-direitos.evidencia.json'
rights_record, rights_body = verify(rights_path)
assert rights_record['url'] == 'https://www.nhlbi.nih.gov/about/contact/trademark-branding-and-logo'
assert 'no changes' in rights_body.read_text(encoding='utf-8')
reader = PdfReader(pdf_path)
assert len(reader.pages) == 8
assert reader.metadata['/Author'] == 'National Heart, Lung, and Blood Institute'

expected = [(2062, 114, 2101), (2027, 99, 2035), (1997, 103, 2114),
            (2024, 110, 2312), (1976, 111, 2373), (1939, 105, 1671), (1993, 93, 2069)]
expected_printed_row_sums = [2100, 2038, 2114, 2310, 2374, 1670, 2070]
labels = ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACKS']
days, extracted = [], []
with pdfplumber.open(pdf_path) as document:
    for index, page in enumerate(document.pages[1:], start=1):
        full_text = page.extract_text()
        assert re.search(rf'DAY {index}\b', full_text)
        # This document keeps food rows left of x=334 and substitution tips to the right.
        table_text = page.crop((90, 182, 334, 716)).extract_text()
        total_match = re.search(r'TOTAL SODIUM \(MG\) FOR DAY \d+ ([\d,]+)', table_text)
        assert total_match, index
        table_text = table_text[:total_match.start()]
        groups = []
        for label_index, label in enumerate(labels):
            header = label + ' SODIUM (MG)'
            assert header in table_text, (index, label)
            start = table_text.index(header) + len(header)
            end = table_text.index(labels[label_index + 1] + ' SODIUM (MG)') if label_index < 3 else len(table_text)
            text = table_text[start:end].strip()
            sodium_rows = [int(m.group(1)) for line in text.splitlines()
                           if (m := re.search(r'(?:^|\s)(\d+)$', line.strip()))]
            assert sodium_rows, (index, label)
            groups.append({'meal': label.lower(), 'sourceText': text,
                           'sodiumRowCount': len(sodium_rows), 'sodiumMgSum': sum(sodium_rows)})
        sodium_total = int(total_match.group(1).replace(',', ''))
        calories_match = re.search(r'([\d,]+) calories', full_text)
        protein_match = re.search(r'(\d+) g protein', full_text)
        assert calories_match and protein_match, index
        calories = int(calories_match.group(1).replace(',', ''))
        protein = int(protein_match.group(1))
        assert (calories, protein, sodium_total) == expected[index - 1]
        printed_row_sum = sum(x['sodiumMgSum'] for x in groups)
        assert printed_row_sum == expected_printed_row_sums[index - 1], index
        days.append({'day': index, 'pdfPage': index + 1,
                     'mealGroups': [{k: v for k, v in group.items() if k != 'sourceText'} for group in groups],
                     'declaredEnergyKcal': calories, 'declaredProteinG': protein,
                     'declaredSodiumMg': sodium_total, 'printedRowSodiumMgSum': printed_row_sum,
                     'sodiumDifferenceMg': printed_row_sum - sodium_total, 'individualTarget': False})
        extracted.append({'day': index, 'mealGroups': groups})

assert 'chicken and Spanish rice 341' in extracted[3]['mealGroups'][2]['sourceText']
projection = {
    'niche': 'N13', 'date': '2026-10-03', 'status': 'concluido_para_pesquisa',
    'plan': {'id': 'P13-01', 'sourceId': 'NU31', 'title': 'A Week With the DASH Eating Plan',
             'sourceUrl': pdf_record['url'], 'sha256': pdf_record['sha256'],
             'publisher': reader.metadata['/Author'], 'publicationDate': '2019-04',
             'pdfModificationDate': reader.metadata.get('/ModDate'), 'clinicalReviewDate': None,
             'audience': 'publico geral e pacientes; exemplo de alimentacao cardiovascular DASH',
             'sourceEnergyBasisKcal': 2000, 'days': days,
             'rightsEvidence': '../../2026-09-29/n08-receitas/n08-nhlbi-direitos.evidencia.json',
             'rightsDecision': 'condicional: publicacao formatada sem alteracoes; traducao e uso comercial com publicidade nao demonstrados',
             'releaseApproved': False},
    'findings': [
        {'type': 'printed_rows_differ_from_declared_total',
         'days': [day['day'] for day in days if day['sodiumDifferenceMg']],
         'differencesMg': [day['sodiumDifferenceMg'] for day in days],
         'cause': 'nao demonstrada; arredondamento e uma possibilidade, nao confirmado', 'correctionApplied': False},
        {'type': 'missing_quantity', 'day': 4, 'meal': 'dinner', 'item': 'chicken and Spanish rice', 'quantity': None},
        {'type': 'source_total_above_heading', 'days': [4, 5], 'headingSodiumMg': 2300,
         'observedSodiumMg': [2312, 2373], 'correctionApplied': False},
        {'type': 'portion_not_mass', 'finding': 'Cup, tsp, Tbsp, oz, unidade e fracao de receita nao fornecem massa universal; depende de N03.'}
    ],
    'limits': ['Texto integral extraido apenas no raw local', 'Receitas e equivalencias de produtos ainda precisam de vinculo',
               'Sem revisao profissional pt-PT ou meta individual', 'Nao escalar porcoes linearmente para prescrever dieta']
}
summary = {'niche': 'N13', 'date': '2026-10-03', 'status': 'concluido_para_pesquisa',
           'planCount': 1, 'days': 7, 'mealGroups': 28,
           'foodRows': sum(x['sodiumRowCount'] for day in days for x in day['mealGroups']),
           'dailySodiumSumsChecked': 7, 'dailySodiumSumsExactlyEqual': 1,
           'dailySodiumSumsDifferent': 6, 'calls': 2, 'http200': 2, 'bodyHashes': 2,
           'reusedRightsRecords': 1, 'rightsStatus': 'condicional', 'releaseApproved': False,
           'next': 'N14 — organizacao e personalizacao da rotina alimentar'}
for path, value in [(RAW / 'n13-dash-extracao.json', extracted),
                    (FOLDER / 'amostra-planos.json', projection),
                    (FOLDER / 'resumo-planos.json', summary)]:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
