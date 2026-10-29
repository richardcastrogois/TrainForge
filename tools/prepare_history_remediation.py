"""Build a local history-only preview. Never touches live refs, remotes, credentials or pushes."""
import argparse
import functools
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit,parse_qsl,urlunsplit

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'.local/security-review/history-preview.git'
TARGETS={
 'docs/conteudo/evidencias/2026-10-03/n16i-apoios/n16i-otago-manual.evidencia.json',
 'docs/conteudo/evidencias/2026-10-04/n15c-retomada/resumo-complemento.json',
 'docs/conteudo/evidencias/2026-10-08/n15c-protocolos-operacionais/c15-baduanjin-avc2023-pdf.evidencia.json',
 'docs/conteudo/evidencias/2026-10-08/n15c-protocolos-operacionais/inventario.json',
 'docs/conteudo/evidencias/2026-10-08/n15c-protocolos-operacionais/requisicoes-baduanjin-pdf.json',
 'docs/conteudo/evidencias/retornos-observados.json'}
SENSITIVE={'token','access_token','api_key','apikey','key','signature','sig','credential'}


def sanitize(raw):
    count=0
    def string(match):
        nonlocal count
        value=json.loads(match.group().decode('utf-8'))
        def url(found):
            nonlocal count
            text=found.group()
            try:
                parsed=urlsplit(text);parameters=parse_qsl(parsed.query,keep_blank_values=True)
                sensitive=[(key.lower(),value) for key,value in parameters if key.lower() in SENSITIVE or key.lower().startswith('x-amz-')]
                # USDA's literal DEMO_KEY is documented public example data, not a credential.
                if not sensitive or all(key=='api_key' and value=='DEMO_KEY' for key,value in sensitive):return text
                count+=1;return urlunsplit((parsed.scheme,parsed.netloc,parsed.path,'',''))
            except ValueError:return text
        cleaned=re.sub(r'https?://[^\s<>"\\]+',url,value)
        return match.group() if cleaned==value else json.dumps(cleaned,ensure_ascii=False).encode('utf-8')
    result=re.sub(rb'"(?:[^"\\]|\\.)*"',string,raw)
    json.loads(result)
    return result,count


def prepare():
    # The only write target is an exact fresh directory inside ignored .local.
    if DEST.resolve().parent!=(ROOT/'.local/security-review').resolve() or DEST.exists():raise RuntimeError('Fresh exact preview directory required; no overwrite/delete')
    if subprocess.run(['git','-C',str(ROOT),'check-ignore','-q',str(DEST)],capture_output=True).returncode:raise RuntimeError('Preview must stay ignored')
    def source(*args):
        r=subprocess.run(['git','-c','safe.directory='+str(ROOT),'-C',str(ROOT),*args],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=60)
        if r.returncode:raise RuntimeError('Source Git read failed')
        return r.stdout
    # A bundle avoids cloning a checkout owned by the sandbox account. Only the
    # existing source read command gets safe.directory; no global trust is changed.
    bundle=DEST.parent/'source-before-history-preview.bundle'
    if bundle.exists():raise RuntimeError('Preview backup already exists; no overwrite')
    source('bundle','create',str(bundle),'--all')
    result=subprocess.run(['git','clone','--mirror',str(bundle),str(DEST)],capture_output=True,timeout=90)
    if result.returncode:raise RuntimeError('Isolated bundle mirror creation failed')
    def git(*args,data=None):
        r=subprocess.run(['git','--git-dir='+str(DEST),*args],input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=45)
        if r.returncode:raise RuntimeError('Preview Git operation failed')
        return r.stdout
    git('config','remote.origin.url','blocked://history-preview-no-push')
    git('config','remote.origin.pushurl','blocked://history-preview-no-push')
    refs=git('for-each-ref','--format=%(refname) %(objecttype) %(objectname)').decode().splitlines()
    if any(line.split()[1]!='commit' for line in refs):raise RuntimeError('Tags/noncommit refs require their own review')
    changed_blobs={};counts={};paths=set();removed_signatures=0
    @functools.lru_cache(maxsize=2048)
    def rewrite_tree(oid,prefix):
        entries=[];changed=False
        for entry in git('ls-tree','-z',oid).split(b'\0'):
            if not entry:continue
            meta,name=entry.split(b'\t',1);mode,kind,child=meta.split();path=prefix+name.decode('utf-8');original=child.decode()
            if kind==b'tree' and any(target.startswith(path+'/') for target in TARGETS):
                next_child=rewrite_tree(original,path+'/')
            elif kind==b'blob' and path in TARGETS:
                key=(original,path)
                if key not in changed_blobs:
                    raw=git('cat-file','blob',original);cleaned,n=sanitize(raw)
                    next_child=git('hash-object','-t','blob','-w','--stdin',data=cleaned).strip().decode() if cleaned!=raw else original
                    changed_blobs[key]=next_child
                    if n:counts[path]=counts.get(path,0)+n;paths.add(path)
                next_child=changed_blobs[key]
            else:next_child=original
            changed|=next_child!=original;entries.append(mode+b' '+kind+b' '+next_child.encode()+b'\t'+name+b'\0')
        return git('mktree','-z',data=b''.join(entries)).strip().decode() if changed else oid
    mapping={};commits=git('rev-list','--all','--reverse','--topo-order').decode().splitlines()
    for old in commits:
        raw=git('cat-file','commit',old);headers,message=raw.split(b'\n\n',1);lines=headers.splitlines();rewritten=[];changed=False
        for line in lines:
            if line.startswith(b'tree '):
                previous=line[5:].decode();new=rewrite_tree(previous,'');changed|=new!=previous;rewritten.append(b'tree '+new.encode())
            elif line.startswith(b'parent '):
                previous=line[7:].decode();new=mapping[previous];changed|=new!=previous;rewritten.append(b'parent '+new.encode())
            else:rewritten.append(line)
        if changed:
            safe=[];skipping=False
            for line in rewritten:
                if line.startswith((b'gpgsig ',b'gpgsig-sha256 ')):removed_signatures+=1;skipping=True;continue
                if skipping and line.startswith(b' '):continue
                skipping=False;safe.append(line)
            mapping[old]=git('hash-object','-t','commit','-w','--stdin',data=b'\n'.join(safe)+b'\n\n'+message).strip().decode()
        else:mapping[old]=old
    old_main=git('rev-parse','refs/heads/main').strip().decode()
    for ref in refs:
        name,_,old=ref.split();git('update-ref',name,mapping[old],old)
    new_main=mapping[old_main]
    main_tree_unchanged=git('rev-parse',old_main+'^{tree}')==git('rev-parse',new_main+'^{tree}')
    if not main_tree_unchanged:raise RuntimeError('Current working files would change; review stopped')
    report={'scope':'isolated-local-preview-no-remote-write','oldMain':old_main,'previewMain':new_main,
        'commitsReviewed':len(commits),'commitsReidentified':sum(old!=new for old,new in mapping.items()),
        'changedHistoricalBlobCount':sum(old!=new for (old,_),new in changed_blobs.items()),
        'removedUrlOccurrencesAcrossUniqueBlobs':sum(counts.values()),'modifiedPaths':sorted(paths),
        'currentMainTreeUnchanged':True,'commitMessagesAuthorsDatesPreserved':True,'invalidatedSignatureHeadersRemoved':removed_signatures,
        'liveRepoRefsChanged':False,'remoteRefsChanged':False,'previewRemoteDisabled':True,'localBundleBackupSha256':hashlib.sha256(bundle.read_bytes()).hexdigest(),
        'requiresExplicitForcePushApproval':True,
        'limits':['Only reachable refs would be replaced; GitHub cached/unreachable commits and external token validity are separate.','Other clones need reconciliation after an approved history replacement.','No token was replayed, provider contacted or private env read.']}
    output=ROOT/'docs/execucao/v1/git-history-remediation-preview.json';output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    (DEST.parent/'commit-map.json').write_text(json.dumps(mapping,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--prepare',action='store_true');args=parser.parse_args()
    if not args.prepare:parser.error('Use --prepare for an isolated local preview')
    prepare()
if __name__=='__main__':main()
