"""Read-only inventory of the prepared debug APK; no device data, credentials or tools installed."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
PACKAGE="com.example.trainforge"
REVIEWED_PERMISSIONS={
 "android.permission.INTERNET",
 "android.permission.USE_BIOMETRIC",
 "android.permission.USE_FINGERPRINT",
 PACKAGE+".DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION",
}
BACKUP_DOMAINS={"root","file","database","sharedpref","external","device_root","device_file","device_database","device_sharedpref"}

def parse_value(value):
 value=value.strip()
 if value in ("true","false"):return value=="true"
 quoted=re.match(r'"(?:[^"\\]|\\.)*"',value)
 if quoted:return json.loads(quoted.group(0))
 if value.isdigit():return int(value)
 return value.split(" ",1)[0]

def parse_tree(text):
 roots=[];stack=[]
 for line in text.splitlines():
  element=re.match(r"^(\s*)E: ([\w-]+)(?:\s|$)",line)
  if element:
   depth=len(element.group(1))
   while stack and stack[-1][0]>=depth:stack.pop()
   node={"tag":element.group(2),"attrs":{},"children":[]}
   (stack[-1][1]["children"] if stack else roots).append(node)
   stack.append((depth,node))
   continue
  attr=re.match(r"^\s*A: ([^=]+)=(.*)$",line)
  if attr and stack:
   name=re.sub(r"\(0x[0-9a-fA-F]+\)$","",attr.group(1)).split(":")[-1]
   stack[-1][1]["attrs"][name]=parse_value(attr.group(2))
 if len(roots)!=1:raise ValueError("Unexpected compiled XML root")
 return roots[0]

def summarize_manifest(text):
 root=parse_tree(text)
 if root["tag"]!="manifest" or root["attrs"].get("package")!=PACKAGE:raise ValueError("Unexpected APK package")
 apps=[n for n in root["children"] if n["tag"]=="application"]
 sdks=[n for n in root["children"] if n["tag"]=="uses-sdk"]
 if len(apps)!=1 or len(sdks)!=1:raise ValueError("Incomplete compiled manifest")
 app=apps[0]
 permissions=sorted(n["attrs"].get("name","") for n in root["children"] if n["tag"].startswith("uses-permission"))
 exported=[]
 for n in app["children"]:
  if n["tag"] not in ("activity","activity-alias","service","receiver","provider") or n["attrs"].get("exported") is not True:continue
  launcher=False
  for intent in n["children"]:
   if intent["tag"]!="intent-filter":continue
   actions={v["attrs"].get("name") for v in intent["children"] if v["tag"]=="action"}
   categories={v["attrs"].get("name") for v in intent["children"] if v["tag"]=="category"}
   launcher|="android.intent.action.MAIN" in actions and "android.intent.category.LAUNCHER" in categories
  exported.append({"kind":n["tag"],"name":n["attrs"].get("name"),"permission":n["attrs"].get("permission"),"launcher":launcher})
 return {
  "package":PACKAGE,"versionName":root["attrs"].get("versionName"),"versionCode":root["attrs"].get("versionCode"),
  "minSdk":sdks[0]["attrs"].get("minSdkVersion"),"targetSdk":sdks[0]["attrs"].get("targetSdkVersion"),
  "application":{k:app["attrs"].get(k) for k in ("debuggable","allowBackup","usesCleartextTraffic","fullBackupContent","dataExtractionRules")},
  "permissions":permissions,"exportedComponents":exported,
 }

def verify_debug_policy(report,artifact):
 if artifact.get("variant")!="debug" or artifact.get("package")!=PACKAGE:raise ValueError("Only the prepared debug artifact is supported")
 if report["versionName"]!=artifact.get("versionName") or report["versionCode"]!=artifact.get("versionCode"):raise ValueError("APK version differs from receipt")
 if report["application"]["debuggable"] is not True or report["application"]["allowBackup"] is not False:raise ValueError("Unexpected debug/backup metadata")
 if not report["application"]["fullBackupContent"] or not report["application"]["dataExtractionRules"]:raise ValueError("Backup exclusion resources missing")
 if set(report["permissions"])-REVIEWED_PERMISSIONS:raise ValueError("New APK permission needs review")
 for n in report["exportedComponents"]:
  main=n["kind"]=="activity" and n["name"] in (".MainActivity",PACKAGE+".MainActivity") and n["launcher"]
  system=n["kind"]=="receiver" and n["name"]=="androidx.profileinstaller.ProfileInstallReceiver" and n["permission"]=="android.permission.DUMP"
  google=n["kind"]=="service" and n["name"]=="com.google.android.gms.auth.api.signin.RevocationBoundService" and n["permission"]=="com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION"
  if not (main or system or google):raise ValueError("New exported component needs review")

def verify_exclusions(text,root_tag):
 root=parse_tree(text)
 if root["tag"]!=root_tag:raise ValueError("Unexpected backup policy")
 sections=[root] if root_tag=="full-backup-content" else [n for n in root["children"] if n["tag"] in ("cloud-backup","device-transfer")]
 if root_tag!="full-backup-content" and {n["tag"] for n in sections}!={"cloud-backup","device-transfer"}:raise ValueError("Backup/transfer section missing")
 for section in sections:
  excluded={n["attrs"].get("domain") for n in section["children"] if n["tag"]=="exclude" and n["attrs"].get("path")=="."}
  if not BACKUP_DOMAINS<=excluded:raise ValueError("Private data exclusion missing")
 return True

def output(command):
 result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=45)
 if result.returncode or len(result.stdout)>4<<20:raise ValueError("SDK metadata command failed; raw output withheld")
 return result.stdout.decode("utf-8",errors="strict")

def inventory(root=ROOT):
 artifact=json.loads((root/".local/android-evaluation/artifact.json").read_text(encoding="utf-8"))
 apk=(root/artifact["relativePath"]).resolve()
 if not apk.is_relative_to(root.resolve()) or not apk.is_file():raise ValueError("Unsafe artifact path")
 if hashlib.sha256(apk.read_bytes()).hexdigest()!=artifact.get("sha256"):raise ValueError("Artifact hash mismatch")
 config={}
 for line in (root/"android/local.properties").read_text(encoding="utf-8").splitlines():
  name,sep,value=line.partition("=")
  if sep:config[name]=value.replace("\\\\","\\")
 sdk=Path(config["sdk.dir"]).resolve()
 candidates=sorted((sdk/"build-tools").glob("*/aapt2.exe"))
 if not candidates:raise ValueError("Installed AAPT2 unavailable; no installation attempted")
 aapt=candidates[-1];signer=aapt.with_name("apksigner.bat")
 # Invoke the installed SDK tool directly; no command text from user input.
 signed=subprocess.run([str(signer),"verify","--verbose","--print-certs",str(apk)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=45)
 if signed.returncode:raise ValueError("Signature verification failed; raw output withheld")
 sha=re.search(rb"certificate SHA-1 digest:\s*([0-9a-fA-F]+)",signed.stdout)
 if not sha or sha.group(1).decode().lower()!=artifact.get("certificateSha1"):raise ValueError("Signer differs from prepared artifact")
 def tree(file):return output([str(aapt),"dump","xmltree",str(apk),"--file",file])
 report=summarize_manifest(tree("AndroidManifest.xml"))
 verify_debug_policy(report,artifact)
 verify_exclusions(tree("res/xml/backup_rules.xml"),"full-backup-content")
 verify_exclusions(tree("res/xml/data_extraction_rules.xml"),"data-extraction-rules")
 return {
  "schemaVersion":1,"scope":"prepared-debug-apk-public-metadata-only","artifactSha256":artifact["sha256"],
  "signatureMatchesPreparedArtifact":True,"sdkBuildTools":aapt.parent.name,"manifest":report,
  "compiledBackupExclusionsVerified":True,"rawValuesPublished":False,
  "limits":["Debug APK only; cleartext/debuggable development flags are not release approval.",
   "Manifest settings do not prove every OEM backup/transfer behavior or device keystore resilience.",
   "Optional biometric permissions originate in AndroidX; their presence does not prove biometric authentication is used.",
   "Exported dependency components retain their declared permissions; runtime caller authorization was not exercised.",
   "This is not dependency vulnerability scanning, penetration testing, iOS validation, or a complete security audit."],
 }

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--write",action="store_true");args=parser.parse_args()
 report=inventory()
 if args.write:
  target=ROOT/"docs/execucao/v1/android-security-inventory.json";target.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
 print(json.dumps({"package":report["manifest"]["package"],"version":report["manifest"]["versionName"],"versionCode":report["manifest"]["versionCode"],"permissions":len(report["manifest"]["permissions"]),"compiledBackupExclusionsVerified":True,"signatureMatchesPreparedArtifact":True,"scope":report["scope"]}))
if __name__=="__main__":
 try:main()
 except (ValueError,OSError,KeyError,subprocess.SubprocessError,json.JSONDecodeError) as error:
  print("Android metadata inventory failed; raw output and private configuration withheld.",file=sys.stderr);raise SystemExit(1)
