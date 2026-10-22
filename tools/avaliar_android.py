"""Prepare/start/stop only this clone's Android evaluation; never installs tools or changes OAuth."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from urllib.error import URLError
from urllib.request import urlopen
from db_local import start as start_database, run as pg_run, verify_owned, DATA
from dev_api import ROOT, LOCAL

STATE_DIR=LOCAL/"android-evaluation"
STATE=STATE_DIR/"runtime.json"
ARTIFACT=STATE_DIR/"artifact.json"
APK=ROOT/"build/app/outputs/flutter-apk/app-debug.apk"
AVD="TrainForge_Benchmark"
DEBUG_SHA1="1e934c58207cd23ba8d8ee4991da805678dc9e1c"
BASE="http://127.0.0.1:8082"

def paths():
    values={}
    for line in (ROOT/"android/local.properties").read_text(encoding="utf-8").splitlines():
        key,sep,value=line.partition("=")
        if sep:values[key]=value.replace("\\\\","\\").replace("\\:",":")
    sdk=Path(values["sdk.dir"])
    flutter=Path(values["flutter.sdk"])/"bin/flutter.bat"
    result={"adb":sdk/"platform-tools/adb.exe","emulator":sdk/"emulator/emulator.exe","flutter":flutter}
    signers=sorted((sdk/"build-tools").glob("*/apksigner.bat"))
    if not signers:raise RuntimeError("apksigner existente não encontrado; nada foi instalado")
    result["signer"]=signers[-1]
    for path in result.values():
        if not path.is_file():raise RuntimeError("Ferramenta existente não encontrada; confira android/local.properties")
    return result

def output(command,timeout=20):
    result=subprocess.run([str(v) for v in command],cwd=ROOT,capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=timeout,
                          creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
    if result.returncode:raise RuntimeError("Comando local falhou; nenhuma instalação/reset foi executado")
    return result.stdout.strip()

def source_fingerprint():
    files=list((ROOT/"lib").rglob("*.dart"))
    files += [p for p in (ROOT/"android/app/src").rglob("*") if p.is_file()]
    files += [p for p in (ROOT/"assets").rglob("*") if p.is_file()]
    files += [ROOT/"pubspec.yaml",ROOT/"pubspec.lock",ROOT/"android/app/build.gradle.kts",
              ROOT/"android/app/src/main/AndroidManifest.xml",ROOT/"android/app/src/debug/AndroidManifest.xml"]
    digest=hashlib.sha256()
    for file in sorted(set(files)):
        digest.update(file.relative_to(ROOT).as_posix().encode())
        digest.update(file.read_bytes().replace(b"\r\n",b"\n"))
    return digest.hexdigest()

def public_config():
    # Read only the public client ID from the service's local config. Never print connection values.
    config={}
    for line in (LOCAL/"api.env").read_text(encoding="utf-8-sig").splitlines():
        key,sep,value=line.partition("=")
        if sep:config[key]=value
    client=os.environ.get("TF_GOOGLE_SERVER_CLIENT_ID",config.get("TF_GOOGLE_SERVER_CLIENT_ID","")).strip()
    if not client.endswith(".apps.googleusercontent.com"):
        raise RuntimeError("Client ID Web público não configurado; login continuará pendente")
    return {"API_BASE_URL":BASE,"GOOGLE_SERVER_CLIENT_ID":client}

def prepare(tooling):
    STATE_DIR.mkdir(parents=True,exist_ok=True)
    config=public_config()
    define=LOCAL/"flutter-auth.json"
    define.write_text(json.dumps(config,indent=2)+"\n",encoding="utf-8")
    before_sources=source_fingerprint()
    before_config=configuration_fingerprint()
    env=os.environ.copy()
    env.setdefault("GRADLE_OPTS",'-Dorg.gradle.jvmargs="-Xmx2048m -XX:MaxMetaspaceSize=768m" -Dorg.gradle.workers.max=2')
    result=subprocess.run([str(tooling["flutter"]),"build","apk","--debug","--no-pub",
                            "--dart-define-from-file="+str(define)],cwd=ROOT,env=env)
    if result.returncode:raise RuntimeError("Build debug não concluiu")
    if source_fingerprint()!=before_sources or configuration_fingerprint()!=before_config:
        raise RuntimeError("Fontes/configuração mudaram durante o build; execute prepare novamente")
    report=output([tooling["signer"],"verify","--verbose","--print-certs",APK])
    match=re.search(r"certificate SHA-1 digest:\s*([0-9a-fA-F]+)",report)
    if not match or match.group(1).lower()!=DEBUG_SHA1:
        raise RuntimeError("Certificado debug difere do OAuth conferido; não instalar automaticamente")
    version=re.search(r"(?m)^version:\s*([^\s]+)",(ROOT/"pubspec.yaml").read_text(encoding="utf-8")).group(1)
    name,code=version.split("+")
    receipt={"versionName":name,"versionCode":int(code),"variant":"debug","package":"com.example.trainforge","relativePath":APK.relative_to(ROOT).as_posix(),
             "sha256":hashlib.sha256(APK.read_bytes()).hexdigest(),"certificateSha1":DEBUG_SHA1,
             "sourceFingerprint":before_sources,"configurationFingerprint":before_config,"realGoogleLoginValidated":False}
    ARTIFACT.write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    print("APK debug preparado; certificado OAuth debug e SHA256 conferidos.",flush=True)
    return receipt

def configuration_fingerprint():
    return hashlib.sha256(json.dumps(public_config(),sort_keys=True).encode()).hexdigest()

def artifact_current():
    if not ARTIFACT.is_file() or not APK.is_file():return False
    receipt=json.loads(ARTIFACT.read_text(encoding="utf-8"))
    return receipt.get("sourceFingerprint")==source_fingerprint() and receipt.get("configurationFingerprint")==configuration_fingerprint() and receipt.get("sha256")==hashlib.sha256(APK.read_bytes()).hexdigest()

def api_ready():
    try:
        with urlopen(BASE+"/api/v1/health/ready",timeout=2) as response:
            if response.status!=200:return False
        with urlopen(BASE+"/docs/doc.json",timeout=2) as response:
            specification=json.load(response)
        return specification.get("info",{}).get("title")=="TrainForge API"
    except (OSError,URLError,ValueError):return False

def port_occupied():
    import socket
    with socket.socket() as connection:
        connection.settimeout(1)
        return connection.connect_ex(("127.0.0.1",8082))==0

def devices(tooling):
    rows=output([tooling["adb"],"devices"]).splitlines()[1:]
    return [line.split()[0] for line in rows if len(line.split())>=2 and line.split()[1]=="device"]

def avd_name(tooling,serial):
    if not serial.startswith("emulator-"):return None
    try:return output([tooling["adb"],"-s",serial,"emu","avd","name"]).splitlines()[0]
    except RuntimeError:return None

def installed_sha256(tooling,serial):
    try:
        paths=output([tooling["adb"],"-s",serial,"shell","pm","path","com.example.trainforge"]).splitlines()
        if len(paths)!=1:return None
        path=paths[0].removeprefix("package:")
        if not re.fullmatch(r"/data/app/[A-Za-z0-9/_=.+~-]+/base[.]apk",path):return None
        result=output([tooling["adb"],"-s",serial,"shell","sha256sum",path]).split()[0]
        return result if re.fullmatch(r"[0-9a-f]{64}",result) else None
    except (RuntimeError,IndexError):return None

def wait_for(check,timeout,message):
    end=time.monotonic()+timeout
    while time.monotonic()<end:
        try:value=check()
        except (RuntimeError,OSError,subprocess.TimeoutExpired):value=False
        if value:return value
        time.sleep(1)
    raise RuntimeError(message)

def save_state(state):
    STATE_DIR.mkdir(parents=True,exist_ok=True)
    STATE.write_text(json.dumps(state,indent=2)+"\n",encoding="utf-8")

def start(tooling,serial=None):
    verify_owned()
    public_config()
    state=json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {"root":str(ROOT)}
    if state.get("root")!=str(ROOT):raise RuntimeError("Estado de outro checkout recusado")
    try:pg_run("pg_ctl",["-D",DATA,"status"],timeout=5);was_running=True
    except RuntimeError:was_running=False
    start_database()
    state["databaseStartedHere"]=state.get("databaseStartedHere",False) or not was_running
    save_state(state)
    if not api_ready():
        if port_occupied():raise RuntimeError("Porta8082 ocupada por API indisponível/desconhecida; não foi encerrada")
        stop=STATE_DIR/("api-stop-"+os.urandom(8).hex()+".flag")
        state["apiStopFile"]=str(stop)
        save_state(state)
        with (STATE_DIR/"api.log").open("a",encoding="utf-8") as log:
            subprocess.Popen([sys.executable,str(ROOT/"tools/dev_api.py"),"--stop-file",str(stop)],
                cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
        print("Iniciando API Go local…",flush=True)
        wait_for(api_ready,60,"API não ficou pronta; consulte .local/android-evaluation/api.log")
    if not artifact_current():prepare(tooling)
    started_emulator=False
    if serial:
        if serial not in devices(tooling):raise RuntimeError("Dispositivo não autorizado/conectado; confira ADB e o serial")
    else:
        serial=next((s for s in devices(tooling) if avd_name(tooling,s)==AVD),None)
        if serial is None:
            if AVD not in output([tooling["emulator"],"-list-avds"]).splitlines():
                raise RuntimeError("AVD existente não encontrado; nenhum AVD novo foi criado")
            with (STATE_DIR/"emulator.log").open("a",encoding="utf-8") as log:
                subprocess.Popen([str(tooling["emulator"]),"-avd",AVD,"-no-snapshot-save"],
                    cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name=="nt" else 0)
            started_emulator=True
            state["emulatorStartedHere"]=True
            save_state(state)
            print("Abrindo emulador Google Play existente…",flush=True)
            serial=wait_for(lambda:next((s for s in devices(tooling) if avd_name(tooling,s)==AVD),None),
                            120,"Emulador não apareceu no ADB; sem wipe/reset")
    previous_boot=state.get("emulatorBootId")
    state["serial"]=serial
    save_state(state)
    wait_for(lambda:output([tooling["adb"],"-s",serial,"shell","getprop","sys.boot_completed"])=="1",90,"Android ainda não concluiu boot")
    boot_id=output([tooling["adb"],"-s",serial,"shell","cat","/proc/sys/kernel/random/boot_id"])
    if not started_emulator and previous_boot and previous_boot!=boot_id:state["emulatorStartedHere"]=False
    state["emulatorBootId"]=boot_id
    output([tooling["adb"],"-s",serial,"reverse","tcp:8082","tcp:8082"])
    expected=hashlib.sha256(APK.read_bytes()).hexdigest()
    if installed_sha256(tooling,serial)!=expected:
        output([tooling["adb"],"-s",serial,"install","-r",APK],timeout=90)
    else:
        print("O APK instalado já corresponde ao arquivo validado; instalação não repetida.")
    output([tooling["adb"],"-s",serial,"shell","am","start","-n","com.example.trainforge/.MainActivity"])
    state["installedSha256"]=hashlib.sha256(APK.read_bytes()).hexdigest()
    save_state(state)
    print("Pronto: app atualizado sem apagar dados, API/banco locais conectados.")
    print("Consulte a biblioteca sem login ou faça o login Google manual. Nenhum consentimento foi automatizado.")

def stop(tooling):
    if not STATE.exists():print("Nenhum processo iniciado por este helper registrado.");return
    state=json.loads(STATE.read_text(encoding="utf-8"))
    if state.get("root")!=str(ROOT):raise RuntimeError("Estado de outro checkout recusado")
    stop_file=state.get("apiStopFile")
    if stop_file:
        target=Path(stop_file).resolve()
        if not target.is_relative_to(STATE_DIR.resolve()) or not re.fullmatch(r"api-stop-[0-9a-f]{16}\.flag",target.name):
            raise RuntimeError("Alvo de parada recusado")
        target.touch()
        wait_for(lambda:not port_occupied(),20,"API ainda ativa; banco preservado")
        state.pop("apiStopFile",None)
    serial=state.get("serial")
    if state.get("emulatorStartedHere") and serial and avd_name(tooling,serial)==AVD and state.get("emulatorBootId")==output([tooling["adb"],"-s",serial,"shell","cat","/proc/sys/kernel/random/boot_id"]):
        output([tooling["adb"],"-s",serial,"emu","kill"])
        state["emulatorStartedHere"]=False
    if state.get("databaseStartedHere") and not port_occupied():
        verify_owned();pg_run("pg_ctl",["-D",DATA,"-m","fast","-w","-t","20","stop"],timeout=25)
        state["databaseStartedHere"]=False
    save_state(state)
    print("Recursos iniciados pelo helper parados; dados, contas e assinatura preservados.")

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action",choices=["start","prepare","status","stop"],nargs="?",default="start")
    parser.add_argument("--serial",help="Serial ADB explícito para celular; nunca escolhe celular automaticamente")
    args=parser.parse_args()
    tooling=paths()
    if args.action=="prepare":prepare(tooling)
    elif args.action=="start":start(tooling,args.serial)
    elif args.action=="stop":stop(tooling)
    else:print(json.dumps({"apiReady":api_ready(),"apkCurrent":artifact_current(),"devices":devices(tooling)},ensure_ascii=False))

if __name__=="__main__":
    try:main()
    except (RuntimeError,OSError,KeyError,ValueError,subprocess.TimeoutExpired) as error:
        print("Avaliação não iniciada/concluída: "+str(error),file=sys.stderr)
        raise SystemExit(1)
