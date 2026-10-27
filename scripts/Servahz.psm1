Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PackageRoot = Split-Path $PSScriptRoot -Parent
$script:MissionName = 'servahz.chernarusplus'

function Write-Utf8File {
    param([string]$Path, [string]$Text)
    $parent = Split-Path $Path -Parent
    if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

function Read-ServerSettings {
    param([string]$Path = (Join-Path $script:PackageRoot 'config/server.local.json'))
    if (!(Test-Path -LiteralPath $Path)) { throw 'Voer eerst 01-Instellen.cmd uit.' }
    $s = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($s.PSObject.Properties.Name -notcontains 'MilitaryLootMultiplier') {
        $s | Add-Member -MemberType NoteProperty -Name MilitaryLootMultiplier -Value 2
    }
    if ($s.PSObject.Properties.Name -notcontains 'LootDamageMax') {
        $s | Add-Member -MemberType NoteProperty -Name LootDamageMax -Value 0.15
    }
    if ($s.PSObject.Properties.Name -notcontains 'TestSuppliesEverywhere') {
        $s | Add-Member -MemberType NoteProperty -Name TestSuppliesEverywhere -Value $false
    }
    if ($s.PSObject.Properties.Name -notcontains 'TestMilitaryEverywhere') {
        $s | Add-Member -MemberType NoteProperty -Name TestMilitaryEverywhere -Value $false
    }
    if ($s.TestSuppliesEverywhere -isnot [bool]) { throw 'TestSuppliesEverywhere moet true of false zijn, zonder quotes.' }
    if ($s.TestMilitaryEverywhere -isnot [bool]) { throw 'TestMilitaryEverywhere moet true of false zijn, zonder quotes.' }
    foreach ($name in @('GamePort', 'QueryPort')) {
        $port = $s.$name
        if ($port -isnot [int] -and $port -isnot [long]) { throw "$name moet een geheel getal zijn." }
        if ($port -lt 1024 -or $port -gt 65530) { throw "$name moet tussen 1024 en 65530 liggen." }
    }
    if ($s.QueryPort -ge $s.GamePort -and $s.QueryPort -le ($s.GamePort + 3)) {
        throw 'QueryPort moet buiten GamePort t/m GamePort+3 liggen.'
    }
    foreach ($name in @('MaxPlayers', 'LootMultiplier', 'MilitaryLootMultiplier', 'LootDamageMax', 'DayAcceleration', 'NightAcceleration')) {
        $number = $s.$name
        if ($number -isnot [int] -and $number -isnot [long] -and $number -isnot [double] -and $number -isnot [decimal]) {
            throw "$name moet een getal zijn."
        }
        if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) { throw "$name moet een eindig getal zijn." }
    }
    if ($s.MaxPlayers -lt 1 -or $s.MaxPlayers -gt 60 -or $s.MaxPlayers % 1 -ne 0) { throw 'MaxPlayers moet een geheel getal tussen 1 en 60 zijn.' }
    if ($s.LootMultiplier -lt 1 -or $s.LootMultiplier -gt 10) { throw 'LootMultiplier moet tussen 1 en 10 liggen.' }
    if ($s.MilitaryLootMultiplier -lt 1 -or $s.MilitaryLootMultiplier -gt 5) { throw 'MilitaryLootMultiplier moet tussen 1 en 5 liggen.' }
    if ($s.LootDamageMax -lt 0 -or $s.LootDamageMax -gt 1) { throw 'LootDamageMax moet tussen 0 en 1 liggen.' }
    if ($s.DayAcceleration -lt 1 -or $s.DayAcceleration -gt 24 -or $s.NightAcceleration -lt 1 -or $s.NightAcceleration -gt 64) {
        throw 'DayAcceleration moet 1-24 en NightAcceleration moet 1-64 zijn.'
    }
    foreach ($field in @('Hostname', 'ServerPassword', 'AdminPassword')) {
        # Prevent configuration/command injection; passwords stay in local files.
        if ($s.$field -match '["\r\n\\]') { throw "$field mag geen dubbele quotes, backslashes of regeleinden bevatten." }
    }
    if ([string]::IsNullOrWhiteSpace($s.AdminPassword)) { throw 'AdminPassword ontbreekt. Voer 01-Instellen.cmd opnieuw uit.' }
    return $s
}

function Get-ModManifest {
    # Windows PowerShell 5.1 emits a JSON array as one pipeline object.
    # Wrapping that pipeline in @() leaves a nested array: .Folder then
    # expands all names into one space-separated string instead of mod paths.
    $mods = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/mods.json') -Raw | ConvertFrom-Json
    foreach ($mod in $mods) {
        Write-Output $mod
    }
}

function Get-ServerLayout {
    param($Settings)
    $server = [IO.Path]::GetFullPath($Settings.ServerPath)
    $runtime = Join-Path $server 'Servahz'
    return [pscustomobject]@{
        Server = $server
        Runtime = $runtime
        Mission = Join-Path $server ('mpmissions/' + $script:MissionName)
        Profiles = Join-Path $runtime 'Profiles'
        Config = Join-Path $runtime 'serverDZ.cfg'
        Marker = Join-Path $runtime '.servahz-managed'
    }
}

function Assert-ServerStopped {
    # Conservative: never change missions or mods while a DayZ server is running.
    if (@(Get-Process -Name DayZServer_x64 -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Sluit de DayZ-server eerst normaal af: in-game #login met AdminPassword en daarna #shutdown.'
    }
}

function Get-SteamLibraries {
    param([string[]]$SteamRoots)
    $roots = @()
    if ($PSBoundParameters.ContainsKey('SteamRoots')) {
        $roots = @($SteamRoots)
    } else {
    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        if (Test-Path $key -ErrorAction SilentlyContinue) {
            $props = Get-ItemProperty $key
            foreach ($name in @('SteamPath', 'InstallPath')) {
                if ($props.PSObject.Properties.Name -contains $name) { $roots += $props.$name }
            }
        }
    }
    if (${env:ProgramFiles(x86)}) { $roots += Join-Path ${env:ProgramFiles(x86)} 'Steam' }
    }
    $libraries = @()
    foreach ($root in $roots) {
        # Steam can retain disconnected drives. Join-Path validates PS drives
        # and throws before Test-Path can reject them; check roots first.
        if ([string]::IsNullOrWhiteSpace($root) -or !(Test-Path -LiteralPath $root -PathType Container -ErrorAction SilentlyContinue)) { continue }
        $libraries += $root
        $vdf = [IO.Path]::Combine($root, 'steamapps/libraryfolders.vdf')
        if (Test-Path -LiteralPath $vdf) {
            foreach ($line in (Get-Content -LiteralPath $vdf)) {
                if ($line -match '"path"\s+"([^"]+)"') { $libraries += $Matches[1].Replace('\\', '\') }
            }
        }
    }
    return @($libraries | Where-Object {
        ![string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_ -PathType Container -ErrorAction SilentlyContinue)
    } | Select-Object -Unique)
}

function Save-ManagedBackup {
    param($Layout)
    $dest = Join-Path $Layout.Runtime ('Backups/config-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    foreach ($relative in @('db/types.xml', 'db/globals.xml', 'cfgeconomycore.xml', 'cfggameplay.json',
            'expansion/settings/AIPatrolSettings.json', 'expansion/settings/BaseBuildingSettings.json',
            'expansion/settings/MapSettings.json',
            'servahz_ce/building_types.xml')) {
        $source = Join-Path $Layout.Mission $relative
        if (Test-Path -LiteralPath $source) {
            $target = Join-Path $dest ('mission/' + $relative)
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
        }
    }
    if (Test-Path -LiteralPath $Layout.Config) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item -LiteralPath $Layout.Config -Destination (Join-Path $dest 'serverDZ.cfg')
    }
}

function Set-LootCondition {
    param([string]$Path, [double]$MaximumDamage)
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    $min = $xml.SelectSingleNode('/variables/var[@name="LootDamageMin"]')
    $max = $xml.SelectSingleNode('/variables/var[@name="LootDamageMax"]')
    if ($null -eq $min -or $null -eq $max) { throw 'LootDamageMin/Max ontbreekt in db/globals.xml. Controleer de standaardmissie.' }
    $min.SetAttribute('value', '0.0')
    $max.SetAttribute('value', $MaximumDamage.ToString([Globalization.CultureInfo]::InvariantCulture))
    Save-Xml $xml $Path
}

function Set-LootMultiplier {
    param([string]$Source, [string]$Destination, [double]$Multiplier, [double]$MilitaryMultiplier = 2, [switch]$MilitaryEverywhere)
    # Always read the installed vanilla baseline, never the previous generated 5x file.
    [xml]$xml = Get-Content -LiteralPath $Source -Raw
    $count = 0
    foreach ($type in $xml.SelectNodes('/types/type')) {
        $nominal = $type.SelectSingleNode('nominal')
        if ($null -eq $nominal -or [int]$nominal.InnerText -le 0) { continue }
        $factor = $Multiplier
        if ($null -ne $type.SelectSingleNode('usage[@name="Military"]')) {
            $factor *= $MilitaryMultiplier
            $flags = $type.SelectSingleNode('flags')
            # Keep event-only and crafted loot rules intact, even in test mode.
            $eventOnly = $null -ne $flags -and $flags.GetAttribute('deloot') -eq '1'
            $crafted = $null -ne $flags -and $flags.GetAttribute('crafted') -eq '1'
            if ($MilitaryEverywhere -and !$eventOnly -and !$crafted) {
                foreach ($usage in @('Town', 'Village', 'Industrial', 'Farm', 'Police', 'Hunting')) {
                    if ($null -eq $type.SelectSingleNode('usage[@name="' + $usage + '"]')) {
                        $node = $xml.CreateElement('usage')
                        $node.SetAttribute('name', $usage)
                        $type.AppendChild($node) | Out-Null
                    }
                }
                foreach ($tier in @('Tier1', 'Tier2', 'Tier3', 'Tier4')) {
                    if ($null -eq $type.SelectSingleNode('value[@name="' + $tier + '"]')) {
                        $node = $xml.CreateElement('value')
                        $node.SetAttribute('name', $tier)
                        $type.AppendChild($node) | Out-Null
                    }
                }
            }
        }
        $nominal.InnerText = [string][int][Math]::Ceiling([int]$nominal.InnerText * $factor)
        $min = $type.SelectSingleNode('min')
        if ($null -ne $min -and [int]$min.InnerText -gt 0) {
            $min.InnerText = [string][int][Math]::Ceiling([int]$min.InnerText * $factor)
        }
        $count++
    }
    Save-Xml $xml $Destination
    return $count
}

function Set-TestSupplies {
    param([string]$Path)
    # Called only on freshly generated vanilla/Expansion types, never on last run's output.
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    $usages = @('Coast', 'ContaminatedArea', 'Farm', 'Firefighter', 'Historical',
        'Hunting', 'Industrial', 'Lunapark', 'Medic', 'Military', 'Office', 'Police',
        'Prison', 'School', 'SeasonalEvent', 'Town', 'Village')
    $building = @('NailBox', 'MetalPlate', 'MetalWire', 'BarbedWire', 'Rope',
        'DuctTape', 'Hammer', 'Hatchet', 'HandSaw', 'Hacksaw', 'Shovel', 'Pickaxe',
        'WoodAxe', 'SledgeHammer', 'Pliers', 'CombinationLock', 'CombinationLock4')
    # Deliberate test-only exceptions: raw materials, never placed structures or kits.
    $materials = @('WoodenPlank', 'ExpansionLumber1', 'ExpansionLumber1_5', 'ExpansionLumber3')
    foreach ($type in $xml.SelectNodes('/types/type')) {
        $name = $type.GetAttribute('name')
        $nominal = $type.SelectSingleNode('nominal')
        $flags = $type.SelectSingleNode('flags')
        if ($null -eq $nominal -or $null -eq $flags -or $flags.GetAttribute('deloot') -eq '1') { continue }
        if ($name -in $materials) {
            $nominal.InnerText = '160'
            $type.SelectSingleNode('min').InnerText = '80'
            $flags.SetAttribute('crafted', '0')
            $category = $xml.CreateElement('category')
            $category.SetAttribute('name', 'tools')
            if ($null -eq $type.SelectSingleNode('category')) { $type.AppendChild($category) | Out-Null }
            $tag = $xml.CreateElement('tag')
            $tag.SetAttribute('name', 'floor')
            if ($null -eq $type.SelectSingleNode('tag')) { $type.AppendChild($tag) | Out-Null }
        } else {
            if ([int]$nominal.InnerText -le 0 -or $flags.GetAttribute('crafted') -eq '1') { continue }
            $weapon = $null -ne $type.SelectSingleNode('category[@name="weapons"]')
            $ammo = $name -match '^(Ammo_|AmmoBox_|Mag_)'
            $expansion = $name -match '^Expansion(CodeLock|SafeMini|SafeMedium|SafeLarge|WallKit|FloorKit|RampKit|StairKit|WoodPillarKit)$'
            if (!$weapon -and !$ammo -and !$expansion -and $name -notin $building) { continue }
            $nominal.InnerText = [string]([int]$nominal.InnerText * 2)
            $min = $type.SelectSingleNode('min')
            if ($null -ne $min) { $min.InnerText = [string]([int]$min.InnerText * 2) }
        }
        foreach ($pair in @(@('usage', $usages), @('value', @('Tier1', 'Tier2', 'Tier3', 'Tier4')))) {
            foreach ($value in $pair[1]) {
                if ($null -eq $type.SelectSingleNode($pair[0] + '[@name="' + $value + '"]')) {
                    $node = $xml.CreateElement($pair[0])
                    $node.SetAttribute('name', $value)
                    $type.AppendChild($node) | Out-Null
                }
            }
        }
    }
    Save-Xml $xml $Path
}

function Save-Xml {
    param([xml]$Xml, [string]$Path)
    $settings = New-Object Xml.XmlWriterSettings
    $settings.Indent = $true
    $settings.Encoding = New-Object Text.UTF8Encoding($false)
    $writer = [Xml.XmlWriter]::Create($Path, $settings)
    try { $Xml.Save($writer) } finally { $writer.Dispose() }
}

function Set-EconomyInclude {
    param([string]$Path)
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    foreach ($old in @($xml.SelectNodes('/economycore/ce[@folder="servahz_ce"]'))) {
        $xml.DocumentElement.RemoveChild($old) | Out-Null
    }
    $ce = $xml.CreateElement('ce')
    $ce.SetAttribute('folder', 'servahz_ce')
    $file = $xml.CreateElement('file')
    $file.SetAttribute('name', 'building_types.xml')
    $file.SetAttribute('type', 'types')
    $ce.AppendChild($file) | Out-Null
    $xml.DocumentElement.AppendChild($ce) | Out-Null
    Save-Xml $xml $Path
}

function Set-EasyBuilding {
    param([string]$Path)
    $gameplay = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    foreach ($name in @('disableIsCollidingBBoxCheck', 'disableIsClippingRoofCheck',
            'disableIsBaseViableCheck', 'disableIsCollidingGPlotCheck', 'disableIsCollidingAngleCheck',
            'disableIsPlacementPermittedCheck', 'disableHeightPlacementCheck')) {
        $gameplay.BaseBuildingData.HologramData | Add-Member -MemberType NoteProperty -Name $name -Value $true -Force
    }
    foreach ($name in @('disablePerformRoofCheck', 'disableIsCollidingCheck')) {
        $gameplay.BaseBuildingData.ConstructionData | Add-Member -MemberType NoteProperty -Name $name -Value $true -Force
    }
    Write-Utf8File $Path ($gameplay | ConvertTo-Json -Depth 30)
}

function Write-ServerConfig {
    param($Settings, [string]$Path)
    $s = $Settings
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $dayRate = $s.DayAcceleration.ToString($culture)
    $nightRate = $s.NightAcceleration.ToString($culture)
    $text = @"
// Generated by Servahz. Edit config/server.local.json and rerun 01-Instellen.cmd.
hostname = "$($s.Hostname)";
password = "$($s.ServerPassword)";
passwordAdmin = "$($s.AdminPassword)";
maxPlayers = $($s.MaxPlayers);
verifySignatures = 2;
forceSameBuild = 1;
disableVoN = 0;
vonCodecQuality = 20;
disable3rdPerson = 0;
disableCrosshair = 0;
serverTime = "2026/07/01/09/00";
serverTimeAcceleration = $dayRate;
serverNightTimeAcceleration = $nightRate;
serverTimePersistent = 1;
guaranteedUpdates = 1;
loginQueueConcurrentPlayers = 5;
loginQueueMaxPlayers = 50;
instanceId = 1;
storageAutoFix = 1;
steamQueryPort = $($s.QueryPort);
enableCfgGameplayFile = 1;
class Missions
{
    class Servahz
    {
        template = "$script:MissionName";
    };
};
"@
    Write-Utf8File $Path $text
}

function Get-LaunchArguments {
    param($Settings, $Layout)
    $paths = @(Get-ModManifest | ForEach-Object { Join-Path $Layout.Runtime ('Mods/' + $_.Folder) })
    return @(
        ('"-config=' + $Layout.Config + '"'),
        ('"-profiles=' + $Layout.Profiles + '"'),
        ('-port=' + $Settings.GamePort),
        ('"-mod=' + ($paths -join ';') + '"'),
        '-dologs', '-adminlog', '-netlog', '-freezecheck'
    )
}

Export-ModuleMember -Function *
