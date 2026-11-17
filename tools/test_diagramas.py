import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

import gerar_diagramas as diagrams


class ReviewedDiagrams(unittest.TestCase):
    def test_generated_files_are_current_and_have_valid_references(self):
        generated = diagrams.outputs()
        maps = json.loads((diagrams.DIRECTORY/'mapas.json').read_text(encoding='utf-8'))['diagrams']
        self.assertEqual({p.stem for p in generated if p.suffix == '.svg'}, {d['id'] for d in maps})
        editable = [p for p in diagrams.DIRECTORY.glob('*.drawio')]
        self.assertEqual([p.name for p in editable], ['trainforge.drawio'])
        for path, value in generated.items():
            with self.subTest(file=path.name):
                self.assertEqual(path.read_text(encoding='utf-8'), value)
                if path.suffix not in {'.drawio', '.svg'}:
                    continue
                root = ET.fromstring(value)
                if path.suffix != '.drawio':
                    continue
                pages = root.findall('diagram')
                self.assertEqual([p.attrib['id'] for p in pages], [d['id'] for d in maps])
                self.assertEqual([p.attrib['name'] for p in pages], [d['title'] for d in maps])
                for page in pages:
                    # draw.io starts a new graph with roots 0/1 on each page.
                    cells = page.findall('.//mxCell')
                    ids = [cell.attrib['id'] for cell in cells]
                    self.assertEqual(len(ids), len(set(ids)))
                    self.assertEqual(ids[:2], ['0', '1'])
                    for cell in cells:
                        if 'parent' in cell.attrib:
                            self.assertIn(cell.attrib['parent'], ids)
                        if cell.attrib.get('edge') == '1':
                            self.assertIn(cell.attrib['source'], ids)
                            self.assertIn(cell.attrib['target'], ids)
                        if cell.attrib.get('vertex') == '1':
                            self.assertIsNotNone(cell.find('mxGeometry'))

    def test_api_index_tracks_specification_without_inventing_operations(self):
        spec = {'info': {'version': 'fixture'}, 'basePath': '/api/v1', 'paths': {
            '/public': {'parameters': [], 'get': {'tags': ['catalog']}},
            '/me/private': {'post': {'tags': ['private'], 'security': [{'BearerAuth': []}]}}
        }}
        rendered = diagrams.api_markdown(spec)
        self.assertIn('**2 operações**', rendered)
        self.assertIn('| GET | /api/v1/public | catalog | Pública |', rendered)
        self.assertIn('| POST | /api/v1/me/private | private | Bearer / titular |', rendered)
        del spec['paths']['/public']
        self.assertNotIn('| GET | /api/v1/public |', diagrams.api_markdown(spec))

    def test_database_maps_cover_real_tables_and_only_real_foreign_keys(self):
        source = json.loads((diagrams.DIRECTORY/'schema-publico.json').read_text(encoding='utf-8'))
        maps = json.loads((diagrams.DIRECTORY/'mapas.json').read_text(encoding='utf-8'))['diagrams']
        core = source['databases']['trainforge_v1_dev']
        catalog = source['databases']['trainforge_catalog_dev']
        self.assertEqual(len(core['tables']), 30)
        self.assertEqual(len(catalog['tables']), 4)
        actual = {(k['table'], k['target']) for k in core['constraints'] if k['type'] == 'f'}
        covered = set()
        for diagram in maps:
            if diagram['id'].startswith(('11-', '12-', '13-', '14-')):
                covered.update(n['id'] for n in diagram['nodes'])
                for edge in diagram['edges']:
                    self.assertIn((edge['from'], edge['to']), actual)
        self.assertEqual(covered, {t['name'] for t in core['tables']})
        self.assertEqual(source['scope'], 'schema-metadata-only-no-rows')


if __name__ == '__main__':
    unittest.main()
