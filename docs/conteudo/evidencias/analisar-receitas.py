"""Analise N08 local. Nao faz rede; corpos e receitas completas ficam em raw ignorado.
Os JSONs versionados sao projecoes de pesquisa, nao respostas de uma API do TrainForge.
"""
import hashlib
import json
import re
from html import unescape
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HERE = ROOT / '2026-09-29/n08-receitas'
RAW = HERE.parent / 'raw'
checks = []

def check(name, condition):
    checks.append({'check': name, 'passed': bool(condition)})
    if not condition:
        raise AssertionError(name)

def clean(value):
    return re.sub(r'\s+', ' ', unescape(re.sub(r'<[^>]+>', ' ', value))).strip()

def read(ident):
    meta = json.loads((HERE / (ident + '.evidencia.json')).read_text(encoding='utf-8'))
    body = (HERE / meta['bodyFile']).read_bytes()
    check(ident + ': original response hash', hashlib.sha256(body).hexdigest() == meta['sha256'])
    return meta, body.decode('utf-8')

def section_list(html, title, tag):
    block = re.search(r'<h[23][^>]*>' + re.escape(title) + r'</h[23]>\s*<' + tag + r'[^>]*>(.*?)</' + tag + '>', html, re.S)
    if not block:
        raise ValueError('Missing section: ' + title)
    return [clean(x) for x in re.findall(r'<li[^>]*>(.*?)</li>', block[1], re.S)]

def ld_recipes(html):
    rows = []
    for blob in re.findall(r'<script[^>]+type="application/ld\+json"[^>]*>(.*?)</script>', html, re.S):
        obj = json.loads(blob)
        rows.extend(obj.get('@graph', [obj]) if isinstance(obj, dict) else obj)
    return [x for x in rows if x.get('@type') == 'Recipe']

def base(ident, source_id, name, rights):
    meta, html = read(ident)
    check(ident + ': HTTP and HTML', meta['status'] == 200 and 'text/html' in meta['contentType'])
    return {'id': ident, 'sourceId': source_id, 'name': name, 'sourceUrl': meta['url'],
            'evidenceFile': ident + '.evidencia.json', 'originalResponseSha256': meta['sha256'],
            'access': 'GET HTML publico; nao e API REST de receitas', 'rightsDecision': rights,
            'releaseApproved': False, 'clinicalSuitability': None, 'photoReuseApproved': False,
            'finalCookedBatchMassG': None, 'ptPTReviewed': False}, html

records, full = [], []
for ident, name, count, steps, servings in [
    ('n08-nhlbi-bacalhau', 'Braised Cod With Leeks', 9, 4, 4),
    ('n08-nhlbi-lentilhas', 'Lentil Soup', 12, 5, 11),
    ('n08-nhlbi-maca', 'Apple Coffee Cake', 10, 5, 20),
]:
    row, html = base(ident, 'NU03', name, 'condicional: politica institucional, adaptacao/publicidade e midia separadas')
    ingredients = section_list(html, 'Ingredients', 'ul')
    directions = section_list(html, 'Directions', 'ol')
    pairs = {clean(k): clean(v) for k, v in re.findall(r'<tr>\s*<th>(.*?)</th>\s*<td>(.*?)</td>\s*</tr>', html, re.S)}
    check(ident + ': ingredient count', len(ingredients) == count)
    check(ident + ': instructions present', len(directions) >= steps)
    check(ident + ': yield', pairs.get('Yields') == str(servings) + ' servings')
    row.update(format='HTML h2 + ul/ol + th/td; sem Recipe JSON-LD', ingredientCount=len(ingredients),
               instructionCount=len(directions), ingredientExample=ingredients[0], declaredValues=pairs,
               recipeSource=clean(re.search(r'Recipe Source:\s*<em>(.*?)</em>', html, re.S)[1]),
               missing=['individual_author', 'allergen_declaration', 'food_ids', 'full_micronutrients', 'cooked_batch_mass'])
    full.append({'id': ident, 'ingredients': ingredients, 'instructions': directions})
    records.append(row)

for ident, name, count, steps in [
    ('n08-nhs-aveia', 'Easy overnight oats recipe', 8, 3),
    ('n08-nhs-salmao', 'Salmon and broccoli pasta recipe', 11, 6),
    ('n08-nhs-chilli', 'Tasty vegetarian chilli recipe', 12, 3),
]:
    row, html = base(ident, 'NU14', name, 'incompativel_zero: termos especificos exigem licenca comercial')
    data = ld_recipes(html)[0]
    directions = section_list(html, 'Method', 'ol')
    nutrition_html = re.search(r'<details[^>]*>.*?Nutritional information(.*?)</details>', html, re.S)[1]
    check(ident + ': ingredient count', len(data['recipeIngredient']) == count)
    check(ident + ': directions count', len(directions) == steps)
    check(ident + ': per serving explicitly present', 'Per serving' in clean(nutrition_html))
    row.update(format='HTML + script application/ld+json @type Recipe',
               observedJsonKeys=list(data), ingredientCount=count, instructionCount=len(directions),
               ingredientExample=data['recipeIngredient'][0], publisher=data['publisher'],
               declaredValues={k: data.get(k) for k in ['recipeYield','prepTime','cookTime','totalTime','nutrition','suitableForDiet']},
               visibleNutrition=[clean(x) for x in re.findall(r'<li[^>]*>(.*?)</li>',nutrition_html,re.S)],
               missing=['food_ids', 'ingredient_grams_for_each_unit', 'cooked_batch_mass', 'individual_author', 'allergen_verification'])
    full.append({'id': ident, 'recipeJsonLd': data, 'instructionsFromHtml': directions})
    records.append(row)

row, html = base('n08-dgs-bacalhau', 'NU01', 'Canelone de bacalhau', 'referencia: licenca comercial aberta nao demonstrada')
ing_block = re.search(r'<ul class="list-ingredients[^>]*>(.*?)</ul>', html, re.S)[1]
# HTML da DGS usa varios <li> sem fechamento; separar marcadores, ignorar vazios.
ings = [clean(x) for x in re.split(r'<li[^>]*>', ing_block) if clean(x)]
dirs = re.search(r'<h2>Orienta.*?</h2>(.*?)<h', html, re.S)[1]
steps = [clean(x) for x in re.findall(r'<p[^>]*>(.*?)</p>',dirs,re.S)]
check('DGS: 15 ingredients despite malformed li', len(ings) == 15)
check('DGS: instructions present', len(steps) >= 5)
check('DGS: 164 kcal belongs to chickpeas, not recipe', '164 kcal por 100g' in clean(html))
row.update(format='HTML de receita; JSON-LD Article, nao Recipe', ingredientCount=len(ings),instructionCount=len(steps),
           ingredientExample=ings[0], declaredValues={'servings':4,'timeMinutes':30,'dateModified':'2020-01-30','recipeEnergyKcal':None},
           missing=['recipe_nutrients','reviewer_named','reuse_permission','cooked_batch_mass'])
full.append({'id':row['id'],'ingredients':ings,'instructions':steps});records.append(row)

row, html = base('n08-medline-lentilhas','NU15','Lentil Confetti Salad','candidato texto: Healthy recipes explicitamente em dominio publico na politica MedlinePlus; imagens separadas')
ing = section_list(html,'Ingredients','ul'); steps = section_list(html,'Directions','ol')
check('Medline: complete human recipe', len(ing)==11 and len(steps)==7)
text = clean(html)
check('Medline: serving mass and calories observed', '2/3 cup (140g)' in text and 'Calories 160' in text)
check('Medline: preserve protein as published, no correction guessed', 'Protein 1g' in text)
row.update(format='HTML h3 + ul/ol e .mp-nutrition; sem Recipe JSON-LD',ingredientCount=11,instructionCount=7,
           ingredientExample=ing[0],publisher='MedlinePlus / National Library of Medicine',creditedProvider='Food Hero / Oregon State University',
           declaredValues={'servings':6,'servingSize':'2/3 cup (140g)','energyKcal':160,'proteinG':1,'carbohydrateG':22,'fatG':6,'saturatedFatG':0.5,'fiberG':5,'sugarsG':4,'addedSugarsG':0,'sodiumMg':400,'potassiumMg':289,'prepMinutes':15,'cookMinutes':20,'totalMinutes':35},
           missing=['individual_reviewer','cooked_batch_mass','allergen_verification','pt_PT_localisation'],
           reviewFlags=['Protein 1g e o retorno literal: conferir composicao antes de usar em metas; nao corrigir por palpite.','Direcoes na pagina do autor sao outra versao, com oito passos; nao fundir silenciosamente.'])
full.append({'id':row['id'],'ingredients':ing,'instructions':steps});records.append(row)

meta, html = read('n08-foodhero-lentilhas'); data=ld_recipes(html)[0]
check('Food Hero: JSON-LD ingredients is a concatenated string, not array', isinstance(data['recipeIngredient'],str))
check('Food Hero: JSON-LD instructions fragmented on commas', len(data['recipeInstructions'])==6)
comparison={'evidenceFile':'n08-foodhero-lentilhas.evidencia.json','authorDeclared':data['author'],
            'sameDishAs':'n08-medline-lentilhas','distinctRecipeCountIncrement':0,'yieldDeclared':data['recipeYield'],
            'jsonLdIngredientType':'string_concatenada','jsonLdInstructionCount':len(data['recipeInstructions']),
            'visibleInstructionCount':8,'nutritionJsonLd':data['nutrition'],
            'decision':'Nao usar array fragmentado como sequencia; comparar HTML. Direitos do MedlinePlus nao se transferem automaticamente ao site Food Hero.'}

byid={x['id']:x for x in records}
check('Apple cake: absent protein remains absent', 'Protein' not in byid['n08-nhlbi-maca']['declaredValues'])
check('NHS: JSON-LD omits fibre although HTML contains it', 'fiberContent' not in byid['n08-nhs-chilli']['declaredValues']['nutrition'] and '12g fibre' in byid['n08-nhs-chilli']['visibleNutrition'])
check('NHS: totalTime 10 minutes does not cover overnight wait', byid['n08-nhs-aveia']['declaredValues']['totalTime']=='PT10M' and 'overnight' in full[3]['recipeJsonLd']['recipeInstructions'])
check('Recipe amount != consumed serving count', all(x['finalCookedBatchMassG'] is None for x in records))
check('No source declaration is clinical approval', all(not x['releaseApproved'] and x['clinicalSuitability'] is None for x in records))

policy = {}
for ident in ['n08-nhlbi-direitos','n08-nhs-termos','n08-nhs-campanha-termos','n08-nhs-excecoes','n08-medline-direitos','n08-themealdb-termos','n08-ogl-v3']:
    meta, html = read(ident); policy[ident]=clean(html)
check('NHS subsite requires commercial licence', 'commercial purposes without obtaining a licence' in policy['n08-nhs-campanha-termos'])
check('NHS general OGL cannot override exception', 'Change4Life' in policy['n08-nhs-excecoes'])
check('Medline explicitly includes healthy recipes in public domain block', 'Healthy recipes' in policy['n08-medline-direitos'].split('Copyrighted content')[0])
check('NHLBI asks no alterations to formatted publications', 'no changes be made' in policy['n08-nhlbi-direitos'])
check('TheMealDB app store paid condition', 'cannot publish apps to an appstore unless you are a paid subscriber' in policy['n08-themealdb-termos'])

calls=[]
for p in sorted(HERE.glob('*.evidencia.json')):
    meta=json.loads(p.read_text(encoding='utf-8')); b=(HERE/meta['bodyFile']).read_bytes()
    if hashlib.sha256(b).hexdigest()!=meta['sha256']: raise ValueError('Hash mismatch '+p.name)
    calls.append(meta)
check('Two failure responses never counted as recipe data', sorted(x['id'] for x in calls if x['status']!=200)==['n08-fns-receitas','n08-foodhero-criterios'])

projection={'schemaVersion':1,'scope':'Oito receitas distintas, nove paginas de receita; amostra de conveniencia, nao catalogo aprovado',
            'notice':'Campos normalizados pela pesquisa. Textos completos preservados somente no raw local; nenhum corpus comercial importado.',
            'recipes':records,'sourceVersionComparison':comparison}
(HERE/'amostra-receitas.json').write_text(json.dumps(projection,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(RAW/'n08-receitas-extraidas.json').write_text(json.dumps(full,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
summary={'niche':'N08','date':'2026-09-29','researchStatus':'concluido_no_recorte','releaseApproved':False,
         'distinctRecipes':len(records),'recipePages':9,'calls':len(calls),'http200':sum(x['status']==200 for x in calls),
         'bodyHashesVerified':len(calls),'checksPassed':len(checks),'checks':checks,
         'candidateForTextPilot':'MedlinePlus Healthy recipes; uma receita completa demonstrada, sem aprovacao de traducao/nutrientes individuais',
         'remaining':['Lote de lancamento e localizacao pt-PT revisados','Validacao nutricional e alergénios por ingrediente/versao','Direitos das fotografias','Politica de adaptacao/monetizacao por fornecedor','Nenhuma API de receitas homologada; dados foram obtidos em HTML','Planos alimentares completos pertencem a N13'],
         'sourceFields':'amostra-receitas.json','next':'N09'}
(HERE/'resumo-receitas.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['checks','remaining']},ensure_ascii=False))
