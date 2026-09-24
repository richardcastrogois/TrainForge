// Executar no Scripter, dentro do arquivo TrainForge. Não faz chamadas de rede.
// Rotas e nomes são inseridos pelo gerador. Os campos permanecem ilustrativos.
const routeSpecs = __ROUTES__;
const expectedNames = __NAMES__;
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
