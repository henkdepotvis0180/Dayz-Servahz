@echo off
setlocal
set "SERVAHZ_PORTABLE_FILE=%~f0"
set "SERVAHZ_PORTABLE_ROOT=%~dp0"
set "SERVAHZ_PORTABLE_TARGET=%~1"
set "SERVAHZ_PORTABLE_MODE=Backup"
if /i "%~n0"=="Terugzetten" set "SERVAHZ_PORTABLE_MODE=Restore"
cd /d "%TEMP%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$lines=[IO.File]::ReadAllLines($env:SERVAHZ_PORTABLE_FILE); $i=[Array]::IndexOf($lines,'# SERVAHZ_PORTABLE_POWERSHELL'); & ([scriptblock]::Create(($lines[($i+1)..($lines.Length-1)] -join [Environment]::NewLine))) -ScriptRoot $env:SERVAHZ_PORTABLE_ROOT -BackupRoot $env:SERVAHZ_PORTABLE_TARGET -Mode $env:SERVAHZ_PORTABLE_MODE -LauncherPath $env:SERVAHZ_PORTABLE_FILE"
set "SERVAHZ_PORTABLE_EXIT=%ERRORLEVEL%"
pause
exit /b %SERVAHZ_PORTABLE_EXIT%
# SERVAHZ_PORTABLE_POWERSHELL
param([string]$ScriptRoot, [string]$BackupRoot = 'G:\Dayzserver',
    [ValidateSet('Backup', 'Restore')][string]$Mode = 'Backup', [string]$LauncherPath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PortableFailure = 'Een bestand of schijf kon niet veilig worden gelezen of geschreven.'

function Stop-Portable {
    param([string]$Message)
    $script:PortableFailure = $Message
    throw 'Portable operation stopped'
}

function Get-PortableNativePath {
    param([string]$Path)
    if ($env:OS -eq 'Windows_NT') {
        # Extended Win32 paths do not normalize forward slashes for us.
        $native = $Path.Replace('/', '\')
        if (!$native.StartsWith('\\?\')) { return '\\?\' + $native }
        return $native
    }
    return $Path
}

function Get-PortablePath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^(\\\\|//)' -or ![IO.Path]::IsPathRooted($Path)) {
        Stop-Portable 'Er is een absoluut lokaal pad nodig; netwerkpaden en relatieve paden worden niet gebruikt.'
    }
    if ($env:OS -eq 'Windows_NT' -and $Path -notmatch '^[A-Za-z]:[\\/]') { Stop-Portable 'Gebruik een volledig lokaal schijfpad.' }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    if ($full.Length -le [IO.Path]::GetPathRoot($full).TrimEnd('\', '/').Length) { Stop-Portable 'Een volledige schijf mag geen bron- of terugzetmap zijn.' }
    return $full
}

function Test-PortableOverlap {
    param([string]$Left, [string]$Right)
    $separator = [IO.Path]::DirectorySeparatorChar
    return ([string]::Equals($Left, $Right, [StringComparison]::OrdinalIgnoreCase) -or
        $Left.StartsWith($Right + $separator, [StringComparison]::OrdinalIgnoreCase) -or
        $Right.StartsWith($Left + $separator, [StringComparison]::OrdinalIgnoreCase))
}

function Assert-PortableNoLinks {
    param([string]$Path)
    $current = $Path
    while ($current) {
        $native = Get-PortableNativePath $current
        if ([IO.Directory]::Exists($native) -or [IO.File]::Exists($native)) {
            if (([IO.File]::GetAttributes($native) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                Stop-Portable 'Een bron of doel bevat een symlink/junction. Er worden geen koppelingen gevolgd.'
            }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
}

function Get-PortableServerProcesses {
    return [Diagnostics.Process]::GetProcessesByName('DayZServer_x64')
}

function Get-PortableClientProcesses {
    foreach ($name in @('steam', 'DayZ_x64', 'DayZ_BE', 'DayZLauncher', 'DZSALauncher')) {
        [Diagnostics.Process]::GetProcessesByName($name)
    }
}

function Assert-PortableStopped {
    if (@(Get-PortableServerProcesses).Count -gt 0) {
        Stop-Portable 'Sluit de DayZ-server eerst normaal af met #shutdown en wacht tot het serverproces uit is.'
    }
    if (@(Get-PortableClientProcesses).Count -gt 0) {
        Stop-Portable 'Sluit ook DayZ, de launcher en Steam volledig, zodat Workshop-bestanden tijdens kopieren of terugzetten niet veranderen.'
    }
}

function Get-PortableHash {
    param([string]$Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = $null
    try {
        $stream = [IO.File]::Open((Get-PortableNativePath $Path), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '')
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        $algorithm.Dispose()
    }
}

function Get-PortableTree {
    param([string]$Root)
    Assert-PortableNoLinks $Root
    if (![IO.Directory]::Exists((Get-PortableNativePath $Root))) { Stop-Portable 'Een vereiste bronmap ontbreekt. Controleer de opgeslagen server- en Workshop-locaties.' }
    $directories = New-Object 'System.Collections.Generic.List[string]'
    $files = New-Object 'System.Collections.Generic.List[object]'
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push('')
    while ($pending.Count -gt 0) {
        $relative = $pending.Pop()
        $folder = $Root
        if ($relative) { $folder = [IO.Path]::Combine($Root, $relative) }
        foreach ($entry in [IO.Directory]::GetFileSystemEntries((Get-PortableNativePath $folder))) {
            $attributes = [IO.File]::GetAttributes($entry)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Stop-Portable 'Een bron of doel bevat een symlink/junction. Er worden geen koppelingen gevolgd.' }
            $name = [IO.Path]::GetFileName($entry)
            $child = $name
            if ($relative) { $child = [IO.Path]::Combine($relative, $name) }
            if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) {
                $directories.Add($child.Replace('\', '/'))
                $pending.Push($child)
            } else {
                $file = New-Object IO.FileInfo($entry)
                $files.Add([pscustomobject]@{ Relative = $child.Replace('\', '/'); Length = [long]$file.Length; SHA256 = Get-PortableHash ([IO.Path]::Combine($Root, $child)) })
                if (($files.Count % 100) -eq 0) { Write-Progress -Activity 'Portable kopie controleren' -Status ("SHA256: $($files.Count) bestanden") }
            }
        }
    }
    return [pscustomobject]@{ Directories = @($directories.ToArray() | Sort-Object); Files = @($files.ToArray() | Sort-Object Relative) }
}

function Assert-PortableRelative {
    param([string]$Relative)
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative) -or
        $Relative -match '[:\\]' -or @($Relative -split '/' | Where-Object { $_ -eq '..' -or $_ -eq '.' -or $_ -eq '' }).Count -gt 0) {
        Stop-Portable 'De kopie bevat een ongeldig relatief bestandspad. Er wordt niets teruggezet.'
    }
}

function Assert-PortableSnapshot {
    param($Snapshot)
    if ($null -eq $Snapshot -or $Snapshot.PSObject.Properties.Name -notcontains 'Directories' -or $Snapshot.PSObject.Properties.Name -notcontains 'Files') { Stop-Portable 'Het kopiemanifest is onvolledig.' }
    $names = @{}
    foreach ($directory in $Snapshot.Directories) {
        Assert-PortableRelative $directory
        if ($names.ContainsKey($directory)) { Stop-Portable 'Het kopiemanifest bevat dubbele mappen.' }
        $names[$directory] = $true
    }
    foreach ($file in $Snapshot.Files) {
        Assert-PortableRelative $file.Relative
        if ($names.ContainsKey($file.Relative) -or $file.SHA256 -notmatch '^[A-F0-9]{64}$' -or
            $file.Length -isnot [ValueType] -or [double]$file.Length -lt 0 -or [double]$file.Length -gt [long]::MaxValue) {
            Stop-Portable 'Het kopiemanifest bevat ongeldige of dubbele bestandsgegevens.'
        }
        $names[$file.Relative] = $true
    }
}

function Assert-PortableEqual {
    param($Expected, $Actual)
    Assert-PortableSnapshot $Expected
    Assert-PortableSnapshot $Actual
    if (@($Expected.Files).Count -ne @($Actual.Files).Count -or @($Expected.Directories).Count -ne @($Actual.Directories).Count) { Stop-Portable 'De bestands- of mappenlijst is gewijzigd. De kopie/bron is niet gelijk; er wordt niets omgeschakeld.' }
    $files = @{}
    foreach ($file in $Actual.Files) { $files[$file.Relative] = $file }
    foreach ($file in $Expected.Files) {
        if (!$files.ContainsKey($file.Relative) -or $files[$file.Relative].SHA256 -cne $file.SHA256 -or [long]$files[$file.Relative].Length -ne [long]$file.Length) {
            Stop-Portable 'SHA256-controle mislukt: een bestand verschilt of is gewijzigd. De bron en huidige installatie blijven bewaard.'
        }
    }
    $directories = @{}
    foreach ($directory in $Actual.Directories) { $directories[$directory] = $true }
    foreach ($directory in $Expected.Directories) {
        if (!$directories.ContainsKey($directory)) { Stop-Portable 'De mappenlijst is gewijzigd; de kopie is niet exact gelijk.' }
    }
}

function Copy-PortableFile {
    param([string]$Source, [string]$Destination)
    [IO.File]::Copy((Get-PortableNativePath $Source), (Get-PortableNativePath $Destination), $false)
}

function Move-PortableDirectory {
    param([string]$Source, [string]$Destination)
    [IO.Directory]::Move((Get-PortableNativePath $Source), (Get-PortableNativePath $Destination))
}

function Copy-PortableTree {
    param([string]$Source, [string]$Destination, $Snapshot)
    Assert-PortableSnapshot $Snapshot
    Assert-PortableNoLinks $Destination
    [IO.Directory]::CreateDirectory((Get-PortableNativePath $Destination)) | Out-Null
    foreach ($relative in $Snapshot.Directories) {
        [IO.Directory]::CreateDirectory((Get-PortableNativePath ([IO.Path]::Combine($Destination, $relative)))) | Out-Null
    }
    $index = 0
    foreach ($file in $Snapshot.Files) {
        Copy-PortableFile ([IO.Path]::Combine($Source, $file.Relative)) ([IO.Path]::Combine($Destination, $file.Relative))
        $index++
        Write-Progress -Activity 'Portable kopie maken' -Status ("$index / $(@($Snapshot.Files).Count) bestanden") -PercentComplete ([int](100 * $index / [Math]::Max(1, @($Snapshot.Files).Count)))
    }
}

function Get-PortableFreeBytes {
    param([string]$Path)
    $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($Path))
    if (!$drive.IsReady) { Stop-Portable 'Een benodigde schijf is niet aangesloten of niet gereed.' }
    return [long]$drive.AvailableFreeSpace
}

function Assert-PortableSpace {
    param($Plans)
    $needs = @{}
    foreach ($plan in $Plans) {
        $drive = [IO.Path]::GetPathRoot($plan.Target)
        if (!$needs.ContainsKey($drive)) { $needs[$drive] = [long]0 }
        foreach ($file in $plan.Snapshot.Files) { $needs[$drive] += [long]$file.Length }
    }
    foreach ($drive in $needs.Keys) {
        $reserve = [long][Math]::Max(128MB, [Math]::Ceiling($needs[$drive] * 0.02))
        if ((Get-PortableFreeBytes $drive) -lt ($needs[$drive] + $reserve)) {
            Stop-Portable 'Onvoldoende vrije ruimte voor een volledige kopie plus veiligheidsmarge. Er wordt geen bestaande kopie verwijderd.'
        }
    }
}

function Assert-PortableOwned {
    param([string]$Root, [string]$Role, [switch]$AllowMissing, [switch]$ArchiveLayout)
    Assert-PortableNoLinks $Root
    if ($Role -eq 'Workshop' -and !$ArchiveLayout -and [IO.Path]::GetFileName($Root) -ne '221100') { Stop-Portable 'De Workshop-bron moet de DayZ-map 221100 zijn.' }
    if (![IO.Directory]::Exists((Get-PortableNativePath $Root))) {
        if ([IO.File]::Exists((Get-PortableNativePath $Root)) -or !$AllowMissing) { Stop-Portable 'Een vereiste map ontbreekt of is een bestand.' }
        return
    }
    $required = @()
    switch ($Role) {
        'Server' { $required = @('DayZServer_x64.exe', 'Servahz/.servahz-managed', 'Servahz/serverDZ.cfg', 'mpmissions/servahz.chernarusplus/.servahz-managed') }
        'Pakket' { $required = @('01-Instellen.cmd', 'scripts/Servahz.psm1', 'config/server.local.json') }
        'Workshop' {
            return
        }
        default { Stop-Portable 'Onbekende bronsoort in het kopiemanifest.' }
    }
    foreach ($relative in $required) {
        if (![IO.File]::Exists((Get-PortableNativePath ([IO.Path]::Combine($Root, $relative))))) { Stop-Portable 'Een server- of pakketmap hoort niet herkenbaar bij Servahz. Bestaande mappen worden niet vervangen.' }
    }
}

function Assert-PortableWorld {
    param([string]$Server)
    $config = [IO.File]::ReadAllText((Get-PortableNativePath ([IO.Path]::Combine($Server, 'Servahz/serverDZ.cfg'))))
    $config = [regex]::Replace($config, '/\*[\s\S]*?\*/|(?m)//[^\r\n]*', '')
    $instance = [regex]::Matches($config, '(?mi)^\s*instanceId\s*=\s*([0-9]{1,8})\s*;')
    $mission = [regex]::Matches($config, '(?mi)^\s*template\s*=\s*"servahz\.chernarusplus"\s*;')
    if ($instance.Count -ne 1 -or $mission.Count -ne 1) { Stop-Portable 'De actieve missie of opslaginstantie is niet eenduidig. Gebruik eerst 08-Opslagdiagnose.cmd.' }
    $world = [IO.Path]::Combine($Server, 'mpmissions/servahz.chernarusplus/storage_' + $instance[0].Groups[1].Value)
    if (![IO.Directory]::Exists((Get-PortableNativePath $world)) -or [IO.Directory]::GetFileSystemEntries((Get-PortableNativePath $world)).Length -eq 0) {
        Stop-Portable 'Geen bestaande wereldsave gevonden bij deze server. Er wordt geen lege wereld als goede kopie behandeld; controleer eerst met 08.'
    }
}

function Write-PortableJson {
    param([string]$Path, $Value)
    [IO.File]::WriteAllText((Get-PortableNativePath $Path), ($Value | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
}

# SERVAHZ_PORTABLE_MAIN
$restorePlans = @()
$restoreCommitted = $false
try {
    Assert-PortableStopped
    $ScriptRoot = Get-PortablePath $ScriptRoot
    $id = [guid]::NewGuid().ToString('N')
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    if ($Mode -eq 'Backup') {
        if ([string]::IsNullOrWhiteSpace($BackupRoot)) { $BackupRoot = 'G:\Dayzserver' }
        $BackupRoot = Get-PortablePath $BackupRoot
        Assert-PortableNoLinks $BackupRoot
        Assert-PortableOwned $ScriptRoot 'Pakket'
        $script:PortableFailure = 'De lokale configuratie is niet leesbaar of geen geldige JSON; inhoud wordt niet afgedrukt.'
        $settings = [IO.File]::ReadAllText([IO.Path]::Combine($ScriptRoot, 'config/server.local.json')) | ConvertFrom-Json
        $server = Get-PortablePath $settings.ServerPath
        $workshop = Get-PortablePath $settings.WorkshopPath
        $roots = @([pscustomobject]@{ Role = 'Server'; Original = $server },
            [pscustomobject]@{ Role = 'Pakket'; Original = $ScriptRoot },
            [pscustomobject]@{ Role = 'Workshop'; Original = $workshop })
        foreach ($root in $roots) {
            if (Test-PortableOverlap $root.Original $BackupRoot) { Stop-Portable 'De kopiemap moet buiten alle bronmappen staan.' }
            Assert-PortableOwned $root.Original $root.Role
        }
        Assert-PortableWorld $server
        for ($i = 0; $i -lt $roots.Count; $i++) {
            for ($j = $i + 1; $j -lt $roots.Count; $j++) {
                if (Test-PortableOverlap $roots[$i].Original $roots[$j].Original) { Stop-Portable 'De bronmappen overlappen. Deze zelfstandige kopie kan ze niet veilig afzonderlijk terugzetten.' }
            }
        }
        $script:PortableFailure = 'Een bronbestand kon niet worden gelezen. Sluit andere instel-/updatescripts en probeer opnieuw met gestopte server.'
        foreach ($root in $roots) {
            Write-Host ("Inventaris en SHA256: " + $root.Role)
            $root | Add-Member -NotePropertyName Snapshot -NotePropertyValue (Get-PortableTree $root.Original)
        }
        Assert-PortableSpace @($roots | ForEach-Object { [pscustomobject]@{ Target = $BackupRoot; Snapshot = $_.Snapshot } })
        Assert-PortableStopped
        $stage = [IO.Path]::Combine($BackupRoot, '.kopie-bezig-' + $id)
        $archive = [IO.Path]::Combine($BackupRoot, 'Kopie-' + $stamp + '-' + $id.Substring(0, 8))
        $script:PortableFailure = 'Kopieren is niet voltooid. Bronbestanden en oudere kopieen blijven staan; een map .kopie-bezig kan achterblijven.'
        [IO.Directory]::CreateDirectory((Get-PortableNativePath $stage)) | Out-Null
        foreach ($root in $roots) {
            Write-Host ("Kopieren en controleren: " + $root.Role)
            $target = [IO.Path]::Combine($stage, $root.Role)
            Copy-PortableTree $root.Original $target $root.Snapshot
            Assert-PortableEqual $root.Snapshot (Get-PortableTree $target)
        }
        Assert-PortableStopped
        foreach ($root in $roots) { Assert-PortableEqual $root.Snapshot (Get-PortableTree $root.Original) }
        if (!$LauncherPath) { $LauncherPath = [IO.Path]::Combine($ScriptRoot, '10-Portable-kopie.cmd') }
        Copy-PortableFile $LauncherPath ([IO.Path]::Combine($stage, 'Terugzetten.cmd'))
        $manifest = [pscustomobject]@{ Schema = 1; Status = 'Complete'; BackupId = $id; CreatedUtc = [DateTime]::UtcNow.ToString('o'); Roots = $roots }
        Write-PortableJson ([IO.Path]::Combine($stage, 'Backup-info.json')) $manifest
        Assert-PortableStopped
        Move-PortableDirectory $stage $archive
        Write-Progress -Activity 'Portable kopie maken' -Completed
        Write-Progress -Activity 'Portable kopie controleren' -Completed
        Write-Host "KLAAR: volledige gecontroleerde kopie in $archive"
        Write-Host 'Server, pakket inclusief .local en alle DayZ-Workshop-downloads zijn gekopieerd. Actieve paden zijn niet veranderd.'
        Write-Host 'Neem deze hele Kopie-map mee. Gebruik later Terugzetten.cmd in die map met de server gestopt.'
        Write-Host 'De kopie bevat wachtwoorden en privegegevens; houd de SSD/kopie prive.'
    } else {
        $script:PortableFailure = 'Het kopiemanifest is niet leesbaar of ongeldig; er wordt niets teruggezet.'
        Assert-PortableNoLinks $ScriptRoot
        $manifest = [IO.File]::ReadAllText((Get-PortableNativePath ([IO.Path]::Combine($ScriptRoot, 'Backup-info.json')))) | ConvertFrom-Json
        if ($manifest.Schema -ne 1 -or $manifest.Status -ne 'Complete' -or $manifest.BackupId -notmatch '^[a-f0-9]{32}$' -or @($manifest.Roots).Count -ne 3) { Stop-Portable 'Dit is geen voltooide ondersteunde portable kopie.' }
        $seen = @{}
        foreach ($root in $manifest.Roots) {
            if ($root.Role -notin @('Server', 'Pakket', 'Workshop') -or $seen.ContainsKey($root.Role)) { Stop-Portable 'De kopie heeft ongeldige of dubbele bronsoorten.' }
            $seen[$root.Role] = $true
            $target = Get-PortablePath $root.Original
            if (Test-PortableOverlap $ScriptRoot $target) { Stop-Portable 'Terugzetten mag de portable kopie zelf niet vervangen.' }
            Assert-PortableSnapshot $root.Snapshot
            $source = [IO.Path]::Combine($ScriptRoot, $root.Role)
            Assert-PortableOwned $source $root.Role -ArchiveLayout
            Assert-PortableEqual $root.Snapshot (Get-PortableTree $source)
            Assert-PortableOwned $target $root.Role -AllowMissing
            $restorePlans += [pscustomobject]@{ Role = $root.Role; Source = $source; Target = $target; Snapshot = $root.Snapshot;
                Stage = $target + '.terugzetten-bezig-' + $id; Previous = $target + '.voor-terugzetten-' + $stamp + '-' + $id.Substring(0, 8);
                PreviousMoved = $false; Installed = $false }
        }
        for ($i = 0; $i -lt $restorePlans.Count; $i++) {
            for ($j = $i + 1; $j -lt $restorePlans.Count; $j++) {
                if (Test-PortableOverlap $restorePlans[$i].Target $restorePlans[$j].Target) { Stop-Portable 'De terugzetmappen overlappen. Er wordt niets vervangen.' }
            }
        }
        $packet = @($restorePlans | Where-Object { $_.Role -eq 'Pakket' })[0]
        $settings = [IO.File]::ReadAllText((Get-PortableNativePath ([IO.Path]::Combine($packet.Source, 'config/server.local.json')))) | ConvertFrom-Json
        $serverPlan = @($restorePlans | Where-Object { $_.Role -eq 'Server' })[0]
        $workshopPlan = @($restorePlans | Where-Object { $_.Role -eq 'Workshop' })[0]
        if ((Get-PortablePath $settings.ServerPath) -ine $serverPlan.Target -or (Get-PortablePath $settings.WorkshopPath) -ine $workshopPlan.Target) { Stop-Portable 'De oorspronkelijke paden in de kopie spreken elkaar tegen; er wordt niets vervangen.' }
        Assert-PortableWorld $serverPlan.Source
        Assert-PortableSpace $restorePlans
        $script:PortableFailure = 'Voorbereiden van terugzetten is niet voltooid. De huidige installatie is nog niet omgeschakeld.'
        foreach ($plan in $restorePlans) {
            Assert-PortableStopped
            Write-Host ("Terugzetkopie voorbereiden en controleren: " + $plan.Role)
            Copy-PortableTree $plan.Source $plan.Stage $plan.Snapshot
            Assert-PortableEqual $plan.Snapshot (Get-PortableTree $plan.Stage)
        }
        foreach ($plan in $restorePlans) { Assert-PortableEqual $plan.Snapshot (Get-PortableTree $plan.Source) }
        Assert-PortableStopped
        $script:PortableFailure = 'Terugzetten is onderbroken. Huidige bestanden en portable kopie blijven bewaard; controleer het terugzetrapport.'
        foreach ($plan in $restorePlans) {
            Assert-PortableStopped
            Assert-PortableOwned $plan.Target $plan.Role -AllowMissing
            if ([IO.Directory]::Exists((Get-PortableNativePath $plan.Target))) {
                Move-PortableDirectory $plan.Target $plan.Previous
                $plan.PreviousMoved = $true
            }
            Move-PortableDirectory $plan.Stage $plan.Target
            $plan.Installed = $true
        }
        $restoreCommitted = $true
        try {
            Write-PortableJson ([IO.Path]::Combine($ScriptRoot, 'Terugzetrapport-' + $id + '.json')) ([pscustomobject]@{ Status = 'Complete'; Roots = @($restorePlans | Select-Object Role, Target, Previous, PreviousMoved) })
        } catch { Write-Host 'Terugzetten is voltooid; een apart terugzetrapport kon niet op de SSD worden geschreven.' }
        Write-Progress -Activity 'Portable kopie maken' -Completed
        Write-Progress -Activity 'Portable kopie controleren' -Completed
        Write-Host 'KLAAR: server, pakket en Workshop zijn naar de oorspronkelijke paden teruggezet. Configuratie en wachtwoorden zijn exact uit de kopie overgenomen.'
        Write-Host 'De vorige installatie staat per map ernaast met .voor-terugzetten-...; verwijder die pas na controle in-game.'
        Write-Host 'Start met 02 in de oorspronkelijke pakketmap en controleer met 03/08. Steam/Windows en Steam-bibliotheekregistratie zijn niet teruggezet.'
    }
} catch {
    # No file contents, arbitrary exceptions, save filenames, passwords or log lines.
    if (!$restoreCommitted -and @($restorePlans | Where-Object { $_.PreviousMoved -or $_.Installed }).Count -gt 0) {
        try {
            Assert-PortableStopped
            for ($i = $restorePlans.Count - 1; $i -ge 0; $i--) {
                $plan = $restorePlans[$i]
                if ($plan.Installed) { Move-PortableDirectory $plan.Target ($plan.Target + '.onvolledig-teruggezet-' + $id) }
                if ($plan.PreviousMoved) { Move-PortableDirectory $plan.Previous $plan.Target }
            }
            Write-Host 'De reeds omgeschakelde mappen zijn teruggedraaid naar de installatie van voor deze poging.'
        } catch { Write-Host 'Automatisch terugdraaien is niet voltooid. Bewaar alle .voor-terugzetten-/terugzetten-bezig-mappen; start de server nog niet.' }
    }
    if ($Mode -eq 'Restore' -and $restorePlans.Count -gt 0) {
        try {
            Write-PortableJson ([IO.Path]::Combine($ScriptRoot, 'Terugzetrapport-' + $id + '.json')) ([pscustomobject]@{
                Status = 'Incomplete'; Roots = @($restorePlans | Select-Object Role, Target, Previous, Stage, PreviousMoved, Installed)
            })
        } catch { }
    }
    Write-Progress -Activity 'Portable kopie maken' -Completed
    Write-Progress -Activity 'Portable kopie controleren' -Completed
    Write-Host ('NIET VOLTOOID: ' + $script:PortableFailure)
    Write-Host 'De portable kopie/bron wordt niet verwijderd. Voer bij een fout geen lootverversing of nieuwe lege installatie uit.'
    exit 1
}
