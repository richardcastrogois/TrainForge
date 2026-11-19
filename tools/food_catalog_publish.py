"""Preserve signed per-source exports by release, without DB writes or hosting.

Run before reusing the export directory for another catalog build. Moves only
verified public exports into an immutable SHA directory; never copies private
files, accepts fixture data, activates SQL, or publishes to the internet.
"""
from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
import re

from food_catalog import ROOT, sha_file
from verificar_catalogo_apk import json_object, signed_manifest


def archive_exports(assets: Path, exports: Path, confirmation: str) -> dict:
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    assets, exports = Path(assets).resolve(), Path(exports).resolve()
    raw = (assets / 'manifest.json').read_bytes()
    trust_raw = (assets / 'trust.json').read_bytes()
    if len(raw) > 2 << 20 or len(trust_raw) > 64 << 10:
        raise ValueError('Oversized catalog metadata')
    envelope, trust = json_object(raw), json_object(trust_raw)
    if trust.get('contract') != 'trainforge.food-catalog-trust/1':
        raise ValueError('Unknown catalog trust contract')
    keys = [key for key in trust.get('keys', [])
            if key.get('keyId') == envelope.get('keyId') and key.get('algorithm') == 'Ed25519']
    if len(keys) != 1:
        raise ValueError('Unknown or ambiguous catalog key')
    message = base64.b64decode(envelope['payload'], validate=True)
    Ed25519PublicKey.from_public_bytes(base64.b64decode(keys[0]['publicKey'], validate=True)).verify(
        base64.b64decode(envelope['signature'], validate=True), message)
    manifest = signed_manifest(message, ci_fixture=False)
    artifact = manifest['sha256']
    if confirmation != artifact:
        raise ValueError('Explicit catalog SHA256 confirmation required')
    target = exports / artifact
    if target.resolve() != target or not target.is_relative_to(exports):
        raise ValueError('Unsafe export destination')
    records = manifest.get('exports')
    if type(records) is not list or not records:
        raise ValueError('Signed source exports required')
    checked = []
    filenames = set()
    for entry in records:
        filename = entry.get('file') if type(entry) is dict else None
        if (type(filename) is not str or not re.fullmatch(r'[A-Za-z0-9_.-]+[.]jsonl[.]gz', filename)
                or filename in filenames or type(entry.get('bytes')) is not int or entry['bytes'] <= 0
                or type(entry.get('sha256')) is not str or not re.fullmatch(r'[a-f0-9]{64}', entry['sha256'])
                or not entry.get('license') or not entry.get('sourceId')):
            raise ValueError('Invalid signed source export')
        filenames.add(filename)
        source, destination = exports / filename, target / filename
        existing = [p for p in (source, destination) if p.exists()]
        if not existing:
            raise ValueError('Signed source export is missing')
        for path in existing:
            if (path.is_symlink() or not path.is_file() or path.resolve() != path
                    or path.stat().st_size != entry['bytes'] or sha_file(path) != entry['sha256']):
                raise ValueError('Source export identity mismatch; nothing moved')
        checked.append((source, destination))
    final_manifest = target / 'manifest.json'
    if final_manifest.exists() and final_manifest.read_bytes() != raw:
        raise ValueError('Release metadata already exists with different bytes')
    # All bytes are checked before moving anything. An interrupted move can be
    # resumed: the next run checks both roots and writes the manifest last.
    target.mkdir(parents=True, exist_ok=True)
    moved = 0
    for source, destination in checked:
        if not destination.exists():
            source.rename(destination)
            moved += 1
    if not final_manifest.exists():
        temporary = target / 'manifest.json.part'
        with temporary.open('wb') as stream:
            stream.write(raw)
            stream.flush()
        temporary.replace(final_manifest)
    return {'contract': 'trainforge.food-catalog-public-exports/1',
            'artifactSha256': artifact, 'sources': len(checked), 'moved': moved,
            'databaseWrites': 0, 'publishedToInternet': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets', type=Path, default=ROOT / 'assets/food_catalog')
    parser.add_argument('--exports', type=Path, default=ROOT / '.local/food-catalog/exports')
    parser.add_argument('--confirm', required=True, help='Signed catalog artifact SHA256')
    args = parser.parse_args()
    try:
        report = archive_exports(args.assets, args.exports, args.confirm)
    except Exception:
        parser.exit(1, 'Public export preparation failed; no SQL activation or internet publication occurred.\n')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
