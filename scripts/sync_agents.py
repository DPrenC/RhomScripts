"""Genera adaptadores equivalentes de Codex y Copilot desde un contrato común."""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
GENERATED_MARKER = 'Perfil generado por scripts/sync_agents.py desde doc/agentes/roles.json.'
AGENT_PATTERNS = {'.github/agents': '*.agent.md', '.codex/agents': '*.toml'}


def expected_files(roles):
    for role in roles:
        instructions = (
            GENERATED_MARKER + '\n\n'
            'Aplicar el flujo documental de AGENTS.md y doc/contexto-multiagente.md. '
            'Aportar al coordinador el estado del plan, los cambios y las evidencias que correspondan al rol.\n\n'
            + role['instructions'] + '\n'
        )
        header = ('---\nname: ' + json.dumps(role['name'], ensure_ascii=False)
                  + '\ndescription: ' + json.dumps(role['description'], ensure_ascii=False)
                  + '\ntarget: github-copilot\ntools: ' + json.dumps(role['tools']) + '\nuser-invocable: true\n---\n')
        yield ROOT / '.github/agents' / (role['id'] + '.agent.md'), header + instructions
        # JSON strings are valid TOML basic strings; inheriting model and permissions is intentional.
        toml = ('name = ' + json.dumps(role['id'].replace('-', '_'))
                + '\ndescription = ' + json.dumps(role['description'], ensure_ascii=False)
                + '\ndeveloper_instructions = ' + json.dumps(instructions, ensure_ascii=False) + '\n')
        yield ROOT / '.codex/agents' / (role['id'] + '.toml'), toml


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    roles = json.loads((ROOT / 'doc/agentes/roles.json').read_text(encoding='utf-8'))
    if any(not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', role['id']) for role in roles):
        parser.error('Los identificadores deben usar letras minúsculas, números y guiones.')
    expected = dict(expected_files(roles))
    if len(expected) != len(roles) * len(AGENT_PATTERNS):
        parser.error('Hay identificadores de rol duplicados.')
    obsolete = sorted(
        path for folder, pattern in AGENT_PATTERNS.items()
        for path in (ROOT / folder).glob(pattern)
        if path not in expected and GENERATED_MARKER in path.read_text(encoding='utf-8-sig')
    )
    if obsolete:
        print('Retira los perfiles generados sobrantes: ' + ', '.join(str(path.relative_to(ROOT)) for path in obsolete))
        return 1
    mismatches = []
    for path, text in expected.items():
        current = path.read_text(encoding='utf-8-sig') if path.is_file() else None
        if (args.check and current != text) or (current is not None and GENERATED_MARKER not in current):
            mismatches.append(str(path.relative_to(ROOT)))
    if mismatches:
        print('Perfiles desincronizados: ' + ', '.join(mismatches))
        return 1
    if not args.check:
        for path, text in expected.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding='utf-8', newline='\n')
    print(f'Perfiles Codex/Copilot sincronizados: {len(roles)} roles, {len(expected)} adaptadores.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
