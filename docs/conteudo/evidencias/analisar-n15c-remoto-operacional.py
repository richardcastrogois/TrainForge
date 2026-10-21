"""Verify received remote caregiver protocol and results without network access."""
import argparse
import hashlib
import json
from pathlib import Path
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-11/n15c-remoto-operacional'
TARGETS = [1, 7, 8, 9, 10, 13, 14, 15]
GUIDE_TARGETS = [24, 30, 45, 46, 53, 59, 62, 67, 68, 69, 70, 121, 124]


def analyse(render=False):
    rows, pdfs, parsed = [], {}, {}
    for name in ['requisicoes.json', 'requisicoes-guia.json']:
        for request in json.loads((FOLDER/name).read_text(encoding='utf-8'))['requests']:
            path = FOLDER / (request['id']+'.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if receipt['url'] != request['url']:
                raise ValueError('Manifest/receipt URL mismatch')
            usable = receipt['status'] == 200 and not receipt.get('error')
            if receipt.get('bodyFile'):
                body_path = (FOLDER/receipt['bodyFile']).resolve()
                if not body_path.is_relative_to(ROOT.resolve()):
                    raise ValueError('Body outside evidence root')
                body = body_path.read_bytes()
                if len(body) != receipt['bytes'] or hashlib.sha256(body).hexdigest() != receipt['sha256']:
                    raise ValueError('Body integrity mismatch')
                if usable and request['extension'] == 'pdf':
                    if not body.startswith(b'%PDF-'):
                        raise ValueError('Expected original PDF, not challenge')
                    pdfs[request['id']] = (body_path, PdfReader(body_path))
                elif usable:
                    parsed[request['id']] = json.loads(body)
            elif any(receipt.get(k) is not None for k in ['sha256','bytes']):
                raise ValueError('Missing body must not have invented hash')
            rows.append({'id':request['id'], 'record':path.relative_to(ROOT).as_posix(),
                         'url':receipt['url'], 'status':receipt['status'], 'bytes':receipt.get('bytes'),
                         'sha256':receipt.get('sha256'), 'usableForReading':usable})
    path, protocol = pdfs['c15-remoto2026-protocolo-pdf']
    if len(protocol.pages) != 27:
        raise ValueError('Protocol length mismatch')
    anchors = {1:['NCT04102514','2022'], 7:['20 hrs./wk.','clearance'],
               8:['60 min','resistance bands'], 9:['physical therapist','3-5 METs','wk. 8'],
               10:['3 mos.','<80%'], 14:['48 hours','caregiver will be allowed'],
               15:['Stopping Rules','recruit']}
    for number, terms in anchors.items():
        text = ' '.join(protocol.pages[number-1].extract_text().split())
        if not all(term in text for term in terms):
            raise ValueError('Protocol anchor absent at page '+str(number))
    registry = parsed['c15-remoto2026-registro-json']
    if not registry['hasResults'] or registry['protocolSection']['identificationModule']['nctId'] != 'NCT04102514':
        raise ValueError('Results/registry identity absent')
    article = parsed['c15-remoto2026-core-json']['resultList']['result'][0]
    if article['id'] != '41774485' or article['doi'].lower() != '10.1249/mss.0000000000003974':
        raise ValueError('Article identity mismatch')
    guide_path, guide = pdfs['c15-nia2017-guia-pdf']
    if len(guide.pages) != 124 or 'March 2018' not in ' '.join(guide.pages[123].extract_text().split()):
        raise ValueError('Guide edition is printed March2018, not indexed2017')
    rendered = []
    if render:
        import pypdfium2 as pdfium
        folder = FOLDER/'paginas'
        folder.mkdir(exist_ok=True)
        document = pdfium.PdfDocument(str(path))
        for number in TARGETS:
            page = document[number-1]
            bitmap = page.render(scale=1.5)
            bitmap.to_pil().save(folder/f'protocolo-pagina-{number}.png')
            bitmap.close()
            page.close()
            rendered.append(number)
        document.close()
        document = pdfium.PdfDocument(str(guide_path))
        for number in GUIDE_TARGETS:
            page = document[number-1]
            bitmap = page.render(scale=1.5)
            bitmap.to_pil().save(folder/f'nia-pagina-{number}.png')
            bitmap.close()
            page.close()
        document.close()
    result = {'niche':'N15-C','date':'2026-10-11','collectorCalls':len(rows),
              'http200':sum(r['status']==200 for r in rows),
              'hashedBodies':sum(r['sha256'] is not None for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows),
              'pdfPages':sum(len(r.pages) for _,r in pdfs.values()),
              'pdfs':{k:len(r.pages) for k,(_,r) in pdfs.items()}, 'receipts':rows,
              'renderedProtocolPages':rendered, 'renderedGuidePages':GUIDE_TARGETS if render else [],
              'renderingIsVisualInspection':False,
              'networkCallsDuringAnalysis':0,'researchClosureApproved':False,
              'releaseApproved':False,'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--render',action='store_true')
    print(json.dumps(analyse(parser.parse_args().render),ensure_ascii=False))
