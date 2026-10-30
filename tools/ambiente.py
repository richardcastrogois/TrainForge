"""Operate only this checkout's existing local evaluation. No init, migration or wipe."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import socket
import sys

import avaliar_android as android
import catalog_local as catalog
import db_local as database
from dev_api import ROOT


def listening(port):
    with socket.socket() as connection:
        connection.settimeout(0.3)
        return connection.connect_ex(('127.0.0.1', port)) == 0


def stop_path(value, parent, pattern):
    if not isinstance(value, str) or not value:
        raise RuntimeError('Processo sem registro de parada; nada foi encerrado')
    path = Path(value).resolve()
    if path.parent != parent.resolve() or not re.fullmatch(pattern, path.name):
        raise RuntimeError('Alvo de parada fora do registro deste projeto')
    return path


def stop_plan():
    """Validate every known listener before creating any stop flag."""
    database.verify_owned()
    plan = []
    if listening(8082):
        state = json.loads(android.STATE.read_text(encoding='utf-8'))
        if state.get('root') != str(ROOT):
            raise RuntimeError('API pertence a outro checkout')
        plan.append(('api', stop_path(state.get('apiStopFile'), android.STATE_DIR,
                                     r'api-stop-[a-f0-9]{16}\.flag'), 8082))
    if listening(18083):
        state = catalog.owned_state()
        plan.append(('catalogo', stop_path(state.get('stopFile'), catalog.DIRECTORY,
                                          r'stop-[a-f0-9]{16}\.flag'), 18083))
    return plan


def stop():
    plan = stop_plan()
    for name, flag, port in plan:
        flag.touch()
        android.wait_for(lambda: not listening(port), 20,
                         name + ' não encerrou; banco preservado')
    # Stop only the registered AVD and the same Android boot, never a phone.
    tooling = android.paths()
    state = json.loads(android.STATE.read_text(encoding='utf-8')) if android.STATE.exists() else {}
    serial = state.get('serial')
    if (state.get('root') == str(ROOT) and serial and serial.startswith('emulator-')
            and serial in android.devices(tooling)
            and android.avd_name(tooling, serial) == android.AVD
            and state.get('emulatorBootId') == android.output([
                tooling['adb'], '-s', serial, 'shell', 'cat', '/proc/sys/kernel/random/boot_id'])):
        android.output([tooling['adb'], '-s', serial, 'emu', 'kill'])
    if listening(8082) or listening(18083):
        raise RuntimeError('Serviço voltou a escutar; banco preservado')
    if listening(database.PORT):
        database.verify_owned()
        database.run('pg_ctl', ['-D', database.DATA, '-m', 'fast', '-w', '-t', '20', 'stop'], timeout=25)
    print('Ambiente registrado parado. Dados, assinatura e contas preservados.')


def start_catalog():
    database.start()
    # Reuse M4's existing provisioned catalog. Never call activate/provision here.
    catalog.start_reader(catalog.owned_state())


def start():
    start_catalog()
    android.start(android.paths())


def status():
    database.verify_owned()
    return {'banco15432': listening(15432), 'catalogo18083': catalog.ready(),
            'api8082': android.api_ready(), 'apkAtual': android.artifact_current(),
            'dispositivos': android.devices(android.paths())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['status', 'start', 'stop', 'plan-stop', 'start-catalog'])
    args = parser.parse_args()
    if args.action == 'start':
        start()
    elif args.action == 'start-catalog':
        start_catalog()
        print('Catálogo pronto; consulte catalog.log.')
    elif args.action == 'stop':
        stop()
    elif args.action == 'plan-stop':
        print(json.dumps({'servicos': [name for name, _, _ in stop_plan()],
                          'cluster': 'trainforge-isolated-v1', 'modificado': False}))
    else:
        print(json.dumps(status(), ensure_ascii=False))


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print('Operação não concluída; nenhum reset/migration executado. Tipo: '
              + type(error).__name__, file=sys.stderr)
        raise SystemExit(1)
