# CJ187's V106 profile format. No mod code or map coordinates are redistributed.
function Assert-LootChestConfig {
    param($Config)
    foreach ($field in @('LootChestsLocations', 'LCPredefinedWeapons', 'LootCategories')) {
        if ($null -eq $Config -or $Config.PSObject.Properties.Name -notcontains $field) { throw 'CJ187-profiel mist verplichte velden. Bestaand profiel wordt niet overschreven.' }
    }
    $tables = @($Config.LootCategories | ForEach-Object { $_.name })
    $weapons = @($Config.LCPredefinedWeapons | ForEach-Object { $_.defname })
    $count = 0
    foreach ($location in $Config.LootChestsLocations) {
        if ($location.keyclass -ne '' -or [int]$location.openable -ne 2) { throw 'CJ187-profiel bevat vergrendelde kisten. Maak keyclass leeg en zet openable op 2; eigen profiel blijft behouden.' }
        if ([int]$location.number -lt 1 -or [int]$location.number -gt @($location.pos).Count) { throw 'CJ187-profiel heeft een ongeldig aantal kisten/posities.' }
        foreach ($position in $location.pos) {
            $parts = $position -split '\|'
            if ($parts.Count -ne 2) { throw 'CJ187-profiel heeft een ongeldige positie.' }
            foreach ($part in $parts) {
                $values = @($part.Trim() -split '\s+')
                if ($values.Count -ne 3) { throw 'CJ187-profiel heeft een ongeldige vector.' }
                foreach ($value in $values) {
                    $number = 0.0
                    if (![double]::TryParse($value, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or [double]::IsNaN($number) -or [double]::IsInfinity($number)) { throw 'CJ187-profiel heeft een ongeldige coördinaat.' }
                }
            }
        }
        if (@($location.chest).Count -eq 0 -or @($location.loot).Count -eq 0) { throw 'CJ187-profiel heeft een lege kist of voorraad.' }
        foreach ($item in $location.loot) {
            if ($item -like 'LC_Table_*' -and $item -notin $tables) { throw 'CJ187-profiel verwijst naar een ontbrekende loottabel.' }
            if ($item -like 'LC_predefined_*' -and $item -notin $weapons) { throw 'CJ187-profiel verwijst naar een ontbrekende wapenset.' }
        }
        $count += [int]$location.number
    }
    if ($count -eq 0) { throw 'CJ187-profiel bevat geen voorraadkisten.' }
    return $count
}

function New-LootChestConfig {
    param([string]$PositionsPath, [string]$GroupsPath)
    [xml]$positions = Get-Content -LiteralPath $PositionsPath -Raw
    [xml]$groups = Get-Content -LiteralPath $GroupsPath -Raw
    $recipe = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-chests.json') -Raw | ConvertFrom-Json
    $balance = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-balance.json') -Raw | ConvertFrom-Json
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $exclusion = $null
    $privatePath = Join-Path $script:PackageRoot '.local/loot-refresh-settings.json'
    if (Test-Path -LiteralPath $privatePath) {
        $exclusion = Get-Content -LiteralPath $privatePath -Raw | ConvertFrom-Json
        foreach ($field in @('CenterX', 'CenterZ', 'Radius')) {
            if ($exclusion.PSObject.Properties.Name -notcontains $field -or $exclusion.$field -isnot [ValueType] -or [double]::IsNaN([double]$exclusion.$field) -or [double]::IsInfinity([double]$exclusion.$field)) { throw 'Privé-basecirkel is ongeldig; er worden geen kistposities geraden.' }
        }
        if ($exclusion.CenterX -lt 0 -or $exclusion.CenterX -gt 15360 -or $exclusion.CenterZ -lt 0 -or $exclusion.CenterZ -gt 15360 -or $exclusion.Radius -lt 500 -or $exclusion.Radius -gt 5000) { throw 'Privé-basecirkel valt buiten de toegestane grenzen.' }
    }
    $prototypes = @{}
    foreach ($group in $groups.SelectNodes('/*/group')) {
        $name = $group.GetAttribute('name')
        if ($group.GetAttribute('lootmax') -eq '0') { continue }
        $usages = @($group.SelectNodes('usage') | ForEach-Object { $_.GetAttribute('name') })
        $kind = ''; $priority = 0
        if ($name -match '^Land_(City_(Store|Stand_(Grocery|FastFood))|Village_(store|Pub)|House_1B01_Pub|FuelStation_Build|Workshop_FuelStation)') { $kind = 'Food'; $priority = 1 }
        elseif ('Medic' -in $usages) { $kind = 'Medical'; $priority = 2 }
        elseif ('Military' -in $usages -or 'Police' -in $usages) { $kind = 'Weapons'; $priority = 3 }
        elseif ($name -match '^Land_(Workshop|Shed|Barn)' -and ('Industrial' -in $usages -or 'Farm' -in $usages)) { $kind = 'Building'; $priority = 4 }
        elseif ($name -match '^Land_House(Block)?_') { $kind = 'General'; $priority = 5 }
        if (!$kind) { continue }
        # Lowest floor first; widest existing floor spawn volume gives clearance.
        $points = @()
        foreach ($container in $group.SelectNodes('container[@name="lootFloor"]')) {
            if ($container.GetAttribute('lootmax') -eq '0') { continue }
            foreach ($point in $container.SelectNodes('point')) {
                $range = [double]::Parse($point.GetAttribute('range'), $culture)
                $height = [double]::Parse($point.GetAttribute('height'), $culture)
                if ($range -lt $recipe.MinimumPointRange -or $height -lt 1) { continue }
                $xyz = @($point.GetAttribute('pos') -split '\s+' | ForEach-Object { [double]::Parse($_, $culture) })
                $points += [pscustomobject]@{ X = $xyz[0]; Y = $xyz[1]; Z = $xyz[2]; Range = $range }
            }
        }
        $point = $points | Sort-Object Y, @{ Expression = 'Range'; Descending = $true } | Select-Object -First 1
        if ($null -ne $point) { $prototypes[$name] = [pscustomobject]@{ Point = $point; Kind = $kind; Priority = $priority } }
    }
    $cells = @{}
    foreach ($building in $positions.SelectNodes('/*/group')) {
        $name = $building.GetAttribute('name')
        if (!$prototypes.ContainsKey($name)) { continue }
        $origin = @($building.GetAttribute('pos') -split '\s+' | ForEach-Object { [double]::Parse($_, $culture) })
        $rpy = @($building.GetAttribute('rpy') -split '\s+' | ForEach-Object { [double]::Parse($_, $culture) })
        # Ignore tilted structures; never guess terrain height or flatten them.
        if ([Math]::Abs($rpy[0]) -gt 0.1 -or [Math]::Abs($rpy[1]) -gt 0.1) { continue }
        $prototype = $prototypes[$name]; $point = $prototype.Point
        $yaw = $rpy[2] * [Math]::PI / 180
        $x = $origin[0] + $point.X * [Math]::Cos($yaw) + $point.Z * [Math]::Sin($yaw)
        $z = $origin[2] - $point.X * [Math]::Sin($yaw) + $point.Z * [Math]::Cos($yaw)
        $y = $origin[1] + $point.Y + 0.03
        if ($x -le 0 -or $z -le 0 -or $x -ge 15360 -or $z -ge 15360) { continue }
        if ($null -ne $exclusion -and ([Math]::Pow($x - $exclusion.CenterX, 2) + [Math]::Pow($z - $exclusion.CenterZ, 2)) -le [Math]::Pow($exclusion.Radius, 2)) { continue }
        $cellX = [int][Math]::Floor($x / $recipe.CellSize)
        $cellZ = [int][Math]::Floor($z / $recipe.CellSize)
        $cell = "$cellX,$cellZ"
        $candidate = [pscustomobject]@{ X = $x; Y = $y; Z = $z; Yaw = $rpy[2]; Kind = $prototype.Kind; Priority = $prototype.Priority; CellX = $cellX; CellZ = $cellZ; Building = $name }
        if (!$cells.ContainsKey($cell) -or $candidate.Priority -lt $cells[$cell].Priority) { $cells[$cell] = $candidate }
    }
    $selected = @(); $locations = @(); $definitions = @(); $weaponIndex = 0
    $weaponSets = @($balance.WeaponSets | Where-Object { $_.Magazine })
    foreach ($candidate in @($cells.Values | Sort-Object CellZ, CellX)) {
        $near = $false
        foreach ($previous in $selected) {
            if ([Math]::Pow($previous.X - $candidate.X, 2) + [Math]::Pow($previous.Z - $candidate.Z, 2) -lt [Math]::Pow($recipe.MinimumSpacing, 2)) { $near = $true; break }
        }
        if ($near) { continue }
        $selected += $candidate
        $loot = @($recipe.Loadouts.($candidate.Kind))
        if ($candidate.Kind -eq 'Weapons') {
            $set = $weaponSets[$weaponIndex % $weaponSets.Count]
            $definition = 'LC_predefined_Servahz_' + $weaponIndex
            $definitions += [pscustomobject]@{ defname = $definition; weapon = $set.Weapon; magazine = $set.Magazine; attachments = @(); optic = ''; opticbattery = 0 }
            $loot += @($definition, $set.Ammo, $set.Ammo, $set.Magazine)
            $weaponIndex++
        }
        $position = [string]::Format($culture, '{0:F3} {1:F3} {2:F3}|{3:F3} 0 0', [object[]]@($candidate.X, $candidate.Y, $candidate.Z, $candidate.Yaw))
        $locations += [pscustomobject]@{
            name = ('Servahz_' + $candidate.Kind + '_' + $candidate.CellX + '_' + $candidate.CellZ)
            number = 1; pos = @($position); keyclass = ''; openable = 2
            chest = @($(if ($candidate.Kind -eq 'Weapons') { 'CJ_LootChest_Olive_Large' } else { 'CJ_LootChest_Brown_Large' }))
            lootrandomize = 0; light = 1; loot = $loot
        }
        if ($locations.Count -ge $recipe.MaxChests) { break }
    }
    $config = [pscustomobject]@{ EnableDebug = 0; DeleteLogs = 0; MaxSpareMags = 2; RandomQuantity = 0; LootChestsLocations = $locations; LCPredefinedWeapons = $definitions; LootCategories = @($recipe.LootCategories) }
    $null = Assert-LootChestConfig $config
    return $config
}

function Write-LootChestLocations {
    param($Config, [string]$Path)
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $rows = @()
    foreach ($location in $Config.LootChestsLocations) {
        foreach ($position in $location.pos) {
            $xyz = (($position -split '\|')[0].Trim() -split '\s+')
            $rows += [pscustomobject]@{
                Kist = $location.name
                X = ([double]::Parse($xyz[0], $culture)).ToString('F1', $culture)
                Z = ([double]::Parse($xyz[2], $culture)).ToString('F1', $culture)
                Hoogte = ([double]::Parse($xyz[1], $culture)).ToString('F1', $culture)
                Aantal = $location.number
            }
        }
    }
    Write-Utf8File $Path (($rows | ConvertTo-Csv -NoTypeInformation -Delimiter ';') -join [Environment]::NewLine)
}
