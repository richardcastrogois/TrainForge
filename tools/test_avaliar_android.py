import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import avaliar_android as android

class AndroidEvaluationSafetyTest(unittest.TestCase):
    def test_stop_refuses_state_from_other_checkout_before_side_effects(self):
        with tempfile.TemporaryDirectory() as temp:
            state=Path(temp)/"state.json"
            state.write_text(json.dumps({"root":"C:/different-checkout","apiStopFile":"C:/outside/target"}))
            with patch.object(android,"STATE",state),patch.object(android,"output",side_effect=AssertionError("must not run")):
                with self.assertRaisesRegex(RuntimeError,"outro checkout"):
                    android.stop({})
    def test_stop_refuses_arbitrary_file_target(self):
        with tempfile.TemporaryDirectory() as temp:
            base=Path(temp)
            state=base/"state.json"
            outside=base/"outside.txt"
            state.write_text(json.dumps({"root":str(android.ROOT),"apiStopFile":str(outside)}))
            with patch.object(android,"STATE",state),patch.object(android,"STATE_DIR",base/"owned"):
                with self.assertRaisesRegex(RuntimeError,"Alvo"):
                    android.stop({})
            self.assertFalse(outside.exists())
    def test_public_configuration_only_includes_public_values(self):
        with tempfile.TemporaryDirectory() as temp:
            base=Path(temp)
            (base/"api.env").write_text("TF_DATABASE_URL=private-secret\nTF_GOOGLE_SERVER_CLIENT_ID=public.apps.googleusercontent.com\n")
            with patch.object(android,"LOCAL",base),patch.dict(android.os.environ,{},clear=True):
                config=android.public_config()
            self.assertEqual(set(config),{"API_BASE_URL","GOOGLE_SERVER_CLIENT_ID"})
            self.assertNotIn("private-secret",json.dumps(config))
    def test_installed_apk_path_is_validated_before_shell_hash(self):
        calls=[]
        def result(command,timeout=20):
            calls.append(command)
            return "package:/data/app/unsafe;command/base.apk"
        with patch.object(android,"output",side_effect=result):
            self.assertIsNone(android.installed_sha256({"adb":"adb"},"emulator-5554"))
        self.assertEqual(len(calls),1)
    def test_wait_retries_transient_adb_failure(self):
        with patch.object(android.time,"sleep"),patch.object(android,"api_ready"):
            outcomes=iter([RuntimeError("temporary"),"ready"])
            def check():
                value=next(outcomes)
                if isinstance(value,Exception):raise value
                return value
            self.assertEqual(android.wait_for(check,1,"timeout"),"ready")


    def test_android_credentials_are_excluded_from_backup_and_transfer(self):
        import xml.etree.ElementTree as ET
        ns="{http://schemas.android.com/apk/res/android}"
        application=ET.parse(android.ROOT/"android/app/src/main/AndroidManifest.xml").getroot().find("application")
        self.assertEqual(application.get(ns+"allowBackup"),"false")
        self.assertEqual(application.get(ns+"fullBackupContent"),"@xml/backup_rules")
        self.assertEqual(application.get(ns+"dataExtractionRules"),"@xml/data_extraction_rules")
        legacy=ET.parse(android.ROOT/"android/app/src/main/res/xml/backup_rules.xml").getroot()
        current=ET.parse(android.ROOT/"android/app/src/main/res/xml/data_extraction_rules.xml").getroot()
        for rules in [legacy,current.find("cloud-backup"),current.find("device-transfer"),current.find("cross-platform-transfer")]:
            excluded={e.get("domain") for e in rules.findall("exclude") if e.get("path")=="."}
            self.assertTrue({"root","file","database","sharedpref","device_sharedpref"}.issubset(excluded))

    def test_artifact_fingerprint_includes_locale_resources_and_generation_config(self):
        with tempfile.TemporaryDirectory() as temp:
            base=Path(temp)
            for relative in [
                "pubspec.yaml","pubspec.lock","android/app/build.gradle.kts",
                "android/app/src/main/AndroidManifest.xml","android/app/src/debug/AndroidManifest.xml",
                "lib/l10n/app_en.arb","l10n.yaml",
            ]:
                target=base/relative
                target.parent.mkdir(parents=True,exist_ok=True)
                target.write_text("isolated",encoding="utf-8")
            with patch.object(android,"ROOT",base):
                before=android.source_fingerprint()
                (base/"lib/l10n/app_en.arb").write_text("changed message",encoding="utf-8")
                self.assertNotEqual(before,android.source_fingerprint())
                (base/"lib/l10n/app_en.arb").write_text("isolated",encoding="utf-8")
                self.assertEqual(before,android.source_fingerprint())
                (base/"l10n.yaml").write_text("changed generation config",encoding="utf-8")
                self.assertNotEqual(before,android.source_fingerprint())

if __name__=="__main__":
    unittest.main()
