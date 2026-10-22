"""Create a project-local evaluation signing key once; output public fingerprints only."""
import json
import os
from pathlib import Path
import secrets
import subprocess
from dev_api import ROOT, LOCAL

KEYTOOL = Path("C:/Program Files/Java/jdk-23/bin/keytool.exe")
DIRECTORY = LOCAL / "android-signing"
KEY = DIRECTORY / "trainforge-evaluation.p12"
PROPERTIES = ROOT / "android/key.properties"
def main():
    if KEY.exists() or PROPERTIES.exists():
        raise RuntimeError("Signing material already exists; no overwrite or rotation")
    if not KEYTOOL.exists():
        raise RuntimeError("Existing keytool not found; no installation attempted")
    DIRECTORY.mkdir(parents=True, exist_ok=True)
    password = secrets.token_urlsafe(32)
    env = os.environ.copy()
    env["TF_ANDROID_SIGNING_PASSWORD"] = password
    command = [str(KEYTOOL), "-genkeypair", "-keystore", str(KEY), "-storetype", "PKCS12",
               "-storepass:env", "TF_ANDROID_SIGNING_PASSWORD", "-keypass:env", "TF_ANDROID_SIGNING_PASSWORD",
               "-alias", "trainforge-evaluation", "-keyalg", "RSA", "-keysize", "3072",
               "-validity", "10000", "-dname", "CN=TrainForge Evaluation,OU=Development"]
    result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise RuntimeError("keytool failed; secret output not echoed")
    PROPERTIES.write_text("storeFile=" + KEY.as_posix() + "\nstorePassword=" + password
                          + "\nkeyPassword=" + password + "\nkeyAlias=trainforge-evaluation\n", encoding="utf-8")
    result = subprocess.run([str(KEYTOOL), "-list", "-v", "-keystore", str(KEY),
                             "-storepass:env", "TF_ANDROID_SIGNING_PASSWORD", "-alias", "trainforge-evaluation"],
                            env=env, capture_output=True, text=True, timeout=20)
    if result.returncode:
        raise RuntimeError("public fingerprint verification failed")
    fingerprints = [line.strip() for line in result.stdout.splitlines() if "SHA1:" in line or "SHA256:" in line]
    if len(fingerprints) != 2:
        raise RuntimeError("expected public SHA1/SHA256 fingerprints")
    report = {"purpose": "local-android-evaluation-release", "keyTracked": False,
              "keyPath": ".local/android-signing/trainforge-evaluation.p12",
              "propertiesPath": "android/key.properties",
              "fingerprints": fingerprints, "remoteOAuthRegistered": False}
    (DIRECTORY / "public-certificate.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
if __name__ == "__main__":
    main()
