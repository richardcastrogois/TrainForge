"""N04: demonstrador local do contrato OFF v3.6; sem rede ou integracao Flutter."""
from decimal import Decimal, InvalidOperation
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / '2026-09-28/n04-contrato-off'
NUTRIENTS = {'energy-kcal', 'energy-kj', 'proteins', 'carbohydrates', 'fat',
             'saturated-fat', 'sugars', 'fiber', 'salt', 'sodium', 'added-sugars'}


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def number(value):
    if value is None:
        return None
    if isinstance(value, bool):
        raise ValueError('invalid_nutrient_value')
    try:
        n = Decimal(str(value))
    except InvalidOperation as error:
        raise ValueError('invalid_nutrient_value') from error
    if not n.is_finite() or n < 0:
        raise ValueError('invalid_nutrient_value')
    return format(n, 'f')


def classify(status, body):
    if status == 429 or status is not None and status >= 500:
        return 'provider_unavailable'
    if not isinstance(body, dict):
        return 'invalid_response'
    errors = {e.get('message', {}).get('id') for e in body.get('errors', [])}
    if 'invalid_code' in errors:
        return 'invalid_code'
    if status == 404 and body.get('result', {}).get('id') == 'product_not_found':
        return 'not_found'
    if status == 200 and isinstance(body.get('products'), list):
        return 'empty' if body.get('count') == 0 and not body['products'] else 'search_results'
    if status == 200 and body.get('status') == 'success' and body.get('result', {}).get('id') == 'product_found' and isinstance(body.get('product'), dict) and not errors:
        return 'found'
    return 'invalid_response'


def nutrient(item, source, path):
    value, computed = number(item.get('value')), number(item.get('value_computed'))
    modifier = item.get('modifier')
    kind = ('computed_only' if computed is not None else 'unknown') if value is None else (
        'estimated' if source == 'estimate' or modifier == '~' else 'qualified' if modifier else 'numeric')
    return {'value': value, 'valueComputed': computed, 'valueString': item.get('value_string'),
            'unit': item.get('unit'), 'modifier': modifier, 'kind': kind, 'source': source, 'sourcePath': path}


def normalize(body):
    if classify(200, body) != 'found':
        raise ValueError('not_a_found_response')
    p = body['product']
    if p.get('code') != body.get('code'):
        raise ValueError('code_mismatch')
    if p.get('schema_version') != 1004:
        raise ValueError('unsupported_schema')
    nutrition = p.get('nutrition')
    if not isinstance(nutrition, dict) or not isinstance(nutrition.get('input_sets'), list):
        raise ValueError('missing_nutrition_projection')
    inputs = []
    for i, entry in enumerate(nutrition['input_sets']):
        base = number(entry.get('per_quantity'))
        if base is None or Decimal(base) <= 0 or entry.get('per_unit') not in ('g', 'ml'):
            raise ValueError('unsupported_nutrition_basis')
        inputs.append({'sourceIndex': i, 'source': entry.get('source'), 'sourceDescription': entry.get('source_description'),
                       'preparation': entry.get('preparation'), 'per': entry.get('per'),
                       'basisQuantity': base, 'basisUnit': entry['per_unit'],
                       'nutrients': {k: nutrient(v, entry.get('source'), f'product.nutrition.input_sets[{i}].nutrients.{k}')
                                     for k, v in entry.get('nutrients', {}).items() if k in NUTRIENTS}})
    aggregate = nutrition.get('aggregated_set', {})
    values = {}
    for k, v in aggregate.get('nutrients', {}).items():
        if k in NUTRIENTS:
            index = v.get('source_index')
            if not isinstance(index, int) or isinstance(index, bool) or not 0 <= index < len(inputs):
                raise ValueError('invalid_source_index')
            values[k] = {**nutrient(v, v.get('source'), f'product.nutrition.aggregated_set.nutrients.{k}'),
                         'sourceIndex': index, 'sourcePer': v.get('source_per')}
    return {'sourceId': 'AL02', 'apiVersion': '3.6', 'schemaVersion': p['schema_version'],
            'code': p['code'], 'nameOriginal': p.get('product_name'), 'inputSets': inputs,
            'aggregatedSet': {'per': aggregate.get('per'), 'preparation': aggregate.get('preparation'), 'nutrients': values},
            'quantityIsNotNutritionBasis': True, 'automaticMassVolumeConversion': False,
            'scope': 'Research demonstrator only; not a production adapter or approved food record'}


def main():
    records = {}
    for file in sorted(OUT.glob('*.evidencia.json')):
        meta = read(file)
        path = (OUT / meta['bodyFile']).resolve()
        assert hashlib.sha256(path.read_bytes()).hexdigest() == meta['sha256'], file.name
        records[meta['id']] = (meta, path)
    assert len(records) == 9
    def payload(name):
        return read(records[name][1])
    body = payload('off-product-nutrition-v36')
    normalized = normalize(body)
    old = read(HERE / '2026-09-27/raw/off-portugal-10.json')['products'][0]
    targeted = payload('off-brand-pingo-doce')
    spec = importlib.util.spec_from_file_location('n04_previous', HERE / 'analisar-produtos-portugal.py')
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    checks = []
    def check(name, ok):
        assert ok, name
        checks.append(name)
    def rejected(name, operation):
        try:
            operation()
        except ValueError:
            checks.append(name)
        else:
            raise AssertionError(name)
    agg = normalized['aggregatedSet']['nutrients']
    check('legacy_empty_new_nutrition_present', body['product']['nutriments'] == {} and bool(agg))
    check('identity_same_as_search', normalized['code'] == old['code'])
    check('energy_matches_v2', Decimal(agg['energy-kcal']['value']) == Decimal(str(old['nutriments']['energy-kcal_100g'])) == 42)
    check('reported_vs_computed', agg['energy-kcal']['valueComputed'] == '42.4' and agg['energy-kcal']['value'] == '42')
    check('explicit_zero_preserved', agg['fat']['value'] == '0')
    check('serving_has_explicit_volume', normalized['inputSets'][1]['basisQuantity'] == '250' and normalized['inputSets'][1]['basisUnit'] == 'ml')
    check('serving_energy_as_received', normalized['inputSets'][1]['nutrients']['energy-kcal']['value'] == '105')
    check('serving_reported_carbs_not_recomputed', normalized['inputSets'][1]['nutrients']['carbohydrates']['value'] == '27' and old['nutriments']['carbohydrates_serving'] == 26.5)
    check('estimate_is_distinct', normalized['inputSets'][2]['nutrients']['added-sugars']['kind'] == 'estimated')
    check('classification_not_scaled_as_nutrient', 'nova-group' not in agg and body['product']['nutrition']['aggregated_set']['nutrients']['nova-group']['value'] == 1.6)
    check('computed_only_not_reported', nutrient({'value_computed': 2, 'unit': 'g'}, None, 'fixture')['value'] is None)
    check('unknown_not_zero', nutrient({}, None, 'fixture')['kind'] == 'unknown')
    for value in [True, -1, 'NaN', 'Infinity', 'unknown']:
        rejected('invalid_number_' + str(value), lambda x=value: number(x))
    projected = copy.deepcopy(body)
    del projected['product']['nutrition']
    rejected('missing_projection_rejected', lambda: normalize(projected))
    future = copy.deepcopy(body)
    future['product']['schema_version'] = 9999
    rejected('unknown_schema_rejected', lambda: normalize(future))
    check('pingo_sample_country_and_brand', len(targeted['products']) == 5 and all('en:portugal' in p['countries_tags'] and 'pingo-doce' in p['brands_tags'] for p in targeted['products']))
    check('pingo_gtins_valid', all(helper.gtin_valid(p['code']) for p in targeted['products']))
    check('empty_search_observed', classify(200, payload('off-empty-search-fixture')) == 'empty')
    check('invalid_code_precedes_not_found', classify(404, payload('off-missing-product-fixture')) == 'invalid_code')
    check('checksum_valid_missing', helper.gtin_valid('9500000001232') and classify(404, payload('off-missing-valid-gtin-fixture')) == 'not_found')
    failed_brands = [b for b in ('continente', 'mimosa', 'compal') if records['off-brand-' + b][0]['status'] == 503]
    check('three_unavailable_not_absent_brands', len(failed_brands) == 3 and all(classify(503, None) == 'provider_unavailable' for b in failed_brands))
    check('malformed_not_success', classify(200, '<html>') == 'invalid_response')
    check('rate_limit_not_missing', classify(429, {}) == 'provider_unavailable')
    products = [{k: p.get(k) for k in ('code', 'product_name', 'product_name_pt', 'brands', 'brands_tags',
                                    'countries_tags', 'categories_tags', 'quantity', 'last_modified_t', 'nutriments')}
                for p in targeted['products']]
    combined = {p['code'] for p in products} | {p['code'] for p in read(HERE / '2026-09-27/raw/off-portugal-10.json')['products']}
    states = [{'evidenceId': n, 'httpStatus': records[n][0]['status'],
               'state': classify(records[n][0]['status'], payload(n) if records[n][0]['status'] != 503 else None)}
              for n in records if n != 'off-schema-changelog']
    summary = {'niche': 'N04', 'researchDate': '2026-09-28', 'researchStatus': 'in_progress', 'releaseApproved': False,
               'nutritionContractResolvedForObservedProduct': True, 'schemaVersion': 1004, 'apiVersion': '3.6',
               'httpCalls': len(records), 'http200': sum(m[0]['status'] == 200 for m in records.values()),
               'http503': len(failed_brands), 'http404NegativeFixtures': 2, 'bodyHashesVerified': len(records),
               'newProducts': len(products), 'combinedUniqueProductCodes': len(combined),
               'pingoDoceCountReportedByProvider': targeted['count'], 'unavailableBrandQueries': failed_brands,
               'checksPassed': len(checks),
               'openItems': ['Three brand strata unavailable: no measured coverage for them',
                             'Convenience samples do not establish Portuguese market coverage',
                             'Publication attribution/derived-database decisions and editorial checks remain pending',
                             'Demonstrator not integrated into Flutter/API/database; no N05 started']}
    save('contrato-nutricional.json', normalized)
    save('amostra-dirigida.json', {'sourceId': 'AL02', 'attribution': 'Open Food Facts and contributors',
                                 'databaseLicense': 'ODbL 1.0', 'contentsLicense': 'DbCL 1.0',
                                 'selection': 'Country Portugal + four planned brand strata; only Pingo Doce responded with data',
                                 'bodySha256': records['off-brand-pingo-doce'][0]['sha256'], 'records': products})
    save('estados-observados.json', {'states': states, 'syntheticFixturesAreNotMarketCoverage': True})
    save('validacao-contrato.json', {'passed': len(checks), 'checks': checks, 'scope': 'Observed API research and synthetic local edge cases; not app integration'})
    save('resumo-contrato.json', summary)
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    main()
