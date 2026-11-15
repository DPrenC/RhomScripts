"""Prueba wxLua en un perfil nuevo de Mudlet, aislado y sin servidor."""
import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import struct
import sys
import time
import uuid
import xml.etree.ElementTree as ET

import requests

ROOT = Path(__file__).resolve().parents[1]


def native_metadata(dll):
    assert dll.is_file(), f'Falta la DLL compilada: {dll}'
    binary = dll.read_bytes()
    assert binary[:2] == b'MZ' and len(binary) >= 64, f'La biblioteca no es un archivo PE: {dll}'
    pe_offset = struct.unpack_from('<I', binary, 0x3C)[0]
    assert binary[pe_offset:pe_offset + 4] == b'PE\0\0', f'Cabecera PE inválida: {dll}'
    assert struct.unpack_from('<H', binary, pe_offset + 4)[0] == 0x8664, f'La DLL no es AMD64: {dll}'
    return {'dll': dll.as_posix(), 'sha256': sha256(binary).hexdigest()}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--exe', type=Path)
    parser.add_argument('--timeout', type=int, default=90)
    parser.add_argument('--interactive', action='store_true',
                        help='Deja la ventana abierta para comprobar teclado y lector manualmente.')
    probe_group = parser.add_mutually_exclusive_group()
    probe_group.add_argument('--configurador', action='store_true', help='Comprueba el configurador nativo real.')
    probe_group.add_argument('--comunicaciones', action='store_true', help='Comprueba el panel de canales nativo real.')
    probe_group.add_argument('--cffi', action='store_true', help='Comprueba cffi-lua y la asociación nativa de ventanas.')
    args = parser.parse_args()
    dll = ROOT / 'rhomscripts/lib/windows-x64/wxlua/wx.dll'
    wx_metadata = native_metadata(dll)
    cffi_metadata = None
    if args.cffi:
        cffi_dll = ROOT / 'rhomscripts/lib/windows-x64/cffi/cffi.dll'
        cffi_metadata = native_metadata(cffi_dll)
        cffi_metadata['manifest'] = json.loads(cffi_dll.with_name('manifest.json').read_text(encoding='utf-8'))
        assert cffi_metadata['manifest']['cffi.dll']['sha256'] == cffi_metadata['sha256'], 'SHA-256 de cffi.dll distinto del manifiesto'
    response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
    response.raise_for_status()
    release = response.json()
    assert not release['draft'] and not release['prerelease']
    latest_version = release['tag_name'].removeprefix('Mudlet-')
    exe = (args.exe or Path(os.environ['LOCALAPPDATA']) / f'Mudlet_64_/app-{latest_version}/Mudlet.exe').resolve()
    assert exe.is_file(), str(exe)
    base = ROOT / '.tools/wxlua-probe'
    run_root = base / 'runs' / uuid.uuid4().hex
    data_root = run_root / 'config'
    profile = 'RhomScripts-wxLua-Validacion'
    profile_root = data_root / 'mudlet/profiles' / profile
    current = profile_root / 'current'
    current.mkdir(parents=True, exist_ok=True)
    result_path = run_root / 'result.txt'
    package = ET.Element('MudletPackage', version='1.001')
    host = ET.SubElement(ET.SubElement(package, 'HostPackage'), 'Host')
    ET.SubElement(host, 'name').text = profile
    ET.SubElement(host, 'mUrl').text = ''
    ET.SubElement(host, 'mPort').text = '0'
    script = ET.SubElement(ET.SubElement(package, 'ScriptPackage'), 'Script', isActive='yes', isFolder='no')
    ET.SubElement(script, 'name').text = 'Prueba wxLua aislada'
    ET.SubElement(script, 'packageName').text = ''
    settings = {
        'RHOM_WX_ROOT': ROOT.as_posix(),
        'RHOM_WX_RESULT': result_path.as_posix(),
        'RHOM_WX_PROFILE': profile_root.as_posix(),
        'RHOM_WX_INTERACTIVE': args.interactive,
    }
    bootstrap = '\n'.join(f'{key} = {json.dumps(value, ensure_ascii=False)}' for key, value in settings.items())
    probe = 'comunicaciones_wx.lua' if args.comunicaciones else 'cffi_probe.lua' if args.cffi else 'configurador_wx.lua' if args.configurador else 'wxlua_probe.lua'
    bootstrap += f'\ntempTimer(2, function() dofile(RHOM_WX_ROOT .. "/scripts/tests/{probe}") end)'
    ET.SubElement(script, 'script').text = bootstrap
    ET.SubElement(script, 'eventHandlerList')
    ET.ElementTree(package).write(current / 'wxlua-validation.xml', encoding='utf-8', xml_declaration=True)
    environment = os.environ.copy()
    environment['XDG_CONFIG_HOME'] = data_root.as_posix()
    environment['CI'] = 'true'
    metadata = {
        'run': run_root.as_posix(), 'profile': profile_root.as_posix(),
        'result': result_path.as_posix(), 'log': (run_root / 'process.log').as_posix(),
        'version': latest_version, 'interactive': args.interactive, 'configurador': args.configurador,
        'dll': wx_metadata['dll'], 'dll_sha256': wx_metadata['sha256'],
        'cffi': cffi_metadata, 'comunicaciones': args.comunicaciones,
    }
    with (run_root / 'process.log').open('wb') as log:
        process = subprocess.Popen([str(exe), '--offline', '--profile', profile], cwd=exe.parent,
                                   env=environment, stdout=log, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        metadata['pid'] = process.pid
        (base / 'active.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'Perfil aislado: {profile_root}\nPID propio: {process.pid}\nResultado: {result_path}', flush=True)
        try:
            deadline = time.monotonic() + args.timeout
            while time.monotonic() < deadline:
                if result_path.exists():
                    text = result_path.read_text(encoding='utf-8')
                    print(text, flush=True)
                    assert f'VERSION {latest_version}\n' in text, 'La versión probada no es la última estable'
                    metadata['success'] = text.startswith('STATUS OK\n')
                    if args.cffi and metadata['success']:
                        assert f'PID {process.pid}\n' in text, 'El PID del sondeo no coincide con el proceso aislado'
                    (run_root / 'summary.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
                    (base / 'latest.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
                    return 0 if metadata['success'] else 1
                if process.poll() is not None:
                    raise RuntimeError(f'Mudlet terminó con {process.returncode}; véase {run_root}')
                time.sleep(0.2)
            progress = result_path.with_name(result_path.name + '.progress')
            if progress.exists():
                print(progress.read_text(encoding='utf-8'), flush=True)
            raise TimeoutError(f'Sin resultado en {args.timeout} s; véase {run_root}')
        except Exception as error:
            metadata['success'] = False
            metadata['runner_error'] = str(error)
            metadata['exit_code'] = process.poll()
            (run_root / 'summary.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            (base / 'latest.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            raise
        finally:
            # Nunca detener otra instancia de Mudlet: solo el proceso recién creado.
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)


if __name__ == '__main__':
    sys.exit(main())
