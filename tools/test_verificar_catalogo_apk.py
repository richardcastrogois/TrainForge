"""Tiny signed APK fixtures cover distribution gates without a real food catalog."""
from __future__ import annotations

import base64
import gzip
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from verificar_catalogo_apk import MANIFEST_LIMIT, PREFIX, verify


class CatalogApkTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='trainforge-apk-verifier-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.assets = self.root / 'assets'
        self.assets.mkdir()
        self.apk = self.root / 'fixture.apk'
        self.key = Ed25519PrivateKey.generate()
        self.data = b'SQLite format 3\x00synthetic verifier bytes'

    def manifest(self, **changes):
        return {'contract': 'trainforge.food-catalog/1', 'schemaVersion': 1,
                'version': 'a' * 64, 'file': 'catalog.sqlite',
                'sha256': hashlib.sha256(self.data).hexdigest(), 'bytes': len(self.data),
                'complete': True, 'fixture': False, 'missingSources': [], **changes}

    def build(self, manifest=None, *, data=None, libraries=None, message=None, trust_changes=None, extra=None):
        manifest = self.manifest() if manifest is None else manifest
        if message is None:
            message = json.dumps(manifest).encode()
        envelope = json.dumps({'keyId': 'test', 'payload': base64.b64encode(message).decode(),
                               'signature': base64.b64encode(self.key.sign(message)).decode()}).encode()
        public = self.key.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
        trust = json.dumps({'contract': 'trainforge.food-catalog-trust/1', 'keys': [
            {'keyId': 'test', 'algorithm': 'Ed25519', 'publicKey': base64.b64encode(public).decode()}],
            **(trust_changes or {})}).encode()
        (self.assets / 'manifest.json').write_bytes(envelope)
        (self.assets / 'trust.json').write_bytes(trust)
        if libraries is None:
            libraries = ['lib/arm64-v8a/libflutter.so', 'lib/arm64-v8a/libsqlcipher.so',
                         'lib/armeabi-v7a/libflutter.so', 'lib/armeabi-v7a/libsqlcipher.so']
        with zipfile.ZipFile(self.apk, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(PREFIX + 'manifest.json', envelope)
            archive.writestr(PREFIX + 'trust.json', trust)
            archive.writestr(PREFIX + manifest.get('file', 'catalog.sqlite'), self.data if data is None else data)
            for name in libraries:
                archive.writestr(name, b'native fixture')
            for name, value in (extra or {}).items():
                archive.writestr(name, value)

    def test_valid_production_apk_verifies_every_flutter_abi(self):
        self.build()
        report = verify(self.apk, self.assets)
        self.assertTrue(report['catalogHashVerified'])
        self.assertTrue(report['signatureVerified'])
        self.assertEqual(report['flutterAbis'], ['arm64-v8a', 'armeabi-v7a'])
        self.assertIs(report['fixture'], False)

    def test_gzip_preserves_distinct_distribution_and_database_identities(self):
        compressed = gzip.compress(self.data, mtime=0)
        manifest = self.manifest(file='catalog.sqlite.gz', bytes=len(compressed),
                                 sha256=hashlib.sha256(compressed).hexdigest(),
                                 databaseFile='catalog.sqlite', databaseBytes=len(self.data),
                                 databaseSha256=hashlib.sha256(self.data).hexdigest())
        self.build(manifest, data=compressed)
        report = verify(self.apk, self.assets)
        self.assertEqual(report['catalogBytes'], len(compressed))
        self.assertEqual(report['databaseBytes'], len(self.data))
        for field, value in [('databaseBytes', True), ('databaseBytes', '40'),
                             ('databaseSha256', None), ('databaseFile', 'other.sqlite')]:
            with self.subTest(field=field, value=value):
                self.build({**manifest, field: value}, data=compressed)
                with self.assertRaises(ValueError):
                    verify(self.apk, self.assets)

    def test_signed_field_types_are_strict_even_with_a_valid_signature(self):
        cases = [('schemaVersion', True), ('schemaVersion', 1.0), ('schemaVersion', '1'),
                 ('bytes', True), ('bytes', 0), ('bytes', -1), ('bytes', 42.0), ('bytes', '42'),
                 ('version', True), ('version', 'short'), ('sha256', 'z' * 64),
                 ('complete', 1), ('fixture', 0), ('missingSources', None),
                 ('missingSources', {}), ('missingSources', False), ('missingSources', ''),
                 ('missingSources', [False])]
        for field, value in cases:
            with self.subTest(field=field, value=value):
                self.build(self.manifest(**{field: value}))
                with self.assertRaises(ValueError):
                    verify(self.apk, self.assets)
        manifest = self.manifest()
        del manifest['missingSources']
        self.build(manifest)
        with self.assertRaises(ValueError):
            verify(self.apk, self.assets)

    def test_fixture_requires_both_explicit_ci_flags_and_never_passes_production(self):
        self.build(self.manifest(complete=False, fixture=True, missingSources=['production catalog']))
        with patch.dict(os.environ, {'CI': 'true', 'TF_CATALOG_NATIVE_FIXTURE': '1'}):
            self.assertIs(verify(self.apk, self.assets, ci_fixture=True)['fixture'], True)
            with self.assertRaises(ValueError):
                verify(self.apk, self.assets)
        for flags in [{'CI': 'false', 'TF_CATALOG_NATIVE_FIXTURE': '1'},
                      {'CI': 'true', 'TF_CATALOG_NATIVE_FIXTURE': '0'}]:
            with self.subTest(flags=flags), patch.dict(os.environ, flags), self.assertRaises(ValueError):
                verify(self.apk, self.assets, ci_fixture=True)
        self.build(self.manifest(missingSources=['a real missing source']))
        with self.assertRaises(ValueError):
            verify(self.apk, self.assets)

    def test_sqlcipher_must_cover_each_flutter_abi(self):
        for libraries in [[], ['lib/arm64-v8a/libsqlcipher.so'],
                          ['lib/arm64-v8a/libflutter.so', 'lib/armeabi-v7a/libsqlcipher.so'],
                          ['lib/arm64-v8a/libflutter.so', 'lib/arm64-v8a/libsqlcipher.so',
                           'lib/armeabi-v7a/libflutter.so']]:
            with self.subTest(libraries=libraries):
                self.build(libraries=libraries)
                with self.assertRaisesRegex(ValueError, 'Flutter ABI'):
                    verify(self.apk, self.assets)
        self.build(libraries=['lib/arm64-v8a/libflutter.so'],
                   extra={'lib/arm64-v8a/libsqlcipher.so': b''})
        with self.assertRaisesRegex(ValueError, 'Flutter ABI'):
            verify(self.apk, self.assets)

    def test_corrupted_payload_or_metadata_cannot_pass(self):
        self.build(data=b'X' + self.data[1:])
        with self.assertRaisesRegex(ValueError, 'hash mismatch'):
            verify(self.apk, self.assets)
        self.build()
        (self.assets / 'manifest.json').write_bytes(b'{}')
        with self.assertRaisesRegex(ValueError, 'reviewed build inputs'):
            verify(self.apk, self.assets)

    def test_ambiguous_or_invalid_trust_is_rejected(self):
        for trust in [{'contract': 'unknown'}, {'keys': {}}, {'keys': [None]},
                      {'keys': [{'keyId': 'test', 'algorithm': 'Ed25519', 'publicKey': True}]}]:
            with self.subTest(trust=trust):
                self.build(trust_changes=trust)
                with self.assertRaises(ValueError):
                    verify(self.apk, self.assets)
        message = json.dumps(self.manifest())[:-1].encode() + b',"schemaVersion":1}'
        self.build(message=message)
        with self.assertRaisesRegex(ValueError, 'Duplicate catalog JSON key'):
            verify(self.apk, self.assets)
        self.build(message=b'[]')
        with self.assertRaisesRegex(ValueError, 'JSON object'):
            verify(self.apk, self.assets)

    def test_signature_must_match_the_reviewed_public_key(self):
        other = Ed25519PrivateKey.generate().public_key().public_bytes(
            serialization.Encoding.Raw, serialization.PublicFormat.Raw)
        self.build(trust_changes={'keys': [{'keyId': 'test', 'algorithm': 'Ed25519',
                                           'publicKey': base64.b64encode(other).decode()}]})
        with self.assertRaisesRegex(ValueError, 'signature is not trusted'):
            verify(self.apk, self.assets)

    def test_metadata_is_bounded_before_json_decoding(self):
        self.build()
        with patch('verificar_catalogo_apk.MANIFEST_LIMIT', 16):
            with self.assertRaisesRegex(ValueError, 'metadata size'):
                verify(self.apk, self.assets)

    def test_payload_hashing_never_reads_the_whole_apk_into_memory(self):
        self.data = b'small bounded stream fixture' * 85000
        self.build()
        requested = []
        original = zipfile.ZipExtFile.read

        def bounded(stream, size=-1):
            requested.append(size)
            self.assertGreater(size, 0)
            self.assertLessEqual(size, MANIFEST_LIMIT + 1)
            return original(stream, size)

        with patch.object(zipfile.ZipExtFile, 'read', bounded):
            verify(self.apk, self.assets)
        self.assertGreater(requested.count(1 << 20), 2)
