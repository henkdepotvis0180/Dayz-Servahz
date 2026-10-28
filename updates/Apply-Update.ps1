#requires -Version 5.1
[CmdletBinding()]
param([string]$PackagePath)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifest = @'
__MANIFEST__
'@ | ConvertFrom-Json
$payloadText = '__PAYLOAD__'
$payloadHash = '__PAYLOAD_SHA256__'
$stage = $null
try {
    if (!$PackagePath) {
        $candidate = Split-Path $env:SERVAHZ_UPDATE_FILE -Parent
        if (Test-Path -LiteralPath (Join-Path $candidate '01-Instellen.cmd')) {
            $PackagePath = $candidate
        } else {
            $PackagePath = Read-Host 'Pad naar je bestaande basispakket (map met 01-Instellen.cmd)'
        }
    }
    $root = [IO.Path]::GetFullPath($PackagePath.Trim('"'))
    if (!(Test-Path -LiteralPath (Join-Path $root 'config/server.local.json'))) {
        throw "Installeer eerst basispakket $($manifest.base) en voer 01-Instellen.cmd uit. Kies de pakketmap, niet de DayZServer-map."
    }
    Import-Module (Join-Path $root 'scripts/Servahz.psm1') -Force
    Assert-ServerStopped
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    if (!(Test-Path -LiteralPath $layout.Marker) -or !(Test-Path -LiteralPath (Join-Path $layout.Mission '.servahz-managed'))) {
        throw 'Dit basispakket is nog niet ingesteld. Voer eerst 01-Instellen.cmd uit.'
    }
    # Exact published file states prevent accidental downgrades, conflicts and
    # replacing user edits. Private settings and live profiles are never inputs.
    $known = $false
    $installed = ''
    foreach ($state in $manifest.states) {
        $matches = $true
        foreach ($property in $state.files.PSObject.Properties) {
            $path = Join-Path $root $property.Name
            if (!(Test-Path -LiteralPath $path -PathType Leaf) -or
                (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $property.Value) {
                $matches = $false; break
            }
        }
        if ($matches) {
            foreach ($property in $manifest.files.PSObject.Properties) {
                if ($state.files.PSObject.Properties.Name -notcontains $property.Name) {
                    $path = Join-Path $root $property.Name
                    if ((Test-Path -LiteralPath $path) -and (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $property.Value) {
                        $matches = $false; break
                    }
                }
            }
        }
        if ($matches) { $known = $true; $installed = $state.version; break }
    }
    $versionPath = Join-Path $root '.local/package-version.txt'
    if (Test-Path -LiteralPath $versionPath) {
        $recorded = (Get-Content -LiteralPath $versionPath -Raw).Trim()
        if ([version]$recorded.TrimStart('v') -gt [version]$manifest.version.TrimStart('v')) {
            throw 'Een nieuwere update is al geinstalleerd. Terugzetten is geblokkeerd.'
        }
    }
    if (!$known) { throw "Geen ongewijzigd ondersteund basispakket gevonden (vanaf $($manifest.base)). Eigen pakketwijzigingen worden niet overschreven. Bewaar die apart of gebruik een schone basis met je bestaande server.local.json." }
    if ($installed -eq $manifest.version -and (Test-Path -LiteralPath $versionPath) -and $recorded -eq $manifest.version) { Write-Host "Update $installed is al toegepast."; exit 0 }
    $stage = Join-Path ([IO.Path]::GetTempPath()) ('servahz-update-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $stage | Out-Null
    $zipPath = Join-Path $stage 'payload.zip'
    [IO.File]::WriteAllBytes($zipPath, [Convert]::FromBase64String($payloadText))
    if ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -ne $payloadHash) { throw 'Het updatescript is beschadigd.' }
    $unpacked = Join-Path $stage 'files'
    Expand-Archive -LiteralPath $zipPath -DestinationPath $unpacked
    foreach ($property in $manifest.files.PSObject.Properties) {
        $path = Join-Path $unpacked $property.Name
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $property.Value) { throw "Beschadigd updatebestand: $($property.Name)" }
    }
    # Check new Workshop requirements before any backup or package replacement.
    $modPath = Join-Path $unpacked 'config/mods.json'
    if (!(Test-Path -LiteralPath $modPath)) { $modPath = Join-Path $root 'config/mods.json' }
    $mods = Get-Content -LiteralPath $modPath -Raw | ConvertFrom-Json
    foreach ($mod in $mods) {
        $source = Join-Path $settings.WorkshopPath $mod.Id
        if (@(Get-ChildItem -LiteralPath (Join-Path $source 'Addons') -Filter '*.pbo' -ErrorAction SilentlyContinue).Count -eq 0 -or
            @(Get-ChildItem -LiteralPath $source -Recurse -Filter '*.bikey' -ErrorAction SilentlyContinue).Count -eq 0) {
            throw "Download eerst $($mod.Name) via Steam: https://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.Id). Wacht tot Steam klaar is en start dit script opnieuw."
        }
    }
    $backup = Join-Path $root ('.local/Backups/update-' + $manifest.version + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    $engine = (Get-Process -Id $PID).Path
    & $engine -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/Backup-World.ps1') -Destination (Join-Path $backup 'world')
    if ($LASTEXITCODE -ne 0) { throw 'Wereldbackup mislukt. Er is niets bijgewerkt.' }
    foreach ($property in $manifest.files.PSObject.Properties) {
        $original = Join-Path $root $property.Name
        if (Test-Path -LiteralPath $original) {
            $saved = Join-Path (Join-Path $backup 'package') $property.Name
            New-Item -ItemType Directory -Path (Split-Path $saved -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $original -Destination $saved
        }
    }
    foreach ($property in $manifest.files.PSObject.Properties) {
        $destination = Join-Path $root $property.Name
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $unpacked $property.Name) -Destination $destination -Force
    }
    & $engine -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/Install-Server.ps1')
    if ($LASTEXITCODE -ne 0) {
        throw "Instellen mislukt. Je backup staat in $backup. Los de fout op en voer 01-Instellen.cmd opnieuw uit; herstel indien nodig de backup."
    }
    & $engine -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/Test-Server.ps1') -StaticOnly
    if ($LASTEXITCODE -ne 0) { throw "Controle mislukt. Bekijk de melding en de backup in $backup." }
    [IO.File]::WriteAllText($versionPath, $manifest.version)
    Write-Host "Update $($manifest.version) klaar. Backup: $backup"
    Write-Host 'Importeer de bijgewerkte Mods.html in de launcher (ook bij vrienden). Start de server met 02-Start-server.cmd.'
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
} finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) { Remove-Item -LiteralPath $stage -Recurse -Force }
}
