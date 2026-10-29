"""Hosted-only Git secret scan. Raw findings and scanner output are never published."""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import tempfile

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
        phase='safe_metadata_report'
        report={'scope':'tracked-git-history','commit':os.environ['GITHUB_SHA'],'scanner':'gitleaks8.30.1',
                'syntheticRedactionSelfTestPassed':True,'candidateCount':len(findings),'findings':findings,
                'rawValuesPublished':False,'humanReviewRequired':bool(findings)}
        (output/'safe-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(json.dumps({'secretCandidates':len(findings),'redactionSelfTestPassed':True,'rawValuesPublished':False}))
        return code


if __name__=='__main__':
    try:raise SystemExit(main())
    except Exception:
        print('Secret audit failed at '+phase+'; raw scanner output intentionally withheld.',file=sys.stderr)
        raise SystemExit(2)
