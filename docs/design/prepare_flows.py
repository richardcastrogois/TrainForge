"""Prepara dados de transferência e mapa do esboço; não escreve no Figma."""
from pathlib import Path
from html import escape
import json

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'fluxos-v03'
base=['01-hoje','02-planos','03-sessao','04-atividade','05-alimentacao','06-evolucao','07-perfil']
names=['Hoje','Planos','Treino em curso','Atividade','Alimentação','Evolução','Perfil']
old=json.loads((OUT/'routes-all.json').read_text(encoding='utf-8'))
exclude={'Editar contexto de treino','Nova rotina','Preferências alimentares','Histórico de treino'}
routes=[r for r in old if r.get('hotspot') and r.get('label') not in exclude]
routes += [r for r in json.loads((OUT/'routes.json').read_text(encoding='utf-8')) if r['from']!=r['to']]
assets=[]
for i,filename in enumerate(base,1):
    source=(ROOT/(filename+'.svg')).read_text(encoding='utf-8')
    overlay=''
    for route in routes:
        if route['from']!=i:continue
        x,y,w,h=route['rect']
        overlay+=f'<g opacity="0.001"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#FFFFFF"/><text x="{x+3}" y="{y+14}" font-family="Inter" font-size="10">{escape(route["label"])}</text></g>'
    source=source.replace('</svg>',overlay+'</svg>')
    (OUT/f'{i:02}.svg').write_text(source,encoding='utf-8')
    assets.append(dict(n=i,name=f'{i:02} · {names[i-1]}',svg=source,x=120+(i-1)*450,y=240))
for item in json.loads((OUT/'manifest.json').read_text(encoding='utf-8')):
    n=item['id']
    x,y=(120+(n-8)*450,-900) if n<=15 else ((120+(n-16)*450,1340) if n<=22 else ((120+(n-23)*450,2440) if n<=25 else (120+(n-26)*450,3540)))
    if n==33:x,y=3720,-900
    assets.append(dict(n=n,name=item['name'],svg=(OUT/item['file']).read_text(encoding='utf-8'),x=x,y=y))
(OUT/'routes-all.json').write_text(json.dumps(routes,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'manifest-all.json').write_text(json.dumps([{k:v for k,v in a.items() if k!='svg'} for a in assets],ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'transfer.html').write_text('<!doctype html><meta charset="utf-8"><title>TrainForge · Dados de design</title><textarea aria-label="Dados do design">'+escape(json.dumps(dict(assets=assets,routes=routes),ensure_ascii=False))+'</textarea>',encoding='utf-8')
print(f'{len(assets)} telas; {len(routes)} rotas previstas. A aplicação online é verificada separadamente.')
