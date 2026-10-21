"""Audita o pacote documental ES2019 sem aprovar treino, licenca ou APK."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parent
PACKAGE = '2026-10-04/n15i-funcional/pacote-apk-snacking-2019.json'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_fields(data):
    require(data['id'] == 'ES2019-DOM-01', 'Wrong package')
    require(data['researchCandidateSelected'] is True and data['releaseApproved'] is False
            and data['appImplemented'] is False, 'Research is not release approval')
    identity = data['identity']
    require(identity['edition'] == '2019-original' and identity['pmcid'] == 'PMC6794984'
            and identity['doi'] == '10.1155/2019/7516939', 'Mixed editions')
    require(identity['actor'] == 'idoso_praticando_para_si' and identity['environment'] == 'casa'
            and not identity['caregiverOwnProgrammeDemonstrated']
            and not identity['publicSquareProgrammeDemonstrated']
            and not identity['indoorGymProgrammeDemonstrated'], 'Unsupported audience/environment')
    dose = data['dose']
    expected = {'durationDays': 28, 'sessionsPerDay': 2, 'sessionsTotal': 56,
                'sessionWindows': ['manha', 'noite'], 'secondsPerMovement': 60,
                'restSecondsBetweenMovements': 60, 'minutesPerSessionCalculated': 9,
                'minutesPerSessionDeclaredBySource': None, 'repetitions': None,
                'warmup': None, 'cooldown': None, 'weeklyProgression': None,
                'progressionState': 'nao_prescrita_na_fonte', 'missedSessionCompensation': None,
                'externalLoad': 'Somente peso corporal',
                'effortSource': 'Tantas repeticoes quanto possivel no minuto; nao prescricao universal, meta minima ou exigencia de falha momentanea.'}
    require(dose == expected, 'Dose must remain the source protocol, with absent fields')
    movements = data['movements']
    require([m['id'] for m in movements] == [f'ES19-S{i}' for i in range(1, 6)]
            and [m['order'] for m in movements] == list(range(1, 6)), 'Wrong exercise order/count')
    supports = ['cadeira_como_assento', 'cadeira_como_assento',
                'cadeira_para_estabilidade_se_necessario_conforme_artigo',
                'uma_mao_na_cadeira_se_necessario', 'segurar_cadeira_para_equilibrio']
    require([m['support'] for m in movements] == supports, 'Lost support semantics')
    require([m['alternating'] for m in movements] == [False, True, True, True, False],
            'Wrong unilateral/bilateral variant')
    for index, movement in enumerate(movements, 1):
        require(movement['sourceFigure'] == f'S{index}'
                and movement['sourcePage'] == (1 if index <= 3 else 2)
                and bool(movement['instructionPtDraft']) and bool(movement['correspondence']),
                'Missing instruction provenance')
    delivery = data['delivery']
    require(delivery['homeSessionsSupervised'] is False
            and delivery['initialResearchScreeningRequiredInStudy'] is True
            and delivery['dailyVideoSubmissionMandatoryInThisEdition'] is False
            and delivery['anotherPersonMandatoryInThisEdition'] is None
            and delivery['validatedAutonomousAppDelivery'] is False
            and delivery['researchTeamOrBudgetAssumedForApp'] is False, 'Delivery fabricated')
    co = data['cointervention']
    require(co['present'] is True and co['bothGroups'] is True
            and co['nutritionPrescriptionForApp'] is False
            and co['exerciseOnlyEfficacyDemonstrated'] is False, 'Cointervention erased')
    require(data['rights']['versionReportedInLocalArticle'] is None
            and data['rights']['licenseUrlReportedInLocalArticle'] is None
            and data['rights']['finalBatchRightsReviewed'] is False, 'Rights overclaimed')
    coverage = data['coverage']
    require(coverage['stairs'] is False and coverage['stretchingRoutine'] is False
            and coverage['wholeBodyProgramme'] is False, 'Missing modality invented')
    require(data['outcomesBoundary']['fallsPreventionDemonstrated'] is False
            and data['outcomesBoundary']['caregiverBenefitDemonstrated'] is False,
            'Unsupported clinical claim')
    require(len(data['releaseGates']) >= 5 and len(data['forbiddenMappings']) >= 6,
            'Publication gates lost')


def verify_record(relative, expected_hash, root=ROOT):
    path = (root / relative).resolve()
    path.relative_to(root.resolve())
    record = json.loads(path.read_text(encoding='utf-8'))
    body = (path.parent / record['bodyFile']).resolve()
    body.relative_to(root.resolve())
    payload = body.read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    require(record['status'] == 200 and record['bytes'] == len(payload)
            and record['sha256'] == digest == expected_hash, 'Body integrity failed')
    return payload


def validate(relative=PACKAGE):
    path = (ROOT / relative).resolve()
    path.relative_to(ROOT)
    data = json.loads(path.read_text(encoding='utf-8'))
    validate_fields(data)
    provenance = data['provenance']
    xml = verify_record(provenance['articleRecord'], provenance['articleSha256'])
    archive = verify_record(provenance['supplementsRecord'], provenance['supplementsSha256'])
    article = ET.fromstring(xml)
    ids = {e.get('pub-id-type'): e.text for e in article.findall('.//article-id')}
    require(ids.get('doi') == data['identity']['doi'], 'Article identity mismatch')
    permission = ' '.join(article.find('.//permissions').itertext())
    require('Creative Commons Attribution' in permission, 'License declaration missing')
    links = [m.get('{http://www.w3.org/1999/xlink}href')
             for m in article.findall('.//supplementary-material/media')]
    require(provenance['member'] in links, 'Supplement not linked by source')
    with zipfile.ZipFile(io.BytesIO(archive)) as source:
        member = source.getinfo(provenance['member'])
        require(member.file_size == provenance['memberBytes'] < 2097152,
                'Unexpected supplement size')
        pdf = source.read(member)
    require(hashlib.sha256(pdf).hexdigest() == provenance['memberSha256'],
            'Supplement integrity failed')
    from pypdf import PdfReader
    pages = PdfReader(io.BytesIO(pdf)).pages
    require(len(pages) == provenance['memberPages'] == 2, 'Unexpected pages')
    for movement in data['movements']:
        require(f"Figure {movement['sourceFigure']}" in pages[movement['sourcePage'] - 1].extract_text(),
                'Figure/page mismatch')
    summary = {'date': data['date'], 'package': data['id'], 'packageArtifactSha256': hashlib.sha256(path.read_bytes()).hexdigest(),
               'verifiedBodies': 2, 'verifiedSupplementMembers': 1, 'instructionRecords': 5,
               'visualPagesDeclaredInspected': 2, 'releaseApproved': False, 'appImplemented': False,
               'testType': 'Integridade e consistencia documental, nao exame clinico/legal ou teste do APK'}
    path.with_name('resumo-pacote-apk.json').write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('package', nargs='?', default=PACKAGE)
    validate(parser.parse_args().package)
