"""Hosted-only container build/smoke. No registry push, cloud or local Docker execution."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

ROOT=Path(__file__).resolve().parents[1]


def check_environment(env,root=ROOT,platform=sys.platform):
    if platform!='linux' or any(env.get(k)!=v for k,v in {
        'CI':'true','GITHUB_ACTIONS':'true','RUNNER_ENVIRONMENT':'github-hosted','TF_IMAGE_CI':'1'}.items()):
        raise RuntimeError('Explicit GitHub-hosted Linux runner required')
    if not env.get('GITHUB_WORKSPACE') or Path(env['GITHUB_WORKSPACE']).resolve()!=root.resolve(): raise RuntimeError('Unexpected checkout')
    if any(env.get(k) for k in ('DOCKER_HOST','DOCKER_CONTEXT','TF_DATABASE_URL','TF_MIGRATION_DATABASE_URL','DATABASE_URL')):
        raise RuntimeError('Existing connection context refused')
    if not re.fullmatch('[a-f0-9]{40}',env.get('GITHUB_SHA','')): raise RuntimeError('Explicit commit required')


def resource_name(value):
    if not re.fullmatch(r'trainforge-ci-image-[a-f0-9]{12}',value): raise RuntimeError('Unsafe ephemeral resource name')
    return value


def main():
    check_environment(os.environ)
    docker=shutil.which('docker')
    if not docker: raise RuntimeError('Hosted Docker missing; no installation attempted')
    commit=os.environ['GITHUB_SHA']; name=resource_name('trainforge-ci-image-'+secrets.token_hex(6))
    artifact=Path(os.environ['RUNNER_TEMP'])/'api-image-artifact';artifact.mkdir(exist_ok=True)
    version=json.loads((ROOT/'services/api/internal/swaggerdocs/swagger.json').read_text(encoding='utf-8'))['info']['version']
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+',version): raise RuntimeError('Invalid API version')
    report={'commit':commit,'apiVersion':version,'platform':'linux/amd64','status':'running',
        'registryPush':False,'deploy':False,'businessDataAccessed':False,'bitReproducibilityProven':False,'phase':'build'}
    def cli(*args,timeout=60):
        result=subprocess.run([docker,*args],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
        if result.returncode: raise RuntimeError('Docker operation failed; raw output withheld')
        return result.stdout.decode('utf-8').strip()
    network=False;container=False
    def stop():
        nonlocal container
        cli('stop','--time','8',resource_name(name))
        state=json.loads(cli('inspect',resource_name(name)))[0]['State']
        if state['ExitCode']!=0: raise RuntimeError('Graceful shutdown failed')
        cli('rm',resource_name(name));container=False
    try:
        cli('build','--platform','linux/amd64','--tag',name,'--build-arg','VCS_REF='+commit,
            '--build-arg','API_VERSION='+version,'services/api',timeout=720)
        report['phase']='inspect-and-smoke'
        image=json.loads(cli('image','inspect',name))[0]
        if image['Config']['User']!='65532:65532' or image['Config']['Labels']['org.opencontainers.image.revision']!=commit:
            raise RuntimeError('Image identity or non-root user mismatch')
        report['imageId']=image['Id'];report['runtimeUser']=image['Config']['User']
        cli('network','create','--internal',resource_name(name));network=True
        for mode,expected_live in [('production',426),('test',200)]:
            cli('run','--detach','--name',name,'--network',name,'--publish','127.0.0.1::8082',
                '--read-only','--cap-drop','ALL','--security-opt','no-new-privileges',
                '--pids-limit','64','--memory','128m','--cpus','1','--env','TF_ENV='+mode,name)
            container=True
            info=json.loads(cli('inspect',name))[0]
            host=info['HostConfig']
            if not host['ReadonlyRootfs'] or host['CapDrop']!=['ALL'] or 'no-new-privileges' not in host['SecurityOpt']:
                raise RuntimeError('Runtime isolation mismatch')
            port=info['NetworkSettings']['Ports']['8082/tcp'][0]
            if port['HostIp']!='127.0.0.1' or not re.fullmatch('[0-9]{1,5}',port['HostPort']): raise RuntimeError('Unexpected smoke port')
            base='http://127.0.0.1:'+port['HostPort']
            for attempt in range(40):
                try:
                    try: response=urllib.request.urlopen(base+'/api/v1/health/live',timeout=1)
                    except urllib.error.HTTPError as error: response=error
                    with response: status=response.status;body=response.read(2048)
                    break
                except (urllib.error.URLError,TimeoutError):
                    if attempt==39: raise RuntimeError('Liveness unavailable') from None
                    time.sleep(0.2)
            if status!=expected_live: raise RuntimeError('Liveness/TLS behavior mismatch')
            if mode=='test':
                try: urllib.request.urlopen(base+'/api/v1/health/ready',timeout=2)
                except urllib.error.HTTPError as error:
                    with error: problem=json.load(error)
                    if error.code!=503 or problem.get('code')!='dependency_unavailable': raise RuntimeError('Readiness contract mismatch')
                else: raise RuntimeError('Readiness must reject missing DB')
            stop()
        report.update({'readOnlyNonRootSmokePassed':True,'productionPlainHttpRejected':True,
            'testLiveness200':True,'missingDbReadiness503':True,'gracefulShutdownPassed':True,
            'internalNetworkOnly':True})
        report['phase']='archive'
        with tempfile.TemporaryDirectory(prefix='api-image-',dir=os.environ['RUNNER_TEMP']) as scratch:
            tar=Path(scratch)/'image.tar';cli('image','save','--output',str(tar),name,timeout=60)
            archive=artifact/('api-linux-amd64-'+commit+'.tar.gz')
            with tar.open('rb') as source,archive.open('wb') as target:
                with gzip.GzipFile(filename='',mode='wb',fileobj=target,mtime=0) as compressed: shutil.copyfileobj(source,compressed)
            digest=hashlib.sha256()
            with archive.open('rb') as stream:
                for chunk in iter(lambda:stream.read(1024*1024),b''):digest.update(chunk)
            report['archive']=archive.name;report['archiveSha256']=digest.hexdigest();report['archiveBytes']=archive.stat().st_size
        report['status']='success';report['phase']='complete'
    finally:
        if container: cli('rm','--force',resource_name(name))
        if network: cli('network','rm',resource_name(name))
        if report['status']=='running': report['status']='failed'
        (artifact/'metadata.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':
    try:main()
    except Exception:
        print('Image CI failed; raw process output withheld.',file=sys.stderr)
        raise SystemExit(1)
