import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

import gerar_diagramas as diagrams


class ReviewedDiagrams(unittest.TestCase):
    def test_generated_files_are_current_and_have_valid_references(self):
        generated = diagrams.outputs()
        self.assertEqual(len(generated), 30)
        for path, value in generated.items():
            with self.subTest(file=path.name):
                self.assertEqual(path.read_text(encoding='utf-8'), value)
                root = ET.fromstring(value)
                if path.suffix != '.drawio':
                    continue
                cells = root.findall('.//mxCell')
                ids = [cell.attrib['id'] for cell in cells]
                self.assertEqual(len(ids), len(set(ids)))
                self.assertTrue({'0', '1'} <= set(ids))
                for cell in cells:
                    if 'parent' in cell.attrib:
                        self.assertIn(cell.attrib['parent'], ids)
                    if cell.attrib.get('edge') == '1':
                        self.assertIn(cell.attrib['source'], ids)
                        self.assertIn(cell.attrib['target'], ids)
                    if cell.attrib.get('vertex') == '1':
                        self.assertIsNotNone(cell.find('mxGeometry'))

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
