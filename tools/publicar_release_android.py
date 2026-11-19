"""Publish the verified release APK as a GitHub Release (explicit, one command).

Run after `preparar_release_android.py` succeeded:
    python tools/publicar_release_android.py --confirm-publish

The asset is always named TrainForge.apk, so the public link and QR code
(…/releases/latest/download/TrainForge.apk) never change between versions.
Requires the GitHub CLI logged in (`gh auth login`). Refuses to publish an APK
that differs from the last verified artifact or a version that already exists.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
REPO = 'richardcastrogois/TrainForge'
ASSET = 'TrainForge.apk'
LATEST_URL = f'https://github.com/{REPO}/releases/latest/download/{ASSET}'


def gh() -> str:
    for candidate in (shutil.which('gh'), r'C:\Program Files\GitHub CLI\gh.exe'):
        if candidate and Path(candidate).exists():
            return candidate
    raise SystemExit('GitHub CLI não encontrado; instale e rode `gh auth login`.')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--confirm-publish', action='store_true', help='publicar de fato (sem isso só confere)')
    parser.add_argument('--notes', default='', help='texto curto do que mudou nesta versão')
    args = parser.parse_args()
    version = re.search(r'^version: (\S+)$', (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'), re.M).group(1)
    name = version.split('+')[0]
    artifact = json.loads((ROOT / '.local/android-release/artifact.json').read_text(encoding='utf-8'))
    apk = ROOT / artifact['relativePath']
    digest = hashlib.sha256(apk.read_bytes()).hexdigest()
    manifest = artifact['manifest']
    if digest != artifact['sha256'] or manifest.get('versionName') != name or str(manifest.get('versionCode')) != version.split('+')[1]:
        raise SystemExit('APK não corresponde ao último release verificado desta versão; rode preparar_release_android.py.')
    print(json.dumps({'version': version, 'sha256': digest, 'bytes': apk.stat().st_size, 'link': LATEST_URL}))
    if not args.confirm_publish:
        print('Conferido. Nada publicado (use --confirm-publish).')
        return
    notes = (f'TrainForge {name} (build {version.split("+")[1]}).\n\n{args.notes}\n\n'
             f'Instalar: baixe `{ASSET}` no Android, abra e permita "Instalar apps desconhecidos".\n\nSHA-256: `{digest}`')
    with tempfile.TemporaryDirectory() as temporary:
        staged = Path(temporary) / ASSET
        shutil.copyfile(apk, staged)
        subprocess.run([gh(), 'release', 'create', f'v{name}', str(staged), '-R', REPO, '--target', 'main',
                        '--title', f'TrainForge {name}', '--notes', notes, '--latest'], check=True)
    print('Publicado. Link fixo (o mesmo do QR code):', LATEST_URL)


if __name__ == '__main__':
    main()
