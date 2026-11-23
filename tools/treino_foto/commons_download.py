import json,urllib.request,urllib.parse,os,sys,hashlib,re,time,concurrent.futures as cf
OUT=sys.argv[1]; ROOT=sys.argv[2] if len(sys.argv)>2 else 'Category:Cuisine of Brazil'; DEPTH=int(sys.argv[3]) if len(sys.argv)>3 else 4
os.makedirs(os.path.join(OUT,'img'),exist_ok=True)
UA={'User-Agent':'TrainForgeDatasetResearch/1.0 (offline food photo research)'}
API='https://commons.wikimedia.org/w/api.php?'
def api(p):
    p.update(format='json',formatversion=2)
    for a in range(5):
        try: return json.load(urllib.request.urlopen(urllib.request.Request(API+urllib.parse.urlencode(p),headers=UA),timeout=60))
        except Exception: time.sleep(2+a*3)
    return {}
seen=set(); files={}  # title -> category
q=[(ROOT,0)]
while q:
    cat,d=q.pop(0)
    if cat in seen or len(seen)>=1500: continue
    if re.search(r'(?i)restaurant|people|chef|logo|market|shop|store|company|brand|festival|event|book|map',cat): continue
    seen.add(cat); cont={}
    if len(seen)%100==0: print('cat',len(seen),'arq',len(files),flush=True)
    while True:
        r=api({'action':'query','list':'categorymembers','cmtitle':cat,'cmtype':'subcat|file','cmlimit':500,**cont})
        for m in r.get('query',{}).get('categorymembers',[]):
            if m['ns']==14 and d<DEPTH: q.append((m['title'],d+1))
            elif m['ns']==6 and re.search(r'\.(jpe?g|png|webp)$',m['title'],re.I): files.setdefault(m['title'],cat)
        if 'continue' not in r: break
        cont=r['continue']
print('categorias',len(seen),'arquivos',len(files),flush=True)
OK=re.compile(r'^(cc0|cc[ -]?by[ -]?\d(\.\d)?( [a-z]+)?|public domain|pd.*)$',re.I)
keep=[]; titles=list(files)
for i in range(0,len(titles),50):
    r=api({'action':'query','prop':'imageinfo','titles':'|'.join(titles[i:i+50]),'iiprop':'url|extmetadata|size|mime','iiurlwidth':640})
    for pg in r.get('query',{}).get('pages',[]):
        ii=(pg.get('imageinfo') or [{}])[0]; em=ii.get('extmetadata',{})
        lic=em.get('LicenseShortName',{}).get('value','').strip()
        if 'sa' in lic.lower().split() or '-sa' in lic.lower() or not OK.match(lic): continue
        keep.append({'title':pg['title'],'category':files.get(pg['title']),'license':lic,'license_url':em.get('LicenseUrl',{}).get('value',''),
                     'artist':re.sub('<[^>]+>','',em.get('Artist',{}).get('value',''))[:300],'page':ii.get('descriptionurl'),'thumb':ii.get('thumburl')})
print('licenca ok',len(keep),flush=True)
def dl(it):
    if not it['thumb']: return None
    name=hashlib.sha1(it['title'].encode()).hexdigest()[:16]+os.path.splitext(it['thumb'])[1][:5]
    dst=os.path.join(OUT,'img',name)
    if not os.path.exists(dst):
        for a in range(4):
            try:
                data=urllib.request.urlopen(urllib.request.Request(it['thumb'],headers=UA),timeout=60).read(); open(dst,'wb').write(data); break
            except Exception: time.sleep(3+a*5)
        else: return None
    it['file']='img/'+name; it['sha256']=hashlib.sha256(open(dst,'rb').read()).hexdigest(); return it
done=[]
with cf.ThreadPoolExecutor(4) as ex:
    for i,it in enumerate(ex.map(dl,keep)):
        if it: done.append(it)
        if i%200==0: print(i,len(keep),flush=True)
json.dump({'source':'https://commons.wikimedia.org/wiki/'+ROOT.replace(' ','_'),'policy':'only CC0/public domain/CC BY (no SA)','files':done},open(os.path.join(OUT,'manifest.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=0)
print('DONE',len(done))
