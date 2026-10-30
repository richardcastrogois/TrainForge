
"""Generate editable draw.io and standalone SVGs from reviewed, public diagram sources."""
from __future__ import annotations
import argparse
import html
import json
from pathlib import Path
import textwrap
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT/'docs/diagramas'
COLORS = {'atual': ('#d5e8d4', '#52734d', 'EXISTENTE'),
          'parcial': ('#fff2cc', '#9c7b18', 'PARCIAL'),
          'planejado': ('#f5f5f5', '#777777', 'PLANEJADO'),
          'externo': ('#e1d5e7', '#756080', 'EXTERNO')}

def lines(value, width):
    return [part for raw in value.splitlines() for part in textwrap.wrap(raw, width=width)] or ['']

def layout(diagram):
    """ER relationships are independent pairs, so no unreadable crossing lines."""
    if diagram['id'].startswith(('11-', '12-', '13-', '14-', '15-')):
        nodes = {n['id']: n for n in diagram['nodes']}
        pairs = diagram['edges']
        used = {e[k] for e in pairs for k in ('from', 'to')}
        positioned, edges = [], []
        for i, edge in enumerate(pairs):
            for j, key in enumerate(('from', 'to')):
                node = dict(nodes[edge[key]], id=f'pair-{i}-{j}', x=70+j*540, y=190+i*230)
                positioned.append(node)
            edges.append({'from': f'pair-{i}-0', 'to': f'pair-{i}-1', 'label': 'referencia (FK)'})
        y = 190+len(pairs)*230
        for i, name in enumerate(sorted(set(nodes)-used)):
            positioned.append(dict(nodes[name], x=70+(i%2)*540, y=y+(i//2)*230))
        return positioned, edges
    cols = diagram['columns']
    return [dict(n, x=60+(i%cols)*390, y=190+(i//cols)*270) for i,n in enumerate(diagram['nodes'])], diagram['edges']

def generate(diagram):
    positions, edges = layout(diagram)
    width = max(n['x']+330 for n in positions)+60
    content_bottom = max(n['y']+180 for n in positions)
    footer = [] if int(diagram['id'][:2]) >= 11 else [by for by in diagram['edges']]
    height = content_bottom+80+len(footer)*26
    mx = ET.Element('mxfile', host='Electron', version='26.0.0', modified='2026-10-29T00:00:00Z')
    page = ET.SubElement(mx, 'diagram', id=diagram['id'], name=diagram['title'])
    model = ET.SubElement(page, 'mxGraphModel', grid='1', gridSize='10', page='1',
                          pageWidth=str(width), pageHeight=str(height), math='0', shadow='0')
    root = ET.SubElement(model, 'root')
    ET.SubElement(root, 'mxCell', id='0')
    ET.SubElement(root, 'mxCell', id='1', parent='0')
    def cell(id, label, x,y,w,h,style):
        c=ET.SubElement(root,'mxCell',id=id,value=label,style=style,vertex='1',parent='1')
        ET.SubElement(c,'mxGeometry',x=str(x),y=str(y),width=str(w),height=str(h),attrib={'as':'geometry'})
    cell('title', diagram['title'],40,30,width-80,40,
         'text;html=1;whiteSpace=wrap;fontSize=18;fontStyle=1;align=left;')
    note='\n'.join(lines(diagram['note'],min(125,int((width-80)/8))))
    cell('note',note,40,85,width-80,80,'text;html=1;whiteSpace=wrap;fontSize=15;align=left;')
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img">',
         f'<title>{html.escape(diagram["title"])}</title>',
         '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#64748b"/></marker></defs>',
         f'<rect width="{width}" height="{height}" fill="#ffffff"/>',
         '<g font-family="Inter,Arial,sans-serif" fill="#18332e">']
    def text(x,y,value,size=17,bold=False):
        svg.append(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{"700" if bold else "400"}">{html.escape(value)}</text>')
    text(40,60,diagram['title'],18,True)
    for i,line in enumerate(note.splitlines()):text(40,100+i*20,line,15)
    by_id={n['id']:n for n in positions}
    # Connectors go behind cards. Each row/column adjacency has a clear gap.
    for i,edge in enumerate(edges):
        a,b=by_id[edge['from']],by_id[edge['to']]
        c=ET.SubElement(root,'mxCell',id=f'e{i}',value=edge['label'],
                        style='edgeStyle=orthogonalEdgeStyle;html=1;fontSize=13;endArrow=block;',
                        edge='1',source=edge['from'],target=edge['to'],parent='1')
        ET.SubElement(c,'mxGeometry',relative='1',attrib={'as':'geometry'})
        if a['y']==b['y']:
            x1,y1=a['x']+330,a['y']+90
            x2,y2=b['x'],b['y']+90
            if x2<x1:x1,y1=a['x'],a['y']+90;x2,y2=b['x']+330,b['y']+90
            path=f'M{x1},{y1} L{x2},{y2}'
        else:
            x1,y1=a['x']+165,a['y']+180
            x2,y2=b['x']+165,b['y']
            mid=(y1+y2)/2
            path=f'M{x1},{y1} L{x1},{mid} L{x2},{mid} L{x2},{y2}'
        svg.append(f'<path d="{path}" fill="none" stroke="#64748b" stroke-width="1.5" marker-end="url(#arrow)"/>')
        # ER pairs have wide gaps. Flow labels live in the editable diagram, while SVG avoids collisions.
        if diagram['id'][:2].isdigit() and int(diagram['id'][:2])>=11:
            text(min(x1,x2)+22,y1-15,edge['label'],13)
    for n in positions:
        fill,stroke,status=COLORS[n.get('state','atual')]
        title=lines(n['title'],31);body=lines(n['text'],35)
        if len(title)>2 or len(body)>5:raise ValueError('Label too long: '+n['id'])
        label=html.escape(status)+'<br><b>'+html.escape(n['title'])+'</b><br>'+html.escape(n['text'])
        cell(n['id'],label,n['x'],n['y'],330,180,
             f'rounded=1;whiteSpace=wrap;html=1;fillColor={fill};strokeColor={stroke};fontSize=17;'
             + ('dashed=1;' if n.get('state')=='planejado' else ''))
        dash=' stroke-dasharray="7 5"' if n.get('state')=='planejado' else ''
        svg.append(f'<rect x="{n["x"]}" y="{n["y"]}" width="330" height="180" rx="15" fill="{fill}" stroke="{stroke}"{dash}/>')
        text(n['x']+18,n['y']+26,status,12,True)
        for i,line in enumerate(title):text(n['x']+18,n['y']+54+i*22,line,18,True)
        for i,line in enumerate(body):text(n['x']+18,n['y']+102+i*18,line,15)
    if footer:
        text(40,content_bottom+40,'Conexões (mesma ordem do arquivo editável)',16,True)
        for i,e in enumerate(footer):
            label=by_id[e['from']]['title']+' → '+by_id[e['to']]['title']+': '+e['label']
            text(40,content_bottom+68+i*26,label,14)
    svg.append('</g></svg>\n')
    return ET.tostring(mx,encoding='unicode')+'\n','\n'.join(svg)

def outputs():
    data=json.loads((DIRECTORY/'mapas.json').read_text(encoding='utf-8'))
    result={}
    for d in data['diagrams']:
        for source in d['sources']:
            if not (ROOT/source).exists():raise ValueError('Missing source: '+source)
        xml,svg=generate(d)
        result[DIRECTORY/(d['id']+'.drawio')]=xml
        result[DIRECTORY/(d['id']+'.svg')]=svg
    return result

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    generated=outputs()
    for path,value in generated.items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8')!=value:
                raise SystemExit('Diagram diverged: '+path.name)
        else:path.write_text(value,encoding='utf-8')
    print(f'{len(generated)//2} diagramas XML/SVG verificados; sem rede ou dados privados.')

if __name__=='__main__':main()
