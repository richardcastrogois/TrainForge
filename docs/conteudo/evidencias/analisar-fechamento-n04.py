"""Fecha N04 com amostras preservadas; somente leitura de fontes locais."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / '2026-09-28/n04-fechamento'

def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

def save(name, value):
    (OUT/name).write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

def main():
    checks=[]
    def check(name, condition):
        assert condition, name
        checks.append({'name':name,'passed':True,'basis':'preserved source response'})
    metas={}
    bodies={}
    for p in sorted(OUT.glob('*.evidencia.json')):
        m=read(p); metas[m['id']]=m
        body=(p.parent/m['bodyFile']).read_bytes()
        check('SHA256 '+m['id'], hashlib.sha256(body).hexdigest()==m['sha256'])
        if m['status']==200 and m['bodyFile'].endswith('.json'):
            bodies[m['id']]=json.loads(body)
    check('Compal v2 failure retained', metas['n04-compal-final']['status']==503)
    samples=[]; strata=[]
    for brand, ident, key in [('continente','n04-continente-final','products'),('mimosa','n04-mimosa-final','products'),('compal','n04-compal-searchalicious','hits')]:
        b=bodies[ident]; rows=b[key]
        check(brand+' returns three distinct barcodes',len(rows)==3 and len({r['code'] for r in rows})==3)
        for r in rows:
            check(brand+' identity '+r['code'], isinstance(r['code'],str) and r['code'].isdigit() and bool(r.get('product_name')))
            check(brand+' country/brand '+r['code'], 'en:portugal' in r.get('countries_tags',[]) and brand in r.get('brands_tags',[]))
            samples.append({'sourceEvidence':ident+'.evidencia.json','sourcePath':key+'[code='+r['code']+']','observed':r})
        strata.append({'brand':brand,'sampleSize':len(rows),'providerReportedMatchingCount':b['count'],'responseItemsKey':key,'representativeMarketSample':False})
    prior=read(ROOT/'2026-09-27/n04-produtos-portugal/amostra-produtos.json')['records']
    pingo=read(ROOT/'2026-09-28/n04-contrato-off/amostra-dirigida.json')['records']
    check('Pingo Doce earlier stratum retained',len(pingo)==5 and all('pingo-doce' in r['brands_tags'] and 'en:portugal' in r['countries_tags'] for r in pingo))
    detail=bodies['n04-compal-product']; p=detail['product']
    hit=next(x['observed'] for x in samples if x['observed']['code']==detail['code'])
    check('Direct Compal identity matches observed search code',detail['status']=='success' and not detail['errors'] and p['code']==hit['code'] and 'en:portugal' in p['countries_tags'])
    check('v3 namespaced brand tags preserved',p['brands_tags']==['xx:compal'] and 'xx:Compal' in p['tags_sources']['brands']['packaging']['tags'])
    check('Search revision older than direct product',hit['last_modified_t']<p['last_modified_t'])
    check('Prior nutrition contract checks passed',read(ROOT/'2026-09-28/n04-contrato-off/resumo-contrato.json')['checksPassed']==27)
    combined={r['code'] for r in prior+pingo}|{x['observed']['code'] for x in samples}
    rights={'source':'Open Food Facts and contributors','sourceId':'AL02','databaseLicense':'ODbL-1.0','individualContentsLicense':'DbCL-1.0','images':'Separate CC BY-SA terms and third-party rights; N06 not evaluated',
       'licenseUrl':'https://opendatacommons.org/licenses/odbl/1-0/','termsUrl':'https://world.openfoodfacts.org/terms-of-use',
       'researchDecision':'Candidate for product lookup with attribution, provenance, freshness and unknown-data states; not approved for release',
       'attributionExample':'Dados: Open Food Facts e colaboradores. Base sob ODbL 1.0; incluir links para a fonte, produto e licença.',
       'implementationRequirements':['Keep source ID, barcode string, response/API/schema version, retrieval and modification dates, field provenance and license with each record.', 'Treat a public normalized OFF-derived catalogue as ODbL; provide the required machine-readable derived database or alterations with license notices.', 'Keep private user diaries/health data and other provider datasets independently modeled. Physical table separation alone does not settle the legal classification.', 'Do not copy brand logos or packaging images as app branding; assess image rights in N06.', 'Before release, verify attribution in screens/export and the actual database derivation/distribution. No publication approval implied.']}
    save('decisao-reutilizacao.json',rights)
    save('amostra-complementar.json',{'sourceId':'AL02','attribution':rights['source'],'databaseLicense':'ODbL-1.0','individualContentsLicense':'DbCL-1.0','scope':'Convenience sample, not Portuguese market coverage','records':samples,'directProduct':{'sourceEvidence':'n04-compal-product.evidencia.json','observed':p},'strata':strata})
    save('validacao-fechamento.json',{'checksPassed':len(checks),'checks':checks,'previousNutritionChecks':27,'networkDuringAnalysis':False})
    summary={'niche':'N04','researchDate':'2026-09-28','researchStatus':'completed_with_explicit_scope_limits','releaseApproved':False,'newCalls':len(metas),'http200':sum(m['status']==200 for m in metas.values()),'http503':sum(m['status']==503 for m in metas.values()),'bodyHashesVerified':len(metas),'newProducts':len(samples),'combinedUniqueProductCodes':len(combined),'plannedBrandsObserved':['continente','pingo-doce','mimosa','compal'],'checksPassed':len(checks),'previousNutritionChecks':27,'searchIndexStalenessObserved':True,'operationalLimit':'Compal v2 search still 503; official Search-a-licious alternative and direct v3.6 product demonstrated','remainingReleaseWork':['Market representativeness not measured; brand counts are provider-reported only','Portuguese editorial/label review and data refresh strategy','Implement attribution and derived catalogue distribution obligations','Flutter/API/database integration and operational testing not done'],'nextNiche':'N05'}
    save('resumo-fechamento.json',summary)
    print(json.dumps(summary,ensure_ascii=False))

if __name__=='__main__':
    main()
