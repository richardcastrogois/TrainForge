"""Gym research projection tests, not exercise or app validation."""
import importlib.util
from pathlib import Path
import unittest

PATH = Path(__file__).with_name('analisar-tabela-academia.py')
SPEC = importlib.util.spec_from_file_location('gym_table', PATH)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GymTableTests(unittest.TestCase):
    def test_blank_dose_is_not_inherited(self):
        html = '<table><tr>'+('<th>h</th>'*9)+'</tr>'
        for cells in [('1-2','endurance','1','press','3','14-16','40-60%','2:2','60 s'),
                      ('','','','extension','2','14-16','','','')]:
            html += '<tr>'+''.join('<td>'+v+'</td>' for v in cells)+'</tr>'
        rows = MODULE.project(html+'</table>')
        self.assertEqual(rows[1]['editorialGroupContext']['session'], '1')
        for key in ('percent1RM','tempo','interSetRest'):
            self.assertIsNone(rows[1]['sourceCells'][key])

    def test_reject_missing_context_or_columns(self):
        for cells in [('','','','extension','2','14-16','','',''), ('1-2','endurance')]:
            with self.subTest(cells=cells), self.assertRaises(ValueError):
                MODULE.project('<table><tr>'+('<th>h</th>'*9)+'</tr><tr>'+''.join('<td>'+v+'</td>' for v in cells)+'</tr></table>')


if __name__ == '__main__':
    unittest.main()
