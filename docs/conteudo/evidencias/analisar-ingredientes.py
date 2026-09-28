"""N05: contrato demonstrativo e testes locais; nao e avaliacao clinica ou integracao."""
import copy
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'2026-09-28/n05-ingredientes'
EU_LABELS={'en:gluten':'Cereais que contêm glúten','en:crustaceans':'Crustáceos','en:eggs':'Ovos','en:fish':'Peixe','en:peanuts':'Amendoins','en:soybeans':'Soja','en:milk':'Leite','en:nuts':'Frutos de casca rija','en:celery':'Aipo','en:mustard':'Mostarda','en:sesame-seeds':'Sementes de sésamo','en:sulphur-dioxide-and-sulphites':'Dióxido de enxofre e sulfitos','en:lupin':'Tremoço','en:molluscs':'Moluscos'}
GUIDE='https://food.ec.europa.eu/food-safety/campaign-2026/allergies_en'
FIELDS=['ingredients_text','ingredients_text_pt','ingredients','ingredients_tags','ingredients_analysis_tags','allergens','allergens_tags','allergens_from_ingredients','allergens_from_user','traces','traces_tags','labels','labels_tags','tags_sources','ingredients_n','unknown_ingredients_n','ingredients_percent_analysis','ingredients_with_specified_percent_n','additives_tags','data_quality_warnings_tags','data_quality_errors_tags']


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(name,value):
    (OUT/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def presence(p,key):
    if key not in p: return 'absent'
    if p[key] is None: return 'null'
    if p[key] in ('',[]): return 'empty'
    return 'present'


def tags(value):
    if value is None: return []
    if not isinstance(value,list) or any(not isinstance(x,str) or not x for x in value):
        raise ValueError('invalid_tags')
    return value


def signals(p,field):
    flat=tags(p.get(field+'_tags'))
    ts=p.get('tags_sources')
    if ts is None: ts={}
    if not isinstance(ts,dict): raise ValueError('invalid_tags_sources')
    group=ts.get(field,{})
    if not isinstance(group,dict): raise ValueError('invalid_tag_group')
    origins=[]; union=set(flat)
    for source,entry in group.items():
        if not isinstance(entry,dict): raise ValueError('invalid_tag_source')
        local=tags(entry.get('tags')); union.update(local)
        origins.append({'providerSource':source,'sourcePath':'product.tags_sources.'+field+'.'+source,'tags':local,'lastUpdatedAtSource':entry.get('last_updated_t'),'independentlyVerified':False})
    positive=sorted(union-{'en:none'})
    state=('reported_presence' if field=='allergens' else 'possible_presence_reported') if positive else 'source_claim_none' if 'en:none' in union else 'unknown'
    return {'state':state,'flatFieldPresence':presence(p,field+'_tags'),'flatTags':flat,'positiveTags':positive,'sourceNoneClaim':'en:none' in union,'conflictingNoneAndPresence':bool(positive and 'en:none' in union),'provenance':origins,'unknownOrNonEU14Tags':[t for t in positive if t not in EU_LABELS],'clinicalAbsenceConfirmed':False}


def flatten_ingredients(items,path='product.ingredients',depth=0):
    if items is None: return []
    if not isinstance(items,list) or depth>20: raise ValueError('invalid_ingredients_tree')
    result=[]
    for i,node in enumerate(items):
        if not isinstance(node,dict): raise ValueError('invalid_ingredient')
        loc=f'{path}[{i}]'
        result.append({'sourcePath':loc,'id':node.get('id'),'text':node.get('text'),'isInTaxonomy':node.get('is_in_taxonomy'),'reportedPercent':node.get('percent'),'estimatedPercent':node.get('percent_estimate'),'estimatedQuantity':node.get('quantity_estimate'),'percentMin':node.get('percent_min'),'percentMax':node.get('percent_max'),'estimatedValuesAreLabelMeasurements':False})
        result.extend(flatten_ingredients(node.get('ingredients'),loc+'.ingredients',depth+1))
    return result


def normalize(body):
    if not isinstance(body,dict) or body.get('status')!='success' or body.get('errors') or body.get('result',{}).get('id')!='product_found': raise ValueError('not_found_response')
    p=body.get('product')
    if not isinstance(p,dict): raise ValueError('invalid_product')
    if not isinstance(p.get('code'),str) or p.get('code')!=body.get('code'): raise ValueError('code_mismatch')
    if p.get('schema_version')!=1004: raise ValueError('unsupported_schema')
    for key in ('ingredients_text','ingredients_text_pt'):
        if p.get(key) is not None and not isinstance(p[key],str): raise ValueError('invalid_ingredients_text')
    pt=p.get('ingredients_text_pt'); orig=p.get('ingredients_text')
    text=pt if pt and pt.strip() else orig
    selected='ingredients_text_pt' if pt and pt.strip() else 'ingredients_text'
    return {'sourceId':'AL02','code':p['code'],'apiVersion':'3.6','schemaVersion':1004,'nameOriginal':p.get('product_name'),'lastModifiedAtSource':p.get('last_modified_t'),'fieldPresence':{k:presence(p,k) for k in FIELDS},
       'ingredientText':{'text':text,'sourcePath':'product.'+selected if text is not None else None,'languageDeclared':'pt' if selected.endswith('_pt') else p.get('lang'),'languageIndependentlyVerified':False,'state':'reported_text_unverified' if text and text.strip() else 'unknown','renderAsPlainText':True},
       'ingredientTree':copy.deepcopy(p.get('ingredients')),'ingredientNodes':flatten_ingredients(p.get('ingredients')),
       'allergens':signals(p,'allergens'),'traces':signals(p,'traces'),
       'dietLabels':{'flatTags':tags(p.get('labels_tags')),'sourcePaths':copy.deepcopy(p.get('tags_sources',{}).get('labels',{})) if isinstance(p.get('tags_sources'),dict) else {},'isClinicalCertification':False},
       'computedDietAnalysis':{'sourcePath':'product.ingredients_analysis_tags','tags':tags(p.get('ingredients_analysis_tags')),'method':'provider automated ingredient analysis; not label certification'},
       'quality':{'unrecognizedIngredientCount':p.get('unknown_ingredients_n'),'warnings':tags(p.get('data_quality_warnings_tags')),'errors':tags(p.get('data_quality_errors_tags'))},
       'clinicalSuitability':'not_assessed','canAutomaticallyDeclareSafe':False}


def main():
    checks=[]; evidences={}; bodies={}
    def check(name,ok,basis='observed source'):
        assert ok,name
        checks.append({'name':name,'passed':True,'basis':basis})
    for path in sorted(OUT.glob('*.evidencia.json')):
        m=read(path); evidences[m['id']]=m
        data=(path.parent/m['bodyFile']).read_bytes()
        check('SHA256 '+m['id'],hashlib.sha256(data).hexdigest()==m['sha256'],'integrity')
        if m['status']==200 and m['bodyFile'].endswith('.json'): bodies[m['id']]=json.loads(data)
    profiles=['milk','lactose-free','muesli','nectar','plant-based']
    normalized={}; samples=[]
    for label in profiles:
        ident='n05-'+label; b=bodies[ident]; p=b['product']; n=normalize(b); normalized[label]=n
        check(label+' found/schema/identity',n['schemaVersion']==1004 and n['code']==b['code'])
        check(label+' no safety promise',n['clinicalSuitability']=='not_assessed' and not n['canAutomaticallyDeclareSafe'])
        samples.append({'sampleProfile':label,'sourceEvidence':ident+'.evidencia.json','observed':p,'researchInterpretation':n})
    milk,lf,mu,ne,pb=[normalized[k] for k in profiles]
    check('Lactose-free claim coexists with reported milk','en:no-lactose' in lf['dietLabels']['flatTags'] and 'en:milk' in lf['allergens']['positiveTags'])
    check('Milk traces none never cancels reported milk',lf['traces']['state']=='source_claim_none' and lf['allergens']['state']=='reported_presence')
    check('Vegan classification coexists with milk trace','en:vegan' in pb['computedDietAnalysis']['tags'] and 'en:milk' in pb['traces']['positiveTags'])
    check('Milk trace does not become declared milk ingredient','en:milk' not in pb['allergens']['positiveTags'])
    check('Empty allergen list remains unknown',ne['allergens']['state']=='unknown' and ne['allergens']['flatFieldPresence']=='empty')
    check('Muesli declared allergens and traces separated','en:gluten' in mu['allergens']['positiveTags'] and set(mu['traces']['positiveTags'])=={'en:milk','en:mustard','en:peanuts','en:soybeans'})
    check('Unnormalized tag retained for review','pt:Frutos secos' in mu['allergens']['unknownOrNonEU14Tags'])
    check('Automatic unknown ingredient counts retained',mu['quality']['unrecognizedIngredientCount']==5 and milk['quality']['unrecognizedIngredientCount']==1)
    check('PT field is not proof of Portuguese content',milk['ingredientText']['text']=='Milk' and not milk['ingredientText']['languageIndependentlyVerified'])
    check('Missing Portuguese text preserved',pb['fieldPresence']['ingredients_text_pt']=='absent' and pb['ingredientText']['languageDeclared']=='en')
    oats=next(n for n in mu['ingredientNodes'] if n['id']=='en:whole-grain-oat-flakes')
    check('Reported and computed percentages kept separate',oats['reportedPercent']==45 and oats['estimatedPercent']==45.5)
    lactase=next(n for n in lf['ingredientNodes'] if n['id']=='en:lactase')
    check('Estimated lactase is not a label quantity',lactase['reportedPercent'] is None and lactase['estimatedPercent']==25 and not lactase['estimatedValuesAreLabelMeasurements'])
    check('Nested ingredients carry exact source paths',any('.ingredients[' in n['sourcePath'][len('product.ingredients'):] for n in mu['ingredientNodes']))
    check('Packaging and parsed allergen provenance separate',{o['providerSource'] for o in mu['allergens']['provenance']}=={'packaging','ingredients'})
    check('Top-level legacy fields absent in v3.6',all(n['fieldPresence']['allergens']=='absent' and n['fieldPresence']['traces']=='absent' for n in normalized.values()))
    tax=bodies['n05-off-allergens-taxonomy']; subset=[]
    for key,label in EU_LABELS.items():
        check('EU group in taxonomy '+key,key in tax and bool(tax[key].get('name',{}).get('pt')))
        subset.append({'canonicalId':key,'namePtProvider':tax[key]['name']['pt'],'displayLabelPtProposed':label,'editorialStatus':'proposed; requires Portuguese review','groupScopeSource':GUIDE})
    check('Taxonomy not equivalent to EU list',len(tax)==27 and 'en:none' in tax and len(EU_LABELS)==14)
    check('Broad nuts group must not be narrowed to walnuts',tax['en:nuts']['name']['pt']=='nozes' and EU_LABELS['en:nuts']=='Frutos de casca rija')
    seed=bodies['n05-nectar']
    for value,state in [('__remove__','absent'),(None,'null'),([], 'empty')]:
        b=copy.deepcopy(seed); p=b['product'];p.pop('tags_sources',None)
        if value=='__remove__':p.pop('allergens_tags',None)
        else:p['allergens_tags']=value
        n=normalize(b)
        check('Missing/allergen '+state,n['allergens']['state']=='unknown' and n['allergens']['flatFieldPresence']==state,'synthetic')
    b=copy.deepcopy(seed);b['product']['allergens_tags']=['en:none','en:milk'];n=normalize(b)
    check('Contradictory none plus positive preserved',n['allergens']['conflictingNoneAndPresence'] and n['allergens']['state']=='reported_presence','synthetic')
    b=copy.deepcopy(seed);b['product']['tags_sources']['allergens']={'packaging':{'tags':['en:milk']}};n=normalize(b)
    check('Positive provenance cannot disappear behind empty aggregate','en:milk' in n['allergens']['positiveTags'],'synthetic')
    b=copy.deepcopy(seed);b['product']['allergens_tags']=['en:peach','xx:unmapped'];n=normalize(b)
    check('Other personal allergens retained',n['allergens']['unknownOrNonEU14Tags']==['en:peach','xx:unmapped'],'synthetic')
    b=copy.deepcopy(seed);b['product']['ingredients_text_pt']='<script>alert(1)</script>';n=normalize(b)
    check('Untrusted text requires plain text rendering',n['ingredientText']['renderAsPlainText'] and n['ingredientText']['text'].startswith('<script>'),'synthetic; no UI execution')
    for title,key,value in [('unsupported schema','schema_version',1005),('code mismatch','code','wrong'),('malformed tags','allergens_tags','milk'),('malformed provenance','tags_sources',[]),('malformed tree','ingredients',{}),('invalid text','ingredients_text_pt',[]),('null tag element','allergens_tags',[None])]:
        b=copy.deepcopy(seed);b['product'][key]=value
        try:normalize(b)
        except ValueError:check('Reject '+title,True,'synthetic')
        else:check('Reject '+title,False,'synthetic')
    b=copy.deepcopy(seed);b['product'].pop('ingredients_text',None);b['product'].pop('ingredients_text_pt',None);b['product'].pop('ingredients',None);n=normalize(b)
    check('No ingredients text/tree never implies no allergens',n['ingredientText']['state']=='unknown' and n['ingredientNodes']==[] and not n['canAutomaticallyDeclareSafe'],'synthetic')
    check('EU original did not yield usable legal text',evidences['n05-eu-1169-pt']['status']==202,'observed HTTP response; not interpreted as law')
    save('amostra-ingredientes.json',{'sourceId':'AL02','attribution':'Open Food Facts and contributors','databaseLicense':'ODbL-1.0','individualContentsLicense':'DbCL-1.0','scope':'Five purposive profiles; research, not package verification','records':samples})
    save('grupos-alergenios.json',{'scope':'EU 14 group mapping plus provider taxonomy; not all possible allergies or executable legal exceptions','source':GUIDE,'providerTaxonomyEvidence':'n05-off-allergens-taxonomy.evidencia.json','taxonomyEntryCount':len(tax),'sentinel':'en:none is a source claim, not medical confirmation','groups':subset,'unmappedProviderIds':sorted(set(tax)-set(EU_LABELS)-{'en:none'}),'notes':['Do not infer wheat allergy equivalence from gluten claims; granular cases need label verification.', 'Sulphites thresholds/exceptions and ingredient derivatives are not encoded by this demonstrator.', 'No claim that an unchanged complete consolidated regulation was fetched; original EUR-Lex returned HTTP 202.']})
    save('validacao-ingredientes.json',{'checksPassed':len(checks),'checks':checks,'networkDuringAnalysis':False,'testScope':'Data semantics and refusal states; not UI, clinical accuracy, prevalence or certification'})
    summary={'niche':'N05','researchDate':'2026-09-28','researchStatus':'completed_with_explicit_scope_limits','releaseApproved':False,'httpCalls':len(evidences),'http200':sum(m['status']==200 for m in evidences.values()),'http202':sum(m['status']==202 for m in evidences.values()),'bodyHashesVerified':len(evidences),'productProfiles':len(samples),'providerTaxonomyEntries':len(tax),'euAllergenGroupsMapped':14,'checksPassed':len(checks),'keyFindings':['Lactose-free claim with milk allergen','Vegan analysis and milk trace coexist','Empty allergen list and en:none are not clinical absence','PT field contains English Milk and parser marks it unknown','Reported oats 45 percent differs from estimate 45.5; lactase 25 percent is estimated only','Provider Portuguese nuts translation is narrower than EU group'],'remainingReleaseWork':['Manufacturer/package verification and pt-PT editorial review','Recipes and unpackaged/home/restaurant meals need their own ingredient provenance','No automatic clinical suitability, dose threshold, contamination clearance or therapeutic diet','Implement confirmation, privacy preferences, UI, API and database later','Consolidated legal exceptions must be validated before regulatory claims'],'nextNiche':'N06'}
    save('resumo-ingredientes.json',summary); print(json.dumps(summary,ensure_ascii=False))

if __name__=='__main__':
    main()
