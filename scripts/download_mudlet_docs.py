"""Actualiza copias oficiales y un índice local sin sustituir manuales anteriores."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from hashlib import sha256
import json
from pathlib import Path
import re

from bs4 import BeautifulSoup
import requests

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'doc' / 'mudlet'
PAGES = [
    'Lua_Functions', 'Mudlet_Object_Functions', 'Miscellaneous_Functions',
    'Basic_Essentials', 'File_System_Functions', 'Table_Functions',
    'String_Functions', 'Trigger_Engine', 'Event_Engine', 'Introduction',
]


def download(page):
    url = 'https://wiki.mudlet.org/w/Manual:' + page
    response = requests.get(url, timeout=90)
    response.raise_for_status()
    soup = BeautifulSoup(response.content, 'html.parser')
    content = soup.select_one('.mw-parser-output')
    if content is None or soup.select_one('.noarticletext'):
        raise RuntimeError(f'Página oficial sin contenido: {url}')
    (DEST / f'{page}.html').write_bytes(response.content)
    for node in content.select('.toc, .mw-editsection, script, style'):
        node.decompose()
    # Las tablas se leen por entradas, conservando asociación con sus cabeceras.
    for table in content.find_all('table'):
        rows = table.find_all('tr')
        headers = [cell.get_text(' ', strip=True) for cell in rows[0].find_all(['th', 'td'])] if rows else []
        blocks = []
        for row in rows[1:]:
            cells = [cell.get_text(' ', strip=True) for cell in row.find_all(['th', 'td'], recursive=False)]
            if cells:
                blocks.append('\n'.join(f'{headers[i] if i < len(headers) else "Campo " + str(i + 1)}: {value}' for i, value in enumerate(cells)))
        table.replace_with('\n' + '\n\n'.join(blocks) + '\n')
    for image in content.find_all('img'):
        image.replace_with(image.get('alt', ''))
    for heading in content.find_all(re.compile(r'^h[1-6]$')):
        heading.replace_with('\n\n' + '#' * int(heading.name[1]) + ' ' + heading.get_text(' ', strip=True) + '\n')
    text = content.get_text('\n', strip=False)
    text = re.sub(r'\n[ \t]*\n(?:[ \t]*\n)+', '\n\n', text).strip()
    header = f'Mudlet: {page}\n\nFuente oficial: {response.url}\nCopia consultable; véase manifest.json para fecha, hash y atribución.\n\n'
    (DEST / f'{page}.txt').write_text(header + text + '\n', encoding='utf-8')
    print(f'Documentación: {page}', flush=True)
    return {'page': page, 'url': response.url, 'html': f'{page}.html', 'text': f'{page}.txt',
            'sha256': sha256(response.content).hexdigest(),
            'retrieved_utc': datetime.now(timezone.utc).isoformat(),
            'license': 'Contenido de Mudlet Wiki: consultar aviso de licencia y atribución en el HTML original.'}


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        entries = list(pool.map(download, PAGES))
    release_response = requests.get('https://api.github.com/repos/Mudlet/Mudlet/releases/latest', timeout=45)
    release_response.raise_for_status()
    release = release_response.json()
    assert not release['draft'] and not release['prerelease']
    key_url = f'https://raw.githubusercontent.com/Mudlet/Mudlet/{release["tag_name"]}/src/mudlet-lua/lua/KeyCodes.lua'
    keys = requests.get(key_url, timeout=45)
    keys.raise_for_status()
    (DEST / 'KeyCodes.lua').write_bytes(keys.content)
    (DEST / 'keycodes-source.json').write_text(json.dumps({'url': key_url, 'release': release['tag_name'],
                                                         'sha256': sha256(keys.content).hexdigest()}, indent=2) + '\n', encoding='utf-8')
    license_url = f'https://raw.githubusercontent.com/Mudlet/Mudlet/{release["tag_name"]}/COPYING'
    license_response = requests.get(license_url, timeout=45)
    license_response.raise_for_status()
    (DEST / 'COPYING-Mudlet.txt').write_bytes(license_response.content)
    (DEST / 'license-source.json').write_text(json.dumps({'url': license_url, 'release': release['tag_name'],
                                                         'sha256': sha256(license_response.content).hexdigest()}, indent=2) + '\n', encoding='utf-8')
    (DEST / 'release.json').write_text(json.dumps({'tag': release['tag_name'], 'url': release['html_url'],
                                                  'verified_utc': datetime.now(timezone.utc).isoformat()}, indent=2) + '\n', encoding='utf-8')
    (DEST / 'manifest.json').write_text(json.dumps(entries, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    index = '# Documentación oficial de Mudlet\n\nCopias descargadas de Mudlet Wiki. Se conservan los HTML originales con sus avisos de licencia y atribución y una extracción de texto para búsqueda accesible. Los manuales anteriores de `doc/` permanecen intactos.\n\n'
    index += '\n'.join(f'- [{entry["page"]}]({entry["text"]}): [fuente oficial]({entry["url"]}).' for entry in entries)
    index += '\n\nActualización: `.\\scripts\\update_docs.ps1`. Fecha de descarga y SHA-256: [manifest.json](manifest.json). La wiki es una referencia cambiante; una API nueva no demuestra que exista en una versión anterior instalada.\n'
    index += '\n[Códigos de teclado oficiales](KeyCodes.lua), descargados de la última release estable: [procedencia y hash](keycodes-source.json). Código de los autores de Mudlet; se conserva el original y su [archivo de licencia](COPYING-Mudlet.txt), con [procedencia](license-source.json). [Release consultada](release.json). Los avisos de licencia de la wiki se conservan en sus HTML originales.\n'
    (DEST / 'README.md').write_text(index, encoding='utf-8')


if __name__ == '__main__':
    main()
