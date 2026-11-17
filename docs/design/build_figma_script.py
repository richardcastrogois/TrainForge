"""Reproduce the historical v0.3 transfer files locally; never write to Figma."""
from pathlib import Path
import argparse
import json
root=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=root.parents[1]/'.local/design-generated',
                    help='Directory for derived files (default: .local/design-generated)')
output=parser.parse_args().output.resolve()
output.mkdir(parents=True, exist_ok=True)
routes=json.loads((root/'fluxos-v03/routes-all.json').read_text(encoding='utf-8'))
names={str(a['n']):a['name'] for a in json.loads((root/'fluxos-v03/manifest-all.json').read_text(encoding='utf-8'))}
assert len(routes)==83 and len(names)==33
assert all(str(r['from']) in names and str(r['to']) in names for r in routes)
template=(root/'finish_figma_template.js').read_text(encoding='utf-8')
code=template.replace('__ROUTES__',json.dumps(routes,ensure_ascii=False)).replace('__NAMES__',json.dumps(names,ensure_ascii=False))
(output/'finish_figma.scripter.js').write_text(code,encoding='utf-8')
(output/'script-transfer.html').write_text('<!doctype html><meta charset="utf-8"><title>TrainForge · Script de conexões</title><textarea aria-label="Script de conexões">'+__import__('html').escape(code)+'</textarea>',encoding='utf-8')
print(f'Histórico v0.3 reproduzido em {output}: 33 telas, 83 rotas. Não aplicado ao Figma.')
