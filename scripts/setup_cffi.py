"""Compila cffi-lua para el Lua 5.1 de Mudlet en Windows x64.

Reutiliza herramientas y cabeceras preparadas por setup_wxlua.py. No instala
otro Lua ni modifica Mudlet. Fuentes y compilación quedan en .tools/cffi-build.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
import importlib.metadata
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile

import requests

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / '.tools/cffi-build'
DESTINATION = ROOT / 'rhomscripts/lib/windows-x64/cffi'
CFFI_COMMIT = '1d6d54b4068eefc6dc4c4455175b6d0e530fa72a'
LIBFFI_COMMIT = '41fc1ec58b987922d66bdc7a7531d3a1b34b3983'
SOURCES = {
    'cffi': ('q66/cffi-lua', CFFI_COMMIT,
             'b5f1a22786be067c19d06ce1512178241e86349a8d961dac01487eeeed3d7f0e'),
    'libffi': ('xclaesse/libffi', LIBFFI_COMMIT,
               'bfb117ec3fe114a8257b38836762558d1da5f553c069f80f073178ab596b5f7d'),
}
REQUIREMENTS = {'meson': '1.12.1', 'ninja': '1.13.2', 'pefile': '2024.8.26'}


def prepare_tools() -> None:
    for name, version in REQUIREMENTS.items():
        try:
            installed = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            installed = None
        if installed != version:
            subprocess.run([sys.executable, '-m', 'pip', 'install', f'{name}=={version}'], check=True)


def source(name: str) -> tuple[Path, dict]:
    repository, commit, digest = SOURCES[name]
    url = f'https://codeload.github.com/{repository}/zip/{commit}'
    archive = BUILD / f'{name}.zip'
    if not archive.exists():
        response = requests.get(url, timeout=180)
        response.raise_for_status()
        archive.write_bytes(response.content)
    assert sha256(archive.read_bytes()).hexdigest() == digest, f'SHA-256 incorrecto: {archive}'
    target = BUILD / name
    if not target.exists():
        target.mkdir()
        with zipfile.ZipFile(archive) as package:
            for member in package.namelist():
                assert (target / member).resolve().is_relative_to(target.resolve()), member
            package.extractall(target)
    extracted = target / f'{repository.split("/")[1]}-{commit}'
    assert extracted.is_dir(), str(extracted)
    return extracted, {'repository': repository, 'commit': commit, 'url': url, 'sha256': digest}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua-dll', type=Path)
    parser.add_argument('--jobs', type=int, default=4)
    args = parser.parse_args()
    assert os.name == 'nt', 'Esta compilación requiere Windows x64.'
    assert args.jobs > 0
    if args.lua_dll is None:
        response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
        response.raise_for_status()
        release = response.json()
        assert not release['draft'] and not release['prerelease']
        version = release['tag_name'].removeprefix('Mudlet-')
        args.lua_dll = Path(os.environ['LOCALAPPDATA']) / f'Mudlet_64_/app-{version}/lua51.dll'
    assert args.lua_dll.is_file() and args.lua_dll.name.lower() == 'lua51.dll', str(args.lua_dll)
    shared = ROOT / '.tools/wxlua-build'
    toolchain = shared / 'toolchain/llvm-mingw-20261104-ucrt-x86_64'
    tools = toolchain / 'bin'
    lua_headers = shared / 'lua/lua-5.1.5/src'
    assert (tools / 'clang.exe').is_file() and (lua_headers / 'lua.h').is_file(), (
        'Preparar primero las herramientas con scripts/setup_wxlua.py')
    BUILD.mkdir(parents=True, exist_ok=True)
    prepare_tools()
    import ninja
    import pefile

    cffi_source, cffi_origin = source('cffi')
    ffi_source, ffi_origin = source('libffi')
    # La rama mutable del wrap upstream se sustituye por su snapshot verificado.
    # No descargar nada durante la configuración ni alterar código de biblioteca.
    shutil.copytree(ffi_source, cffi_source / 'subprojects/libffi', dirs_exist_ok=True)
    deps = cffi_source / 'deps'
    shutil.copytree(lua_headers, deps / 'include', dirs_exist_ok=True)
    # Lua 5.1 distribuye su cabecera C++ en etc/, no en src/.
    shutil.copy2(lua_headers.parent / 'etc/lua.hpp', deps / 'include/lua.hpp')
    lua_pe = pefile.PE(str(args.lua_dll))
    assert lua_pe.FILE_HEADER.Machine == 0x8664, 'La DLL Lua debe ser AMD64.'
    exports = [item.name.decode() for item in lua_pe.DIRECTORY_ENTRY_EXPORT.symbols if item.name]
    assert {'luaL_register', 'lua_objlen', 'lua_gettop'} <= set(exports), 'ABI Lua 5.1 incorrecta'
    definition = BUILD / 'lua51.def'
    definition.write_text('LIBRARY lua51.dll\nEXPORTS\n' + '\n'.join(exports) + '\n', encoding='ascii')
    subprocess.run([str(tools / 'llvm-dlltool.exe'), '-m', 'i386:x86-64', '-d', str(definition),
                    '-l', str(deps / 'liblua51.a')], check=True)
    native_file = BUILD / 'llvm.ini'
    def quoted(path: Path) -> str:
        return "'" + path.as_posix().replace("'", "\\'") + "'"
    native_file.write_text('\n'.join([
        '[binaries]', f'c = {quoted(tools / "x86_64-w64-mingw32-clang.exe")}',
        f'cpp = {quoted(tools / "x86_64-w64-mingw32-clang++.exe")}',
        f'ar = {quoted(tools / "llvm-ar.exe")}',
        f'strip = {quoted(tools / "llvm-strip.exe")}',
        '[built-in options]', "c_link_args = ['-static', '-Wl,--no-insert-timestamp']",
        "cpp_link_args = ['-static', '-static-libstdc++', '-Wl,--no-insert-timestamp']",
    ]) + '\n', encoding='utf-8')
    environment = os.environ.copy()
    environment['PATH'] = str(tools) + ';' + str(Path(ninja.BIN_DIR)) + ';' + str(Path(sys.executable).parent) + ';' + environment['PATH']
    def run(command: list[str], logname: str) -> None:
        print(f'Ejecutando: {logname}', flush=True)
        log = BUILD / logname
        with log.open('w', encoding='utf-8') as output:
            result = subprocess.run(command, env=environment, stdout=output, stderr=subprocess.STDOUT)
        if result.returncode:
            print(log.read_text(encoding='utf-8')[-16000:])
            raise RuntimeError(f'Falló {logname}: {result.returncode}')
    build_dir = BUILD / 'build'
    configure = [sys.executable, '-m', 'mesonbuild.mesonmain', 'setup', str(build_dir), str(cffi_source),
                 '--native-file', str(native_file), '--buildtype=release', '--wrap-mode=nodownload',
                 '--force-fallback-for=libffi',
                 '-Dlua_version=vendor', '-Dtests=false', '-Dlibffi=auto',
                 '-Dlibffi:default_library=static', '-Dlibffi:tests=false']
    if (build_dir / 'meson-private/coredata.dat').exists():
        configure.append('--reconfigure')
    run(configure, 'configure.log')
    run([sys.executable, '-m', 'mesonbuild.mesonmain', 'compile', '-C', str(build_dir), '-j', str(args.jobs)],
        'compile.log')
    dll = build_dir / 'cffi.dll'
    assert dll.is_file(), str(dll)
    binary = pefile.PE(str(dll))
    assert binary.FILE_HEADER.Machine == 0x8664
    imports = sorted(item.dll.decode() for item in binary.DIRECTORY_ENTRY_IMPORT)
    dll_exports = [item.name.decode() for item in binary.DIRECTORY_ENTRY_EXPORT.symbols if item.name]
    assert 'luaopen_cffi' in dll_exports
    assert 'lua51.dll' in [name.lower() for name in imports]
    assert not any(name.lower().startswith(('libffi', 'libc++', 'libunwind', 'libwinpthread', 'libgcc'))
                   for name in imports), imports
    DESTINATION.mkdir(parents=True, exist_ok=True)
    installed = DESTINATION / 'cffi.dll'
    if not installed.exists() or sha256(installed.read_bytes()).digest() != sha256(dll.read_bytes()).digest():
        shutil.copy2(dll, installed)
    licenses = DESTINATION / 'licenses'
    licenses.mkdir(exist_ok=True)
    for name, path in {
        'cffi-lua-COPYING.md': cffi_source / 'COPYING.md',
        'libffi-LICENSE': ffi_source / 'LICENSE',
        'LLVM-runtime-LICENSE.txt': toolchain / 'LICENSE.TXT',
    }.items():
        shutil.copy2(path, licenses / name)
    manifest = {
        'cffi-lua': {'version': '0.2.4', 'commit': CFFI_COMMIT},
        'libffi': {'version': '3.4.4', 'commit': LIBFFI_COMMIT, 'link': 'static',
                   'source': 'Snapshot del fork meson-port usado por el wrap oficial de cffi-lua'},
        'platform': 'windows-x64', 'toolchain': 'LLVM-MinGW 20261104 UCRT x86_64',
        'build_tools': REQUIREMENTS, 'sources': [cffi_origin, ffi_origin],
        'lua_host': {'filename': args.lua_dll.name, 'sha256': sha256(args.lua_dll.read_bytes()).hexdigest(),
                     'imported_runtime': 'lua51.dll', 'headers': 'Lua 5.1.5'},
        'cffi.dll': {'sha256': sha256(dll.read_bytes()).hexdigest(), 'bytes': dll.stat().st_size,
                     'imports': imports, 'exports_checked': ['luaopen_cffi']},
        'notes': ['No incluye ni sustituye Lua ni modifica Mudlet.',
                  'Las fuentes se verifican por SHA-256 antes de extraer.',
                  'La carga y llamadas Win32 requieren validación real independiente.'],
    }
    (DESTINATION / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Instalado: {installed}', flush=True)
    print(json.dumps(manifest['cffi.dll'], indent=2), flush=True)


if __name__ == '__main__':
    main()
