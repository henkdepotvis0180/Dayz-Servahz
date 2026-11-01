"""Selective CE targets, conservative chest migration and protected cleanup queue."""
import json
import unittest
import xml.etree.ElementTree as ET
import test_package as package_tests


@unittest.skipUnless(package_tests.PWSH, 'PowerShell is required')
class RareLootTests(unittest.TestCase):
    def setUp(self):
        self.case = package_tests.PackageTests()
        self.case.setUp()
        self.addCleanup(self.case.doCleanups)
        self.balance = json.loads((self.case.package / 'config/loot-balance.json').read_text())
        self.rare = set(self.balance['RareWeaponBoost']['Weapons'])

    def enable(self, missing=False):
        config = json.loads(self.case.local.read_text())
        if missing:
            config.pop('RareWeaponsOnly', None)
        else:
            config['RareWeaponsOnly'] = True
        self.case.local.write_text(json.dumps(config))

    def test_rare_ce_keeps_persistence_and_existing_world_and_matching_supplies(self):
        self.case.install()
        world = self.case.mission / 'storage_1/players.db'
        world.parent.mkdir()
        world.write_bytes(b'PRIVATE-base-guns-and-character')
        old = ET.parse(self.case.mission / 'servahz_ce/extra_types.xml')
        self.enable(missing=True)  # Existing installations opt in without resetting local settings.
        config = json.loads(self.case.local.read_text())
        for test_mode in [False, True]:
            if test_mode:
                cfg = json.loads(self.case.local.read_text())
                cfg['TestSuppliesEverywhere'] = True
                self.case.local.write_text(json.dumps(cfg))
                config = json.loads(self.case.local.read_text())
            self.case.install()
            extra = ET.parse(self.case.mission / 'servahz_ce/extra_types.xml')
            vanilla = ET.parse(self.case.mission / 'db/types.xml')
            for pair in self.balance['WeaponSets']:
                gun = extra.find(f"type[@name='{pair['Weapon']}']")
                if pair['Weapon'] in self.rare:
                    self.assertEqual(int(gun.findtext('nominal')), 240 if test_mode else 120)
                    for name, multiplier in [(pair['Ammo'], 4), (pair['Magazine'], 2)]:
                        supply = vanilla.find(f"type[@name='{name}']")
                        if supply is None:
                            supply = extra.find(f"type[@name='{name}']")
                        if supply is not None:
                            self.assertGreaterEqual(int(supply.findtext('nominal')), int(gun.findtext('nominal')) * multiplier)
                else:
                    self.assertEqual(gun.findtext('nominal'), '0')
                    self.assertEqual(gun.findtext('min'), '0')
                self.assertEqual(gun.findtext('lifetime'), old.findtext(f"type[@name='{pair['Weapon']}']/lifetime"))
                self.assertEqual(gun.find('flags').attrib, old.find(f"type[@name='{pair['Weapon']}']/flags").attrib)
            self.assertEqual(extra.findtext("type[@name='Mag_Expansion_M9_15Rnd']/nominal"), '0')
            result = self.case.run_ps('Test-Server.ps1', '-StaticOnly')
            self.assertIn('Wapenselectie 0.18.11', result.stdout)
            self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
            self.assertEqual(world.read_bytes(), b'PRIVATE-base-guns-and-character')
            self.assertEqual(json.loads(self.case.local.read_text()), config)

    def test_fresh_military_chests_only_use_selected_weapons(self):
        groups_path = self.case.baseline / 'mapgroupproto.xml'
        groups = ET.parse(groups_path)
        group = ET.SubElement(groups.getroot(), 'group', name='Land_Mil_Test', lootmax='4')
        ET.SubElement(group, 'usage', name='Military')
        floor = ET.SubElement(group, 'container', name='lootFloor', lootmax='4')
        ET.SubElement(floor, 'point', pos='0 0 0', range='2', height='2')
        groups.write(groups_path)
        positions = ET.parse(self.case.baseline / 'mapgrouppos.xml')
        for n in range(18):
            ET.SubElement(positions.getroot(), 'group', name='Land_Mil_Test',
                          pos=f'{1000+(n%6)*1800} 20 {5000+(n//6)*1800}', rpy='0 0 0', a='0')
        positions.write(self.case.baseline / 'mapgrouppos.xml')
        example = self.case.package / 'config/server.example.json'
        cfg = json.loads(example.read_text())
        cfg.pop('RareWeaponsOnly', None)
        example.write_text(json.dumps(cfg))
        self.case.install()
        profile = self.case.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        definitions = json.loads(profile.read_text())['LCPredefinedWeapons']
        self.assertGreaterEqual(len(definitions), 12)
        self.assertEqual({d['weapon'] for d in definitions}, self.rare)

    def test_chest_migration_preserves_positions_custom_loadouts_and_repeat(self):
        self.case.install()
        recipe = json.loads((self.case.package / 'config/loot-chests.json').read_text())
        pair = next(p for p in self.balance['WeaponSets'] if p['Weapon'] == 'Expansion_M9')
        profile = self.case.server / 'Servahz/Profiles/CJ_LootChests/LootChests_V106.json'
        cfg = json.loads(profile.read_text())
        cfg['LCPredefinedWeapons'] = []
        for n in range(2):
            definition = f'LC_predefined_Servahz_{n}'
            table = f'LC_Table_Weapons_Servahz_{n}'
            cfg['LCPredefinedWeapons'].append(dict(defname=definition, weapon=pair['Weapon'], magazine=pair['Magazine'], attachments=[], optic='CustomOptic' if n else '', opticbattery=0))
            cfg['LootCategories'].append(dict(name=table, Loot=[definition]))
            cfg['LootChestsLocations'].append(dict(name=f'Servahz_Weapons_{n}_1', chest=['CJ_LootChest_Olive_Large'], number=1,
                pos=[f'{2000+n*1000} 10 3000|0 0 0'], keyclass='', openable=2, CustomField=17,
                loot=[table, pair['Magazine'], pair['Ammo'], pair['Ammo']] + recipe['Loadouts']['Weapons']))
        profile.write_text(json.dumps(cfg))
        self.enable()
        self.case.install()
        current = json.loads(profile.read_text())
        defs = {d['defname']: d for d in current['LCPredefinedWeapons']}
        self.assertIn(defs['LC_predefined_Servahz_0']['weapon'], self.rare)
        self.assertEqual(defs['LC_predefined_Servahz_1'], cfg['LCPredefinedWeapons'][1])
        for before, after in zip(cfg['LootChestsLocations'], current['LootChestsLocations']):
            self.assertEqual({k:v for k,v in before.items() if k != 'loot'}, {k:v for k,v in after.items() if k != 'loot'})
        updated = profile.read_bytes()
        self.case.install()
        self.assertEqual(profile.read_bytes(), updated)
        backups = list((self.case.server / 'Servahz/Backups').glob('config-*/Profiles/CJ_LootChests/LootChests_V106.json'))
        self.assertTrue(any(json.loads(p.read_text()) == cfg for p in backups))

    def test_gorka_cleanup_requires_matching_preview_and_preserves_original_circle(self):
        self.case.prepare_refresh()
        self.enable()
        self.case.install()
        self.case.run_ps('Queue-LootRefresh.ps1', '-ObsoleteWeaponsOnly', '-ProtectTown', 'Gorka', '-CenterX', 8000, '-CenterZ', 7000)
        folder = self.case.server / 'Servahz/Profiles/Servahz'
        request = folder / 'LootRefresh-request.json'
        preview = json.loads(request.read_text())
        self.assertEqual((preview['CenterX'], preview['CenterZ'], preview['Radius']), (8000, 7000, 500))
        self.assertEqual(len(preview['ExtraProtectedAreas']), 1)
        self.assertEqual(preview['ExtraProtectedAreas'][0]['Name'], 'Gorka')
        self.assertEqual(preview['ExtraProtectedAreas'][0]['Radius'], 1500)
        self.assertTrue(self.rare.isdisjoint(preview['AllowedTypes']))
        self.assertIn('M4A1', preview['AllowedTypes'])
        self.assertIn('Expansion_M9', preview['AllowedTypes'])
        self.assertNotIn('Ammo_308Win', preview['AllowedTypes'])
        self.assertNotIn('NailBox', preview['AllowedTypes'])
        self.case.run_ps('Queue-LootRefresh.ps1', '-Apply', '-ObsoleteWeaponsOnly', ok=False)
        report = dict(preview, Status='PreviewCompleted', Cells=225, Candidates=10, Deleted=0, Protected=2, Message='fixture')
        (folder / 'LootRefresh-report.json').write_text(json.dumps(report))
        # The broad historical refresh cannot reuse this narrow preview.
        self.case.run_ps('Queue-LootRefresh.ps1', '-Apply', ok=False)
        extra = self.case.package / '.local/loot-refresh-extra-areas.json'
        saved = extra.read_bytes()
        areas = json.loads(saved)
        areas[0]['Radius'] = 1600
        extra.write_text(json.dumps(areas))
        self.case.run_ps('Queue-LootRefresh.ps1', '-Apply', '-ObsoleteWeaponsOnly', ok=False)
        self.assertEqual(json.loads(request.read_text()), preview)
        extra.write_bytes(saved)
        self.case.run_ps('Queue-LootRefresh.ps1', '-Apply', '-ObsoleteWeaponsOnly')
        apply = json.loads(request.read_text())
        self.assertFalse(apply['PreviewOnly'])
        self.assertEqual(apply['ExtraProtectedAreas'], preview['ExtraProtectedAreas'])
        self.assertEqual(apply['PolicyHash'], preview['PolicyHash'])
        self.assertEqual((self.case.mission / 'storage_1/players.db').read_bytes(), b'precious-world')

    def test_pending_old_refresh_refused_before_live_changes(self):
        self.case.prepare_refresh()
        self.case.run_ps('Queue-LootRefresh.ps1', '-CenterX', 8000, '-CenterZ', 7000)
        old = (self.case.mission / 'servahz_ce/extra_types.xml').read_bytes()
        self.enable()
        self.assertIn('oude lootverversing', self.case.install(ok=False).stderr)
        self.assertEqual((self.case.mission / 'servahz_ce/extra_types.xml').read_bytes(), old)
