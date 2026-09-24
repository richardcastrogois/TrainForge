"""Resume evidencias existentes, sem rede e sem transformar amostra em censo."""
import json
import re
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parent
def data(name):
    return json.loads((ROOT / (name + '.json')).read_text(encoding='utf-8'))['data']

w = data('wger-25')['results']
exercise_rows = []
for e in w:
    en = next((t for t in e['translations'] if t['language'] == 2), {})
    pt = next((t for t in e['translations'] if t['language'] == 7), {})
    exercise_rows.append({'id':e['id'], 'name':en.get('name'), 'hasPortugueseName':bool(pt.get('name')), 'englishDescriptionChars':len(re.sub('<[^>]+>', '', en.get('description','')).strip()), 'hasPortugueseDescription':bool(re.sub('<[^>]+>','',pt.get('description','')).strip()), 'imageCount':len(e['images']), 'videoCount':len(e['videos']), 'license':e['license']['short_name'], 'authorPresent':bool(e['license_author']), 'equipmentCount':len(e['equipment']), 'imagesMarkedAi':sum(i.get('is_ai_generated') is True for i in e['images']), 'imagesMissingAuthor':sum(not i.get('license_author') for i in e['images'])})

f = data('free-exercise-db')
# Subamostra deterministica distribuida pela ordenacao do arquivo.
sample = [f[round(i * (len(f)-1) / 24)] for i in range(25)]
free_rows = [{'id':e['id'], 'name':e['name'], 'instructionsCount':len(e['instructions']), 'imagesCount':len(e['images']), 'equipment':e.get('equipment'), 'mechanic':e.get('mechanic'), 'hasPerRecordAuthor':'author' in e, 'hasPerRecordLicense':'license' in e} for e in sample]

foods = []
for q in ['rice','milk','egg']:
    for e in data('usda-'+q)['foods']:
        ns = {n['nutrientId']:n for n in e['foodNutrients']}
        foods.append({'query':q,'id':e['fdcId'],'description':e['description'],'dataType':e['dataType'],'publishedDate':e.get('publishedDate'),'nutrientCount':len(ns),'energyKcal':next((ns[k].get('value') for k in [1008,2048,2047] if k in ns),None),'proteinG':ns.get(1003,{}).get('value'),'carbohydrateG':ns.get(1005,{}).get('value'),'fatG':ns.get(1004,{}).get('value'),'hasServingSize':'servingSize' in e,'hasFoodPortions':'foodPortions' in e})

summary = {
    'date':'2026-09-22',
    'samplingLimits':'Convenience samples. Not representative of Portugal, clinical quality or uptime. Timings are single requests, not a performance benchmark.',
    'wger':{'reportedTotal':data('wger-25')['count'],'sampleSize':len(w),'portugueseName':sum(e['hasPortugueseName'] for e in exercise_rows),'portugueseDescription':sum(e['hasPortugueseDescription'] for e in exercise_rows),'withImages':sum(e['imageCount']>0 for e in exercise_rows),'withVideo':sum(e['videoCount']>0 for e in exercise_rows),'withAuthor':sum(e['authorPresent'] for e in exercise_rows),'licenses':dict(Counter(e['license'] for e in exercise_rows)),'imageAiFlags':sum(e['imagesMarkedAi'] for e in exercise_rows),'rows':exercise_rows},
    'freeExerciseDb':{'recordsInDownloadedFile':len(f),'sampleSize':len(sample),'missingEquipment':sum(e['equipment'] is None for e in free_rows),'missingMechanic':sum(e['mechanic'] is None for e in free_rows),'withPerRecordAuthor':sum(e['hasPerRecordAuthor'] for e in free_rows),'withPerRecordLicense':sum(e['hasPerRecordLicense'] for e in free_rows),'rows':free_rows},
    'usda':{'sampleSize':len(foods),'uniqueIds':len(set(e['id'] for e in foods)),'withEnergy':sum(e['energyKcal'] is not None for e in foods),'withMacros':sum(all(e[k] is not None for k in ['proteinG','carbohydrateG','fatG']) for e in foods),'withServingSize':sum(e['hasServingSize'] for e in foods),'rows':foods},
    'openFoodFacts':{'targetSampleSize':20,'received':0,'status':503,'attempts':2,'interpretation':'No coverage or completeness inference possible.'}
}
(ROOT / 'resumo-amostras.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:{kk:vv for kk,vv in v.items() if kk!='rows'} if isinstance(v,dict) else v for k,v in summary.items()},ensure_ascii=True,indent=2))
