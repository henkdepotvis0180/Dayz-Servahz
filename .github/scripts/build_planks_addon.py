"""Build the small client/server addon; the signing key stays outside the repo.

Requires armake2 (https://github.com/KoffeinFlummi/armake2), with the adjacent
armake2-dayz-v3.patch applied to its src/sign.rs, and an existing BI private
key named ServahzPlanks01814. The patch switches the v3 extension policy from
Arma to DayZ (including .c scripts). No vendor PBOs/assets are repacked.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / 'config/local-mods/@ServahzPlanks'


def verify_dayz_script_hash(public, signature):
    """Independently reject an Arma-policy signer for our uncompressed source PBO."""
    key = public.read_bytes()
    offset = key.index(0) + 1
    bits, exponent = struct.unpack_from('<II', key, offset + 16)
    size = bits // 8
    modulus = int.from_bytes(key[offset + 24:offset + 24 + size], 'little')
    files = sorted((p.relative_to(ADDON / 'source').as_posix().replace('/', '\\').lower(), p.read_bytes())
                   for p in (ADDON / 'source').rglob('*') if p.is_file())
    sha1 = lambda value: hashlib.sha1(value).digest()
    names = sha1(b''.join(name.encode() for name, data in files if data))
    selected = [data for name, data in files if data and name.rsplit('.', 1)[-1] in {'bikb', 'c', 'ext', 'hpp', 'cfg', 'h', 'inc'}]
    file_hash = sha1(b''.join(selected) if selected else b'gnihton')
    digest = sha1(file_hash + names + b'Servahz\\Planks\\')
    expected = b'\0\x01' + b'\xff' * (size - 38) + bytes.fromhex('003021300906052b0e03021a05000414') + digest
    sig3 = int.from_bytes(signature.read_bytes()[-size:], 'little')
    if pow(sig3, exponent, modulus).to_bytes(size, 'big') != expected:
        raise RuntimeError('Signer did not use the DayZ v3 .c script policy; apply armake2-dayz-v3.patch before building.')


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
    verify_dayz_script_hash(public, signature)
    names = [pbo, signature, public]
    manifest = {p.relative_to(ADDON).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in names}
    (ADDON / 'files.json').write_text(json.dumps(manifest, indent=2) + '\n')


if __name__ == '__main__':
    main()
