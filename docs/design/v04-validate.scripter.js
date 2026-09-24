const p=figma.currentPage;
const frames=p.children.filter(n=>n.type==='FRAME'&&/^\d+ · /.test(n.name)&&!n.name.startsWith('00'));
const get=i=>frames.find(f=>parseInt(f.name)===i);
const board=p.children.find(n=>n.name==='00 · Destinos e percursos v0.4');
const special=[get(8).id,get(7).id,board.id];
p.flowStartingPoints=[...(p.flowStartingPoints||[]).filter(s=>!special.includes(s.nodeId)),{name:'TrainForge · início',nodeId:get(8).id},{name:'TrainForge · perfil',nodeId:get(7).id},{name:'TrainForge · rotas v0.4',nodeId:board.id}];
const ids=new Set(frames.map(f=>f.id));let routes=0,broken=[],edges=[];
for(const f of frames)for(const n of [f,...f.findAll(n=>n.reactions&&n.reactions.length)])for(const r of n.reactions||[])for(const a of r.actions||[]){if(a.type==='NODE'){routes++;if(a.destinationId&&!ids.has(a.destinationId))broken.push(n.id);else if(a.destinationId)edges.push([f.id,a.destinationId]);}}
const reachable=new Set([get(8).id]);for(let i=0;i<frames.length;i++)for(const [a,b]of edges)if(reachable.has(a))reachable.add(b);
const orphans=frames.filter(f=>!reachable.has(f.id)).map(f=>f.name);
let overflow=[];for(const f of frames.filter(n=>n.getPluginData('tf-v04')))for(const t of f.findAll(n=>n.type==='TEXT')){const a=t.absoluteBoundingBox,b=f.absoluteBoundingBox;if(a.x<b.x||a.y<b.y||a.x+a.width>b.x+b.width+.5||a.y+a.height>b.y+b.height+.5)overflow.push(f.name+' / '+t.characters);}
const report={version:'0.4',screens:frames.length,routes,broken:broken.length,orphans,overflow,profile:get(7).id,personal:get(34).id,board:board.id};
p.setPluginData('trainforge-v04-report',JSON.stringify(report));
for(const t of get(7).findAll(n=>n.type==='TEXT'&&n.characters.includes('v0.2'))){for(const seg of t.getStyledTextSegments(['fontName']))await figma.loadFontAsync(seg.fontName);t.characters=t.characters.replace('v0.2','v0.4');}
p.selection=[get(7)];figma.viewport.scrollAndZoomIntoView([get(7)]);figma.commitUndo();
print('TELAS '+report.screens+'\nROTAS '+report.routes+'\nQUEBRADAS '+report.broken+'\nSEM ACESSO '+report.orphans.length+'\nOVERFLOW '+report.overflow.length+'\nMAPA '+report.board);
