"""Audit deposited yoga curricula and read bounded OOXML without executing it."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path, PurePosixPath
import xml.etree.ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT/'2026-10-11/n15c-yoga-grupo'
SPEC = importlib.util.spec_from_file_location('yoga_ooxml',ROOT/'analisar-n15c-revieew-suplementos.py')
OOXML = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(OOXML)


def bounded_members(archive):
    members = archive.infolist()
    if len(members)>500 or sum(m.file_size for m in members)>20000000:
        raise ValueError('Archive expansion limit')
    names = [m.filename for m in members]
    if len(names)!=len(set(names)):
        raise ValueError('Duplicate archive member')
    for member in members:
        path = PurePosixPath(member.filename)
        if path.is_absolute() or '..' in path.parts or '\\' in member.filename or ':' in member.filename:
            raise ValueError('Unsafe archive member')
        if member.file_size/max(member.compress_size,1)>200:
            raise ValueError('Archive compression limit')
    return members


def analyse():
    rows = []
    curricula = None
    for request in json.loads((FOLDER/'requisicoes.json').read_text(encoding='utf-8'))['requests']:
        path = FOLDER/(request['id']+'.evidencia.json')
        receipt = json.loads(path.read_text(encoding='utf-8'))
        if receipt['url']!=request['url']:
            raise ValueError('Manifest/receipt mismatch')
        source = (FOLDER/receipt['bodyFile']).resolve()
        if not source.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside root')
        body = source.read_bytes()
        if len(body)!=receipt['bytes'] or hashlib.sha256(body).hexdigest()!=receipt['sha256']:
            raise ValueError('Body integrity mismatch')
        row = {'id':receipt['id'],'record':path.relative_to(ROOT).as_posix(),
               'url':receipt['url'],'status':receipt['status'],'bytes':len(body),'sha256':receipt['sha256'],
               'usableForReading':receipt['status']==200 and not receipt.get('error') and len(body)>0}
        if row['usableForReading'] and request['extension']=='xml':
            article = ET.fromstring(body)
            row['sections'] = [{'id':s.get('id'),'title':''.join(s.find('title').itertext())}
                               for s in article.findall('.//sec') if s.find('title') is not None]
            row['tables'] = [t.get('id') for t in article.findall('.//table-wrap')]
        if row['usableForReading'] and request['extension']=='zip':
            with ZipFile(io.BytesIO(body)) as archive:
                members = bounded_members(archive)
                row['members'] = [{'name':m.filename,'bytes':m.file_size} for m in members]
                member = 'Supplemental_Material_1_Yoga_class_curricula.docx'
                data = archive.read(member)
                paragraphs,tables,audit = OOXML.docx_text(io.BytesIO(data))
                curricula = {'containerReceipt':row['record'],'containerSha256':row['sha256'],
                             'member':member,'memberBytes':len(data),'memberSha256':hashlib.sha256(data).hexdigest(),
                             'paragraphs':[{'paragraph':i+1,'text':p} for i,p in enumerate(paragraphs)],
                             'tables':tables,'ooxmlAudit':audit,'readFromMemory':True,
                             'mediaViewed':False,'notACompleteExerciseManual':True}
        rows.append(row)
    result = {'niche':'N15-C','date':'2026-10-11','collectorCalls':len(rows),
              'http200':sum(r['status']==200 for r in rows),'hashedBodies':sum(bool(r['sha256']) for r in rows),
              'usableBodies':sum(r['usableForReading'] for r in rows),'receipts':rows,
              'networkCallsDuringAnalysis':0,'researchClosureApproved':False,'releaseApproved':False,'appImplemented':False}
    (FOLDER/'inventario.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (FOLDER/'leitura-suplemento.json').write_text(json.dumps(curricula,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return result


if __name__=='__main__':
    print(json.dumps(analyse(),ensure_ascii=False))
