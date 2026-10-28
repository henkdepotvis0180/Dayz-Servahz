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
    if ($s.PSObject.Properties.Name -notcontains 'TestFastRestock') {
        $s | Add-Member -MemberType NoteProperty -Name TestFastRestock -Value $false
    }
    if ($s.TestFastRestock -isnot [bool]) { throw 'TestFastRestock moet true of false zijn, zonder quotes.' }
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
    foreach ($relative in @('db/types.xml', 'db/globals.xml', 'mapgroupproto.xml', 'cfgeconomycore.xml', 'cfggameplay.json',
            'expansion/settings/AIPatrolSettings.json', 'expansion/settings/BaseBuildingSettings.json',
            'expansion/settings/MapSettings.json',
            'servahz_ce/building_types.xml', 'servahz_ce/extra_types.xml', 'servahz_ce/extra_spawnabletypes.xml')) {
        $source = Join-Path $Layout.Mission $relative
        if (Test-Path -LiteralPath $source) {
            $target = Join-Path $dest ('mission/' + $relative)
            New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $target
        }
    }
    $ragRelative = 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
    $ragConfig = Join-Path $Layout.Profiles $ragRelative
    if (Test-Path -LiteralPath $ragConfig) {
        $target = Join-Path $dest ('Profiles/' + $ragRelative)
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $ragConfig -Destination $target
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
    param([string]$Source, [string]$Destination, [double]$Multiplier, [double]$MilitaryMultiplier = 2, [switch]$MilitaryEverywhere, [switch]$FastRestock)
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
        $flags = $type.SelectSingleNode('flags')
        if ($FastRestock -and $null -ne $flags -and $flags.GetAttribute('crafted') -ne '1' -and $flags.GetAttribute('deloot') -ne '1') {
            $restock = $type.SelectSingleNode('restock')
            if ($null -ne $restock) { $restock.InnerText = '0' }
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
            $extra = $name -match '^RaG_BB_.*Kit$|^RaG_BB_Book$|^BF_.*Kit$|^MMG_(assault_pack|carrier_backpack|camelback|supplybag|mmps_bag)_'
            if (!$weapon -and !$ammo -and !$expansion -and !$extra -and $name -notin $building) { continue }
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

function Set-SurvivalLoot {
    param([string]$Path, [string]$ExtraPath, [bool]$TestSupplies)
    $balance = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-balance.json') -Raw | ConvertFrom-Json
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    [xml]$extra = Get-Content -LiteralPath $ExtraPath -Raw
    $cap = [int]$balance.VanillaFirearmCap
    if ($TestSupplies) { $cap *= 2 }
    foreach ($type in $xml.SelectNodes('/types/type')) {
        $name = $type.GetAttribute('name')
        $nominal = $type.SelectSingleNode('nominal')
        $flags = $type.SelectSingleNode('flags')
        if ($null -eq $nominal -or [int]$nominal.InnerText -le 0 -or $null -eq $flags -or
            $flags.GetAttribute('crafted') -eq '1' -or $flags.GetAttribute('deloot') -eq '1') { continue }
        if ($name -in $balance.VanillaFirearms -and [int]$nominal.InnerText -gt $cap) {
            $nominal.InnerText = [string]$cap
            $minimum = $type.SelectSingleNode('min')
            if ($null -ne $minimum) { $minimum.InnerText = [string][Math]::Min([int]$minimum.InnerText, [int]($cap * 0.8)) }
        }
        if ($name -in $balance.ShelfFood) {
            $nominal.InnerText = [string]([int]$nominal.InnerText * [int]$balance.FoodFactor)
            $minimum = $type.SelectSingleNode('min')
            if ($null -ne $minimum) { $minimum.InnerText = [string][Math]::Max([int]$minimum.InnerText * [int]$balance.FoodFactor, [Math]::Ceiling([int]$nominal.InnerText * 0.9)) }
            $restock = $type.SelectSingleNode('restock')
            if ($null -ne $restock) { $restock.InnerText = '0' }
            if ($null -eq $type.SelectSingleNode('tag[@name="floor"]')) {
                $tag = $xml.CreateElement('tag'); $tag.SetAttribute('name','floor')
                $type.AppendChild($tag) | Out-Null
            }
            foreach ($pair in @(@('usage', @('Town', 'Village')), @('value', @('Tier1', 'Tier2', 'Tier3', 'Tier4')))) {
                foreach ($value in $pair[1]) {
                    if ($null -eq $type.SelectSingleNode($pair[0] + '[@name="' + $value + '"]')) {
                        $node = $xml.CreateElement($pair[0]); $node.SetAttribute('name', $value)
                        $type.AppendChild($node) | Out-Null
                    }
                }
            }
        }
    }
    $supplyCap = [int]$balance.SupplyCap
    $accessoryCap = [int]$balance.AccessoryCap
    if ($TestSupplies) { $supplyCap *= 2; $accessoryCap *= 2 }
    $guns = @($balance.VanillaFirearms) + @($balance.WeaponSets | ForEach-Object { $_.Weapon })
    foreach ($document in @($xml, $extra)) {
        foreach ($type in $document.SelectNodes('/types/type[nominal > 0]')) {
            $name = $type.GetAttribute('name')
            $flags = $type.SelectSingleNode('flags')
            if ($null -eq $flags -or $flags.GetAttribute('crafted') -eq '1' -or $flags.GetAttribute('deloot') -eq '1') { continue }
            if ($name -match '^(Ammo_|AmmoBox_|Mag_|Expansion_Ammo|SNAFU_Ammo_|GCGN_Ammo_)' -or $name -match '(_Mag|_Mag_BK|rdMag_Black)$') {
                $limit = $supplyCap
                if ($name -notmatch 'AmmoBox') {
                    foreach ($key in @('quantmin','quantmax')) {
                        $quantity = $type.SelectSingleNode($key)
                        if ($null -ne $quantity) { if ($key -eq 'quantmin') { $quantity.InnerText = '80' } else { $quantity.InnerText = '100' } }
                    }
                }
            } elseif ($null -ne $type.SelectSingleNode('category[@name="weapons"]') -and $name -notin $guns) {
                $limit = $accessoryCap
            } else { continue }
            $nominal = $type.SelectSingleNode('nominal')
            if ([int]$nominal.InnerText -gt $limit) {
                $nominal.InnerText = [string]$limit
                $minimum = $type.SelectSingleNode('min')
                if ($null -ne $minimum) { $minimum.InnerText = [string][Math]::Min([int]$minimum.InnerText, [int]($limit * 0.8)) }
            }
        }
    }
    # Match the locations and tiers of each selected mod gun to its actual ammo
    # and magazine; quantities turn loose rounds and spare magazines into useful finds.
    foreach ($set in $balance.WeaponSets) {
        $weapon = $extra.SelectSingleNode('/types/type[@name="' + $set.Weapon + '"]')
        foreach ($name in @($set.Ammo, $set.Magazine)) {
            if (!$name) { continue }
            $type = $xml.SelectSingleNode('/types/type[@name="' + $name + '"]')
            if ($null -eq $type) { $type = $extra.SelectSingleNode('/types/type[@name="' + $name + '"]') }
            if ($null -eq $type) { continue } # Older Steam baselines may omit a class.
            $flags = $type.SelectSingleNode('flags')
            if ($null -eq $flags -or $flags.GetAttribute('deloot') -eq '1' -or $flags.GetAttribute('crafted') -eq '1') { continue }
            $nominal = $type.SelectSingleNode('nominal')
            if ($null -eq $nominal -or [int]$nominal.InnerText -le 0) { continue }
            $floor = [int]$weapon.SelectSingleNode('nominal').InnerText * 2
            $nominal.InnerText = [string][Math]::Max([int]$nominal.InnerText, $floor)
            $minimum = $type.SelectSingleNode('min')
            if ($null -ne $minimum) { $minimum.InnerText = [string][Math]::Max([int]$minimum.InnerText, [int]($floor * 0.8)) }
            foreach ($key in @('quantmin', 'quantmax')) {
                $quantity = $type.SelectSingleNode($key)
                if ($null -ne $quantity) { if ($key -eq 'quantmin') { $quantity.InnerText = '80' } else { $quantity.InnerText = '100' } }
            }
            foreach ($key in @('usage', 'value')) {
                foreach ($source in $weapon.SelectNodes($key)) {
                    $value = $source.GetAttribute('name')
                    if ($null -eq $type.SelectSingleNode($key + '[@name="' + $value + '"]')) {
                        $node = $type.OwnerDocument.CreateElement($key); $node.SetAttribute('name', $value)
                        $type.AppendChild($node) | Out-Null
                    }
                }
            }
        }
    }
    Save-Xml $xml $Path
    Save-Xml $extra $ExtraPath
}

function Set-FoodShelves {
    param([string]$Path)
    # Use the original CE container names and coordinates. Every install starts
    # from Steam's prototype so capacity increases never compound.
    [xml]$xml = Get-Content -LiteralPath $Path -Raw
    $groupDefault = $xml.SelectSingleNode('/*/defaults/default[@name="group"]')
    $containerDefault = $xml.SelectSingleNode('/*/defaults/default[@name="container"]')
    $defaultGroupCap = 6; $defaultContainerCap = 4
    if ($null -ne $groupDefault) { $defaultGroupCap = [int]$groupDefault.GetAttribute('lootmax') }
    if ($null -ne $containerDefault) { $defaultContainerCap = [int]$containerDefault.GetAttribute('lootmax') }
    foreach ($group in $xml.SelectNodes('/*/group')) {
        $name = $group.GetAttribute('name')
        $shop = $name -match '^Land_(City_(Store|Stand_(Grocery|FastFood))|Village_(store|Pub)|House_1B01_Pub|FuelStation_Build|Workshop_FuelStation)'
        $isHouse = $name -match '^Land_House(Block)?_'
        if (!$shop -and !$isHouse) { continue }
        $groupCap = $defaultGroupCap
        if ($group.HasAttribute('lootmax')) { $groupCap = [int]$group.GetAttribute('lootmax') }
        if ($groupCap -le 0) { continue }
        $extra = 3
        if ($shop) { $extra = 12 }
        $changed = $false
        foreach ($shelf in @($group.SelectNodes('container[category[@name="food"] and tag[@name="shelves"]]'))) {
            $points = @($shelf.SelectNodes('point'))
            $cap = $defaultContainerCap
            if ($shelf.HasAttribute('lootmax')) { $cap = [int]$shelf.GetAttribute('lootmax') }
            if ($points.Count -eq 0 -or $cap -le 0) { continue }
            foreach ($category in @($shelf.SelectNodes('category[@name!="food"]'))) { $shelf.RemoveChild($category) | Out-Null }
            $shelf.SetAttribute('lootmax', [string][Math]::Max($cap, [Math]::Min($points.Count, $cap + $extra)))
            $changed = $true
        }
        if (!$changed) { continue }
        foreach ($floor in @($group.SelectNodes('container[tag[@name="floor"] and point]'))) {
            if ($floor.HasAttribute('lootmax') -and [int]$floor.GetAttribute('lootmax') -eq 0) { continue }
            if ($null -eq $floor.SelectSingleNode('category[@name="food"]')) {
                $category = $xml.CreateElement('category'); $category.SetAttribute('name', 'food')
                $floor.AppendChild($category) | Out-Null
            }
        }
        $pointCount = $group.SelectNodes('container/point').Count
        $group.SetAttribute('lootmax', [string][Math]::Max($groupCap, [Math]::Min($pointCount, $groupCap + $extra)))
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
    foreach ($entry in @(@('building_types.xml', 'types'), @('extra_types.xml', 'types'), @('extra_spawnabletypes.xml', 'spawnabletypes'))) {
        $file = $xml.CreateElement('file')
        $file.SetAttribute('name', $entry[0])
        $file.SetAttribute('type', $entry[1])
        $ce.AppendChild($file) | Out-Null
    }
    $xml.DocumentElement.AppendChild($ce) | Out-Null
    Save-Xml $xml $Path
}

function Set-LootRefill {
    param([string]$SourceGlobals, [string]$GlobalsPath, [string]$SourceGroups, [string]$GroupsPath, [bool]$Enabled)
    [xml]$baseline = Get-Content -LiteralPath $SourceGlobals -Raw
    [xml]$globals = Get-Content -LiteralPath $GlobalsPath -Raw
    $values = @{ RestartSpawn = 50; RespawnTypes = 30; RespawnLimit = 50; RespawnAttempt = 4; LootSpawnAvoidance = 50 }
    foreach ($name in $values.Keys) {
        $original = $baseline.SelectSingleNode('/variables/var[@name="' + $name + '"]')
        if ($null -eq $original) { throw "$name ontbreekt in de standaardglobals. Controleer de Steam-missie." }
        $node = $globals.SelectSingleNode('/variables/var[@name="' + $name + '"]')
        if ($null -eq $node) {
            $node = $globals.ImportNode($original, $true)
            $globals.DocumentElement.AppendChild($node) | Out-Null
        }
        $value = $original.GetAttribute('value')
        if ($Enabled) { $value = [string]$values[$name] }
        $node.SetAttribute('value', $value)
    }
    Save-Xml $globals $GlobalsPath
    # Raise existing capacity limits, preserving all positions, categories and exclusions.
    # Reading the pristine mission each time prevents cumulative doubling.
    [xml]$groups = Get-Content -LiteralPath $SourceGroups -Raw
    if ($Enabled) {
        foreach ($node in $groups.SelectNodes('//*[@lootmax]')) {
            $value = [int]$node.GetAttribute('lootmax')
            if ($value -gt 0) { $node.SetAttribute('lootmax', [string]($value * 2)) }
        }
    }
    Save-Xml $groups $GroupsPath
}

function Set-EasyBuilding {
    param([string]$Path)
    $gameplay = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($gameplay.PlayerData.PSObject.Properties.Name -notcontains 'StaminaData') {
        $gameplay.PlayerData | Add-Member -MemberType NoteProperty -Name StaminaData -Value ([pscustomobject]@{})
    }
    # Only standing sprint drain changes; combat actions, recovery and weight stay as configured.
    $gameplay.PlayerData.StaminaData | Add-Member -MemberType NoteProperty -Name sprintStaminaModifierErc -Value 0.25 -Force
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
