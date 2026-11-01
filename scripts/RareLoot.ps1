# Keep persistence declarations intact: only future CE targets are changed.
function Get-ObsoleteFirearms {
    param($Balance)
    return @((@($Balance.VanillaFirearms) + @($Balance.WeaponSets | ForEach-Object { $_.Weapon })) |
        Where-Object { $_ -notin $Balance.RareWeaponBoost.Weapons } | Sort-Object -Unique)
}

function Get-RareSupplies {
    param($Balance)
    $sets = @($Balance.WeaponSets | Where-Object { $_.Weapon -in $Balance.RareWeaponBoost.Weapons })
    return @(@($sets | ForEach-Object { $_.Ammo; $_.Magazine }) + @(
        'Ammo_556x45Tracer', 'Ammo_308WinTracer', 'AmmoBox_556x45_20Rnd',
        'AmmoBox_308Win_20Rnd', 'AmmoBox_45ACP_25rnd',
        'AmmoBox_Expansion_46x30_25rnd', 'AmmoBox_Expansion_338_15rnd'))
}

function Set-RareWorldLoot {
    param([string]$Path, [string]$ExtraPath)
    $balance = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-balance.json') -Raw | ConvertFrom-Json
    $obsolete = @(Get-ObsoleteFirearms $balance)
    $supplies = @(Get-RareSupplies $balance)
    foreach ($file in @($Path, $ExtraPath)) {
        [xml]$xml = Get-Content -LiteralPath $file -Raw
        foreach ($type in $xml.SelectNodes('/types/type')) {
            $name = $type.GetAttribute('name')
            $isSupply = $name -match '^(Ammo_|AmmoBox_|Mag_|Expansion_Ammo|SNAFU_Ammo_|GCGN_Ammo_)|(_Mag|_Mag_BK|rdMag_Black)$'
            if (($name -in $balance.RareWeaponBoost.Weapons -or $name -in $supplies) -and [int]$type.nominal -gt 0) {
                foreach ($usage in @('Military', 'Police', 'Town', 'Village', 'Hunting', 'Farm', 'Industrial')) {
                    if ($null -eq $type.SelectSingleNode('usage[@name="' + $usage + '"]')) {
                        $tag = $xml.CreateElement('usage'); $tag.SetAttribute('name', $usage); $type.AppendChild($tag) | Out-Null
                    }
                }
            }
            if ($name -in $obsolete -or ($isSupply -and $name -notin $supplies)) {
                foreach ($key in @('nominal', 'min')) {
                    $node = $type.SelectSingleNode($key)
                    if ($null -ne $node) { $node.InnerText = '0' }
                }
            }
        }
        Save-Xml $xml $file
    }
}

function Update-RareLootChestConfig {
    param($Config)
    $balance = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-balance.json') -Raw | ConvertFrom-Json
    $recipe = Get-Content -LiteralPath (Join-Path $script:PackageRoot 'config/loot-chests.json') -Raw | ConvertFrom-Json
    $rareSets = @($balance.WeaponSets | Where-Object { $_.Weapon -in $balance.RareWeaponBoost.Weapons -and $_.Magazine })
    $changed = 0
    foreach ($location in $Config.LootChestsLocations) {
        if ($location.name -notmatch '^Servahz_Weapons_[0-9]+_[0-9]+$' -or @($location.chest).Count -ne 1 -or $location.chest[0] -ne 'CJ_LootChest_Olive_Large') { continue }
        $names = @($location.loot | Where-Object { $_ -cmatch '^LC_Table_Weapons_Servahz_[0-9]+$' })
        if ($names.Count -ne 1) { continue }
        $tables = @($Config.LootCategories | Where-Object { $_.name -ceq $names[0] })
        if ($tables.Count -ne 1 -or @($tables[0].Loot).Count -ne 1) { continue }
        $table = $tables[0]; $defname = $table.Loot[0]
        if ($defname -cnotmatch '^LC_predefined_Servahz_[0-9]+$') { continue }
        $definitions = @($Config.LCPredefinedWeapons | Where-Object { $_.defname -ceq $defname })
        if ($definitions.Count -ne 1) { continue }
        $definition = $definitions[0]
        if ($definition.weapon -in $balance.RareWeaponBoost.Weapons) { continue }
        $old = @($balance.WeaponSets | Where-Object { $_.Weapon -ceq $definition.weapon -and $_.Magazine -ceq $definition.magazine })
        if ($old.Count -ne 1 -or @($definition.attachments).Count -ne 0 -or $definition.optic -ne '' -or $definition.opticbattery -ne 0) { continue }
        $expected = @($names[0], $old[0].Magazine, $old[0].Ammo, $old[0].Ammo) + @($recipe.Loadouts.Weapons)
        if ((ConvertTo-Json -InputObject @($location.loot) -Compress) -cne (ConvertTo-Json -InputObject $expected -Compress)) { continue }
        # Refuse shared definitions/tables: editing those could alter custom chests.
        $references = @($Config.LootChestsLocations | Where-Object { $names[0] -cin $_.loot -or $defname -cin $_.loot })
        $tableRefs = @($Config.LootCategories | Where-Object { $defname -cin $_.Loot })
        if ($references.Count -ne 1 -or $tableRefs.Count -ne 1) { continue }
        $index = [int]$defname.Substring('LC_predefined_Servahz_'.Length)
        $set = $rareSets[$index % $rareSets.Count]
        $definition.weapon = $set.Weapon; $definition.magazine = $set.Magazine
        $location.loot = @($names[0], $set.Magazine, $set.Ammo, $set.Ammo) + @($recipe.Loadouts.Weapons)
        $changed++
    }
    return $changed
}
