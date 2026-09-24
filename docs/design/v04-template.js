// Figma Desktop / Scripter. Offline. Design only. Idempotent through pluginData.
const spec=__SPEC__;
const page=figma.currentPage;
if(page.name!=='01 · Proposta mobile')throw Error('Abra 01 · Proposta mobile.');
if(figma.fileKey&&figma.fileKey!=='bX6YjBBLIJgoo2MtiFLntl')throw Error('Arquivo incorreto');
const frames={};
for(const f of page.children.filter(n=>n.type==='FRAME')){
 const m=f.name.match(/^(\d+) · /);if(m&&Number(m[1])>0)frames[Number(m[1])]=f;
}
for(let i=1;i<=33;i++)if(!frames[i])throw Error('Tela original ausente: '+i);
await figma.loadFontAsync({family:'Inter',style:'Regular'});
await figma.loadFontAsync({family:'Inter',style:'Bold'});
const C={bg:'#F6F6F1',green:'#215E52',ink:'#142F2C',muted:'#64736E',lime:'#D8EB90',soft:'#E8EEE3',white:'#FFFFFF'};
const rgb=h=>({r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255});
const fill=h=>[{type:'SOLID',color:rgb(h)}];
function box(p,x,y,w,h,c=C.white,r=18){const n=figma.createFrame();p.appendChild(n);n.x=x;n.y=y;n.resize(w,h);n.cornerRadius=r;n.fills=fill(c);n.clipsContent=false;return n;}
function txt(p,x,y,s,size=14,bold=false,col=C.ink,w=304){const n=figma.createText();p.appendChild(n);n.fontName={family:'Inter',style:bold?'Bold':'Regular'};n.fontSize=size;n.characters=s;n.fills=fill(col);n.x=x;n.y=y;n.resize(w,20);n.textAutoResize='HEIGHT';return n;}
const links=[];
function link(n,to){links.push({n,to});n.name+=' → '+to;}
function screen(id,name,index){
 let f=page.children.find(n=>n.getPluginData('tf-v04')===String(id));
 if(f){for(const n of [...f.children])n.remove();}else{f=figma.createFrame();page.appendChild(f);f.setPluginData('tf-v04',String(id));}
 f.name=String(id).padStart(2,'0')+' · '+name;f.x=120+(index%8)*450;f.y=4640+Math.floor(index/8)*1010;f.resize(390,844);f.cornerRadius=32;f.fills=fill(C.bg);f.clipsContent=true;frames[id]=f;return f;
}
function button(p,y,label,to,primary=true){const b=box(p,24,y,342,50,primary?C.green:C.white,17);b.name=label;const t=txt(b,16,15,label,13,true,primary?C.white:C.green,310);t.textAlignHorizontal='CENTER';link(b,to);return b;}
figma.commitUndo();
for(let i=0;i<spec.screens.length;i++){
 const [id,name,sub,back,cards,primary]=spec.screens[i],f=screen(id,name,i);
 txt(f,26,18,'9:41',11,true);txt(f,344,18,'●',10,true,C.ink,22);
 const mark=box(f,24,51,34,34,C.green,11);txt(mark,4,7,'TF',17,true,C.lime,28);txt(f,68,53,'trainforge',24,true,C.green);
 const b=box(f,24,97,92,38,C.soft,13);txt(b,12,10,'← Voltar',12,true,C.green,75);link(b,back);
 txt(f,24,151,name,name.length>26?22:26,true,C.ink,342);
 txt(f,24,191,sub,10,false,C.muted,342);
 let y=226;
 for(const [title,detail,to] of cards){
  const card=box(f,24,y,342,86);card.name=title;
  const a=txt(card,18,16,title,14,true,C.green,to?282:306);
  const t=txt(card,18,20+a.height,detail,11,false,C.muted,306);
  const height=Math.max(80,Math.ceil(t.y+t.height+16));card.resize(342,height);
  if(to){txt(card,313,19,'›',21,false,C.green,18);link(card,to);}
  y+=height+10;
 }
 if(y>728)throw Error('Conteúdo excede área útil: '+id+' / '+y);
 button(f,744,primary[0],primary[1]);txt(f,24,811,'Protótipo · dados e ações de demonstração',9,false,C.muted,342);
 box(f,145,834,100,4,C.ink,2);
}
// Explicit click areas on original screens, placed above the existing artwork.
function hot(id,name,x,y,w,h,to){
 const f=frames[id],tag='v04:'+name;let n=f.children.find(c=>c.getPluginData('tf-hot')===tag);
 if(!n){n=box(f,x,y,w,h,C.white,4);n.setPluginData('tf-hot',tag);}n.x=x;n.y=y;n.resize(w,h);n.opacity=.001;n.name=name;link(n,to);
}
function label(id,value,to){
 const t=frames[id].findOne(n=>n.type==='TEXT'&&n.characters===value);
 if(!t)throw Error('Texto não encontrado: '+id+' / '+value);
 const f=frames[id],a=t.absoluteBoundingBox,b=f.absoluteBoundingBox;
 hot(id,value,Math.max(10,a.x-b.x-10),a.y-b.y-10,Math.min(370,a.width+20),Math.max(40,a.height+20),to);
}
hot(7,'Editar perfil',24,151,342,184,35);
for(const [y,to,name]of [[379,34,'Dados pessoais'],[427,38,'Objetivos'],[475,39,'Notificações'],[523,41,'Idioma e unidades'],[614,43,'Privacidade'],[662,48,'Ajuda']])hot(7,name,24,y,342,48,to);
hot(7,'Terminar sessão',24,729,342,44,52);
hot(2,'Pesquisar planos',24,188,342,46,68);hot(2,'Filtrar planos',24,249,342,36,89);
hot(2,'Detalhe do plano',24,301,342,221,53);hot(2,'Origem',40,444,300,56,54);hot(2,'Trazer o meu plano',24,538,342,76,69);
hot(3,'Consultar instruções',40,280,310,40,57);hot(3,'Editar séries',24,388,342,183,58);
hot(3,'Descanso',24,599,342,61,59);hot(3,'Registar série',24,681,342,52,58);hot(3,'Terminar treino',24,749,342,50,60);
hot(4,'Registar atividade',24,648,342,52,63);
hot(5,'Pequeno-almoço',24,399,342,76,74);hot(5,'Almoço',24,489,342,76,94);hot(5,'Adicionar alimento',24,622,342,52,65);
hot(6,'Histórico completo',24,592,342,76,66);hot(6,'Período de análise',24,170,342,45,66);
hot(1,'Detalhe do dia',24,482,342,88,73);
label(13,'Reenviar e-mail',71);
hot(11,'Termos e privacidade',24,499,342,60,72);
button(frames[72],632,'Ler proposta de privacidade',93,false);
hot(33,'Ver exemplo de redefinição',24,550,342,50,70);
// A visible action, unlike an invisible unlabelled link.
button(frames[33],550,'Ver exemplo de nova palavra-passe',70);
// Review every existing form field. Preserve input presentation; expose an explicit
// prefilled example screen instead of pretending that Figma accepts arbitrary text.
const inputSpecs=__INPUTS__;
const fieldAudit=[];
for(const [source,items]of inputSpecs){
 const id=100+source;
 const f=screen(id,'Rever dados · '+source,spec.screens.length+fieldAudit.length);
 txt(f,24,35,'trainforge',24,true,C.green,342);txt(f,24,94,'Exemplo de preenchimento',23,true,C.ink,342);
 txt(f,24,133,'Campos demonstrativos · sem recolha de dados',11,false,C.muted,342);
 let y=180;
 for(const [key,value]of items){
  txt(f,26,y,key,11,false,C.muted,338);
  const b=box(f,24,y+22,342,55,C.white,14);txt(b,16,13,value,12,false,C.ink,310);y+=97;
  const t=frames[source].findOne(n=>n.type==='TEXT'&&n.characters===key);
  if(t){const a=t.absoluteBoundingBox,p=frames[source].absoluteBoundingBox;hot(source,'Preencher '+key,24,a.y-p.y-5,342,74,id);}
 }
 button(f,744,'Voltar e continuar o percurso',source);txt(f,24,808,'Edição livre e validação real ficam para o aplicativo.',9,false,C.muted,342);
 fieldAudit.push({source,screen:id,fields:items.length});
}
// Apply all destinations and read them back before reporting completion.
for(const {n,to}of links){
 if(!frames[to])throw Error('Destino ausente '+to);
 const reactions=[{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:frames[to].id,navigation:'NAVIGATE',transition:null,resetScrollPosition:true}]}];
 if(n.setReactionsAsync)await n.setReactionsAsync(reactions);else n.reactions=reactions;
}
const bad=links.filter(({n,to})=>!n.reactions.some(r=>r.actions&&r.actions.some(a=>a.destinationId===frames[to].id)));
if(bad.length)throw Error('Rotas não aplicadas: '+bad.length);
// A new explicit flow index extends the existing v0.3 map without destroying it.
let board=page.children.find(n=>n.name==='00 · Destinos e percursos v0.4');
if(!board){board=figma.createFrame();page.appendChild(board);}else for(const c of [...board.children])c.remove();
board.name='00 · Destinos e percursos v0.4';board.x=4300;board.y=2050;board.resize(2500,1720);board.fills=fill(C.soft);
txt(board,60,40,'TrainForge · Percursos completos v0.4',42,true,C.green,2300);
txt(board,60,105,'Toca num cartão para começar. As setas dos botões aparecem no separador Protótipo.',21,false,C.muted,2300);
const groups=[['Perfil e conta',[7,34,35,36,37,52]],['Preferências',[7,38,39,40,41,42]],['Privacidade e ajuda',[43,44,45,46,47,48,50]],['Treino',[2,53,54,55,3,58,60]],['Atividade e evolução',[4,63,64,6,66,67]],['Alimentação',[5,65,86,88,74]],['Entrada e recuperação',[10,11,13,12,33,70]]];
for(let row=0;row<groups.length;row++){
 const [title,ids]=groups[row],y=205+row*203;txt(board,60,y-38,title,23,true,C.green,2000);
 for(let j=0;j<ids.length;j++){const id=ids[j],b=box(board,60+j*340,y,302,112);const t=txt(b,18,20,frames[id].name,18,true,C.green,266);b.reactions=[{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId:frames[id].id,navigation:'NAVIGATE',transition:null}]}];if(j<ids.length-1)txt(board,369+j*340,y+36,'→',24,true,C.green,30);}
}
// Stable Play entry points, retain previous starts.
const starts=page.flowStartingPoints||[];
page.flowStartingPoints=[...starts.filter(s=>![frames[8].id,frames[7].id,board.id].includes(s.nodeId)),{name:'TrainForge · início',nodeId:frames[8].id},{name:'TrainForge · perfil',nodeId:frames[7].id},{name:'TrainForge · rotas v0.4',nodeId:board.id}];
const all=Object.values(frames),ids=new Set(all.map(f=>f.id));let count=0,broken=[];
for(const f of all)for(const n of [f,...f.findAll(n=>n.reactions&&n.reactions.length)])for(const r of n.reactions||[])for(const a of r.actions||[]){if(a.type==='NODE'){count++;if(a.destinationId&&!ids.has(a.destinationId))broken.push(n.id);}}
if(broken.length)throw Error('Conexões externas ao catálogo: '+broken.join(','));
page.selection=[frames[7]];figma.viewport.scrollAndZoomIntoView([frames[7]]);figma.commitUndo();
const report={version:'0.4',screens:all.length,newScreens:spec.screens.length,fieldReviewScreens:fieldAudit.length,fieldsReviewed:fieldAudit.reduce((n,f)=>n+f.fields,0),newLinks:links.length,totalRoutes:count,broken:broken.length};
page.setPluginData('trainforge-v04-report',JSON.stringify(report));
print('TRAINFORGE_V04_OK '+JSON.stringify(report));
