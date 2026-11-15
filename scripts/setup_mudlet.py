"""Instala la última versión estable oficial de Mudlet en Windows por usuario."""
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import requests

ROOT = Path(__file__).resolve().parents[1]


def main():
    response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
    response.raise_for_status()
    release = response.json()
    assert not release['draft'] and not release['prerelease']
    version = release['tag_name'].removeprefix('Mudlet-')
    executable = Path(os.environ['LOCALAPPDATA']) / f'Mudlet_64_/app-{version}/Mudlet.exe'
    if executable.exists():
        print(f'Mudlet estable {version} ya instalado: {executable}')
        return
    asset = next(asset for asset in release['assets'] if asset['name'].endswith('windows-64-installer.exe'))
    download = requests.get(asset['browser_download_url'], timeout=180)
    download.raise_for_status()
    checksum = sha256(download.content).hexdigest()
    digest = asset.get('digest')
    assert digest and digest == 'sha256:' + checksum, 'Falta el digest oficial o no coincide la descarga'
    destination = ROOT / '.tools' / asset['name']
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(download.content)
    (ROOT / '.tools/mudlet-release.json').write_text(json.dumps({'tag': release['tag_name'], 'url': release['html_url'],
                                                               'sha256': checksum, 'asset_digest': digest}, indent=2), encoding='utf-8')
    subprocess.run([str(destination), '/silent'], check=True, timeout=180,
                   creationflags=subprocess.CREATE_NO_WINDOW)
    assert executable.exists(), 'El instalador terminó sin dejar la versión esperada'
    print(f'Mudlet estable {version} instalado: {executable}')


if __name__ == '__main__':
    main()
