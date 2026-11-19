"""Download official snapshots with streaming, disk checks and SHA-256 receipts.

Does not build or activate a catalog. Raw material and receipts remain private.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import time
from urllib.request import Request, urlopen

from food_catalog import ROOT, canonical, sha_file

DOWNLOADS = {
    "taco": ("https://www.nepa.unicamp.br/arquivo/uploads/taco-4a-edicao/taco-4a-edicao-2/", "taco-4a-edicao.xlsx"),
    "usda": ("https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2026-10-29.zip", "usda-full-2026-10-29.zip"),
    "off": ("https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz", "off-products.csv.gz"),
}


def download(name, raw_dir):
    url, filename = DOWNLOADS[name]
    raw_dir = Path(raw_dir);raw_dir.mkdir(parents=True,exist_ok=True)
    target = raw_dir/filename
    receipt_path = raw_dir/(filename+".receipt.json")
    if target.exists() and receipt_path.exists():
        receipt=json.loads(receipt_path.read_text(encoding="utf-8"))
        if target.stat().st_size==receipt["bytes"] and sha_file(target)==receipt["sha256"]:
            print(canonical({"source":name,"state":"cached_verified","bytes":receipt["bytes"]}),flush=True)
            return receipt
        raise ValueError("Existing raw snapshot failed verification: "+name)
    temporary=target.with_name(target.name+".part")
    headers={"User-Agent":"TrainForge-food-catalog/1 (offline catalog preparation)","Accept-Encoding":"identity"}
    # Resume only when the server supplies a matching representation validator.
    start=temporary.stat().st_size if temporary.exists() else 0
    if start:headers["Range"]="bytes="+str(start)+"-"
    request=Request(url,headers=headers)
    with urlopen(request,timeout=60) as response:
        if start and response.status!=206:start=0
        length=int(response.headers.get("Content-Length") or 0)
        if shutil.disk_usage(raw_dir).free < max(length*3, 8*1024**3):
            raise OSError("Insufficient disk for raw snapshot and catalog preparation")
        written=start;last=time.monotonic()
        with temporary.open("ab" if start else "wb") as output:
            while True:
                chunk=response.read(1024*1024)
                if not chunk:break
                output.write(chunk);written+=len(chunk)
                if time.monotonic()-last>15:
                    print(canonical({"source":name,"state":"downloading","bytes":written,"expected":start+length}),flush=True)
                    last=time.monotonic()
        if length and written!=start+length:raise OSError("Incomplete official download")
        receipt={"contract":"trainforge.food-download/1","source":name,"url":url,
                 "file":filename,"bytes":written,"sha256":sha_file(temporary),
                 "lastModified":response.headers.get("Last-Modified"),"etag":response.headers.get("ETag")}
    temporary.replace(target)
    receipt_path.write_text(canonical(receipt)+"\n",encoding="utf-8")
    print(canonical({"source":name,"state":"download_verified","bytes":written,"sha256":receipt["sha256"]}),flush=True)
    return receipt


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",choices=sorted(DOWNLOADS),action="append")
    parser.add_argument("--all",action="store_true")
    parser.add_argument("--raw-dir",type=Path,default=ROOT/".local/food-catalog/raw")
    args=parser.parse_args()
    for name in sorted(DOWNLOADS) if args.all else args.source or []:
        download(name,args.raw_dir)


if __name__=="__main__":main()
