"""Audit received caregiver yoga originals without turning pose lists into scripts."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-protocolos'
TARGETS = [1,5,6,7,11,12,13]


def analyse(render=False):
    rows, originals = [], {}
    for name in ['requisicoes.json','requisicoes-registro.json','requisicoes-protocolo.json']:
        for request in json.loads((FOLDER/name).read_text(encoding='utf-8'))['requests']:
            path = FOLDER/(request['id']+'.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if receipt['url'] != request['url']:
                raise ValueError('Manifest/receipt mismatch')
            usable = receipt['status']==200 and not receipt.get('error')
            if receipt.get('bodyFile'):
                source = (FOLDER/receipt['bodyFile']).resolve()
                if not source.is_relative_to(ROOT.resolve()):
                    raise ValueError('Body outside root')
                body = source.read_bytes()
                if len(body)!=receipt['bytes'] or hashlib.sha256(body).hexdigest()!=receipt['sha256']:
                    raise ValueError('Body integrity mismatch')
                if usable:
                    originals[request['id']] = (source,body)
            elif any(receipt.get(k) is not None for k in ['bytes','sha256']):
                raise ValueError('Missing body cannot acquire hash')
            rows.append({'id':request['id'],'record':path.relative_to(ROOT).as_posix(),
                         'url':receipt['url'],'status':receipt['status'],'bytes':receipt.get('bytes'),
                         'sha256':receipt.get('sha256'),'usableForReading':usable})
    yoga = ET.fromstring(originals['c15-teleyoga2024-xml'][1])
    old = ET.fromstring(originals['c15-yoga2007-xml'][1])
    app = yoga.find(".//app[@id='app1-27536130241240405']")
    if app is None or 'Weekly Class Themes' not in ' '.join(app.itertext()):
        raise ValueError('Wrong teleyoga appendix')
    old_app = old.find(".//sec[@id='APP1']")
    if old_app is None or 'Jennifer Cameron' not in ' '.join(old_app.itertext()):
        raise ValueError('Wrong historical appendix')
    result = yoga.find(".//table-wrap[@id='table3-27536130241240405']")
    if not all(x in ' '.join(result.itertext()) for x in ['Caregivers','energy/fatigue','9.81','.021']):
        raise ValueError('Wrong caregiver result table')
    registry = json.loads(originals['c15-teleyoga2024-registro-json'][1])
    if registry['protocolSection']['identificationModule']['nctId']!='NCT04512040':
        raise ValueError('Wrong teleyoga registry')
    source, body = originals['c15-teleyoga2024-protocolo-pdf']
    if not body.startswith(b'%PDF-'):
        raise ValueError('Protocol is not PDF')
    document = PdfReader(source)
    if len(document.pages)!=15 or 'homework manual' not in document.pages[4].extract_text():
        raise ValueError('Wrong protocol')
    rendered = []
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER/'paginas'
        folder.mkdir(exist_ok=True)
        pdf = pdfium.PdfDocument(str(source))
        for number in TARGETS:
            page = pdf[number-1]
            bitmap = page.render(scale=1.8)
            bitmap.to_pil().save(folder/f'c15-teleyoga2024-protocolo-pagina-{number}.png')
            bitmap.close()
            page.close()
        pdf.close()
        rendered = TARGETS
    inventory = {'niche':'N15-C','date':'2026-10-11','collectorCalls':len(rows),
                 'http200':sum(r['status']==200 for r in rows),
                 'hashedBodies':sum(r['sha256'] is not None for r in rows),
                 'usableBodies':sum(r['usableForReading'] for r in rows),'pdfPages':15,
                 'receipts':rows,'renderedPages':rendered,'renderingIsVisualInspection':False,
                 'networkCallsDuringAnalysis':0,'researchClosureApproved':False,
                 'releaseApproved':False,'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return inventory


if __name__=='__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render',action='store_true')
    print(json.dumps(analyse(parser.parse_args().render),ensure_ascii=False))
