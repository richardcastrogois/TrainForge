"""Extrai a progressao humana N15 e confere o redirecionamento NHS, sem rede."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n15-casa-sem-equipamento'


class Tables(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables = []
        self.table = None
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            assert self.table is None, 'Nested table needs separate handling'
            self.table = []
        elif self.table is not None and tag == 'tr':
            self.row = []
        elif self.row is not None and tag in ('td', 'th'):
            self.cell = []
        elif self.cell is not None and tag == 'br':
            self.cell.append(' ')

    def handle_data(self, text):
        if self.cell is not None:
            self.cell.append(text)

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.cell is not None:
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        elif tag == 'tr' and self.row is not None:
            self.table.append(self.row)
            self.row = None
        elif tag == 'table' and self.table is not None:
            self.tables.append(self.table)
            self.table = None


def read(ident):
    path = FOLDER / (ident + '.evidencia.json')
    record = json.loads(path.read_text(encoding='utf-8'))
    body = (FOLDER / record['bodyFile']).resolve()
    body.relative_to(ROOT)
    payload = body.read_bytes()
    assert record['status'] == 200 and len(payload) == record['bytes']
    assert hashlib.sha256(payload).hexdigest() == record['sha256']
    return record, payload.decode('utf-8')


article_record, article = read('n15-oec-bodyweight')
redirect_record, redirected = read('n15-nhs-strength-flex')
parser = Tables()
parser.feed(article)
tables = [table for table in parser.tables if table and table[0][:2] == ['Lesson', 'Exercise']]
assert len(tables) == 1
rows = tables[0][1:]
expected_reps = [8, 8, 10, 10, 10, 10, 10, 15, 15, 15, 15, 15]
expected_sets = [2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3]
expected_rests = [60, 60, 60, 60, 45, 45, 45, 45, 45, 30, 30, 30]
assert len(rows) == 12
lessons = []
for i, row in enumerate(rows):
    assert len(row) == 6 and int(row[0]) == i + 3, row
    assert int(row[2]) == expected_reps[i]
    assert int(row[4]) == expected_sets[i]
    assert int(row[5]) == expected_rests[i]
    assert row[3] in ('3–3', '3-3')
    lessons.append({'lesson': int(row[0]), 'exerciseCodes': row[1].split(', '),
                    'repetitions': int(row[2]), 'sets': int(row[4]),
                    'concentricSeconds': 3, 'eccentricSeconds': 3, 'restSeconds': int(row[5])})
assert 'creativecommons.org/licenses/by/4.0/' in article
assert 'approved by a physician' in article
assert 'Healthcare (Basel)' in article
assert '10.3390/healthcare13233091' in article
assert 'fracture within six months' in article
assert redirect_record['resolvedUrl'] == 'https://www.nhs.uk/live-well/exercise/'

content = {'niche': 'N15', 'date': '2026-10-03', 'status': 'parcial',
           'researchRoundComplete': True,
           'program': {'sourceId': 'PR13', 'sourceUrl': article_record['url'],
                       'sha256': article_record['sha256'], 'publicationDate': '2025-11-27',
                       'journal': 'Healthcare (Basel)', 'doi': '10.3390/healthcare13233091',
                       'author': 'Zhenyue Liu e colaboradores', 'license': 'CC BY 4.0',
                       'audience': 'adultos mais velhos residentes na comunidade; oito participantes analisados',
                       'eligibility': 'residentes na comunidade, sem historico cardiovascular, fratura nos ultimos seis meses ou disturbio de movimento; sem treino regular de resistencia ha pelo menos um ano; aprovacao medica',
                       'eligibilityIsValidatedAppScreening': False,
                       'caregiverWorkflowDemonstrated': False,
                       'setting': 'casa; aulas online supervisionadas', 'equipment': ['cadeira aproximadamente 40 cm', 'dispositivo com camera/audio para supervisao'],
                       'specialResistanceEquipment': False, 'weeks': 7, 'lessonsPerWeek': 2,
                       'introductoryLessons': [1, 2], 'trainingLessons': lessons,
                       'exerciseNames': {'SQ': 'squat', 'SSQ': 'split squat, por lado', 'SP': 'shoulder press', 'CSAC': 'chair-seated abdominal curl'},
                       'releaseApproved': False},
           'nhsAvailability': {'requestedUrl': redirect_record['url'], 'resolvedUrl': redirect_record['resolvedUrl'],
                               'httpStatus': 200, 'fullFiveWeekPlanObtained': False},
           'limits': ['Publico e supervisao nao equivalem a programa geral autonomo',
                      'Primeiras duas aulas sem dose formal na tabela', 'Aquecimento/desaceleracao e videos completos nao obtidos',
                      'Cadeira e equipamento domestico; nao chamar literalmente de zero objetos',
                      'NHS piloto inclui pesos e nao preenche este programa completo',
                      'Revisao pt-PT, ativos e adequacao pendentes']}
summary = {'niche': 'N15', 'date': '2026-10-03', 'status': 'parcial', 'researchRoundComplete': True,
           'calls': 2, 'http200': 2, 'bodyHashes': 2, 'usableProgramBodies': 1,
           'trainingLessonsStructured': 12, 'exerciseTypes': 4,
           'nhsRedirectIsProgram': False, 'releaseApproved': False,
           'next': 'N16 — casa com material disponivel'}
for name, value in [('amostra-programas.json', content), ('resumo-programas.json', summary)]:
    (FOLDER / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
