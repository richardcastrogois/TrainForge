import json
import unittest

import gerar_treinos_app as g


class TrainingAssetTest(unittest.TestCase):
    def test_asset_matches_research(self):
        expected = json.dumps(g.build(), ensure_ascii=False, indent=1) + "\n"
        self.assertEqual(g.OUT.read_text(encoding="utf-8"), expected, "rode python tools/gerar_treinos_app.py")

    def test_only_ready_sessions_with_exercises(self):
        data = g.build()
        self.assertEqual(len(data["sessions"]), 122)
        self.assertTrue(all(s["exercises"] and s["source"]["name"] for s in data["sessions"]))


if __name__ == "__main__":
    unittest.main()
