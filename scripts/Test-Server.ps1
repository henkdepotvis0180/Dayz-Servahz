#requires -Version 5.1
[CmdletBinding()]
param([switch]$StaticOnly, [string]$Address = '127.0.0.1')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    $deliveryPath = Join-Path $layout.Profiles 'Servahz/CodeLockDelivery-request.json'
    if (Test-Path -LiteralPath $deliveryPath) {
        try {
            $delivery = Get-Content -LiteralPath $deliveryPath -Raw | ConvertFrom-Json
            if ($delivery.Schema -ne 1 -or $delivery.RequestId -notmatch '^[0-9a-f]{32}$' -or $delivery.SteamId -notmatch '^[0-9]{17}$') { throw 'Ongeldige levering' }
            $receiptPath = Join-Path $layout.Profiles 'Servahz/CodeLockDelivery-report.json'
            $status = 'Ingepland; wacht op inloggen van het opgegeven account'
            $claimed = Test-Path -LiteralPath (Join-Path $layout.Profiles ('Servahz/CodeLockDelivery-' + $delivery.RequestId + '.started'))
            if ($claimed) { $status = 'Uitvoering geclaimd; geen automatische extra levering bij een onderbreking' }
            if (Test-Path -LiteralPath $receiptPath) {
                $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
                if ($receipt.RequestId -eq $delivery.RequestId) {
                    switch ($receipt.Status) {
                        'Delivered' { $status = 'Geleverd: 1 DigitalCodeLock; batterij bevestigd=' + [bool]$receipt.BatteryAttached }
                        'NoInventorySpace' { $status = 'Geen ruimte; maak inventarisruimte en voer 09 opnieuw uit met gestopte server' }
                        'MissingClass' { $status = 'DigitalCodeLock ontbreekt in de geladen gamebestanden; nog niets geleverd' }
                        default { $status = 'Onbekend ontvangstbewijs; geen automatische extra levering' }
                    }
                }
            }
            Write-Host ('Codeslotlevering 0.18.4: ' + $status)
        } catch { Write-Warning 'Codeslotlevering kon niet veilig worden gecontroleerd; geen ID of inhoud afgedrukt.' }
    }
    $ragPath = Join-Path $layout.Profiles 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json'
    $rag = Get-Content -LiteralPath $ragPath -Raw | ConvertFrom-Json
    if (@($rag.PartCosts).Count -eq 0) { throw 'RaG-bouwkosten ontbreken in het profiel.' }
    foreach ($file in @($layout.Marker, $layout.Config, (Join-Path $layout.Server 'DayZServer_x64.exe'),
            (Join-Path $layout.Mission 'init.c'), (Join-Path $layout.Mission 'db/types.xml'),
            (Join-Path $layout.Mission 'cfgeconomycore.xml'))) {
        if (!(Test-Path -LiteralPath $file)) { throw "Bestand ontbreekt: $file. Voer 01-Instellen.cmd uit." }
    }
    [xml]$types = Get-Content -LiteralPath (Join-Path $layout.Mission 'db/types.xml') -Raw
    [xml]$core = Get-Content -LiteralPath (Join-Path $layout.Mission 'cfgeconomycore.xml') -Raw
    [xml]$building = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/building_types.xml') -Raw
    [xml]$extra = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/extra_types.xml') -Raw
    [xml]$attachments = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/extra_spawnabletypes.xml') -Raw
    [xml]$groups = Get-Content -LiteralPath (Join-Path $layout.Mission 'mapgroupproto.xml') -Raw
    foreach ($entry in @(@('building_types.xml', 'types'), @('extra_types.xml', 'types'), @('extra_spawnabletypes.xml', 'spawnabletypes'), @('lootchest_types.xml', 'types'))) {
        if (@($core.SelectNodes('/economycore/ce[@folder="servahz_ce"]/file[@name="' + $entry[0] + '" and @type="' + $entry[1] + '"]')).Count -ne 1) {
            throw "CE-koppeling ontbreekt of is dubbel: $($entry[0]). Voer de installer opnieuw uit."
        }
    }
    if (@($extra.SelectNodes('/types/type')).Count -lt 1) { throw 'Extra modloot ontbreekt.' }
    Write-Host "Extra modloot: $(@($extra.SelectNodes('/types/type')).Count) itemtypen gekoppeld aan de economie."
    $chestPath = Join-Path $layout.Profiles 'CJ_LootChests/LootChests_V106.json'
    $chestConfig = Get-Content -LiteralPath $chestPath -Raw | ConvertFrom-Json
    $chestCount = Assert-LootChestConfig $chestConfig
    [xml]$chestTypes = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/lootchest_types.xml') -Raw
    foreach ($name in @($chestConfig.LootChestsLocations | ForEach-Object { $_.chest } | Sort-Object -Unique)) {
        $type = $chestTypes.SelectSingleNode('/types/type[@name="' + $name + '"]')
        if ($null -eq $type -or [int]$type.nominal -ne 0 -or [int]$type.min -ne 0 -or [int]$type.lifetime -lt 86400) { throw 'CJ187-kisteconomie ontbreekt of laat losse extra kisten spawnen. Voer 01-Instellen.cmd uit.' }
    }
    Write-Host "CJ187 0.18: $chestCount voorraadkisten zonder sleutel ingesteld; inhoud wordt door de mod bij een serverstart gevuld."
    $militaryChests = Get-MilitaryLootChestSummary $chestConfig
    Write-Host "CJ187 militair 0.18.6: $($militaryChests.Military) groene locaties, $($militaryChests.WeaponTables) met wapentabel, $($militaryChests.DirectSets) met losse oude wapensetverwijzing. Configuratieaantallen, geen telling van gespawnde wapens."
    if ($militaryChests.DirectSets -gt 0) { Write-Warning 'Oude/eigen militaire kistinhoud gevonden. Alleen herkenbare ongewijzigde pakketinhoud wordt automatisch bijgewerkt; eigen inhoud blijft behouden.' }
    $chestLogs = Get-LootChestLogSummary -ProfilesPath $layout.Profiles
    if ($chestLogs.Files -gt 0) { Write-Host "CJ187-logsignalen: $($chestLogs.Files) recente logs; ruimte/te groot=$($chestLogs.Space), ontbrekende/ongeldige klasse=$($chestLogs.Classes), onleesbaar=$($chestLogs.Unreadable). Trefwoorden uit maximaal 200 regels per log; geen bewijs van een actuele oorzaak." }
    Write-Host ('Locatielijst: ' + (Join-Path $layout.Profiles 'CJ_LootChests/Servahz-Lootkisten.csv'))
    $balance = Get-Content -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) 'config/loot-balance.json') -Raw | ConvertFrom-Json
    foreach ($set in $balance.WeaponSets) {
        $weapon = $extra.SelectSingleNode('/types/type[@name="' + $set.Weapon + '"]')
        if ($null -eq $weapon -or [int]$weapon.nominal -le 0) { throw "Wapenvoorraad ontbreekt: $($set.Weapon). Voer 01-Instellen.cmd uit." }
        if ($set.Magazine) {
            $attachment = $attachments.SelectSingleNode('/spawnabletypes/type[@name="' + $set.Weapon + '"]/attachments[item[@name="' + $set.Magazine + '"]]')
            if ($null -eq $attachment -or $attachment.GetAttribute('chance') -ne '0.95') { throw "Magazijnkoppeling ontbreekt: $($set.Weapon)." }
        }
        foreach ($name in @($set.Ammo, $set.Magazine)) {
            if (!$name) { continue }
            $supply = $types.SelectSingleNode('/types/type[@name="' + $name + '"]')
            if ($null -eq $supply) { $supply = $extra.SelectSingleNode('/types/type[@name="' + $name + '"]') }
            if ($null -eq $supply) { continue }
            if ([int]$supply.nominal -lt ([int]$weapon.nominal * 2) -or [int]$supply.quantmin -ne 80 -or [int]$supply.quantmax -ne 100) {
                throw "Bijpassende voorraad is niet toegepast: $name. Voer 01-Instellen.cmd uit."
            }
        }
    }
    $obsolete = $extra.SelectSingleNode('/types/type[@name="GCGN_Ammo_762x51"]')
    if ($null -ne $obsolete -and [int]$obsolete.nominal -ne 0) { throw 'Oude 7.62x51-loot is nog actief; de geselecteerde SNAFU-geweren gebruiken .308 Winchester.' }
    if ($groups.SelectNodes('/*/group/container[@name="ServahzFood"]').Count -gt 0) { throw 'Oude voedselindeling gevonden. Voer 01-Instellen.cmd uit voor food-only schappen.' }
    $foodShelves = $groups.SelectNodes('/*/group/container[tag[@name="shelves"] and category[@name="food"] and count(category)=1]')
    $foodGoal = 0; $supplyGoal = 0; $modWeaponGoal = 0; $vanillaWeaponGoal = 0
    $modWeapons = @($balance.WeaponSets | ForEach-Object { $_.Weapon })
    foreach ($document in @($types, $extra)) {
        foreach ($node in $document.SelectNodes('/types/type[nominal > 0]')) {
            $name = $node.GetAttribute('name')
            if ($name -in $modWeapons) { $modWeaponGoal += [int]$node.nominal }
            if ($name -in $balance.VanillaFirearms) { $vanillaWeaponGoal += [int]$node.nominal }
            if ($name -in $balance.ShelfFood) { $foodGoal += [int]$node.nominal }
            elseif ($name -match '^(Ammo_|AmmoBox_|Mag_|Expansion_Ammo|SNAFU_Ammo_|GCGN_Ammo_)|(_Mag|_Mag_BK|rdMag_Black)$') { $supplyGoal += [int]$node.nominal }
        }
    }
    Write-Host "Lootbalans 0.17: $($foodShelves.Count) food-only schappen; doelen eten/drinken=$foodGoal, munitie/magazijnen=$supplyGoal. Dit zijn configuratiedoelen, geen actuele wereldtelling."
    Write-Host "Wapendoelen: modwapens=$modWeaponGoal, vanilla-vuurwapens=$vanillaWeaponGoal. Bestaande items worden niet verwijderd."
    # Only emit class names, never full RPT lines (which can contain player data).
    try {
        $rpt = Get-ChildItem -LiteralPath $layout.Profiles -Filter '*.RPT' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -ne $rpt) {
            $unknown = @()
            foreach ($line in (Get-Content -LiteralPath $rpt.FullName -Tail 5000)) {
                if ($line -match '(?i)(unknown|cannot|can.t spawn|not found|does not exist|doesn.t exist|no such|failed|no economy profile)') {
                    foreach ($match in [regex]::Matches($line, '(?i)\b(?:SNAFU|GCGN|Expansion_|CJ_LootChest_)[A-Za-z0-9_]*\b')) { $unknown += $match.Value }
                }
            }
            foreach ($name in @($unknown | Sort-Object -Unique | Select-Object -First 15)) { Write-Warning "RPT-waarschuwing met modklasse: $name. Controleer de modversie/spawnklasse." }
        }
    } catch { Write-Warning 'Laatste RPT kon niet worden gelezen; de statische configuratiecontrole gaat verder.' }
    [xml]$globals = Get-Content -LiteralPath (Join-Path $layout.Mission 'db/globals.xml') -Raw
    if ($settings.TestFastRestock) {
        $expected = @{ RestartSpawn = 50; RespawnTypes = 30; RespawnLimit = 50; RespawnAttempt = 4; LootSpawnAvoidance = 50 }
        foreach ($name in $expected.Keys) {
            $node = $globals.SelectSingleNode('/variables/var[@name="' + $name + '"]')
            if ($null -eq $node -or [int]$node.GetAttribute('value') -ne $expected[$name]) {
                throw "Snelle testaanvulling is niet toegepast: $name. Voer 04-Teststand.cmd opnieuw uit."
            }
        }
        Write-Host 'Snelle testaanvulling: RestartSpawn=50%, 30 typen, 50 items/type, 4 pogingen, 50 m afstand.'
    }
    $damageMin = $globals.SelectSingleNode('/variables/var[@name="LootDamageMin"]')
    $damageMax = $globals.SelectSingleNode('/variables/var[@name="LootDamageMax"]')
    if ($null -eq $damageMin -or $null -eq $damageMax) { throw 'Lootconditie ontbreekt in db/globals.xml.' }
    $culture = [Globalization.CultureInfo]::InvariantCulture
    if ([double]::Parse($damageMin.GetAttribute('value'), $culture) -ne 0 -or [double]::Parse($damageMax.GetAttribute('value'), $culture) -ne $settings.LootDamageMax) {
        throw 'Lootconditie is nog niet toegepast. Voer 01-Instellen.cmd opnieuw uit.'
    }
    if ($types.SelectNodes('/types/type').Count -eq 0 -or $building.SelectNodes('/types/type').Count -eq 0) { throw 'Geen loottypen gevonden.' }
    if ($core.SelectNodes('/economycore/ce[@folder="servahz_ce"]/file[@name="building_types.xml" and @type="types"]').Count -ne 1) { throw 'Bouwloot is niet correct geregistreerd.' }
    foreach ($relative in @('cfggameplay.json', 'expansion/settings/AIPatrolSettings.json', 'expansion/settings/BaseBuildingSettings.json', 'expansion/settings/MapSettings.json')) {
        $null = Get-Content -LiteralPath (Join-Path $layout.Mission $relative) -Raw | ConvertFrom-Json
    }
    $patrols = Get-Content -LiteralPath (Join-Path $layout.Mission 'expansion/settings/AIPatrolSettings.json') -Raw | ConvertFrom-Json
    if (!$patrols.Enabled -or @($patrols.Patrols).Count -eq 0) { throw 'AI-patrouilles ontbreken of zijn uitgeschakeld.' }
    $map = Get-Content -LiteralPath (Join-Path $layout.Mission 'expansion/settings/MapSettings.json') -Raw | ConvertFrom-Json
    if (!$map.EnableMap -or !$map.EnableHUDGPS -or !$map.CanOpenMapWithKeyBinding -or $map.NeedGPSItemForKeyBinding -or $map.NeedMapItemForKeyBinding) {
        throw 'Kaart/minimap is uitgeschakeld of vereist nog een kaart/GPS-item. Controleer MapSettings.json.'
    }
    $respawn = Get-RespawnSettingsPlan $layout
    if ($respawn.Write) { throw 'Persoonlijke respawn is nog niet ingesteld. Voer 01-Instellen.cmd uit met gestopte server.' }
    Write-Host 'Persoonlijke respawn: selectie en eigen territory ingeschakeld; alleen na overlijden/nieuw personage. Territorylidmaatschap en werkelijke spawn in-game controleren.'
    foreach ($mod in (Get-ModManifest)) {
        $path = Join-Path $layout.Runtime ('Mods/' + $mod.Folder)
        if (@(Get-ChildItem -LiteralPath (Join-Path $path 'Addons') -Filter '*.pbo').Count -eq 0) { throw "PBO ontbreekt: $($mod.Name)" }
        $bikeys = @(Get-ChildItem -LiteralPath $path -Filter '*.bikey' -Recurse)
        if ($bikeys.Count -eq 0) { throw "Modsleutel ontbreekt: $($mod.Name)" }
        foreach ($key in $bikeys) {
            $installed = Join-Path $layout.Server ('keys/' + $key.Name)
            if (!(Test-Path -LiteralPath $installed) -or (Get-FileHash -LiteralPath $installed).Hash -ne (Get-FileHash -LiteralPath $key.FullName).Hash) {
                throw "Server-sleutel ontbreekt of wijkt af: $($key.Name)"
            }
        }
    }
    $refreshRequest = Join-Path $layout.Profiles 'Servahz/LootRefresh-request.json'
    $refreshReport = Join-Path $layout.Profiles 'Servahz/LootRefresh-report.json'
    if (Test-Path -LiteralPath $refreshRequest) {
        $pending = Get-Content -LiteralPath $refreshRequest -Raw | ConvertFrom-Json
        Write-Host "Beschermde cirkel: X=$($pending.CenterX) Z=$($pending.CenterZ), straal $($pending.Radius) meter, ongeacht hoogte."
        $report = $null
        if (Test-Path -LiteralPath $refreshReport) {
            try { $report = Get-Content -LiteralPath $refreshReport -Raw | ConvertFrom-Json }
            catch { Write-Warning 'Scanrapport wordt geschreven of is onvolledig; controleer straks opnieuw.' }
        }
        if ($null -ne $report -and $report.RequestId -eq $pending.RequestId) {
            Write-Host "Lootverversing: $($report.Status), $($report.Cells)/225 vakken, kandidaten $($report.Candidates), verwijderd $($report.Deleted), overgeslagen $($report.Protected)."
            if ($report.PSObject.Properties.Name -contains 'Samples') {
                foreach ($sample in @($report.Samples | Select-Object -First 10)) { Write-Host "  Voorbeeld: $sample" }
            }
        } else { Write-Host 'Lootverversing ingepland; wacht op de scan na de volgende serverstart. Laat spelers uitgelogd.' }
    }
    Write-Host 'Configuratie, missie, AI, loot, kaart/minimap, modbestanden en sleutels: OK.'
    if (!$StaticOnly) {
        # Valve A2S_INFO, including challenge support. An open UDP port alone is not a check.
        $client = New-Object Net.Sockets.UdpClient
        try {
            $client.Client.ReceiveTimeout = 5000
            $client.Connect($Address, [int]$settings.QueryPort)
            [byte[]]$request = @(255, 255, 255, 255, 84) + [Text.Encoding]::ASCII.GetBytes("Source Engine Query`0")
            $null = $client.Send($request, $request.Length)
            $remote = New-Object Net.IPEndPoint ([Net.IPAddress]::Any), 0
            [byte[]]$response = $client.Receive([ref]$remote)
            if ($response.Length -ge 9 -and $response[4] -eq 65) {
                [byte[]]$request = $request + $response[5..8]
                $null = $client.Send($request, $request.Length)
                $response = $client.Receive([ref]$remote)
            }
            if ($response.Length -lt 7 -or $response[4] -ne 73) { throw 'Geen geldige A2S_INFO-respons ontvangen.' }
            $end = 6
            while ($end -lt $response.Length -and $response[$end] -ne 0) { $end++ }
            if ($end -ge $response.Length) { throw 'Afgebroken A2S_INFO-respons.' }
            $name = [Text.Encoding]::UTF8.GetString($response, 6, $end - 6)
            if ($name -ne $settings.Hostname) { throw "Andere server antwoordt op de querypoort: $name" }
            Write-Host "A2S_INFO: $name antwoordt op ${Address}:$($settings.QueryPort)."
            Write-Host 'Dit bevestigt de querydienst. Test ook in-game: verbinden, een AI-patrouille en bouwen; zie README.'
        } finally { $client.Dispose() }
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    if (!$StaticOnly) { Write-Host 'Geef de server enkele minuten om te laden. Bekijk daarna Servahz/Profiles/*.RPT en controleer poorten/firewall.' }
    exit 1
}
