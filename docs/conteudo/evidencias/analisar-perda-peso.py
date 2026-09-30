"""Analisa o recorte N10 sem rede; requer corpos locais preservados.

Valida respostas, politicas especificas, estrutura de titulos e a tabela didatica
NIDDK com rowspan. Nao calcula metas de dieta nem gera programa individual.
"""
from pathlib import Path
from html.parser import HTMLParser
from decimal import Decimal
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent
FOLDER = ROOT / '2026-09-30/n10-perda-peso'
CHECKS = []


def verify(name, value):
    if not value:
        raise AssertionError(name)
    CHECKS.append({'check': name, 'passed': True})


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.skip = 0
        self.text = []
        self.headings = []
        self.heading = None
        self.links = []
        self.tables = []
        self.table = None
        self.row = None
        self.cell = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ('script', 'style', 'noscript'):
            self.skip += 1
        if tag in ('h1', 'h2', 'h3'):
            self.heading = {'tag': tag, 'text': ''}
        if tag == 'a':
            self.links.append(attrs.get('href', ''))
        if tag == 'table':
            self.table = []
        if self.table is not None and tag == 'tr':
            self.row = []
        if self.row is not None and tag in ('td', 'th'):
            self.cell = {'text': '', 'rowspan': int(attrs.get('rowspan', 1)),
                         'colspan': int(attrs.get('colspan', 1))}

    def handle_data(self, text):
        if not self.skip:
            self.text.append(text)
        if self.heading is not None:
            self.heading['text'] += text
        if self.cell is not None:
            self.cell['text'] += text

    def handle_endtag(self, tag):
        if tag in ('script', 'style', 'noscript'):
            self.skip = max(0, self.skip - 1)
        if self.heading is not None and tag == self.heading['tag']:
            self.heading['text'] = clean(self.heading['text'])
            self.headings.append(self.heading)
            self.heading = None
        if self.cell is not None and tag in ('td', 'th'):
            self.cell['text'] = clean(self.cell['text'])
            self.row.append(self.cell)
            self.cell = None
        if tag == 'tr' and self.row is not None:
            self.table.append(self.row)
            self.row = None
        if tag == 'table' and self.table is not None:
            self.tables.append(self.table)
            self.table = None

    @property
    def plain(self):
        return clean(' '.join(self.text))

    @property
    def title(self):
        return next(x['text'] for x in self.headings if x['tag'] == 'h1')


def clean(text):
    return re.sub(r'\s+', ' ', text).strip()


def load_page(path):
    meta = json.loads(path.read_text(encoding='utf-8-sig'))
    body = (path.parent / meta['bodyFile']).resolve()
    body.relative_to(ROOT)
    data = body.read_bytes()
    verify(meta['id'] + ': original body hash', hashlib.sha256(data).hexdigest() == meta['sha256'])
    parser = Page()
    parser.feed(data.decode('utf-8'))
    return meta, parser


def expand_rows(rows):
    """Propaga apenas celulas que a propria fonte declarou com rowspan/colspan."""
    pending = {}
    result = []
    for row in rows:
        current = {i: text for i, (text, _) in pending.items()}
        pending = {i: (text, left - 1) for i, (text, left) in pending.items() if left > 1}
        col = 0
        for cell in row:
            while col in current:
                col += 1
            for offset in range(cell['colspan']):
                pos = col + offset
                current[pos] = cell['text']
                if cell['rowspan'] > 1:
                    pending[pos] = (cell['text'], cell['rowspan'] - 1)
            col += cell['colspan']
        result.append([current.get(i, '') for i in range(max(current) + 1)])
    return result


def main():
    evidence, pages = {}, {}
    for path in sorted(FOLDER.glob('*.evidencia.json')):
        meta, page = load_page(path)
        evidence[meta['id']], pages[meta['id']] = meta, page
    verify('10 independent attempts retained', len(evidence) == 10)
    verify('nine HTTP 200 and one original 404', sum(x['status'] == 200 for x in evidence.values()) == 9 and evidence['n10-niddk-porcoes']['status'] == 404)
    verify('canonical portion URL actually linked by source', '/health-information/weight-management/just-enough-food-portions' in pages['n10-niddk-programa'].links)
    for ident in ['n10-nhs-perda', 'n10-cdc-passos', 'n10-niddk-programa', 'n10-niddk-porcoes-canonico']:
        verify(ident + ': usable HTML guide, not failed request', evidence[ident]['status'] == 200 and 'text/html' in evidence[ident]['contentType'] and bool(pages[ident].title))

    nhs = pages['n10-nhs-perda'].plain
    cdc = pages['n10-cdc-passos'].plain
    program = pages['n10-niddk-programa'].plain
    portion = pages['n10-niddk-porcoes-canonico'].plain
    verify('NHS: published weekly range is general context', '0.5 to 1kg' in nhs and 'do not lose weight suddenly' in nhs)
    verify('NHS: displayed review dates preserved', '17 March 2023' in nhs and '17 March 2026' in nhs)
    steps = [x for x in pages['n10-cdc-passos'].headings if x['tag'] == 'h2' and re.match(r'Step [1-5]:', x['text'])]
    verify('CDC: exactly five numbered steps in order', [int(x['text'][5]) for x in steps] == [1, 2, 3, 4, 5])
    verify('CDC: attainable behaviors plus setback support', 'two or three goals' in cdc and 'occasional setbacks' in cdc)
    verify('CDC: date and broader context retained', 'January 17, 2025' in cdc and 'medicines' in cdc and 'sleep' in cdc)
    verify('NIDDK: support and maintenance part of real programs', all(s in program for s in ['ongoing guidance and support', 'A plan for keeping the weight off', 'trained professional']))
    verify('NIDDK: regional-loss claim rejected', 'Lose weight in a specific part of your body!' in program)
    verify('NIDDK: institutional review and named acknowledgement', 'carefully reviewed by NIDDK scientists' in program and 'Samuel Klein' in program and 'February 2024' in program)
    verify('NIDDK portions: source serving is not individual recommendation', 'serving size on a label is not a recommendation' in portion)
    verify('NIDDK portions: older version and named acknowledgement', 'July 2021' in portion and 'Carla Miller' in portion)
    verify('NIDDK: illustrative 280 times two equals 560', '280' in portion and '560' in portion and 'two servings' in portion)

    tables = pages['n10-niddk-porcoes-canonico'].tables
    raw_table = next(t for t in tables if [c['text'] for c in t[0]] == ['Time', 'Food', 'Amount', 'Estimated Calories', 'Place', 'Hunger/Reason'])
    table = expand_rows(raw_table)
    body = table[1:-1]
    verify('Diary: 13 food rows and six real columns', len(body) == 13 and all(len(row) == 6 for row in body))
    values = [int(row[3]) for row in body]
    declared_total = int(table[-1][-1].replace(',', ''))
    verify('Diary: extracted calories sum to source total 2916', sum(values) == declared_total == 2916)
    verify('Diary: empty sandwich amount retained', body[3][1] == 'Grilled cheese sandwich' and body[3][2] == '')
    verify('Diary: rowspan time and place resolved for breakfast', all(row[0] == '8 a.m.' and row[4] == 'Home' for row in body[:3]))
    verify('Diary: zero calorie water not confused with missing data', body[6][1] == 'Water' and body[6][3] == '0')
    verify('Diary: restaurant context spans five rows', len({tuple((row[0], row[4], row[5])) for row in body[8:]}) == 1)

    reuse = []
    for ident in ['n08-nhs-termos', 'n08-nhs-excecoes', 'n08-ogl-v3']:
        path = ROOT / '2026-09-29/n08-receitas' / (ident + '.evidencia.json')
        meta, page = load_page(path)
        reuse.append({'file': path.relative_to(ROOT).as_posix(), 'sha256': meta['sha256'], 'status': meta['status']})
        if ident == 'n08-nhs-termos':
            verify('NHS: general OGL terms retained with adaptation conditions', 'Open Government Licence' in page.plain and 'translation' in page.plain.lower())
    bh_terms = pages['n10-better-health-termos'].plain
    bh_app = pages['n10-better-health-app-termos'].plain
    cdc_rights = pages['n10-cdc-direitos'].plain
    ni_rights = pages['n10-niddk-direitos'].plain
    verify('Better Health: commercial licence explicitly required', 'commercial purposes without obtaining a licence' in bh_terms)
    verify('Better Health: personal download does not allow alteration', 'must not modify' in bh_terms and 'personal use' in bh_terms)
    verify('Better Health app: separate personal-purpose licence', 'personal purposes only' in bh_app and 'not to rent, lease, sub-license, loan, translate, merge, adapt' in bh_app)
    verify('Better Health: advertised 12 weeks is not actual imported program', '12-week' in pages['n10-better-health'].plain)
    verify('Better Health: specific clinical context retained', all(s in pages['n10-better-health'].plain for s in ['eating disorder', 'special diet', 'healthcare professional']))
    verify('CDC: public-domain text has substantive-change restriction', 'public domain' in cdc_rights and 'may not change the substantive content' in cdc_rights)
    verify('CDC: credit, no endorsement, free origin and jurisdiction limits', all(s in cdc_rights for s in ['Attribution', 'does not imply endorsement', 'for no charge', 'copyright laws also differ internationally']))
    verify('NIDDK: free reproduction but third-party exception', 'freely downloaded and reproduced' in ni_rights and 'third party' in ni_rights)
    verify('NIDDK: edited content no logos/endorsement or medical recommendation', all(s in ni_rights for s in ['logos must be removed', 'imply endorsement', 'specific medical advice']))

    old_path = ROOT / '2026-09-26/network/nhs-c25k.evidencia.json'
    old = json.loads(old_path.read_text(encoding='utf-8-sig'))
    old_body = (old_path.parent / old['bodyFile']).read_bytes()
    verify('PR06: prior running body hash', hashlib.sha256(old_body).hexdigest() == old['sha256'])
    verify('PR06: original page links specific Better Health terms', '/better-health/terms-and-conditions/' in old_body.decode('utf-8'))
    reuse.append({'file': old_path.relative_to(ROOT).as_posix(), 'sha256': old['sha256'], 'status': old['status']})

    guide_specs = [
        ('G10-01', 'NU21', 'n10-nhs-perda', 'NHS', '2023-03-17', 'Texto geral candidato OGL + termos; traducao revisada, sem campanhas/calculadora/imagens', 'adultos; orientacao geral, nao meta individual'),
        ('G10-02', 'NU22', 'n10-cdc-passos', 'CDC / NCCDPHP', '2025-01-17', 'Condicional para versao adaptada pt-PT: nao alterar conteudo substantivo; credito, nao endosso, origem gratuita e direitos territoriais', 'educacao geral para adultos; fatores individuais interferem'),
        ('G10-03', 'NU23', 'n10-niddk-programa', 'NIDDK', '2024-02', 'Texto candidato segundo politica; excluir imagens/terceiros e nao usar como aconselhamento medico especifico', 'adultos avaliando programas e apoio; nao prova eficacia do TrainForge'),
        ('G10-04', 'NU23', 'n10-niddk-porcoes-canonico', 'NIDDK', '2021-07', 'Texto candidato; exemplos EUA exigem revisao pt-PT e fiscalizacao das referencias antigas', 'educacao sobre quantidades e contexto; diario ilustrativo nao e dieta')
    ]
    guides = []
    for gid, sid, ident, publisher, date, rights, audience in guide_specs:
        guides.append({'id': gid, 'sourceId': sid, 'title': pages[ident].title, 'publisher': publisher,
            'sourceUrl': evidence[ident]['url'], 'evidence': ident + '.evidencia.json',
            'sha256': evidence[ident]['sha256'], 'format': 'HTML institucional; nao API de dieta',
            'sourceDate': date, 'audience': audience, 'reuseDecision': rights,
            'individualEnergyTargetKcal': None, 'individualWeightLossTargetKg': None,
            'releaseApproved': False})
    lessons = [
        ('L01', 'Escolher um percurso adequado', 'O objetivo declarado nao determina sozinho a necessidade de perder peso.', ['G10-01', 'G10-03'], ['goalIntent', 'supportContextOptional']),
        ('L02', 'Observar a rotina com contexto', 'Alimentos, quantidades e contexto do registo ajudam a identificar escolhas a rever.', ['G10-02', 'G10-04'], ['mealItems', 'amount', 'unit', 'time', 'contextOptional']),
        ('L03', 'Distinguir rotulo e consumo', 'Duas porcoes consumidas exigem duas vezes os valores por porcao; o rotulo nao prescreve a quantidade.', ['G10-04'], ['nutritionBasis', 'servingCount', 'actualIntake']),
        ('L04', 'Comparar escolhas simples', 'O guia geral permite explicar trocas de bebidas e leitura de rotulos, com quantidades confirmadas.', ['G10-01'], ['foodId', 'quantity', 'labelEvidence']),
        ('L05', 'Escolher pequenas acoes praticaveis', 'Definir comportamentos claros e rever dificuldades; a balanca nao e o unico registo util.', ['G10-02'], ['userChosenAction', 'frequency', 'barriersOptional']),
        ('L06', 'Reconhecer promessas sem fundamento', 'Avaliar provas, custos e apoio de um programa antes de confiar em resultados anunciados.', ['G10-03'], ['programEvidence', 'provider', 'cost', 'support']),
        ('L07', 'Pensar no contexto da refeicao', 'Porcoes em casa e fora e compras com orcamento limitado pedem exemplos locais, sem culpa.', ['G10-04'], ['mealContext', 'budgetOptional', 'localExampleReview']),
        ('L08', 'Rever e sustentar a rotina', 'Acompanhamento e apoio fazem parte do percurso; nao inventar metas ou prometer eficacia clinica do app.', ['G10-02', 'G10-03'], ['voluntaryReview', 'supportSource', 'targetProvenance'])
    ]
    lessons = [{'id': 'G10-' + key, 'title': title, 'draftPtPT': draft, 'guideIds': ids,
                'futureFields': fields, 'textAuthorship': 'sintese editorial assistida por agente a partir das fontes humanas',
                'reviewStatus': 'pendente_editorial_nutricional_ptPT', 'releaseApproved': False}
               for key, title, draft, ids, fields in lessons]
    output = {'niche': 'N10', 'date': '2026-09-30', 'guides': guides, 'lessons': lessons,
        'sourceDiaryProjection': {'guideId': 'G10-04', 'sourceTableColumns': table[0],
            'foodRows': len(body), 'sourceDeclaredCalories': declared_total,
            'sumOfRowCalories': sum(values), 'oneRowMissingAmount': True,
            'role': 'exemplo didatico de registo e contexto, nunca dieta ou meta de 2916 kcal',
            'rowProjection': [{'sourceRow': i + 1, 'sourceFood': row[1], 'amountAsPublished': row[2] or None,
                'sourceEstimatedKcal': int(row[3]), 'inheritsContextViaRowspan': len(raw_table[i+1]) == 3}
                for i, row in enumerate(body)]},
        'portionMathExample': {'guideId': 'G10-04', 'sourceKcalPerServing': 280, 'consumedServings': 2,
            'resultKcal': int(Decimal('280') * 2), 'gramsPerServing': None,
            'role': 'aritmetica da fonte, sem conversao inventada de cup para gramas'},
        'sourceReferenceRangesNotTargets': [
            {'guideId': 'G10-01', 'quantity': [0.5, 1], 'unit': 'kg/week', 'applyAutomatically': False},
            {'guideId': 'G10-02', 'quantity': [1, 2], 'unit': 'lb/week', 'applyAutomatically': False},
            {'guideId': 'G10-03', 'quantity': [5, 10], 'unit': 'percent_start_weight_within_6_months', 'applyAutomatically': False}],
        'excludedImport': {'sourceId': 'NU24', 'scope': 'Better Health / Weight Loss Plan app',
            'observedOfferWeeks': 12, 'actualWeeklyContentImported': 0, 'commercialReuseApproved': False,
            'reason': 'termos especificos exigem licenca comercial; app/documentos para uso pessoal'},
        'previousFindingCorrection': {'sourceId': 'PR06', 'oldStatus': 'candidato', 'newStatus': 'condicional',
            'technicalPilotStillValid': True, 'commercialImportApproved': False,
            'basis': 'pagina original de 26/09 aponta termos Better Health especificos recebidos em 30/09; OGL geral nao basta',
            'remaining': 'demonstrar permissao especifica/excecao para texto e PDF exatos antes de importar'},
        'editorialBoundaries': ['sem alvo calorico ou prazo individual automatico',
            'sem percurso adulto aplicado silenciosamente a menores, gravidez ou contexto desconhecido',
            'condicoes medicas/dietas especiais/transtornos alimentares pedem contexto profissional apropriado',
            'sem classificacao moral dos alimentos, punicao ou incentivo a restricao extrema',
            'educacao e diario nao equivalem a programa clinico com apoio humano',
            'localizar servicos, unidades, rotulos e exemplos em Portugal antes de publicar'],
        'reusedEvidence': reuse, 'releaseApproved': False}
    summary = {'niche': 'N10', 'date': '2026-09-30', 'researchStatus': 'concluido_no_recorte',
        'guides': len(guides), 'lessons': len(lessons), 'sourceDiaryRows': len(body),
        'calls': len(evidence), 'http200': sum(x['status'] == 200 for x in evidence.values()),
        'bodyHashesVerified': len(evidence), 'reusedEvidenceHashes': len(reuse),
        'checksPassed': len(CHECKS), 'checks': CHECKS, 'releaseApproved': False,
        'criticalCorrection': 'PR06: direitos comerciais condicionais; termos Better Health especificos substituem a conclusao anterior baseada so na OGL',
        'remaining': ['revisao editorial/nutricional pt-PT', 'direitos por ativo e condicoes de adaptacao',
            'programa alimentar completo e apoio individual nao entregues neste recorte',
            'sem app, Figma, contrato interno ou banco alterado'], 'next': 'N11'}
    for name, data in [('conteudo-guiado.json', output), ('resumo-perda-peso.json', summary)]:
        (FOLDER / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in summary.items() if k not in ('checks','remaining')},ensure_ascii=False))


if __name__ == '__main__':
    main()
