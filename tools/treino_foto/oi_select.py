# Seleciona imagens de alimentos do Open Images (rótulos humanos positivos) e grava a lista com atribuição
import csv,sys,os,json,collections
META=sys.argv[1]; CAND=sys.argv[2]; OUT=sys.argv[3]; CAP=int(sys.argv[4]); MINIMG=int(sys.argv[5])
cand=dict(l.strip().split(',',1) for l in open(CAND,encoding='utf-8') if l.strip())
labels=collections.defaultdict(set); per=collections.Counter()
for f in ['oidv7-train-annotations-human-imagelabels.csv','oidv7-val-annotations-human-imagelabels.csv','oidv7-test-annotations-human-imagelabels.csv']:
    with open(os.path.join(META,f),encoding='utf-8') as fh:
        r=csv.reader(fh); next(r)
        for row in r:
            iid,src,lab,conf=row[0],row[1],row[2],row[3]
            if lab in cand and conf=='1':
                labels[iid].add(lab); per[lab]+=1
keep_cls={k for k,v in per.items() if v>=MINIMG}
print('classes com imagens',len(per),'classes >=',MINIMG,len(keep_cls),'imagens',len(labels),flush=True)
# metadados de licença
info={}
with open(os.path.join(META,'image_ids_and_rotation.csv'),encoding='utf-8') as fh:
    r=csv.DictReader(fh)
    for row in r:
        if row['ImageID'] in labels: info[row['ImageID']]=row
lic=collections.Counter(v['License'] for v in info.values()); print('licencas',lic.most_common(5),flush=True)
OKL={'https://creativecommons.org/licenses/by/2.0/'}
# seleção com teto por classe, priorizando classes raras
bycls=collections.defaultdict(list)
for i,ls in labels.items():
    for l in ls: bycls[l].append(i)
chosen=set(); cnt=collections.Counter()
for lab in sorted(keep_cls,key=lambda k:per[k]):
    for iid in bycls[lab]:
        if cnt[lab]>=CAP: break
        if iid in info and info[iid]['License'] in OKL: chosen.add(iid)
        if iid in chosen: cnt[lab]+=1
recs=[]
for iid in chosen:
    v=info[iid]
    recs.append({'id':iid,'subset':v['Subset'],'labels':sorted(cand[l] for l in labels[iid] if l in keep_cls),'license':v['License'],
                 'author':v['Author'],'author_url':v['AuthorProfileURL'],'landing':v['OriginalLandingURL'],'title':v['Title'],'rotation':v['Rotation']})
json.dump({'classes':{cand[k]:min(per[k],CAP) for k in keep_cls},'images':recs},open(OUT,'w',encoding='utf-8'),ensure_ascii=False)
print('selecionadas',len(recs),'classes',len(keep_cls))
