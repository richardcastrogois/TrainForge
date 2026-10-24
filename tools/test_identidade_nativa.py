import json,struct,unittest,xml.etree.ElementTree as ET
from pathlib import Path
import gerar_identidade_nativa as brand

class NativeBrandTests(unittest.TestCase):
    def test_all_native_icons_match_provenance_and_dimensions(self):
        brand.check()
    def test_ios_icons_have_no_alpha_channel(self):
        manifest=json.loads(brand.MANIFEST.read_text())
        for icon in manifest["files"]:
            if icon["kind"]=="ios":
                self.assertEqual((brand.ROOT/icon["path"]).read_bytes()[25],2,"iOS icon must be RGB")
    def test_adaptive_icons_reference_brand_resources(self):
        ns="{http://schemas.android.com/apk/res/android}"
        for version in ["v26","v33"]:
            tree=ET.parse(brand.ROOT/("android/app/src/main/res/mipmap-anydpi-"+version+"/ic_launcher.xml")).getroot()
            self.assertEqual(tree.tag,"adaptive-icon")
            self.assertEqual(tree.find("background").get(ns+"drawable"),"@color/tf_brand_green")
            self.assertEqual(tree.find("foreground").get(ns+"drawable"),"@mipmap/ic_launcher_foreground")
            if version=="v33":self.assertEqual(tree.find("monochrome").get(ns+"drawable"),"@mipmap/ic_launcher_monochrome")
    def test_native_splash_uses_the_same_brand_in_light_and_dark(self):
        for directory in ['values-v31','values-night-v31']:
            tree=ET.parse(brand.ROOT/('android/app/src/main/res/'+directory+'/styles.xml')).getroot()
            values={n.get('name'):n.text for n in tree.find('style').findall('item')}
            self.assertEqual(values['android:windowSplashScreenBackground'],'@color/tf_brand_green')
            self.assertEqual(values['android:windowSplashScreenAnimatedIcon'],'@drawable/tf_splash')
        ET.parse(brand.ROOT/'ios/Runner/Base.lproj/LaunchScreen.storyboard')
        self.assertIn('LaunchImage',(brand.ROOT/'ios/Runner/Base.lproj/LaunchScreen.storyboard').read_text())
    def test_public_package_and_oauth_identity_are_unchanged(self):
        tree=ET.parse(brand.ROOT/"android/app/src/main/AndroidManifest.xml").getroot()
        ns="{http://schemas.android.com/apk/res/android}"
        self.assertEqual(tree.find("application").get(ns+"label"),"TrainForge")
        self.assertEqual(tree.find("application").get(ns+"icon"),"@mipmap/ic_launcher")
        self.assertIn('applicationId = "com.example.trainforge"',(brand.ROOT/"android/app/build.gradle.kts").read_text())

if __name__=="__main__":unittest.main()
