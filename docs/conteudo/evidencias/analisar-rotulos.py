"""N07: validar cálculos didáticos e gerar referência visual própria, sem rede.
Não integra o app nem cria dieta. Requer apenas biblioteca padrão e corpos locais.
"""
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
import hashlib
from html import escape
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'2026-09-28/n07-rotulos'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def save(n,v):(OUT/n).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def number(v):
    if isinstance(v,bool) or not isinstance(v,(str,int,Decimal)):raise ValueError('invalid_numeric_type')
    try:d=Decimal(v)
    except InvalidOperation as e:raise ValueError('not_a_measured_number') from e
    if not d.is_finite() or d<0:raise ValueError('invalid_value')
    return d

def portion(value,quantity,unit,basis_unit='g',basis='100',state='como vendido',basis_state='como vendido'):
    if unit!=basis_unit or unit not in ('g','ml'):raise ValueError('incompatible_basis_unit')
    if state!=basis_state:raise ValueError('incompatible_preparation')
    q,b=number(quantity),number(basis)
    if b<=0:raise ValueError('invalid_basis')
    if value is None:return None
    return number(value)*q/b

def display(value):
    if value is None:return 'Não informado'
    d=number(value).quantize(Decimal('.01'),rounding=ROUND_HALF_UP)
    return format(d,'f').rstrip('0').rstrip('.').replace('.',',') if d else '0'

def main():
    data=read(OUT/'conteudo-didatico.json');checks=[]
    def check(name,ok):
        if not ok:raise AssertionError(name)
        checks.append({'name':name,'passed':True})
    def rejects(name,call):
        try:call()
        except ValueError:check(name,True)
        else:check(name,False)
    a,b=data['examples'];nut={v['id']:v for v in a['nutrients']}
    cases=[('45 g','200','45','g','g','90'),('porção 30 g','200','30','g','g','60'),('pacote 300 g','200','300','g','g','600'),('bebida 250 ml','42','250','ml','ml','105'),('kJ não é kcal','838','45','g','g','377.1'),('sal em g','0.4','45','g','g','0.18'),('consumo zero explícito','200','0','g','g','0'),('nutriente zero explícito','0','45','g','g','0'),('quantidade fracionária','200','45.5','g','g','91')]
    for name,v,q,u,bu,expected in cases:check(name,portion(v,q,u,bu)==Decimal(expected))
    check('Ausente permanece desconhecido',portion(None,'45','g') is None)
    check('Vírgula decimal no texto',display(Decimal('0.18'))=='0,18')
    check('Arredondamento somente na apresentação',portion('1.333','45','g')==Decimal('.59985') and display(portion('1.333','45','g'))=='0,6')
    check('Sal 0,18 g corresponde a 180 mg, não 0,18 mg',portion('0.4','45','g')*1000==Decimal(180))
    rejects('g não vira ml sem densidade',lambda:portion('42','250','g','ml'))
    rejects('unidade sem massa não vira gramas',lambda:portion('200','1','unidade'))
    rejects('cozido não usa ficha crua automaticamente',lambda:portion('200','45','g',state='cozido',basis_state='cru'))
    rejects('base zero recusada',lambda:portion('200','45','g',basis='0'))
    for v in ['-1','NaN','Infinity','<0.1','tr',True,None]:rejects('Quantidade inválida '+str(v),lambda v=v:portion('200',v,'g'))
    check('Açúcares pertencem a hidratos; não somar 22+4',nut['sugars']['partOf']=='carbohydrate' and number(nut['sugars']['value'])<=number(nut['carbohydrate']['value']))
    check('Saturados pertencem a lípidos; não somar 8+1,5',nut['saturates']['partOf']=='fat' and number(nut['saturates']['value'])<=number(nut['fat']['value']))
    check('Recortes didáticos explicitamente fictícios',all(x['fictional'] and x['notice'] for x in data['examples']))
    check('Pacote, porção e consumo distintos',len({a[k]['quantity'] for k in ['package','serving','consumed']})==3)
    hashes=[];failed=[]
    for p in sorted(OUT.glob('*.evidencia.json')):
        e=read(p)
        if e.get('bodyFile'):
            body=p.parent/e['bodyFile'];ok=hashlib.sha256(body.read_bytes()).hexdigest()==e['sha256']
            if not ok:raise AssertionError('Hash incorreto '+p.name)
            hashes.append({'file':p.name,'status':e['status'],'sha256Matches':ok})
        else:failed.append({'file':p.name,'status':e['status'],'error':e.get('error')})
    sources={s['id']:s for s in data['sources']}
    check('Todas as lições rastreáveis a fontes preservadas',len(data['lessons'])==12 and all(l['sourceIds'] and all(i in sources for i in l['sourceIds']) for l in data['lessons']))
    check('Cinco fontes principais são HTTP 200 com corpo/hash',len(hashes)==5 and all(x['status']==200 for x in hashes))
    check('Duas falhas TLS preservadas, não tratadas como dados',len(failed)==2 and all(x['status'] is None and 'CERTIFICATE_VERIFY_FAILED' in x['error'] for x in failed))
    for s in sources.values():
        e=read(OUT/s['evidenceFile'])
        if e['url']!=s['url'] or e['status']!=200:raise AssertionError('Fonte inconsistente')
    results={'A':{'servingKcal':'60','consumedKcal':'90','packageKcal':'600','consumedKj':'377.1','consumedSaltG':'0.18'},'B':{'consumedKcal':'105'}}
    save('validacao-rotulos.json',{'networkCallsDuringAnalysis':0,'functionalChecks':checks,'hashChecks':hashes,'preservedFailures':failed,'fictionalExampleResults':results})
    rows=[]
    for n in a['nutrients']:
        val=n['value'];label=('↳ ' if n['partOf'] else '')+n['label']
        rows.append('<tr><th scope="row">'+escape(label)+'</th><td>'+display(Decimal(val))+' '+n['unit']+'</td><td>'+display(portion(val,'30','g'))+' '+n['unit']+'</td><td>'+display(portion(val,'45','g'))+' '+n['unit']+'</td></tr>')
    lessons=[]
    for l in data['lessons']:
        refs=' · '.join('<a href="'+escape(sources[i]['url'],quote=True)+'">'+escape(sources[i]['publisher'])+'</a>' for i in l['sourceIds'])
        lessons.append('<article class="lesson" id="'+l['id']+'"><span class="tag">'+l['id']+'</span><h3>'+escape(l['title'])+'</h3><p>'+escape(l['simpleText'])+'</p><details><summary>Ver detalhe e fonte</summary><p>'+escape(l['technicalNote'])+'</p><p class="source">'+refs+'</p></details></article>')
    html='''<!doctype html><html lang="pt-PT"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>TrainForge · Aprender a ler um rótulo · N07</title><style>
:root{--ink:#173b34;--green:#235e52;--lime:#d8ec92;--paper:#f4f5ef;--line:#d9e1d7}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.55 system-ui,Arial,sans-serif}main{max-width:1160px;margin:auto;padding:44px 28px 64px}a{color:var(--green)}.brand{font-size:25px;font-weight:800;letter-spacing:-1px}.eyebrow{font-size:12px;letter-spacing:2px;text-transform:uppercase}h1{font-size:clamp(32px,5vw,54px);line-height:1.1;max-width:800px;letter-spacing:-1.5px;margin:14px 0}h2{font-size:25px;line-height:1.25;margin:0 0 18px}h3{font-size:19px;line-height:1.3;margin:10px 0}.intro{max-width:720px;color:#4d635c}.notice{border-left:4px solid var(--green);padding:10px 16px;background:#e6ecdf;max-width:900px}.examples{display:grid;grid-template-columns:2fr 1fr;gap:22px;margin:34px 0}.panel{background:white;border:1px solid var(--line);border-radius:20px;padding:24px;min-width:0}.tag{font-size:12px;font-weight:700;letter-spacing:1px}.quantity{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:16px 0}.quantity div{padding:14px 10px;border-radius:12px;background:var(--paper);font-size:12px}.quantity strong{display:block;font-size:24px}.quantity .chosen{background:var(--lime)}.table-scroll{overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{padding:9px 8px;border-bottom:1px solid var(--line);text-align:right;white-space:nowrap}th:first-child{text-align:left}thead th{font-size:12px}td:last-child,thead th:last-child{background:#f0f6dd}th[scope=row]{font-weight:500}.formula{font-size:22px;background:var(--green);color:white;padding:18px;border-radius:12px;margin:20px 0 12px}.formula small{display:block;font-size:13px;color:#def0cd}.small{font-size:13px;color:#50665c}.label{border:1px solid var(--line);border-radius:12px;padding:16px;margin-top:20px;font-size:14px}.bottle{height:150px;width:76px;border:3px solid var(--green);border-radius:14px 14px 26px 26px;position:relative;background:linear-gradient(to top,#d8ec92 62%,white 62%);margin:35px auto 20px}.bottle:before{content:"";position:absolute;width:40px;height:15px;top:-18px;left:15px;border-radius:4px;background:var(--green)}.bottle span{position:absolute;left:8px;top:55px;font-weight:700;font-size:13px}.big{font-size:40px;letter-spacing:-1px;margin:5px 0;line-height:1.15}.big small{font-size:16px}.lessons{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.lesson{padding:22px;background:white;border-radius:16px;border:1px solid var(--line)}.lesson p{font-size:15px}.lesson .tag{color:#577061}summary{font-size:13px;font-weight:650;cursor:pointer;text-decoration:underline;text-underline-offset:3px}summary:focus-visible{outline:3px solid #235e52;outline-offset:4px}.source{font-size:12px!important}footer{margin-top:28px;border-top:1px solid var(--line);padding-top:18px;font-size:13px;color:#52645d}@media(max-width:900px){.examples{grid-template-columns:1fr}.lessons{grid-template-columns:repeat(2,1fr)}}@media(max-width:540px){main{padding:26px 16px}.panel{padding:18px}.lessons{grid-template-columns:1fr}th,td{padding:8px 5px}.formula{font-size:20px}.quantity strong{font-size:21px}}@media print{body{background:white}main{max-width:none}.lesson{break-inside:avoid}details{display:block}.examples{grid-template-columns:2fr 1fr}}
</style><main><div class="brand">trainforge</div><p class="eyebrow">N07 · referência didática · 28 setembro 2026</p><h1>O rótulo explica.<br>Tu escolhes quanto registar.</h1><p class="intro">Aprende a encontrar os valores, comparar na mesma base e registar a quantidade que realmente consumiste.</p><p class="notice"><strong>Exemplos fictícios.</strong> Valores e desenhos próprios apenas para aprender. Não representam produtos reais, dietas ou recomendações de porção. Este material de pesquisa ainda precisa de revisão editorial.</p>
<div class="examples"><section class="panel"><span class="tag">EXEMPLO A · ALIMENTO</span><h2>Três quantidades. Três significados.</h2><div class="quantity"><div>Pacote<strong>300 g</strong>Quantidade total</div><div>Porção indicada<strong>30 g</strong>Exemplo do rótulo</div><div class="chosen">O que consumiste<strong>45 g</strong>Quantidade a registar</div></div><p class="small">Em ecrãs pequenos, desliza a tabela para ver todas as colunas.</p><div class="table-scroll" role="region" tabindex="0" aria-label="Tabela nutricional com deslocação horizontal"><table><caption class="small">Recorte didático · base: alimento como vendido</caption><thead><tr><th scope="col">Informação</th><th scope="col">Por 100 g</th><th scope="col">Por 30 g</th><th scope="col">Nos teus 45 g</th></tr></thead><tbody>'''+''.join(rows)+'''</tbody></table></div><div class="formula">200 × 45 ÷ 100 = <strong>90 kcal</strong><small>Valor na base × quantidade consumida ÷ tamanho da base</small></div><p class="small">A porção de 30 g daria 60 kcal. O pacote completo daria 600 kcal. Nenhum destes tamanhos é uma recomendação para ti.</p><div class="label"><strong>Outra parte do rótulo: ingredientes</strong><p>Água, flocos de <strong>AVEIA</strong>, óleo vegetal, açúcar, sal.<br>Pode conter <strong>LEITE</strong>.</p><p class="small">Lista fictícia independente dos números acima. O ingrediente destacado e o aviso de possível presença têm significados diferentes. Não é uma receita nem uma avaliação de alergias.</p></div></section>
<section class="panel"><span class="tag">EXEMPLO B · BEBIDA</span><h2>Também vale para mililitros.</h2><div class="bottle" role="img" aria-label="Desenho original de uma garrafa fictícia"><span>250 ml</span></div><p class="small">42 kcal por 100 ml.<br>Quantidade do exercício: 250 ml.</p><p class="big">105 <small>kcal</small></p><p>42 × 250 ÷ 100 = 105</p><div class="label"><strong>Mantém a unidade.</strong><p>250 ml não significa automaticamente 250 g. Para converter, falta uma densidade adequada.</p></div><div class="label"><strong>Foto não é balança.</strong><p>Uma imagem ilustra o alimento. Não demonstra os gramas, a receita ou as calorias consumidas.</p></div><p class="small">Se o valor ou a quantidade não estiverem disponíveis, mostrar «Não informado». Nunca preencher com zero por conveniência.</p></section></div>
<h2>Um guia em pequenos passos</h2><div class="lessons">'''+''.join(lessons)+'''</div><footer>Fontes humanas: Comissão Europeia, EFSA, NHS e British Nutrition Foundation — ligações em cada lição. Fontes do Reino Unido são apoio pedagógico; não substituem regras portuguesas. Diagramas e exemplos próprios do projeto; nenhuma fotografia, logótipo institucional ou ilustração de terceiros foi reproduzida.<br>Rascunho assistido por agente, sem revisão profissional independente. Não é a interface implementada nem um protótipo Figma. Dados estruturados e evidências: <a href="conteudo-didatico.json">conteudo-didatico.json</a>.</footer></main></html>'''
    (OUT/'guia-rotulos.html').write_text(html,encoding='utf-8')
    save('resumo-rotulos.json',{'niche':'N07','researchStatus':'completed_for_declared_scope','date':'2026-09-28','lessons':len(data['lessons']),'humanInstitutionalGuidesWithLocalBody':len(hashes),'preservedCalls':len(hashes)+len(failed),'http200':len(hashes),'tlsFailuresPreserved':len(failed),'verifiedBodyHashes':len(hashes),'functionalChecksPassed':len(checks),'originalVisualArtifact':'guia-rotulos.html','fictionalExamples':2,'releaseApproved':False,'next':'N08','limits':data['notValidated']})
    print(json.dumps(read(OUT/'resumo-rotulos.json'),ensure_ascii=False))

if __name__=='__main__':main()
