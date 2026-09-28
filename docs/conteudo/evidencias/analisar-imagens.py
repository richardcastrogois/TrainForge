"""N06: demonstrador de seleção de imagens e auditoria de evidências, sem rede.
Não integra o app, não homologa direitos de terceiros nem reconhece alimentos.
"""
import copy
import hashlib
import json
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
from PIL import Image

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'2026-09-28/n06-imagens'
RAW=OUT.parent/'raw'

def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def save(name,v): (OUT/name).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

class TextOnly(HTMLParser):
    def __init__(self): super().__init__(convert_charrefs=True); self.parts=[]; self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in ('script','style'): self.skip+=1
    def handle_endtag(self,tag):
        if tag in ('script','style'): self.skip=max(0,self.skip-1)
    def handle_data(self,data):
        if not self.skip: self.parts.append(data)

def plain(value):
    p=TextOnly(); p.feed(value or ''); return ' '.join(' '.join(p.parts).split())

def safe_image_url(value,host='images.openfoodfacts.org'):
    if not isinstance(value,str): raise ValueError('invalid_url')
    u=urlparse(value)
    if u.scheme!='https' or u.hostname!=host or u.username or u.password or u.port not in (None,443): raise ValueError('untrusted_url')
    return value

def select_off(body,role='front',language='pt',fallback=(),size='display'):
    if body.get('status')!='success' or body.get('errors') or body.get('result',{}).get('id')!='product_found': raise ValueError('not_product_success')
    p=body.get('product',{})
    if p.get('schema_version')!=1004: raise ValueError('unknown_schema')
    code=p.get('code')
    if not isinstance(code,str) or not code.isascii() or not code.isdigit(): raise ValueError('invalid_code')
    if role not in ('front','ingredients','nutrition','packaging') or size not in ('display','small','thumb'): raise ValueError('invalid_role_or_size')
    urls=p.get('selected_images') or {}
    if not isinstance(urls,dict): raise ValueError('invalid_images')
    available=urls.get(role,{}).get(size,{})
    if not isinstance(available,dict): raise ValueError('invalid_variants')
    for lang in (language,*fallback):
        if not available.get(lang): continue
        url=safe_image_url(available[lang]); info=p.get('images',{}).get('selected',{}).get(role,{}).get(lang,{})
        imgid,rev=info.get('imgid'),info.get('rev')
        if imgid is None or rev is None or not str(imgid).isdigit() or not str(rev).isdigit(): raise ValueError('missing_revision_or_imageid')
        padded=code.zfill(13); folder='/'.join((padded[:3],padded[3:6],padded[6:9],padded[9:]))
        pixels={'display':'400','small':'200','thumb':'100'}[size]
        expected=f'https://images.openfoodfacts.org/images/products/{folder}/{role}_{lang}.{rev}.{pixels}.jpg'
        if url!=expected: raise ValueError('url_metadata_mismatch')
        upload=p.get('images',{}).get('uploaded',{}).get(str(imgid),{})
        return {'provider':'AL02','code':code,'role':role,'requestedLanguage':language,'sourceLanguage':lang,'languageFallback':lang!=language,'url':url,'imageId':str(imgid),'revision':str(rev),'sourceSize':size,'sourceDimensions':info.get('sizes',{}).get(pixels),'uploader':upload.get('uploader'),'uploadedAtSource':upload.get('uploaded_t'),'authorIndependentlyVerified':False,'sourcePath':f'product.selected_images.{role}.{size}.{lang}','sourceMetadataPath':f'product.images.selected.{role}.{lang}','productPage':'https://world.openfoodfacts.org/product/'+code,'license':'CC BY-SA 3.0','licenseUrl':'https://creativecommons.org/licenses/by-sa/3.0/','licenseEvidence':'../n04-fechamento/n04-off-reuse-terms.evidencia.json','releaseApproved':False}
    return None

def main():
    checks=[]
    def check(name,ok):
        if not ok: raise AssertionError(name)
        checks.append({'name':name,'passed':True})
    def rejects(name,call):
        try: call()
        except ValueError: check(name,True)
        else: check(name,False)
    bodies={k:read(RAW/f'n06-off-{k}.json') for k in ('leite','nectar','vegetal')}
    rows=[]
    for k,role in [('leite','front'),('leite','ingredients'),('nectar','front'),('vegetal','ingredients')]:
        v=select_off(bodies[k],role,fallback=('en',)); v['evidenceFile']=f'n06-off-{k}.evidencia.json';v['assetId']='off-'+k+'-'+role;rows.append(v)
    check('PT supera URL legada EN no rótulo vegetal',rows[3]['url'].endswith('ingredients_pt.147.400.jpg') and rows[3]['url']!=bodies['vegetal']['product']['image_ingredients_url'])
    check('Leite sem ingredientes PT permanece ausente sem fallback explícito',select_off(bodies['leite'],'ingredients') is None)
    check('Fallback conserva idioma EN e aviso',rows[1]['sourceLanguage']=='en' and rows[1]['languageFallback'])
    check('Front vegetal PT ausente sem inventar fotografia',select_off(bodies['vegetal']) is None)
    check('Miniatura usa URL 100 já declarada',select_off(bodies['nectar'],size='thumb')['url'].endswith('.100.jpg'))
    check('Revisão, imgid e uploader resolvidos com tipos int/string',rows[3]['imageId']=='20' and rows[3]['revision']=='147' and bool(rows[3]['uploader']))
    check('Papel nutrition não é substituído por front',select_off(bodies['nectar'],'nutrition')['url'].endswith('nutrition_pt.12.400.jpg'))
    for state in [None,{}]:
        b=copy.deepcopy(bodies['leite']); b['product']['selected_images']=state
        check('Ausência de imagens: '+str(state),select_off(b) is None)
    b=copy.deepcopy(bodies['leite']);b['product']['schema_version']=9999
    rejects('Schema desconhecido exige revisão',lambda:select_off(b))
    b=copy.deepcopy(bodies['leite']);b['status']='failure'
    rejects('Falha de fornecedor não é catálogo vazio',lambda:select_off(b))
    for value in ['javascript:alert(1)','https://images.openfoodfacts.org.evil.test/a.jpg','http://images.openfoodfacts.org/a.jpg','https://x@images.openfoodfacts.org/a.jpg']:
        rejects('URL rejeitada '+value,lambda value=value:safe_image_url(value))
    b=copy.deepcopy(bodies['leite']);b['product']['images']['selected']['front']['pt']['rev']='999'
    rejects('URL e revisão em conflito',lambda:select_off(b))
    b=copy.deepcopy(bodies['leite']);del b['product']['images']['selected']['front']['pt']['imgid']
    rejects('Sem imgid não atribuir uploader por engano',lambda:select_off(b))
    check('HTML de crédito vira texto; script não executável',plain('<a href="x">Ana &amp; Rui</a><script>alert(1)</script>')=='Ana & Rui')
    for kind in ('banana','arroz','prato','bacalhau'):
        for p in read(RAW/f'n06-commons-{kind}.json')['query']['pages']:
            i=p['imageinfo'][0];m=i['extmetadata'];get=lambda key:plain(m.get(key,{}).get('value',''))
            rows.append({'assetId':'commons-'+str(p['pageid']),'provider':'MI01','evidenceFile':f'n06-commons-{kind}.evidencia.json','pageId':p['pageid'],'title':p['title'],'url':i['thumburl'],'originalUrl':i['url'],'sourcePage':i['descriptionurl'],'sourceDimensions':{'w':i['width'],'h':i['height']},'reportedThumbDimensions':{'w':i['thumbwidth'],'h':i['thumbheight']},'sourceSha1Original':i['sha1'],'mime':i['mime'],'sourceTimestamp':i['timestamp'],'uploader':i['user'],'artist':get('Artist'),'credit':get('Credit'),'license':get('LicenseShortName'),'licenseUrl':get('LicenseUrl'),'attributionRequiredRaw':get('AttributionRequired'),'restrictionsRaw':get('Restrictions'),'releaseApproved':False,'authorIndependentlyVerified':False})
    audit=read(OUT/'revisao-visual.json')
    for row in rows:
        row['review']=audit['assets'][row['assetId']]
        row['attributionDraft']={'creator':row.get('artist') or ('Contribuidor OFF: '+str(row.get('uploader'))),'title':row.get('title') or row['assetId'],'source':row.get('sourcePage') or row.get('productPage'),'license':row['license'],'licenseUrl':row['licenseUrl'],'modifications':'Miniatura/seleção existente do fornecedor; nenhuma edição adicional neste estudo. Confirmar histórico antes da publicação.'}
    check('Sete itens Commons conservam licença individual',len([r for r in rows if r['provider']=='MI01' and r['license'] and r['licenseUrl'] and r['artist']])==7)
    check('Uploader não substitui autor no prato de carne',next(r for r in rows if r['assetId']=='commons-25804985')['artist'].startswith('Bernt Rostad'))
    check('Catálogo de sementes não vira alimento por resultado de busca',audit['assets']['commons-42627978']['decision']=='reject')
    check('Fotografia não estima massa/nutrientes',all(r['review']['providesMeasuredPortion'] is False for r in rows))
    hashes=[];images=[]
    for path in sorted(OUT.glob('*.evidencia.json')):
        e=read(path);body=path.parent/e['bodyFile'];measured=hashlib.sha256(body.read_bytes()).hexdigest()
        if measured!=e['sha256']:raise AssertionError('Hash incorreto '+path.name)
        hashes.append({'evidence':path.name,'status':e['status'],'sha256Matches':True})
        if body.suffix=='.jpg':
            with Image.open(body) as im: fmt=im.format;dimensions=im.size;im.verify()
            if fmt!='JPEG':raise AssertionError('Formato diferente do esperado')
            images.append({'evidence':path.name,'dimensionsDecoded':{'w':dimensions[0],'h':dimensions[1]},'format':fmt,'bytes':e['bytes'],'status':e['status']})
    check('Oito fotografias recebidas 200 e decodificáveis',len(images)==8 and all(x['status']==200 for x in images))
    save('amostra-imagens.json',{'scope':'Amostra de pesquisa; fotografias raw locais, nenhuma liberação automática de uso','assets':rows,'availability':images})
    save('validacao-imagens.json',{'networkCallsDuringAnalysis':0,'functionalChecks':checks,'hashChecks':hashes,'decodedImages':images})
    save('resumo-imagens.json',{'niche':'N06','researchStatus':'completed_for_declared_scope','date':'2026-09-28','sourceFamilies':['AL02','MI01'],'offProducts':3,'commonsFiles':7,'assetCandidates':len(rows),'preservedCalls':len(hashes),'http200':sum(x['status']==200 for x in hashes),'verifiedBodyHashes':len(hashes),'visuallyInspectedImages':len(images),'functionalChecksPassed':len(checks),'next':'N07','limits':['Amostra não é cobertura de 3484 alimentos nem catálogo completo de pratos','Direitos de terceiros e autoria não independentemente homologados','Licença/atribuição por ficheiro; CC0, CC BY e CC BY-SA não são equivalentes','Sem medição de porção, calorias ou reconhecimento por foto','Alguns idiomas ausentes e resolução insuficiente para ampliação','Sem integração no app, Figma ou banco']})
    print(json.dumps(read(OUT/'resumo-imagens.json'),ensure_ascii=False))

if __name__=='__main__':main()
