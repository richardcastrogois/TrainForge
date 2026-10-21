"""Audita metadados wger locais; sem rede, download de midia ou match automatico."""
import hashlib
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent
DOCS = ROOT.parent.parent
FOLDER = ROOT / '2026-10-03/n20-instrucao-academia'
paths = [DOCS / 'planejamento/evidencias/wger-25.json',
         ROOT / 'wger-offset-300.json', ROOT / 'wger-offset-600.json']
rows = []
provenance = []
for path in paths:
    payload = path.read_bytes()
    wrapper = json.loads(payload)
    data = wrapper.get('data', wrapper)
    assert len(data['results']) == 25
    rows.extend(data['results'])
    provenance.append({'file': path.relative_to(DOCS).as_posix(),
                       'artifactSha256': hashlib.sha256(payload).hexdigest(),
                       'hashScope': 'Local stored artifact; not necessarily original HTTP byte stream'})
assert len(rows) == 75 and len({r['id'] for r in rows}) == 75
counts = {'records': len(rows),
          'portuguese': sum(any(t['language'] == 7 for t in r['translations']) for r in rows),
          'withImages': sum(bool(r['images']) for r in rows),
          'withVideos': sum(bool(r['videos']) for r in rows),
          'imagesFlaggedAi': sum(i.get('is_ai_generated', False) for r in rows for i in r['images'])}
original = json.loads((ROOT / 'wger-amostra-ampliada.json').read_text(encoding='utf-8'))
assert all(counts[k] == original['combinedUnique'][k] for k in counts)
assert any(r['id'] == 1022 for r in rows)
terms = {'row': 'row', 'benchPress': 'bench press', 'squat': 'squat',
         'chinup': 'chin', 'overheadPress': 'overhead press', 'deadlift': 'deadlift'}
candidates = {}
for target, term in terms.items():
    candidates[target] = [{'exerciseId': r['id'], 'englishNames': [
        t['name'] for t in r['translations'] if t['language'] == 2],
        'equipment': [e['name'] for e in r['equipment']], 'license': r['license'],
        'licenseAuthor': r.get('license_author'), 'images': len(r['images']),
        'videos': len(r['videos']), 'variantApproved': False}
        for r in rows if any(t['language'] == 2 and term in t['name'].casefold() for t in r['translations'])]
result = {'niche': 'N20', 'date': '2026-10-03', 'method': 'Convenience sample; lexical candidates only',
          'counts': counts, 'artifactProvenance': provenance, 'candidates': candidates,
          'semanticHoldExerciseIds': [1022], 'mediaInspectedThisRound': 0,
          'approvedMappings': 0, 'approvedAssets': 0, 'releaseApproved': False,
          'olderSpecificSuitabilityVerified': False, 'appTestsRun': False}
(FOLDER / 'amostra-instrucao.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'counts': counts, 'lexicalCandidates': {k:len(v) for k,v in candidates.items()},
                  'approvedMappings': 0, 'approvedAssets': 0}))
