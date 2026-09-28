"""N04: amostra inicial de produtos OFF, sem rede ou integracao no app."""
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / '2026-09-27/n04-produtos-portugal'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(name, data):
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def gtin_valid(code):
    if not isinstance(code, str) or not code.isascii() or not code.isdigit() or len(code) not in (8, 12, 13, 14):
        return False
    checksum = sum(int(n) * (3 if i % 2 == 0 else 1) for i, n in enumerate(reversed(code[:-1])))
    return (10 - checksum % 10) % 10 == int(code[-1])


def main():
    bodies = {}
    hashes = {}
    for name in ('off-api-guide', 'off-license-guide', 'off-portugal-10', 'off-product-observed'):
        meta = read(OUT / (name + '.evidencia.json'))
        body = (OUT / meta['bodyFile']).resolve()
        assert meta['status'] == 200 and not meta.get('error'), name
        hashes[name] = hashlib.sha256(body.read_bytes()).hexdigest()
        assert hashes[name] == meta['sha256'], name
        bodies[name] = body
    search = read(bodies['off-portugal-10'])
    detail = read(bodies['off-product-observed'])
    products = search['products']
    assert len(products) == search['page_count'] == search['page_size'] == 10
    assert len({p['code'] for p in products}) == 10
    assert all('en:portugal' in p['countries_tags'] for p in products)
    assert detail['status'] == 'success' and detail['result']['id'] == 'product_found' and not detail['errors']
    assert detail['code'] == detail['product']['code'] == products[0]['code']
    keys = ['code', 'product_name', 'product_name_pt', 'brands', 'lang', 'quantity',
            'product_quantity', 'product_quantity_unit', 'serving_size', 'serving_quantity',
            'serving_quantity_unit', 'nutrition_data_per', 'last_modified_t']
    nutrients = ['energy-kcal_100g', 'energy-kcal_serving', 'energy-kcal_unit', 'proteins_100g',
                 'proteins_unit', 'carbohydrates_100g', 'carbohydrates_unit', 'fat_100g', 'fat_unit']
    records = []
    for product in products:
        row = {k: product.get(k) for k in keys}
        row['countryFilterMatched'] = 'en:portugal' in product['countries_tags']
        row['gtinChecksumValid'] = gtin_valid(product['code'])
        row['missingRequestedFields'] = [k for k in keys if k not in product]
        row['nutrimentsSelectedAsReceived'] = {k: product.get('nutriments', {}).get(k) for k in nutrients}
        records.append(row)
    sample = {'sourceId': 'AL02', 'source': 'Open Food Facts and contributors',
              'databaseLicense': 'ODbL 1.0', 'individualContentsLicense': 'DbCL 1.0',
              'scope': 'Research only; convenient first page sorted by unique_scans_n, not representative of Portugal',
              'sourceEvidence': 'off-portugal-10.evidencia.json', 'bodySha256': hashes['off-portugal-10'],
              'providerReportedMatchingCount': search['count'], 'records': records}
    comparison = {'code': detail['code'], 'searchApi': 'v2', 'detailApi': 'v3.6',
                  'searchNutrimentKeys': sorted(products[0].get('nutriments', {})),
                  'searchEnergyKcal100g': products[0].get('nutriments', {}).get('energy-kcal_100g'),
                  'detailNutrimentsAsReceived': detail['product'].get('nutriments'),
                  'detailStatus': detail['status'], 'detailResult': detail['result'],
                  'identityMatches': all(products[0].get(k) == detail['product'].get(k) for k in ('code', 'brands', 'product_name')),
                  'causeOfNutrientDifference': 'Not established; do not infer that nutrients are absent from the source',
                  'nextInvestigation': 'Check nutrition schema/version/fields mapping before a new bounded detail request'}
    summary = {'niche': 'N04', 'date': '2026-09-27', 'researchStatus': 'in_progress', 'releaseApproved': False,
               'httpCalls': 4, 'http200': 4, 'bodyHashesVerified': 4, 'productsSampled': len(products),
               'providerReportedMatchingCount': search['count'], 'uniqueCodes': len({p['code'] for p in products}),
               'allCountryFilterMatches': True, 'gtinChecksumsValid': sum(x['gtinChecksumValid'] for x in records),
               'nonemptyPortugueseNames': sum(bool(p.get('product_name_pt', '').strip()) for p in products),
               'nonemptyBrands': sum(bool(p.get('brands', '').strip()) for p in products),
               'withServingQuantity': sum(p.get('serving_quantity') is not None for p in products),
               'sampleNumericEnergyKcal100g': sum(isinstance(p.get('nutriments', {}).get('energy-kcal_100g'), (int, float)) for p in products),
               'detailIdentityVerified': comparison['identityMatches'], 'detailNutritionCompatible': False,
               'openItems': ['Explain and verify v2 search/v3.6 detail nutrition difference',
                             'Measure brand/category coverage with a justified Portuguese sample; first page is biased',
                             'Validate missing code, empty results and provider errors in a future adapter',
                             'Decide attribution/share-alike treatment before production; no rights approval from this sample'],
               'nextNicheStarted': False}
    save('amostra-produtos.json', sample)
    save('comparacao-v2-v3.json', comparison)
    save('resumo-produtos.json', summary)
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    main()
