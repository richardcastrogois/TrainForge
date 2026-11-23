import json,urllib.request,urllib.parse,os,sys,hashlib,concurrent.futures as cf
OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
UA={'User-Agent':'dataset-download/1.0'}
B='https://storage.googleapis.com/storage/v1/b/nutrition5k_dataset/o?'
def get(p): return json.load(urllib.request.urlopen(urllib.request.Request(B+urllib.parse.urlencode(p),headers=UA),timeout=60))
names=[]
p={'prefix':'nutrition5k_dataset/imagery/realsense_overhead/','fields':'nextPageToken,items(name,size,md5Hash)','maxResults':1000}
while True:
    r=get(p); names+= [it for it in r.get('items',[]) if it['name'].endswith('/rgb.png')]
    if not r.get('nextPageToken'): break
    p['pageToken']=r['nextPageToken']
names+= get({'prefix':'nutrition5k_dataset/metadata/','fields':'items(name,size,md5Hash)'})['items']
def dl(it):
    rel=it['name'].replace('nutrition5k_dataset/','')
    dst=os.path.join(OUT,*rel.split('/'))
    if os.path.exists(dst) and os.path.getsize(dst)==int(it['size']): return rel,'skip',dst
    os.makedirs(os.path.dirname(dst),exist_ok=True)
    url='https://storage.googleapis.com/nutrition5k_dataset/'+urllib.parse.quote(it['name'])
    for a in range(4):
        try:
            data=urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=120).read()
            if len(data)==int(it['size']):
                open(dst,'wb').write(data); return rel,'ok',dst
        except Exception as e: err=e
    return rel,'fail',None
man=[]
with cf.ThreadPoolExecutor(16) as ex:
    for i,(rel,st,dst) in enumerate(ex.map(dl,names)):
        if dst: man.append({'path':rel,'sha256':hashlib.sha256(open(dst,'rb').read()).hexdigest(),'bytes':os.path.getsize(dst)})
        else: print('FAIL',rel,flush=True)
        if i%500==0: print(i,len(names),flush=True)
json.dump({'source':'https://github.com/google-research-datasets/Nutrition5k','license':'CC BY 4.0','files':man},open(os.path.join(OUT,'manifest.json'),'w'),indent=0)
print('DONE',len(man),'of',len(names))
