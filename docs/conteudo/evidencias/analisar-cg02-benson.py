"""Audit Benson's existing article, publisher and one safety guide offline."""
import hashlib
import argparse
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-12/cg02-benson'
spec = importlib.util.spec_from_file_location('static_reader', ROOT / 'analisar-cg01-estatico.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)
RECORDS = [
    '2026-10-08/n15c-benson-reavaliacao/c15-benson2022-original-html.evidencia.json',
    '2026-10-05/programas-manuais-02/c15-benson-hemodialise-direitos.evidencia.json',
    '2026-10-12/cg02-benson/cg02-nccih-relaxamento-html.evidencia.json',
    '2026-10-12/cg02-benson/cg02-benson-artigo-pdf.evidencia.json',
    '2026-10-12/cg02-benson/cg02-ilm-bhi2009-pdf.evidencia.json',
]


def analyse(write=True, render=False):
    rows = []
    for relative in RECORDS:
        record_path = ROOT / relative
        receipt = json.loads(record_path.read_text(encoding='utf-8'))
        body_path = (record_path.parent / receipt['bodyFile']).resolve()
        if not body_path.is_relative_to(ROOT.resolve()):
            raise ValueError('Body outside evidence root')
        body = body_path.read_bytes()
        if receipt['status'] != 200 or receipt.get('error') or len(body) != receipt['bytes']:
            raise ValueError('Unusable source body')
        if hashlib.sha256(body).hexdigest() != receipt['sha256']:
            raise ValueError('Integrity mismatch')
        row = {'record':relative, 'url':receipt['url'], 'resolvedUrl':receipt['resolvedUrl'],
                     'collectedAtUtc':receipt['collectedAtUtc'], 'bytes':len(body),
                     'sha256':receipt['sha256']}
        if body.startswith(b'%PDF-'):
            from pypdf import PdfReader
            pdf = PdfReader(body_path)
            row.update(pages=len(pdf.pages), pageTexts=[p.extract_text() for p in pdf.pages],
                       selectedRenderPages=[1,2] if 'ilm-bhi2009' in relative else [1,6,7,14], renderedThisRun=render,
                       renderIsVisualReview=False)
            if render:
                import pypdfium2 as pdfium
                target = FOLDER / 'raw-render'
                target.mkdir(exist_ok=True)
                document = pdfium.PdfDocument(body_path)
                for number in row['selectedRenderPages']:
                    page = document[number-1]
                    bitmap = page.render(scale=1.4)
                    prefix = 'ilm-bhi-page-' if 'ilm-bhi2009' in relative else 'benson-page-'
                    bitmap.to_pil().save(target / (prefix+str(number)+'.png'))
                    bitmap.close()
                    page.close()
                document.close()
        else:
            parser = reader.TextReader()
            parser.feed(body.decode('utf-8'))
            row['text'] = '\n'.join(parser.parts)
        rows.append(row)
    transcript = ROOT / '2026-10-12/raw/cg02-video-editorial-transcricao-auto.txt'
    payload = transcript.read_bytes()
    result = {
        'date':'2026-10-12', 'targetSourceId':'PR61', 'usableHttpBodies':len(rows),
        'collectorCallsThisFolder':3, 'networkCallsDuringAnalysis':0, 'sources':rows,
        'browserTranscript':{
            'file':transcript.relative_to(ROOT).as_posix(), 'bytes':len(payload),
            'sha256':hashlib.sha256(payload).hexdigest(), 'videoId':'MDEM7dwXvqw',
            'publisherGalleyUrl':'https://revistas.udea.edu.co/index.php/iee/article/view/351819/20812292',
            'observedVideoUrl':'https://www.youtube.com/watch?v=MDEM7dwXvqw',
            'acquisition':'native browser exportYouTubeTranscript, not media download or HTTP receipt',
            'captions':'auto-generated en, names/numbers may be wrong',
            'observedRuntimeSeconds':154, 'wholeVideoWatched':False,
            'transcriptRead':True, 'text':payload.decode('utf-8'),
            'content':'Brief author presentation of rationale/results; no six-step practice script',
            'identityAsTrialCdVerified':False, 'videoReproductionPermissionVerified':False,
        },
        'mechanicalAnalysisApprovesClosure':False, 'closureDecisionFile':'pacote-factual.json',
        'releaseApproved':False, 'appImplemented':False,
    }
    if write:
        (FOLDER / 'inventario.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    audit = analyse(render=parser.parse_args().render)
    print(json.dumps({key:value for key,value in audit.items() if key not in ('sources','browserTranscript')}))
