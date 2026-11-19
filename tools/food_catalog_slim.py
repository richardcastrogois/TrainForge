"""Derive signed regional catalog packs from the complete verified catalog.

Run: python tools/food_catalog_slim.py --pack br
     python tools/food_catalog_slim.py --pack br-pt

A pack keeps every generic reference source plus the Open Food Facts products
sold in the selected countries. The complete SQLite stays read-only; each pack
gets its own SQLite, gzip, signed manifest, per-source exports and update ZIP
under .local/food-catalog/packs/<pack>. Nothing is published or imported here.
"""
from __future__ import annotations

import argparse
import base64
import csv
import gzip
import hashlib
import io
import json
from pathlib import Path
import shutil
import sqlite3
import sys
import zipfile

from food_catalog import ROOT, canonical, create_compact_schema, sha_file, sign_manifest

LOCAL = ROOT / '.local/food-catalog'
FULL_DB = LOCAL / 'distribution/catalog.sqlite'
FULL_ASSETS = ROOT / 'assets/food_catalog'
RAW_OFF = LOCAL / 'raw/off-products.csv.gz'
COUNTRY_CODES = LOCAL / 'off-country-codes.json'
# Reference tables with prepared/generic foods. Branded USDA and lab sample
# sources stay in the complete catalog only.
GENERIC = ('AL-TACO', 'AL-CIQUAL-2025', 'AL-COFID-2021', 'AL-USDA-FOUNDATION', 'AL-USDA-SR-LEGACY', 'AL-USDA-FNDDS')
PACKS = {
    'br': {'title': 'Brasil', 'countries': ['BR']},
    'br-pt': {'title': 'Brasil + Portugal', 'countries': ['BR', 'PT']},
}
TAGS = {'BR': 'en:brazil', 'PT': 'en:portugal'}


def full_payload():
    envelope = json.loads((FULL_ASSETS / 'manifest.json').read_text(encoding='utf-8'))
    payload = json.loads(base64.b64decode(envelope['payload'], validate=True))
    if payload.get('fixture') is not False or not payload.get('complete'):
        raise ValueError('Complete signed catalog required as pack parent')
    return payload


def country_codes():
    """OFF barcodes per country with unique scan counts, cached under .local."""
    if COUNTRY_CODES.is_file():
        return json.loads(COUNTRY_CODES.read_text(encoding='utf-8'))
    csv.field_size_limit(2**31 - 1)
    found = {key: {} for key in TAGS}
    with gzip.open(RAW_OFF, 'rb') as raw:
        reader = csv.DictReader(io.TextIOWrapper(raw, encoding='utf-8', errors='replace', newline=''), delimiter='\t')
        for row in reader:
            tags = (row.get('countries_tags') or '').split(',')
            for key, tag in TAGS.items():
                if tag in tags and row.get('code'):
                    try:
                        scans = int(row.get('unique_scans_n') or 0)
                    except ValueError:
                        scans = 0
                    found[key][row['code']] = scans
    COUNTRY_CODES.write_text(json.dumps(found), encoding='utf-8')
    return found


def build_sqlite(target, codes, limit):
    """Copy selected rows; most scanned OFF products first when a limit applies."""
    if target.exists():
        target.unlink()
    db = sqlite3.connect(f'file:{Path(target).as_posix()}', uri=True)
    db.executescript('PRAGMA journal_mode=OFF;PRAGMA synchronous=OFF;PRAGMA page_size=4096;')
    create_compact_schema(db)
    db.execute('ATTACH DATABASE ? AS full', (f'file:{FULL_DB.as_posix()}?mode=ro',))
    db.execute('CREATE TEMP TABLE wanted(code TEXT PRIMARY KEY, scans INTEGER) WITHOUT ROWID')
    ranked = sorted(codes.items(), key=lambda item: (-item[1], item[0]))
    if limit is not None:
        ranked = ranked[:limit]
    db.executemany('INSERT INTO wanted VALUES(?,?)', ranked)
    marks = ','.join('?' * len(GENERIC))
    db.execute('INSERT INTO sources SELECT * FROM full.sources WHERE source_id IN (' + marks + ",'AL-OFF')", GENERIC)
    db.execute('INSERT INTO nutrient_columns SELECT * FROM full.nutrient_columns')
    db.execute('INSERT INTO foods SELECT * FROM full.foods WHERE source_id IN (' + marks + ') ORDER BY row_key', GENERIC)
    db.execute("INSERT INTO foods SELECT f.* FROM full.foods f JOIN wanted w ON w.code=f.source_food_id "
               "WHERE f.source_id='AL-OFF' ORDER BY f.row_key")
    db.execute('INSERT INTO barcode_links SELECT b.* FROM full.barcode_links b JOIN foods f ON f.row_key=b.food_row_key')
    db.commit()
    db.execute('DETACH DATABASE full')
    db.executescript('''
      CREATE INDEX foods_search ON foods(search_name);
      CREATE INDEX foods_source ON foods(source_id);
      CREATE INDEX barcodes_normalized ON barcode_links(normalized_code);
      INSERT INTO foods_fts(foods_fts) VALUES('rebuild');
      INSERT INTO foods_fts(foods_fts) VALUES('optimize');
    ''')
    counts = dict(db.execute('SELECT source_id,count(*) FROM foods GROUP BY source_id'))
    identity = hashlib.sha256()
    for food_id, version_id in db.execute('SELECT food_id,version_id FROM foods ORDER BY food_id,version_id'):
        identity.update(f'{food_id}\t{version_id}\n'.encode())
    db.commit()
    db.close()
    return counts, identity.hexdigest()


def write_metadata(target, version, pack):
    db = sqlite3.connect(target)
    full = sqlite3.connect(f'file:{FULL_DB.as_posix()}?mode=ro', uri=True)
    rows = full.execute('SELECT key,value FROM metadata').fetchall()
    full.close()
    db.executemany('INSERT INTO metadata VALUES(?,?)', rows)
    db.execute("UPDATE metadata SET value=? WHERE key='version'", (version,))
    db.execute("INSERT INTO metadata VALUES('pack',?)", (pack,))
    db.commit()
    db.execute('VACUUM')
    db.close()


def subset_exports(parent, target_dir, food_ids):
    """Generic exports are copied byte-for-byte; OFF keeps only selected foods."""
    source_dir = LOCAL / 'exports' / parent['sha256']
    target_dir.mkdir(parents=True, exist_ok=True)
    exports = []
    for export in parent['exports']:
        sid = export['sourceId']
        if sid not in GENERIC and sid != 'AL-OFF':
            continue
        out = target_dir / export['file']
        if sid != 'AL-OFF':
            shutil.copyfile(source_dir / export['file'], out)
            exports.append(dict(export))
            continue
        rows = 0
        with gzip.open(source_dir / export['file'], 'rt', encoding='utf-8') as src, \
                out.open('wb') as raw, gzip.GzipFile(filename='', fileobj=raw, mode='wb', mtime=0, compresslevel=6) as dst:
            for line in src:
                start = line.find('"foodId":"')
                food_id = line[start + 10:line.find('"', start + 10)] if start >= 0 else None
                if food_id is None or food_id not in food_ids:
                    if food_id is None and json.loads(line).get('foodId') in food_ids:
                        pass
                    else:
                        continue
                dst.write(line.encode('utf-8'))
                rows += 1
        exports.append({**export, 'rows': rows, 'bytes': out.stat().st_size, 'sha256': sha_file(out)})
    return exports


def update_zip(assets, distribution):
    temporary = distribution / 'catalog-update.zip.part'
    with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_STORED, allowZip64=False) as output:
        output.write(assets / 'manifest.json', 'manifest.json')
        output.write(assets / 'catalog.sqlite.gz', 'catalog.sqlite.gz')
    temporary.replace(distribution / 'catalog-update.zip')


def build(pack_id, limit=None):
    pack = PACKS[pack_id]
    parent = full_payload()
    if sha_file(FULL_DB) != parent['databaseSha256']:
        raise ValueError('Complete SQLite differs from its signed manifest')
    all_codes = country_codes()
    codes = {}
    for country in pack['countries']:
        for code, scans in all_codes[country].items():
            codes[code] = max(scans, codes.get(code, 0))
    out = LOCAL / 'packs' / pack_id
    assets = out / 'assets'
    assets.mkdir(parents=True, exist_ok=True)
    database = out / 'catalog.sqlite'
    counts, identity = build_sqlite(database, codes, limit)
    version = hashlib.sha256(canonical({'parent': parent['version'], 'pack': pack_id, 'foods': identity}).encode()).hexdigest()
    write_metadata(database, version, pack_id)
    db = sqlite3.connect(f'file:{database.as_posix()}?mode=ro', uri=True)
    if db.execute('PRAGMA quick_check').fetchone()[0] != 'ok':
        raise ValueError('Pack SQLite failed integrity check')
    food_ids = {row[0] for row in db.execute('SELECT food_id FROM foods')}
    db.close()
    compressed = assets / 'catalog.sqlite.gz'
    with database.open('rb') as src, compressed.open('wb') as raw, \
            gzip.GzipFile(filename='', fileobj=raw, mode='wb', mtime=0, compresslevel=9) as dst:
        shutil.copyfileobj(src, dst, 1 << 20)
    counts['foods'] = sum(counts.values())
    payload = {key: value for key, value in parent.items() if key not in {'compaction', 'recovery', 'sourceReports'}}
    payload.update({
        'file': 'catalog.sqlite.gz', 'compression': 'gzip', 'bytes': compressed.stat().st_size, 'sha256': sha_file(compressed),
        'databaseFile': 'catalog.sqlite', 'databaseBytes': database.stat().st_size, 'databaseSha256': sha_file(database),
        'version': version, 'counts': counts,
        'sources': [{**s, 'foods': counts[s['sourceId']]} for s in parent['sources'] if s['sourceId'] in counts],
        'pack': {'id': pack_id, 'title': pack['title'], 'countries': pack['countries'], 'parentVersion': parent['version'],
                 'parentSha256': parent['sha256'], 'offLimit': limit, 'offCandidates': len(codes)},
    })
    payload['exports'] = subset_exports(parent, LOCAL / 'exports' / payload['sha256'], food_ids)
    if sum(e['rows'] for e in payload['exports']) != counts['foods']:
        raise ValueError('Pack exports do not match pack rows')
    sign_manifest(payload, LOCAL / 'signing', assets)
    shutil.copyfile(assets / 'manifest.json', LOCAL / 'exports' / payload['sha256'] / 'manifest.json')
    update_zip(assets, out)
    report = {'pack': pack_id, 'foods': counts['foods'], 'counts': counts, 'databaseBytes': payload['databaseBytes'],
              'gzipBytes': payload['bytes'], 'zipBytes': (out / 'catalog-update.zip').stat().st_size,
              'sha256': payload['sha256'], 'version': version}
    (out / 'report.json').write_text(canonical(report) + '\n', encoding='utf-8')
    print(canonical(report), flush=True)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pack', choices=sorted(PACKS), required=True)
    parser.add_argument('--off-limit', type=int, help='keep only the N most scanned OFF products')
    args = parser.parse_args()
    build(args.pack, args.off_limit)


if __name__ == '__main__':
    sys.exit(main())
