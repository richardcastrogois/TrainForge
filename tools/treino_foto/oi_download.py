# Baixa as imagens selecionadas do bucket público do Open Images e reduz para 512 px
import json,sys,os,io,hashlib,urllib.request,time,concurrent.futures as cf
from PIL import Image
SEL=sys.argv[1]; OUT=sys.argv[2]; os.makedirs(os.path.join(OUT,'img'),exist_ok=True)
d=json.load(open(SEL,encoding='utf-8')); UA={'User-Agent':'dataset-download/1.0'}
def dl(r):
    dst=os.path.join(OUT,'img',r['id']+'.jpg')
    if not os.path.exists(dst):
        url=f"https://open-images-dataset.s3.amazonaws.com/{r['subset']}/{r['id']}.jpg"
        for a in range(4):
            try:
                data=urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=90).read()
                im=Image.open(io.BytesIO(data)).convert('RGB'); im.thumbnail((512,512)); im.save(dst,'JPEG',quality=90); break
            except Exception: time.sleep(2+a*4)
        else: return None
    r['file']='img/'+r['id']+'.jpg'; r['sha256']=hashlib.sha256(open(dst,'rb').read()).hexdigest(); return r
done=[]
with cf.ThreadPoolExecutor(24) as ex:
    for i,r in enumerate(ex.map(dl,d['images'])):
        if r: done.append(r)
        if i%2000==0: print(i,len(d['images']),flush=True)
json.dump({'source':'https://storage.googleapis.com/openimages/web/index.html','license':'images CC BY 2.0 (per image, attribution below); annotations CC BY 4.0 Google','classes':d['classes'],'images':done},open(os.path.join(OUT,'manifest.json'),'w',encoding='utf-8'),ensure_ascii=False)
print('DONE',len(done),'of',len(d['images']))
