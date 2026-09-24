from pathlib import Path
import json
root=Path(__file__).resolve().parent
routes=json.loads((root/'fluxos-v03/routes-all.json').read_text(encoding='utf-8'))
names={str(a['n']):a['name'] for a in json.loads((root/'fluxos-v03/manifest-all.json').read_text(encoding='utf-8'))}
assert len(routes)==83 and len(names)==33
assert all(str(r['from']) in names and str(r['to']) in names for r in routes)
template=(root/'finish_figma_template.js').read_text(encoding='utf-8')
code=template.replace('__ROUTES__',json.dumps(routes,ensure_ascii=False)).replace('__NAMES__',json.dumps(names,ensure_ascii=False))
(root/'finish_figma.scripter.js').write_text(code,encoding='utf-8')
(root/'script-transfer.html').write_text('<!doctype html><meta charset="utf-8"><title>TrainForge · Script de conexões</title><textarea aria-label="Script de conexões">'+__import__('html').escape(code)+'</textarea>',encoding='utf-8')
print('Script preparado: 33 telas, 83 rotas, validação antes e depois da aplicação.')
