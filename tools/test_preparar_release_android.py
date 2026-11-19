"""Release configuration and upgrade failures must stop before changing device data."""
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

import preparar_release_android as release
from preparar_release_android import release_config, validate_upgrade


class ReleasePreparationTests(unittest.TestCase):
    def config(self, url="https://api.trainforge.test"):
        return {"APP_ENV": "staging", "API_BASE_URL": url,
                "GOOGLE_SERVER_CLIENT_ID": "public-test.apps.googleusercontent.com"}

    def test_release_refuses_local_insecure_or_credential_urls(self):
        for url in ["http://api.trainforge.test", "https://127.0.0.1", "https://10.0.0.3",
                    "https://[::1]", "https://user:secret@api.trainforge.test", "https://api.trainforge.test?token=x",
                    "https://api.trainforge.test/path", "https://api.trainforge.test:bad"]:
            with self.subTest(url=url), self.assertRaises(ValueError):
                release_config(self.config(url))

    def test_release_rejects_secret_or_unexpected_defines(self):
        for extra in [{"TOKEN": "private"}, {"APP_ENV": "development"}, {"GOOGLE_SERVER_CLIENT_ID": ""}]:
            with self.assertRaises(ValueError):
                release_config({**self.config(), **extra})
        self.assertEqual(release_config(self.config()), self.config())

    def test_upgrade_requires_same_identity_and_increasing_version(self):
        previous = {"manifest": {"package": "com.example.trainforge", "versionCode": 29},
                    "certificateSha256": "a" * 64}
        candidate = {"manifest": {"package": "com.example.trainforge", "versionCode": 30},
                     "certificateSha256": "a" * 64}
        validate_upgrade(previous, candidate)
        for change in [{"certificateSha256": "b" * 64},
                       {"manifest": {"package": "other.app", "versionCode": 30}},
                       {"manifest": {"package": "com.example.trainforge", "versionCode": 29}}]:
            with self.assertRaises(ValueError):
                validate_upgrade(previous, {**candidate, **change})

    def prepared_build(self):
        temporary = tempfile.TemporaryDirectory(prefix="trainforge-release-verifier-test-")
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / "android").mkdir()
        (root / "android/key.properties").write_text("synthetic test configuration\n", encoding="utf-8")
        apk = root / "build/app/outputs/flutter-apk/app-release.apk"
        apk.parent.mkdir(parents=True)
        apk.write_bytes(b"synthetic test artifact")
        catalog = {"version": "b" * 64, "sha256": "c" * 64, "complete": True, "fixture": False}
        packaged = {"catalogVersion": catalog["version"], "catalogSha256": catalog["sha256"],
                    "catalogHashVerified": True, "signatureVerified": True, "sqlCipherBundled": True,
                    "fixture": False, "flutterAbis": ["arm64-v8a"]}
        self.enterContext(patch.object(release, "ROOT", root))
        self.enterContext(patch.object(release, "LOCAL", root / ".local"))
        self.enterContext(patch.object(release, "source_fingerprint", return_value="fixed source fingerprint"))
        self.enterContext(patch.object(release, "paths", return_value={"flutter": root / "flutter"}))
        bundle = self.enterContext(patch("food_catalog.verify_bundle", return_value=catalog))
        build = self.enterContext(patch.object(release.subprocess, "run", return_value=SimpleNamespace(returncode=0)))
        self.enterContext(patch.object(release, "inspect_apk", return_value={
            "manifest": {"application": {"debuggable": False, "usesCleartextTraffic": False, "allowBackup": False}}}))
        native = self.enterContext(patch.object(release, "verify_catalog_apk", return_value=packaged))
        return root, apk, bundle, build, native

    def test_release_receipt_requires_verification_of_the_final_apk(self):
        root, apk, bundle, build, native = self.prepared_build()
        report = release.prepare(self.config(), "a" * 64)
        native.assert_called_once_with(apk, root / "assets/food_catalog", ci_fixture=False)
        bundle.assert_called_once_with(root / "assets/food_catalog")
        self.assertEqual(build.call_count, 1)
        self.assertTrue(report["catalogApk"]["signatureVerified"])
        receipt = json.loads((root / ".local/android-release/artifact.json").read_text(encoding="utf-8"))
        self.assertEqual(receipt["catalogApk"], report["catalogApk"])
        self.assertIs(receipt["published"], False)

    def test_invalid_final_apk_never_receives_a_release_receipt(self):
        root, _, _, _, native = self.prepared_build()
        native.side_effect = ValueError("missing SQLCipher for one Flutter ABI")
        with self.assertRaisesRegex(ValueError, "SQLCipher"):
            release.prepare(self.config(), "a" * 64)
        self.assertFalse((root / ".local/android-release/artifact.json").exists())

    def test_catalog_changed_during_build_cannot_be_certified(self):
        root, _, _, _, native = self.prepared_build()
        native.return_value = {**native.return_value, "catalogSha256": "d" * 64}
        with self.assertRaisesRegex(ValueError, "verified release inputs"):
            release.prepare(self.config(), "a" * 64)
        self.assertFalse((root / ".local/android-release/artifact.json").exists())

    def test_check_only_never_builds_or_claims_a_verified_final_apk(self):
        root, _, _, build, native = self.prepared_build()
        report = release.prepare(self.config(), "a" * 64, check_only=True)
        build.assert_not_called()
        native.assert_not_called()
        self.assertIs(report["built"], False)
        self.assertNotIn("catalogApk", report)
        self.assertFalse((root / ".local/android-release/artifact.json").exists())

    def test_fixture_catalog_stops_release_before_building(self):
        root, _, bundle, build, native = self.prepared_build()
        bundle.side_effect = ValueError("Catalog is a fixture or is incomplete")
        with self.assertRaisesRegex(ValueError, "fixture"):
            release.prepare(self.config(), "a" * 64)
        build.assert_not_called()
        native.assert_not_called()
        self.assertFalse((root / ".local/android-release/artifact.json").exists())
