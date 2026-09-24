"""Artefatos de esboço v0.3. Não executa login, coleta de dados ou APIs."""
from pathlib import Path
import json
from html import escape

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'fluxos-v03'
OUT.mkdir(exist_ok=True)
SPECS=json.loads((ROOT/'fluxos-v03.json').read_text(encoding='utf-8'))
def r(x,y,w,h,c,rad=16):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rad}" fill="{c}"/>'
def t(x,y,s,z=14,c='#142F2C',w=400):return ''.join(f'<text x="{x}" y="{y+i*(z+5)}" font-family="Inter,Segoe UI,sans-serif" font-size="{z}" font-weight="{w}" fill="{c}">{escape(v)}</text>' for i,v in enumerate(str(s).split('\n')))
def p(d,c='#215E52',w=3):return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
def svg(s):return f'<svg xmlns="http://www.w3.org/2000/svg" width="390" height="844" viewBox="0 0 390 844">{s}</svg>'
BRAND=r(24,51,34,34,'#215E52',11)+p('M31 61 H45 M38 61 V77','white')+p('M44 77 V60 H51 M44 68 H50','#D8EB90')+t(68,79,'trainforge',24,'#215E52',700)
manifest=[]
routes=[]
for n,name,title,sub,blocks,*_ in SPECS:
    s=r(0,0,390,844,'#F6F6F1',32)+t(26,30,'9:41',12,'#142F2C',600)+BRAND+t(24,130,title,23 if len(title)>26 else 26,'#142F2C',700)+t(24,159,sub,11,'#64736E')+r(145,834,100,4,'#142F2C',2)
    y=185
    if n in (8,9):
        s=r(0,0,390,844,'#F6F6F1',32)+r(146,264,98 if n==8 else 102,98 if n==8 else 102,'#215E52',30)+p('M166 294 H194 M180 294 V336','white',6)+p('M201 336 V292 H224 M201 310 H221','#D8EB90',6)+t(85,419,'trainforge',38,'#215E52',700)+t(78,461,sub,14,'#64736E')+r(160,510,24 if n==8 else 70,5,'#D8EB90',3)
        routes.append({'from':n,'trigger':'after-delay','to':9 if n==8 else 10,'delayMs':250})
    for block in blocks:
        kind,label,*args=block
        value=args[0] if args else None
        if kind in ('field','choice'):
            s+=t(26,y+11,label,11 if len(label)>35 else 12,'#64736E',500)+r(24,y+23,342,44,'#E8EEE3' if kind=='choice' else 'white',14)+t(40,y+51,value,10 if len(str(value))>43 else 12,'#142F2C',500 if kind=='choice' else 400)
            y+=79
        elif kind=='card':
            h=48+len(str(value).split('\n'))*17
            s+=r(24,y,342,h,'#E8EEE3',20)+t(42,y+29,label,13 if len(label)>33 else 16,'#215E52',650)+t(42,y+54,value,11,'#64736E')
            y+=h+16
        elif kind=='note':
            s+=t(28,y+13,label,11,'#64736E');y+=len(label.split('\n'))*16+22
        else:
            h=30 if kind=='link' else 48
            bg='' if kind=='link' else r(24,y,342,h,'#215E52' if kind=='button' else 'white',16)
            fg='white' if kind=='button' else '#215E52'
            s+=f'<g>{bg}<text x="195" y="{y+(20 if kind=="link" else 30)}" text-anchor="middle" font-family="Inter,Segoe UI,sans-serif" font-size="13" font-weight="600" fill="{fg}">{escape(label)}</text></g>'
            routes.append({'from':n,'label':label,'to':value,'rect':[24,y,342,h]});y+=h+10
    if y>816:raise ValueError(f'Tela {n} excede altura: {y}')
    (OUT/f'{n:02}.svg').write_text(svg(s),encoding='utf-8')
    manifest.append({'id':n,'name':f'{n:02} · {name}','file':f'{n:02}.svg'})

# Carregamento mantém cabeçalhos e navegação já conhecidos.
basefiles=['01-hoje','02-planos','03-sessao','04-atividade','05-alimentacao','06-evolucao','07-perfil']
for i,filename in enumerate(basefiles):
    n=26+i
    source=(ROOT/f'{filename}.svg').read_text(encoding='utf-8')
    start,end=(150,807) if i==6 else ((180,799) if i==2 else (180,739))
    overlay=r(18,start,354,end-start,'#F6F6F1',8)
    for x,y,w,h in [(24,start+12,342,160),(24,start+191,158,80),(208,start+191,158,80),(24,start+300,342,70),(24,start+390,342,70)]:
        if y+h<end:overlay+=r(x,y,w,h,'#E5EBE2',18)
    if i==1:
        # Pesquisa e filtros são locais; só os resultados precisam de skeleton.
        overlay=r(18,294,354,439,'#F6F6F1',8)
        for x,y,w,h in [(24,301,342,221),(24,538,342,76),(24,632,342,87)]:
            overlay+=r(x,y,w,h,'#E5EBE2',18)
    elif i==6:
        # Preservar as opções estáticas do perfil durante a carga dos dados.
        overlay=r(24,151,342,184,'#E8EEE3',20)+r(155,170,80,80,'#D6DED2',40)+r(115,270,160,16,'#D6DED2',8)+r(140,298,110,12,'#D6DED2',6)
    overlay+=t(28,end-8,'A carregar dados…',11,'#64736E')
    (OUT/f'{n:02}.svg').write_text(source.replace('</svg>',overlay+'</svg>'),encoding='utf-8')
    manifest.append({'id':n,'name':f'{n:02} · A carregar · {filename[3:]}','file':f'{n:02}.svg'})
    routes.append({'from':n,'trigger':'after-delay','to':i+1,'delayMs':350})
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'routes.json').write_text(json.dumps(routes,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'{len(manifest)} telas adicionais; {len(routes)} transições especificadas.')
