"""Catalog generation must stay public when new private domains are added."""
import copy
import json
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch

import gerar_catalogo_m1_swagger as catalog


def public_contract():
    return {
        'paths': {path: {'get': {'responses': {'200': {'description': 'fixture'}}}}
                  for path in sorted(catalog.PATHS)},
        'definitions': {'catalog.Program': {'type': 'object'}}
    }


class CatalogSwaggerTests(unittest.TestCase):
    def test_new_private_modules_cannot_enter_the_public_scan(self):
        reference = public_contract()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            service = root/'services/api'
            sources = {
                'cmd/catalog/main.go': 'package main\n',
                'internal/catalog/handler.go': '\n'.join(
                    '// @Router '+path+' [get]' for path in sorted(catalog.PATHS) if '/catalog/' in path),
                'internal/platform/httpapi/health.go': '\n'.join(
                    '// @Router '+path+' [get]' for path in sorted(catalog.PATHS) if '/health/' in path),
                'internal/activity/handler.go': '// @Router /api/v1/me/activity [get]\n',
                'internal/anotherprivate/handler.go': '// @Router /api/v1/me/future-private [post]\n',
            }
            for relative, content in sources.items():
                path = service/relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding='utf-8')
            spec = root/'contracts/generated/swagger-v1.json'
            spec.parent.mkdir(parents=True)
            spec.write_text(json.dumps(reference), encoding='utf-8')

            def scoped_swag(command, *, cwd, check):
                """Stand-in scans @Router only in the directories passed to Swag."""
                self.assertTrue(check)
                search = command[command.index('--dir')+1].split(',')
                general = command[command.index('--generalInfo')+1]
                self.assertTrue((cwd/search[0]/general).is_file())
                excludes = (command[command.index('--exclude')+1].split(',')
                            if '--exclude' in command else [])
                document = {'paths': {}, 'definitions': reference['definitions']}
                for base in search:
                    for path in sorted((cwd/base).rglob('*.go')):
                        relative = path.relative_to(cwd).as_posix()
                        if any(relative == e or relative.startswith(e+'/') for e in excludes):
                            continue
                        for route, method in re.findall(r'@Router\s+(\S+)\s+\[(\w+)\]', path.read_text(encoding='utf-8')):
                            document['paths'][route] = copy.deepcopy(reference['paths'].get(
                                route, {method: {'responses': {'200': {'description': 'private fixture'}}}}))
                output = Path(command[command.index('--output')+1])
                (output/'swagger.json').write_text(json.dumps(document, sort_keys=True), encoding='utf-8')
                (output/'swagger.yaml').write_text('fixtureOnly: true\n', encoding='utf-8')

            with patch.object(catalog.shutil, 'which', return_value='fixture-swag'), \
                 patch.object(catalog.subprocess, 'check_output', return_value='mod github.com/swaggo/swag v1.16.6'), \
                 patch.object(catalog.subprocess, 'run', side_effect=scoped_swag):
                catalog.generate(root, write=True)
                catalog.generate(root)
            generated = json.loads((root/catalog.TARGETS['swagger.json']).read_text(encoding='utf-8'))
            self.assertEqual(set(generated['paths']), catalog.PATHS)
            self.assertFalse(any('/me/' in path for path in generated['paths']))

    def test_public_guard_rejects_private_paths_security_and_schema_changes(self):
        reference = public_contract()
        private_path = copy.deepcopy(reference)
        private_path['paths']['/api/v1/me/activity'] = {'get': {}}
        global_auth = copy.deepcopy(reference)
        global_auth['securityDefinitions'] = {'BearerAuth': {'type': 'apiKey'}}
        changed_operation = copy.deepcopy(reference)
        changed_operation['paths'][sorted(catalog.PATHS)[0]]['get']['summary'] = 'changed'
        private_schema = copy.deepcopy(reference)
        private_schema['definitions']['activity.Session'] = {'type': 'object'}
        changed_schema = copy.deepcopy(reference)
        changed_schema['definitions']['catalog.Program']['type'] = 'string'
        for document in [private_path, global_auth, changed_operation, private_schema, changed_schema]:
            with self.subTest(document=document), self.assertRaises(ValueError):
                catalog.validate_contract(reference, document)
        catalog.validate_contract(reference, reference)


if __name__ == '__main__':
    unittest.main()
