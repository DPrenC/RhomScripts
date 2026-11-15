"""Prueba el empaquetado aislado y el acceso concurrente a su salida."""
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]


def read_package_script(package):
    with ZipFile(package) as archive:
        assert set(archive.namelist()) == {'config.lua', 'rhomloader.xml'}
        xml = ET.fromstring(archive.read('rhomloader.xml'))
        script = xml.find('.//Script/script')
        assert script is not None and script.text
        assert 'PONER_RUTA_AQUI' not in script.text
        return script.text


def run(package_copy=None):
    environment = os.environ.copy()
    local_java = list((ROOT / '.tools/java').glob('*/bin/java.exe'))
    if local_java:
        environment['JAVA_HOME'] = str(local_java[0].parent.parent)
    assert local_java or shutil.which('java'), 'Ejecuta scripts/setup_validation.ps1 para preparar Java.'
    with tempfile.TemporaryDirectory(prefix='rhom-package-', dir=ROOT / '.tools') as folder:
        fixture = Path(folder)
        assert fixture.resolve().is_relative_to((ROOT / '.tools').resolve())
        shutil.copytree(ROOT / 'RhomLoader/src', fixture / 'RhomLoader/src')
        shutil.copy2(ROOT / 'RhomLoader/muddler.yml', fixture / 'RhomLoader/muddler.yml')
        shutil.copytree(ROOT / 'muddler', fixture / 'muddler')
        (fixture / 'scripts').mkdir()
        shutil.copy2(ROOT / 'scripts/package_rhomloader.ps1', fixture / 'scripts/package_rhomloader.ps1')
        source = fixture / 'RhomLoader/src/scripts/rhomloader/code.lua'
        before = source.read_bytes()
        command = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
                   str(fixture / 'scripts/package_rhomloader.ps1')]

        def build(scripts_path):
            return subprocess.run([*command, '-ScriptsPath', str(scripts_path)], cwd=fixture, env=environment,
                                  capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=90)

        result = build(ROOT / 'rhomscripts')
        assert result.returncode == 0, result.stdout + result.stderr
        assert source.read_bytes() == before, 'Se modificó el fuente tras empaquetar'
        package = fixture / 'RhomLoader/build/rhomloader.mpackage'
        assert (ROOT / 'rhomscripts').as_posix() + '/' in read_package_script(package)
        if package_copy is not None:
            shutil.copy2(package, package_copy)

        paths = [fixture / 'fuentes de prueba A', fixture / 'fuentes de prueba B']
        for path in paths:
            path.mkdir()
            (path / 'init.lua').touch()
        with ThreadPoolExecutor(max_workers=2) as pool:
            for result in pool.map(build, paths):
                assert result.returncode == 0, result.stdout + result.stderr
        assert source.read_bytes() == before, 'Dos empaquetados cambiaron el fuente'
        script = read_package_script(package)
        assert sum(path.as_posix() + '/' in script for path in paths) == 1, 'Las rutas se mezclaron'
        assert sorted(path.name for path in package.parent.iterdir()) == [package.name]

        previous_package = package.read_bytes()
        (fixture / 'muddler/bin/muddle.bat').write_text('@exit /b 17\n', encoding='ascii')
        failed = build(ROOT / 'rhomscripts')
        assert failed.returncode != 0, 'El fallo del build se presentó como éxito'
        assert source.read_bytes() == before, 'Se modificó el fuente tras un fallo'
        assert package.read_bytes() == previous_package, 'Un fallo modificó la salida anterior'
    return {'cases': ['Paquete XML válido con ruta local', 'Fuente intacto tras éxito',
                      'Dos empaquetados concurrentes con rutas distintas y ZIP final válido',
                      'El fallo del build conserva los fuentes y la salida anterior'],
            'isolation': 'Copia temporal; no se alteraron RhomLoader/build ni el índice del repositorio.'}


if __name__ == '__main__':
    print(json.dumps(run(), ensure_ascii=False, indent=2))
