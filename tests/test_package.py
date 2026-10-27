"""Package integration tests with synthetic server/mod files, not a DayZ game test.

Python 3.10+ and PowerShell 7 (or Windows PowerShell 5.1) required.
SERVAHZ_PWSH=/path/to/pwsh python -m unittest discover -s tests -v
Optional SERVAHZ_VANILLA_MISSION=/path/to/dayzOffline.chernarusplus tests real CE data.
"""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PWSH = os.environ.get("SERVAHZ_PWSH") or shutil.which("pwsh") or shutil.which("powershell")


@unittest.skipUnless(PWSH, "PowerShell is required")
class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="servahz test ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.package = self.root / "package with spaces"
        for name in ("scripts", "config"):
            shutil.copytree(ROOT / name, self.package / name)
        self.server = self.root / "DayZ Server"
        self.baseline = self.server / "mpmissions/dayzOffline.chernarusplus"
        (self.baseline / "db").mkdir(parents=True)
        self.workshop = self.root / "workshop/221100"
        (self.server / "DayZServer_x64.exe").write_text("TEST FIXTURE, NOT AN EXECUTABLE")
        self.mods = json.loads((self.package / "config/mods.json").read_text())
        for mod in self.mods:
            folder = self.workshop / mod["Id"]
            (folder / "Addons").mkdir(parents=True)
            (folder / "Keys").mkdir()
            (folder / "Addons/test.pbo").write_text("TEST FIXTURE, NOT A MOD")
            (folder / f"Keys/{mod['Id']}.bikey").write_text("TEST KEY")
        vanilla = os.environ.get("SERVAHZ_VANILLA_MISSION")
        if vanilla:
            for name in ("init.c", "db/types.xml", "cfgeconomycore.xml", "cfggameplay.json"):
                shutil.copyfile(Path(vanilla) / name, self.baseline / name)
        else:
            (self.baseline / "init.c").write_text("// TEST FIXTURE")
            (self.baseline / "db/types.xml").write_text(
                '<types><type name="NailBox"><nominal>10</nominal><min>5</min>'
                '<lifetime>14400</lifetime><flags crafted="0"/></type>'
                '<type name="Car"><nominal>0</nominal><min>0</min></type>'
                '<type name="NoNominal"><lifetime>100</lifetime></type></types>'
            )
            tree = ET.parse(self.baseline / 'db/types.xml')
            for name, nominal, minimum in [('MilitaryRifle', 2, 1), ('MilitaryDisabled', 0, 0)]:
                item = ET.SubElement(tree.getroot(), 'type', name=name)
                ET.SubElement(item, 'nominal').text = str(nominal)
                ET.SubElement(item, 'min').text = str(minimum)
                ET.SubElement(item, 'usage', name='Military')
                ET.SubElement(item, 'value', name='Tier4')
                ET.SubElement(item, 'flags', deloot='1')
            tree.write(self.baseline / 'db/types.xml')
            (self.baseline / "cfgeconomycore.xml").write_text(
                '<economycore><classes><rootclass name="Default"/></classes>'
                '<ce folder="other"><file name="other.xml" type="types"/></ce></economycore>'
            )
            (self.baseline / "cfggameplay.json").write_text(json.dumps({
                "version": 123, "GeneralData": {"disableBaseDamage": False},
                "BaseBuildingData": {"HologramData": {"disableIsUnderwaterCheck": False},
                                     "ConstructionData": {"disableDistanceCheck": False}},
                "PlayerData": {"sentinel": "preserve"}}))
        # A vanilla world must never be copied into our new mission.
        (self.baseline / "storage_1").mkdir()
        (self.baseline / "storage_1/vanilla-save").write_text("do not copy")
        self.mission = self.server / "mpmissions/servahz.chernarusplus"
        self.local = self.package / "config/server.local.json"

    def run_ps(self, script, *args, ok=True):
        process_env = os.environ.copy()
        # Keep test caches inside the disposable fixture in sandboxed Linux CI.
        process_env['XDG_CACHE_HOME'] = str(self.root / 'cache')
        process_env['XDG_CONFIG_HOME'] = str(self.root / 'xdg-config')
        process_env['XDG_DATA_HOME'] = str(self.root / 'xdg-data')
        result = subprocess.run([PWSH, "-NoLogo", "-NoProfile", "-File",
                                 str(self.package / "scripts" / script), *map(str, args)],
                                capture_output=True, text=True, timeout=45, env=process_env)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def install(self, ok=True):
        return self.run_ps("Install-Server.ps1", "-ServerPath", self.server,
                           "-WorkshopPath", self.workshop, ok=ok)

    def test_install_repeat_update_and_preserve_world(self):
        original = (self.baseline / "db/types.xml").read_bytes()
        self.install()
        self.assertEqual((self.baseline / "db/types.xml").read_bytes(), original)
        self.assertFalse((self.mission / "storage_1").exists())
        generated = (self.mission / "db/types.xml").read_bytes()
        before = ET.fromstring(original)
        after = ET.fromstring(generated)
        for tree in (before, after):
            for element in tree.iter():
                if element.text is not None:
                    element.text = element.text.strip() or None
                element.tail = None
        self.assertEqual(len(before), len(after))
        for base, boosted in zip(before, after):
            nominal = base.find("nominal")
            if nominal is not None and int(nominal.text) > 0:
                factor = 10 if base.find("usage[@name='Military']") is not None else 5
                self.assertEqual(int(boosted.findtext("nominal")), int(nominal.text) * factor)
                if base.find("min") is not None:
                    self.assertEqual(int(boosted.findtext("min")), int(base.findtext("min")) * factor)
            else:
                self.assertEqual(ET.tostring(base), ET.tostring(boosted))
            for field in ("lifetime", "restock", "quantmin", "quantmax", "flags", "usage", "value"):
                if base.find(field) is not None:
                    self.assertEqual(ET.tostring(base.find(field)), ET.tostring(boosted.find(field)))
        (self.mission / "storage_1").mkdir()
        (self.mission / "storage_1/players.db").write_text("keep my players")
        mod_target = self.server / "Servahz/Mods" / self.mods[0]["Folder"]
        (mod_target / "Addons/obsolete.pbo").write_text("obsolete")
        self.install()
        self.assertEqual((self.mission / "db/types.xml").read_bytes(), generated)
        self.assertEqual((self.mission / "storage_1/players.db").read_text(), "keep my players")
        self.assertFalse((mod_target / "Addons/obsolete.pbo").exists())
        core = ET.parse(self.mission / "cfgeconomycore.xml")
        self.assertEqual(len(core.findall("./ce[@folder='servahz_ce']")), 1)
        self.assertTrue(list((self.server / "Servahz/Backups").glob("config-*")))
        self.run_ps("Test-Server.ps1", "-StaticOnly")

    def test_military_settings_migration_and_retuning(self):
        self.install()
        settings = json.loads(self.local.read_text())
        admin = settings['AdminPassword']
        del settings['MilitaryLootMultiplier']
        settings['ServerPassword'] = 'keep-this-test-password'
        self.local.write_text(json.dumps(settings))
        self.install()
        settings = json.loads(self.local.read_text())
        self.assertEqual(settings['MilitaryLootMultiplier'], 2)
        self.assertEqual(settings['AdminPassword'], admin)
        self.assertEqual(settings['ServerPassword'], 'keep-this-test-password')
        settings['MilitaryLootMultiplier'] = 1
        self.local.write_text(json.dumps(settings))
        self.install()
        baseline = ET.parse(self.baseline / 'db/types.xml')
        output = ET.parse(self.mission / 'db/types.xml')
        for before, after in zip(baseline.findall('type'), output.findall('type')):
            if int(before.findtext('nominal', '0')) > 0:
                self.assertEqual(int(after.findtext('nominal')), int(before.findtext('nominal')) * 5)

    def test_missing_mod_does_not_create_mission(self):
        shutil.rmtree(self.workshop / self.mods[-1]["Id"])
        result = self.install(ok=False)
        self.assertIn('Mod ontbreekt', result.stderr)
        self.assertFalse(self.mission.exists())

    def test_steam_detection_skips_disconnected_drives(self):
        steam = self.root / 'Steam'
        (steam / 'steamapps').mkdir(parents=True)
        existing = self.root / 'Other Library'
        existing.mkdir()
        (steam / 'steamapps/libraryfolders.vdf').write_text(
            '"libraryfolders"\n{\n"0" { "path" "' + str(existing).replace('\\', '\\\\') +
            '" }\n"1" { "path" "ServahzMissingDrive:\\\\SteamLibrary" }\n}\n')
        script = self.package / 'scripts/Probe-Steam.ps1'
        script.write_text('''
param([string]$SteamRoot)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
$libraries = @(Get-SteamLibraries -SteamRoots @('ServahzMissingDrive:\\Steam', $SteamRoot))
Write-Utf8File (Join-Path $PSScriptRoot 'libraries.json') (ConvertTo-Json -InputObject $libraries)
''')
        self.run_ps('Probe-Steam.ps1', '-SteamRoot', steam)
        libraries = json.loads((script.parent / 'libraries.json').read_text())
        self.assertEqual(libraries, [str(steam), str(existing)])

    def test_explicit_missing_drive_has_actionable_error(self):
        result = self.run_ps('Install-Server.ps1', '-ServerPath', 'ServahzMissingDrive:\\DayZServer',
                             '-WorkshopPath', self.workshop, ok=False)
        self.assertIn('ServerPath is niet bereikbaar', result.stderr)
        self.assertFalse(self.mission.exists())

    def test_missing_key_does_not_create_mission(self):
        shutil.rmtree(self.workshop / self.mods[0]["Id"] / "Keys")
        result = self.install(ok=False)
        self.assertIn('Handtekeningsleutel ontbreekt', result.stderr)
        self.assertFalse(self.mission.exists())

    def test_unowned_mission_is_not_overwritten(self):
        self.mission.mkdir()
        sentinel = self.mission / "valuable.txt"
        sentinel.write_text("keep")
        self.install(ok=False)
        self.assertEqual(sentinel.read_text(), "keep")

    def test_unowned_runtime_is_not_overwritten(self):
        runtime = self.server / "Servahz"
        runtime.mkdir()
        sentinel = runtime / "valuable.txt"
        sentinel.write_text("keep")
        self.install(ok=False)
        self.assertEqual(sentinel.read_text(), "keep")

    def test_invalid_config_and_query_conflict(self):
        self.install()
        settings = json.loads(self.local.read_text())
        settings["Hostname"] = 'evil"; maxPlayers=1000;'
        self.local.write_text(json.dumps(settings))
        self.install(ok=False)
        settings["Hostname"] = "Servahz"
        settings["QueryPort"] = settings["GamePort"]
        self.local.write_text(json.dumps(settings))
        self.install(ok=False)

    def test_static_check_detects_wrong_key(self):
        self.install()
        (self.server / "keys" / (self.mods[0]["Id"] + ".bikey")).write_text("WRONG")
        self.run_ps("Test-Server.ps1", "-StaticOnly", ok=False)

    def test_script_syntax_config_and_launch_arguments(self):
        self.install()
        probe = self.package / 'scripts/Probe.ps1'
        probe.write_text('''
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in @('.ps1', '.psm1') } | ForEach-Object {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw ($errors | Out-String) }
}
& (Join-Path $PSScriptRoot 'Test-Server.ps1') -StaticOnly
if ($LASTEXITCODE -ne 0) { throw 'Static checker failed' }
$s = Read-ServerSettings
$layout = Get-ServerLayout $s
Write-Utf8File (Join-Path $PSScriptRoot 'arguments.json') (ConvertTo-Json @(Get-LaunchArguments $s $layout))
''')
        self.run_ps('Probe.ps1')
        arguments = json.loads((self.package / 'scripts/arguments.json').read_text())
        mods = [arg for arg in arguments if arg.startswith('"-mod=')]
        self.assertEqual(len(mods), 1)
        self.assertTrue(mods[0].endswith('"'))
        for mod in self.mods:
            self.assertIn(str(self.server / 'Servahz/Mods' / mod['Folder']), mods[0])
        config = (self.server / 'Servahz/serverDZ.cfg').read_text()
        self.assertIn('template = "servahz.chernarusplus";', config)
        self.assertIn('verifySignatures = 2;', config)
        self.assertIn('enableCfgGameplayFile = 1;', config)

    def test_ai_admin_merge_and_backup(self):
        self.install()
        path = self.server / 'Servahz/Profiles/ExpansionMod/Settings/AISettings.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps({'m_Version': 20, 'Admins': ['76561198000000002'], 'sentinel': 'keep'}))
        for _ in range(2):
            self.run_ps('Set-AIAdmin.ps1', '-SteamId64', '76561198000000001')
        data = json.loads(path.read_text())
        self.assertEqual(data['Admins'], ['76561198000000002', '76561198000000001'])
        self.assertEqual(data['sentinel'], 'keep')
        self.assertEqual(len(list(path.parent.glob('AISettings.json.*.bak'))), 2)

    def test_backup_preserves_save_and_refuses_overwrite(self):
        self.install()
        (self.mission / "storage_1").mkdir()
        (self.mission / "storage_1/players.db").write_text("players")
        dest = self.root / "world backup"
        self.run_ps("Backup-World.ps1", "-Destination", dest)
        self.assertEqual((dest / "mission/storage_1/players.db").read_text(), "players")
        self.run_ps("Backup-World.ps1", "-Destination", dest, ok=False)
        self.run_ps("Backup-World.ps1", "-Destination", self.mission / "recursive", ok=False)

    def test_query_checker_handles_challenge(self):
        self.install()
        settings = json.loads(self.local.read_text())
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
            udp.bind(("127.0.0.1", 0))
            udp.settimeout(15)
            settings["QueryPort"] = udp.getsockname()[1]
            self.local.write_text(json.dumps(settings))
            errors = []

            def serve():
                try:
                    packet, address = udp.recvfrom(1024)
                    self.assertTrue(packet.startswith(b'\xff\xff\xff\xffTSource Engine Query\0'))
                    udp.sendto(b'\xff\xff\xff\xffAabcd', address)
                    packet, address = udp.recvfrom(1024)
                    self.assertTrue(packet.endswith(b'abcd'))
                    udp.sendto(b'\xff\xff\xff\xffI\x11' + settings["Hostname"].encode() + b'\0', address)
                except Exception as exc:
                    errors.append(exc)

            thread = threading.Thread(target=serve, daemon=True)
            thread.start()
            self.run_ps("Test-Server.ps1")
            thread.join(16)
            self.assertFalse(thread.is_alive())
            self.assertEqual(errors, [])


class ConfigTests(unittest.TestCase):
    def test_patrol_budget_and_building_types(self):
        settings = ROOT / "config/mission/expansion/settings"
        ai = json.loads((settings / "AIPatrolSettings.json").read_text())
        self.assertEqual(ai['MinDistRadius'], 125)
        self.assertGreater(ai['ThreatDistanceLimit'], 250)
        self.assertGreater(ai['NoiseInvestigationDistanceLimit'], 150)
        patrols = ai["Patrols"]
        self.assertEqual(len(patrols), 6)
        self.assertEqual(len({p["Name"] for p in patrols}), len(patrols))
        self.assertLessEqual(ai["LoadBalancingCategories"]["Global"][0]["MaxPatrols"] *
                             max(p["NumberOfAI"] for p in patrols), 12)
        for patrol in patrols:
            self.assertEqual(patrol['Speed'], 'JOG')
            self.assertEqual(patrol["Loadout"], "WestLoadout")
            self.assertGreaterEqual(len(patrol["Waypoints"]), 2)
            for x, y, z in patrol["Waypoints"]:
                self.assertTrue(0 < x < 15360 and 0 < z < 15360)
                self.assertEqual(y, 0)  # Expansion snaps zero altitude to terrain.
        building = ET.parse(ROOT / "config/mission/servahz_ce/building_types.xml")
        names = [node.attrib["name"] for node in building.findall("type")]
        self.assertEqual(len(names), len(set(names)))
        for node in building.findall("type"):
            self.assertLessEqual(int(node.findtext("min")), int(node.findtext("nominal")))


if __name__ == "__main__":
    unittest.main()
