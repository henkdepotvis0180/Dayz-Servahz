"""Bundled PBO/signature and real installer checks; no native DayZ runtime."""
import hashlib
import io
import json
from pathlib import Path
import re
import struct
import shutil
import subprocess
import tempfile
import unittest
import test_package as package_tests

ROOT = package_tests.ROOT
ADDON = ROOT / 'config/local-mods/@ServahzPlanks'


def cstring(stream):
    data = bytearray()
    while True:
        value = stream.read(1)
        if not value:
            raise ValueError('Truncated string')
        if value == b'\0':
            return data.decode('ascii')
        data.extend(value)


def integer(stream):
    return struct.unpack('<I', stream.read(4))[0]


def pbo_contents(data):
    stream = io.BytesIO(data)
    headers, extensions = [], {}
    while True:
        name = cstring(stream)
        method, original, reserved, timestamp, size = struct.unpack('<5I', stream.read(20))
        if method == 0x56657273:
            while True:
                key = cstring(stream)
                if not key:
                    break
                extensions[key] = cstring(stream)
        elif not name:
            break
        else:
            if method != 0 or original != size:
                raise ValueError('Unexpected packing')
            headers.append((name, size))
    files = {name: stream.read(size) for name, size in headers}
    end = stream.tell()
    if stream.read(1) != b'\0' or stream.read(20) != hashlib.sha1(data[:end]).digest() or stream.read():
        raise ValueError('Invalid PBO checksum')
    return files, extensions, hashlib.sha1(data[:end]).digest()


def public_header(stream):
    name = cstring(stream)
    size = integer(stream)
    if stream.read(12) != b'\x06\x02\0\0\0\x24\0\0RSA1':
        raise ValueError('Invalid public key header')
    bits, exponent = integer(stream), integer(stream)
    if size != bits // 8 + 20:
        raise ValueError('Invalid public key length')
    modulus = int.from_bytes(stream.read(bits // 8), 'little')
    return name, bits, exponent, modulus


def verify_signature(pbo, key, signature):
    files, extensions, checksum = pbo_contents(pbo)
    public = public_header(io.BytesIO(key))
    stream = io.BytesIO(signature)
    if public_header(stream) != public:
        raise ValueError('Different public key')
    signatures = []
    bits, exponent, modulus = public[1:]
    for i in range(3):
        if i == 1 and integer(stream) != 3:
            raise ValueError('Expected v3 signature')
        if integer(stream) != bits // 8:
            raise ValueError('Invalid signature length')
        signatures.append(int.from_bytes(stream.read(bits // 8), 'little'))
    if stream.read():
        raise ValueError('Trailing signature data')
    sha1 = lambda x: hashlib.sha1(x).digest()
    names = sha1(b''.join(name.lower().encode() for name in sorted(files, key=str.lower) if files[name]))
    prefix = extensions['prefix'].rstrip('\\').encode() + b'\\'
    # DayZ v3 includes Enforce .c scripts. Arma's extension list differs;
    # a signature created with that policy must fail this independent check.
    selected = [data for name, data in files.items() if name.rsplit('.', 1)[-1].lower() in {'bikb', 'c', 'ext', 'hpp', 'cfg', 'h', 'inc'} and data]
    file_hash = sha1(b''.join(selected) if selected else b'gnihton')
    hashes = [checksum, sha1(checksum + names + prefix), sha1(file_hash + names + prefix)]
    for sig, digest in zip(signatures, hashes):
        padded = b'\0\x01' + b'\xff' * (bits // 8 - 38) + bytes.fromhex('003021300906052b0e03021a05000414') + digest
        if pow(sig, exponent, modulus).to_bytes(bits // 8, 'big') != padded:
            raise ValueError('Signature mismatch')


def parse_patch(text):
    """Read only the small patch grammar; rejects unexpected executable fields."""
    text = re.sub(r'//[^\n]*', '', text)
    tokens = re.findall(r'"[^"\n]*"|[A-Za-z_][A-Za-z_0-9]*|\d+(?:\.\d+)?|[^\s]', text)
    pos = 0
    def block():
        nonlocal pos
        result = {}
        while pos < len(tokens) and tokens[pos] != '}':
            token = tokens[pos]; pos += 1
            if token == 'class':
                name = tokens[pos]; pos += 1
                if tokens[pos] == ':':
                    pos += 2
                if tokens[pos] == ';':
                    pos += 1
                    continue
                assert tokens[pos] == '{'; pos += 1
                result[name] = block()
                assert tokens[pos:pos+2] == ['}', ';']; pos += 2
            else:
                name = token
                if tokens[pos:pos+2] == ['[', ']']:
                    pos += 2
                if tokens[pos] == '+':
                    pos += 1
                assert tokens[pos] == '='; pos += 1
                values = []
                while tokens[pos] != ';':
                    values.append(tokens[pos]); pos += 1
                pos += 1
                result[name] = values
        return result
    return block()


class PlanksArtifactTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which('g++'), 'C++ compiler required for isolated permission predicate')
    def test_real_fence_permission_hook_only_allows_planks_in_unbuilt_foundation(self):
        hook = (ADDON / 'source/Scripts/4_World/ServahzPlanksFence.c').read_text()
        translated = hook.replace('modded class Fence', 'class Fence: public BaseFence').replace('override bool', 'public: bool')
        translated = translated.replace('attachment.IsKindOf', 'attachment->IsKindOf').replace('EntityAI attachment', 'EntityAI* attachment')
        translated = translated.replace('InventorySlots.GetSlotIdFromString', 'InventorySlots::GetSlotIdFromString')
        translated = translated.replace('super.CanReceiveAttachment', 'BaseFence::CanReceiveAttachment')
        harness = r'''
#include <cassert>
#include <string>
struct EntityAI { bool plank; bool IsKindOf(const char*) { return plank; } };
struct InventorySlots { static int GetSlotIdFromString(const char*) { return 42; } };
struct BaseFence {
    bool built = false, upstream = false;
    bool HasBase() { return built; }
    bool CanReceiveAttachment(EntityAI*, int) { return upstream; }
};
''' + translated + r'''
int main() {
    EntityAI plank{true}, other{false}; Fence fence;
    assert(fence.CanReceiveAttachment(&plank,42));
    assert(!fence.CanReceiveAttachment(&plank,43));
    assert(!fence.CanReceiveAttachment(&other,42));
    assert(!fence.CanReceiveAttachment(nullptr,42));
    fence.built = true;
    assert(!fence.CanReceiveAttachment(&plank,42));
    fence.upstream = true;
    assert(fence.CanReceiveAttachment(&plank,42));
    assert(fence.CanReceiveAttachment(&other,43));
}
'''
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            (path / 'probe.cpp').write_text(harness)
            executable = path / 'probe.exe'
            subprocess.run([shutil.which('g++'), '-std=c++11', str(path / 'probe.cpp'), '-o', str(executable)], check=True, capture_output=True)
            subprocess.run([str(executable)], check=True, capture_output=True)

    def test_signed_pbo_contains_exact_reviewed_config_and_rejects_damage(self):
        pbo = (ADDON / 'Addons/servahz_planks.pbo').read_bytes()
        key = (ADDON / 'Keys/ServahzPlanks01814.bikey').read_bytes()
        sig = (ADDON / 'Addons/servahz_planks.pbo.ServahzPlanks01814.bisign').read_bytes()
        files, extensions, checksum = pbo_contents(pbo)
        self.assertEqual(files, {p.relative_to(ADDON / 'source').as_posix().replace('/', '\\'): p.read_bytes()
                                 for p in (ADDON / 'source').rglob('*') if p.is_file()})
        verify_signature(pbo, key, sig)
        damaged = bytearray(pbo); damaged[-30] ^= 1
        with self.assertRaises(ValueError):
            verify_signature(bytes(damaged), key, sig)
        damaged_sig = bytearray(sig); damaged_sig[-1] ^= 1
        with self.assertRaises(ValueError):
            verify_signature(pbo, key, bytes(damaged_sig))
        manifest = json.loads((ADDON / 'files.json').read_text())
        for name, digest in manifest.items():
            self.assertEqual(hashlib.sha256((ADDON / name).read_bytes()).hexdigest(), digest)
        self.assertFalse(list(ADDON.rglob('*.biprivatekey')))

    def test_all_seven_upstream_lumber_stages_use_reachable_plank_slot(self):
        config = parse_patch((ADDON / 'source/config.cpp').read_text())
        vehicles = config['CfgVehicles']
        # Audited upstream release config paths. No entity class or part renamed.
        expected = {'ExpansionWallBase': {'wood_base': 4, 'wood_base_half': 4, 'wood_base_third': 4},
                    'ExpansionFloorBase': {'wood_base': 8}, 'ExpansionFloor6x6': {'wood_base': 8},
                    'ExpansionStairBase': {'wood_base': 8}, 'ExpansionRampBase': {'wood_base': 4}}
        self.assertEqual(set(vehicles), set(expected) | {'WoodenPlank', 'Fence', 'Watchtower', 'TerritoryFlag', 'BF_DoorBarricade', 'BF_DoubleDoorBarricade'})
        for cls, parts in expected.items():
            self.assertEqual(set(vehicles[cls]), {'Construction'})
            stages = vehicles[cls]['Construction']['interact']
            self.assertEqual(set(stages), set(parts))
            for name, quantity in parts.items():
                self.assertEqual(stages[name], {'Materials': {'Material1': {
                    'type': ['"WoodenPlank"'], 'slot_name': ['"Material_WoodenPlanks"'], 'quantity': [str(quantity)]}}})
        # Nails/metal costs, health, part IDs, slots, lock/load/save definitions
        # and existing attachment stacks must remain inherited and untouched.
        source = (ADDON / 'source/config.cpp').read_text()
        for forbidden in ['delete ', 'attachments[', 'lifetime', 'DamageSystem', 'SetQuantity', 'OnStoreLoad', 'OnStoreSave']:
            self.assertNotIn(forbidden, source)

    def test_native_and_barricade_foundations_keep_reachable_slots_but_consume_planks(self):
        config = parse_patch((ADDON / 'source/config.cpp').read_text())
        vehicles = config['CfgVehicles']
        stages = [('Fence', 'wall', 'base', 'Material1', 'Material_WoodenLogs', 4),
                  *[('Watchtower', f'level_{i}', f'level_{i}_base', 'Material1', f'Material_L{i}_WoodenLogs', 8) for i in [1,2,3]],
                  ('TerritoryFlag', 'totem', 'base', 'Material1', 'Material_FPole_WoodenLog', 2),
                  ('TerritoryFlag', 'totem', 'support', 'Material2', 'Material_FPole_WoodenLog2', 12),
                  ('TerritoryFlag', 'totem', 'pole', 'Material4', 'Material_FPole_MagicStick', 6),
                  ('BF_DoorBarricade', 'wall', 'a_base', 'Material1', 'Material_WoodenLogs', 4),
                  ('BF_DoubleDoorBarricade', 'wall', 'a_base', 'Material1', 'Material_WoodenLogs', 4)]
        for cls, group, part, material, slot, quantity in stages:
            self.assertEqual(vehicles[cls]['Construction'][group][part], {'Materials': {material: {
                'type': ['"WoodenPlank"'], 'slot_name': ['"' + slot + '"'], 'quantity': [str(quantity)], 'lockable': ['0']}}})
        slots = {value.strip('"') for value in vehicles['WoodenPlank']['inventorySlot'] if value.startswith('"')}
        self.assertEqual(slots, {stage[4] for stage in stages})
        self.assertIn('inventorySlot[] +=', (ADDON / 'source/config.cpp').read_text())
        self.assertEqual(config['CfgMods']['Servahz_Planks']['defs']['worldScriptModule']['files'],
                         ['{', '"Servahz/Planks/Scripts/4_World"', '}'])


@unittest.skipUnless(package_tests.PWSH, 'PowerShell required')
class PlanksInstallTests(unittest.TestCase):
    def setUp(self):
        self.case = package_tests.PackageTests()
        self.case.setUp()
        self.addCleanup(self.case.doCleanups)
        self.case.install()

    def test_real_install_preserves_world_and_preferences_repeats_and_checks_signature_files(self):
        c = self.case
        save = c.mission / 'storage_1/data/building_000.bin'
        save.parent.mkdir(parents=True)
        save.write_bytes(b'opaque-synthetic-existing-building-and-attachments')
        preferences = json.loads(c.local.read_text())
        target = c.server / 'Servahz/Mods/@ServahzPlanks'
        self.assertEqual((target / 'Addons/servahz_planks.pbo').read_bytes(), (ADDON / 'Addons/servahz_planks.pbo').read_bytes())
        for _ in range(2):
            c.install()
            self.assertEqual(save.read_bytes(), b'opaque-synthetic-existing-building-and-attachments')
            self.assertEqual(json.loads(c.local.read_text()), preferences)
            result = c.run_ps('Test-Server.ps1', '-StaticOnly')
            self.assertIn('Expansion Planken 0.18.14:', result.stdout)
        self.assertIn('verifySignatures = 2;', (c.server / 'Servahz/serverDZ.cfg').read_text())
        (target / 'Addons/servahz_planks.pbo.ServahzPlanks01814.bisign').write_bytes(b'damaged')
        result = c.run_ps('Test-Server.ps1', '-StaticOnly', ok=False)
        self.assertIn('Planken-aanvulling', result.stdout + result.stderr)
        c.install()
        (c.server / 'keys/ServahzPlanks01814.bikey').write_bytes(b'wrong-key')
        result = c.run_ps('Test-Server.ps1', '-StaticOnly', ok=False)
        self.assertIn('serversleutel', result.stdout + result.stderr)

    def test_damaged_bundled_addon_is_refused_before_live_mod_and_mission_writes(self):
        c = self.case
        installed = c.server / 'Servahz/Mods/@CF/Addons/test.pbo'
        installed.write_bytes(b'existing-live-mod')
        types = (c.mission / 'db/types.xml').read_bytes()
        source = c.package / 'config/local-mods/@ServahzPlanks/Addons/servahz_planks.pbo'
        source.write_bytes(b'damaged-bundle')
        result = c.install(ok=False)
        self.assertIn('Planken-aanvulling', result.stdout + result.stderr)
        self.assertEqual(installed.read_bytes(), b'existing-live-mod')
        self.assertEqual((c.mission / 'db/types.xml').read_bytes(), types)


if __name__ == '__main__':
    unittest.main()
