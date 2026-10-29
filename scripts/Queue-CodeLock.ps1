#requires -Version 5.1
[CmdletBinding()]
param([string]$SteamId, [switch]$Disable)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    Assert-ServerStopped
    $root = Split-Path $PSScriptRoot -Parent
    $layout = Get-ServerLayout (Read-ServerSettings)
    if (!(Test-Path -LiteralPath $layout.Marker) -or !(Test-Path -LiteralPath (Join-Path $layout.Mission '.servahz-managed'))) { throw 'Voer eerst 01-Instellen.cmd uit.' }
    $stateDir = Join-Path $layout.Profiles 'Servahz'
    $requestPath = Join-Path $stateDir 'CodeLockDelivery-request.json'
    if ($Disable) {
        if (Test-Path -LiteralPath $requestPath) { Remove-Item -LiteralPath $requestPath }
        Write-Host 'Nog niet uitgevoerde codeslotlevering uitgeschakeld. Reeds geleverde items blijven bestaan.'
        exit 0
    }
    if (Test-Path -LiteralPath $requestPath) {
        $prior = Get-Content -LiteralPath $requestPath -Raw | ConvertFrom-Json
        if ($prior.Schema -ne 1 -or $prior.RequestId -notmatch '^[0-9a-f]{32}$' -or $prior.SteamId -notmatch '^[0-9]{17}$') { throw 'Ongeldige bestaande levering; er is niets opnieuw ingepland.' }
        $receiptPath = Join-Path $stateDir 'CodeLockDelivery-report.json'
        $receipt = $null
        if (Test-Path -LiteralPath $receiptPath) { $receipt = Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json }
        if ($receipt -and $receipt.RequestId -eq $prior.RequestId -and $receipt.Status -eq 'NoInventorySpace') {
            if (!$SteamId) { $SteamId = $prior.SteamId }
        } else {
            Write-Host 'Deze levering bestaat al. Er is geen extra slot ingepland.'
            if ($receipt -and $receipt.RequestId -eq $prior.RequestId) { Write-Host ('Status: ' + (@{ Delivered = 'Geleverd'; MissingClass = 'DigitalCodeLock ontbreekt'; NoInventorySpace = 'Geen inventarisruimte' }[$receipt.Status])) }
            else { Write-Host 'Wacht op de levering na inloggen. Een onderbroken uitvoering wordt niet automatisch herhaald.' }
            exit 0
        }
    }
    if (!$SteamId) { $SteamId = (Read-Host 'Je eigen Steam64-ID (17 cijfers, geen wachtwoord)').Trim() }
    if ($SteamId -notmatch '^[0-9]{17}$') { throw 'Gebruik je Steam64-ID van 17 cijfers. Geen levering ingepland.' }
    $refreshPath = Join-Path $stateDir 'LootRefresh-request.json'
    if (Test-Path -LiteralPath $refreshPath) {
        $refresh = Get-Content -LiteralPath $refreshPath -Raw | ConvertFrom-Json
        if ($refresh.RequestId -notmatch '^[0-9a-f]{32}$' -or !(Test-Path -LiteralPath (Join-Path $stateDir ('LootRefresh-' + $refresh.RequestId + '.started')))) { throw 'Er staat nog een loot-proefscan/verversing klaar. Rond die eerst af of schakel die uit; codeslot niet ingepland.' }
    }
    foreach ($relative in @('servahz_delivery/CodeLockDelivery.c', 'servahz_delivery/Policy.c', 'servahz_refresh/LootRefresh.c', 'servahz_refresh/Policy.c')) {
        $target = Join-Path $layout.Mission $relative
        $source = Join-Path $root ('config/mission/' + $relative)
        if (!(Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $source).Hash) { throw 'Missiecode ontbreekt of wijkt af. Voer eerst de gewone update 0.18.4 uit; eigen code wordt niet overschreven.' }
    }
    $initPath = Join-Path $layout.Mission 'init.c'
    $init = [IO.File]::ReadAllText($initPath)
    $refreshHook = '#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_refresh/LootRefresh.c"'
    $deliveryHook = '#include "$CurrentDir:mpmissions/servahz.chernarusplus/servahz_delivery/CodeLockDelivery.c"'
    $factories = [regex]::Matches($init, 'return new (CustomMission|ServahzRefreshMission|ServahzDeliveryMission)\(\);')
    if ($factories.Count -ne 1) { throw 'Onbekend init.c; eigen missiecode wordt niet vervangen.' }
    $factory = $factories[0].Groups[1].Value
    if ($factory -eq 'ServahzRefreshMission' -and ([regex]::Matches($init, [regex]::Escape($refreshHook)).Count -ne 1 -or $init.Contains($deliveryHook))) { throw 'Onvolledige lootverversingshook; niets ingepland.' }
    if ($factory -eq 'ServahzDeliveryMission' -and ([regex]::Matches($init, [regex]::Escape($deliveryHook)).Count -ne 1 -or $init.Contains($refreshHook))) { throw 'Onvolledige leveringshook; niets ingepland.' }
    if ($factory -eq 'CustomMission' -and ($init.Contains($refreshHook) -or $init.Contains($deliveryHook))) { throw 'Onverwachte missiehook; niets ingepland.' }
    $init = $init.Replace($factories[0].Value, 'return new ServahzDeliveryMission();').Replace($refreshHook, '').Replace($deliveryHook, '')
    $init = $init.TrimEnd() + "`r`n" + $deliveryHook + "`r`n"
    $requestId = [guid]::NewGuid().ToString('N')
    $backup = Join-Path $root ('.local/Backups/codelock-' + $requestId)
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Backup-World.ps1') -Destination $backup
    if ($LASTEXITCODE -ne 0) { throw 'Wereldbackup mislukt; geen levering ingepland.' }
    Write-Utf8File $initPath $init
    $request = [ordered]@{ Schema = 1; RequestId = $requestId; SteamId = $SteamId }
    Write-Utf8File ($requestPath + '.tmp') ($request | ConvertTo-Json)
    Move-Item -LiteralPath ($requestPath + '.tmp') -Destination $requestPath -Force
    Write-Host 'Eenmalig 1 DigitalCodeLock ingepland, met een batterij als het slot die accepteert. Geen pincode ingesteld.'
    Write-Host 'Start met 02, log met het opgegeven Steam-account in en houd ruimte in je inventaris. 03 toont de status.'
    Write-Host 'Na ontvangst normaal afsluiten om de huidige wereld te bewaren. Bij een onderbreking geen automatische extra levering.'
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
