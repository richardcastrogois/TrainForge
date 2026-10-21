"""Resolve the caregiver research catalogue offline; never approve or assemble a workout."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CATALOGUE = ROOT / 'catalogo-cuidadores.json'
FIELDS = {'practitioner', 'citationAndVersion', 'professionalAuthorship', 'eligibility',
          'careWorkloadAndFatigue', 'compatibleSetting', 'initialPreparation', 'materials',
          'dose', 'sequence', 'progression', 'ending', 'instructions', 'stopAndReturn',
          'clinicalClaim', 'visualAssets', 'rightsPerAsset', 'publicationState'}


def bounded_path(relative, base=ROOT, boundary=ROOT):
    path = (base / relative).resolve()
    if not path.is_relative_to(boundary.resolve()):
        raise ValueError('Reference outside documentation boundary')
    return path


def pointer(document, path):
    if path == '':
        return document
    if not path.startswith('/'):
        raise ValueError('Invalid JSON pointer')
    current = document
    for part in path[1:].split('/'):
        key = part.replace('~1', '/').replace('~0', '~')
        current = current[int(key)] if isinstance(current, list) else current[key]
    return current


def load_catalogue():
    return json.loads(CATALOGUE.read_text(encoding='utf-8'))


def selected_library(catalogue=None):
    """Read the explicit current selection without changing historical candidate gates."""
    catalogue = load_catalogue() if catalogue is None else catalogue
    selection = catalogue.get('currentSelection')
    if not selection:
        return None
    library = json.loads(bounded_path(selection['file']).read_text(encoding='utf-8'))
    audit = json.loads(bounded_path(selection['audit']).read_text(encoding='utf-8'))
    identifiers = [item['id'] for item in library['components']]
    if len(set(identifiers)) != len(identifiers) or len(identifiers) != selection['selectedComponents']:
        raise ValueError('Current library component identity/count mismatch')
    if any(item['group'] not in library['sourceGroups'] for item in library['components']):
        raise ValueError('Current component has no source group')
    if any(doc.get('releaseApproved') or doc.get('appImplemented') for doc in (library, audit)):
        raise ValueError('Current research library cannot approve publication or implementation')
    if selection['researchClosed'] != audit['researchClosed']:
        raise ValueError('Current selection disagrees with its scoped audit')
    if audit['researchClosed'] and not all(row['met'] for row in audit['criteria']):
        raise ValueError('Current selection has an unmet research criterion')
    return {'file':selection['file'], 'audit':selection['audit'],
            'researchClosed':audit['researchClosed'], 'selectedComponents':len(identifiers),
            'allFiveOriginalProgrammesExecutable':library['allFiveOriginalProgrammesExecutable'],
            'releaseApproved':False, 'appImplemented':False, 'library':library}


def validate(catalogue=None):
    catalogue = load_catalogue() if catalogue is None else catalogue
    if catalogue['releaseApproved'] or catalogue['appImplemented'] or catalogue['researchClosureApproved']:
        raise ValueError('Documentary consolidation cannot silently approve publication or niche closure')
    cache = {}
    receipts = {}
    resolved = []
    identifiers = set()
    source_identifiers = set()

    def load(relative):
        if relative not in cache:
            cache[relative] = json.loads(bounded_path(relative).read_text(encoding='utf-8'))
        return cache[relative]

    execution_rows = {}
    audit_reference = catalogue.get('executionContentAudit')
    if audit_reference:
        execution_audit = load(audit_reference)
        if execution_audit['releaseApproved'] or execution_audit['appImplemented']:
            raise ValueError('Execution research audit cannot approve publication or implementation')
        for row in execution_audit['items']:
            if row['id'] in execution_rows:
                raise ValueError('Duplicate execution audit item')
            if row['releaseApproved']:
                raise ValueError('Execution research row cannot approve publication')
            closed = row['instructionGateMetForDocumentedPath'] and row['useGateMetForDocumentedResearchAssets']
            if closed != row['executableResearchClosedInDeclaredPath']:
                raise ValueError('Execution audit closure must match both research gates')
            if closed and any(not question['resolved'] for question in row['remainingSourceResearch']):
                raise ValueError('Execution closure still has unresolved source questions')
            execution_rows[row['id']] = row
        if set(execution_rows) != {item['id'] for item in catalogue['items']}:
            raise ValueError('Execution audit must cover exactly the catalogue items')

    for item in catalogue['items']:
        if item['id'] in identifiers or item['sourceId'] in source_identifiers:
            raise ValueError('Duplicate catalogue item or programme family')
        identifiers.add(item['id'])
        source_identifiers.add(item['sourceId'])
        if item['releaseApproved'] or item['appImplemented'] or item['syntheticProgrammeCreated']:
            raise ValueError('Unapproved item cannot be presented as implemented or synthetic workout')
        if item['publicationState'] != 'pendente' or not item['blockingReasons']:
            raise ValueError('Pending publication needs explicit outstanding requirements')
        if set(item['fields']) != FIELDS:
            raise ValueError('Item must map all 18 documentary fields')
        for source in item['sources'].values():
            actual = pointer(load(source['file']), source['sourceIdPointer'])
            if actual != item['sourceId']:
                raise ValueError('Source belongs to a different programme family')
        if item.get('researchItemClosed'):
            package = load(item['sources']['focal']['file'])
            if not package['researchItemClosed'] or package['releaseApproved'] or package['appImplemented']:
                raise ValueError('Research closure must match its scoped factual package, not publication')

        def resolve(reference):
            alias, path = reference.split('#', 1)
            source = item['sources'][alias]
            value = pointer(load(source['file']), path)
            return {'file':source['file'], 'pointer':path, 'value':value}

        evidence_fields = {name:[resolve(ref) for ref in refs] for name, refs in item['fields'].items()}
        for component in item['components']:
            if component['standaloneClaimApproved']:
                raise ValueError('A programme result cannot silently validate an isolated component')
            for ref in component['sourceRefs']:
                resolve(ref)
        for relative in item['receipts']:
            receipt = load(relative)
            if receipt['status'] != 200 or receipt.get('error') or not receipt.get('bytes'):
                raise ValueError('Selected receipt has no usable primary body')
            record_path = bounded_path(relative)
            body_path = bounded_path(receipt['bodyFile'], record_path.parent, ROOT / 'evidencias')
            body = body_path.read_bytes()
            if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                raise ValueError('Selected primary body integrity mismatch')
            receipts[relative] = {key:receipt.get(key) for key in ('id', 'url', 'resolvedUrl', 'collectedAtUtc', 'status', 'bytes', 'sha256', 'bodyFile')}
        row = execution_rows.get(item['id'])
        if audit_reference and (row is None or row['sourceId'] != item['sourceId']):
            raise ValueError('Execution audit belongs to a different programme family or lacks item')
        resolved.append({'id':item['id'], 'sourceId':item['sourceId'], 'title':item['title'],
                         'researchItemClosed':item.get('researchItemClosed', False),
                         'researchClosureScope':item.get('researchClosureScope'),
                         'executionContentAudit':{'file':audit_reference, 'item':row} if row else None,
                         'publicationState':item['publicationState'], 'releaseApproved':False,
                         'blockingReasons':item['blockingReasons'], 'fields':evidence_fields})
    components = [c for i in catalogue['items'] for c in i['components']]
    return {'catalogue':CATALOGUE.name, 'date':catalogue['date'], 'items':len(resolved),
            'mappedFields':len(resolved)*len(FIELDS), 'readingFiles':len({s['file'] for i in catalogue['items'] for s in i['sources'].values()}),
            'verifiedPrimaryReceipts':len(receipts),
            'exerciseOrTechniqueComponentsIndexed':sum(c['type']=='exercise_or_technique' for c in components),
            'programmePhasesIndexed':sum(c['type']=='programme_phase_not_executable_exercise' for c in components),
            'publishedItems':0, 'syntheticProgrammes':0, 'networkCalls':0,
            'researchClosedItems':sum(i.get('researchItemClosed', False) for i in catalogue['items']),
            'executionAuditChecked':bool(audit_reference),
            'executableResearchClosedItems':sum(row['executableResearchClosedInDeclaredPath'] for row in execution_rows.values()),
            'researchClosureApproved':False, 'appImplemented':False,
            'currentSelection':{key:value for key,value in (selected_library(catalogue) or {}).items() if key != 'library'},
            'historicalCatalogueClosureIsCurrentNicheClosure':False,
            'resolvedItems':resolved, 'receiptAudit':receipts}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--item', help='Print an item and its exact offline source fields')
    parser.add_argument('--write-audit', action='store_true')
    parser.add_argument('--biblioteca', action='store_true', help='Read the current selected library; not the five historical programmes')
    args = parser.parse_args()
    result = validate()
    if args.write_audit:
        output = ROOT / 'evidencias/2026-10-12/n15c-catalogo-modular'
        output.mkdir(parents=True, exist_ok=True)
        compact = {key:value for key,value in result.items() if key != 'resolvedItems'}
        compact['catalogueSha256'] = hashlib.sha256(CATALOGUE.read_bytes()).hexdigest()
        (output / 'verificacoes.json').write_text(json.dumps(compact, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    if args.biblioteca:
        print(json.dumps(selected_library(), ensure_ascii=False, indent=2))
    elif args.item:
        chosen = next((item for item in result['resolvedItems'] if item['id']==args.item), None)
        if chosen is None:
            parser.error('Unknown item: '+args.item)
        print(json.dumps(chosen, ensure_ascii=False, indent=2))
    else:
        print(json.dumps({key:value for key,value in result.items() if key not in ('resolvedItems','receiptAudit')}, ensure_ascii=False))
