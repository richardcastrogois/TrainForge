
"""Generate editable draw.io and standalone SVGs from reviewed, public diagram sources."""
from __future__ import annotations
import argparse
import html
import json
from pathlib import Path
import textwrap
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT/'docs/arquitetura/diagramas'
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

def api_markdown(spec):
    """Route list comes from the same specification consumed by Swagger UI."""
    rows=[]
    for route, operations in sorted(spec.get('paths', {}).items()):
        for method, operation in sorted(operations.items()):
            if method.upper() not in {'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'}:
                continue
            path=spec.get('basePath', '').rstrip('/')+'/'+route.lstrip('/')
            tags=', '.join(operation.get('tags', [])) or 'sem tag'
            security=operation.get('security', spec.get('security', []))
            auth='Bearer / titular' if any('BearerAuth' in value for value in security) else 'Pública'
            if path.startswith('/api/v1/auth/'):
                auth='Credencial do fluxo; ver contrato'
            rows.append((method.upper(), path, tags, auth))
    text='# APIs atuais\n\n'
    text+='> Gerado por `tools/gerar_diagramas.py` de `contracts/generated/swagger-v1.json`; não editar à mão.\n\n'
    text+=f"API **{spec['info']['version']}**, **{len(rows)} operações**. [Contrato completo](../../../contracts/generated/swagger-v1.json) · [Modelo e regras](../modelo-e-contratos.md) · [Arquitetura](../README.md).\n\n"
    text+='Com a API iniciada, Swagger local: `http://127.0.0.1:8082/docs/index.html`. Operação documentada não implica aceite funcional ou prática autorizada.\n\n'
    text+='| Método | Rota | Área | Autorização |\n|---|---|---|---|\n'
    text+=''.join('| '+' | '.join(row)+' |\n' for row in rows)
    text+='\n## Ler uma chamada\n\n'
    text+='Consulta: tela → repository Flutter → AppDio → handler Go → consulta parametrizada → JSON → tela. Escrita: revisão da pessoa → requisição privada → sessão/titular/revisão → transação/idempotência → resposta confirmada. O celular não consulta tabelas diretamente.\n\n'
    text+='As cinco leituras do catálogo passam pela API para o processo separado. Execução usa ocorrências e eventos reais; seleção/adesão, conteúdo, agenda, foto e master conservam critérios próprios. [Camadas e fluxos](../camadas-e-fluxos.md).\n'
    return text


def diagram_index(data):
    text='# Mapas do TrainForge\n\n'
    text+='> Índice gerado de `mapas.json` por `tools/gerar_diagramas.py`; não editar à mão.\n\n'
    text+='Comece por produto, arquitetura e telas. Abra [o índice visual](index.html) localmente ou cada SVG no navegador/editor. O [arquivo draw.io](trainforge.drawio) contém os mesmos 15 mapas em páginas separadas, editáveis no draw.io Desktop/extensão VS Code.\n\n'
    text+='| Página | Mapa | Prévia |\n|---|---|---|\n'
    for i,d in enumerate(data['diagrams'],1):
        text+=f"| {i:02} | {d['title']} | [SVG]({d['id']}.svg) |\n"
    text+='\nVerde: existente; amarelo: parcial; cinza tracejado: planejado; lilás: externo. Setas de tela representam navegação; HTTP/SQL representam comunicação; FK representa referência, sem ordem de INSERT. Uma tabela pode aparecer repetida para manter as relações legíveis.\n\n'
    text+='[APIs](apis.md) · [Tabelas e colunas](banco.md) · [Arquitetura explicada](../README.md) · [Operação diária](../../aprendizado/operacao-local.md).\n\n'
    text+='Fontes revisadas: `mapas.json`; metadados sem registros: `schema-publico.json`. Alterar a fonte e regenerar; uma edição direta do derivado é substituída na próxima geração. O snapshot de schema conserva sua data original, sem alegar nova consulta ao banco.\n\n'
    text+='Aplicada a skill [draw-io-diagram-generator](https://github.com/github/awesome-copilot/tree/5269f7ea2d6c3a9bfda5ed878b6726cf509121fd/skills/draw-io-diagram-generator), fixada nessa revisão. Arquivos locais, sem envio a serviço externo e sem conteúdo de fornecedor copiado.\n'
    return text


def diagram_html(data):
    nav=''.join(f'<li><a href="#{html.escape(d["id"], quote=True)}">{html.escape(d["title"])}</a></li>' for d in data['diagrams'])
    figures=''.join(f'<section id="{html.escape(d["id"], quote=True)}"><h2>{html.escape(d["title"])}</h2><p>{html.escape(d["note"])}</p><a href="{html.escape(d["id"], quote=True)}.svg"><img loading="lazy" src="{html.escape(d["id"], quote=True)}.svg" alt="{html.escape(d["title"], quote=True)}"></a></section>' for d in data['diagrams'])
    return ('<!doctype html>\n<html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>Mapas do TrainForge</title><style>body{margin:0 auto;padding:24px;max-width:1200px;font:17px/1.6 system-ui,sans-serif;color:#18332e;background:#f6f8f7}a{color:#245744}nav,section{background:white;border:1px solid #d4dfda;border-radius:12px;padding:24px;margin:24px 0}img{display:block;width:100%;height:auto}h1,h2{line-height:1.3}section{scroll-margin-top:20px}</style>'
            '<body><h1>Mapas do TrainForge</h1><p>Fontes revisadas em mapas.json. Verde: existente; amarelo: parcial; cinza: planejado; lilás: externo.</p>'
            '<p><a href="trainforge.drawio">Editar as 15 páginas no draw.io</a> · <a href="README.md">Índice em Markdown</a> · <a href="apis.md">APIs</a> · <a href="banco.md">Banco</a></p>'
            f'<nav aria-label="Mapas"><ol>{nav}</ol></nav>{figures}</body></html>\n')


def outputs(root=ROOT):
    directory=root/'docs/arquitetura/diagramas'
    data=json.loads((directory/'mapas.json').read_text(encoding='utf-8'))
    result={}
    combined=ET.Element('mxfile', host='Electron', version='26.0.0', modified='2026-11-16T00:00:00Z')
    ids=[d['id'] for d in data['diagrams']]
    if len(ids)!=len(set(ids)):
        raise ValueError('Duplicate diagram id')
    for d in data['diagrams']:
        for source in d['sources']:
            if not (root/source).exists():raise ValueError('Missing source: '+source)
        xml,svg=generate(d)
        combined.append(ET.fromstring(xml).find('diagram'))
        result[directory/(d['id']+'.svg')]=svg
    result[directory/'trainforge.drawio']=ET.tostring(combined, encoding='unicode')+'\n'
    result[directory/'README.md']=diagram_index(data)
    result[directory/'index.html']=diagram_html(data)
    spec=json.loads((root/'contracts/generated/swagger-v1.json').read_text(encoding='utf-8'))
    result[directory/'apis.md']=api_markdown(spec)
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
    count=sum(path.suffix=='.svg' for path in generated)
    print(f'{count} mapas SVG, um draw.io multipáginas e três índices verificados; sem rede ou dados privados.')

if __name__=='__main__':main()
