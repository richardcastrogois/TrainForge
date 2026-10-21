'use strict';
let data, revision, tab = 'map', mode = 'actual', search = '', busy = false;
const $ = id => document.getElementById(id);
const make = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
const add = (parent, ...nodes) => { nodes.forEach(n => parent.append(n)); return parent; };
const has = item => JSON.stringify(item).toLocaleLowerCase('pt-BR').includes(search.toLocaleLowerCase('pt-BR'));
const labelStatus = {todo:'Não iniciada',doing:'Em andamento',blocked:'Bloqueada',done:'Concluída'};
const tagEl = (text, cls = '') => make('span', text, `tag ${cls}`);
function details(title, sections) {
  $('detail').replaceChildren(make('h2', title));
  sections.forEach(([heading, value]) => {
    add($('detail'), make('h3', heading));
    if (Array.isArray(value)) { const ul = make('ul'); value.forEach(x => add(ul, make('li', typeof x === 'string' ? x : JSON.stringify(x)))); add($('detail'), ul); }
    else add($('detail'), make('pre', typeof value === 'object' ? JSON.stringify(value, null, 2) : String(value ?? 'Não detectado')));
  });
}
function showSource(s) { return s ? `${s.path}:${s.line}` : 'Sem localização detectada'; }
function metric(value, caption) { return add(make('div',undefined,'metric'),make('strong',String(value)),make('span',caption)); }
function renderMetrics() {
  const c = data.actual.coverage, all = data.backlog.epics.flatMap(e=>e.stories);
  $('metrics').replaceChildren(metric(c.dartFiles,'arquivos Dart detectados'),metric(c.routes,'rotas Fastify detectadas'),metric(`${c.matchedCalls}/${c.httpCalls}`,'chamadas Flutter com rota compatível'),metric(data.backlog.epics.length,'épicos planejados'),metric(`${all.filter(s=>s.status==='done').length}/${all.length}`,'histórias concluídas com registro'));
  $('next').textContent = data.backlog.next;
}
function render() {
  if (!data) return;
  $('detail').replaceChildren(make('h2',mode==='actual'?'Evidência do código':'Proposta de implementação'),make('p','Selecione um bloco, ligação, rota ou história para inspecionar.'));
  $('context-note').textContent = mode === 'actual' ? 'Código local · análise estática · sem executar o app' : 'Proposta · serviços Go e contratos ainda não implementados';
  $('actual').setAttribute('aria-pressed',String(mode==='actual'));
  $('planned').setAttribute('aria-pressed',String(mode==='planned'));
  document.querySelectorAll('[data-tab]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.tab===tab)));
  $('content').replaceChildren();
  ({map:renderMap,screens:renderScreens,http:renderHttp,db:renderDb,backlog:renderBacklog,findings:renderFindings})[tab]();
}
function heading(title, caption) { add($('content'),make('h2',title,'section-title'),make('p',caption,'caption')); }
function renderMap() {
  heading(mode==='actual'?'Estrutura atual':'Arquitetura de destino', mode==='actual'?'Agrupada por responsabilidade. Importações e literais HTTP fornecem as ligações. Selecione os blocos para ver arquivos.':'Selecione uma ligação para ver chamada, dados enviados e retorno esperado.');
  const map = mode==='actual'?data.actual:data.planned;
  graph(map.nodes.filter(has),map.edges,'architecture');
}
function graph(nodes, edges, name) {
  const content=$('content');
  if (!nodes.length) { add(content,make('p','Nenhum bloco corresponde à busca.','empty')); return; }
  const ns='http://www.w3.org/2000/svg', svg=document.createElementNS(ns,'svg');
  svg.setAttribute('class','graph'); svg.setAttribute('role','group'); svg.setAttribute('aria-label',`${name}: mapa interativo, selecione os nós pelo seletor ou pelo desenho`);
  const layerOrder=[...new Set(nodes.map(n=>n.layer||'Telas'))];
  let cols = mode==='actual' && name==='architecture' ? 4 : Math.min(layerOrder.length,5);
  if(name==='screens') cols=3;
  const width=cols*275+80, positions=new Map(), counts={};
  nodes.forEach((n,i)=>{ const col = name==='screens'?i%3:(name==='architecture'&&mode==='actual'?i%4:layerOrder.indexOf(n.layer)%5); const row=counts[col]||0; counts[col]=row+1; positions.set(n.id,{x:35+col*275,y:45+row*140}); });
  const height=Math.max(460,Math.max(...Object.values(counts))*140+80); let box={x:0,y:0,w:width,h:height};
  const apply=()=>svg.setAttribute('viewBox',`${box.x} ${box.y} ${box.w} ${box.h}`); apply();
  const defs=document.createElementNS(ns,'defs'), marker=document.createElementNS(ns,'marker');
  marker.setAttribute('id',`arrow-${name}`); marker.setAttribute('viewBox','0 0 10 10'); marker.setAttribute('refX','9'); marker.setAttribute('refY','5'); marker.setAttribute('markerWidth','6'); marker.setAttribute('markerHeight','6'); marker.setAttribute('orient','auto-start-reverse');
  const arrow=document.createElementNS(ns,'path');arrow.setAttribute('d','M 0 0 L 10 5 L 0 10 z');arrow.setAttribute('fill','#8fa99c');marker.append(arrow);defs.append(marker);svg.append(defs);
  const edgeLayer=document.createElementNS(ns,'g'), nodeLayer=document.createElementNS(ns,'g');svg.append(edgeLayer,nodeLayer);
  function drawEdges() {
    edgeLayer.replaceChildren();
    edges.filter(e=>positions.has(e.from)&&positions.has(e.to)).forEach(e=>{
      const a=positions.get(e.from),b=positions.get(e.to),p=document.createElementNS(ns,'path');
      const start={x:a.x+112,y:a.y+65},end={x:b.x+112,y:b.y};
      if(a.x!==b.x){start.x=a.x+(b.x>a.x?225:0);start.y=a.y+34;end.x=b.x+(b.x>a.x?0:225);end.y=b.y+34;}
      p.setAttribute('d',`M ${start.x} ${start.y} C ${start.x+(end.x-start.x)*.55} ${start.y},${end.x-(end.x-start.x)*.55} ${end.y},${end.x} ${end.y}`);
      p.setAttribute('class','edge');p.setAttribute('marker-end',`url(#arrow-${name})`);p.setAttribute('tabindex','0');p.setAttribute('role','button');p.setAttribute('aria-label',`${e.from} para ${e.to}: ${e.label}`);
      const title=document.createElementNS(ns,'title');title.textContent=e.label;p.append(title);
      p.addEventListener('pointerdown',ev=>ev.stopPropagation());
      const choose=()=>details(`${e.from} → ${e.to}`,[['Ligação',e.label],['Envia',e.input],['Recebe',e.output],['Evidência',e.evidence||'Importação/literal estático; não chamada executada.'],['Localizações',e.sources?.map(showSource)||showSource(e.source)]]);
      p.addEventListener('click',choose);p.addEventListener('keydown',ev=>{if(ev.key==='Enter'||ev.key===' '){ev.preventDefault();choose();}});edgeLayer.append(p);
    });
  }
  drawEdges();
  const inspectors = new Map();
  let moving, last;
  function svgPoint(event) { const point=svg.createSVGPoint();point.x=event.clientX;point.y=event.clientY;return point.matrixTransform(svg.getScreenCTM().inverse()); }
  nodes.forEach(n=>{
    const pos=positions.get(n.id),g=document.createElementNS(ns,'g');g.setAttribute('class','node');g.setAttribute('transform',`translate(${pos.x},${pos.y})`);g.setAttribute('tabindex','0');g.setAttribute('role','button');g.setAttribute('aria-label',n.label);
    const rect=document.createElementNS(ns,'rect');rect.setAttribute('width','225');rect.setAttribute('height','70');g.append(rect);
    const text=document.createElementNS(ns,'text');text.setAttribute('x','15');text.setAttribute('y','29');text.textContent=n.label.length>27?n.label.slice(0,26)+'…':n.label;g.append(text);
    const meta=document.createElementNS(ns,'text');meta.setAttribute('class','meta');meta.setAttribute('x','15');meta.setAttribute('y','50');meta.textContent=n.layer+(n.files?` · ${n.files.length} arquivos`:'');g.append(meta);
    const choose=()=>{nodeLayer.querySelectorAll('.selected').forEach(el=>el.classList.remove('selected'));g.classList.add('selected');details(n.label,[['Responsabilidade',n.description||n.kind||n.layer],['Evidência',n.evidence||'Referência estática de widget.'],['Arquivos',n.files?.map(showSource)||[showSource(n.source)]],['Ligações',edges.filter(e=>e.from===n.id||e.to===n.id).map(e=>`${e.from} → ${e.to}: ${e.label}`)]]);};
    inspectors.set(n.id, choose);
    g.addEventListener('click',choose);g.addEventListener('keydown',ev=>{if(ev.key==='Enter'||ev.key===' '){ev.preventDefault();choose();}});
    g.addEventListener('pointerdown',ev=>{ev.stopPropagation();moving={n,g};last=svgPoint(ev);g.setPointerCapture(ev.pointerId);});nodeLayer.append(g);
  });
  svg.addEventListener('pointerdown',ev=>{moving={pan:true};last=svgPoint(ev);svg.setPointerCapture(ev.pointerId);});
  svg.addEventListener('pointermove',ev=>{if(!moving)return;const point=svgPoint(ev);const dx=point.x-last.x,dy=point.y-last.y;if(moving.pan){box.x-=dx;box.y-=dy;apply();}else{const p=positions.get(moving.n.id);p.x+=dx;p.y+=dy;moving.g.setAttribute('transform',`translate(${p.x},${p.y})`);drawEdges();}last=svgPoint(ev);});
  svg.addEventListener('pointerup',()=>{moving=null;});svg.addEventListener('pointercancel',()=>{moving=null;});
  const zoom=factor=>{const oldW=box.w,oldH=box.h;box.w=Math.max(width*.25,Math.min(width*3,box.w*factor));box.h=box.w*height/width;box.x+=(oldW-box.w)/2;box.y+=(oldH-box.h)/2;apply();};
  const selector = make('select'); selector.setAttribute('aria-label','Inspecionar bloco');
  const emptyOption=make('option','Escolha um bloco para inspecionar');emptyOption.value='';add(selector,emptyOption);
  nodes.forEach(n=>{const opt=make('option',n.label);opt.value=n.id;add(selector,opt);});
  selector.addEventListener('change',()=>{if(inspectors.has(selector.value))inspectors.get(selector.value)();});
  const selectLabel=add(make('label',undefined,'node-select'),make('span','Inspecionar bloco'),selector);
  const tools=add(make('div',undefined,'graph-tools'),make('span','Arraste o fundo ou os blocos. Enter abre os detalhes.'));
  [['Ampliar',()=>zoom(.8)],['Reduzir',()=>zoom(1.25)],['Enquadrar',()=>{box={x:0,y:0,w:width,h:height};apply();}]].forEach(([label,fn])=>{const b=make('button',label);b.addEventListener('click',fn);add(tools,b);});
  add(content,selectLabel,tools,svg,make('p',`${nodes.length} blocos · ${edges.filter(e=>positions.has(e.from)&&positions.has(e.to)).length} ligações visíveis. A posição é visual e não indica ordem de execução.`,'caption'));
}
function renderScreens() {
  if(mode==='actual'){heading('Telas e referências atuais','Uma referência de widget não prova qual condição foi seguida. AuthGate e AppShell também aparecem.');graph(data.actual.screens.filter(has),data.actual.screenEdges,'screens');}
  else {heading('Jornadas planejadas','A navegação será confrontada com contratos e material real durante a implementação.');data.planned.flows.filter(has).forEach(f=>{const card=add(make('article',undefined,'card'),make('h3',f.title));const flow=make('div',undefined,'flow');f.steps.forEach((s,i)=>{if(i)add(flow,make('b','→'));add(flow,make('span',s));});add(card,flow);add($('content'),card);});}
}
function table(headers, rows, action) {
  const t=make('table'),head=make('thead'),hr=make('tr');headers.forEach(h=>add(hr,make('th',h)));add(head,hr);add(t,head);const body=make('tbody');
  rows.forEach(row=>{const tr=make('tr',undefined,action?'clickable':'');row.cells.forEach(c=>add(tr,make('td',c)));if(action){tr.tabIndex=0;tr.setAttribute('role','button');tr.setAttribute('aria-label',row.cells.join(' '));tr.addEventListener('click',()=>action(row.item));tr.addEventListener('keydown',ev=>{if(ev.key==='Enter'||ev.key===' '){ev.preventDefault();action(row.item);}});}add(body,tr);});add(t,body);add($('content'),t);
  if(!rows.length)add($('content'),make('p','Nenhum registro corresponde à busca.','empty'));
}
function renderHttp() {
  if(mode==='planned') {heading('Chamadas propostas','Contratos completos a especificar em OpenAPI antes de gerar cliente. Estas rotas ainda não estão implementadas.');table(['Método','Rota proposta','Envia','Recebe'],(data.planned.contracts||[]).filter(has).map(c=>({item:c,cells:[c.method,c.path,c.input,c.output]})),c=>details(c.path,[['Estado','PLANEJADO'],['Método',c.method],['Envia',c.input],['Recebe',c.output],['Especificação','docs/arquitetura/contratos-v1.md']]));return;}
  heading('Flutter → Fastify','Selecione uma chamada para ver request, tipo de resposta e localizações. Correspondência de método/path não é teste de rede.');
  table(['Método','Literal no Flutter','Correspondência','Resposta declarada'],data.actual.calls.filter(has).map(c=>({item:c,cells:[c.method,c.path,c.matches.length?c.matches.map(r=>r.path).join(', '):'Não resolvida',c.matches.map(r=>JSON.stringify(r.responses)).join('; ')||'Não detectada']})),c=>details(`${c.method} ${c.path}`,[['Chamada Flutter',showSource(c.source)],['Chaves detectadas (data/query)',c.bodyKeys],['Rotas e tipos backend',c.matches.map(r=>`${r.path} | body=${r.requestType||'inline/ausente'} query=${r.queryType||'ausente'} | responses=${JSON.stringify(r.responses)} | ${showSource(r.source)}`)],['Evidência',c.evidence]]));
  add($('content'),make('h3','Inventário de rotas do backend'));
  table(['Método','Rota Fastify','Grupo','Request'],data.actual.routes.filter(has).map(r=>({item:r,cells:[r.method,r.path,r.group,r.requestType||'Inline/ausente']})),r=>details(`${r.method} ${r.path}`,[['Localização',showSource(r.source)],['Body / query',`${r.requestType||'inline/ausente'} / ${r.queryType||'ausente'}`],['Responses declaradas',r.responses],['Casos de uso detectados',r.usecases],['Limite',r.evidence]]));
}
function renderDb(){
  if(mode==='planned'){heading('Modelo lógico proposto','O schema novo será fechado na009 e migrado na010. Não houve SQL aplicado nesta etapa.');(data.planned.entities||[]).filter(has).forEach(e=>{const c=add(make('article',undefined,'card'),make('h3',e.name),make('p',e.description));add($('content'),c);});return;}
  heading('Modelos Prisma atuais','Leitura de schema.prisma do backend externo. Não há conexão ou consulta ao banco.');
  data.actual.models.filter(has).forEach(m=>{const card=add(make('article',undefined,'card'),make('h3',m.name),make('p',m.fields.map(f=>`${f.name}: ${f.type}${f.relation?' ↗':''}`).join(' · ')));const b=make('button','Ver campos e localização');b.addEventListener('click',()=>details(m.name,[['Schema',showSource(m.source)],['Campos',m.fields.map(f=>`${f.name}: ${f.type}${f.relation?' (relação)':''}`)],['Limite','Schema presente não comprova migrations aplicadas no banco.']]));add(card,b);add($('content'),card);});
}
function renderBacklog(){
  heading('Plano de entrega','12 épicos, com histórias, tarefas e subtarefas. A atualização ocorre no backlog.json, nunca por dedução do mapa. S/M/L são tamanhos relativos.');
  let count=0;
  data.backlog.epics.forEach(e=>{
    const stories=e.stories.filter(s=>has(s)||has({id:e.id,title:e.title}));if(!stories.length)return;count+=stories.length;
    const sec=add(make('section',undefined,'epic'),make('h2',`${e.id} · ${e.title}`),make('p',e.outcome));
    stories.forEach(s=>{
      const d=make('details'),summary=add(make('summary'),tagEl(labelStatus[s.status],s.status),make('strong',` ${s.id} · ${s.title} `),tagEl(s.release),tagEl(s.size));add(d,summary);
      const body=make('div',undefined,'story-body');add(body,make('p',s.userStory),make('p',`Dependências: ${s.dependsOn.join(', ')||'nenhuma'} · Requisitos: ${s.requirements.join(', ')}`));
      const list=(title,items)=>{const ul=make('ul');items.forEach(x=>add(ul,make('li',x)));add(body,make('h4',title),ul);};
      list('Critérios de aceite',s.acceptance);
      s.tasks.forEach(t=>list(`${t.id} · ${t.title}`,t.subtasks));
      list('Validação',s.validation);list('Entregas',s.deliverables);list('Entradas',s.inputs);add(body,make('h4','Handoff'),make('p',s.handoff));
      if(s.completionEvidence.length)list('Evidência de conclusão',s.completionEvidence.map(x=>typeof x==='string'?x:JSON.stringify(x)));
      add(d,body);d.addEventListener('toggle',()=>{if(d.open)details(s.id,[['Estado',labelStatus[s.status]],['Depende de',s.dependsOn],['Requisitos',s.requirements],['Evidências de conclusão',s.completionEvidence.length?s.completionEvidence:['Ainda não implementada.']]]);});add(sec,d);
    });add($('content'),sec);
  });if(!count)add($('content'),make('p','Nenhuma história corresponde à busca.','empty'));
}
function renderFindings(){heading('Achados do código','Inspeção estática revisada. Não são CVEs confirmadas, contagem de scanner nem falhas de produção observadas.');data.actual.findings.filter(has).forEach(f=>{const card=add(make('article',undefined,'card'),tagEl(f.priority),tagEl(f.story),make('h3',`${f.id} · ${f.title}`),make('p',f.detail),make('p',`${f.evidence}:${f.line}`));const b=make('button','Ver contexto');b.addEventListener('click',()=>details(f.title,[['Status',f.status],['Evidência',`${f.evidence}:${f.line}`],['Arquivo presente',f.exists?'Sim':'Não — revisar localização'],['História',f.story],['Limites',f.detail]]));add(card,b);add($('content'),card);});}
async function refresh(force=false){
  if(busy)return;busy=true;
  try{
    const response=await fetch('/api/mapa',{cache:'no-store'});if(!response.ok)throw new Error(`Inventário indisponível (HTTP ${response.status}). Execute a validação local.`);
    const next=await response.json();const changed=next.revision!==revision;data=next;
    $('error').hidden=true;$('connection').textContent='● Conectado · atualização automática';
    if(changed||force){revision=next.revision;renderMetrics();render();}
    $('updated').textContent=`Inventário: ${new Date(data.actual.generatedAt).toLocaleString('pt-BR')} · Backend ${data.actual.coverage.apiAvailable?'encontrado':'AUSENTE: confira --api-root'} · Revisão ${revision.slice(0,10)}`;
  }catch(error){$('connection').textContent='○ Sem conexão local';$('error').hidden=false;$('error').textContent=`${error.message} O último mapa exibido pode estar desatualizado. Inicie tools/abrir-painel.ps1 para retomar.`;}finally{busy=false;}
}
$('tabs').addEventListener('click',event=>{const b=event.target.closest('[data-tab]');if(b){tab=b.dataset.tab;render();}});
$('actual').addEventListener('click',()=>{mode='actual';render();});$('planned').addEventListener('click',()=>{mode='planned';render();});
$('search').addEventListener('input',event=>{search=event.target.value;render();});$('refresh').addEventListener('click',()=>refresh(true));
refresh();setInterval(()=>{if(!document.hidden)refresh();},3000);document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh();});
