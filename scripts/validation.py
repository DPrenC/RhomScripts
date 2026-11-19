"""Compilación Lua real, Luacheck, PCRE2 y casos de comportamiento reproducibles."""
import argparse
from functools import lru_cache
from hashlib import sha256
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import tomllib
import io
from urllib.parse import unquote, urlsplit
from zipfile import ZipFile

import pcre2
import requests
import yaml
import lupa
from lupa.lua51 import LuaRuntime as Lua51
from lupa.luajit21 import LuaRuntime as LuaJIT

ROOT = Path(__file__).resolve().parents[1]
LUACHECK_URL = 'https://github.com/lunarmodules/luacheck/releases/download/v1.2.0/luacheck.exe'
LUACHECK_HASH = '0f1c69c4d09f1ebb4d8df14c215e4553e2e639bd4cb7bf3c639b0daa6198317b'


def install_luacheck():
    path = ROOT / '.tools/luacheck.exe'
    if not path.exists() or sha256(path.read_bytes()).hexdigest() != LUACHECK_HASH:
        response = requests.get(LUACHECK_URL, timeout=120)
        response.raise_for_status()
        if sha256(response.content).hexdigest() != LUACHECK_HASH:
            raise RuntimeError('La descarga de Luacheck no coincide con el hash fijado.')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(response.content)
    print('Luacheck 1.2.0 instalado y verificado por SHA-256.')


def install_java():
    destination = ROOT / '.tools/java'
    if list(destination.glob('*/bin/java.exe')):
        print('Java local ya preparado.')
        return
    response = requests.get('https://api.adoptium.net/v3/assets/latest/17/hotspot',
                            params={'architecture': 'x64', 'image_type': 'jre', 'os': 'windows'}, timeout=60)
    response.raise_for_status()
    asset = response.json()[0]
    package = asset['binary']['package']
    download = requests.get(package['link'], timeout=180)
    download.raise_for_status()
    assert sha256(download.content).hexdigest() == package['checksum'], 'Hash de Java incorrecto'
    destination.mkdir(parents=True, exist_ok=True)
    with ZipFile(io.BytesIO(download.content)) as archive:
        for entry in archive.infolist():
            assert (destination / entry.filename).resolve().is_relative_to(destination.resolve()), 'Ruta ZIP inválida'
        archive.extractall(destination)
    (destination / 'source.json').write_text(json.dumps({'url': package['link'], 'sha256': package['checksum'],
                                                       'version': asset['version']}, indent=2), encoding='utf-8')
    print('Java 17 local instalado y verificado; no se modificó el PATH del sistema.')


def lua_files():
    return sorted(path for folder in ['rhomscripts', 'RhomLoader/src', 'scripts']
                  for path in (ROOT / folder).rglob('*.lua'))


def check_syntax():
    results = []
    for runtime_type in [Lua51, LuaJIT]:
        runtime = runtime_type(unpack_returned_tuples=True)
        compile_lua = runtime.eval('function(text, name) local f, err = loadstring(text, name); return f ~= nil, err end')
        for path in lua_files():
            ok, error = compile_lua(path.read_text(encoding='utf-8-sig'), '@' + path.relative_to(ROOT).as_posix())
            if not ok:
                raise AssertionError(error)
        results.append(runtime.eval('jit and jit.version or _VERSION'))
    return {'files': len(lua_files()), 'runtimes': results}


def check_agents():
    from test_sync_agents import run as test_sync

    subprocess.run([sys.executable, str(ROOT / 'scripts/sync_agents.py'), '--check'], check=True, cwd=ROOT)
    roles = json.loads((ROOT / 'doc/agentes/roles.json').read_text(encoding='utf-8'))
    for path in (ROOT / '.github').rglob('*.md'):
        text = path.read_text(encoding='utf-8-sig')
        if text.startswith('---\n'):
            metadata = yaml.safe_load(text.split('---', 2)[1])
            assert metadata.get('description'), f'Falta description: {path}'
            if path.name.endswith('.instructions.md'):
                assert isinstance(metadata.get('applyTo'), str), f'applyTo debe ser cadena: {path}'
                for pattern in metadata['applyTo'].split(','):
                    assert list(ROOT.glob(pattern.strip())), f'Patrón sin archivos: {pattern}'
    for path in (ROOT / '.codex/agents').glob('*.toml'):
        metadata = tomllib.loads(path.read_text(encoding='utf-8'))
        assert all(metadata.get(key) for key in ['name', 'description', 'developer_instructions'])
    paths = [ROOT / 'README.md', ROOT / 'AGENTS.md',
             *(ROOT / 'doc').rglob('*.md'), *(ROOT / '.github').rglob('*.md')]
    local_links = 0
    for path in paths:
        for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
            destination = urlsplit(link)
            if not destination.scheme and not destination.netloc and destination.path:
                target = (path.parent / unquote(destination.path)).resolve()
                assert target.exists(), f'Enlace roto en {path.relative_to(ROOT)}: {link}'
                local_links += 1
    return {'roles': len(roles), 'adapters': len(roles) * 2,
            'markdown_files': len(paths), 'local_links': local_links, 'generator_regression': test_sync()}


def check_support_scripts():
    paths = list((ROOT / 'scripts').rglob('*.py'))
    for path in paths:
        compile(path.read_text(encoding='utf-8-sig'), str(path), 'exec')
    result = subprocess.run(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(ROOT / 'scripts/validate_powershell.ps1')],
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=30)
    assert result.returncode == 0, result.stdout + result.stderr
    for record in json.loads((ROOT / 'doc/mudlet/manifest.json').read_text(encoding='utf-8')):
        assert sha256((ROOT / 'doc/mudlet' / record['html']).read_bytes()).hexdigest() == record['sha256']
    keys = json.loads((ROOT / 'doc/mudlet/keycodes-source.json').read_text(encoding='utf-8'))
    assert sha256((ROOT / 'doc/mudlet/KeyCodes.lua').read_bytes()).hexdigest() == keys['sha256']
    return {'python_files': len(paths), 'powershell': result.stdout.strip(), 'documentation_hashes': 'OK'}


def check_api_policy():
    # Lista cerrada de APIs documentadas usadas por el proyecto, no detección de funciones de dominio.
    apis = ['cecho', 'echo', 'announce', 'tempKey', 'tempAlias', 'tempRegexTrigger',
            'getMudletHomeDir', 'getProfileName', 'playSoundFile', 'stopSounds',
            'feedTriggers', 'table.load', 'table.save', 'getLines', 'setClipboardText']
    alternatives = '|'.join(re.escape(api) for api in apis)
    guards = re.compile(r'(?:type\(\s*(?:' + alternatives + r')\s*\)|\bif\s+(?:' + alternatives + r')\b|\bpcall\(\s*(?:' + alternatives + r')\b)')
    for path in lua_files():
        if path.is_relative_to(ROOT / 'scripts'):
            continue
        for number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
            code = line.split('--', 1)[0]
            assert not guards.search(code), f'Protección de API prohibida: {path}:{number}'
            assert not re.search(r'\b(?:setSoundPan|loadTable|saveTable)\s*\(', code), f'API sin contrato: {path}:{number}'
    return 'Sin protecciones de existencia en las APIs auditadas; también se ejecutan pruebas negativas.'


def check_behavior(runtime_type):
    runtime = runtime_type(unpack_returned_tuples=True)
    @lru_cache(maxsize=None)
    def regex(pattern):
        return pcre2.compile(pattern)
    def validate_regex(pattern):
        regex(pattern)
        return True
    def match_regex(pattern, text):
        found = regex(pattern).search(text)
        if found is None:
            return None
        def capture(group):
            try:
                return found.group(group) or ''
            except pcre2._cy.LibraryError as error:
                # PCRE2 reports an unmatched optional capture as UNSET; Mudlet
                # exposes the corresponding matches field as an empty string.
                if str(error) != 'requested value is not set':
                    raise
                return ''
        values = {index + 1: capture(index) for index in range(found.re.groups + 1)}
        values.update({name: capture(name) for name in found.re.groupindex})
        return runtime.table_from(values)
    runtime.globals().validateRegex = validate_regex
    runtime.globals().matchRegex = match_regex
    # Puente estrecho al sistema de archivos real; no simula recursos existentes.
    def attributes(path, attribute, follow_symlinks=True):
        assert attribute == 'mode', attribute
        try:
            mode = Path(path).stat(follow_symlinks=follow_symlinks).st_mode
        except OSError:
            return None
        if stat.S_ISDIR(mode):
            return 'directory'
        if stat.S_ISREG(mode):
            return 'file'
        if stat.S_ISLNK(mode):
            return 'link'
        return 'other'
    def dir_entries(path):
        return runtime.table_from(['.', '..', *os.listdir(path)])
    def mkdir(path):
        try:
            Path(path).mkdir()
        except OSError as error:
            return None, str(error)
        return True
    lua_dir = runtime.eval('''function(list)
        return function(path)
          local entries, index = list(path), 0
          return function()
            index = index + 1
            return entries[index]
          end
        end
    end''')(dir_entries)
    runtime.globals().lfs = runtime.table_from({
        'attributes': attributes,
        'symlinkattributes': lambda path, attribute: attributes(path, attribute, follow_symlinks=False),
        'currentdir': os.getcwd,
        'dir': lua_dir,
        'mkdir': mkdir,
    })
    # Serialización JSON real para el doble: no sustituye la prueba con yajl en Mudlet.
    is_lua_table = runtime.eval('function(value) return type(value) == "table" end')
    def to_lua(value):
        if isinstance(value, dict):
            return runtime.table_from({key: to_lua(item) for key, item in value.items()})
        if isinstance(value, list):
            return runtime.table_from([to_lua(item) for item in value])
        return value
    def to_python(value):
        if is_lua_table(value):
            entries = dict(value.items())
            if entries and set(entries) == set(range(1, len(entries) + 1)):
                return [to_python(entries[index]) for index in range(1, len(entries) + 1)]
            return {key: to_python(item) for key, item in entries.items()}
        return value
    def decode_json(value):
        return to_lua(json.loads(value, parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token))))
    def encode_json(value):
        return json.dumps(to_python(value), ensure_ascii=False, allow_nan=False)
    runtime.globals().yajl = runtime.table_from({'to_value': decode_json, 'to_string': encode_json})
    runtime.globals().RhomScriptsBasePath = (ROOT / 'rhomscripts').as_posix()
    with tempfile.TemporaryDirectory(prefix='rhom-validation-') as temp_path:
        assert Path(temp_path).resolve().is_relative_to(Path(tempfile.gettempdir()).resolve())
        runtime.globals().TEST_PROFILE_PATH = Path(temp_path).as_posix()
        results = runtime.execute('return dofile("scripts/validate_mudlet_load.lua")')
        return {'runtime': runtime.eval('jit and jit.version or _VERSION'),
                'cases': list(results['cases'].values()),
                'counts': {key: value for key, value in results['counts'].items()},
                'compiled_regex': regex.cache_info().currsize}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--install-luacheck', action='store_true')
    parser.add_argument('--install-java', action='store_true')
    parser.add_argument('--skip-git', action='store_true', help='Registra Git como omitido, no como superado.')
    parser.add_argument('--mudlet', action='store_true', help='Ejecuta también la integración real.')
    parser.add_argument('--mudlet-exe', type=Path)
    args = parser.parse_args()
    os.chdir(ROOT)
    if args.install_luacheck:
        install_luacheck()
        return 0
    if args.install_java:
        install_java()
        return 0
    report = {'tools': {'python': sys.version.split()[0], 'lupa': lupa.__version__, 'pcre2_binding': pcre2.__version__,
                        'luacheck': '1.2.0'}, 'checks': {}, 'failures': []}
    def check(name, action):
        try:
            report['checks'][name] = action()
            print('OK: ' + name, flush=True)
        except Exception as error:
            report['failures'].append({'check': name, 'error': str(error)})
            print('ERROR: ' + name + ': ' + str(error), flush=True)
    check('syntax', check_syntax)
    check('agents_and_docs', check_agents)
    check('support_scripts_and_documentation', check_support_scripts)
    check('api_policy', check_api_policy)
    def lint():
        path = ROOT / '.tools/luacheck.exe'
        assert path.exists(), 'Ejecuta scripts/setup_validation.ps1'
        assert sha256(path.read_bytes()).hexdigest() == LUACHECK_HASH, 'Hash de Luacheck incorrecto'
        result = subprocess.run([str(path), 'rhomscripts', 'RhomLoader/src', 'scripts', '--no-color', '--codes'],
                                capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=90)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result.stdout.strip()
    check('luacheck', lint)
    for runtime_type, label in [(Lua51, 'lua51'), (LuaJIT, 'luajit21')]:
        check('behavior_' + label, lambda kind=runtime_type: check_behavior(kind))
    from test_packaging import run as packaging_run
    runs = ROOT / '.tools/validation/runs'
    runs.mkdir(parents=True, exist_ok=True)
    run_dir = Path(tempfile.mkdtemp(dir=runs))
    with tempfile.TemporaryDirectory(prefix='rhom-validation-package-', dir=run_dir) as package_dir:
        package = Path(package_dir) / 'rhomloader.mpackage' if args.mudlet else None
        check('packaging', lambda: packaging_run(package_copy=package))
        if args.skip_git:
            report['checks']['git_diff_check'] = 'OMITIDO por --skip-git'
        else:
            def git_check(*diff_args):
                result = subprocess.run(['git', '-c', 'core.fsmonitor=false', 'diff', *diff_args, '--check'],
                                        capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=40)
                assert result.returncode == 0, result.stdout + result.stderr
                return 'Sin errores de espacios en el diff comprobado.'
            check('git_diff_worktree', git_check)
            check('git_diff_index', lambda: git_check('--cached'))
        report_path = run_dir / 'local.json'
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        print(f'Comprobaciones: {len(report["checks"])} superadas o registradas; {len(report["failures"])} fallidas.')
        print('Resultado local: ' + report_path.relative_to(ROOT).as_posix(), flush=True)
        if report['failures']:
            return 1
        if args.mudlet:
            command = [sys.executable, str(ROOT / 'scripts/run_mudlet_validation.py'), '--package', str(package)]
            if args.mudlet_exe:
                command.extend(['--exe', str(args.mudlet_exe)])
            return subprocess.run(command, cwd=ROOT).returncode
    return 0


if __name__ == '__main__':
    sys.exit(main())
