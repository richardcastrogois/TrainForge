"""Hosted Git/archive secret scan. Raw findings and scanner output stay private."""
import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import stat
import subprocess
import sys
import tempfile
import zipfile
import evidence_store
from secret_review import load_review, classify, classify_findings

ROOT=Path(__file__).resolve().parents[1]
phase='environment'


def safe_findings(raw,root):
    if not isinstance(raw,list):raise ValueError('Invalid scanner report')
    safe=[]
    for finding in raw:
        if not isinstance(finding,dict):raise ValueError('Invalid finding')
        rule=finding.get('RuleID');file=finding.get('File');line=finding.get('StartLine');commit=finding.get('Commit')
        if not isinstance(rule,str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,100}',rule):raise ValueError('Invalid rule')
        if not isinstance(file,str) or not file or len(file)>1000:raise ValueError('Invalid path')
        path=Path(file)
        if path.is_absolute():
            path=path.resolve().relative_to(root.resolve())
        if '..' in path.parts or any(ord(c)<32 for c in str(path)):raise ValueError('Unsafe path')
        if type(line) is not int or not 1<=line<=2147483647:raise ValueError('Invalid line')
        if not isinstance(commit,str) or not re.fullmatch(r'[a-f0-9]{40,64}',commit):raise ValueError('Invalid commit')
        safe.append({'rule':rule,'file':path.as_posix(),'line':line,'commit':commit})
    return safe


def scan_result(code,findings):
    if code==0 and not findings:return 0
    if code==1 and findings:return 1
    raise RuntimeError('Scanner exit/report mismatch')


def run_scan(binary,root,raw_path):
    result=subprocess.run([str(binary),'git','--no-banner','--redact=100','--ignore-gitleaks-allow',
        '--log-opts=--all --full-history','--report-format=json','--report-path='+str(raw_path),str(root)],
        stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=420)
    # No stdout/stderr text is echoed, including in error paths.
    findings=safe_findings(json.loads(raw_path.read_text(encoding='utf-8')),root)
    return scan_result(result.returncode,findings),findings,result.stdout


def validated_archives(root):
    """Verify original indexed bytes and reject every unindexed ZIP member."""
    root=Path(root).resolve()
    if any(not (root/path).is_file() or not (root/path).resolve().is_relative_to(root/'docs')
           for path in evidence_store.INDEXES):
        raise ValueError('Documentary archive index missing')
    indexed=evidence_store.records(root)
    if any(not archive.is_relative_to(root/'docs') for archive,_row in indexed.values()):
        raise ValueError('Documentary archive outside checkout docs')
    evidence_store.verify(root)
    groups={}
    for key,(archive,row) in indexed.items():
        member=PurePosixPath(key)
        if (member.as_posix()!=key or '!' in key or
                any(ord(c)<32 for c in key)):
            raise ValueError('Invalid documentary archive member')
        groups.setdefault(archive,{})[key]=row
    if len(groups)!=len(evidence_store.INDEXES):
        raise ValueError('Unexpected documentary archive set')
    for archive,rows in groups.items():
        with zipfile.ZipFile(archive) as bundle:
            infos=bundle.infolist()
            names=Counter(info.filename for info in infos)
            if set(names)!=set(rows) or any(count!=1 for count in names.values()):
                raise ValueError('Unindexed or duplicate documentary archive member')
            if any(stat.S_IFMT(info.external_attr>>16) not in (0,stat.S_IFREG) for info in infos):
                raise ValueError('Documentary archive requires regular files')
    return groups


def safe_archive_findings(raw,root,archive,rows):
    """Retain only locators bound to the verified archive and original path."""
    if not isinstance(raw,list):raise ValueError('Invalid archive scanner report')
    root=Path(root).resolve();archive=Path(archive).resolve()
    safe=[]
    for finding in raw:
        if not isinstance(finding,dict):raise ValueError('Invalid archive finding')
        rule=finding.get('RuleID');file=finding.get('File');line=finding.get('StartLine')
        if not isinstance(rule,str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,100}',rule):
            raise ValueError('Invalid archive rule')
        if not isinstance(file,str) or not file or len(file)>2000 or any(ord(c)<32 for c in file):
            raise ValueError('Invalid archive locator')
        prefix,separator,key=file.partition('!')
        if not separator or '!' in key or key not in rows:
            raise ValueError('Unindexed archive finding')
        source=Path(prefix)
        source=source.resolve() if source.is_absolute() else (root/source).resolve()
        if source!=archive:raise ValueError('Finding belongs to another archive')
        if type(line) is not int or not 1<=line<=2147483647:
            raise ValueError('Invalid archive line')
        safe.append({'rule':rule,'file':key,'line':line,
                     'archive':archive.relative_to(root).as_posix()})
    return safe


def scan_archives(binary,root,raw_directory,review):
    """Reusable local/CI entry point; return safe metadata and never echo raw output."""
    root=Path(root).resolve();private=Path(raw_directory).resolve();binary=Path(binary).resolve()
    if private.is_relative_to(root) and not private.is_relative_to(root/'.local'):
        raise ValueError('Raw archive reports require private storage')
    groups=validated_archives(root)
    private.mkdir(parents=True,exist_ok=True,mode=0o700)
    classified=[];metadata=[]
    for number,(archive,rows) in enumerate(sorted(groups.items())):
        # Keep reports/output private even when the scanner itself fails.
        before=hashlib.sha256(archive.read_bytes()).digest()
        raw_path=private/('archive-'+str(number)+'-'+secrets.token_hex(8)+'-raw.json')
        result=subprocess.run([str(binary),'dir','--no-banner','--redact=100',
            '--ignore-gitleaks-allow','--max-archive-depth=2','--report-format=json',
            '--report-path='+str(raw_path),archive.relative_to(root).as_posix()],
            cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=420)
        findings=safe_archive_findings(json.loads(raw_path.read_text(encoding='utf-8')),root,archive,rows)
        scan_result(result.returncode,findings)
        if hashlib.sha256(archive.read_bytes()).digest()!=before:
            raise ValueError('Documentary archive changed during scan')
        with zipfile.ZipFile(archive) as bundle:
            def reader(_root,_commit,path):
                if path not in rows:raise ValueError('Unindexed reviewed source')
                value=bundle.read(path)
                if (len(value)!=rows[path]['bytes'] or
                        hashlib.sha256(value).hexdigest()!=rows[path]['sha256']):
                    raise ValueError('Reviewed archive source differs from index')
                return value
            for finding in findings:
                # The source is the original ZIP member, never a fabricated Git blob.
                classification=classify(root,dict(finding,commit=''),review,reader=reader)
                accepted=classification.startswith('reviewed_nonsecret:') or classification=='verified_source_file_sha256'
                classified.append(dict(finding,classification=classification,blocking=not accepted))
        metadata.append({'archive':archive.relative_to(root).as_posix(),
                         'indexedFileCount':len(rows),'candidateCount':len(findings),
                         'originalBytesVerified':True})
    if validated_archives(root)!=groups:
        raise ValueError('Documentary archive indexes changed during scan')
    return {'archives':metadata,'findings':classified,'candidateCount':len(classified),
            'blockingCandidateCount':sum(item['blocking'] for item in classified)}


def main():
    global phase
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--binary',required=True)
    args=parser.parse_args()
    if sys.platform!='linux' or any(os.environ.get(k)!=v for k,v in {
        'CI':'true','GITHUB_ACTIONS':'true','RUNNER_ENVIRONMENT':'github-hosted'}.items()):raise RuntimeError('Hosted runner required')
    if Path(os.environ['GITHUB_WORKSPACE']).resolve()!=ROOT.resolve():raise RuntimeError('Unexpected checkout')
    temporary=Path(os.environ['RUNNER_TEMP']).resolve();binary=Path(args.binary).resolve()
    if not binary.is_relative_to(temporary):raise RuntimeError('Unexpected scanner location')
    output=temporary/'git-secret-report';output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='trainforge-secret-',dir=temporary) as directory:
        phase='synthetic_redaction_test'
        scratch=Path(directory).resolve();fixture=scratch/'fixture';fixture.mkdir()
        token='ghp_'+''.join(secrets.choice('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') for _ in range(36))
        (fixture/'fixture.txt').write_text('token='+token+'\n',encoding='utf-8')
        git=['git','-C',str(fixture),'-c','core.hooksPath=/dev/null']
        for command in [['init','-q'],['add','fixture.txt'],['-c','user.name=ScannerFixture','-c','user.email=fixture@example.invalid','commit','-qm','isolated scanner fixture']]:
            subprocess.run(git+command,check=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=20)
        code,safe,stdout=run_scan(binary,fixture,scratch/'fixture-raw.json')
        if code!=1 or not safe or token.encode() in stdout or token in json.dumps(safe):raise RuntimeError('Redaction self-test failed')
        phase='git_history_scan'
        code,findings,_=run_scan(binary,ROOT,scratch/'history-raw.json')
        phase='classify_exact_reviewed_nonsecrets'
        review=load_review(ROOT/'docs/execucao/v1/git-secret-nonsecret-review.json')
        classified=classify_findings(ROOT,findings,review)
        phase='indexed_documentary_archive_scan'
        archived=scan_archives(binary,ROOT,scratch/'archive-reports',review)
        classified+=archived['findings']
        blocking=sum(item['blocking'] for item in classified)
        phase='safe_metadata_report'
        total=len(classified)
        report={'scope':'tracked-git-history-and-indexed-documentary-archives','commit':os.environ['GITHUB_SHA'],'scanner':'gitleaks8.30.1',
                'syntheticRedactionSelfTestPassed':True,'candidateCount':total,'findings':classified,'blockingCandidateCount':blocking,'verifiedNonsecretCount':total-blocking,
                'gitHistoryCandidateCount':len(findings),'archiveCandidateCount':archived['candidateCount'],'archives':archived['archives'],
                'rawValuesPublished':False,'humanReviewRequired':bool(blocking)}
        (output/'safe-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps({'secretCandidates':total,'blockingCandidates':blocking,'verifiedNonsecrets':total-blocking,
                          'archivesScanned':len(archived['archives']),'redactionSelfTestPassed':True,'rawValuesPublished':False}))
        return 1 if blocking else 0


if __name__=='__main__':
    try:raise SystemExit(main())
    except Exception:
        print('Secret audit failed at '+phase+'; raw scanner output intentionally withheld.',file=sys.stderr)
        raise SystemExit(2)
