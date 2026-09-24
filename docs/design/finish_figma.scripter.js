// Executar no Scripter, dentro do arquivo TrainForge. Não faz chamadas de rede.
// Rotas e nomes são inseridos pelo gerador. Os campos permanecem ilustrativos.
const routeSpecs = [{"from": 1, "label": "Abrir Perfil", "to": 7, "rect": [322, 48, 46, 46], "hotspot": true}, {"from": 1, "label": "Abrir Planos", "to": 2, "rect": [95, 754, 62, 70], "hotspot": true}, {"from": 1, "label": "Abrir Atividade", "to": 4, "rect": [164, 754, 62, 70], "hotspot": true}, {"from": 1, "label": "Abrir Diário", "to": 5, "rect": [233, 754, 62, 70], "hotspot": true}, {"from": 1, "label": "Abrir Evolução", "to": 6, "rect": [302, 754, 62, 70], "hotspot": true}, {"from": 1, "label": "Abrir treino", "to": 3, "rect": [24, 190, 342, 237], "hotspot": true}, {"from": 1, "label": "Abrir rotina", "to": 25, "rect": [24, 577, 342, 76], "hotspot": true}, {"from": 1, "label": "Abrir alimentação pendente", "to": 24, "rect": [24, 661, 342, 76], "hotspot": true}, {"from": 2, "label": "Abrir Perfil", "to": 7, "rect": [322, 48, 46, 46], "hotspot": true}, {"from": 2, "label": "Abrir Hoje", "to": 1, "rect": [26, 754, 62, 70], "hotspot": true}, {"from": 2, "label": "Abrir Atividade", "to": 4, "rect": [164, 754, 62, 70], "hotspot": true}, {"from": 2, "label": "Abrir Diário", "to": 5, "rect": [233, 754, 62, 70], "hotspot": true}, {"from": 2, "label": "Abrir Evolução", "to": 6, "rect": [302, 754, 62, 70], "hotspot": true}, {"from": 2, "label": "Escolher plano", "to": 3, "rect": [24, 301, 342, 221], "hotspot": true}, {"from": 3, "label": "Voltar a Hoje", "to": 1, "rect": [20, 50, 44, 44], "hotspot": true}, {"from": 3, "label": "Finalizar treino", "to": 6, "rect": [24, 749, 342, 50], "hotspot": true}, {"from": 4, "label": "Abrir Perfil", "to": 7, "rect": [322, 48, 46, 46], "hotspot": true}, {"from": 4, "label": "Abrir Hoje", "to": 1, "rect": [26, 754, 62, 70], "hotspot": true}, {"from": 4, "label": "Abrir Planos", "to": 2, "rect": [95, 754, 62, 70], "hotspot": true}, {"from": 4, "label": "Abrir Diário", "to": 5, "rect": [233, 754, 62, 70], "hotspot": true}, {"from": 4, "label": "Abrir Evolução", "to": 6, "rect": [302, 754, 62, 70], "hotspot": true}, {"from": 5, "label": "Abrir Perfil", "to": 7, "rect": [322, 48, 46, 46], "hotspot": true}, {"from": 5, "label": "Abrir Hoje", "to": 1, "rect": [26, 754, 62, 70], "hotspot": true}, {"from": 5, "label": "Abrir Planos", "to": 2, "rect": [95, 754, 62, 70], "hotspot": true}, {"from": 5, "label": "Abrir Atividade", "to": 4, "rect": [164, 754, 62, 70], "hotspot": true}, {"from": 5, "label": "Abrir Evolução", "to": 6, "rect": [302, 754, 62, 70], "hotspot": true}, {"from": 6, "label": "Abrir Perfil", "to": 7, "rect": [322, 48, 46, 46], "hotspot": true}, {"from": 6, "label": "Abrir Hoje", "to": 1, "rect": [26, 754, 62, 70], "hotspot": true}, {"from": 6, "label": "Abrir Planos", "to": 2, "rect": [95, 754, 62, 70], "hotspot": true}, {"from": 6, "label": "Abrir Atividade", "to": 4, "rect": [164, 754, 62, 70], "hotspot": true}, {"from": 6, "label": "Abrir Diário", "to": 5, "rect": [233, 754, 62, 70], "hotspot": true}, {"from": 7, "label": "Voltar a Hoje", "to": 1, "rect": [20, 102, 44, 44], "hotspot": true}, {"from": 7, "label": "Editar dados", "to": 18, "rect": [24, 151, 342, 184], "hotspot": true}, {"from": 7, "label": "Editar objetivos", "to": 15, "rect": [24, 427, 342, 48], "hotspot": true}, {"from": 7, "label": "Sair da conta", "to": 10, "rect": [24, 729, 342, 44], "hotspot": true}, {"from": 8, "trigger": "after-delay", "to": 9, "delayMs": 250}, {"from": 9, "trigger": "after-delay", "to": 10, "delayMs": 250}, {"from": 10, "label": "Esqueci a palavra-passe", "to": 12, "rect": [24, 343, 342, 30]}, {"from": 10, "label": "Entrar", "to": 26, "rect": [24, 383, 342, 48]}, {"from": 10, "label": "Continuar com Google", "to": 14, "rect": [24, 441, 342, 48]}, {"from": 10, "label": "Continuar com Apple · iOS", "to": 14, "rect": [24, 499, 342, 48]}, {"from": 10, "label": "Ainda não tenho conta", "to": 11, "rect": [24, 557, 342, 30]}, {"from": 11, "label": "Criar a minha conta", "to": 13, "rect": [24, 555, 342, 48]}, {"from": 11, "label": "Já tenho conta", "to": 10, "rect": [24, 613, 342, 30]}, {"from": 12, "label": "Enviar instruções", "to": 33, "rect": [24, 318, 342, 48]}, {"from": 12, "label": "Voltar ao login", "to": 10, "rect": [24, 376, 342, 30]}, {"from": 13, "label": "Já confirmei o e-mail", "to": 14, "rect": [24, 283, 342, 48]}, {"from": 13, "label": "Corrigir o endereço", "to": 11, "rect": [24, 381, 342, 30]}, {"from": 14, "label": "Escolher por onde começar", "to": 15, "rect": [24, 533, 342, 48]}, {"from": 15, "label": "Configurar o meu treino", "to": 16, "rect": [24, 283, 342, 48]}, {"from": 15, "label": "Configurar alimentação", "to": 19, "rect": [24, 341, 342, 48]}, {"from": 15, "label": "Organizar a minha rotina", "to": 21, "rect": [24, 399, 342, 48]}, {"from": 15, "label": "Explorar e preencher depois", "to": 23, "rect": [24, 457, 342, 30]}, {"from": 16, "label": "Continuar para disponibilidade", "to": 17, "rect": [24, 476, 342, 48]}, {"from": 16, "label": "Voltar às áreas", "to": 15, "rect": [24, 534, 342, 30]}, {"from": 17, "label": "Continuar para dados opcionais", "to": 18, "rect": [24, 501, 342, 48]}, {"from": 17, "label": "Voltar ao objetivo", "to": 16, "rect": [24, 559, 342, 30]}, {"from": 18, "label": "Guardar preferências de treino", "to": 22, "rect": [24, 492, 342, 48]}, {"from": 18, "label": "Continuar sem estes dados", "to": 22, "rect": [24, 550, 342, 30]}, {"from": 19, "label": "Continuar para horários", "to": 20, "rect": [24, 492, 342, 48]}, {"from": 19, "label": "Configurar alimentação depois", "to": 24, "rect": [24, 550, 342, 30]}, {"from": 20, "label": "Guardar e abrir o diário", "to": 5, "rect": [24, 492, 342, 48]}, {"from": 20, "label": "Voltar às preferências", "to": 19, "rect": [24, 550, 342, 30]}, {"from": 21, "label": "Guardar a minha rotina", "to": 1, "rect": [24, 580, 342, 48]}, {"from": 21, "label": "Configurar rotina depois", "to": 25, "rect": [24, 638, 342, 30]}, {"from": 22, "label": "Explorar os planos", "to": 2, "rect": [24, 462, 342, 48]}, {"from": 22, "label": "Configurar alimentação agora", "to": 19, "rect": [24, 520, 342, 48]}, {"from": 22, "label": "Rever preferências de treino", "to": 16, "rect": [24, 578, 342, 30]}, {"from": 23, "label": "Configurar treino", "to": 16, "rect": [24, 337, 342, 48]}, {"from": 23, "label": "Já tenho um plano", "to": 2, "rect": [24, 395, 342, 48]}, {"from": 23, "label": "Configurar outras áreas", "to": 15, "rect": [24, 453, 342, 30]}, {"from": 24, "label": "Configurar alimentação", "to": 19, "rect": [24, 337, 342, 48]}, {"from": 24, "label": "Voltar a Hoje", "to": 1, "rect": [24, 395, 342, 30]}, {"from": 25, "label": "Criar a minha rotina", "to": 21, "rect": [24, 283, 342, 48]}, {"from": 25, "label": "Voltar a Hoje", "to": 1, "rect": [24, 341, 342, 30]}, {"from": 33, "label": "Voltar ao login", "to": 10, "rect": [24, 283, 342, 48]}, {"from": 26, "trigger": "after-delay", "to": 1, "delayMs": 350}, {"from": 27, "trigger": "after-delay", "to": 2, "delayMs": 350}, {"from": 28, "trigger": "after-delay", "to": 3, "delayMs": 350}, {"from": 29, "trigger": "after-delay", "to": 4, "delayMs": 350}, {"from": 30, "trigger": "after-delay", "to": 5, "delayMs": 350}, {"from": 31, "trigger": "after-delay", "to": 6, "delayMs": 350}, {"from": 32, "trigger": "after-delay", "to": 7, "delayMs": 350}];
const expectedNames = {"1": "01 · Hoje", "2": "02 · Planos", "3": "03 · Treino em curso", "4": "04 · Atividade", "5": "05 · Alimentação", "6": "06 · Evolução", "7": "07 · Perfil", "8": "08 · Abertura A", "9": "09 · Abertura B", "10": "10 · Entrar", "11": "11 · Criar conta", "12": "12 · Recuperar acesso", "13": "13 · Confirmar e-mail", "14": "14 · Antes de começar", "15": "15 · Escolher áreas", "16": "16 · Treino · objetivo", "17": "17 · Treino · contexto", "18": "18 · Treino · dados opcionais", "19": "19 · Alimentação · preferências", "20": "20 · Alimentação · horários", "21": "21 · Rotina · configurar", "22": "22 · Rever configuração", "23": "23 · Planos · por configurar", "24": "24 · Diário · por configurar", "25": "25 · Rotina · por configurar", "33": "33 · Recuperação · enviada", "26": "26 · A carregar · hoje", "27": "27 · A carregar · planos", "28": "28 · A carregar · sessao", "29": "29 · A carregar · atividade", "30": "30 · A carregar · alimentacao", "31": "31 · A carregar · evolucao", "32": "32 · A carregar · perfil"};
if (figma.fileKey && figma.fileKey !== 'bX6YjBBLIJgoo2MtiFLntl') throw Error('Abra o arquivo TrainForge correto.');
const page = figma.currentPage;
if (page.name !== '01 · Proposta mobile') throw Error('Selecione a página 01 · Proposta mobile.');
const frames = {};
for (const [number, name] of Object.entries(expectedNames)) {
  const matches = page.children.filter(n => n.type === 'FRAME' && n.name === name);
  if (matches.length !== 1) throw Error('Quadro ausente ou duplicado: ' + name);
  frames[number] = matches[0];
}
// Resolver tudo antes de editar. Nunca conectar o quadro inteiro por engano.
const resolved = routeSpecs.map(r => {
  const source = frames[r.from], destination = frames[r.to];
  let node = source;
  if (r.label) {
    const matches = source.findAll(n => n.type === 'TEXT' && n.characters === r.label);
    if (matches.length !== 1 || matches[0].parent.type !== 'GROUP') throw Error('Botão ambíguo: ' + r.from + ' / ' + r.label);
    node = matches[0].parent;
  }
  if (!destination) throw Error('Destino inexistente');
  return {r, node, source, destination};
});
const fontNames = new Map();
for (const f of Object.values(frames)) for (const t of f.findAll(n => n.type === 'TEXT')) {
  for (const segment of t.getStyledTextSegments(['fontName'])) fontNames.set(JSON.stringify(segment.fontName), segment.fontName);
}
await Promise.all([...fontNames.values()].map(font => figma.loadFontAsync(font)));
await figma.loadFontAsync({family:'Inter', style:'Regular'});
await figma.loadFontAsync({family:'Inter', style:'Bold'});
const setReactions = async (node, reactions) => {
  if (typeof node.setReactionsAsync === 'function') await node.setReactionsAsync(reactions);
  else node.reactions = reactions;
};
const mutatedNodeIds = [], createdNodeIds = [];
figma.commitUndo();
// Limpar somente reações indevidas dos quadros deste esboço.
for (const frame of Object.values(frames)) {
  await setReactions(frame, []);
  mutatedNodeIds.push(frame.id);
}
for (const {r,node,destination} of resolved) {
  const transition = r.from === 8 ? {type:'SMART_ANIMATE', duration:0.2, easing:{type:'EASE_IN_AND_OUT'}} : null;
  await setReactions(node, [{
    trigger: r.trigger === 'after-delay' ? {type:'AFTER_TIMEOUT', timeout:r.delayMs/1000} : {type:'ON_CLICK'},
    actions:[{type:'NODE', destinationId:destination.id, navigation:'NAVIGATE', transition, resetScrollPosition:true}]
  }]);
  if (r.label) node.name = r.label + ' → ' + destination.name;
  if (r.hotspot) node.opacity = 0.001;
  mutatedNodeIds.push(node.id);
}
// Apenas dados recebem skeleton; pesquisa, filtros e definições continuam visíveis.
function rect(parent,x,y,w,h,hex,radius=16) {
  const node = figma.createRectangle(); parent.appendChild(node);
  node.name='Skeleton · dados';node.x=x;node.y=y;node.resize(w,h);node.cornerRadius=radius;
  node.fills=[{type:'SOLID',color:color(hex)}];createdNodeIds.push(node.id);return node;
}
function color(hex) {return {r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255};}
function clearOverlay(frame, y) {
  const index=frame.children.findIndex(n => Math.abs(n.x-18)<1 && Math.abs(n.y-y)<1 && Math.abs(n.width-354)<1 && n.height>400);
  if(index>=0) for(const n of frame.children.slice(index)) n.remove();
  for(const n of frame.children.filter(n=>n.name==='Skeleton · dados'))n.remove();
}
clearOverlay(frames[27],180);
rect(frames[27],18,294,354,439,'#F6F6F1',8);
for(const [x,y,w,h] of [[24,301,342,221],[24,538,342,76],[24,632,342,87]])rect(frames[27],x,y,w,h,'#E5EBE2',18);
clearOverlay(frames[32],150);
rect(frames[32],24,151,342,184,'#E8EEE3',20);
rect(frames[32],155,170,80,80,'#D6DED2',40);
rect(frames[32],115,270,160,16,'#D6DED2',8);
rect(frames[32],140,298,110,12,'#D6DED2',6);
// Mapa visível para revisão; as setas interativas também ficam no modo Protótipo.
let board=page.children.find(n=>n.name==='00 · Mapa dos fluxos v0.3');
if (!board) {board=figma.createFrame();page.appendChild(board);createdNodeIds.push(board.id);}
else for(const child of [...board.children])child.remove();
board.name='00 · Mapa dos fluxos v0.3';board.x=4300;board.y=240;board.resize(2460,1530);board.fills=[{type:'SOLID',color:color('#E8EEE3')}];
function text(parent,x,y,value,size=22,bold=false) {
  const n=figma.createText();parent.appendChild(n);n.fontName={family:'Inter',style:bold?'Bold':'Regular'};n.fontSize=size;n.characters=value;n.x=x;n.y=y;n.fills=[{type:'SOLID',color:color('#215E52')}];createdNodeIds.push(n.id);return n;
}
text(board,60,45,'TrainForge · Percursos do esboço',42,true);
text(board,60,108,'Clica nos cartões para abrir a tela. No separador Protótipo, seleciona um botão para ver a seta.',22);
const rows=[
 ['Entrada',[8,9,10,11,13,14,15]],
 ['Treino',[15,16,17,18,22,2,3]],
 ['Alimentação',[24,19,20,5]],
 ['Rotina',[25,21,1]],
 ['Conta',[1,7,10,12,33]],
 ['Carregamento',[26,27,28,29,30,31,32]]
];
for(let row=0;row<rows.length;row++) {
  const [label,numbers]=rows[row];const y=210+row*192;
  text(board,60,y-34,label,23,true);
  for(let i=0;i<numbers.length;i++) {
    const num=numbers[i],x=60+i*335;
    const card=figma.createFrame();board.appendChild(card);card.name='Abrir '+expectedNames[num];card.x=x;card.y=y;card.resize(290,110);card.cornerRadius=20;card.fills=[{type:'SOLID',color:color('#FFFFFF')}];createdNodeIds.push(card.id);
    const labelNode=text(card,18,20,expectedNames[num].replace(' · ','\n'),18,true);labelNode.resize(255,70);
    await setReactions(card,[{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:frames[num].id,navigation:'NAVIGATE',transition:null}]}]);
    if(i<numbers.length-1 && row!==5) text(board,x+302,y+33,'→',32);
  }
}
text(board,60,1400,'Dados fictícios · login e formulários simulados · cada área pode ser configurada separadamente.',22);
text(board,60,1440,'Carregamento: a estrutura permanece visível. Os 250–350 ms servem só para demonstrar o estado no protótipo.',20);
page.flowStartingPoints=[{nodeId:frames[8].id,name:'Começar · acesso e configuração'},{nodeId:frames[1].id,name:'Explorar · aplicação'},{nodeId:frames[24].id,name:'Completar · alimentação'},{nodeId:board.id,name:'Mapa · todos os percursos'}];
const invalid=[];
for(const {r,node,destination} of resolved) {
  const reactions=node.reactions;
  if(reactions.length!==1 || !(reactions[0].actions || [reactions[0].action]).some(a=>a&&a.destinationId===destination.id)) invalid.push(r);
}
if(invalid.length)throw Error('Validação falhou em '+invalid.length+' ligações.');
figma.currentPage.selection=[board];figma.viewport.scrollAndZoomIntoView([board]);figma.commitUndo();
print(JSON.stringify({status:'VERIFICADO',screens:33,routes:resolved.length,mapId:board.id,createdNodeIds,mutatedNodeIds}));
