"""Package a complete verified SQLite snapshot as a streamed gzip APK asset.

Keeps the >4 GiB uncompressed database and update ZIP outside Flutter assets.
No record is dropped. Source exports remain individually hash-bound in manifest.
"""
from __future__ import annotations

import argparse
import base64
import ctypes
import gzip
import hashlib
import json
import os
from pathlib import Path
import time
import zipfile

from food_catalog import ROOT, canonical, sha_file, sign_manifest


def alive(pid):
    if os.name!="nt":
        try:os.kill(pid,0);return True
        except ProcessLookupError:return False
    handle=ctypes.windll.kernel32.OpenProcess(0x100000,False,pid)
    if not handle:return False
    try:return ctypes.windll.kernel32.WaitForSingleObject(handle,0)==258
    finally:ctypes.windll.kernel32.CloseHandle(handle)


def write_update_archive(assets,distribution):
    """Use actual ZIP32 limits; Python defaults to a conservative 2 GiB limit."""
    manifest=assets/"manifest.json";database=assets/"catalog.sqlite.gz"
    if manifest.stat().st_size+database.stat().st_size+65536>=2**32-1:
        raise ValueError("Complete update exceeds the ZIP32 distribution size limit")
    temporary=distribution/"catalog-update.zip.part"
    previous_limit=zipfile.ZIP64_LIMIT
    try:
        zipfile.ZIP64_LIMIT=2**32-1
        with zipfile.ZipFile(temporary,"w",compression=zipfile.ZIP_STORED,allowZip64=False) as output:
            output.write(manifest,"manifest.json")
            output.write(database,"catalog.sqlite.gz")
    finally:zipfile.ZIP64_LIMIT=previous_limit
    temporary.replace(distribution/"catalog-update.zip")


def package(assets,distribution,signing,*,create_archive=True):
    assets=Path(assets).resolve();distribution=Path(distribution).resolve()
    expected=(ROOT/".local/food-catalog/distribution").resolve()
    if distribution!=expected:raise ValueError("Distribution target must be the project food-catalog directory")
    distribution.mkdir(parents=True,exist_ok=True)
    envelope=json.loads((assets/"manifest.json").read_text(encoding="utf-8"))
    payload=json.loads(base64.b64decode(envelope["payload"],validate=True))
    if not payload.get("complete") or payload.get("fixture") is not False:
        raise ValueError("Cannot package an incomplete catalog or a fixture")
    if payload["file"]=="catalog.sqlite.gz":
        target=assets/"catalog.sqlite.gz"
        if not target.is_file() or target.stat().st_size!=payload["bytes"] or sha_file(target)!=payload["sha256"]:
            raise ValueError("Packaged catalog no longer matches its signed manifest")
        if create_archive:write_update_archive(assets,distribution)
        print(canonical({"state":"already_packaged","bytes":payload["bytes"],"databaseBytes":payload["databaseBytes"]}),flush=True)
        return payload
    if payload["file"]!="catalog.sqlite":raise ValueError("Unexpected source database filename")
    source=assets/"catalog.sqlite";raw=distribution/"catalog.sqlite"
    if source.exists():
        if raw.exists():raise FileExistsError("Refusing to overwrite an archived SQLite snapshot")
        source.rename(raw)
    if not raw.is_file():raise FileNotFoundError("Completed SQLite snapshot unavailable")
    target=assets/"catalog.sqlite.gz";temporary=distribution/"catalog.sqlite.gz.building"
    digest=hashlib.sha256();total=0;started=time.monotonic();last=started
    print(canonical({"state":"compressing_catalog","databaseBytes":raw.stat().st_size}),flush=True)
    with raw.open("rb") as stream,gzip.GzipFile(filename=str(temporary),mode="wb",compresslevel=6,mtime=0) as output:
        for block in iter(lambda:stream.read(1024*1024),b""):
            digest.update(block);total+=len(block);output.write(block)
            if time.monotonic()-last>30:
                print(canonical({"state":"compressing_catalog","inputBytes":total,"compressedBytes":temporary.stat().st_size}),flush=True)
                last=time.monotonic()
    if total!=payload["bytes"] or digest.hexdigest()!=payload["sha256"]:
        raise ValueError("Uncompressed database differs from signed complete snapshot")
    temporary.replace(target)
    payload.update({"file":"catalog.sqlite.gz","databaseFile":"catalog.sqlite",
                    "databaseSha256":payload["sha256"],"databaseBytes":payload["bytes"],
                    "sha256":sha_file(target),"bytes":target.stat().st_size,"compression":"gzip"})
    sign_manifest(payload,signing,assets)
    public=ROOT/"content/food_catalog"
    (public/"catalog.lock.json").write_text(canonical({"contract":"trainforge.food-catalog-lock/1",**payload})+"\n",encoding="utf-8")
    report=json.loads((public/"build-report.json").read_text(encoding="utf-8"))
    report.update({"bytes":payload["bytes"],"databaseBytes":payload["databaseBytes"],
                   "databaseSha256":payload["databaseSha256"],"sha256":payload["sha256"],
                   "file":payload["file"],"packagingSeconds":round(time.monotonic()-started),
                   **({"storageLayout":payload["storageLayout"]} if "storageLayout" in payload else {})})
    (public/"build-report.json").write_text(canonical(report)+"\n",encoding="utf-8")
    if create_archive:write_update_archive(assets,distribution)
    print(canonical({"state":"catalog_packaged","bytes":payload["bytes"],"databaseBytes":payload["databaseBytes"],
                     "counts":payload["counts"],"sha256":payload["sha256"]}),flush=True)
    return payload


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--wait-build-pid",type=int)
    parser.add_argument("--assets",type=Path,default=ROOT/"assets/food_catalog")
    parser.add_argument("--distribution",type=Path,default=ROOT/".local/food-catalog/distribution")
    parser.add_argument("--signing",type=Path,default=ROOT/".local/food-catalog/signing")
    args=parser.parse_args()
    if args.wait_build_pid:
        while alive(args.wait_build_pid):
            print(canonical({"state":"waiting_for_complete_build","pid":args.wait_build_pid}),flush=True)
            time.sleep(30)
    package(args.assets,args.distribution,args.signing)


if __name__=="__main__":main()
