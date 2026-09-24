"""Gera apenas artefatos visuais de demonstração; não altera o aplicativo."""
from pathlib import Path
from html import escape
import json

ROOT = Path(__file__).resolve().parent
INK, MUTED, BG, GREEN, LIME = '#142F2C', '#64736E', '#F6F6F1', '#215E52', '#D8EB90'

def rect(x,y,w,h,c,r=20,stroke=None):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c}"'+(f' stroke="{stroke}"' if stroke else '')+'/>'

def text(x,y,s,size=14,color=INK,weight=400):
    lines=s.split('\n')
    return f'<text x="{x}" y="{y}" fill="{color}" font-size="{size}" font-weight="{weight}">' + ''.join(f'<tspan x="{x}" dy="{0 if i==0 else round(size*1.3,1)}">{escape(line)}</tspan>' for i,line in enumerate(lines))+'</text>'

def path(d,c=GREEN,width=2,fill='none'):
    return f'<path d="{d}" fill="{fill}" stroke="{c}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'

def icon(name,x,y,c=INK):
    paths={
      'home':'M3 11 L12 3 L21 11 M5 10 V21 H19 V10 M9 21 V14 H15 V21',
      'plan':'M5 3 H19 V21 H5 Z M9 8 H15 M9 12 H15 M9 16 H13',
      'activity':'M2 13 H7 L10 5 L14 20 L17 11 H22',
      'food':'M5 3 V9 Q5 12 8 12 V22 M11 3 V9 Q11 12 8 12 M8 3 V9 M19 3 Q14 8 19 13 V22',
      'chart':'M4 20 V13 M12 20 V5 M20 20 V9',
      'arrow':'M5 12 H20 M14 6 L20 12 L14 18',
      'check':'M5 12 L10 17 L20 6',
      'plus':'M5 12 H19 M12 5 V19',
      'back':'M19 12 H4 M10 6 L4 12 L10 18',
    }
    return f'<g transform="translate({x} {y})">{path(paths[name],c,1.8)}</g>'

def nav(active):
    s=rect(16,750,358,76,'#FFFFFF',26)
    for i,(label,key) in enumerate([('Hoje','home'),('Planos','plan'),('Atividade','activity'),('Diário','food'),('Evolução','chart')]):
        cx=57+i*69
        if i==active:
            s+=rect(cx-28,756,56,40,LIME,18)
            s+=f'<g transform="translate({cx-14} 762) scale({28/24})">{icon(key,0,0,GREEN)}</g>'
            s+=f'<text x="{cx}" y="813" text-anchor="middle" font-size="11" font-weight="600" fill="{GREEN}">{label}</text>'
        else:
            s+=f'<g transform="translate({cx-10} 778) scale({20/24})">{icon(key,0,0,MUTED)}</g>'
    return s+rect(145,834,100,4,INK,2)

def brand():
    return rect(24,51,34,34,GREEN,11)+path('M31 61 H45 M38 61 V77','white',3)+path('M44 77 V60 H51 M44 68 H50',LIME,3)+text(68,79,'trainforge',24,GREEN,700)

def button(y,label,c=GREEN,fg='white'):
    return rect(24,y,342,52,c,18)+text(44,y+32,label,15,fg,600)+icon('arrow',320,y+14,fg)

def shell(title,subtitle,active):
    return rect(0,0,390,844,BG,32)+text(26,30,'9:41',12,INK,600)+text(310,30,'●  ▰',13,INK)+brand()+rect(326,52,38,38,'#E3E9DF',19)+text(336,77,'RG',12,GREEN,600)+text(24,130,title,28,INK,700)+text(24,160,subtitle,12,MUTED)+nav(active)

def row(y,title,sub,icon_name='plan',c='#EAF0E7'):
    return rect(24,y,342,76,'white',18)+rect(38,y+15,46,46,c,14)+icon(icon_name,49,y+26)+text(98,y+31,title,14,INK,600)+text(98,y+53,sub,12,MUTED)+text(340,y+44,'›',23,MUTED)

screens=[]
# 1. Hoje: primary task, week rhythm, quick entry points.
s=shell('O teu ritmo.','Quinta, 10 setembro · Bom dia, Richard',0)
s+=rect(24,190,342,237,GREEN,26)+text(46,221,'O TEU TREINO DE HOJE',11,LIME,600)+text(46,263,'Força, com\nconsistência.',30,'white',700)
s+=text(46,335,'Plano exemplo · 3 sessões por semana',12,'#DCEAE4')+text(46,361,'45 min    /    5 exercícios',15,'white',500)
s+=rect(46,382,140,29,LIME,14)+text(59,402,'Ver treino  →',12,INK,600)
s+=text(24,466,'A tua semana',18,INK,600)+text(256,466,'1 feito · 1 parcial',11,MUTED)
for i,day in enumerate(['S','T','Q','Q','S','S','D']):
    x=25+i*49;s+=text(x+15,491,day,11,MUTED)+rect(x,501,38,38,[GREEN,'#F7E3DD','#F8EDCE',LIME,'#E8ECE4','#E8ECE4','#E8ECE4'][i],14)
    if i==0:s+=icon('check',x+7,508,'white')
    elif i==1:s+=path(f'M{x+14} 515 L{x+24} 525 M{x+24} 515 L{x+14} 525','#A24C3A',2)
    elif i==2:s+=f'<circle cx="{x+19}" cy="520" r="9" fill="none" stroke="#DFC98E" stroke-width="3"/>'+path(f'M{x+19} 511 A9 9 0 0 1 {x+19} 529','#96701E',3)
    else:s+=text(x+12,525,str(7+i),12,INK,600 if i==3 else 400)
s+=icon('check',24,544,GREEN)+text(51,560,'Feito',10,MUTED)+path('M118 548 A6 6 0 0 1 118 560','#96701E',2)+text(131,560,'Incompleto',10,MUTED)+path('M251 550 L259 558 M259 550 L251 558','#A24C3A',2)+text(270,560,'Não feito',10,MUTED)
s+=row(577,'Caminhada ao fim do dia','Registo rápido de atividade','activity','#DFEAF7')
s+=row(661,'O teu diário alimentar','Adicionar uma refeição','food','#F5E3D5')
screens.append(('01-hoje','Hoje',s))
# 2. Plans: a source-oriented catalog without fabricated credentials.
s=shell('Planos com uma origem.','Escolhe com contexto. Guarda o que te serve.',1)
s+=rect(24,188,342,46,'white',16)+text(43,217,'Pesquisar plano ou modalidade',13,MUTED)
s+=rect(24,249,112,32,GREEN,16)+text(39,270,'Musculação',12,'white',600)+rect(145,249,101,32,'#E8ECE4',16)+text(162,270,'Em casa',12)+text(269,270,'Mobilidade',12,MUTED)
s+=rect(24,301,342,221,'white',24)+rect(40,317,310,66,'#E3ECE0',17)+text(57,344,'BASE DE FORÇA',11,GREEN,700)+text(57,369,'Uma rotina que cabe na semana.',14,INK,500)
s+=text(44,412,'Plano de exemplo A',21,INK,700)+text(44,437,'3 dias / semana · 45 min · Ginásio',12,MUTED)+text(44,464,'Origem e autoria',13,GREEN,600)+text(44,486,'A validar antes da publicação',12,MUTED)+text(330,478,'↗',22,GREEN)
s+=row(538,'Trazer o meu plano','Registar um plano próprio ou do treinador','plus')
s+=rect(24,632,342,87,'#E8EEE3',18)+text(42,659,'A confiança começa na fonte.',14,INK,600)+text(42,681,'Autor, versão e licença acompanham\ncada programa aprovado.',12,MUTED)
screens.append(('02-planos','Planos',s))
# 3. In-session: log rather than invent prescription, no advertising.
s=rect(0,0,390,844,BG,32)+text(26,30,'9:41',12,INK,600)+text(310,30,'●  ▰',13,INK)+icon('back',24,59)+text(61,77,'Treino A',17,INK,600)+text(281,77,'12:34',18,GREEN,600)
s+=text(24,126,'Uma série de cada vez.',26,INK,700)+text(24,155,'EXERCÍCIO 02 / 05 · DEMONSTRAÇÃO',11,MUTED,600)
s+=rect(24,180,342,151,GREEN,24)+text(44,216,'Remada sentada',25,'white',700)+text(44,245,'Regista a tua execução',13,'#DCEAE4')+text(44,281,'Vê a técnica e a fonte do exercício',12,'#DCEAE4')+text(44,306,'Consultar instruções  ↗',12,LIME,600)
s+=text(26,369,'Série',12,MUTED)+text(98,369,'Carga / kg',12,MUTED)+text(209,369,'Repetições',12,MUTED)+text(314,369,'Feita',12,MUTED)
for i,(kg,reps,done) in enumerate([('20','10',True),('20','10',False),('—','—',False)]):
    y=388+i*64;s+=rect(24,y,342,54,'white',14)+text(40,y+34,str(i+1),16,INK,600)+text(127,y+34,kg,18,INK,500)+text(242,y+34,reps,18,INK,500)+rect(315,y+13,28,28,GREEN if done else '#E8ECE4',9)
    if done:s+=icon('check',317,y+15,'white')
s+=rect(24,599,342,61,'#E8EEE3',17)+text(43,625,'Pausa entre séries',13,INK,600)+text(43,646,'Temporizador opcional',11,MUTED)+text(270,640,'01:00',24,GREEN,600)
s+=button(681,'Registar série')+rect(24,749,342,50,'white',18)+text(137,780,'Terminar treino',14,GREEN,600)+rect(145,827,100,4,INK,2)
screens.append(('03-sessao','Sessão de treino',s))
# 4. Running: schematic route, clearly illustrative.
s=shell('Vai ao teu ritmo.','Corrida, caminhada e outras atividades',2)
s+=rect(24,190,342,243,'#DFEAF7',25)
for y in [220,270,320,370,415]:s+=path(f'M35 {y} C120 {y-35},230 {y+30},355 {y-15}','#F6FAFE',12)
for x in [66,157,265,330]:s+=path(f'M{x} 200 L{x-20} 422','#F6FAFE',7)
s+=path('M87 365 C65 300,139 321,151 276 S243 229,277 270 S247 351,301 370',GREEN,5)
s+='<circle cx="87" cy="365" r="8" fill="#215E52"/><circle cx="301" cy="370" r="8" fill="#D8EB90" stroke="#215E52" stroke-width="3"/>'
s+=rect(43,207,161,28,'white',14)+text(56,226,'PERCURSO ILUSTRATIVO',9,GREEN,600)
s+=text(25,488,'3,20',48,INK,700)+text(139,488,'km',20,MUTED)+text(26,513,'Distância registada',13,MUTED)
s+=rect(24,538,164,89,'white',20)+text(41,568,'Duração',12,MUTED)+text(41,600,'24:18',26,INK,600)
s+=rect(202,538,164,89,'white',20)+text(219,568,'Ritmo médio',12,MUTED)+text(219,600,'7:36 /km',24,INK,600)
s+=button(648,'Registar atividade')+text(43,727,'Também podes adicionar sem localização.',12,MUTED)
screens.append(('04-atividade','Atividade',s))
# 5. Nutrition: distinguish logged intake from expenditure and targets.
s=shell('O teu diário alimentar.','Hoje · Regista sem complicar',3)
s+=rect(24,190,342,190,'#F5E3D5',25)+text(45,225,'ENERGIA REGISTADA',11,'#714C34',600)+text(44,279,'1 480',46,INK,700)+text(190,279,'kcal',17,'#714C34')+text(45,310,'Estimativa das refeições adicionadas',12,'#714C34')
s+=text(45,346,'Proteína 82 g   ·   Hidratos 180 g   ·   Gordura 48 g',10,'#714C34')
s+=row(399,'Pequeno-almoço','Iogurte, aveia e fruta · 380 kcal','food','#F5E3D5')+row(489,'Almoço','Arroz, legumes e frango · 640 kcal','food','#F5E3D5')
s+=text(28,598,'Outros registos: 460 kcal',12,MUTED)+button(622,'Adicionar alimento')+text(38,709,'As porções e a fonte alteram a estimativa.',12,MUTED)
screens.append(('05-alimentacao','Alimentação',s))
# 6. Progress: straightforward weekly chart, no invented trend percentage.
s=shell('Cada semana conta.','Evolução · Últimos 7 dias',4)
s+=rect(24,190,342,272,'white',25)+text(44,225,'TEMPO EM ATIVIDADE',11,MUTED,600)+text(43,271,'135',44,INK,700)+text(129,271,'min',17,MUTED)+text(256,267,'3 sessões',12,GREEN,600)
s+=path('M49 411 H344','#E6EAE3',1)
for i,h in enumerate([96,0,120,0,108,0,0]):
    x=47+i*44;s+=rect(x,410-max(h,5),23,max(h,5),GREEN if h else '#E6EAE3',7)+text(x+6,437,['S','T','Q','Q','S','S','D'][i],11,MUTED)
s+=rect(24,481,164,92,'#E8EEE3',20)+text(42,514,'Treinos',12,MUTED)+text(42,548,'3 feitos',25,INK,600)
s+=rect(202,481,164,92,'#DFEAF7',20)+text(220,514,'Atividade',12,MUTED)+text(220,548,'3,2 km',25,INK,600)
s+=row(592,'Histórico completo','Treinos e atividades, mesmo ao mudar plano','chart')+text(35,715,'O descanso também faz parte da rotina.',12,MUTED)
screens.append(('06-evolucao','Evolução',s))

# 7. Profile: secondary destination reached through the avatar, no sixth nav item.
s=rect(0,0,390,844,BG,32)+text(26,30,'9:41',12,INK,600)+brand()+icon('back',24,108)+text(62,126,'O teu perfil',25,INK,700)
s+=rect(24,151,342,184,'#E8EEE3',24)+rect(155,170,80,80,GREEN,40)+text(174,220,'RG',28,'white',600)
s+=rect(216,225,25,25,LIME,12)+path('M223 241 L224 235 L233 227 L237 231 L228 239 Z',GREEN,1.4)
s+=f'<text x="195" y="279" text-anchor="middle" font-size="22" font-weight="700" fill="{INK}">Richard Gois</text>'
s+=f'<text x="195" y="301" text-anchor="middle" font-size="12" fill="{MUTED}">Perfil de demonstração</text>'
s+=f'<text x="195" y="320" text-anchor="middle" font-size="12" font-weight="600" fill="{GREEN}">Editar perfil</text>'
s+=text(26,365,'CONTA E PREFERÊNCIAS',11,MUTED,600)+rect(24,379,342,192,'white',20)
for i,label in enumerate(['Dados pessoais','Objetivos e preferências de treino','Notificações','Idioma e unidades']):
    y=379+i*48;s+=text(42,y+29,label,13,INK,500)+text(337,y+30,'›',21,MUTED)
    if i<3:s+=path(f'M42 {y+48} H348','#EDF0E9',1)
s+=text(26,600,'PRIVACIDADE E APOIO',11,MUTED,600)+rect(24,614,342,96,'white',20)
for i,label in enumerate(['Privacidade e os meus dados','Ajuda e feedback']):
    y=614+i*48;s+=text(42,y+29,label,13,INK,500)+text(337,y+30,'›',21,MUTED)
    if i==0:s+=path(f'M42 {y+48} H348','#EDF0E9',1)
s+=rect(24,729,342,44,'white',16)+f'<text x="195" y="757" text-anchor="middle" font-size="13" font-weight="600" fill="{GREEN}">Terminar sessão</text>'+f'<text x="195" y="801" text-anchor="middle" font-size="11" fill="{MUTED}">TrainForge · Esboço v0.2</text>'+rect(145,834,100,4,INK,2)
screens.append(('07-perfil','Perfil',s))

def svg(content,w=390,h=844):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" font-family="Inter, Segoe UI, sans-serif">{content}</svg>'

for slug,title,content in screens:
    (ROOT/f'{slug}.svg').write_text(svg(content),encoding='utf-8')
board=rect(0,0,1390,2900,'#E8ECE5',0)+text(60,72,'trainforge',31,GREEN,700)+text(60,117,'Treinar. Registar. Continuar.',43,INK,700)+text(61,157,'CONCEITO V0.2 · PROPOSTA PARA REVISÃO · DADOS FICTÍCIOS',13,MUTED,600)
for i,(slug,title,content) in enumerate(screens):
    x=60+(i%3)*440;y=225+(i//3)*880
    board+=text(x,y-20,f'0{i+1} / {title}',13,MUTED,600)+f'<g transform="translate({x} {y})">{content}</g>'
board+=text(61,2875,'Visão futura: funcionalidades ainda não implementadas. Autoria e licenças de conteúdo por validar.',13,MUTED)
(ROOT/'trainforge-board.svg').write_text(svg(board,1390,2900),encoding='utf-8')
(ROOT/'trainforge-marca.svg').write_text(svg(brand(),265,100),encoding='utf-8')

assets=[{'slug':s,'title':t} for s,t,_ in screens]
html='''<!doctype html><html lang="pt-PT"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>TrainForge · Conceito v0.2</title>
<style>*{box-sizing:border-box}body{margin:0;background:#E8ECE5;color:#142F2C;font-family:Segoe UI,sans-serif}.layout{display:grid;grid-template-columns:minmax(240px,380px) minmax(320px,440px);gap:64px;justify-content:center;padding:48px 24px}.intro{padding-top:24px}.brand{font-size:22px;font-weight:750;color:#215E52}h1{font-size:42px;line-height:1.12;letter-spacing:-1.5px}p{line-height:1.6;color:#64736E}nav{display:flex;flex-wrap:wrap;gap:8px;margin:26px 0}button,.download{font:inherit;border:0;border-radius:20px;padding:11px 17px;cursor:pointer;background:#fff;color:#215E52}button[aria-pressed=true]{background:#215E52;color:white}a{color:#215E52}.phone{position:relative;width:min(390px,100%);margin:auto;box-shadow:0 20px 70px #142f2c18;border-radius:32px;overflow:hidden}.phone img{width:100%;display:block}.hot{position:absolute;background:transparent;padding:0;border-radius:16px}.hot:hover,.hot:focus-visible{background:#d8eb9033;outline:2px solid #215e52}.tag{font-size:11px;font-weight:700;letter-spacing:1.5px}.note{font-size:13px}#feedback{min-height:44px;margin-top:20px;font-size:14px;color:#215e52}.links{display:flex;gap:18px;flex-wrap:wrap}.links a{font-size:13px}@media(max-width:760px){.layout{display:flex;flex-direction:column;padding:24px 16px;gap:20px}.intro{padding:0}h1{font-size:32px;margin:16px 0}nav{margin:18px 0}.note{margin:8px 0}.phone{max-width:390px}}
</style><main class="layout"><section class="intro"><div class="brand">trainforge</div><p class="tag">DIREÇÃO VISUAL · V0.2</p><h1>Treinar.<br>Registar.<br>Continuar.</h1><p>Uma proposta para rever a experiência do app: treino do dia em destaque, origem dos planos e registo da rotina.</p><nav aria-label="Telas do conceito" id="screens"></nav><p class="note">Protótipo visual com dados fictícios. As telas mostram a visão futura; não representam funcionalidades já prontas nem recomendações de treino.</p><div class="links"><a href="trainforge-board.svg">Ver todas as telas</a><a id="download" href="01-hoje.svg" download>Descarregar tela SVG</a><a href="../proposta-visual.md">Ler decisões</a></div><div id="feedback" role="status" aria-live="polite"></div></section><section><div class="phone" id="phone"><img id="screen" src="01-hoje.svg" alt="Proposta da tela Hoje"></div></section></main>
<script>const screens=ASSETS;let current=0;const panel=document.getElementById('screens'),phone=document.getElementById('phone'),feedback=document.getElementById('feedback');screens.forEach((s,i)=>{const b=document.createElement('button');b.type='button';b.textContent=s.title;b.onclick=()=>show(i);panel.appendChild(b)});function hot(x,y,w,h,label,action){const b=document.createElement('button');b.type='button';b.className='hot';b.setAttribute('aria-label',label);Object.assign(b.style,{left:x/390*100+'%',top:y/844*100+'%',width:w/390*100+'%',height:h/844*100+'%'});b.onclick=action;phone.appendChild(b)}function note(t){feedback.textContent=t}function show(i){current=i;const s=screens[i];document.getElementById('screen').src=s.slug+'.svg';document.getElementById('screen').alt='Proposta: '+s.title;document.getElementById('download').href=s.slug+'.svg';[...panel.children].forEach((b,j)=>b.setAttribute('aria-pressed',String(i===j)));phone.querySelectorAll('.hot').forEach(b=>b.remove());feedback.textContent='';if(i!==2&&i!==6)[0,1,3,4,5].forEach((v,j)=>hot(26+j*69,755,61,66,screens[v].title,()=>show(v)));if(i!==2&&i!==6)hot(326,52,38,38,'Abrir perfil',()=>show(6));if(i===6){hot(20,102,40,40,'Voltar a Hoje',()=>show(0));hot(24,151,342,184,'Editar perfil de demonstração',()=>note('Proposta visual: dados pessoais e foto serão editáveis na implementação.'));hot(24,379,342,331,'Preferências de demonstração',()=>note('Subtelas de conta, preferências, notificações e privacidade serão detalhadas no refinamento.'));hot(24,729,342,44,'Terminar sessão de demonstração',()=>note('Demonstração visual; nenhuma sessão real foi encerrada.'))}if(i===0){hot(24,190,342,237,'Abrir treino',()=>show(2));hot(24,577,342,76,'Abrir atividade',()=>show(3));hot(24,661,342,76,'Abrir diário alimentar',()=>show(4))}if(i===1){hot(24,301,342,221,'Consultar origem do plano',()=>note('Neste conceito, autor, fonte, versão e licença aparecem no detalhe. Nenhum catálogo real foi selecionado.'));hot(24,538,342,76,'Trazer o meu plano',()=>note('Proposta futura: registo de plano próprio ou do treinador. Ainda sem importação implementada.'))}if(i===2){hot(20,50,40,45,'Voltar a Hoje',()=>show(0));hot(24,681,342,52,'Registar série de demonstração',()=>note('Interação demonstrativa. Na implementação, o registo será persistido com carga, repetições e estado de sincronização.'));hot(24,749,342,50,'Terminar treino de demonstração',()=>{show(5);note('Exemplo de passagem da sessão para o histórico. Nenhum treino real foi gravado.')})}if(i===3)hot(24,648,342,52,'Registar atividade de demonstração',()=>note('Conceito: escolher modalidade, duração e distância. GPS é opcional e ainda não existe no app.'));if(i===4)hot(24,622,342,52,'Adicionar alimento de demonstração',()=>note('Conceito: pesquisar alimento, confirmar fonte e porção. Base nutricional ainda por selecionar.'));if(i===5)hot(24,592,342,76,'Ver histórico',()=>note('Proposta: histórico de todos os planos e atividades. Hoje a API agrega apenas o plano ativo.'))}show(0);</script></html>'''.replace('ASSETS',json.dumps(assets,ensure_ascii=False))
(ROOT/'preview.html').write_text(html,encoding='utf-8')
print('Generated 7 screens, brand, board and navigable preview.')
