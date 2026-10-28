#requires -Version 5.1
[CmdletBinding()]
param([double]$CenterX, [double]$CenterZ, [int]$Radius = 500, [switch]$Apply, [switch]$Disable)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    Assert-ServerStopped
    $root = Split-Path $PSScriptRoot -Parent
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    if (!(Test-Path -LiteralPath $layout.Marker) -or !(Test-Path -LiteralPath (Join-Path $layout.Mission '.servahz-managed'))) { throw 'Stel eerst het basispakket in.' }
    $initPath = Join-Path $layout.Mission 'init.c'
    $init = [IO.File]::ReadAllText($initPath)
    $hook = '#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_refresh/LootRefresh.c"'
    $stateDir = Join-Path $layout.Profiles 'Servahz'
    $requestPath = Join-Path $stateDir 'LootRefresh-request.json'
    if ($Disable) {
        $init = $init.Replace($hook, '').Replace('return new ServahzRefreshMission();', 'return new CustomMission();')
        Write-Utf8File $initPath $init
        if (Test-Path -LiteralPath $requestPath) { Remove-Item -LiteralPath $requestPath }
        Write-Host 'Lootverversing uitgeschakeld. Dit herstelt geen eerder verwijderde items; gebruik daarvoor de wereldbackup.'
        exit 0
    }
    $privatePath = Join-Path $root '.local/loot-refresh-settings.json'
    if ($PSBoundParameters.ContainsKey('CenterX') -xor $PSBoundParameters.ContainsKey('CenterZ')) { throw 'Geef zowel CenterX als CenterZ op.' }
    if (!$PSBoundParameters.ContainsKey('CenterX')) {
        if (Test-Path -LiteralPath $privatePath) {
            $private = Get-Content -LiteralPath $privatePath -Raw | ConvertFrom-Json
            $CenterX = $private.CenterX; $CenterZ = $private.CenterZ
            if (!$PSBoundParameters.ContainsKey('Radius')) { $Radius = $private.Radius }
        } else {
            $coordinates = (Read-Host 'Basepositie in meters: X Z (twee getallen, gescheiden door een spatie)').Trim() -split '\s+'
            if ($coordinates.Count -ne 2) { throw 'Gebruik twee gehele kaartcoordinaten, bijvoorbeeld X Z.' }
            $CenterX = [double]::Parse($coordinates[0], [Globalization.CultureInfo]::InvariantCulture)
            $CenterZ = [double]::Parse($coordinates[1], [Globalization.CultureInfo]::InvariantCulture)
        }
    }
    foreach ($coordinate in @($CenterX, $CenterZ)) {
        if ([double]::IsNaN($coordinate) -or [double]::IsInfinity($coordinate) -or $coordinate -le 0 -or $coordinate -ge 15360) { throw 'Coordinaten moeten binnen Chernarus liggen: groter dan 0 en kleiner dan 15360 meter.' }
    }
    if ($Radius -lt 500 -or $Radius -gt 5000) { throw 'Beschermingsradius moet tussen 500 en 5000 meter liggen.' }
    $originalReturn = 'return new CustomMission();'
    $patchedReturn = 'return new ServahzRefreshMission();'
    if (!$init.Contains($hook)) {
        if ([regex]::Matches($init, [regex]::Escape($originalReturn)).Count -ne 1) { throw 'Onbekend init.c. De lootverversing overschrijft geen eigen missiecode.' }
        $init = $init.Replace($originalReturn, $patchedReturn) + "`r`n" + $hook + "`r`n"
    } elseif (!$init.Contains($patchedReturn)) { throw 'Onvolledige missiehook. Gebruik -Disable en probeer opnieuw.' }
    $balance = Get-Content -LiteralPath (Join-Path $root 'config/loot-balance.json') -Raw | ConvertFrom-Json
    [xml]$types = Get-Content -LiteralPath (Join-Path $layout.Mission 'db/types.xml') -Raw
    [xml]$extra = Get-Content -LiteralPath (Join-Path $layout.Mission 'servahz_ce/extra_types.xml') -Raw
    $allowed = @($balance.VanillaFirearms) + @($balance.ShelfFood)
    foreach ($set in $balance.WeaponSets) { $allowed += @($set.Weapon, $set.Magazine, $set.Ammo) }
    foreach ($document in @($types, $extra)) {
        foreach ($node in $document.SelectNodes('/types/type[nominal > 0]')) {
            $flags = $node.SelectSingleNode('flags')
            if ($node.GetAttribute('name') -match '^(Ammo_|AmmoBox_|Mag_|Expansion_AmmoBox_)' -and $null -ne $flags -and $flags.GetAttribute('deloot') -ne '1' -and $flags.GetAttribute('crafted') -ne '1') { $allowed += $node.GetAttribute('name') }
        }
    }
    # Old .308-mismatched CE ammo is eligible too, outside the protected circle.
    $allowed += 'GCGN_Ammo_762x51'
    $allowed = @($allowed | Where-Object { $_ } | Sort-Object -Unique)
    $scriptHashes = @()
    foreach ($name in @('Policy.c', 'LootRefresh.c')) {
        $file = Join-Path $layout.Mission ('servahz_refresh/' + $name)
        if (!(Test-Path -LiteralPath $file)) { throw 'Lootverversingscode ontbreekt. Voer eerst 01-Instellen.cmd uit.' }
        $scriptHashes += (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    }
    $identity = (@($CenterX.ToString('R', [Globalization.CultureInfo]::InvariantCulture), $CenterZ.ToString('R', [Globalization.CultureInfo]::InvariantCulture), $Radius) + $scriptHashes + $allowed) -join '|'
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $policyHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($identity)))).Replace('-', '').ToLowerInvariant() } finally { $sha.Dispose() }
    $previewRequestId = ''
    if ($Apply) {
        $reportPath = Join-Path $stateDir 'LootRefresh-report.json'
        if (!(Test-Path -LiteralPath $requestPath) -or !(Test-Path -LiteralPath $reportPath)) { throw 'Voer eerst de proefscan uit; er is nog geen voltooid rapport.' }
        $prior = Get-Content -LiteralPath $requestPath -Raw | ConvertFrom-Json
        $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        if (!$prior.PreviewOnly -or $report.Status -ne 'PreviewCompleted' -or $report.RequestId -ne $prior.RequestId -or $report.PolicyHash -ne $policyHash -or $report.CenterX -ne $CenterX -or $report.CenterZ -ne $CenterZ -or $report.Radius -ne $Radius) { throw 'Geen passende voltooide proefscan. Voer eerst 05-Loot-proefscan.cmd uit en laat de scan afronden.' }
        $previewRequestId = $prior.RequestId
        Write-Host "Proefscan: $($report.Candidates) kandidaten buiten de beschermde cirkel. De actuele scan kan hiervan afwijken."
    }
    $requestId = [guid]::NewGuid().ToString('N')
    $backup = Join-Path $root ('.local/Backups/loot-refresh-' + $requestId)
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Backup-World.ps1') -Destination $backup
    if ($LASTEXITCODE -ne 0) { throw 'Wereldbackup mislukt. Er is geen lootverversing ingepland.' }
    $private = [ordered]@{ CenterX = $CenterX; CenterZ = $CenterZ; Radius = $Radius }
    Write-Utf8File $privatePath ($private | ConvertTo-Json)
    Write-Utf8File $initPath $init
    $request = [ordered]@{ Schema = 1; RequestId = $requestId; CenterX = $CenterX; CenterZ = $CenterZ; Radius = $Radius; PreviewOnly = !$Apply; PreviewRequestId = $previewRequestId; PolicyHash = $policyHash; BackupPath = $backup; AllowedTypes = $allowed }
    Write-Utf8File ($requestPath + '.tmp') ($request | ConvertTo-Json -Depth 4)
    Move-Item -LiteralPath ($requestPath + '.tmp') -Destination $requestPath -Force
    Write-Host "Beschermd: X=$CenterX Z=$CenterZ, straal $Radius meter, ongeacht hoogte. Backup: $backup"
    if ($Apply) { Write-Host 'Eenmalige uitvoering ingepland. Ook zelf gedropte doelitems BUITEN de beschermde cirkel kunnen verdwijnen.' }
    else { Write-Host 'Proefscan ingepland. Deze verwijdert niets.' }
    Write-Host 'Start met 02-Start-server.cmd en laat iedereen uitgelogd. De scan begint na 2 minuten. 03-Controleren.cmd toont de voortgang. Stop de server normaal voordat je een volgende stap uitvoert.'
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
