"""Comprueba regeneración y perfiles retirados con un catálogo sintético."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run():
    with tempfile.TemporaryDirectory(prefix='rhom-agents-') as directory:
        root = Path(directory)
        script = root / 'scripts/sync_agents.py'
        script.parent.mkdir()
        shutil.copy2(Path(__file__).with_name(script.name), script)
        catalog = root / 'doc/agentes/roles.json'
        catalog.parent.mkdir(parents=True)
        role = {'id': 'rol-sintetico', 'name': 'Rol de prueba', 'description': 'Prueba de generación.',
                'tools': ['read'], 'instructions': 'Leer el contrato.'}
        catalog.write_text(json.dumps([role]), encoding='utf-8')

        def sync(*args):
            return subprocess.run([sys.executable, str(script), *args], capture_output=True, text=True,
                                  encoding='utf-8', env={**os.environ, 'PYTHONIOENCODING': 'utf-8'}, timeout=15)

        result = sync()
        assert result.returncode == 0 and '1 roles, 2 adaptadores' in result.stdout, result.stderr
        copilot_profile = root / '.github/agents/rol-sintetico.agent.md'
        assert 'target: github-copilot' in copilot_profile.read_text(encoding='utf-8')
        assert sync('--check').returncode == 0
        manual = root / '.codex/agents/manual.toml'
        manual.write_text('name = "manual"\n', encoding='utf-8')
        assert sync('--check').returncode == 0
        catalog.write_text('[]', encoding='utf-8')
        for args in [(), ('--check',)]:
            result = sync(*args)
            assert result.returncode == 1 and result.stdout.count('rol-sintetico') == 2, result.stdout
            assert 'manual.toml' not in result.stdout
        assert manual.read_text(encoding='utf-8') == 'name = "manual"\n'
        catalog.write_text(json.dumps([role]), encoding='utf-8')
        copilot_profile.write_text('Perfil manual en una ruta reservada.\n', encoding='utf-8')
        assert sync().returncode == 1
        assert copilot_profile.read_text(encoding='utf-8') == 'Perfil manual en una ruta reservada.\n'
    return 'Detecta perfiles retirados y conserva archivos manuales.'
