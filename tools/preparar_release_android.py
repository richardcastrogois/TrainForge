"""Build/inspect a signed Android release. Never install, upload or change OAuth."""
from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import subprocess
from urllib.parse import urlsplit

from avaliar_android import ROOT, LOCAL, paths, source_fingerprint
from android_security_inventory import summarize_manifest, verify_exclusions
from verificar_catalogo_apk import verify as verify_catalog_apk

PUBLIC_KEYS = {"APP_ENV", "API_BASE_URL", "GOOGLE_SERVER_CLIENT_ID", "GOOGLE_IOS_CLIENT_ID"}


def file_hash(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def release_config(raw: dict) -> dict:
    if not isinstance(raw, dict) or set(raw) - PUBLIC_KEYS:
        raise ValueError("Release config must contain only public Dart defines")
    if raw.get("APP_ENV") not in {"staging", "production"}:
        raise ValueError("Release requires staging or production")
    url = raw.get("API_BASE_URL", "")
    if not isinstance(url, str):
        raise ValueError("Release requires a public HTTPS API endpoint")
    try:
        parsed = urlsplit(url)
        host = parsed.hostname or ""
        port = parsed.port
    except ValueError:
        raise ValueError("Release requires a public HTTPS API endpoint") from None
    if (parsed.scheme != "https" or not host or parsed.username is not None
            or parsed.password is not None or parsed.query or parsed.fragment
            or parsed.path not in {"", "/"} or port not in {None, 443}
            or host.lower() in {"localhost", "10.0.2.2"}
            or host.lower().endswith((".localhost", ".local", ".invalid", ".example"))):
        raise ValueError("Release requires a public HTTPS API endpoint")
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        pass
    else:
        if not address.is_global:
            raise ValueError("Release cannot point to a private or loopback API")
    client = raw.get("GOOGLE_SERVER_CLIENT_ID", "")
    if not isinstance(client, str) or not re.fullmatch(r"[A-Za-z0-9_-]+[.]apps[.]googleusercontent[.]com", client):
        raise ValueError("Release requires the public Google Web client ID")
    if any(not isinstance(value, str) for value in raw.values()):
        raise ValueError("Dart defines must be strings")
    return dict(raw)


def command_output(command: list, timeout: int = 60) -> str:
    result = subprocess.run([str(v) for v in command], cwd=ROOT, capture_output=True,
                            timeout=timeout, creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    if result.returncode or len(result.stdout) > 4 << 20:
        raise RuntimeError("Android verification failed; raw tool output withheld")
    return result.stdout.decode("utf-8", errors="strict")


def inspect_apk(apk: Path, tooling: dict, expected_certificate: str | None = None) -> dict:
    signed = command_output([tooling["signer"], "verify", "--verbose", "--print-certs", apk])
    match = re.search(r"certificate SHA-256 digest:\s*([0-9a-fA-F]+)", signed)
    if not match:
        raise ValueError("APK certificate SHA256 unavailable")
    certificate = match.group(1).lower()
    if expected_certificate is not None and certificate != expected_certificate:
        raise ValueError("APK signer differs from the expected release certificate")
    aapt = tooling["signer"].with_name("aapt2.exe" if os.name == "nt" else "aapt2")
    # Release builds shorten resource paths (res/xml/backup_rules.xml -> res/Qq.xml);
    # resolve the packaged file through the resource table instead of guessing.
    table = None
    def tree(name):
        nonlocal table
        if name.startswith("res/xml/"):
            table = table if table is not None else command_output([aapt, "dump", "resources", apk], timeout=120)
            entry = "xml/" + name.removeprefix("res/xml/").removesuffix(".xml")
            found = re.search(r"resource 0x[0-9a-f]+ " + re.escape(entry) + r"\s*\n\s*\(\) \(file\) (\S+)", table)
            if found:
                name = found.group(1)
        return command_output([aapt, "dump", "xmltree", apk, "--file", name])
    manifest = summarize_manifest(tree("AndroidManifest.xml"))
    return {"sha256": file_hash(apk), "bytes": apk.stat().st_size,
            "certificateSha256": certificate, "manifest": manifest,
            "backupExclusions": all((verify_exclusions(tree("res/xml/backup_rules.xml"), "full-backup-content"),
                                     verify_exclusions(tree("res/xml/data_extraction_rules.xml"), "data-extraction-rules")))}


def validate_upgrade(previous: dict, candidate: dict) -> None:
    if previous["manifest"]["package"] != candidate["manifest"]["package"]:
        raise ValueError("Package differs: this is a separate installation")
    if previous["certificateSha256"] != candidate["certificateSha256"]:
        raise ValueError("Signing key differs: stop without uninstalling or clearing data")
    if int(candidate["manifest"]["versionCode"]) <= int(previous["manifest"]["versionCode"]):
        raise ValueError("Candidate versionCode must increase")


def prepare(config: dict, certificate: str, *, check_only=False, compare_apk: Path | None = None) -> dict:
    config = release_config(config)
    certificate = certificate.lower().replace(":", "")
    if not re.fullmatch(r"[a-f0-9]{64}", certificate):
        raise ValueError("Expected public release certificate SHA256 is required")
    if not (ROOT / "android/key.properties").is_file():
        raise ValueError("Local signing configuration is missing; no debug fallback")
    # Imported lazily so checking endpoint/signing configuration never downloads source data.
    from food_catalog import verify_bundle
    catalog = verify_bundle(ROOT / "assets/food_catalog")
    if check_only:
        return {"configurationValid": True, "catalog": catalog,
                "built": False, "installed": False, "published": False}
    tooling = paths()
    before = source_fingerprint()
    directory = LOCAL / "android-release"
    directory.mkdir(parents=True, exist_ok=True)
    defines = directory / "public-defines.json"
    defines.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    env = os.environ.copy()
    env.setdefault("GRADLE_OPTS", '-Dorg.gradle.jvmargs="-Xmx2048m -XX:MaxMetaspaceSize=768m" -Dorg.gradle.workers.max=2')
    completed = subprocess.run([str(tooling["flutter"]), "build", "apk", "--release", "--no-pub",
                                "--dart-define-from-file=" + str(defines)], cwd=ROOT, env=env)
    if completed.returncode or source_fingerprint() != before:
        raise RuntimeError("Release build failed or sources changed during build")
    apk = ROOT / "build/app/outputs/flutter-apk/app-release.apk"
    report = inspect_apk(apk, tooling, certificate)
    app = report["manifest"]["application"]
    if app.get("debuggable") is True or app.get("usesCleartextTraffic") is True or app.get("allowBackup") is not False:
        raise ValueError("Compiled release policy failed")
    catalog_apk = verify_catalog_apk(apk, ROOT / "assets/food_catalog", ci_fixture=False)
    if (catalog_apk["catalogVersion"] != catalog["version"]
            or catalog_apk["catalogSha256"] != catalog["sha256"]):
        raise ValueError("Packaged catalog differs from the verified release inputs")
    if compare_apk is not None:
        validate_upgrade(inspect_apk(compare_apk, tooling), report)
    report.update({"variant": "release", "sourceFingerprint": before,
                   "configurationSha256": file_hash(defines), "catalog": catalog, "catalogApk": catalog_apk,
                   "relativePath": apk.relative_to(ROOT).as_posix(), "installed": False,
                   "published": False, "realGoogleLoginValidated": False,
                   "publicApiReachabilityValidated": False})
    (directory / "artifact.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path, help="JSON with public Dart defines")
    parser.add_argument("--certificate-sha256", required=True, help="Expected public signing fingerprint")
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--compare-apk", type=Path, help="Previous APK: require compatible signing and higher versionCode")
    args = parser.parse_args()
    try:
        report = prepare(json.loads(args.config.read_text(encoding="utf-8")), args.certificate_sha256,
                         check_only=args.check_only, compare_apk=args.compare_apk)
    except (ValueError, RuntimeError, OSError, ImportError):
        parser.exit(1, "Release preparation failed; verify public configuration, catalog and signing. No installation/publication performed.\n")
    print(json.dumps(report, ensure_ascii=True))


if __name__ == "__main__":
    main()
