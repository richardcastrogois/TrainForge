"""Audit walking and social-exergame receipts, including empty HTTP error bodies."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-caminhada-social'


def analyse():
    rows = []
    for name in ['requisicoes.json','requisicoes-gogrow.json']:
        for request in json.loads((FOLDER/name).read_text(encoding='utf-8'))['requests']:
            path = FOLDER/(request['id']+'.evidencia.json')
            receipt = json.loads(path.read_text(encoding='utf-8'))
            if request['url']!=receipt['url']:
                raise ValueError('Manifest/receipt mismatch')
            if receipt.get('bodyFile'):
                source = (FOLDER/receipt['bodyFile']).resolve()
                if not source.is_relative_to(ROOT.resolve()):
                    raise ValueError('Body outside root')
                body = source.read_bytes()
                if len(body)!=receipt['bytes'] or hashlib.sha256(body).hexdigest()!=receipt['sha256']:
                    raise ValueError('Body integrity mismatch')
            elif any(receipt.get(k) is not None for k in ['bytes','sha256']):
                raise ValueError('Missing body cannot acquire hash')
            usable = receipt['status']==200 and not receipt.get('error') and receipt.get('bytes',0)>0
            rows.append({'id':request['id'],'record':path.relative_to(ROOT).as_posix(),
                         'url':receipt['url'],'status':receipt['status'],'bytes':receipt.get('bytes'),
                         'sha256':receipt.get('sha256'),'usableForReading':usable})
    result = {'niche':'N15-C','date':'2026-10-11','collectorCalls':len(rows),
              'http200':sum(r['status']==200 for r in rows),
              'hashedBodies':sum(r['sha256'] is not None for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows),'receipts':rows,
              'empty500IsClinicalArticle':False,'networkCallsDuringAnalysis':0,
              'researchClosureApproved':False,'releaseApproved':False,'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__=='__main__':
    print(json.dumps(analyse(),ensure_ascii=False))
