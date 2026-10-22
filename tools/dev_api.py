"""Watch local Go sources: regenerate Swagger, build, then restart the owned API."""
from __future__ import annotations
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[1]
SERVICE=ROOT/"services/api"
LOCAL=ROOT/".local"


def environment():
    env=os.environ.copy()
    go=ROOT/".tools/go/bin/go.exe"
    if not go.exists():
        found=shutil.which("go")
        if not found:raise RuntimeError("Go1.27.3 required; no installer is run by this command")
        go=Path(found)
    env["PATH"]=str(go.parent)+os.pathsep+str(ROOT/".tools/bin")+os.pathsep+env.get("PATH","")
    env["GOCACHE"]=str(ROOT/".tools/gocache");env["GOMODCACHE"]=str(ROOT/".tools/gomodcache");env["GOTOOLCHAIN"]="local"
    env.setdefault("TF_ENV","development");env.setdefault("TF_SWAGGER","true")
    source=LOCAL/"api.env"
    if source.exists():
        for line in source.read_text(encoding="utf-8-sig").splitlines():
            if not line or line.startswith("#"):continue
            key,sep,value=line.partition("=")
            if sep and key.startswith("TF_"):env.setdefault(key,value)
    return env,go


def fingerprint():
    files=[p for p in SERVICE.rglob("*.go") if "swaggerdocs" not in p.parts]
    files += [SERVICE/"go.mod", SERVICE/"go.sum"]
    h=hashlib.sha256()
    for p in sorted(files):
        if p.exists():h.update(p.relative_to(SERVICE).as_posix().encode());h.update(p.read_bytes())
    return h.hexdigest()


def stop_owned(process):
    if process is None or process.poll() is not None:return
    try:
        process.send_signal(signal.CTRL_BREAK_EVENT if os.name=="nt" else signal.SIGINT)
        process.wait(timeout=6)
    except (OSError,subprocess.TimeoutExpired):
        process.terminate();process.wait(timeout=6)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stop-file", type=Path, help="Exit and stop only this API when this file appears")
    args=parser.parse_args()
    LOCAL.mkdir(exist_ok=True);env,go=environment();last=None;process=None;failed=None
    try:
        while args.stop_file is None or not args.stop_file.exists():
            current=fingerprint()
            if current!=last and current!=failed:
                next_binary=LOCAL/("api-next.exe" if os.name=="nt" else "api-next")
                try:
                    subprocess.run([sys.executable,str(ROOT/"tools/gerar_swagger.py"),"--write"],cwd=ROOT,env=env,check=True)
                    subprocess.run([str(go),"build","-trimpath","-o",str(next_binary),"./cmd/api"],cwd=SERVICE,env=env,check=True)
                except subprocess.CalledProcessError:
                    failed=current;print("Build failed; previous development process preserved",flush=True)
                else:
                    stop_owned(process)
                    target=LOCAL/("api.exe" if os.name=="nt" else "api")
                    os.replace(next_binary,target)
                    process=subprocess.Popen([str(target)],cwd=SERVICE,env=env,creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name=="nt" else 0)
                    last=fingerprint();failed=None;print("Swagger regenerated and API restarted",flush=True)
            if process is not None and process.poll() is not None and current==last:
                raise RuntimeError("API exited; inspect its sanitized startup error")
            time.sleep(.7)
    except KeyboardInterrupt:pass
    finally:stop_owned(process)


if __name__=="__main__":main()
