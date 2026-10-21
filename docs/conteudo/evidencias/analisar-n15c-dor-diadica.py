"""Verify dyadic pain study originals, keeping pilot and cluster trial separate."""
import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-dor-diadica'
TARGETS = {'c15-dpmp2020-pdf':[1,5,6,13,18], 'c15-dpmp2022-protocolo-pdf':[1,4,5,11]}


class HtmlText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        if data.strip():
            self.parts.append(data.strip())


def analyse(render=False):
    rows, pdfs, originals = [], {}, {}
    for name in ['requisicoes.json','requisicoes-registro.json','requisicoes-antecedentes.json','requisicoes-correcao.json']:
        for request in json.loads((FOLDER/name).read_text(encoding='utf-8'))['requests']:
            path = FOLDER/(request['id']+'.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if request['url'] != receipt['url']:
                raise ValueError('Manifest/receipt URL mismatch')
            usable = receipt['status']==200 and not receipt.get('error')
            if receipt.get('bodyFile'):
                source = (FOLDER/receipt['bodyFile']).resolve()
                if not source.is_relative_to(ROOT.resolve()):
                    raise ValueError('Body outside evidence root')
                body = source.read_bytes()
                if len(body)!=receipt['bytes'] or hashlib.sha256(body).hexdigest()!=receipt['sha256']:
                    raise ValueError('Original body integrity mismatch')
                if usable:
                    originals[request['id']] = body
                    if request['extension']=='pdf':
                        if not body.startswith(b'%PDF-'):
                            raise ValueError('Not an original PDF')
                        pdfs[request['id']] = (source,PdfReader(source))
            elif any(receipt.get(k) is not None for k in ['bytes','sha256']):
                raise ValueError('Missing body cannot acquire hash')
            rows.append({'id':request['id'],'record':path.relative_to(ROOT).as_posix(),
                         'url':receipt['url'],'status':receipt['status'],'bytes':receipt.get('bytes'),
                         'sha256':receipt.get('sha256'),'usableForReading':usable})
    expected = {'c15-dpmp2020-pdf':18,'c15-dpmp2022-protocolo-pdf':11}
    for key, pages in expected.items():
        if len(pdfs[key][1].pages)!=pages:
            raise ValueError('PDF original length mismatch')
    article = ET.fromstring(originals['c15-dpmp2026-xml'])
    ids = [x.text for x in article.findall('front/article-meta/article-id')]
    if '10.3390/healthcare14040553' not in ids:
        raise ValueError('Wrong result article')
    table = article.find(".//table-wrap[@id='healthcare-14-00553-t004']")
    text = ' '.join(table.itertext())
    if not all(x in text for x in ['Caregiver Burden','0.137','0.001','0.015']):
        raise ValueError('Caregiver Table4 anchors absent')
    registry_body = originals.get('c15-dpmp2026-registro-json')
    if registry_body and json.loads(registry_body)['protocolSection']['identificationModule']['nctId']!='NCT05056623':
        raise ValueError('Wrong registry')
    pilot_registry = json.loads(originals['c15-dpmp2020-registro-json'])
    if pilot_registry['protocolSection']['identificationModule']['nctId']!='NCT04106271':
        raise ValueError('Wrong pilot registry')
    correction = HtmlText()
    correction.feed(originals['c15-dpm2024-correcao-html'].decode('utf-8'))
    text = ' '.join(correction.parts)
    if not all(x in text for x in ['2401213','mistakenly inputted','30 samples in each group, not 75 samples','4.28','2.20','0.011']):
        raise ValueError('Original correction anchors absent')
    rendered = {}
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER/'paginas'
        folder.mkdir(exist_ok=True)
        for key, targets in TARGETS.items():
            document = pdfium.PdfDocument(str(pdfs[key][0]))
            for number in targets:
                page = document[number-1]
                bitmap = page.render(scale=1.8)
                bitmap.to_pil().save(folder/f'{key}-pagina-{number}.png')
                bitmap.close()
                page.close()
            document.close()
            rendered[key] = targets
    result = {'niche':'N15-C','date':'2026-10-11','collectorCalls':len(rows),
              'http200':sum(r['status']==200 for r in rows),
              'hashedBodies':sum(r['sha256'] is not None for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows),
              'pdfPages':sum(len(r.pages) for _,r in pdfs.values()),'receipts':rows,
              'renderedPages':rendered,'renderingIsVisualInspection':False,
              'networkCallsDuringAnalysis':0,'researchClosureApproved':False,
              'correctionReceived':True,'oldTablesAreNotCurrentResults':True,
              'releaseApproved':False,'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render',action='store_true')
    print(json.dumps(analyse(parser.parse_args().render),ensure_ascii=False))
