"""Real local process/DB/Swagger/watch checks. Restores the changed comment and stops owned processes."""
from __future__ import annotations
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request

from dev_api import ROOT, LOCAL, environment, stop_owned


def free_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1",0));return sock.getsockname()[1]


def response(base,path):
    try:
        with urllib.request.urlopen(base+path,timeout=2) as r:return r.status,r.read()
    except urllib.error.HTTPError as e:return e.code,e.read()


def await_version(base, version):
    until=time.monotonic()+90
    while time.monotonic()<until:
        try:
            code,body=response(base,"/docs/doc.json")
            if code==200 and json.loads(body)["info"]["version"]==version:return json.loads(body)
        except (OSError,ValueError,KeyError):pass
        time.sleep(.3)
    raise RuntimeError("API/Swagger update timed out; inspect .local/api-watch-check.log")


def main():
    env,go=environment();port=free_port();env["TF_LISTEN_ADDR"]=f"127.0.0.1:{port}"
    if not env.get("TF_DATABASE_URL"):raise RuntimeError("Prepare the isolated runtime database first")
    base=f"http://127.0.0.1:{port}";source=ROOT/"services/api/cmd/api/main.go";original=source.read_bytes()
    trigger=LOCAL/"api-watch-check.stop";trigger.unlink(missing_ok=True)
    report={"schemaVersion":1,"date":"2026-10-21","realProcess":True}
    process=None
    try:
        with (LOCAL/"api-watch-check.log").open("wb") as log:
            process=subprocess.Popen([sys.executable,str(ROOT/"tools/dev_api.py"),"--stop-file",str(trigger)],cwd=ROOT,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
            spec=await_version(base,"0.1.0")
            for path,expected in [("/api/v1/health/live",200),("/api/v1/health/ready",200),("/docs/index.html",200),("/missing",404)]:
                code,_=response(base,path)
                if code!=expected:raise RuntimeError("Unexpected HTTP result for "+path)
            if spec.get("swagger")!="2.0" or set(spec["paths"])!={"/api/v1/health/live","/api/v1/health/ready"}:raise RuntimeError("Health-only spec differs from implemented foundation")
            replacement=original.replace(b"// @version 0.1.0",b"// @version 0.1.1-watch-verification",1)
            if replacement==original:raise RuntimeError("Expected source annotation missing")
            source.write_bytes(replacement)
            await_version(base,"0.1.1-watch-verification")
            source.write_bytes(original)
            spec=await_version(base,"0.1.0")
            checked=json.loads((ROOT/"contracts/generated/swagger-v1.json").read_text(encoding="utf-8"))
            # Swag's live template emits host:"" whereas its JSON writer omits it.
            if spec.get("host")=="":spec.pop("host")
            if spec!=checked:raise RuntimeError("Served contract differs from generated version")
            report.update(databaseConnected=True,livenessHTTP=200,readinessHTTP=200,swaggerUIHTTP=200,specPaths=list(spec["paths"]),servedSpecMatchesGenerated=True,emptyHostNormalization=True,annotationRegenerateBuildRestart=True,sourceRestored=True)
    finally:
        source.write_bytes(original);trigger.touch()
        if process is not None:
            try:process.wait(timeout=20)
            except subprocess.TimeoutExpired:stop_owned(process);raise RuntimeError("Watcher failed to stop normally; inspect its owned API process")
        trigger.unlink(missing_ok=True)
    try:response(base,"/api/v1/health/live")
    except OSError:report["ownedProcessStopped"]=True
    else:raise RuntimeError("Owned API remained listening after watcher stopped")
    report["result"]="PASS"
    (ROOT/"docs/execucao/v1/api-connected-verification.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,ensure_ascii=False,indent=2))


if __name__=="__main__":main()
