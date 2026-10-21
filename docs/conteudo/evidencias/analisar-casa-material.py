"""Confere manual Tufts/CDC e projecao factual N16, sem rede."""
import hashlib
import json
from pathlib import Path
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-10-03/n16-casa-material'
record = json.loads((FOLDER / 'n16-growing-stronger.evidencia.json').read_text(encoding='utf-8'))
body = (FOLDER / record['bodyFile']).resolve()
body.relative_to(ROOT)
payload = body.read_bytes()
assert record['status'] == 200 and len(payload) == record['bytes']
assert hashlib.sha256(payload).hexdigest() == record['sha256']
reader = PdfReader(body)
assert len(reader.pages) == 126
texts = [' '.join(page.extract_text().split()) for page in reader.pages]
assert 'do not change any of the content' in texts[3]
assert '2002 by Tufts University' in texts[3]
assert 'Weeks 1' in texts[43] and 'Weeks 3' in texts[43] and 'Weeks 7' in texts[43]
assert 'AT LEAST 4 WEEKS' in texts[63]
names = ['Squats', 'Wall push-ups', 'Toe stands', 'Finger marching', 'Biceps curl',
         'Step-ups', 'Overhead press', 'Side hip raise', 'Knee extension', 'Knee curl',
         'Pelvic tilt', 'Floor back extension']
pages = [[47, 48], [49, 50], [51, 52], [53, 54], [57, 58], [59, 60],
         [61, 62], [63, 64], [65, 66], [67, 68], [69, 70], [71]]
equipment = [['chair'], ['wall'], ['chair_or_counter'], ['chair_optional'],
             ['dumbbells', 'chair_optional'], ['stairs_with_handrail'],
             ['dumbbells', 'chair_optional'], ['chair', 'ankle_weights_optional'],
             ['chair', 'ankle_weights'], ['chair', 'ankle_weights'], ['floor_or_firm_mattress'], ['floor']]
movements = []
for i, (name, loc, kit) in enumerate(zip(names, pages, equipment), start=1):
    text = ' '.join(texts[p-1] for p in loc)
    assert 'EXERCISE' in text
    if i != 4:
        assert 'second set' in text.lower(), (i, loc)
    movements.append({'exerciseNumber': i, 'sourceName': name, 'pdfPages': loc,
                      'equipment': kit, 'sets': None if i == 4 else 2,
                      'repetitionsPerSet': None if i == 4 else 10,
                      'perSide': i in [6, 8, 9, 10, 12],
                      'restSecondsRange': None if i == 4 else ([60, 60] if i < 9 else [60, 120]),
                      'specialDose': {'sequenceRepeats': 3, 'holdSecondsApprox': 10, 'positions': 3} if i == 4 else None,
                      'doseIsSourceFactNotPrescription': True})
assert 'Repeat the exercise 3 times' in texts[53]
assert '5 minutes' in texts[45]
program = {'niche': 'N16', 'date': '2026-10-03', 'status': 'parcial', 'researchRoundComplete': True,
           'sourceId': 'PR11', 'sourceUrl': record['url'], 'sha256': record['sha256'],
           'title': 'Growing Stronger: Strength Training for Older Adults',
           'author': 'Rebecca A. Seguin e colaboradores; Tufts University',
           'copyrightYear': 2002, 'clinicalReviewDate': None, 'pdfPageCount': 126,
           'audience': 'adultos mais velhos; nao equivaler a todos os adultos ou todas as condicoes clinicas',
           'sessionsPerWeekRange': [2, 3], 'sessionDurationMinutes': None,
           'phases': [{'phase': 1, 'startWeek': 1, 'endWeek': 2, 'exerciseNumbers': [1, 2, 3, 4]},
                      {'phase': 2, 'startWeek': 3, 'endWeek': 6, 'exerciseNumbers': [5, 6, 7, 8]},
                      {'phase': 3, 'startWeek': 7, 'endWeek': None, 'exerciseNumbers': [9, 10, 11, 12]}],
           'phaseTransitionConflict': {'pdfPage44': 'duas semanas parte I e quatro semanas parte II',
                                      'pdfPage64': 'partes I e II pelo menos quatro semanas; criterio difere',
                                      'automaticTransitionApproved': False},
           'warmupMinutes': 5, 'warmupMode': 'walking or source alternatives',
           'movements': movements,
           'progressionEvidencePages': [57, 82, 83, 84],
           'progression': 'avaliar execucao e esforco antes de aumentar; nao aumentar doente, lesionado ou muito dolorido',
           'weightUnit': 'lb', 'automaticWeightTargetApproved': False,
           'substitutions': 'somente alternativas expressas pela fonte; nao gerar equivalencias livres',
           'rights': 'distribuicao gratuita creditada sem alterar; ilustracoes e PAR-Q de terceiros; adaptacao pt-PT nao demonstrada',
           'releaseApproved': False,
           'limits': ['Kit cadeira/parede/degrau/halteres/caneleiras; nao cobre bandas/kettlebell universalmente',
                      'Manual historico; revisao de atualidade, linguagem e seguranca pendente',
                      'Nao importar afirmacoes terapeuticas como garantia',
                      'Videos e revisao pt-PT pendentes; N17 separado',
                      'Artigo alternativo teve reCAPTCHA e 429; nao contornar ou repetir']}
summary = {'niche': 'N16', 'date': '2026-10-03', 'status': 'parcial', 'researchRoundComplete': True,
           'calls': 1, 'http200': 1, 'bodyHashes': 1, 'programsObtained': 1, 'phases': 3,
           'movements': 12, 'phaseTransitionConflict': True, 'releaseApproved': False,
           'next': 'N17 - instrucao visual em casa'}
for name, value in [('amostra-programas.json', program), ('resumo-programas.json', summary)]:
    (FOLDER / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False))
