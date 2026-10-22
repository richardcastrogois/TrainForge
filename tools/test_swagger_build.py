import unittest
from gerar_swagger import validate_build_info

class SwagBuildTests(unittest.TestCase):
    def test_actual_pinned_module_is_authoritative(self):
        validate_build_info("swag.exe: go1.27.3\n\tmod\tgithub.com/swaggo/swag\tv1.16.6\th1:fixture")
    def test_cli_label_or_different_module_is_not_proof(self):
        for text in ["swag version v1.16.6","mod github.com/swaggo/swag v1.16.4","mod another/module v1.16.6"]:
            with self.assertRaises(ValueError):validate_build_info(text)
