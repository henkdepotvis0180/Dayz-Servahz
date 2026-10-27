#requires -Version 5.1
[CmdletBinding()]
param([switch]$StaticOnly, [string]$Address = '127.0.0.1')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    foreach ($file in @($layout.Marker, $layout.Config, (Join-Path $layout.Server 'DayZServer_x64.exe'),
            (Join-Path $layout.Mission 'init.c'), (Join-Path $layout.Mission 'db/types.xml'),
            (Join-Path $layout.Mission 'cfgeconomycore.xml'))) {
        if (!(Test-Path -LiteralPath $file)) { throw "Bestand ontbreekt: $file. Voer 01-Instellen.cmd uit." }
    }
    [xml]$types = Get-Content -LiteralPath (Join-Path $layout.Mission 'db/types.xml') -Raw
    [xml]$core = Get-Content -LiteralPath (Join-Path $layout.Mission 'cfgeconomycore.xml') -Raw
    [xml]$building = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/building_types.xml') -Raw
    [xml]$globals = Get-Content -LiteralPath (Join-Path $layout.Mission 'db/globals.xml') -Raw
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
