const p=figma.currentPage;
const fs=p.children.filter(n=>n.type==='FRAME'&&/^\d+ · /.test(n.name)&&!n.name.startsWith('00'));
const get=i=>fs.find(f=>parseInt(f.name)===i);
let changed=0;
for(const f of [get(1),get(55)])for(const n of f.findAll(n=>n.reactions&&n.reactions.length)){
 const rs=JSON.parse(JSON.stringify(n.reactions));let edit=false;
 for(const r of rs)for(const a of r.actions||[])if(a.type==='NODE'){
  const target=fs.find(t=>t.id===a.destinationId);const num=target?parseInt(target.name):0;
  if((f===get(1)&&[2,4,5,6,7].includes(num))||(f===get(55)&&num===3)){a.destinationId=get(num+25).id;edit=true;}
 }
 if(edit){await n.setReactionsAsync(rs);changed++;}
}
const report=JSON.parse(p.getPluginData('trainforge-v04-report'));
print('SCREENS '+report.screens+' | ROUTES '+report.routes+' | BROKEN '+report.broken+' | OVERFLOW '+report.overflow.length+' | LOADING_LINKS '+changed);
p.selection=[get(7)];figma.viewport.scrollAndZoomIntoView([get(7)]);
