"""Full portable server copies and transactional restore with synthetic files."""
import json
import os
from pathlib import Path
import subprocess
import unittest

import test_package as package_tests


@unittest.skipUnless(package_tests.PWSH, 'PowerShell is required')
class PortableTests(unittest.TestCase):
    def setUp(self):
        self.case = package_tests.PackageTests()
        self.case.setUp()
        self.addCleanup(self.case.doCleanups)
        self.case.install()
        for name in ['01-Instellen.cmd', '10-Portable-kopie.cmd']:
            (self.case.package / name).write_bytes((package_tests.ROOT / name).read_bytes())
        self.world = self.case.mission / 'storage_1/players.db'
        self.world.parent.mkdir()
        self.world.write_bytes(b'PRIVATE-original-world-and-base')
        hidden = self.case.package / '.local/Backups/older-world/save.bin'
        hidden.parent.mkdir(parents=True)
        hidden.write_bytes(b'PRIVATE-previous-world')
        (self.case.server / 'empty folder').mkdir()
        self.ssd = self.case.root / 'portable ssd'
        self.roots = [self.case.server, self.case.package, self.case.workshop]

    def files(self, root):
        return {p.relative_to(root).as_posix(): p.read_bytes() for p in root.rglob('*') if p.is_file()}

    def directories(self, root):
        return {p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_dir()}

    def run_portable(self, mode='Backup', *, archive=None, inject='', ok=True):
        # The launcher body is executed without modifying any captured source tree.
        wrapper = self.case.root / 'portable-probe.ps1'
        script_path = str(package_tests.ROOT / '10-Portable-kopie.cmd').replace("'", "''")
        wrapper.write_text('''param([string]$SourceRoot, [string]$BackupRoot, [string]$Mode)
$ErrorActionPreference = 'Stop'
$lines = [IO.File]::ReadAllLines(''' + "'" + script_path + "'" + ''')
$i = [Array]::IndexOf($lines, '# SERVAHZ_PORTABLE_POWERSHELL')
$body = $lines[($i+1)..($lines.Length-1)] -join [Environment]::NewLine
''' + ("$body = $body.Replace('# SERVAHZ_PORTABLE_MAIN', @'\n" + inject + "\n'@ + [Environment]::NewLine + '# SERVAHZ_PORTABLE_MAIN')\n" if inject else '') + '''
& ([scriptblock]::Create($body)) -ScriptRoot $SourceRoot -BackupRoot $BackupRoot -Mode $Mode
''')
        env = os.environ.copy()
        for key in ['XDG_CACHE_HOME', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME']:
            env[key] = str(self.case.root / key)
        result = subprocess.run([package_tests.PWSH, '-NoLogo', '-NoProfile', '-File', str(wrapper),
                                 '-SourceRoot', str(archive or self.case.package), '-BackupRoot', str(self.ssd), '-Mode', mode],
                                capture_output=True, text=True, timeout=90, cwd=self.case.root, env=env)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        self.assertNotIn('PRIVATE-', result.stdout + result.stderr)
        return result

    def make_backup(self):
        self.run_portable()
        archives = list(self.ssd.glob('Kopie-*'))
        self.assertEqual(len(archives), 1)
        return archives[0]

    def test_portable_exact_copy_all_roots_hidden_files_long_paths_and_repeat(self):
        long_file = self.case.package / '.local' / ('nested-long-directory-' * 2)
        for _ in range(6):
            long_file /= 'another-long-nested-directory'
        long_file.mkdir(parents=True)
        (long_file / 'private-save.bin').write_bytes(b'PRIVATE-long-path-content')
        before = [self.files(r) for r in self.roots]
        dirs_before = [self.directories(r) for r in self.roots]
        archive = self.make_backup()
        info = json.loads((archive / 'Backup-info.json').read_text(encoding='utf-8-sig'))
        self.assertEqual(info['Schema'], 1)
        self.assertEqual(info['Status'], 'Complete')
        self.assertEqual([r['Role'] for r in info['Roots']], ['Server', 'Pakket', 'Workshop'])
        for root, role, files, dirs in zip(self.roots, ['Server', 'Pakket', 'Workshop'], before, dirs_before):
            self.assertEqual(self.files(root), files)
            self.assertEqual(self.files(archive / role), files)
            self.assertEqual(self.directories(archive / role), dirs)
        self.assertEqual((archive / 'Terugzetten.cmd').read_bytes(), (package_tests.ROOT / '10-Portable-kopie.cmd').read_bytes())
        self.run_portable()
        self.assertEqual(len(list(self.ssd.glob('Kopie-*'))), 2)
        self.assertEqual(self.files(archive / 'Pakket'), before[1])

    def test_portable_restore_preserves_previous_installation_and_removes_stale_live_files(self):
        archive = self.make_backup()
        backup_files = [self.files(archive / name) for name in ['Server', 'Pakket', 'Workshop']]
        # The SSD may have a different mount path/drive letter after transport.
        transport = self.case.root / 'SSD after transport'
        transport.mkdir()
        archive = archive.rename(transport / archive.name)
        self.world.write_bytes(b'PRIVATE-newer-world-kept-in-rollback')
        (self.case.server / 'stale-extra-mod.pbo').write_bytes(b'PRIVATE-stale-extra-file')
        config = json.loads(self.case.local.read_text())
        config['AdminPassword'] = 'PRIVATE-newer-admin-password'
        self.case.local.write_text(json.dumps(config))
        previous = [self.files(r) for r in self.roots]
        self.run_portable('Restore', archive=archive)
        for root, expected, old in zip(self.roots, backup_files, previous):
            self.assertEqual(self.files(root), expected)
            rollback = list(root.parent.glob(root.name + '.voor-terugzetten-*'))
            self.assertEqual(len(rollback), 1)
            self.assertEqual(self.files(rollback[0]), old)
        report = json.loads(next(archive.glob('Terugzetrapport-*.json')).read_text(encoding='utf-8-sig'))
        self.assertEqual(report['Status'], 'Complete')
        self.assertEqual(self.files(archive / 'Server'), backup_files[0])

    def test_portable_refuses_active_server_overlap_no_space_and_missing_world(self):
        before = [self.files(r) for r in self.roots]
        cases = [
            ("function Get-PortableServerProcesses { [pscustomobject]@{ Id=123 } }", '#shutdown'),
            ("function Get-PortableClientProcesses { [pscustomobject]@{ Id=456 } }", 'Steam volledig'),
            ("function Get-PortableFreeBytes { param($Path) return 0 }", 'Onvoldoende vrije ruimte'),
        ]
        for inject, message in cases:
            self.assertIn(message, self.run_portable(inject=inject, ok=False).stdout)
            self.assertFalse(self.ssd.exists())
            self.assertEqual([self.files(r) for r in self.roots], before)
        self.ssd = self.case.server / 'inside source'
        self.assertIn('buiten alle bronmappen', self.run_portable(ok=False).stdout)
        self.assertFalse(self.ssd.exists())
        self.ssd = self.case.root / 'portable ssd'
        self.world.unlink()
        self.assertIn('Geen bestaande wereldsave', self.run_portable(ok=False).stdout)
        self.assertFalse(self.ssd.exists())

    def test_portable_corruption_or_source_change_never_publishes_completed_backup(self):
        before = [self.files(r) for r in self.roots]
        corrupt = '''function Copy-PortableFile {
param($Source, $Destination)
[IO.File]::Copy((Get-PortableNativePath $Source), (Get-PortableNativePath $Destination), $false)
if ($Destination -like '*players.db') { [IO.File]::WriteAllText((Get-PortableNativePath $Destination), 'PRIVATE-corrupt-copy') }
}'''
        self.assertIn('SHA256-controle mislukt', self.run_portable(inject=corrupt, ok=False).stdout)
        self.assertFalse(list(self.ssd.glob('Kopie-*')))
        self.assertEqual([self.files(r) for r in self.roots], before)
        change = corrupt.replace('$Destination -like', '$Source -like').replace('Get-PortableNativePath $Destination), \'PRIVATE-corrupt-copy\'', 'Get-PortableNativePath $Source), \'PRIVATE-changed-source\'')
        self.assertIn('SHA256-controle mislukt', self.run_portable(inject=change, ok=False).stdout)
        self.assertFalse(list(self.ssd.glob('Kopie-*')))
        self.assertEqual(self.files(self.case.package), before[1])

    def test_portable_restore_refuses_corrupt_backup_and_foreign_target(self):
        archive = self.make_backup()
        before = [self.files(r) for r in self.roots]
        saved = archive / 'Server/mpmissions/servahz.chernarusplus/storage_1/players.db'
        original = saved.read_bytes()
        saved.write_bytes(b'PRIVATE-corrupt-transport')
        self.assertIn('SHA256-controle mislukt', self.run_portable('Restore', archive=archive, ok=False).stdout)
        self.assertEqual([self.files(r) for r in self.roots], before)
        saved.write_bytes(original)
        manifest_path = archive / 'Backup-info.json'
        manifest_before = manifest_path.read_bytes()
        manifest = json.loads(manifest_before.decode('utf-8-sig'))
        manifest['Roots'][0]['Snapshot']['Files'][0]['Relative'] = '../outside-backup'
        manifest_path.write_text(json.dumps(manifest))
        self.assertIn('ongeldig relatief bestandspad', self.run_portable('Restore', archive=archive, ok=False).stdout)
        self.assertEqual([self.files(r) for r in self.roots], before)
        manifest_path.write_bytes(manifest_before)
        marker = self.case.server / 'Servahz/.servahz-managed'
        marker.unlink()
        current = self.files(self.case.server)
        self.assertIn('niet herkenbaar bij Servahz', self.run_portable('Restore', archive=archive, ok=False).stdout)
        self.assertEqual(self.files(self.case.server), current)
        self.assertFalse(list(self.case.server.parent.glob(self.case.server.name + '.voor-terugzetten-*')))

    def test_portable_restore_rolls_back_completed_switches_after_later_move_failure(self):
        archive = self.make_backup()
        self.world.write_bytes(b'PRIVATE-newest-world-to-preserve')
        before = [self.files(r) for r in self.roots]
        inject = '''$script:moveFailed = $false
function Move-PortableDirectory {
param($Source, $Destination)
if (!$script:moveFailed -and $Source -like '*.terugzetten-bezig-*' -and $Destination -like '*221100') {
    $script:moveFailed = $true
    throw 'PRIVATE-copy-failure'
}
[IO.Directory]::Move((Get-PortableNativePath $Source), (Get-PortableNativePath $Destination))
}'''
        result = self.run_portable('Restore', archive=archive, inject=inject, ok=False)
        self.assertIn('teruggedraaid', result.stdout)
        self.assertEqual([self.files(r) for r in self.roots], before)

    def test_portable_rejects_junctions_or_symlinks(self):
        link = self.case.server / 'do not follow link'
        try:
            link.symlink_to(self.case.workshop, target_is_directory=True)
        except OSError:
            if os.name != 'nt':
                raise
            subprocess.run(['cmd.exe', '/d', '/c', 'mklink', '/J', str(link), str(self.case.workshop)], check=True, capture_output=True)
        self.addCleanup(lambda: link.unlink() if link.is_symlink() else os.rmdir(link) if link.exists() else None)
        self.assertIn('symlink/junction', self.run_portable(ok=False).stdout)
        self.assertFalse(self.ssd.exists())

    @unittest.skipUnless(os.name == 'nt', 'Native CMD requires Windows')
    def test_portable_native_cmd_backup_and_restore(self):
        command = self.case.package / '10-Portable-kopie.cmd'
        result = subprocess.run(['cmd.exe', '/d', '/c', command.name, str(self.ssd)], cwd=self.case.package,
                                input='', capture_output=True, text=True, timeout=90)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        archive = next(self.ssd.glob('Kopie-*'))
        self.world.write_bytes(b'PRIVATE-newer-native-world')
        result = subprocess.run(['cmd.exe', '/d', '/c', 'Terugzetten.cmd'], cwd=archive,
                                input='', capture_output=True, text=True, timeout=90)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.world.read_bytes(), b'PRIVATE-original-world-and-base')
