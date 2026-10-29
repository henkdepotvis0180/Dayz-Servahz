"""Package integration tests with synthetic server/mod files, not a DayZ game test.

Python 3.10+ and PowerShell 7 (or Windows PowerShell 5.1) required.
SERVAHZ_PWSH=/path/to/pwsh python -m unittest discover -s tests -v
Optional SERVAHZ_VANILLA_MISSION=/path/to/dayzOffline.chernarusplus tests real CE data.
"""
import json
import importlib.util
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
        # Windows TEMP can use an 8.3 user directory while PowerShell expands it.
        self.root = Path(self.temp.name).resolve()
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
            for name in ("init.c", "db/types.xml", "db/globals.xml", "mapgroupproto.xml", "cfgeconomycore.xml", "cfggameplay.json"):
                shutil.copyfile(Path(vanilla) / name, self.baseline / name)
        else:
            (self.baseline / 'db/globals.xml').write_text('<variables><var name="LootDamageMin" type="1" value="0.0"/><var name="LootDamageMax" type="1" value="0.82"/><var name="ZombieMaxCount" type="0" value="1000"/></variables>')
            tree = ET.parse(self.baseline / 'db/globals.xml')
            for name, value in {'RestartSpawn': 0, 'RespawnTypes': 12, 'RespawnLimit': 20, 'RespawnAttempt': 2, 'LootSpawnAvoidance': 100}.items():
                ET.SubElement(tree.getroot(), 'var', name=name, type='0', value=str(value))
            tree.write(self.baseline / 'db/globals.xml')
            (self.baseline / 'mapgroupproto.xml').write_text('<prototype><defaults><default name="group" lootmax="6"/></defaults><group name="House" lootmax="4"><container name="lootFloor" lootmax="2"><category name="tools"/><point pos="1 2 3"/></container></group><group name="NoLoot" lootmax="0"/></prototype>')
            (self.baseline / "init.c").write_text("// TEST FIXTURE")
            (self.baseline / "db/types.xml").write_text(
                '<types><type name="NailBox"><nominal>10</nominal><min>5</min>'
                '<lifetime>14400</lifetime><flags crafted="0"/></type>'
                '<type name="Car"><nominal>0</nominal><min>0</min></type>'
                '<type name="NoNominal"><lifetime>100</lifetime></type></types>'
            )
            tree = ET.parse(self.baseline / 'db/types.xml')
            for name, nominal, minimum, deloot, crafted in [('MilitaryRifle', 2, 1, '1', '0'), ('MilitaryDisabled', 0, 0, '0', '0'), ('MilitaryOrdinary', 3, 1, '0', '0'), ('MilitaryCrafted', 2, 1, '0', '1')]:
                item = ET.SubElement(tree.getroot(), 'type', name=name)
                ET.SubElement(item, 'nominal').text = str(nominal)
                ET.SubElement(item, 'min').text = str(minimum)
                ET.SubElement(item, 'usage', name='Military')
                ET.SubElement(item, 'value', name='Tier4')
                ET.SubElement(item, 'flags', deloot=deloot, crafted=crafted)
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
        economy_source = Path(vanilla) / 'db/economy.xml' if vanilla else None
        if economy_source and economy_source.is_file():
            shutil.copyfile(economy_source, self.baseline / 'db/economy.xml')
        else:
            (self.baseline / 'db/economy.xml').write_text(
                '<economy><building init="1" load="1" respawn="0" save="1"/>'
                '<dynamic init="1" load="1" respawn="1" save="1"/>'
                '<vehicles init="1" load="1" respawn="1" save="1"/></economy>')
        if vanilla:
            shutil.copyfile(Path(vanilla) / 'mapgrouppos.xml', self.baseline / 'mapgrouppos.xml')
        else:
            # Asymmetric floor point tests world rotation independently of origin.
            groups = ET.parse(self.baseline / 'mapgroupproto.xml')
            shop = ET.SubElement(groups.getroot(), 'group', name='Land_Village_store', lootmax='4')
            ET.SubElement(shop, 'usage', name='Town')
            floor = ET.SubElement(shop, 'container', name='lootFloor', lootmax='4')
            ET.SubElement(floor, 'point', pos='2 -1 3', range='1.5', height='2', flags='32')
            groups.write(self.baseline / 'mapgroupproto.xml')
            (self.baseline / 'mapgrouppos.xml').write_text('<map><group name="Land_Village_store" pos="2000 100 3000" rpy="0 0 90" a="0"/></map>')
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
        map_path = self.mission / 'expansion/settings/MapSettings.json'
        self.assertEqual(json.loads(map_path.read_text())['NeedGPSItemForKeyBinding'], 0)
        self.assertTrue(list((self.server / 'Servahz/Backups').glob('config-*/mission/expansion/settings/MapSettings.json')))
        self.run_ps("Test-Server.ps1", "-StaticOnly")

    def test_personal_respawn_seed_preserves_world_and_existing_mission_hooks(self):
        recipient = self.prepare_delivery()
        self.run_ps('Queue-CodeLock.ps1', '-SteamId', recipient)
        init = (self.mission / 'init.c').read_bytes()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'keep character, gear and base')
        path = self.mission / 'expansion/settings/SpawnSettings.json'
        # Simulate a pre-feature live installation with no respawn file.
        path.unlink()
        local = self.local.read_bytes()
        self.install()
        config = json.loads(path.read_text())
        self.assertEqual(config['EnableSpawnSelection'], 1)
        self.assertEqual(config['SpawnOnTerritory'], 1)
        self.assertFalse(config['StartingClothing']['EnableCustomClothing'])
        self.assertFalse(config['StartingGear']['EnableStartingGear'])
        self.assertFalse(config['UseLoadouts'])
        self.assertFalse(config['EnableRespawnCooldowns'])
        self.assertEqual(config['SpawnLocations'][0]['Positions'], ['0 0 0'])
        self.assertEqual((self.mission / 'init.c').read_bytes(), init)
        self.assertEqual(world.read_bytes(), b'keep character, gear and base')
        self.assertEqual(self.local.read_bytes(), local)
        self.assertTrue((self.server / 'Servahz/Mods/@ExpansionSpawnSelection/Addons/test.pbo').is_file())
        self.assertFalse((self.server / 'Servahz/Profiles/Servahz/LootRefresh-request.json').exists())
        result = self.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertIn('Persoonlijke respawn: selectie en eigen territory ingeschakeld', result.stdout)

    def test_personal_respawn_changes_only_opt_in_flags_and_backs_up_previous_config(self):
        self.install()
        path = self.mission / 'expansion/settings/SpawnSettings.json'
        config = json.loads(path.read_text())
        config.update(EnableSpawnSelection=0, SpawnOnTerritory=0,
                      EnableRespawnCooldowns=1, TerritoryRespawnCooldown=750,
                      PrivateUnknownField='PRIVATE-spawn-data')
        config['SpawnLocations'] = [dict(Name='PRIVATE-location', Positions=['1200 15 2500'], UseCooldown=1)]
        config['StartingGear']['UpperGear'] = [dict(ClassName='Apple', Quantity=2)]
        path.write_text(json.dumps(config))
        before = path.read_bytes()
        self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False)
        self.assertEqual(path.read_bytes(), before)  # Read-only checker.
        self.install()
        expected = dict(config, EnableSpawnSelection=1, SpawnOnTerritory=1)
        self.assertEqual(json.loads(path.read_text()), expected)
        backups = list((self.server / 'Servahz/Backups').glob('config-*/mission/expansion/settings/SpawnSettings.json'))
        self.assertTrue(any(p.read_bytes() == before for p in backups))
        stable = path.read_bytes()
        self.install()
        self.assertEqual(path.read_bytes(), stable)
        result = self.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)

    def test_personal_respawn_refuses_bad_or_legacy_settings_before_live_changes(self):
        self.install()
        path = self.mission / 'expansion/settings/SpawnSettings.json'
        original = path.read_bytes()
        init = (self.mission / 'init.c').read_bytes()
        mod = self.server / 'Servahz/Mods/@ExpansionSpawnSelection/Addons/test.pbo'
        mod.write_bytes(b'keep live mod until preflight passes')
        for bad in [b'{invalid', b'{"m_Version":99}', b'{"m_Version":7,"SpawnLocations":[]}']:
            path.write_bytes(bad)
            result = self.install(ok=False)
            self.assertIn('SpawnSettings.json', result.stderr)
            self.assertEqual(path.read_bytes(), bad)
            self.assertEqual(mod.read_bytes(), b'keep live mod until preflight passes')
            self.assertEqual((self.mission / 'init.c').read_bytes(), init)
        path.write_bytes(original)
        legacy = self.server / 'Servahz/Profiles/ExpansionMod/Settings/SpawnSettings.json'
        legacy.parent.mkdir(parents=True)
        legacy.write_bytes(original)
        result = self.install(ok=False)
        self.assertIn('Oude respawninstellingen', ' '.join(result.stderr.split()))
        self.assertEqual(path.read_bytes(), original)
        self.assertEqual(legacy.read_bytes(), original)
        self.assertEqual(mod.read_bytes(), b'keep live mod until preflight passes')

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

    def test_testmode_loot_quality_backup_and_world_preservation(self):
        self.install()
        saved = json.loads(self.local.read_text())
        saved['ServerPassword'] = 'preserve-private-password'
        saved.pop('TestSuppliesEverywhere', None)
        self.local.write_text(json.dumps(saved))
        previous = self.local.read_bytes()
        settings = json.loads(previous)
        (self.mission / 'storage_1').mkdir()
        (self.mission / 'storage_1/players.db').write_text('keep players')
        original_globals = (self.baseline / 'db/globals.xml').read_bytes()
        for _ in range(2):
            self.run_ps('Install-Server.ps1', '-ServerPath', self.server, '-WorkshopPath', self.workshop, '-TestMode')
            current = json.loads(self.local.read_text())
            self.assertEqual(current['LootMultiplier'], 8)
            self.assertEqual(current['MilitaryLootMultiplier'], 3)
            self.assertEqual(current['LootDamageMax'], 0.10)
            self.assertIs(current['TestMilitaryEverywhere'], True)
            self.assertIs(current['TestSuppliesEverywhere'], True)
            self.assertIs(current['TestFastRestock'], True)
            for field in ('AdminPassword', 'ServerPassword', 'ServerPath', 'WorkshopPath'):
                self.assertEqual(current[field], settings[field])
            before = ET.parse(self.baseline / 'db/types.xml').findall('type')
            after = ET.parse(self.mission / 'db/types.xml').findall('type')
            for base, generated in zip(before, after):
                nominal = int(base.findtext('nominal', '0'))
                if nominal > 0:
                    factor = 24 if base.find("usage[@name='Military']") is not None else 8
                    self.assertGreaterEqual(int(generated.findtext('nominal')), nominal * factor)
                for tag in ('usage', 'value'):
                    values = [n.get('name') for n in generated.findall(tag)]
                    self.assertEqual(len(values), len(set(values)))
                if base.get('name') not in ('WoodenPlank',):
                    self.assertEqual(base.find('flags').attrib if base.find('flags') is not None else {}, generated.find('flags').attrib if generated.find('flags') is not None else {})
            globals_xml = ET.parse(self.mission / 'db/globals.xml')
            self.assertEqual(float(globals_xml.find("var[@name='LootDamageMax']").get('value')), 0.10)
            self.assertEqual(float(globals_xml.find("var[@name='LootDamageMin']").get('value')), 0)
            original = ET.fromstring(original_globals)
            for node in original:
                if node.get('name') not in ('LootDamageMin', 'LootDamageMax', 'RestartSpawn', 'RespawnTypes', 'RespawnLimit', 'RespawnAttempt', 'LootSpawnAvoidance'):
                    self.assertEqual(globals_xml.find(f"var[@name='{node.get('name')}']").attrib, node.attrib)
        self.assertEqual((self.mission / 'storage_1/players.db').read_text(), 'keep players')
        self.assertEqual((self.baseline / 'db/globals.xml').read_bytes(), original_globals)
        backups = list((self.package / '.local/Backups').glob('server-before-testmode-*.json'))
        self.assertEqual(len(backups), 2)
        self.assertTrue(any(p.read_bytes() == previous for p in backups))
        current['TestMilitaryEverywhere'] = False
        current['TestSuppliesEverywhere'] = False
        self.local.write_text(json.dumps(current))
        self.install()
        restored = ET.parse(self.mission / 'db/types.xml').findall('type')
        for base, generated in zip(before, restored):
            for tag in ('usage', 'value'):
                self.assertEqual([n.attrib for n in base.findall(tag)], [n.attrib for n in generated.findall(tag)])

    def test_invalid_loot_damage_is_rejected(self):
        self.install()
        settings = json.loads(self.local.read_text())
        settings['LootDamageMax'] = 1.5
        self.local.write_text(json.dumps(settings))
        result = self.install(ok=False)
        self.assertIn('LootDamageMax', result.stderr)

    def test_travel_sprint_preserves_other_stamina_and_world(self):
        path = self.baseline / 'cfggameplay.json'
        gameplay = json.loads(path.read_text())
        stamina = gameplay['PlayerData'].setdefault('StaminaData', {})
        stamina.update(sprintStaminaModifierErc=1.0, sprintStaminaModifierCro=1.0,
                       meleeStaminaModifier=1.0, obstacleTraversalStaminaModifier=1.0,
                       holdBreathStaminaModifier=1.0, staminaMax=100.0,
                       staminaWeightLimitThreshold=6000.0, CustomSentinel=17)
        path.write_text(json.dumps(gameplay))
        baseline = path.read_bytes()
        self.install()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'keep my save')
        self.run_ps('Install-Server.ps1', '-TestMode')
        current = json.loads((self.mission / 'cfggameplay.json').read_text())
        expected = dict(gameplay['PlayerData'])
        expected['StaminaData'] = dict(stamina, sprintStaminaModifierErc=0.25)
        self.assertEqual(current['PlayerData'], expected)
        self.assertEqual(path.read_bytes(), baseline)
        self.assertEqual(world.read_bytes(), b'keep my save')

    def test_fast_refill_density_and_restore_without_wipe(self):
        types = ET.parse(self.baseline / 'db/types.xml')
        nailbox = types.find("type[@name='NailBox']")
        restock = nailbox.find('restock')
        if restock is None:
            restock = ET.SubElement(nailbox, 'restock')
        restock.text = '3600'
        types.write(self.baseline / 'db/types.xml')
        self.install()
        previous = json.loads(self.local.read_text())
        self.assertFalse(previous['TestFastRestock'])
        save = self.mission / 'storage_1/players.db'
        save.parent.mkdir()
        save.write_bytes(b'keep world')
        path = self.mission / 'db/globals.xml'
        globals_xml = ET.parse(path)
        ET.SubElement(globals_xml.getroot(), 'var', name='CustomUnrelated', type='0', value='123')
        globals_xml.write(path)
        source = ET.parse(self.baseline / 'mapgroupproto.xml')
        baseline_groups = (self.baseline / 'mapgroupproto.xml').read_bytes()
        for _ in range(2):
            self.run_ps('Install-Server.ps1', '-TestMode')
            self.assertEqual(ET.parse(self.mission / 'db/types.xml').findtext("type[@name='NailBox']/restock"), '0')
            current = ET.parse(path)
            for name, amount in {'RestartSpawn': 50, 'RespawnTypes': 30, 'RespawnLimit': 50, 'RespawnAttempt': 4, 'LootSpawnAvoidance': 50}.items():
                self.assertEqual(int(current.find(f"var[@name='{name}']").get('value')), amount)
            self.assertEqual(current.find("var[@name='CustomUnrelated']").get('value'), '123')
            generated = ET.parse(self.mission / 'mapgroupproto.xml')
            # Food partitioning is tested separately; compare unchanged groups
            # here to isolate the optional fast-refill capacity multiplier.
            filtered_source = ET.fromstring(ET.tostring(source.getroot()))
            filtered_generated = ET.fromstring(ET.tostring(generated.getroot()))
            for group in list(filtered_generated.findall('group')):
                if any(c.find("tag[@name='shelves']") is not None and c.find("category[@name='food']") is not None and len(c.findall('category')) == 1 for c in group.findall('container')):
                    old = filtered_source.find(f"group[@name='{group.get('name')}']")
                    filtered_source.remove(old)
                    filtered_generated.remove(group)
            for before, after in zip(filtered_source.iter(), filtered_generated.iter()):
                expected = dict(before.attrib)
                if 'lootmax' in expected:
                    expected['lootmax'] = str(int(expected['lootmax']) * 2)
                self.assertEqual(after.attrib, expected)
            self.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertEqual(save.read_bytes(), b'keep world')
        self.assertEqual((self.baseline / 'mapgroupproto.xml').read_bytes(), baseline_groups)
        config = json.loads(self.local.read_text())
        config['TestFastRestock'] = False
        self.local.write_text(json.dumps(config))
        self.install()
        self.assertEqual(ET.parse(self.mission / 'db/types.xml').findtext("type[@name='NailBox']/restock"), '3600')
        restored = ET.parse(self.mission / 'mapgroupproto.xml')
        original = ET.fromstring(ET.tostring(source.getroot()))
        for group in list(restored.findall('group')):
            if any(c.find("tag[@name='shelves']") is not None and c.find("category[@name='food']") is not None and len(c.findall('category')) == 1 for c in group.findall('container')):
                original.remove(original.find(f"group[@name='{group.get('name')}']"))
                restored.getroot().remove(group)
        self.assertEqual([n.attrib for n in restored.iter()], [n.attrib for n in original.iter()])
        current = ET.parse(path)
        baseline = ET.parse(self.baseline / 'db/globals.xml')
        for name in ('RestartSpawn', 'RespawnTypes', 'RespawnLimit', 'RespawnAttempt', 'LootSpawnAvoidance'):
            self.assertEqual(current.find(f"var[@name='{name}']").attrib, baseline.find(f"var[@name='{name}']").attrib)
        self.assertEqual(current.find("var[@name='CustomUnrelated']").get('value'), '123')
        self.assertTrue(list((self.server / 'Servahz/Backups').glob('config-*/mission/mapgroupproto.xml')))
        config['TestFastRestock'] = 'true'
        self.local.write_text(json.dumps(config))
        self.assertIn('TestFastRestock', self.install(ok=False).stderr)

    def test_extra_mod_loot_and_economy_links(self):
        self.run_ps('Install-Server.ps1', '-ServerPath', self.server, '-WorkshopPath', self.workshop, '-TestMode')
        extra_path = self.mission / 'servahz_ce/extra_types.xml'
        first = extra_path.read_bytes()
        extra = ET.parse(extra_path)
        self.assertEqual(extra.findtext("type[@name='Expansion_MP7']/nominal"), '60')
        self.assertEqual(extra.findtext("type[@name='Mag_Expansion_MP7_40Rnd']/nominal"), '120')
        self.assertEqual(extra.findtext("type[@name='MMG_mmps_bag_black']/nominal"), '150')
        self.assertEqual(extra.findtext("type[@name='BF_DoorBarricadeKit']/nominal"), '80')
        self.assertEqual(extra.findtext("type[@name='Snafu_ScarH_Black_GUN']/nominal"), '60')
        self.assertEqual(extra.findtext("type[@name='Snafu_ScarH_25RND_Mag_BK']/nominal"), '120')
        self.assertEqual(extra.findtext("type[@name='SNAFU_Ammo_338']/nominal"), '180')
        self.assertEqual(extra.findtext("type[@name='Expansion_G36']/nominal"), '60')
        for node in extra.findall('type'):
            if int(node.findtext('nominal')) == 0:
                continue
            self.assertEqual(len(node.findall('usage')), 17, node.get('name'))
            self.assertTrue({'Tier1', 'Tier2', 'Tier3', 'Tier4'} <= {n.get('name') for n in node.findall('value')})
        for _ in range(2):
            self.install()
            self.assertEqual(extra_path.read_bytes(), first)
            core = ET.parse(self.mission / 'cfgeconomycore.xml')
            files = core.findall("ce[@folder='servahz_ce']/file")
            self.assertEqual({(f.get('name'), f.get('type')) for f in files},
                             {('building_types.xml', 'types'), ('extra_types.xml', 'types'), ('extra_spawnabletypes.xml', 'spawnabletypes'), ('lootchest_types.xml', 'types')})
            self.assertEqual(len(files), 4)
        core_path = self.mission / 'cfgeconomycore.xml'
        core = ET.parse(core_path)
        ce = core.find("ce[@folder='servahz_ce']")
        ce.remove(ce.find("file[@name='extra_types.xml']"))
        core.write(core_path)
        self.assertIn('extra_types.xml', self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False).stderr)

    def test_rag_profile_seed_preserve_backup_and_testloot(self):
        self.install()
        relative = 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
        profile = self.server / 'Servahz/Profiles' / relative
        default = json.loads((ROOT / 'config/profiles' / relative).read_text())
        self.assertEqual(json.loads(profile.read_text()), default)
        custom = dict(default, NailsPerKitCraft=3, PrivateSentinel='keep my preferences')
        profile.write_text(json.dumps(custom))
        previous = profile.read_bytes()
        settings = json.loads(self.local.read_text())
        settings['ServerPassword'] = 'keep-private-password'
        self.local.write_text(json.dumps(settings))
        save = self.mission / 'storage_1/players.db'
        save.parent.mkdir()
        save.write_bytes(b'player and world sentinel')
        for _ in range(2):
            self.run_ps('Install-Server.ps1', '-TestMode')
            self.assertEqual(profile.read_bytes(), previous)
            self.assertEqual(save.read_bytes(), b'player and world sentinel')
            current = json.loads(self.local.read_text())
            for key in ('ServerPassword', 'AdminPassword', 'ServerPath', 'WorkshopPath'):
                self.assertEqual(current[key], settings[key])
        backups = list((self.server / 'Servahz/Backups').glob('config-*/Profiles/' + relative))
        self.assertTrue(backups)
        self.assertTrue(all(p.read_bytes() == previous for p in backups))
        loot = ET.parse(self.mission / 'servahz_ce/building_types.xml')
        for name in ('RaG_BB_WallKit', 'RaG_BB_FloorKit', 'RaG_BB_Book'):
            node = loot.find(f"type[@name='{name}']")
            self.assertEqual(int(node.findtext('nominal')), 80 if name.endswith('Book') else 60)
            self.assertEqual(len(node.findall('usage')), 17)
        self.run_ps('Test-Server.ps1', '-StaticOnly')
        destination = self.root / 'rag world backup'
        self.run_ps('Backup-World.ps1', '-Destination', destination)
        self.assertEqual((destination / 'Profiles' / relative).read_bytes(), previous)

    def test_build_diagnostic_preserves_world_profile_and_filters_private_logs(self):
        self.install()
        profiles = self.server / 'Servahz/Profiles'
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'preserve whole world')
        profile = profiles / 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
        rag = json.loads(profile.read_text())
        rag['PrivateSentinel'] = 'DO-NOT-PRINT-PROFILE'
        profile.write_text(json.dumps(rag))
        settings = json.loads(self.local.read_text())
        settings['ServerPassword'] = 'DO-NOT-PRINT-PASSWORD'
        self.local.write_text(json.dumps(settings))
        (profiles / 'script_test.log').write_text('''SCRIPT (E): 18:22:31 NULL pointer to instance
Private player SOME-PRIVATE-PLAYER at 192.0.2.123 used pin DIAGNOSTIC-PRIVATE-PIN
Class: ActionDialCombinationLockOnTarget
Function: OnFinishProgressServer
File: RaG_BB_Door.c
18:24:00 player SOME-PRIVATE-PLAYER dismantled RaG_BB_Door at private-coordinates
''')
        backup = self.package / '.local/Backups/update-v0.18.0-test/world/mission/storage_1'
        backup.mkdir(parents=True)
        (backup / 'players.db').write_bytes(b'older world')
        before = {p.relative_to(self.server).as_posix(): p.read_bytes() for p in self.server.rglob('*') if p.is_file()}
        local_before = self.local.read_bytes()
        result = self.run_ps('Test-Building.ps1')
        self.assertIn('bouwdiagnose 0.18.1', result.stdout)
        self.assertIn('RaG_Core: GELIJK', result.stdout)
        self.assertIn('BaseInfiniteLifetime=0', result.stdout)
        self.assertIn('PLANKS=2, NAILS=0, LOGS=0, METALSHEETS=0', result.stdout)
        self.assertIn('NULL-pointer', result.stdout)
        self.assertIn('afbraak/verwijderingsmelding', result.stdout)
        self.assertIn('ActionDialCombinationLockOnTarget', result.stdout)
        self.assertIn('Wereldbackup #1', result.stdout)
        reports = list((self.package / '.local/BuildDiagnostics').glob('*.txt'))
        self.assertEqual(len(reports), 1)
        for output in [result.stdout, result.stderr, reports[0].read_text(encoding='utf-8-sig')]:
            for private in ['DO-NOT-PRINT-PROFILE', 'DO-NOT-PRINT-PASSWORD', 'SOME-PRIVATE-PLAYER', '192.0.2.123', 'DIAGNOSTIC-PRIVATE-PIN', 'private-coordinates']:
                self.assertNotIn(private, output)
        self.assertEqual(self.local.read_bytes(), local_before)
        self.assertEqual(before, {p.relative_to(self.server).as_posix(): p.read_bytes() for p in self.server.rglob('*') if p.is_file()})

    def test_build_diagnostic_detects_stale_and_missing_mod_copies(self):
        self.install()
        workshop = self.workshop / '3157695626/Addons/test.pbo'
        workshop.write_bytes(b'new workshop script version')
        result = self.run_ps('Test-Building.ps1')
        self.assertIn('RaG_BaseBuilding: WIJKT AF', result.stdout)
        server_pbo = self.server / 'Servahz/Mods/@RaG_BaseBuilding/Addons/test.pbo'
        server_pbo.unlink()
        result = self.run_ps('Test-Building.ps1')
        self.assertIn('RaG_BaseBuilding: ONVOLLEDIG', result.stdout)
        self.assertFalse(server_pbo.exists())

    def test_build_diagnostic_reports_invalid_profile_without_replacing_it(self):
        self.install()
        profile = self.server / 'Servahz/Profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
        profile.write_text('{ invalid json PRIVATE-INVALID-CONTENT')
        previous = profile.read_bytes()
        result = self.run_ps('Test-Building.ps1')
        self.assertIn('RaG-profiel: ontbreekt', result.stdout)
        self.assertIn('Geen herkende bouw-/slotfoutsignalen', result.stdout)
        self.assertNotIn('PRIVATE-INVALID-CONTENT', result.stdout + result.stderr)
        self.assertEqual(profile.read_bytes(), previous)

    def run_storage_probe(self, processes=None, *, unavailable=False):
        # The one-file CMD is also usable on existing packages without stopping
        # the process whose launch selection we need to inspect.
        command = (ROOT / '08-Opslagdiagnose.cmd').read_text()
        (self.package / '08-Opslagdiagnose.cmd').write_text(command)
        (self.package / 'scripts/storage-processes.json').write_text(json.dumps(processes or []))
        mock = "throw 'PRIVATE-CIM-ERROR'" if unavailable else """
foreach ($process in $script:storageProcesses) {
    $process.CreationDate = [DateTime]$process.CreationDate
    $process
}
"""
        (self.package / 'scripts/StorageProbe.ps1').write_text('''
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:storageProcesses = Get-Content (Join-Path $PSScriptRoot 'storage-processes.json') -Raw | ConvertFrom-Json
function Get-CimInstance {
    param($ClassName, $Filter, $ErrorAction)
''' + mock + '''
}
$root = Split-Path $PSScriptRoot -Parent
$lines = [IO.File]::ReadAllLines((Join-Path $root '08-Opslagdiagnose.cmd'))
$marker = [Array]::IndexOf($lines, '# SERVAHZ_STORAGE_POWERSHELL')
$body = $lines[($marker + 1)..($lines.Length - 1)] -join [Environment]::NewLine
& ([scriptblock]::Create($body)) -PackageRoot $root
''')
        return self.run_ps('StorageProbe.ps1')

    def storage_process(self, command):
        return dict(ExecutablePath=str(self.server / 'DayZServer_x64.exe'), CommandLine=command,
                    CreationDate='2026-10-29T17:00:00Z')

    def test_storage_diagnostic_compares_quoted_live_launch_and_preserves_files(self):
        self.install()
        profiles = self.server / 'Servahz/Profiles'
        world = self.mission / 'storage_1/data/types.bin'
        world.parent.mkdir(parents=True)
        world.write_bytes(b'WORLD-MUST-NOT-CHANGE')
        (profiles / 'PRIVATE-log-name.RPT').write_text(
            '18:03:01 Storage write failed: access denied PRIVATE-player PRIVATE-pin PRIVATE-path\n'
            '18:03:02 Persistence corrupt, repair PRIVATE-password\n')
        before = {p.relative_to(self.server).as_posix(): p.read_bytes() for p in self.server.rglob('*') if p.is_file()}
        local_before = self.local.read_bytes()
        command = (f'"{self.server / "DayZServer_x64.exe"}" '
                   f'"-config={self.server / "Servahz/serverDZ.cfg"}" '
                   f'-profiles="{profiles}" -port=2302 -password=PRIVATE-command-password')
        process = self.storage_process(command)
        process['ExecutablePath'] = process['ExecutablePath'].swapcase()
        result = self.run_storage_probe([process])
        for token in ['executable t.o.v. pakket=GELIJK', '-config t.o.v. pakket=GELIJK',
                      '-profiles t.o.v. pakket=GELIJK', 'poort t.o.v. pakket=GELIJK',
                      'Proces #1 config instanceId=1', 'config missie t.o.v. pakket=GELIJK',
                      'toegang/schrijven', 'beschadiging/herstel', 'Verwachte pakketopslag storage_1: bestanden=1']:
            self.assertIn(token, result.stdout)
        reports = list((self.package / '.local/StorageDiagnostics').glob('*.txt'))
        self.assertEqual(len(reports), 1)
        for output in (reports[0].read_text(), result.stderr):
            for private in ['PRIVATE-', str(self.server), str(self.workshop), 'WORLD-MUST-NOT-CHANGE']:
                self.assertNotIn(private, output)
        self.assertNotIn('PRIVATE-', result.stdout)
        self.assertNotIn('Installatie #2', result.stdout)
        self.assertEqual(result.stdout.count('koppelingen naar servahz_ce/building_types.xml='), 1)
        self.assertEqual(self.local.read_bytes(), local_before)
        self.assertEqual(before, {p.relative_to(self.server).as_posix(): p.read_bytes() for p in self.server.rglob('*') if p.is_file()})

    def test_storage_diagnostic_reports_overrides_other_slots_and_ambiguity(self):
        self.install()
        other = self.server / 'mpmissions/PRIVATE-mission/storage_2'
        other.mkdir(parents=True)
        (other / 'types.bin').write_bytes(b'OTHER-WORLD')
        os.utime(other / 'types.bin', (1793296800, 1793296800))
        config = self.root / 'PRIVATE-config.cfg'
        config.write_text('instanceId = 2;\nstorageAutoFix = 1;\ntemplate = "PRIVATE-mission";\npasswordAdmin="PRIVATE-admin";')
        processes = [self.storage_process(f'-config="{config}" -mission="{other.parent}" -storage=PRIVATE-relative -port=9999'),
                     self.storage_process('-config=PRIVATE-relative -profiles=PRIVATE-a -profiles=PRIVATE-b')]
        result = self.run_storage_probe(processes)
        for token in ['Meerdere processen', '-config t.o.v. pakket=ANDERS', 'config instanceId=2',
                      'config missie t.o.v. pakket=ANDERS', '-mission=AANWEZIG', '-storage=AANWEZIG',
                      '-storage: relatief', 'storage_2: bestanden=1', 'poort t.o.v. pakket=ANDERS',
                      '-config t.o.v. pakket=ONBEKEND', '-profiles=DUBBEL']:
            self.assertIn(token, result.stdout)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
        self.assertEqual((other / 'types.bin').read_bytes(), b'OTHER-WORLD')

    def test_storage_diagnostic_reports_missing_and_unavailable_process_data(self):
        self.install()
        self.assertIn('Geen actief proces', self.run_storage_probe().stdout)
        result = self.run_storage_probe(unavailable=True)
        self.assertIn('Procescontrole niet beschikbaar', result.stdout)
        self.assertNotIn('PRIVATE-CIM-ERROR', result.stdout + result.stderr)
        result = self.run_storage_probe([self.storage_process('"PRIVATE-unbalanced')])
        self.assertIn('startselectie niet beschikbaar', result.stdout)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)

    def test_storage_diagnostic_checks_economy_ignore_and_rejects_external_xml(self):
        self.install()
        ignore = self.mission / 'cfgIgnoreList.xml'
        ignore.write_text('<ignore><type name="Fence" cheatCheck="1"/><type name="RaG_BB_Low_Wall"/><type name="PRIVATE-class"/></ignore>')
        economy = self.mission / 'db/economy.xml'
        economy.write_text('<economy><building load="1" save="0"/><dynamic load="1" save="1"/><vehicles load="1" save="1"/></economy>')
        result = self.run_storage_probe()
        for token in ['koppelingen naar servahz_ce/building_types.xml=1',
                      'RaG_BB_DoorKit aantal=1 lifetime=14400', 'RaG_BB_Low_WallKit aantal=1 lifetime=14400',
                      'ignorelijst actieve cheatCheck-regels=1; bouwgerelateerde regels=2',
                      'db/economy.xml building save=0']:
            self.assertIn(token, result.stdout)
        self.assertNotIn('PRIVATE-class', result.stdout + result.stderr)
        self.assertIn('cheatCheck="1"', ignore.read_text())
        ignore.write_text('<!DOCTYPE ignore [<!ENTITY secret SYSTEM "file:///PRIVATE-xml-path">]><ignore>&secret;</ignore>')
        result = self.run_storage_probe()
        self.assertIn('cfgIgnoreList.xml ontbreekt of ongeldig', result.stdout)
        self.assertNotIn('PRIVATE-xml-path', result.stdout + result.stderr)

    def test_storage_diagnostic_reads_db_economy_without_root_fallback(self):
        self.install()
        # Real DayZ layout: db/economy.xml. A valid root-level decoy must not
        # determine the result or hide a missing/invalid database configuration.
        decoy = self.mission / 'economy.xml'
        decoy.write_text('<economy><building load="0" save="0"/></economy>')
        database = self.mission / 'db/economy.xml'
        original = database.read_bytes()
        result = self.run_storage_probe()
        self.assertIn('Verwachte pakketmissie: db/economy.xml building load=1', result.stdout)
        self.assertIn('Verwachte pakketmissie: db/economy.xml building save=1', result.stdout)
        self.assertEqual(database.read_bytes(), original)
        database.unlink()
        result = self.run_storage_probe()
        self.assertIn('Verwachte pakketmissie: db/economy.xml ontbreekt of ongeldig', result.stdout)
        self.assertNotIn('Verwachte pakketmissie: db/economy.xml building save=0', result.stdout)
        self.assertFalse(database.exists())

    def test_storage_diagnostic_safe_details_for_recovery_and_restore_logs(self):
        self.install()
        profiles = self.server / 'Servahz/Profiles'
        log = profiles / 'PRIVATE-file-name.RPT'
        log.write_text('''19:22:20 [CE][Storage] Recovering corrupted save failed C:\\PRIVATE-root\\dynamic_000.bin PRIVATE-player PRIVATE-PIN
19:22:21 [CE][Storage] Recovering backup valid:yes C:\\PRIVATE-root\\vehicles.002 PRIVATE-address
19:22:23 [CE][Storage] Restoring file C:\\PRIVATE-root\\building.bin PRIVATE-password
19:22:35 !!! Corrupted stream after "RaG_BB_Low_Wall:PRIVATE-ID" at PRIVATE-coordinates
''')
        original = log.read_bytes()
        result = self.run_storage_probe()
        self.assertIn('corrupt,recover', result.stdout)
        self.assertIn('engine:CE,engine:Storage', result.stdout)
        self.assertIn('bestand:dynamic_000.bin', result.stdout)
        self.assertIn('valid:yes,bestand:vehicles.002', result.stdout)
        self.assertIn('restore,engine:CE,engine:Storage,bestand:building.bin', result.stdout)
        self.assertIn('corrupt,stream,code:RaG_BB_Low_Wall', result.stdout)
        self.assertIn('recover/restore alleen bewijst geen beschadiging', result.stdout)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
        report = max((self.package / '.local/StorageDiagnostics').glob('*.txt'))
        self.assertNotIn('PRIVATE-', report.read_text())
        self.assertEqual(log.read_bytes(), original)

    @unittest.skipUnless(os.name == 'nt', 'Real one-file CMD launcher requires Windows')
    def test_storage_diagnostic_native_cmd_launcher(self):
        self.install()
        command = self.package / '08-Opslagdiagnose.cmd'
        # Exact GitHub raw download bytes, without an installer converting lines.
        command.write_bytes((ROOT / command.name).read_bytes())
        result = subprocess.run(['cmd.exe', '/d', '/c', command.name], cwd=self.package,
                                input='', capture_output=True, text=True, timeout=45)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('opslagdiagnose 0.18.3', result.stdout)
        self.assertEqual(len(list((self.package / '.local/StorageDiagnostics').glob('*.txt'))), 1)

    def prepare_delivery(self):
        self.install()
        (self.mission / 'init.c').write_text('class CustomMission: MissionServer {};\nMission CreateCustomMission(string path) { return new CustomMission(); }\n')
        return '76561198000000123'  # Synthetic recipient, never a user's ID.

    def test_codelock_delivery_queue_backup_repeat_and_private_receipt(self):
        recipient = self.prepare_delivery()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'preserve existing character and base')
        initial = (self.mission / 'init.c').read_bytes()
        settings = self.local.read_bytes()
        rag = self.server / 'Servahz/Profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
        profile = rag.read_bytes()
        result = self.run_ps('Queue-CodeLock.ps1', '-SteamId', recipient)
        request_path = self.server / 'Servahz/Profiles/Servahz/CodeLockDelivery-request.json'
        request = json.loads(request_path.read_text())
        self.assertEqual(set(request), {'Schema', 'RequestId', 'SteamId'})
        self.assertEqual(request['SteamId'], recipient)
        self.assertRegex(request['RequestId'], r'^[0-9a-f]{32}$')
        self.assertNotIn(recipient, result.stdout + result.stderr)
        patched = (self.mission / 'init.c').read_text()
        self.assertIn('return new ServahzDeliveryMission();', patched)
        self.assertEqual(patched.count('#include'), 1)
        self.assertEqual(world.read_bytes(), b'preserve existing character and base')
        self.assertEqual(self.local.read_bytes(), settings)
        self.assertEqual(rag.read_bytes(), profile)
        backups = list((self.package / '.local/Backups').glob('codelock-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'mission/init.c').read_bytes(), initial)
        self.assertEqual((backups[0] / 'mission/storage_1/players.db').read_bytes(), world.read_bytes())
        self.run_ps('Queue-CodeLock.ps1')
        self.assertEqual(json.loads(request_path.read_text()), request)
        self.assertEqual(len(list((self.package / '.local/Backups').glob('codelock-*'))), 1)
        receipt = request_path.with_name('CodeLockDelivery-report.json')
        receipt.write_text(json.dumps(dict(RequestId=request['RequestId'], Status='Delivered', BatteryAttached=True)))
        before = request_path.read_bytes()
        self.run_ps('Queue-CodeLock.ps1')
        self.assertEqual(request_path.read_bytes(), before)
        result = self.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertIn('Geleverd: 1 DigitalCodeLock', result.stdout)
        self.assertNotIn(recipient, result.stdout + result.stderr)
        self.run_ps('Queue-CodeLock.ps1', '-Disable')
        self.assertFalse(request_path.exists())
        self.assertEqual(world.read_bytes(), b'preserve existing character and base')

    def test_codelock_delivery_refuses_bad_recipient_custom_init_and_pending_cleanup(self):
        recipient = self.prepare_delivery()
        init = self.mission / 'init.c'
        original = init.read_bytes()
        for value in ['bad-id', '0' * 16, '0' * 18, '\u0661' * 17]:
            self.run_ps('Queue-CodeLock.ps1', '-SteamId', value, ok=False)
            self.assertEqual(init.read_bytes(), original)
        init.write_text('Mission CreateCustomMission(string path) { return new OwnMission(); }')
        self.run_ps('Queue-CodeLock.ps1', '-SteamId', recipient, ok=False)
        self.assertIn('OwnMission', init.read_text())
        init.write_bytes(original)
        state = self.server / 'Servahz/Profiles/Servahz'
        state.mkdir()
        (state / 'LootRefresh-request.json').write_text(json.dumps(dict(RequestId='a' * 32)))
        self.run_ps('Queue-CodeLock.ps1', '-SteamId', recipient, ok=False)
        self.assertFalse((state / 'CodeLockDelivery-request.json').exists())
        self.assertFalse((self.package / '.local/Backups').exists())
        self.assertEqual(init.read_bytes(), original)

    def test_codelock_delivery_supports_completed_refresh_and_no_space_retry(self):
        recipient = self.prepare_delivery()
        init = self.mission / 'init.c'
        init.write_text(init.read_text().replace('return new CustomMission();', 'return new ServahzRefreshMission();') +
                        '#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_refresh/LootRefresh.c"\n')
        state = self.server / 'Servahz/Profiles/Servahz'
        state.mkdir()
        (state / 'LootRefresh-request.json').write_text(json.dumps(dict(RequestId='a' * 32)))
        (state / ('LootRefresh-' + 'a' * 32 + '.started')).write_text('completed earlier')
        self.run_ps('Queue-CodeLock.ps1', '-SteamId', recipient)
        request_path = state / 'CodeLockDelivery-request.json'
        request = json.loads(request_path.read_text())
        (state / ('CodeLockDelivery-' + request['RequestId'] + '.started')).write_text('claimed')
        # A claimed execution with no receipt must never automatically repeat.
        self.run_ps('Queue-CodeLock.ps1')
        self.assertEqual(json.loads(request_path.read_text()), request)
        (state / 'CodeLockDelivery-report.json').write_text(json.dumps(dict(RequestId=request['RequestId'], Status='NoInventorySpace', BatteryAttached=False)))
        self.run_ps('Queue-CodeLock.ps1')
        retried = json.loads(request_path.read_text())
        self.assertNotEqual(retried['RequestId'], request['RequestId'])
        self.assertEqual(retried['SteamId'], recipient)
        self.assertIn('return new ServahzDeliveryMission();', init.read_text())
        self.assertEqual(init.read_text().count('#include'), 1)
        self.run_ps('Queue-LootRefresh.ps1', '-CenterX', 8000, '-CenterZ', 7000)
        self.assertIn('return new ServahzDeliveryMission();', init.read_text())
        self.assertEqual(init.read_text().count('#include'), 1)
        self.run_ps('Queue-LootRefresh.ps1', '-Disable')
        self.assertIn('return new ServahzDeliveryMission();', init.read_text())

    @unittest.skipUnless(os.name == 'nt', 'Real delivery CMD launcher requires Windows')
    def test_codelock_delivery_native_cmd_launcher(self):
        recipient = self.prepare_delivery()
        command = self.package / '09-Codeslot-geven.cmd'
        command.write_bytes((ROOT / command.name).read_bytes())
        result = subprocess.run(['cmd.exe', '/d', '/c', command.name, '-SteamId', recipient], cwd=self.package,
                                input='', capture_output=True, text=True, timeout=45)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.server / 'Servahz/Profiles/Servahz/CodeLockDelivery-request.json').exists())
        self.assertNotIn(recipient, result.stdout + result.stderr)

    def prepare_military_chests(self):
        (self.baseline / 'mapgroupproto.xml').write_text('''<prototype>
          <group name="Land_Mil_Barracks1" lootmax="4"><usage name="Military"/>
            <container name="lootFloor" lootmax="4"><point pos="0 0 0" range="1.5" height="2"/></container></group>
          <group name="Land_Village_store" lootmax="4"><usage name="Town"/>
            <container name="lootFloor" lootmax="4"><point pos="0 0 0" range="1.5" height="2"/></container></group>
          </prototype>''')
        (self.baseline / 'mapgrouppos.xml').write_text('''<map>
          <group name="Land_Mil_Barracks1" pos="4000 100 5000" rpy="0 0 0"/>
          <group name="Land_Mil_Barracks1" pos="8000 100 9000" rpy="0 0 0"/>
          <group name="Land_Village_store" pos="2000 100 3000" rpy="0 0 0"/>
          </map>''')
        self.install()
        return self.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'

    def old_military_loadout(self, config, location):
        table_name = location['loot'][0]
        table = next(t for t in config['LootCategories'] if t['name'] == table_name)
        definition = next(d for d in config['LCPredefinedWeapons'] if d['defname'] == table['Loot'][0])
        sets = json.loads((ROOT / 'config/loot-balance.json').read_text())['WeaponSets']
        pair = next(s for s in sets if (s['Weapon'], s['Magazine']) == (definition['weapon'], definition['magazine']))
        return (['LC_Table_Servahz_Food'] * 3 + ['LC_Table_Servahz_Drink'] * 2 +
                ['LC_Table_Servahz_Medical', 'LC_Table_Servahz_Tools', definition['defname'],
                 pair['Ammo'], pair['Ammo'], pair['Magazine']])

    def test_military_chests_weapon_tables_first_matching_supplies_and_private_log_summary(self):
        profile = self.prepare_military_chests()
        config = json.loads(profile.read_text())
        military = [l for l in config['LootChestsLocations'] if l['name'].startswith('Servahz_Weapons_')]
        self.assertEqual(len(military), 2)
        sets = json.loads((ROOT / 'config/loot-balance.json').read_text())['WeaponSets']
        for location in military:
            table = next(t for t in config['LootCategories'] if t['name'] == location['loot'][0])
            self.assertTrue(table['name'].startswith('LC_Table_Weapons_Servahz_'))
            self.assertEqual(len(table['Loot']), 1)
            definition = next(d for d in config['LCPredefinedWeapons'] if d['defname'] == table['Loot'][0])
            pair = next(s for s in sets if s['Weapon'] == definition['weapon'])
            self.assertEqual(location['loot'][1:4], [pair['Magazine'], pair['Ammo'], pair['Ammo']])
            self.assertEqual(location['loot'][4:], ['LC_Table_Servahz_Food', 'LC_Table_Servahz_Drink', 'LC_Table_Servahz_Medical'])
            self.assertFalse(any(x.startswith('LC_predefined_') for x in location['loot']))
        log = profile.parent / 'LootChests_LOG.txt'
        log.write_text('Weapon does not fit, chest full PRIVATE-player PRIVATE-coordinates PRIVATE-PIN\n'
                       'Weapon class not found PRIVATE-item PRIVATE-password\n')
        before = profile.read_bytes(), log.read_bytes()
        result = self.run_ps('Test-Server.ps1', '-StaticOnly')
        self.assertIn('2 groene locaties, 2 met wapentabel, 0 met losse oude', result.stdout)
        self.assertIn('ruimte/te groot=1', result.stdout)
        self.assertIn('klasse=1', result.stdout)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
        self.assertEqual((profile.read_bytes(), log.read_bytes()), before)

    def test_military_chests_upgrade_exact_old_loadout_preserves_custom_positions_world_and_backup(self):
        profile = self.prepare_military_chests()
        config = json.loads(profile.read_text())
        military = [l for l in config['LootChestsLocations'] if l['name'].startswith('Servahz_Weapons_')]
        expected = list(military[0]['loot'])
        for location in military:
            location['loot'] = self.old_military_loadout(config, location)
        military[0]['pos'] = ['4100 123 5100|19 0 0']  # Existing private placement must survive.
        military[0]['UnknownLocationField'] = 'keep private preference'
        military[1]['loot'].append('NailBox')  # Real administrator change must not be overwritten.
        custom = json.loads(json.dumps(military[1]))
        brown = next(l for l in config['LootChestsLocations'] if l['name'].startswith('Servahz_Food_'))
        brown_before = json.loads(json.dumps(brown))
        config['LootCategories'] = [t for t in config['LootCategories'] if not t['name'].startswith('LC_Table_Weapons_')]
        config['PrivateUnknownField'] = {'Keep': 'PRIVATE-profile'}
        profile.write_text(json.dumps(config))
        before = profile.read_bytes()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'keep existing base and gear')
        local = self.local.read_bytes()
        init = (self.mission / 'init.c').read_bytes()
        result = self.install()
        self.assertIn('1 bestaande militaire pakketkisten bijgewerkt', result.stdout)
        updated = json.loads(profile.read_text())
        self.assertEqual(len(updated['LootChestsLocations']), len(config['LootChestsLocations']))
        upgraded = next(l for l in updated['LootChestsLocations'] if l['name'] == military[0]['name'])
        self.assertEqual(upgraded['loot'], expected)
        self.assertEqual(upgraded['pos'], military[0]['pos'])
        self.assertEqual(upgraded['UnknownLocationField'], military[0]['UnknownLocationField'])
        self.assertIn(custom, updated['LootChestsLocations'])
        self.assertIn(brown_before, updated['LootChestsLocations'])
        self.assertEqual(updated['LCPredefinedWeapons'], config['LCPredefinedWeapons'])
        self.assertEqual(updated['PrivateUnknownField'], config['PrivateUnknownField'])
        self.assertEqual(world.read_bytes(), b'keep existing base and gear')
        self.assertEqual(self.local.read_bytes(), local)
        self.assertEqual((self.mission / 'init.c').read_bytes(), init)
        backups = list((self.server / 'Servahz/Backups').glob('config-*/Profiles/CJ_LootChests/LootChests_V106.json'))
        self.assertTrue(any(p.read_bytes() == before for p in backups))
        stable = profile.read_bytes()
        self.install()
        self.assertEqual(profile.read_bytes(), stable)

    def test_military_chests_refuse_missing_weapon_table_definition_and_preserve_name_collision(self):
        profile = self.prepare_military_chests()
        config = json.loads(profile.read_text())
        table = next(t for t in config['LootCategories'] if t['name'].startswith('LC_Table_Weapons_'))
        original = list(table['Loot'])
        table['Loot'] = ['LC_predefined_Missing']
        profile.write_text(json.dumps(config))
        before = profile.read_bytes()
        mission_before = (self.mission / 'db/types.xml').read_bytes()
        self.assertIn('ontbrekende wapenset', ' '.join(self.install(ok=False).stderr.split()))
        self.assertEqual(profile.read_bytes(), before)
        self.assertEqual((self.mission / 'db/types.xml').read_bytes(), mission_before)
        table['Loot'] = original
        location = next(l for l in config['LootChestsLocations'] if l['loot'][0] == table['name'])
        location['loot'] = self.old_military_loadout(config, location)
        other = next(d['defname'] for d in config['LCPredefinedWeapons'] if d['defname'] != original[0])
        table['Loot'] = [other]  # An administrator's table with our new name.
        profile.write_text(json.dumps(config))
        before = profile.read_bytes()
        self.install()
        self.assertEqual(profile.read_bytes(), before)

    def test_lootchests_unlocked_contents_placement_and_culture(self):
        # Deliberately use a non-symmetric local point and a 90-degree building.
        (self.baseline / 'mapgroupproto.xml').write_text('''<prototype>
          <group name="Land_Village_store" lootmax="3"><usage name="Town"/>
            <container name="lootFloor" lootmax="3">
              <point pos="2 -1 3" range="1.5" height="2"/>
            </container></group></prototype>''')
        (self.baseline / 'mapgrouppos.xml').write_text('''<map>
          <group name="Land_Village_store" pos="2000 100 3000" rpy="0 0 90" a="0"/>
          <group name="Land_Village_store" pos="2010 100 3010" rpy="0 0 0" a="90"/>
          <group name="Land_Village_store" pos="5000 100 3000" rpy="4 0 0" a="90"/>
          <group name="Land_Village_store" pos="6000 100 3000" rpy="0 0 -90" a="180"/>
          </map>''')
        probe = self.package / 'scripts/Probe-ChestCulture.ps1'
        probe.write_text('''
param([string]$ServerPath, [string]$WorkshopPath)
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
[Threading.Thread]::CurrentThread.CurrentCulture = 'nl-NL'
& (Join-Path $PSScriptRoot 'Install-Server.ps1') -ServerPath $ServerPath -WorkshopPath $WorkshopPath
''')
        self.run_ps('Probe-ChestCulture.ps1', '-ServerPath', self.server, '-WorkshopPath', self.workshop)
        profile = self.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        config = json.loads(profile.read_text(encoding='utf-8-sig'))
        locations = config['LootChestsLocations']
        self.assertEqual(len(locations), 2)
        xyz = [list(map(float, x['pos'][0].split('|')[0].split())) for x in locations]
        self.assertEqual(xyz, [[2003.0, 99.03, 2998.0], [5997.0, 99.03, 3002.0]])
        self.assertTrue(all(x['keyclass'] == '' and x['openable'] == 2 for x in locations))
        self.assertTrue(all(x['number'] == 1 and x['lootrandomize'] == 0 for x in locations))
        self.assertTrue(all(len(x['loot']) >= 10 for x in locations))
        self.assertEqual(config['RandomQuantity'], 0)
        self.assertIn('2003.0', (profile.parent / 'Servahz-Lootkisten.csv').read_text())
        self.run_ps('Test-Server.ps1', '-StaticOnly')

    def test_lootchests_preserve_profile_world_and_refuse_locked_profile(self):
        self.install()
        relative = 'CJ_LootChests/LootChests_V106.json'
        profile = self.server / 'Servahz/Profiles' / relative
        config = json.loads(profile.read_text())
        config['PrivateSentinel'] = 'keep these preferences'
        profile.write_text(json.dumps(config))
        before = profile.read_bytes()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'world sentinel')
        settings = self.local.read_bytes()
        self.install()
        self.assertEqual(profile.read_bytes(), before)
        self.assertEqual(world.read_bytes(), b'world sentinel')
        self.assertEqual(json.loads(self.local.read_bytes()), json.loads(settings))
        backups = list((self.server / 'Servahz/Backups').glob('config-*/Profiles/' + relative))
        self.assertTrue(any(p.read_bytes() == before for p in backups))
        config['LootChestsLocations'][0]['keyclass'] = 'CJ_Key1'
        profile.write_text(json.dumps(config))
        locked = profile.read_bytes()
        mission_before = (self.mission / 'db/types.xml').read_bytes()
        self.assertIn('vergrendelde', self.install(ok=False).stderr)
        self.assertEqual(profile.read_bytes(), locked)
        self.assertEqual((self.mission / 'db/types.xml').read_bytes(), mission_before)
        self.assertEqual(world.read_bytes(), b'world sentinel')

    def test_lootchests_generated_economy_and_weapon_pairs(self):
        self.install()
        profile = self.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        config = json.loads(profile.read_text())
        locations = config['LootChestsLocations']
        self.assertGreaterEqual(len(locations), 1)
        self.assertLessEqual(len(locations), 256)
        positions = [list(map(float, x['pos'][0].split('|')[0].split())) for x in locations]
        for i, a in enumerate(positions):
            self.assertTrue(0 < a[0] < 15360 and 0 < a[2] < 15360)
            for b in positions[:i]:
                self.assertGreaterEqual((a[0]-b[0])**2 + (a[2]-b[2])**2, 349.99**2)
        pairs = {(x['Weapon'], x['Magazine']) for x in json.loads((ROOT / 'config/loot-balance.json').read_text())['WeaponSets']}
        for weapon in config['LCPredefinedWeapons']:
            self.assertIn((weapon['weapon'], weapon['magazine']), pairs)
        if os.environ.get('SERVAHZ_VANILLA_MISSION'):
            vanilla_names = {n.get('name') for n in ET.parse(self.baseline / 'db/types.xml').findall('type')}
            self.assertFalse({n for table in config['LootCategories'] if not table['name'].startswith('LC_Table_Weapons_') for n in table['Loot']} - vanilla_names)
            self.assertGreater(len(locations), 100)
            self.assertGreater(len(config['LCPredefinedWeapons']), 5)
            self.assertEqual({x['name'].split('_')[1] for x in locations}, {'Food', 'General', 'Medical', 'Weapons', 'Building'})
        economy = ET.parse(self.mission / 'servahz_ce/lootchest_types.xml')
        for location in locations:
            for name in location['chest']:
                node = economy.find(f"type[@name='{name}']")
                self.assertEqual(node.findtext('nominal'), '0')
                self.assertEqual(node.findtext('min'), '0')
                self.assertGreaterEqual(int(node.findtext('lifetime')), 86400)
        self.run_ps('Test-Server.ps1', '-StaticOnly')
        economy.find('type/lifetime').text = '0'
        economy.write(self.mission / 'servahz_ce/lootchest_types.xml')
        self.assertIn('kisteconomie', self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False).stderr)

    def test_lootchests_skip_private_base_without_changing_protection(self):
        (self.baseline / 'mapgroupproto.xml').write_text('''<prototype>
          <group name="Land_Village_store"><usage name="Town"/>
            <container name="lootFloor"><point pos="0 0 0" range="2" height="2"/></container>
          </group></prototype>''')
        (self.baseline / 'mapgrouppos.xml').write_text('''<map>
          <group name="Land_Village_store" pos="2000 100 3000" rpy="0 0 0"/>
          <group name="Land_Village_store" pos="6000 100 3000" rpy="0 0 0"/>
          </map>''')
        private = self.package / '.local/loot-refresh-settings.json'
        private.parent.mkdir()
        private.write_text(json.dumps({'CenterX': 2000, 'CenterZ': 3000, 'Radius': 500}))
        previous = private.read_bytes()
        self.install()
        profile = self.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        locations = json.loads(profile.read_text())['LootChestsLocations']
        self.assertEqual(len(locations), 1)
        self.assertEqual(locations[0]['pos'], ['6000.000 100.030 3000.000|0.000 0 0'])
        self.assertEqual(private.read_bytes(), previous)

    def test_supplies_locations_amounts_and_restore(self):
        # Independent representative cases include civilian ammunition, disabled/event
        # weapons, raw building material and unrelated loot. No real saves are used.
        tree = ET.parse(self.baseline / 'db/types.xml')
        cases = [('CivilRifle', 'weapons', 4, '0', '0'),
                 ('TestMilitaryRifle', 'weapons', 2, '0', '0'),
                 ('Ammo_Example', 'weapons', 10, '0', '0'),
                 ('AmmoBox_Example', 'tools', 5, '0', '0'),
                 ('Mag_Example', 'tools', 6, '0', '0'),
                 ('EventRifle', 'weapons', 3, '1', '0'),
                 ('DisabledRifle', 'weapons', 0, '0', '0'),
                 ('CraftedRifle', 'weapons', 3, '0', '1'),
                 ('UnrelatedFood', 'food', 10, '0', '0')]
        # Replace/add just these test cases, retaining real CE data when requested.
        for name, category, amount, event, crafted in cases:
            item = ET.SubElement(tree.getroot(), 'type', name=name)
            ET.SubElement(item, 'nominal').text = str(amount)
            ET.SubElement(item, 'min').text = str(amount // 2)
            ET.SubElement(item, 'flags', deloot=event, crafted=crafted)
            ET.SubElement(item, 'category', name=category)
            ET.SubElement(item, 'tag', name='shelves')
            ET.SubElement(item, 'usage', name='Village')
            if name == 'TestMilitaryRifle':
                ET.SubElement(item, 'usage', name='Military')
        if tree.find("type[@name='WoodenPlank']") is None:
            item = ET.SubElement(tree.getroot(), 'type', name='WoodenPlank')
            ET.SubElement(item, 'nominal').text = '0'
            ET.SubElement(item, 'min').text = '0'
            ET.SubElement(item, 'flags', deloot='0', crafted='1')
        tree.write(self.baseline / 'db/types.xml')
        baseline = (self.baseline / 'db/types.xml').read_bytes()
        usages = {'Coast', 'ContaminatedArea', 'Farm', 'Firefighter', 'Historical',
                  'Hunting', 'Industrial', 'Lunapark', 'Medic', 'Military', 'Office',
                  'Police', 'Prison', 'School', 'SeasonalEvent', 'Town', 'Village'}
        self.run_ps('Install-Server.ps1', '-ServerPath', self.server, '-WorkshopPath', self.workshop, '-TestMode')
        generated = ET.parse(self.mission / 'db/types.xml')
        for name, amount in [('CivilRifle', 64), ('Ammo_Example', 160),
                             ('TestMilitaryRifle', 96),
                             ('AmmoBox_Example', 80), ('Mag_Example', 96),
                             ('WoodenPlank', 160), ('NailBox', int(tree.findtext("type[@name='NailBox']/nominal")) * 16)]:
            item = generated.find(f"type[@name='{name}']")
            self.assertEqual(int(item.findtext('nominal')), amount, name)
            if name == 'TestMilitaryRifle':
                self.assertEqual(int(item.findtext('min')), 48)
            self.assertEqual({n.get('name') for n in item.findall('usage')}, usages)
            self.assertEqual({n.get('name') for n in item.findall('value')}, {'Tier1', 'Tier2', 'Tier3', 'Tier4'})
        for name in ('EventRifle', 'DisabledRifle', 'CraftedRifle', 'UnrelatedFood'):
            item = generated.find(f"type[@name='{name}']")
            self.assertEqual([n.get('name') for n in item.findall('usage')], ['Village'])
            self.assertEqual(item.find('tag').get('name'), 'shelves')
        building_file = self.mission / 'servahz_ce/building_types.xml'
        building = ET.parse(building_file)
        self.assertEqual(building.findtext("type[@name='ExpansionWallKit']/nominal"), '120')
        self.assertEqual(building.findtext("type[@name='ExpansionLumber3']/nominal"), '160')
        self.assertEqual(building.findtext("type[@name='ExpansionWall6x3']/nominal"), '0')
        self.assertEqual({n.get('name') for n in building.findall("type[@name='ExpansionWallKit']/usage")}, usages)
        first = (self.mission / 'db/types.xml').read_bytes(), building_file.read_bytes()
        self.install()
        self.assertEqual(first, ((self.mission / 'db/types.xml').read_bytes(), building_file.read_bytes()))
        current = json.loads(self.local.read_text())
        current['TestSuppliesEverywhere'] = False
        current['TestMilitaryEverywhere'] = False
        self.local.write_text(json.dumps(current))
        self.install()
        restored = ET.parse(self.mission / 'db/types.xml')
        self.assertEqual(restored.findtext("type[@name='WoodenPlank']/nominal"), '0')
        for original, result in zip(tree.findall('type'), restored.findall('type')):
            for tag in ('usage', 'value', 'flags', 'category', 'tag'):
                self.assertEqual([n.attrib for n in original.findall(tag)],
                                 [n.attrib for n in result.findall(tag)])
        self.assertEqual(building_file.read_bytes(), (ROOT / 'config/mission/servahz_ce/building_types.xml').read_bytes())
        self.assertEqual((self.baseline / 'db/types.xml').read_bytes(), baseline)

    def test_supplies_setting_requires_boolean(self):
        self.install()
        current = json.loads(self.local.read_text())
        current['TestSuppliesEverywhere'] = 'true'
        self.local.write_text(json.dumps(current))
        self.assertIn('TestSuppliesEverywhere', self.install(ok=False).stderr)

    def test_missing_mod_does_not_create_mission(self):
        shutil.rmtree(self.workshop / self.mods[-1]["Id"])
        result = self.install(ok=False)
        self.assertIn('Mod ontbreekt', ' '.join(result.stderr.split()))
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

    def test_static_check_detects_map_item_requirement(self):
        self.install()
        path = self.mission / 'expansion/settings/MapSettings.json'
        data = json.loads(path.read_text())
        data['NeedGPSItemForKeyBinding'] = 1
        path.write_text(json.dumps(data))
        result = self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False)
        self.assertIn('Kaart/minimap', result.stderr)

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
        self.assertEqual(mods[0][len('"-mod='):-1].split(';'),
                         [str(self.server / 'Servahz/Mods' / mod['Folder']) for mod in self.mods])
        for mod in self.mods:
            self.assertIn(str(self.server / 'Servahz/Mods' / mod['Folder']), mods[0])
        config = (self.server / 'Servahz/serverDZ.cfg').read_text()
        self.assertIn('template = "servahz.chernarusplus";', config)
        self.assertIn('verifySignatures = 2;', config)
        self.assertIn('enableCfgGameplayFile = 1;', config)

    def test_windows_powershell_json_array_pipeline_shape(self):
        # Reproduce 5.1 ConvertFrom-Json's single-array pipeline output on PS7.
        self.install()
        probe = self.package / 'scripts/Probe-JsonArray.ps1'
        probe.write_text('''
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
& (Get-Module Servahz) {
    function script:ConvertFrom-Json {
        param([Parameter(ValueFromPipeline = $true)][string]$InputObject)
        process {
            $parsed = Microsoft.PowerShell.Utility\\ConvertFrom-Json -InputObject $InputObject
            Write-Output -NoEnumerate $parsed
        }
    }
}
$mods = @(Get-ModManifest)
if ($mods.Count -ne 18) { throw 'Expected eighteen individual mod objects' }
foreach ($mod in $mods) {
    if ($mod -is [array] -or $mod.Folder -isnot [string]) { throw 'Nested mod array' }
}
if (!(Get-PSDrive -Name F -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name F -PSProvider FileSystem -Root $PSScriptRoot | Out-Null
}
$layout = [pscustomobject]@{ Runtime = 'F:\\steam installatie\\DayZServer\\Servahz'; Config = 'test.cfg'; Profiles = 'test profiles' }
$s = [pscustomobject]@{ GamePort = 2302 }
Write-Utf8File (Join-Path $PSScriptRoot 'legacy-arguments.json') (ConvertTo-Json @(Get-LaunchArguments $s $layout))
''')
        self.run_ps('Probe-JsonArray.ps1')
        args = json.loads((probe.parent / 'legacy-arguments.json').read_text())
        mod_arg = next(arg for arg in args if arg.startswith('"-mod='))
        paths = mod_arg[len('"-mod='):-1].split(';')
        self.assertEqual(len(paths), len(self.mods))
        for path, mod in zip(paths, self.mods):
            self.assertTrue(path.endswith(mod['Folder']))
            self.assertEqual(path.count('steam installatie'), 1)

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



    def test_loot_summary_filters_rpt_to_class_names(self):
        self.install()
        rpt = self.server / 'Servahz/Profiles/test.RPT'
        rpt.write_text('Cannot spawn SNAFU_FixtureMissing player=76561111111111111 address=192.0.2.1 secret-fixture-password\n')
        result = self.run_ps('Test-Server.ps1','-StaticOnly')
        self.assertIn('SNAFU_FixtureMissing',result.stdout)
        for private in ['76561111111111111','192.0.2.1','secret-fixture-password']:
            self.assertNotIn(private,result.stdout+result.stderr)
        self.assertIn('Lootbalans 0.17',result.stdout)
        self.assertIn('modwapens=',result.stdout)

    def test_static_check_detects_unusable_ammo_supply(self):
        self.install()
        path = self.mission / 'servahz_ce/extra_types.xml'
        types = ET.parse(path)
        types.find("type[@name='SNAFU_Ammo_338']/quantmin").text = '10'
        types.write(path)
        result = self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False)
        self.assertIn('SNAFU_Ammo_338',result.stderr)

    def test_rare_weapon_boost_matching_supplies_tiers_repeat_and_save_preservation(self):
        balance = json.loads((ROOT / 'config/loot-balance.json').read_text())
        rare = balance['RareWeaponBoost']
        self.assertEqual(len(set(rare['Weapons'])), 12)
        original = ET.parse(self.package / 'config/mission/servahz_ce/extra_types.xml')
        baseline = self.baseline / 'db/types.xml'
        tree = ET.parse(baseline)
        for name in ['Ammo_308Win', 'Ammo_556x45', 'Ammo_45ACP', 'Mag_STANAG_30Rnd']:
            if tree.find(f"type[@name='{name}']") is not None:
                continue
            node = ET.SubElement(tree.getroot(), 'type', name=name)
            for field, value in [('nominal', 30), ('min', 20), ('restock', 600), ('lifetime', 14400), ('quantmin', 10), ('quantmax', 30)]:
                ET.SubElement(node, field).text = str(value)
            ET.SubElement(node, 'flags', deloot='0', crafted='0')
            ET.SubElement(node, 'category', name='weapons')
            ET.SubElement(node, 'usage', name='Military')
            ET.SubElement(node, 'value', name='Tier3')
        tree.write(baseline)
        baseline_bytes = baseline.read_bytes()
        self.install()
        world = self.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'keep base and dropped personal gear')
        profile = self.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        profile_bytes = profile.read_bytes()
        init = (self.mission / 'init.c').read_bytes()
        for test_mode, factor in [(False, 1), (True, 2)]:
            settings = json.loads(self.local.read_text())
            settings.update(TestSuppliesEverywhere=test_mode, TestFastRestock=False,
                            ServerPassword='PRIVATE-fixture-password')
            self.local.write_text(json.dumps(settings))
            self.install()
            extra = ET.parse(self.mission / 'servahz_ce/extra_types.xml')
            vanilla = ET.parse(self.mission / 'db/types.xml')
            for name in rare['Weapons']:
                gun = extra.find(f"type[@name='{name}']")
                before = original.find(f"type[@name='{name}']")
                self.assertEqual(int(gun.findtext('nominal')), 90 * factor)
                self.assertEqual(int(gun.findtext('min')), 81 * factor)
                self.assertEqual(gun.findtext('restock'), '0')
                self.assertEqual({n.get('name') for n in gun.findall('value')}, {'Tier1', 'Tier2', 'Tier3', 'Tier4'})
                self.assertIn('Military', {n.get('name') for n in gun.findall('usage')})
                if not test_mode:
                    self.assertEqual([n.attrib for n in gun.findall('usage')], [n.attrib for n in before.findall('usage')])
                for field in ['lifetime', 'flags']:
                    self.assertEqual(gun.find(field).attrib, before.find(field).attrib)
                    self.assertEqual(gun.findtext(field), before.findtext(field))
                pair = next(s for s in balance['WeaponSets'] if s['Weapon'] == name)
                for supply_name in [pair['Magazine'], pair['Ammo']]:
                    supply = vanilla.find(f"type[@name='{supply_name}']")
                    if supply is None:
                        supply = extra.find(f"type[@name='{supply_name}']")
                    self.assertIsNotNone(supply)
                    self.assertGreaterEqual(int(supply.findtext('nominal')), 180 * factor)
                    self.assertGreaterEqual(int(supply.findtext('min')), 144 * factor)
                    self.assertEqual(supply.findtext('restock'), '0')
                    self.assertEqual(supply.findtext('quantmin'), '80')
                    self.assertEqual(supply.findtext('quantmax'), '100')
            self.assertEqual(int(extra.findtext("type[@name='Expansion_M9']/nominal")), 30 * factor)
            result = self.run_ps('Test-Server.ps1', '-StaticOnly')
            self.assertIn('Zeldzame wapens 0.18.7: 12 typen', result.stdout)
            self.assertIn(f'wereld-doel={1080 * factor}', result.stdout)
            self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
            before_files = [(p, p.read_bytes()) for p in [self.mission / 'db/types.xml', self.mission / 'servahz_ce/extra_types.xml']]
            self.install()
            for path, content in before_files:
                self.assertEqual(path.read_bytes(), content)
            self.assertEqual(profile.read_bytes(), profile_bytes)
            self.assertEqual((self.mission / 'init.c').read_bytes(), init)
            self.assertEqual(world.read_bytes(), b'keep base and dropped personal gear')
            self.assertEqual(json.loads(self.local.read_text())['ServerPassword'], settings['ServerPassword'])
        self.assertEqual(baseline.read_bytes(), baseline_bytes)
        extra_path = self.mission / 'servahz_ce/extra_types.xml'
        generated = ET.parse(extra_path)
        gun = generated.find("type[@name='Expansion_AWM']")
        gun.remove(gun.find("value[@name='Tier1']"))
        generated.write(extra_path)
        before = extra_path.read_bytes()
        self.assertIn('Tierkoppeling', self.run_ps('Test-Server.ps1', '-StaticOnly', ok=False).stderr)
        self.assertEqual(extra_path.read_bytes(), before)

    def test_rare_weapon_boost_never_enables_disabled_crafted_or_event_only_mod_guns(self):
        path = self.package / 'config/mission/servahz_ce/extra_types.xml'
        tree = ET.parse(path)
        cases = [('Expansion_AWM', 'disabled'), ('GCGN_HK416', 'event'), ('SNAFUM24_GUN', 'crafted')]
        for name, mode in cases:
            gun = tree.find(f"type[@name='{name}']")
            gun.find('restock').text = '321'
            if mode == 'disabled':
                gun.find('nominal').text = '0'
                gun.find('min').text = '0'
            else:
                gun.find('flags').set('deloot' if mode == 'event' else 'crafted', '1')
        tree.write(path)
        self.install()
        generated = ET.parse(self.mission / 'servahz_ce/extra_types.xml')
        for name, _ in cases:
            def values(document):
                return [(n.tag, n.attrib, (n.text or '').strip())
                        for n in document.find(f"type[@name='{name}']").iter()]
            self.assertEqual(values(generated), values(tree))

    def test_food_slots_weapon_caps_and_matching_supplies(self):
        path = self.baseline / 'db/types.xml'
        types = ET.parse(path)
        def add_type(name, nominal, minimum, category, *, deloot='0', crafted='0'):
            old = types.find(f"type[@name='{name}']")
            if old is not None:
                types.getroot().remove(old)
            node = ET.SubElement(types.getroot(), 'type', name=name)
            for key, amount in [('nominal', nominal), ('min', minimum), ('lifetime', 14400), ('quantmin', 10), ('quantmax', 30)]:
                ET.SubElement(node, key).text = str(amount)
            ET.SubElement(node, 'flags', deloot=deloot, crafted=crafted)
            ET.SubElement(node, 'category', name=category)
            ET.SubElement(node, 'usage', name='Hunting')
            ET.SubElement(node, 'value', name='Tier3')
        for name, nominal, minimum, category, flags in [
            ('BakedBeansCan',15,12,'food',{}), ('Apple',0,0,'food',{}),
            ('Izh18',50,35,'weapons',{}), ('SVD',4,2,'weapons',{'deloot':'1'}),
            ('Ammo_308Win',50,30,'weapons',{}), ('Mag_STANAG_30Rnd',5,2,'weapons',{})]:
            add_type(name,nominal,minimum,category,**flags)
        types.write(path)
        groups_path = self.baseline / 'mapgroupproto.xml'
        groups = ET.parse(groups_path)
        for name, limit in [('Land_City_Store_Test',8), ('Land_House_1W_Test',8), ('Land_Workshop1_Test',8), ('Land_House_Disabled_Test',0)]:
            group = ET.SubElement(groups.getroot(),'group',name=name,lootmax=str(limit))
            ET.SubElement(group,'usage',name='Town')
            shelf = ET.SubElement(group,'container',name='lootshelves',lootmax='2')
            for category in ['tools','food']:
                ET.SubElement(shelf,'category',name=category)
            ET.SubElement(shelf,'tag',name='shelves')
            for i in range(6):
                ET.SubElement(shelf,'point',pos=f'{i} 0 0',range='0.2',height='0.5')
            floor = ET.SubElement(group,'container',name='lootFloor',lootmax='4')
            ET.SubElement(floor,'category',name='tools')
            ET.SubElement(floor,'tag',name='floor')
            for i in range(5):
                ET.SubElement(floor,'point',pos=f'{i} 1 0',range='0.5',height='1')
        groups.write(groups_path)
        source_types = path.read_bytes()
        source_groups = groups_path.read_bytes()
        self.install()
        save = self.mission / 'storage_1/players.db'
        save.parent.mkdir(); save.write_bytes(b'keep player')
        for test_mode in [False, True]:
            settings = json.loads(self.local.read_text())
            settings['TestSuppliesEverywhere'] = test_mode
            settings['TestFastRestock'] = False
            self.local.write_text(json.dumps(settings))
            previous = None
            for _ in range(2):
                self.install()
                generated = ET.parse(self.mission / 'db/types.xml')
                self.assertEqual(generated.findtext("type[@name='BakedBeansCan']/nominal"), '600')
                self.assertEqual(generated.findtext("type[@name='BakedBeansCan']/min"), '540')
                self.assertEqual(generated.findtext("type[@name='Apple']/nominal"), '0')
                self.assertEqual(generated.findtext("type[@name='SVD']/nominal"), '20')
                self.assertEqual(generated.findtext("type[@name='Izh18']/nominal"), '24' if test_mode else '12')
                for name in ['Ammo_308Win','Mag_STANAG_30Rnd']:
                    node = generated.find(f"type[@name='{name}']")
                    self.assertEqual(node.findtext('quantmin'),'80')
                    self.assertEqual(node.findtext('quantmax'),'100')
                    expected_usages = {'Town','Village','Military'} if name == 'Ammo_308Win' or test_mode else {'Military'}
                    self.assertTrue(expected_usages <= {u.get('name') for u in node.findall('usage')})
                    expected_tiers = {'Tier1','Tier2','Tier3','Tier4'}
                    self.assertEqual({v.get('name') for v in node.findall('value')},expected_tiers)
                updated = ET.parse(self.mission / 'mapgroupproto.xml')
                for before in groups.findall('group'):
                    after = updated.find(f"group[@name='{before.get('name')}']")
                    self.assertEqual(sorted(tuple(sorted(x.attrib.items())) for x in before.findall('.//point')),
                                     sorted(tuple(sorted(x.attrib.items())) for x in after.findall('.//point')))
                    expected_cap = '11' if before.get('name') in ['Land_City_Store_Test','Land_House_1W_Test'] else before.get('lootmax')
                    if before.get('name').endswith('_Test'):
                        self.assertEqual(after.get('lootmax'),expected_cap)
                for name, limit in [('Land_City_Store_Test',6),('Land_House_1W_Test',5)]:
                    shelf = updated.find(f"group[@name='{name}']/container[@name='lootshelves']")
                    self.assertEqual(len(shelf.findall('point')),6)
                    self.assertEqual(shelf.get('lootmax'),str(limit))
                    self.assertEqual([n.get('name') for n in shelf.findall('category')],['food'])
                    self.assertIsNotNone(updated.find(f"group[@name='{name}']/container[@name='lootFloor']/category[@name='food']"))
                for name in ['Land_Workshop1_Test','Land_House_Disabled_Test']:
                    shelf = updated.find(f"group[@name='{name}']/container[@name='lootshelves']")
                    self.assertEqual(len(shelf.findall('category')),2)
                    self.assertIsNone(updated.find(f"group[@name='{name}']/container[@name='lootFloor']/category[@name='food']"))
                self.assertIn('floor',{n.get('name') for n in generated.find("type[@name='BakedBeansCan']").findall('tag')})
                # Rare-weapon supply floors intentionally exceed the general ammo cap.
                self.assertEqual(int(generated.findtext("type[@name='Ammo_308Win']/nominal")),360 if test_mode else 180)
                current = ((self.mission / 'db/types.xml').read_bytes(),(self.mission / 'mapgroupproto.xml').read_bytes())
                if previous is not None:
                    self.assertEqual(current,previous)
                previous = current
        self.assertEqual(path.read_bytes(),source_types)
        self.assertEqual(groups_path.read_bytes(),source_groups)
        self.assertEqual(save.read_bytes(),b'keep player')

    def prepare_refresh(self):
        self.install()
        init = 'class CustomMission {}\nMission CreateCustomMission(string path) { return new CustomMission(); }\n'
        (self.mission / 'init.c').write_text(init)
        save = self.mission / 'storage_1/players.db'
        save.parent.mkdir(exist_ok=True); save.write_bytes(b'precious-world')
        return init

    def test_loot_refresh_preview_apply_backup_and_disable(self):
        init = self.prepare_refresh()
        settings = self.local.read_bytes()
        self.run_ps('Queue-LootRefresh.ps1', '-CenterX',8000,'-CenterZ',7000)
        folder = self.server / 'Servahz/Profiles/Servahz'
        request_path = folder / 'LootRefresh-request.json'
        preview = json.loads(request_path.read_text())
        self.assertTrue(preview['PreviewOnly'])
        self.assertEqual((preview['CenterX'],preview['CenterZ'],preview['Radius']),(8000,7000,500))
        self.assertNotIn('NailBox',preview['AllowedTypes'])
        self.assertNotIn('ExpansionFloorKit',preview['AllowedTypes'])
        self.assertIn('GCGN_Ammo_762x51',preview['AllowedTypes'])
        self.assertIn('AmmoBox_Expansion_338_15rnd',preview['AllowedTypes'])
        self.assertIn('SNAFUHoneyBadger_Black',preview['AllowedTypes'])
        self.assertEqual((Path(preview['BackupPath']) / 'mission/storage_1/players.db').read_bytes(),b'precious-world')
        patched = (self.mission / 'init.c').read_text()
        self.assertEqual(patched.count('#include'),1)
        self.assertIn('return new ServahzRefreshMission();',patched)
        # Installer updates preserve the optional hook without duplicating it.
        self.install()
        self.assertEqual((self.mission / 'init.c').read_text(),patched)
        report_path = folder / 'LootRefresh-report.json'
        report_path.write_text('{')  # A live writer must not block server checks.
        self.run_ps('Test-Server.ps1','-StaticOnly')
        report = {'RequestId':preview['RequestId'],'PolicyHash':preview['PolicyHash'],
                  'Status':'PreviewCompleted','PreviewOnly':True,'Cells':225,
                  'CenterX':8000,'CenterZ':7000,'Radius':500,
                  'Candidates':10,'Deleted':0,'Protected':2,'Message':'test report'}
        report_path.write_text(json.dumps(report))
        # A different protection circle cannot reuse a completed preview.
        self.run_ps('Queue-LootRefresh.ps1','-Apply','-Radius',600,ok=False)
        self.assertEqual(json.loads(request_path.read_text()),preview)
        self.run_ps('Queue-LootRefresh.ps1','-Apply')
        apply = json.loads(request_path.read_text())
        self.assertFalse(apply['PreviewOnly'])
        self.assertNotEqual(apply['RequestId'],preview['RequestId'])
        self.assertEqual(apply['PolicyHash'],preview['PolicyHash'])
        self.assertNotEqual(apply['BackupPath'],preview['BackupPath'])
        self.assertEqual(self.local.read_bytes(),settings)
        self.assertEqual((self.mission / 'storage_1/players.db').read_bytes(),b'precious-world')
        self.run_ps('Queue-LootRefresh.ps1','-Disable')
        self.assertFalse(request_path.exists())
        self.assertNotIn('#include',(self.mission / 'init.c').read_text())
        self.assertIn('return new CustomMission();',(self.mission / 'init.c').read_text())

    def test_loot_refresh_requires_preview_and_valid_zone(self):
        init = self.prepare_refresh()
        for args in [('-CenterX',8000,'-CenterZ',7000,'-Apply'),
                     ('-CenterX',0,'-CenterZ',7000),
                     ('-CenterX',8000,'-CenterZ',7000,'-Radius',499),
                     ('-CenterX',8000)]:
            self.run_ps('Queue-LootRefresh.ps1',*args,ok=False)
            self.assertEqual((self.mission / 'init.c').read_text(),init)
        (self.mission / 'init.c').write_text('// own mission factory')
        self.run_ps('Queue-LootRefresh.ps1','-CenterX',8000,'-CenterZ',7000,ok=False)
        self.assertFalse((self.package / '.local/loot-refresh-settings.json').exists())

    def make_update(self, *, missing_mod=False, second_change=False, changed_example=False):
        # Render a real embedded payload against this disposable installed base.
        spec = importlib.util.spec_from_file_location('build_update', ROOT / '.github/scripts/build_update.py')
        builder = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(builder)
        base = {str(p.relative_to(self.package)).replace('\\', '/'): p.read_bytes()
                for p in self.package.rglob('*') if p.is_file()
                and p != self.local and '.local' not in p.parts}
        target = dict(base)
        name = 'config/mission/servahz_ce/extra_types.xml'
        tree = ET.fromstring(target[name])
        tree.find("type[@name='Snafu_ScarH_Black_GUN']/nominal").text = '31'
        target[name] = ET.tostring(tree)
        if missing_mod:
            mods = json.loads(target['config/mods.json'])
            mods.append({'Name': 'Missing test mod', 'Id': '999999', 'Folder': '@Missing'})
            target['config/mods.json'] = json.dumps(mods).encode()
        target['README.md'] = b'Updated documentation'
        if second_change:
            name = 'scripts/Test-Server.ps1'
            target[name] += b'\n# Official fixture update\n'
        if changed_example:
            example = json.loads(target['config/server.example.json'])
            example['Hostname'] = 'Official future default'
            target['config/server.example.json'] = json.dumps(example).encode()
        self.update_target = target

        states = [builder.file_state('v0.13.0',base), builder.file_state('v0.14.0',target)]
        command, manifest = builder.render('v0.14.0', base, target, states)
        # Exercise the same PowerShell body as the cmd launcher, including ZIP
        # verification, backup, installer and static post-install checker.
        script = self.root / 'update.ps1'
        self.update_launcher, body = command.split('# SERVAHZ_POWERSHELL\n', 1)
        script.write_text(body, encoding='utf-8')
        return script, manifest

    def apply_update(self, script, *, ok=True):
        process_env = os.environ.copy()
        for key, directory in [('XDG_CACHE_HOME', 'cache'), ('XDG_CONFIG_HOME', 'xdg-config'), ('XDG_DATA_HOME', 'xdg-data')]:
            process_env[key] = str(self.root / directory)
        if os.name == 'nt':
            cmd = self.root / 'Servahz-Update.cmd'
            cmd.write_bytes((self.update_launcher + '# SERVAHZ_POWERSHELL\n' + script.read_text()).replace('\n', '\r\n').encode('utf-8'))
            args = ['cmd.exe', '/d', '/c', cmd.name, str(self.package)]
        else:
            args = [PWSH, '-NoProfile', '-File', str(script), '-PackagePath', str(self.package)]
        result = subprocess.run(args, cwd=self.root, input='', capture_output=True,
                                text=True, timeout=60, env=process_env)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def test_single_file_update_preserves_world_settings_and_repeat(self):
        self.install()
        self.run_ps('Install-Server.ps1', '-TestMode')
        settings = json.loads(self.local.read_text())
        settings.update(ServerPassword='keep-secret', TestFastRestock=False)
        self.local.write_text(json.dumps(settings))
        self.install()
        save = self.mission / 'storage_1/players.db'
        save.parent.mkdir(exist_ok=True)
        save.write_bytes(b'keep-player-world')
        script, manifest = self.make_update()
        self.assertEqual(set(manifest['files']), {'README.md', 'config/mission/servahz_ce/extra_types.xml'})
        self.apply_update(script)
        self.assertEqual(json.loads(self.local.read_text()), settings)
        self.assertEqual(save.read_bytes(), b'keep-player-world')
        self.assertEqual(ET.parse(self.mission / 'servahz_ce/extra_types.xml').findtext("type[@name='Snafu_ScarH_Black_GUN']/nominal"), '62')
        backups = list((self.package / '.local/Backups').glob('update-v0.14.0-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / 'world/mission/storage_1/players.db').read_bytes(), b'keep-player-world')
        self.assertEqual((backups[0] / 'package/config/mission/servahz_ce/extra_types.xml').read_bytes(),
                         (ROOT / 'config/mission/servahz_ce/extra_types.xml').read_bytes())
        self.apply_update(script)
        self.assertEqual(len(list((self.package / '.local/Backups').glob('update-v0.14.0-*'))), 1)
        # A newer installed version cannot be downgraded by an older cmd.
        (self.package / '.local/package-version.txt').write_text('v0.15.0')
        self.apply_update(script, ok=False)

    def test_update_rejects_custom_changes_missing_mod_and_corruption(self):
        self.install()
        script, _ = self.make_update(missing_mod=True)
        original = (self.package / 'config/mods.json').read_bytes()
        result = self.apply_update(script, ok=False)
        self.assertIn('Missing test mod', result.stderr)
        self.assertEqual((self.package / 'config/mods.json').read_bytes(), original)
        script, _ = self.make_update()
        source = self.package / 'scripts/Install-Server.ps1'
        original_script = source.read_bytes()
        source.write_bytes(original_script + b'\n# own edit\n')
        result = self.apply_update(script, ok=False)
        self.assertIn('Eigen pakketwijzigingen', result.stderr)
        self.assertIn('scripts/Install-Server.ps1',result.stdout)
        diagnostics = list((self.package / '.local/UpdateDiagnostics').glob('*.txt'))
        self.assertEqual(len(diagnostics),1)
        self.assertEqual(diagnostics[0].read_text().strip(),'Onbekende inhoud: scripts/Install-Server.ps1')
        source.write_bytes(original_script)
        body = script.read_text()
        body = body.replace("$payloadHash = '", "$payloadHash = '0", 1)
        script.write_text(body)
        result = self.apply_update(script, ok=False)
        self.assertIn('beschadigd', result.stderr)
        self.assertFalse((self.package / '.local/Backups').exists())

    def test_update_accepts_mixed_official_files_bom_crlf_and_old_docs(self):
        self.install()
        docs = self.package / 'README.md'
        docs.write_text('Original public documentation')
        script, _ = self.make_update(second_change=True)
        # A partial manual update: one critical file is already from the target,
        # another payload file is missing, and the rest is still from the base.
        (self.package / 'scripts/Test-Server.ps1').write_bytes(self.update_target['scripts/Test-Server.ps1'])
        (self.package / 'config/mission/servahz_ce/extra_types.xml').unlink()
        install = self.package / 'scripts/Install-Server.ps1'
        content = install.read_text(encoding='utf-8-sig').replace('\r\n','\n').rstrip('\n')
        install.write_bytes(b'\xef\xbb\xbf' + (content + '\n\n').replace('\n','\r\n').encode('utf-8'))
        docs.write_text('My retained local notes')
        settings = self.local.read_bytes()
        self.apply_update(script)
        self.assertEqual(self.local.read_bytes(),settings)
        self.assertTrue((self.package / 'config/mission/servahz_ce/extra_types.xml').exists())
        backups = list((self.package / '.local/Backups').glob('update-v0.14.0-*/package/README.md'))
        self.assertEqual(len(backups),1)
        self.assertEqual(backups[0].read_text(),'My retained local notes')
        self.assertEqual(docs.read_text(),'Updated documentation')

    def test_update_preserves_private_example_even_when_payload_changes_it(self):
        self.install()
        script, manifest = self.make_update(changed_example=True)
        self.assertIn('config/server.example.json',manifest['files'])
        example = self.package / 'config/server.example.json'
        private_example = b'{"ServerPassword":"private-template-secret","unknown":true}'
        example.write_bytes(private_example)
        active = self.local.read_bytes()
        result = self.apply_update(script)
        self.assertEqual(example.read_bytes(),private_example)
        self.assertEqual(self.local.read_bytes(),active)
        self.assertNotIn('private-template-secret',result.stdout+result.stderr)
        self.apply_update(script)
        self.assertEqual(len(list((self.package / '.local/Backups').glob('update-v0.14.0-*'))),1)

    def test_update_accepts_missing_unused_example_with_valid_local_settings(self):
        self.install()
        script, _ = self.make_update()
        example = self.package / 'config/server.example.json'
        example.unlink()
        active = self.local.read_bytes()
        self.apply_update(script)
        self.assertFalse(example.exists())
        self.assertEqual(self.local.read_bytes(),active)

    def test_update_reports_missing_required_base_file(self):
        self.install()
        script, _ = self.make_update()
        (self.package / 'config/mods.json').unlink()
        result = self.apply_update(script,ok=False)
        self.assertIn('Ontbreekt: config/mods.json',result.stdout)
        self.assertFalse((self.package / '.local/Backups').exists())

    def test_update_retries_after_installer_failure(self):
        self.install()
        script, _ = self.make_update()
        vanilla = self.baseline / 'db/types.xml'
        original = vanilla.read_bytes()
        vanilla.unlink()
        self.apply_update(script, ok=False)
        self.assertFalse((self.package / '.local/package-version.txt').exists())
        self.assertTrue(list((self.package / '.local/Backups').glob('update-v0.14.0-*/world')))
        vanilla.write_bytes(original)
        self.apply_update(script)
        self.assertEqual((self.package / '.local/package-version.txt').read_text(), 'v0.14.0')

    def test_update_requires_installed_base(self):
        script, _ = self.make_update()
        result = self.apply_update(script, ok=False)
        self.assertIn('Installeer eerst basispakket', result.stderr)


class ConfigTests(unittest.TestCase):
    def test_new_mods_loot_attachments_and_no_duplicate_types(self):
        mods = json.loads((ROOT / 'config/mods.json').read_text())
        self.assertEqual([m['Id'] for m in mods[9:12]], ['2670506982', '2663169692', '2792985069'])
        extra = ET.parse(ROOT / 'config/mission/servahz_ce/extra_types.xml')
        names = [n.get('name') for n in extra.findall('type')]
        self.assertEqual(len(names), 67)
        self.assertEqual(len(names), len(set(names)))
        building = ET.parse(ROOT / 'config/mission/servahz_ce/building_types.xml')
        self.assertFalse(set(names) & {n.get('name') for n in building.findall('type')})
        for name in ('BF_WindowBarricade', 'BF_WindowBarricadeMed', 'BF_DoorBarricade', 'BF_DoubleDoorBarricade'):
            node = building.find(f"type[@name='{name}']")
            self.assertEqual(node.findtext('nominal'), '0')
            self.assertEqual(node.findtext('lifetime'), '3888000')
            self.assertEqual(node.find('flags').get('crafted'), '1')
        self.assertFalse(any('RPG' in n or 'LAW' in n or 'M203' in n or 'Admin' in n or 'Hologram' in n for n in names))
        self.assertEqual(len([n for n in names if n.startswith('MMG_')]), 9)
        self.assertEqual(len([n for n in names if n.startswith('BF_')]), 4)
        spawn = ET.parse(ROOT / 'config/mission/servahz_ce/extra_spawnabletypes.xml')
        guns = {n.get('name') for n in spawn.findall('type')} | {'Expansion_DT11', 'Expansion_BenelliM4', 'Expansion_Kar98'}
        self.assertEqual(len(guns), 21)
        self.assertEqual(sum(int(n.findtext('nominal')) for n in extra.findall('type') if n.get('name') in guns), 630)
        self.assertTrue({'Snafu_ScarH_Black_GUN', 'GCGN_HK416', 'SNAFUHoneyBadger_Black', 'SNAFUM24_GUN'} <= guns)
        balance = json.loads((ROOT / 'config/loot-balance.json').read_text())
        sets = {entry['Weapon']: entry for entry in balance['WeaponSets']}
        self.assertEqual(set(sets), guns)
        for name in ['Snafu_ScarH_Black_GUN','SNAFU_SR25_Gun','GCGN_M110_Black']:
            self.assertEqual(sets[name]['Ammo'],'Ammo_308Win')
        self.assertEqual(sets['Expansion_Kedr']['Ammo'],'Ammo_380')
        self.assertEqual(extra.findtext("type[@name='GCGN_Ammo_762x51']/nominal"),'0')

        for node in spawn.findall('type'):
            self.assertIn(node.get('name'), names)
            self.assertEqual(node.find('attachments').get('chance'), '0.95')
            magazine = node.find('attachments/item').get('name')
            self.assertTrue(magazine in names or magazine in ('Mag_MP5_30Rnd', 'Mag_STANAG_30Rnd'))

    def test_rag_dependencies_materials_and_economy(self):
        mods = json.loads((ROOT / 'config/mods.json').read_text())
        self.assertEqual([(m['Name'], m['Id']) for m in mods[7:9]],
                         [('RaG_Core', '3556131153'), ('RaG_BaseBuilding', '3157695626')])
        config = json.loads((ROOT / 'config/profiles/RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json').read_text())
        self.assertEqual(config['Version'], 2)
        self.assertEqual(config['PlanksPerKitCraft'], 2)
        self.assertEqual(config['NailsPerKitCraft'], 1)
        self.assertEqual(len(config['PartCosts']), 37)
        for stage in config['PartCosts']:
            self.assertEqual(stage['NAILS'], 0)
            self.assertEqual(stage['LOGS'], 0)
            self.assertEqual(stage['PLANKS'], 0 if stage['Part'] == 'MetalDoor' else 2)
        self.assertEqual(config['DisableCraftVanillaFence'], 0)
        self.assertEqual(config['DisableAllDamage'], 0)
        loot = ET.parse(ROOT / 'config/mission/servahz_ce/building_types.xml')
        names = {n.get('name') for n in loot.findall('type') if n.get('name').startswith('RaG_')}
        self.assertEqual(len(names), 22)
        self.assertTrue(all(n.endswith('Kit') or n == 'RaG_BB_Book' for n in names))

    def test_navigation_manifest_preset_and_settings(self):
        mods = json.loads((ROOT / 'config/mods.json').read_text())
        self.assertEqual(mods[12], {'Name': 'GoreZ', 'Id': '1648967877', 'Folder': '@GoreZ'})
        self.assertEqual(mods[13], {'Name': 'BaseBuildingItemStackandRepair', 'Id': '1896597833', 'Folder': '@BaseBuildingItemStackandRepair'})
        self.assertFalse(any('bleedtrail' in m['Name'].lower() for m in mods))
        self.assertEqual(mods[14], {'Name': 'SNAFU Weapons', 'Id': '2443122116', 'Folder': '@SNAFUWeapons'})
        self.assertEqual(mods[15], {'Name': 'MMG - Half Mega Inventory Size', 'Id': '2895332994', 'Folder': '@MMGHalfMegaInventory'})
        self.assertEqual(mods[16], {'Name': 'CJ187-LootChest', 'Id': '2345073965', 'Folder': '@CJ187LootChest'})
        self.assertEqual(mods[17], {'Name': 'DayZ-Expansion-Spawn-Selection', 'Id': '2804241648', 'Folder': '@ExpansionSpawnSelection'})
        self.assertEqual(len(mods), 18)
        navigation = [m for m in mods if m['Id'] == '2792984722']
        self.assertEqual(len(navigation), 1)
        self.assertEqual(navigation[0]['Name'], 'DayZ-Expansion-Navigation')
        self.assertEqual(len({m['Id'] for m in mods}), len(mods))
        self.assertEqual(len({m['Folder'] for m in mods}), len(mods))
        from html.parser import HTMLParser
        class Links(HTMLParser):
            def __init__(self):
                super().__init__()
                self.links = []
            def handle_starttag(self, tag, attrs):
                attrs = dict(attrs)
                if tag == 'a' and attrs.get('data-type') == 'Link':
                    self.links.append(attrs['href'])
        preset = Links()
        preset.feed((ROOT / 'Mods.html').read_text())
        self.assertEqual(preset.links, [f"https://steamcommunity.com/sharedfiles/filedetails/?id={m['Id']}" for m in mods])
        settings = json.loads((ROOT / 'config/mission/expansion/settings/MapSettings.json').read_text())
        for name in ('EnableMap', 'CanOpenMapWithKeyBinding', 'EnableHUDGPS', 'ShowPlayerPosition'):
            self.assertEqual(settings[name], 1)
        for name in ('NeedGPSItemForKeyBinding', 'NeedMapItemForKeyBinding', 'NeedCompassItemForHUDCompass', 'NeedGPSItemForHUDCompass'):
            self.assertEqual(settings[name], 0)

    def test_patrol_budget_and_building_types(self):
        settings = ROOT / "config/mission/expansion/settings"
        ai = json.loads((settings / "AIPatrolSettings.json").read_text())
        self.assertEqual(ai['MinDistRadius'], 125)
        self.assertGreater(ai['ThreatDistanceLimit'], 250)
        self.assertGreater(ai['NoiseInvestigationDistanceLimit'], 150)
        patrols = ai["Patrols"]
        self.assertEqual(len(patrols), 17)
        self.assertEqual(sum(p['NumberOfAI'] for p in patrols), 43)
        self.assertEqual(len({p["Name"] for p in patrols}), len(patrols))
        caps = {name: rules[0]['MaxPatrols'] for name, rules in ai['LoadBalancingCategories'].items()}
        from itertools import combinations
        from collections import Counter
        max_active = 0
        max_hostile = 0
        for size in range(1, caps['Global'] + 1):
            for active in combinations(patrols, size):
                counts = Counter(p['LoadBalancingCategory'] for p in active)
                if any(count > caps[category] for category, count in counts.items()):
                    continue
                max_active = max(max_active, sum(p['NumberOfAI'] for p in active))
                max_hostile = max(max_hostile, sum(p['NumberOfAI'] for p in active if p['LoadBalancingCategory'] == 'Hostile'))
        self.assertEqual(max_active, 31)
        self.assertLessEqual(max_hostile, 18)
        self.assertEqual(Counter(p['LoadBalancingCategory'] for p in patrols),
                         {'Hostile': 10, 'Survivor': 5, 'Guards': 2})
        self.assertLessEqual(ai['DamageMultiplier'], 0.65)
        self.assertLessEqual(ai['AccuracyMax'], 0.35)
        loadouts = {'West': 'WestLoadout', 'East': 'EastLoadout', 'Civilian': 'SurvivorLoadout', 'Guards': 'PoliceLoadout'}
        for patrol in patrols:
            self.assertEqual(patrol['Speed'], 'JOG' if patrol['LoadBalancingCategory'] == 'Hostile' else 'WALK')
            self.assertEqual(patrol['Loadout'], loadouts[patrol['Faction']])
            self.assertEqual(patrol['NumberOfAIMax'], 0)
            self.assertEqual(patrol['MinDistRadius'], -1)
            self.assertEqual(patrol['MaxDistRadius'], -1)
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
