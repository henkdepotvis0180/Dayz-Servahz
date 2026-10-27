#requires -Version 5.1
[CmdletBinding()]
param([string]$ServerPath, [string]$WorkshopPath, [switch]$TestMode)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    Assert-ServerStopped
    $root = Split-Path $PSScriptRoot -Parent
    $localConfig = Join-Path $root 'config/server.local.json'
    if (!(Test-Path -LiteralPath $localConfig)) {
        Copy-Item -LiteralPath (Join-Path $root 'config/server.example.json') -Destination $localConfig
    }
    $settings = Get-Content -LiteralPath $localConfig -Raw | ConvertFrom-Json
    if ($TestMode) {
        $backup = Join-Path $root ('.local/Backups/server-before-testmode-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.json')
        New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $localConfig -Destination $backup
    }
    # Migrate existing local settings without replacing paths or passwords.
    if ($settings.PSObject.Properties.Name -notcontains 'MilitaryLootMultiplier') {
        $settings | Add-Member -MemberType NoteProperty -Name MilitaryLootMultiplier -Value 2
    }
    if ($settings.PSObject.Properties.Name -notcontains 'LootDamageMax') {
        $settings | Add-Member -MemberType NoteProperty -Name LootDamageMax -Value 0.15
    }
    if ($settings.PSObject.Properties.Name -notcontains 'TestSuppliesEverywhere') {
        $settings | Add-Member -MemberType NoteProperty -Name TestSuppliesEverywhere -Value $false
    }
    if ($settings.PSObject.Properties.Name -notcontains 'TestMilitaryEverywhere') {
        $settings | Add-Member -MemberType NoteProperty -Name TestMilitaryEverywhere -Value $false
    }
    if ($TestMode) {
        $settings.LootMultiplier = 8
        $settings.MilitaryLootMultiplier = 3
        $settings.LootDamageMax = 0.10
        $settings.TestMilitaryEverywhere = $true
        $settings.TestSuppliesEverywhere = $true
    }
    if ($ServerPath) { $settings.ServerPath = $ServerPath }
    if ($WorkshopPath) { $settings.WorkshopPath = $WorkshopPath }
    foreach ($name in @('ServerPath', 'WorkshopPath')) {
        if ($settings.$name -and !(Test-Path -LiteralPath $settings.$name -PathType Container -ErrorAction SilentlyContinue)) {
            if ($PSBoundParameters.ContainsKey($name)) {
                throw "De opgegeven $name is niet bereikbaar. Controleer het pad en of de schijf is aangesloten."
            }
            Write-Warning "Opgeslagen $name is niet meer bereikbaar. Steam-locaties opnieuw zoeken."
            $settings.$name = ''
        }
    }
    if (!$settings.ServerPath -or !$settings.WorkshopPath) {
        foreach ($library in (Get-SteamLibraries)) {
            $candidate = [IO.Path]::Combine($library, 'steamapps/common/DayZServer')
            if (!$settings.ServerPath -and (Test-Path -LiteralPath ([IO.Path]::Combine($candidate, 'DayZServer_x64.exe')) -ErrorAction SilentlyContinue)) {
                $settings.ServerPath = $candidate
            }
            $candidate = [IO.Path]::Combine($library, 'steamapps/workshop/content/221100')
            if (!$settings.WorkshopPath -and (Test-Path -LiteralPath $candidate -PathType Container -ErrorAction SilentlyContinue)) { $settings.WorkshopPath = $candidate }
        }
    }
    if (!$settings.ServerPath) {
        throw 'DayZ Server niet gevonden. Installeer DayZ Server via Steam > Bibliotheek > Tools. Of gebruik -ServerPath "D:\SteamLibrary\steamapps\common\DayZServer".'
    }
    if (!$settings.WorkshopPath) {
        throw 'Workshop niet gevonden. Abonneer je op alle mods in Mods.html, wacht op Steam-downloads, of geef -WorkshopPath op.'
    }
    $settings.ServerPath = [IO.Path]::GetFullPath($settings.ServerPath)
    $settings.WorkshopPath = [IO.Path]::GetFullPath($settings.WorkshopPath)
    if (!$settings.AdminPassword) { $settings.AdminPassword = [guid]::NewGuid().ToString('N') }
    Write-Utf8File $localConfig ($settings | ConvertTo-Json -Depth 5)
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    $baseline = Join-Path $layout.Server 'mpmissions/dayzOffline.chernarusplus'
    foreach ($file in @('DayZServer_x64.exe', 'mpmissions/dayzOffline.chernarusplus/init.c',
            'mpmissions/dayzOffline.chernarusplus/db/types.xml',
            'mpmissions/dayzOffline.chernarusplus/db/globals.xml',
            'mpmissions/dayzOffline.chernarusplus/cfgeconomycore.xml',
            'mpmissions/dayzOffline.chernarusplus/cfggameplay.json')) {
        if (!(Test-Path -LiteralPath (Join-Path $layout.Server $file))) { throw "Serverbestand ontbreekt: $file. Controleer de Steam-installatie." }
    }
    # Validate every download BEFORE writing the mission or touching live mod copies.
    foreach ($mod in (Get-ModManifest)) {
        $source = Join-Path $settings.WorkshopPath $mod.Id
        $addons = Join-Path $source 'Addons'
        if (!(Test-Path -LiteralPath $addons) -or @(Get-ChildItem -LiteralPath $addons -Filter '*.pbo').Count -eq 0) {
            throw "Mod ontbreekt of download is niet klaar: $($mod.Name). Zie Mods.html. Verwachte map: $source"
        }
        if (@(Get-ChildItem -LiteralPath $source -Recurse -Filter '*.bikey').Count -eq 0) {
            throw "Handtekeningsleutel ontbreekt voor $($mod.Name). Laat Steam de mod opnieuw downloaden."
        }
    }
    if ((Test-Path -LiteralPath $layout.Runtime) -and !(Test-Path -LiteralPath $layout.Marker)) {
        throw "De map $($layout.Runtime) bestaat zonder Servahz-marker. Kies een andere serverinstallatie; bestaande bestanden worden niet overschreven."
    }
    if ((Test-Path -LiteralPath $layout.Mission) -and !(Test-Path -LiteralPath (Join-Path $layout.Mission '.servahz-managed'))) {
        throw 'De missie servahz.chernarusplus bestaat al en hoort niet bij dit pakket. Er is niets overschreven.'
    }
    New-Item -ItemType Directory -Path $layout.Runtime -Force | Out-Null
    Write-Utf8File $layout.Marker 'Managed by Dayz-Servahz. Do not remove this marker.'
    if (!(Test-Path -LiteralPath $layout.Mission)) {
        # Copy the pristine mission, never a previous storage_1/save directory.
        New-Item -ItemType Directory -Path $layout.Mission -Force | Out-Null
        foreach ($entry in (Get-ChildItem -LiteralPath $baseline -Force)) {
            if ($entry.Name -like 'storage_*') { continue }
            Copy-Item -LiteralPath $entry.FullName -Destination $layout.Mission -Recurse
        }
        Write-Utf8File (Join-Path $layout.Mission '.servahz-managed') 'Managed by Dayz-Servahz.'
    }
    Save-ManagedBackup $layout
    # Each target is an owned mod directory. Stage a full copy so obsolete PBOs
    # disappear on updates; do not merge new and old Workshop versions.
    foreach ($mod in (Get-ModManifest)) {
        Write-Host "Mod kopieren: $($mod.Name)"
        $source = Join-Path $settings.WorkshopPath $mod.Id
        $target = Join-Path $layout.Runtime ('Mods/' + $mod.Folder)
        $stage = $target + '.staging'
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
        Copy-Item -LiteralPath $source -Destination $stage -Recurse
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
        Move-Item -LiteralPath $stage -Destination $target
        $keys = Join-Path $layout.Server 'keys'
        New-Item -ItemType Directory -Path $keys -Force | Out-Null
        Get-ChildItem -LiteralPath $target -Recurse -Filter '*.bikey' | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $keys -Force
        }
    }
    $count = Set-LootMultiplier -Source (Join-Path $baseline 'db/types.xml') -Destination (Join-Path $layout.Mission 'db/types.xml') -Multiplier $settings.LootMultiplier -MilitaryMultiplier $settings.MilitaryLootMultiplier -MilitaryEverywhere:$settings.TestMilitaryEverywhere
    $globals = Join-Path $layout.Mission 'db/globals.xml'
    if (!(Test-Path -LiteralPath $globals)) { Copy-Item -LiteralPath (Join-Path $baseline 'db/globals.xml') -Destination $globals }
    Set-LootCondition -Path $globals -MaximumDamage $settings.LootDamageMax
    Set-EconomyInclude (Join-Path $layout.Mission 'cfgeconomycore.xml')
    Set-EasyBuilding (Join-Path $layout.Mission 'cfggameplay.json')
    $missionConfig = Join-Path $root 'config/mission'
    foreach ($file in (Get-ChildItem -LiteralPath $missionConfig -Recurse -File)) {
        $relative = $file.FullName.Substring($missionConfig.Length + 1)
        $target = Join-Path $layout.Mission $relative
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
    if ($settings.TestSuppliesEverywhere) {
        Set-TestSupplies (Join-Path $layout.Mission 'db/types.xml')
        Set-TestSupplies (Join-Path $layout.Mission 'servahz_ce/building_types.xml')
    }
    New-Item -ItemType Directory -Path $layout.Profiles -Force | Out-Null
    # Seed RaG defaults once. Existing server preferences and unknown fields stay intact.
    $ragRelative = 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
    $ragTarget = Join-Path $layout.Profiles $ragRelative
    if (!(Test-Path -LiteralPath $ragTarget)) {
        $ragSource = Join-Path $root ('config/profiles/' + $ragRelative)
        $null = Get-Content -LiteralPath $ragSource -Raw | ConvertFrom-Json
        New-Item -ItemType Directory -Path (Split-Path $ragTarget -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $ragSource -Destination $ragTarget
    }
    Write-ServerConfig $settings $layout.Config
    Write-Host "Klaar: $count vanilla-loottypen op $($settings.LootMultiplier)x. Missie: servahz.chernarusplus"
    Write-Host "Military-loot: extra $($settings.MilitaryLootMultiplier)x (totaal $($settings.LootMultiplier * $settings.MilitaryLootMultiplier)x vanilla)."
    Write-Host "Nieuwe CE-loot: maximale beginschade $($settings.LootDamageMax). Bestaande items worden niet gerepareerd."
    if ($settings.TestMilitaryEverywhere) { Write-Host 'Teststand: normale militaire loot ook in steden, dorpen, industrie, boerderijen, politie en jachtgebieden; tiers 1-4.' }
    if ($settings.TestSuppliesEverywhere) { Write-Host 'Testvoorraad: dubbele doelen voor wapens, munitie en bouwvoorraad op alle 17 locatiecategorieen; planken en lumber als loot.' }
    Write-Host 'Start met 02-Start-server.cmd. Configuratie: config/server.local.json.'
    if (!$settings.ServerPassword) { Write-Warning 'Geen serverwachtwoord ingesteld. Stel ServerPassword in voordat je poorten opent en voer deze installer opnieuw uit.' }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
