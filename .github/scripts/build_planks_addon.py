"""Build the small client/server addon; the signing key stays outside the repo.

Requires armake2 (https://github.com/KoffeinFlummi/armake2) and an existing
BI private key named ServahzPlanks01814. No vendor PBOs/assets are repacked.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / 'config/local-mods/@ServahzPlanks'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--armake', required=True, type=Path)
    parser.add_argument('--private-key', required=True, type=Path)
    parser.add_argument('--public-key', required=True, type=Path)
    args = parser.parse_args()
    def run(*command):
        subprocess.run([str(args.armake.resolve()), *map(str, command)], check=True)
    # Parse/compile the config as a separate check. Ship readable config.cpp.
    with tempfile.TemporaryDirectory() as folder:
        run('rapify', ADDON / 'source/config.cpp', Path(folder) / 'config.bin')
    pbo = ADDON / 'Addons/servahz_planks.pbo'
    signature = Path(str(pbo) + '.ServahzPlanks01814.bisign')
    run('pack', '-f', '-e', 'prefix=Servahz\\Planks', ADDON / 'source', pbo)
    run('sign', '-f', args.private_key.resolve(), pbo, signature)
    public = ADDON / 'Keys/ServahzPlanks01814.bikey'
    public.write_bytes(args.public_key.read_bytes())
    run('verify', public, pbo, signature)
    names = [pbo, signature, public]
    manifest = {p.relative_to(ADDON).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in names}
    (ADDON / 'files.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
