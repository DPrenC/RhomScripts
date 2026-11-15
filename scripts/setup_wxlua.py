"""Compila wxLua x64 contra el Lua de Mudlet, sin cambiar la instalación del cliente.

Fuentes y herramientas se conservan en .tools/wxlua-build. Solo wx.dll,
licencias y procedencia se instalan en rhomscripts/lib/windows-x64/wxlua.
"""
from __future__ import annotations

import argparse
import concurrent.futures
from hashlib import sha256
import importlib.metadata
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import zipfile

import requests

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / '.tools/wxlua-build'
DESTINATION = ROOT / 'rhomscripts/lib/windows-x64/wxlua'
WXLUA_COMMIT = 'd80dddbd78a1f93ea5f40e163f6d246da28a65ed'
SOURCES = {
    'toolchain.zip': (
        'https://github.com/mstorsjo/llvm-mingw/releases/download/20261104/llvm-mingw-20261104-ucrt-x86_64.zip',
        '552191b5754c49a5a20723276a6fc56541ea1922c4c50b7b669022333fc1b40f'),
    'wxwidgets.tar.bz2': (
        'https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.8/wxWidgets-3.2.8.tar.bz2',
        'c74784904109d7229e6894c85cfa068f1106a4a07c144afd78af41f373ee0fe6'),
    'wxlua.zip': (
        f'https://codeload.github.com/pkulchenko/wxlua/zip/{WXLUA_COMMIT}',
        '7409ae4383c448a6e97205e4df7e1ffa28f592135aebf2b9a9e669835bb223cc'),
    'lua.tar.gz': (
        'https://www.lua.org/ftp/lua-5.1.5.tar.gz',
        '2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333'),
}
REQUIREMENTS = {'cmake': '4.4.4', 'ninja': '1.13.2', 'pefile': '2024.8.26'}


def prepare_python_tools() -> None:
    for package, version in REQUIREMENTS.items():
        try:
            installed = importlib.metadata.version(package)
        except importlib.metadata.PackageNotFoundError:
            installed = None
        if installed != version:
            subprocess.run([sys.executable, '-m', 'pip', 'install', f'{package}=={version}'], check=True)


def download_and_extract(entry: tuple[str, tuple[str, str]]) -> dict:
    name, (url, digest) = entry
    archive = BUILD / name
    if not archive.exists():
        response = requests.get(url, timeout=180)
        response.raise_for_status()
        archive.write_bytes(response.content)
    actual = sha256(archive.read_bytes()).hexdigest()
    assert actual == digest, f'SHA-256 incorrecto: {archive}'
    target = BUILD / name.split('.')[0]
    if not target.exists():
        target.mkdir()
        if name.endswith('.zip'):
            with zipfile.ZipFile(archive) as source:
                for member in source.namelist():
                    assert (target / member).resolve().is_relative_to(target.resolve()), member
                source.extractall(target)
        else:
            with tarfile.open(archive) as source:
                source.extractall(target, filter='data')
    print(f'Verificado: {name}', flush=True)
    return {'archive': name, 'url': url, 'sha256': digest}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua-dll', type=Path,
                        help='DLL Lua de la instalación real que se utilizará; no se copia ni modifica.')
    parser.add_argument('--jobs', type=int, default=4)
    args = parser.parse_args()
    assert os.name == 'nt', 'Esta compilación produce controles nativos de Windows x64.'
    if args.lua_dll is None:
        response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
        response.raise_for_status()
        release = response.json()
        assert not release['prerelease'] and not release['draft']
        version = release['tag_name'].removeprefix('Mudlet-')
        args.lua_dll = Path(os.environ['LOCALAPPDATA']) / f'Mudlet_64_/app-{version}/lua51.dll'
    assert args.lua_dll.is_file(), str(args.lua_dll)
    assert args.lua_dll.name.lower() == 'lua51.dll', 'Se requiere el runtime Lua 5.1 de Mudlet.'
    assert args.jobs > 0
    BUILD.mkdir(parents=True, exist_ok=True)
    prepare_python_tools()
    import pefile
    import cmake
    import ninja

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        sources = list(executor.map(download_and_extract, SOURCES.items()))
    toolchain = BUILD / 'toolchain/llvm-mingw-20261104-ucrt-x86_64'
    tools = toolchain / 'bin'
    cmake_exe = Path(cmake.CMAKE_BIN_DIR) / 'cmake.exe'
    ninja_exe = Path(ninja.BIN_DIR) / 'ninja.exe'
    cmake_modules = Path(cmake.__file__).parent / 'data/share/cmake-4.4/Modules'
    env = os.environ.copy()
    env['PATH'] = str(tools) + ';' + str(ninja_exe.parent) + ';' + env['PATH']

    def run(command: list, logfile: str) -> None:
        print(f'Ejecutando: {logfile}', flush=True)
        with (BUILD / logfile).open('w', encoding='utf-8') as log:
            result = subprocess.run([str(value) for value in command], env=env,
                                    stdout=log, stderr=subprocess.STDOUT)
        if result.returncode:
            print((BUILD / logfile).read_text(encoding='utf-8')[-12000:])
            raise RuntimeError(f'Falló {logfile}, código {result.returncode}')

    lua_pe = pefile.PE(str(args.lua_dll))
    assert lua_pe.FILE_HEADER.Machine == 0x8664, 'La DLL Lua debe ser AMD64.'
    lua_exports = [item.name.decode() for item in lua_pe.DIRECTORY_ENTRY_EXPORT.symbols if item.name]
    assert {'luaL_register', 'lua_objlen', 'lua_gettop'} <= set(lua_exports), 'No es la ABI Lua 5.1 esperada.'
    definition = BUILD / 'lua51.def'
    definition.write_text('LIBRARY lua51.dll\nEXPORTS\n' + '\n'.join(lua_exports) + '\n')
    import_library = BUILD / 'liblua51.a'
    run([tools / 'llvm-dlltool.exe', '-m', 'i386:x86-64', '-d', definition,
         '-l', import_library], 'lua-import.log')
    toolchain_file = BUILD / 'llvm.cmake'
    # Se compila nativamente en Windows: no declarar cross-compilación.
    toolchain_file.write_text('\n'.join([
        f'set(CMAKE_C_COMPILER "{(tools / "x86_64-w64-mingw32-clang.exe").as_posix()}")',
        f'set(CMAKE_CXX_COMPILER "{(tools / "x86_64-w64-mingw32-clang++.exe").as_posix()}")',
        f'set(CMAKE_RC_COMPILER "{(tools / "x86_64-w64-mingw32-windres.exe").as_posix()}")',
        f'set(CMAKE_AR "{(tools / "llvm-ar.exe").as_posix()}")',
        f'set(CMAKE_RANLIB "{(tools / "llvm-ranlib.exe").as_posix()}")',
    ]) + '\n')
    wx_source = BUILD / 'wxwidgets/wxWidgets-3.2.8'
    wx_build = BUILD / 'wx-build'
    wx_install = BUILD / 'wx-install'
    common = ['-G', 'Ninja', f'-DCMAKE_TOOLCHAIN_FILE={toolchain_file.as_posix()}',
              f'-DCMAKE_MAKE_PROGRAM={ninja_exe.as_posix()}', '-DCMAKE_BUILD_TYPE=Release']
    wx_options = ['-DBUILD_SHARED_LIBS=OFF', '-DwxBUILD_SHARED=OFF', '-DwxBUILD_PRECOMP=ON',
                  '-DwxBUILD_TESTS=OFF', '-DwxBUILD_SAMPLES=OFF', '-DwxBUILD_DEMOS=OFF',
                  '-DwxBUILD_DEBUG_LEVEL=0', '-DwxBUILD_COMPATIBILITY=3.0',
                  '-DwxUSE_ACCESSIBILITY=ON', '-DwxUSE_UNICODE=ON',
                  '-DCMAKE_CXX_FLAGS=-static-libstdc++',
                  f'-DCMAKE_INSTALL_PREFIX={wx_install.as_posix()}']
    for feature in ['STC', 'WEBVIEW', 'MEDIACTRL', 'GLCANVAS', 'RICHTEXT', 'RIBBON',
                    'PROPGRID', 'AUI', 'HTML', 'XRC', 'WXHTML_HELP']:
        wx_options.append(f'-DwxUSE_{feature}=OFF')
    run([cmake_exe, '-S', wx_source, '-B', wx_build, *common, *wx_options], 'wx-configure.log')
    run([cmake_exe, '--build', wx_build, '--parallel', args.jobs], 'wx-build.log')
    run([cmake_exe, '--install', wx_build], 'wx-install.log')
    wxlua_source = BUILD / f'wxlua/wxlua-{WXLUA_COMMIT}/wxLua'
    wxlua_build = BUILD / 'wxlua-build-native'
    wxlua_options = [
        '-DCMAKE_POLICY_VERSION_MINIMUM=3.5', '-DBUILD_SHARED_LIBS=OFF',
        '-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON',
        f'-DwxWidgets_DIR={(wx_install / "lib/cmake/wxWidgets").as_posix()}',
        f'-DwxWidgets_USE_FILE={(cmake_modules / "UsewxWidgets.cmake").as_posix()}',
        '-DwxWidgets_COMPONENTS=net;core;base', '-DwxLuaBind_COMPONENTS=core;base',
        f'-DwxWidgets_ROOT_DIR={wx_source.as_posix()}',
        f'-DwxWidgets_LIB_DIR={(wx_build / "lib/clang_x64_lib").as_posix()}',
        '-DwxWidgets_CONFIGURATION=mswu', '-DwxWidgets_USE_STATIC=ON',
        '-DwxWidgets_USE_UNICODE=ON', '-DwxWidgets_USE_DEBUG=OFF',
        '-DwxLua_LUA_LIBRARY_USE_BUILTIN=OFF', '-DwxLua_LUA_LIBRARY_VERSION=5.1',
        f'-DwxLua_LUA_INCLUDE_DIR={(BUILD / "lua/lua-5.1.5/src").as_posix()}',
        f'-DwxLua_LUA_LIBRARY={import_library.as_posix()}',
        '-DCMAKE_SHARED_LINKER_FLAGS=-static -static-libstdc++ -Wl,--no-insert-timestamp',
        '-DCMAKE_CXX_FLAGS=-Wno-deprecated-declarations -DwxLUA_USE_wxHelpController=0 -DwxDEBUG_LEVEL=0',
    ]
    run([cmake_exe, '-S', wxlua_source, '-B', wxlua_build, *common, *wxlua_options], 'wxlua-configure.log')
    run([cmake_exe, '--build', wxlua_build, '--target', 'wxLuaModule', '--parallel', args.jobs],
        'wxlua-build.log')
    candidates = list(wxlua_build.rglob('*wx.dll'))
    assert len(candidates) == 1, [str(path) for path in candidates]
    dll = candidates[0]
    binary = pefile.PE(str(dll))
    assert binary.FILE_HEADER.Machine == 0x8664
    imports = sorted(entry.dll.decode() for entry in binary.DIRECTORY_ENTRY_IMPORT)
    exports = [item.name.decode() for item in binary.DIRECTORY_ENTRY_EXPORT.symbols if item.name]
    assert 'luaopen_wx' in exports
    assert 'lua51.dll' in [name.lower() for name in imports]
    assert not any(name.lower().startswith(('libc++', 'libunwind', 'libwinpthread', 'libgcc'))
                   for name in imports), imports
    DESTINATION.mkdir(parents=True, exist_ok=True)
    installed_dll = DESTINATION / 'wx.dll'
    # No sustituir una DLL idéntica: Windows puede tenerla cargada en Mudlet.
    if not installed_dll.exists() or sha256(installed_dll.read_bytes()).digest() != sha256(dll.read_bytes()).digest():
        shutil.copy2(dll, installed_dll)
    license_files = {
        'wxLua-licence.txt': wxlua_source / 'docs/licence.txt',
        'wxWidgets-licence.txt': wx_source / 'docs/licence.txt',
        'LLVM-runtime-LICENSE.txt': toolchain / 'LICENSE.TXT',
        'zlib-LICENSE.txt': wx_source / 'src/zlib/LICENSE',
        'libpng-LICENSE.txt': wx_source / 'src/png/LICENSE',
        'libjpeg-README.txt': wx_source / 'src/jpeg/README',
        'libtiff-COPYRIGHT.txt': wx_source / 'src/tiff/COPYRIGHT',
        'expat-COPYING.txt': wx_source / 'src/expat/expat/COPYING',
        'PCRE2-LICENCE.txt': wx_source / '3rdparty/pcre/LICENCE',
        'NanoSVG-LICENSE.txt': wx_source / '3rdparty/nanosvg/LICENSE.txt',
    }
    licenses = DESTINATION / 'licenses'
    licenses.mkdir(exist_ok=True)
    for name, source in license_files.items():
        shutil.copy2(source, licenses / name)
    manifest = {
        'wxLua': {'version': '3.2.0.2', 'commit': WXLUA_COMMIT, 'bindings': ['core', 'base']},
        'wxWidgets': {'version': '3.2.8', 'port': 'msw', 'unicode': True, 'accessibility': True,
                      'link': 'static'},
        'platform': 'windows-x64', 'toolchain': 'LLVM-MinGW 20261104 UCRT x86_64',
        'build_tools': REQUIREMENTS, 'sources': sources,
        'lua_host': {'filename': args.lua_dll.name, 'sha256': sha256(args.lua_dll.read_bytes()).hexdigest(),
                     'imported_runtime': 'lua51.dll', 'headers': 'Lua 5.1.5'},
        'wx.dll': {'sha256': sha256(dll.read_bytes()).hexdigest(), 'bytes': dll.stat().st_size,
                   'imports': imports, 'exports_checked': ['luaopen_wx']},
        'notes': ['No se incluye ni sustituye lua51.dll.',
                  'No modifica Mudlet, PATH del sistema ni el índice Git.',
                  'La carga y el comportamiento requieren validación real independiente.'],
    }
    (DESTINATION / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n',
                                            encoding='utf-8')
    print(f'Instalado: {DESTINATION / "wx.dll"}', flush=True)
    print(json.dumps(manifest['wx.dll'], indent=2), flush=True)


if __name__ == '__main__':
    main()
