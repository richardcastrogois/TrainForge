"""Classify exact reviewed non-secret lines; never blanket-ignore history or token URLs."""
import functools
import hashlib
import json
from pathlib import Path
import re
import subprocess

REASONS={'file_sha256_metadata','public_figma_file_id','test_cursor_fixture','application_field_name','natural_language_research_note','editorial_field_mapping'}
GENERATED={'docs/arquitetura/inventario-atual.json','docs/arquitetura/referencias/backend-fastify.json'}


@functools.lru_cache(maxsize=256)
def read_blob(root,commit,path):
    if not re.fullmatch('[a-f0-9]{40,64}',commit) or Path(path).is_absolute() or '..' in Path(path).parts:raise ValueError('Unsafe source locator')
    r=subprocess.run(['git','-c','safe.directory='+str(root),'-C',str(root),'show',commit+':'+path],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=20)
    if r.returncode or len(r.stdout)>32<<20:raise ValueError('Historical source unavailable')
    return r.stdout


def load_review(path):
    data=json.loads(Path(path).read_text(encoding='utf-8'))
    if data.get('schemaVersion')!=1 or data.get('scope')!='exact-reviewed-nonsecret-lines-only':raise ValueError('Invalid review registry')
    result={}
    for row in data['reviewed']:
        if set(row)!={'file','rule','lineDigest','reason'} or row['reason'] not in REASONS or not re.fullmatch('[a-f0-9]{64}',row['lineDigest']):raise ValueError('Invalid reviewed finding')
        key=(row['file'],row['rule'],row['lineDigest'])
        if key in result:raise ValueError('Duplicate review')
        result[key]=row['reason']
    return result


def classify(root,finding,review,reader=read_blob):
    try:
        raw=reader(root,finding['commit'],finding['file']);lines=raw.decode('utf-8-sig').splitlines();line=lines[finding['line']-1]
        # No credential-like URL (even a previously reviewed row) can be exempted here.
        if re.search(r'https?://[^\s"]+\?',line):return 'historical_url_query'
        key=(finding['file'],finding['rule'],hashlib.sha256(line.encode('utf-8')).hexdigest())
        if key in review:return 'reviewed_nonsecret:'+review[key]
        if finding['file'] in GENERATED:
            match=re.fullmatch(r'\s*"([A-Za-z0-9_./-]+)":\s*"([a-f0-9]{64})",?\s*',line)
            if match and '..' not in Path(match[1]).parts:
                value=reader(root,finding['commit'],match[1])
                lf=value.replace(b'\r\n',b'\n')
                expected={hashlib.sha256(v).hexdigest() for v in (value,lf,lf.replace(b'\n',b'\r\n'))}
                if match[2] in expected:return 'verified_source_file_sha256'
    except (ValueError,KeyError,IndexError,UnicodeError,OSError,subprocess.SubprocessError):
        return 'requires_review'
    return 'requires_review'


def classify_findings(root,findings,review):
    result=[]
    for finding in findings:
        classification=classify(root,finding,review)
        accepted=classification.startswith('reviewed_nonsecret:') or classification=='verified_source_file_sha256'
        result.append(dict(finding,classification=classification,blocking=not accepted))
    return result
