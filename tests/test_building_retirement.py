"""Real package operations with opaque synthetic hive files, not a DayZ engine."""
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
import test_package as package_tests


@unittest.skipUnless(package_tests.PWSH, 'PowerShell required')
class BuildingRetirementTests(unittest.TestCase):
    def setUp(self):
        self.case = package_tests.PackageTests()
        self.case.setUp()
        self.addCleanup(self.case.doCleanups)
        self.case.install()

    def files(self, root):
        return {p.relative_to(root).as_posix():p.read_bytes() for p in root.rglob('*') if p.is_file()}

    def legacy_world(self):
        world = self.case.mission / 'storage_1'
        for name in ['players.db', 'data/dynamic_000.bin', 'data/dynamic_000.001', 'data/building_000.bin',
                     'data/building_000.002', 'data/types.bin', 'data/events.bin', 'data/vehicles.bin']:
            p = world / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(b'SYNTHETIC-PRIVATE-save-' + name.encode())
        oldmod = self.case.server / 'Servahz/Mods/@RaG_BaseBuilding/Addons/retired.pbo'
        oldmod.parent.mkdir(parents=True)
        oldmod.write_bytes(b'SYNTHETIC-OLD-RAG-MOD')
        profile = self.case.seed_legacy_rag_profile()
        return world, oldmod, profile

    def test_clean_install_unloads_basebuilding_keeps_core_and_other_builders(self):
        mods = json.loads((self.case.package / 'config/mods.json').read_text())
        self.assertEqual(len(mods), 17)
        self.assertNotIn('3157695626', [m['Id'] for m in mods])
        self.assertTrue({'3556131153','2792982513','2670506982'} <= {m['Id'] for m in mods})
        self.assertFalse((self.case.server / 'Servahz/Profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json').exists())
        loot = ET.parse(self.case.mission / 'servahz_ce/building_types.xml')
        self.assertFalse(any(n.get('name').startswith('RaG_BB_') for n in loot.findall('type')))
        self.assertGreater(int(loot.findtext("type[@name='ExpansionWallKit']/nominal")), 0)
        self.assertGreater(int(loot.findtext("type[@name='ExpansionCodeLock']/nominal")), 0)
        result = self.case.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertIn('RaG BaseBuilding 0.18.13: uit', result.stdout)
        probe = self.case.package / 'scripts/LaunchProbe.ps1'
        probe.write_text('''Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
$s = Read-ServerSettings
Get-LaunchArguments $s (Get-ServerLayout $s)
''')
        result = self.case.run_ps('LaunchProbe.ps1')
        self.assertNotIn('@RaG_BaseBuilding', result.stdout)
        self.assertIn('@RaG_Core', result.stdout)
        self.assertIn('@ExpansionBaseBuilding', result.stdout)
        self.assertIn('@BuildingFortifications', result.stdout)

    def test_direct_install_backs_up_all_hive_files_before_unload_and_repeat_is_safe(self):
        world, oldmod, profile = self.legacy_world()
        before = self.files(world)
        profile_before = profile.read_bytes()
        local_before = json.loads(self.case.local.read_text())
        self.case.install()
        marker = self.case.server / 'Servahz/.rag-basebuilding-disabled'
        backup = Path(marker.read_text())
        self.assertEqual(self.files(backup / 'mission/storage_1'), before)
        self.assertEqual(self.files(world), before)
        self.assertEqual(profile.read_bytes(), profile_before)
        self.assertEqual((backup / 'Profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json').read_bytes(), profile_before)
        self.assertEqual(json.loads((backup / 'server.local.json').read_text()), local_before)
        self.assertEqual(json.loads(self.case.local.read_text()), local_before)
        self.assertEqual(oldmod.read_bytes(), b'SYNTHETIC-OLD-RAG-MOD')
        self.case.run_ps('Install-Server.ps1', '-TestMode')
        self.assertEqual(self.files(world), before)
        self.assertEqual(self.files(backup / 'mission/storage_1'), before)
        self.assertEqual(len(list((self.case.package / '.local/Backups').glob('disable-rag-*'))), 1)

    def test_failed_world_backup_prevents_live_mod_replacement(self):
        world, oldmod, profile = self.legacy_world()
        before = self.files(world)
        core = self.case.server / 'Servahz/Mods/@RaG_Core/Addons/test.pbo'
        core.write_bytes(b'SYNTHETIC-keep-old-core-until-backup-completes')
        backup_script = self.case.package / 'scripts/Backup-World.ps1'
        backup_script.write_text('exit 1')
        result = self.case.install(ok=False)
        self.assertIn('Wereldbackup voor RaG-uitschakeling mislukt', result.stderr)
        self.assertEqual(core.read_bytes(), b'SYNTHETIC-keep-old-core-until-backup-completes')
        self.assertEqual(self.files(world), before)
        self.assertFalse((self.case.server / 'Servahz/.rag-basebuilding-disabled').exists())
        self.assertTrue(oldmod.exists())

    def test_both_refresh_scopes_exclude_every_rag_class_and_preserve_hive_files(self):
        world, oldmod, profile = self.legacy_world()
        self.case.install()
        (self.case.mission / 'init.c').write_text('class CustomMission {};\nMission CreateCustomMission(string path) { return new CustomMission(); }')
        before = self.files(world)
        self.case.run_ps('Queue-LootRefresh.ps1', '-CenterX',8000,'-CenterZ',7000)
        request = self.case.server / 'Servahz/Profiles/Servahz/LootRefresh-request.json'
        broad = json.loads(request.read_text())
        self.assertFalse(any(n.startswith('RaG_') for n in broad['AllowedTypes']))
        self.case.run_ps('Queue-LootRefresh.ps1', '-Disable')
        settings = json.loads(self.case.local.read_text())
        settings['RareWeaponsOnly'] = True
        self.case.local.write_text(json.dumps(settings))
        self.case.install()
        self.case.run_ps('Queue-LootRefresh.ps1', '-ObsoleteWeaponsOnly', '-ProtectTown','Gorka')
        narrow = json.loads(request.read_text())
        self.assertFalse(any(n.startswith('RaG_') for n in narrow['AllowedTypes']))
        self.assertIn('M4A1', narrow['AllowedTypes'])
        self.assertEqual(narrow['ExtraProtectedAreas'][0]['Radius'],1500)
        self.assertEqual(self.files(world), before)

    def test_diagnostic_reads_startup_and_filters_valid_loads_and_repair_item_names(self):
        profiles = self.case.server / 'Servahz/Profiles'
        log = profiles / 'PRIVATE-world-log.RPT'
        startup = '23:00:01 [::JsonLoadFile] [ERROR] Cannot load "$mission:expansion/settings/SpawnSettings.json" PRIVATE-password\n'
        ordinary = '''23:26:44 SCRIPT : Module: World; loaded BaseBuildingItemStackandRepair CE save PRIVATE-player
23:27:02 [CE][Storage] ver:27 stamp:2799, valid:yes, name:"PRIVATE-path/dynamic_000.bin"
23:27:03 [CE][Storage] Restoring file "PRIVATE-path/dynamic_000.bin" 50 items.
23:27:04 [CE][Hive] Storage load took:15.27 seconds, recovery stamp:2799
23:33:41 [CE][LootRespawner] Item causing search overtime: "TireRepairKit"
23:33:42 [CE][LootRespawner] Item causing search overtime: "ElectronicRepairKit"
23:40:00 [CE][Storage] Recovering corrupted save failed PRIVATE-path/dynamic_001.bin PRIVATE-player
'''
        log.write_text(startup + 'ordinary filler\n'*4000 + ordinary)
        settings = profiles / 'ExpansionMod/Settings/TerritorySettings.json'
        settings.parent.mkdir(parents=True, exist_ok=True)
        settings.write_text(json.dumps(dict(EnableTerritories=True, TerritorySize=150, PrivateOwner='PRIVATE-not-printed')))
        globals_path = self.case.mission / 'db/globals.xml'
        globals_xml = ET.parse(globals_path)
        for name,value in [('FlagRefreshFrequency',432000),('FlagRefreshMaxDuration',3456000),('CleanupLifetimeRuined',330)]:
            ET.SubElement(globals_xml.getroot(),'var',name=name,type='0',value=str(value))
        globals_xml.write(globals_path)
        before = self.files(self.case.server)
        result = self.case.run_storage_probe()
        for expected in ['config:SpawnSettings.json', 'normale opslaglaadmeldingen overgeslagen=3',
                         'aparte lootplaatsingsmeldingen=2', 'bestand:dynamic_001.bin', 'Expansion TerritorySize=150',
                         'Wereld FlagRefreshFrequency=432000', 'CleanupLifetimeRuined=330']:
            self.assertIn(expected, result.stdout)
        self.assertNotIn('bestand:dynamic_000.bin', result.stdout)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
        self.assertEqual(self.files(self.case.server), before)
