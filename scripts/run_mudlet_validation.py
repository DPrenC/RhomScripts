"""Ejecuta integración real con Mudlet en una configuración separada, sin red de juego."""
import argparse
from pathlib import Path
from hashlib import sha256
import json
import os
import shutil
import subprocess
import sys
import time
import uuid
import xml.etree.ElementTree as ET
from zipfile import ZipFile
import requests

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--exe', type=Path)
    parser.add_argument('--package', type=Path, help='Reutiliza el paquete comprobado por la validación local.')
    parser.add_argument('--timeout', type=int, default=100)
    parser.add_argument('--clipboard-text-only', action='store_true',
                        help='Prueba optativa que sustituye el portapapeles; preparar antes contenido solo de texto.')
    args = parser.parse_args()
    release_response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
    release_response.raise_for_status()
    latest = release_response.json()
    assert not latest['prerelease'] and not latest['draft']
    latest_version = latest['tag_name'].removeprefix('Mudlet-')
    executable = (args.exe or Path(os.environ['LOCALAPPDATA']) / f'Mudlet_64_/app-{latest_version}/Mudlet.exe').resolve()
    assert executable.exists(), str(executable)
    run_base = ROOT / '.tools/mudlet-integration'
    # Perfil y artefactos propios: dos ejecutores no pueden compartir resultados.
    run_root = run_base / 'runs' / uuid.uuid4().hex
    data_root = run_root / 'config'
    profile = 'RhomScripts-Validacion'
    profile_root = data_root / 'mudlet/profiles' / profile
    current = profile_root / 'current'
    current.mkdir(parents=True, exist_ok=True)
    # Copia oficial real y procedencia del ensayo; nunca se inventa un paquete
    # con el nombre RLMud_Config para conseguir una inicialización positiva.
    official_url = 'https://mudlet.reinosdeleyenda.es/RLMud_Config.zip'
    official_response = requests.get(official_url, timeout=45)
    official_response.raise_for_status()
    official_package = run_root / 'RLMud_Config.zip'
    official_package.write_bytes(official_response.content)
    with ZipFile(official_package) as archive:
        assert 'RLMud_Config.xml' in archive.namelist()
    official_hash = sha256(official_response.content).hexdigest()
    (run_root / 'official-source.json').write_text(json.dumps({
        'url': official_url, 'sha256': official_hash,
    }, indent=2) + '\n', encoding='utf-8')
    package_path = run_root / 'rhomloader.mpackage'
    if args.package:
        shutil.copy2(args.package, package_path)
    else:
        from test_packaging import run as package_run
        package_run(package_copy=package_path)
    result_path = run_root / 'result.txt'
    if result_path.exists():
        result_path.unlink()
    # Un perfil sin servidor, abierto además con --offline. XDG_CONFIG_HOME está
    # soportado por Mudlet 5.1.1 también en Windows (MudletApp::xdgConfigDir).
    package = ET.Element('MudletPackage', version='1.001')
    host = ET.SubElement(ET.SubElement(package, 'HostPackage'), 'Host')
    ET.SubElement(host, 'name').text = profile
    ET.SubElement(host, 'mUrl').text = ''
    ET.SubElement(host, 'mPort').text = '0'
    script = ET.SubElement(ET.SubElement(package, 'ScriptPackage'), 'Script', isActive='yes', isFolder='no')
    ET.SubElement(script, 'name').text = 'RhomScripts integración aislada'
    ET.SubElement(script, 'packageName').text = ''
    bootstrap = ('RHOM_TEST_ROOT = ' + json.dumps(ROOT.as_posix(), ensure_ascii=False)
                 + '\nRHOM_TEST_RESULT = ' + json.dumps(result_path.as_posix(), ensure_ascii=False)
                 + '\nRHOM_TEST_PACKAGE = ' + json.dumps(package_path.as_posix(), ensure_ascii=False)
                 + '\nRHOM_TEST_OFFICIAL_PACKAGE = ' + json.dumps(official_package.as_posix(), ensure_ascii=False)
                 + '\nRHOM_TEST_PROFILE = ' + json.dumps(profile_root.as_posix(), ensure_ascii=False)
                 + '\nRHOM_TEST_CLIPBOARD = ' + ('true' if args.clipboard_text_only else 'false')
                 + '\ntempTimer(2, function() dofile(RHOM_TEST_ROOT .. "/scripts/tests/mudlet_integration.lua") end)')
    ET.SubElement(script, 'script').text = bootstrap
    ET.SubElement(script, 'eventHandlerList')
    ET.ElementTree(package).write(current / 'validation.xml', encoding='utf-8', xml_declaration=True)
    environment = os.environ.copy()
    environment['XDG_CONFIG_HOME'] = data_root.as_posix()
    environment['CI'] = 'true'
    command = [str(executable), '--offline', '--profile', profile]
    # CREATE_NO_WINDOW evita una consola adicional. El perfil de prueba es propio;
    # no se modifica ni se cierra ninguna instancia anterior del usuario.
    flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    with (run_root / 'process.log').open('wb') as log:
        process = subprocess.Popen(command, cwd=executable.parent, env=environment,
                                   stdout=log, stderr=subprocess.STDOUT, creationflags=flags)
        try:
            deadline = time.monotonic() + args.timeout
            while time.monotonic() < deadline:
                if result_path.exists():
                    text = result_path.read_text(encoding='utf-8')
                    print(text, flush=True)
                    assert f'VERSION {latest_version}\n' in text, f'Mudlet probado no es la última versión estable: {latest_version}'
                    if text.startswith('STATUS OK\n'):
                        with ZipFile(official_package) as archive:
                            expected_xml = archive.read('RLMud_Config.xml')
                        installed_xml = (profile_root / 'RLMud_Config/RLMud_Config.xml').read_bytes()
                        assert installed_xml == expected_xml, 'La descarga Qt difiere de la copia oficial de referencia'
                    metadata = {'result': result_path.as_posix(), 'log': (run_root / 'process.log').as_posix(),
                                'version': latest_version, 'official_sha256': official_hash,
                                'success': text.startswith('STATUS OK\n')}
                    pointer = run_root / 'latest.json'
                    pointer.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
                    pointer.replace(run_base / 'latest.json')
                    print('Resultado detallado: ' + str(result_path), flush=True)
                    return 0 if text.startswith('STATUS OK\n') else 1
                if process.poll() is not None:
                    raise RuntimeError(f'Mudlet terminó con {process.returncode} sin escribir resultados. Véase {run_root}')
                time.sleep(0.5)
            raise TimeoutError(f'Mudlet no escribió resultados en {args.timeout} s. Véase {run_root}')
        finally:
            # Solo la instancia que inició este script. Los datos son aislados.
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)


if __name__ == '__main__':
    sys.exit(main())
