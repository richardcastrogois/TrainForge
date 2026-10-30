"""Parser/policy tests use synthetic public metadata, never a device or credentials."""
import copy
import unittest

from android_security_inventory import (
    BACKUP_DOMAINS, PACKAGE, REVIEWED_PERMISSIONS, parse_tree,
    summarize_manifest, verify_debug_policy, verify_exclusions,
)


MANIFEST = f'''N: android=http://schemas.android.com/apk/res/android
E: manifest (line=1)
  A: package="{PACKAGE}"
  A: http://schemas.android.com/apk/res/android:versionCode(0x0101021b)=27
  A: http://schemas.android.com/apk/res/android:versionName(0x0101021c)="0.4.5"
  E: uses-sdk (line=2)
    A: android:minSdkVersion=24
    A: android:targetSdkVersion=36
  E: uses-permission (line=3)
    A: android:name="android.permission.INTERNET"
  E: application (line=4)
    A: android:debuggable=true
    A: android:allowBackup=false
    A: android:usesCleartextTraffic=true
    A: android:fullBackupContent=@0x7f110000
    A: android:dataExtractionRules=@0x7f110001
    E: activity (line=5)
      A: android:name="{PACKAGE}.MainActivity"
      A: android:exported=true
      E: intent-filter (line=6)
        E: action (line=7)
          A: android:name="android.intent.action.MAIN"
        E: category (line=8)
          A: android:name="android.intent.category.LAUNCHER"
    E: receiver (line=9)
      A: android:name="androidx.profileinstaller.ProfileInstallReceiver"
      A: android:exported=true
      A: android:permission="android.permission.DUMP"
    E: service (line=10)
      A: android:name="com.google.android.gms.auth.api.signin.RevocationBoundService"
      A: android:exported=true
      A: android:permission="com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION"
    E: service (line=11)
      A: android:name="fixture.PrivateService"
      A: android:exported=false
'''
ARTIFACT = {"package": PACKAGE, "variant": "debug", "versionName": "0.4.5", "versionCode": 27}


def exclusions(tag, missing=None):
    sections = [None] if tag == "full-backup-content" else ["cloud-backup", "device-transfer"]
    lines = [f"E: {tag} (line=1)"]
    for section in sections:
        if section:
            lines.append(f"  E: {section} (line=2)")
        indent = "    " if section else "  "
        for domain in sorted(BACKUP_DOMAINS - set(missing or [])):
            lines.extend([f"{indent}E: exclude (line=3)",
                          f'{indent}  A: domain="{domain}"', f'{indent}  A: path="."'])
    return "\n".join(lines)


class AndroidInventoryTests(unittest.TestCase):
    def test_compiled_manifest_preserves_types_and_hierarchy(self):
        report = summarize_manifest(MANIFEST)
        self.assertEqual(report["minSdk"], 24)
        self.assertEqual(report["targetSdk"], 36)
        self.assertIs(report["application"]["allowBackup"], False)
        self.assertEqual(len(report["exportedComponents"]), 3)
        self.assertTrue(report["exportedComponents"][0]["launcher"])
        self.assertFalse(report["exportedComponents"][1]["launcher"])
        verify_debug_policy(report, ARTIFACT)

    def test_unreviewed_permission_or_unprotected_export_is_rejected(self):
        report = summarize_manifest(MANIFEST)
        report["permissions"] = sorted(REVIEWED_PERMISSIONS | {"android.permission.CAMERA"})
        with self.assertRaisesRegex(ValueError, "permission"):
            verify_debug_policy(report, ARTIFACT)
        report = summarize_manifest(MANIFEST)
        for index in (1, 2):
            changed = copy.deepcopy(report)
            changed["exportedComponents"][index]["permission"] = None
            with self.subTest(component=index), self.assertRaisesRegex(ValueError, "exported"):
                verify_debug_policy(changed, ARTIFACT)

    def test_debug_receipt_version_backup_and_package_are_required(self):
        for key, value in (("variant", "release"), ("versionCode", 28), ("package", "other.app")):
            artifact = copy.deepcopy(ARTIFACT)
            artifact[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                verify_debug_policy(summarize_manifest(MANIFEST), artifact)
        for key, value in (("debuggable", False), ("allowBackup", True), ("dataExtractionRules", None)):
            report = summarize_manifest(MANIFEST)
            report["application"][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                verify_debug_policy(report, ARTIFACT)
        with self.assertRaisesRegex(ValueError, "package"):
            summarize_manifest(MANIFEST.replace(PACKAGE, "other.app"))

    def test_both_backup_formats_exclude_all_private_domains(self):
        for tag in ("full-backup-content", "data-extraction-rules"):
            with self.subTest(tag=tag):
                self.assertTrue(verify_exclusions(exclusions(tag), tag))
                with self.assertRaisesRegex(ValueError, "exclusion"):
                    verify_exclusions(exclusions(tag, {"sharedpref"}), tag)
        with self.assertRaisesRegex(ValueError, "section"):
            verify_exclusions("E: data-extraction-rules (line=1)", "data-extraction-rules")

    def test_malformed_or_multiple_root_output_is_rejected(self):
        for text in ("unrelated output", "E: manifest\nE: application"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse_tree(text)


if __name__ == "__main__":
    unittest.main()
