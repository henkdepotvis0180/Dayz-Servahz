"""Build one offline Windows updater containing only changes since the stable base."""
import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
BASE = 'v0.13.0'
PUBLIC = ('01-Instellen.cmd', '02-Start-server.cmd', '03-Controleren.cmd',
          '04-Teststand.cmd', '05-Loot-proefscan.cmd', '06-Loot-verversen.cmd', 'AGENTS.md', 'CHANGELOG.md', 'README.md', 'Mods.html')


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def snapshot(ref):
    names = git('ls-tree', '-r', '--name-only', ref).decode().splitlines()
    return {name: git('show', f'{ref}:{name}') for name in names
            if name in PUBLIC or name.startswith(('scripts/', 'config/'))
            if name != 'config/server.local.json'}


def hashes(files):
    return {name: hashlib.sha256(data).hexdigest() for name, data in files.items()}


def render(version, base_files, target_files, states):
    removed = set(base_files) - set(target_files)
    if removed:
        raise ValueError('File removals require an explicit migration: ' + ', '.join(sorted(removed)))
    changed = {name: data for name, data in target_files.items() if base_files.get(name) != data}
    manifest = {'version': version, 'base': BASE, 'states': states,
                'files': hashes(changed)}
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in changed.items():
            archive.writestr(name, data)
    payload = stream.getvalue()
    script = (ROOT / 'updates/Apply-Update.ps1').read_text(encoding='utf-8')
    script = script.replace('__MANIFEST__', json.dumps(manifest, separators=(',', ':')))
    script = script.replace('__PAYLOAD_SHA256__', hashlib.sha256(payload).hexdigest())
    script = script.replace('__PAYLOAD__', base64.b64encode(payload).decode())
    launcher = '''@echo off
setlocal
set "SERVAHZ_UPDATE_FILE=%~f0"
set "SERVAHZ_UPDATE_ROOT=%~1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$lines=[IO.File]::ReadAllLines($env:SERVAHZ_UPDATE_FILE); $i=[Array]::IndexOf($lines,'# SERVAHZ_POWERSHELL'); & ([scriptblock]::Create(($lines[($i+1)..($lines.Length-1)] -join [Environment]::NewLine))) -PackagePath $env:SERVAHZ_UPDATE_ROOT"
set "SERVAHZ_UPDATE_EXIT=%ERRORLEVEL%"
if not "%SERVAHZ_UPDATE_EXIT%"=="0" echo Update mislukt. Lees de melding hierboven.
pause
exit /b %SERVAHZ_UPDATE_EXIT%
# SERVAHZ_POWERSHELL
'''
    return launcher + script, manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('version')
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if not re.fullmatch(r'v\d+\.\d+\.\d+', args.version):
        parser.error('Expected vMAJOR.MINOR.PATCH')
    target = snapshot('HEAD')
    base = snapshot(BASE)
    version_tuple = lambda value: tuple(map(int, value[1:].split('.')))
    tags = git('tag', '--list', 'v*').decode().splitlines()
    states = []
    for tag in sorted(tags):
        if re.fullmatch(r'v\d+\.\d+\.\d+', tag) and version_tuple(BASE) <= version_tuple(tag) < version_tuple(args.version):
            states.append({'version': tag, 'files': hashes(snapshot(tag))})
    states.append({'version': args.version, 'files': hashes(target)})
    command, manifest = render(args.version, base, target, states)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(command.replace('\r\n', '\n').replace('\n', '\r\n').encode('utf-8'))
    print(f'{args.output.name}: {len(manifest["files"])} changed files since {BASE}; no game files or local settings.')


if __name__ == '__main__':
    main()
