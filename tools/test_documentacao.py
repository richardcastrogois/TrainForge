"""Regressões da documentação portátil. Fixtures existem somente nestes testes."""
import copy
import json
import os
import re
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from documentacao_backlog import validate
from documentacao_inventario import dart_calls, go_inventory, normalized, scan
from gerar_documentacao import ROOT, check_links, outputs
from gerar_swagger import generate


def isolated_copy(destination):
    """Copiar somente fontes/entradas necessárias; nunca banco, rede, raw ou .env."""
    shutil.copytree(ROOT / "lib", destination / "lib", ignore=shutil.ignore_patterns("graphify-out"))
    shutil.copytree(ROOT / "tools", destination / "tools", ignore=shutil.ignore_patterns("__pycache__"))
    paths = {"docs/execucao/v1/backlog.json", "docs/arquitetura/plano.json", "docs/arquitetura/achados.json"}
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / "services/api").rglob("*") if p.is_file() and (p.suffix in {".go", ".sql"} or p.name in {"go.mod", "go.sum"}))
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / "contracts/generated").glob("*.json"))
    backlog = json.loads((ROOT / "docs/execucao/v1/backlog.json").read_text(encoding="utf-8"))
    paths.update(p for e in backlog["epics"] for s in e["stories"] for p in s["inputs"])
    for relative in paths:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / relative, target)


class DocumentationTests(unittest.TestCase):
    def test_inventory_serialization_ignores_filesystem_glob_order(self):
        expected = json.dumps(scan(ROOT), ensure_ascii=False)
        original = Path.glob
        def reversed_module_glob(path, pattern):
            values = list(original(path, pattern))
            return iter(reversed(values)) if path == ROOT / "services/api" and pattern == "go.*" else iter(values)
        with patch.object(Path, "glob", new=reversed_module_glob):
            observed = json.dumps(scan(ROOT), ensure_ascii=False)
        self.assertEqual(observed, expected, "Module file enumeration changed serialized inventory")

    def test_portable_inventory_does_not_require_external_checkout(self):
        data = scan(ROOT)
        self.assertNotIn("backend", data)
        self.assertIsNone(re.search(r"(?<![A-Za-z])[A-Za-z]:[/\\]", json.dumps(data)), "Inventário contém caminho de unidade local")
        for call in data["calls"]:
            self.assertFalse(Path(call["source"]["path"]).is_absolute())

    def test_relocated_tree_and_mtime_produce_identical_outputs(self):
        original, _ = outputs(ROOT)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            isolated_copy(root)
            moved, _ = outputs(root)
            self.assertEqual(original, moved)
            os.utime(root / "lib/main.dart", (1000000000, 1000000000))
            touched, _ = outputs(root)
            self.assertEqual(moved, touched)

    def test_generation_preserves_manual_guides_and_has_one_technical_reference(self):
        expected, _ = outputs(ROOT)
        self.assertEqual(set(expected), {'docs/arquitetura/inventario-atual.json',
                                         'docs/arquitetura/gerado/referencia.md',
                                         'docs/execucao/v1/backlog.md'})
        reference = expected['docs/arquitetura/gerado/referencia.md']
        self.assertNotIn('Referência histórica do backend anterior', reference)
        self.assertNotIn('Arquitetura proposta: ainda a implementar', reference)

    def test_new_screen_and_http_literal_update_without_phantom_navigation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            isolated_copy(root)
            before = scan(root)
            path = root / "lib/features/teste.dart"
            path.write_text("class FixturePage extends StatelessWidget {}\nvoid call() { dio.get('/fixture'); }", encoding="utf-8")
            after = scan(root)
            self.assertNotEqual(before["inputRevision"], after["inputRevision"])
            self.assertIn("FixturePage", [s["id"] for s in after["screens"]])
            self.assertFalse(any(e["to"] == "FixturePage" for e in after["navigation"]))
            call = next(c for c in after["calls"] if c["path"] == "/fixture")
            self.assertEqual(call["goMatches"], [])

    def test_method_path_normalization_does_not_merge_different_actions(self):
        self.assertEqual(normalized("/plans/$plan/days/${day}"), normalized("/plans/:id/days/{day}"))
        self.assertNotEqual(normalized("/sessions/$id/events"), normalized("/sessions/:id"))

    def test_dynamic_dart_path_remains_unknown(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "api.dart"
            path.write_text("dio.get(dynamicPath); dio.post('/records', data: {'quantity': q});", encoding="utf-8")
            calls = dart_calls(path, root)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]["keys"], ["quantity"])

    def test_dio_request_helper_preserves_literal_routes_without_inventing_dynamic_calls(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'repository.dart'
            path.write_text("Future call() => dio.request(path);\n"
                            "load() => _request('GET', '/api/v1/me/activity', decode);\n"
                            "command(id) => _request('POST', '/api/v1/me/activity-sessions/${Uri.encodeComponent(id)}/commands', decode);\n"
                            "dynamic() => _request(method, path);", encoding='utf-8')
            calls = dart_calls(path, root)
            self.assertEqual([(c['method'], normalized(c['path'])) for c in calls],
                             [('GET', '/api/v1/me/activity'),
                              ('POST', '/api/v1/me/activity-sessions/:param/commands')])
            path.write_text("load() => _request('GET', '/not-an-http-helper');", encoding='utf-8')
            self.assertEqual(dart_calls(path, root), [])

    def test_go_comment_registration_and_specification_are_separate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            code = root / "services/api/main.go"
            code.parent.mkdir(parents=True)
            code.write_text('// @Param limit query int false "limit"\n// @Success 200 {object} Result\n// @Router /api/v1/items [get]\nfunc List() {}\nfunc main() { mux.HandleFunc("GET /api/v1/items", List); mux.HandleFunc(dynamic, Other) }', encoding="utf-8")
            inventory = go_inventory(root)
            self.assertEqual(len(inventory["annotations"]), 1)
            self.assertTrue(inventory["annotations"][0]["registrationDetected"])
            self.assertEqual(len(inventory["registrations"]), 1)
            self.assertEqual(inventory["specificationOperations"], [])
            spec = root / "contracts/generated/swagger-v1.json"
            spec.parent.mkdir(parents=True)
            spec.write_text(json.dumps({"swagger": "2.0", "basePath": "/api/v1", "paths": {"/items": {"get": {"parameters": [{"name": "limit", "in": "query"}], "responses": {"200": {"description": "ok"}}}}}}), encoding="utf-8")
            operation = go_inventory(root)["specificationOperations"][0]
            self.assertEqual(operation["path"], "/api/v1/items")
            self.assertIn("200", operation["responses"])
            code.write_text('// @Router /api/v1/never-registered [post]\nfunc Draft() {}', encoding="utf-8")
            self.assertFalse(go_inventory(root)["annotations"][0]["registrationDetected"])

    def test_absent_go_does_not_install_tools_or_fabricate_swagger(self):
        with tempfile.TemporaryDirectory() as directory, patch("gerar_swagger.shutil.which", side_effect=AssertionError("Não procurar ferramenta sem Go")):
            root = Path(directory)
            self.assertIn("PENDENTE V1-008", generate(root))
            self.assertFalse((root / "contracts").exists())

    def test_missing_swag_fails_actionably_when_go_exists(self):
        with tempfile.TemporaryDirectory() as directory, patch("gerar_swagger.shutil.which", return_value=None):
            root = Path(directory)
            (root / "services/api/cmd/api").mkdir(parents=True)
            (root / "services/api/go.mod").write_text("module example.test/fixture\n", encoding="utf-8")
            (root / "services/api/cmd/api/main.go").write_text("package main\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "v1.16.6"):
                generate(root)

    def test_specification_without_go_cannot_be_presented_as_validated(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "contracts/generated").mkdir(parents=True)
            (root / "contracts/generated/swagger-v1.json").write_text('{}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "sem serviço Go"):
                generate(root)

    def test_cycles_and_done_without_evidence_are_rejected(self):
        backlog = json.loads((ROOT / "docs/execucao/v1/backlog.json").read_text(encoding="utf-8"))
        plan = json.loads((ROOT / "docs/arquitetura/plano.json").read_text(encoding="utf-8"))
        bad = copy.deepcopy(backlog)
        story = bad["epics"][0]["stories"][0]
        story["dependsOn"] = [story["id"]]
        story["status"] = "done"
        story["completionEvidence"] = []  # O caso negativo independe do progresso real.
        errors = validate(bad, plan, ROOT)
        self.assertTrue(any("cíclica" in e for e in errors))
        self.assertTrue(any("sem evidência" in e for e in errors))

    def test_broken_relative_link_fails_but_code_sample_is_not_a_link(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "readme.md").write_text("[broken](missing.md)\n```text\n[example](example.md)\n```", encoding="utf-8")
            self.assertEqual(check_links(root, ["readme.md"]), ["readme.md → missing.md"])

    def test_checked_in_files_match_generator_and_no_panel_output(self):
        expected, _ = outputs(ROOT)
        for relative, text in expected.items():
            self.assertTrue((ROOT / relative).exists(), relative)
            self.assertEqual((ROOT / relative).read_text(encoding="utf-8-sig"), text, relative)
            self.assertNotIn("docs/painel", relative)
        self.assertFalse((ROOT / "tools/painel_projeto.py").exists())
        self.assertFalse((ROOT / "tools/abrir-painel.ps1").exists())

    def test_relative_heading_and_explicit_anchors_are_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'guide.md').write_text('# Guia\n<a id="exact"></a>\n## Ação real\n'
                '[valid](#ação-real) [explicit](#exact) [broken](#missing)\n'
                '~~~text\n[example](absent.md)\n~~~', encoding='utf-8')
            self.assertEqual(check_links(root, ['guide.md']), ['guide.md → #missing'])

    def test_archive_locator_must_name_a_preserved_member(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with zipfile.ZipFile(root / 'research.zip', 'w') as bundle:
                bundle.writestr('docs/original.json', '{"fixtureOnly":true}')
            (root / 'guide.md').write_text('[source](research.zip#docs/original.json) '
                '[missing](research.zip#docs/missing.json)', encoding='utf-8')
            self.assertEqual(check_links(root, ['guide.md']), ['guide.md → research.zip#docs/missing.json'])


if __name__ == "__main__":
    unittest.main()
