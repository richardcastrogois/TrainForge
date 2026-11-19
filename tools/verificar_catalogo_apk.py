"""Verify signed catalog bytes and encrypted SQLite native libraries inside an APK."""
from __future__ import annotations
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PREFIX = 'assets/flutter_assets/assets/food_catalog/'
MANIFEST_LIMIT = 2 << 20
TRUST_LIMIT = 64 << 10
SHA256 = re.compile(r'[a-f0-9]{64}')


def json_object(raw):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError('Duplicate catalog JSON key')
            result[key] = value
        return result

    def invalid_constant(_):
        raise ValueError('Non-finite catalog JSON number')

    result = json.loads(raw, object_pairs_hook=pairs, parse_constant=invalid_constant)
    if type(result) is not dict:
        raise ValueError('Catalog metadata must be a JSON object')
    return result


def metadata(archive, assets, filename, limit):
    try:
        entry = archive.getinfo(PREFIX + filename)
    except KeyError:
        raise ValueError('APK catalog metadata is missing') from None
    if not 0 < entry.file_size <= limit:
        raise ValueError('Invalid APK catalog metadata size')
    with archive.open(entry) as stream:
        raw = stream.read(limit + 1)
    with (assets / filename).open('rb') as stream:
        reviewed = stream.read(limit + 1)
    if len(raw) > limit or len(reviewed) > limit or raw != reviewed:
        raise ValueError('APK catalog metadata differs from the reviewed build inputs')
    return raw


def positive_integer(value):
    return type(value) is int and 0 < value <= (1 << 63) - 1


def sha256(value):
    return type(value) is str and SHA256.fullmatch(value) is not None


def signed_manifest(message, ci_fixture):
    manifest = json_object(message)
    if (manifest.get('contract') != 'trainforge.food-catalog/1'
            or type(manifest.get('schemaVersion')) is not int or manifest['schemaVersion'] != 1):
        raise ValueError('Unknown catalog contract')
    if (not sha256(manifest.get('version')) or not sha256(manifest.get('sha256'))
            or not positive_integer(manifest.get('bytes'))
            or type(manifest.get('complete')) is not bool or type(manifest.get('fixture')) is not bool
            or type(manifest.get('missingSources')) is not list
            or any(type(source) is not str or not source for source in manifest['missingSources'])):
        raise ValueError('Invalid signed catalog field type')
    if not ci_fixture and (not manifest['complete'] or manifest['fixture'] or manifest['missingSources'] != []):
        raise ValueError('Incomplete/fixture data cannot pass production artifact verification')
    filename = manifest.get('file')
    if type(filename) is not str or filename not in {'catalog.sqlite', 'catalog.sqlite.gz'}:
        raise ValueError('Unsafe catalog filename')
    if filename == 'catalog.sqlite.gz':
        if (manifest.get('databaseFile') != 'catalog.sqlite'
                or not positive_integer(manifest.get('databaseBytes'))
                or not sha256(manifest.get('databaseSha256'))):
            raise ValueError('Invalid uncompressed catalog identity')
    else:
        if ('databaseFile' in manifest and manifest['databaseFile'] != 'catalog.sqlite'
                or 'databaseBytes' in manifest and (not positive_integer(manifest['databaseBytes']) or manifest['databaseBytes'] != manifest['bytes'])
                or 'databaseSha256' in manifest and (not sha256(manifest['databaseSha256']) or manifest['databaseSha256'] != manifest['sha256'])):
            raise ValueError('Invalid uncompressed catalog identity')
    return manifest


def verify(apk: Path, assets: Path, *, ci_fixture=False):
    from cryptography.exceptions import InvalidSignature
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    if type(ci_fixture) is not bool:
        raise ValueError('Fixture selection must be boolean')
    if ci_fixture and (os.environ.get('CI') != 'true' or os.environ.get('TF_CATALOG_NATIVE_FIXTURE') != '1'):
        raise ValueError('Fixture acceptance requires explicit CI context')
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('APK contains duplicate ZIP entries')
        raw = metadata(archive, assets, 'manifest.json', MANIFEST_LIMIT)
        trust_raw = metadata(archive, assets, 'trust.json', TRUST_LIMIT)
        envelope, trust = json_object(raw), json_object(trust_raw)
        if any(type(envelope.get(field)) is not str or not envelope[field] for field in ('keyId', 'payload', 'signature')):
            raise ValueError('Invalid catalog signature envelope')
        if (trust.get('contract') != 'trainforge.food-catalog-trust/1'
                or type(trust.get('keys')) is not list or not 1 <= len(trust['keys']) <= 16
                or any(type(key) is not dict or any(type(key.get(field)) is not str or not key[field]
                       for field in ('keyId', 'algorithm', 'publicKey')) for key in trust['keys'])):
            raise ValueError('Invalid catalog trust metadata')
        keys = [key for key in trust['keys'] if key['keyId'] == envelope['keyId'] and key['algorithm'] == 'Ed25519']
        if len(keys) != 1: raise ValueError('Ambiguous catalog signing key')
        message = base64.b64decode(envelope['payload'], validate=True)
        try:
            Ed25519PublicKey.from_public_bytes(base64.b64decode(keys[0]['publicKey'], validate=True)).verify(
                base64.b64decode(envelope['signature'], validate=True), message)
        except InvalidSignature:
            raise ValueError('APK catalog signature is not trusted') from None
        manifest = signed_manifest(message, ci_fixture)
        filename = manifest['file']
        try:
            database = archive.getinfo(PREFIX + filename)
        except KeyError:
            raise ValueError('APK catalog payload is missing') from None
        if database.file_size != manifest['bytes']: raise ValueError('APK catalog size mismatch')
        digest = hashlib.sha256()
        with archive.open(database) as stream:
            for block in iter(lambda: stream.read(1 << 20), b''): digest.update(block)
        if digest.hexdigest() != manifest['sha256']: raise ValueError('APK catalog hash mismatch')
        flutter_abis = {parts[1] for name in names if len(parts := name.split('/')) == 3
                        and parts[0] == 'lib' and parts[2] == 'libflutter.so'}
        if not flutter_abis or any('lib/' + abi + '/libsqlcipher.so' not in names
                                   or archive.getinfo('lib/' + abi + '/libsqlcipher.so').file_size == 0
                                   for abi in flutter_abis):
            raise ValueError('Native SQLCipher library is missing for a Flutter ABI')
        if any(name.startswith(PREFIX) and name != PREFIX + filename and name.endswith(('.sqlite', '.building.sqlite', '.pem', '.p12', '.zip')) for name in names):
            raise ValueError('APK contains unexpected large or private catalog artifacts')
        return {'catalogVersion':manifest['version'],'catalogSha256':manifest['sha256'],'catalogBytes':manifest['bytes'],
                'databaseBytes':manifest.get('databaseBytes',manifest['bytes']),
                'catalogHashVerified':True,'signatureVerified':True,'sqlCipherBundled':True,
                'fixture':manifest['fixture'],'flutterAbis':sorted(flutter_abis),'apkBytes':apk.stat().st_size}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path, required=True)
    parser.add_argument('--assets', type=Path, default=ROOT/'assets/food_catalog')
    parser.add_argument('--fixture-ci', action='store_true')
    args = parser.parse_args()
    print(json.dumps(verify(args.apk,args.assets,ci_fixture=args.fixture_ci)))


if __name__ == '__main__': main()
