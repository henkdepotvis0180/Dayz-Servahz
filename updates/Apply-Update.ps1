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
    # Recognize each managed file independently. Manual updates can legitimately
    # mix published versions; text encoding/newlines do not change their content.
    $targetState = $manifest.states[-1]
    $documentation = @('README.md', 'CHANGELOG.md', 'AGENTS.md')
    # Read-ServerSettings already validated the mandatory active local settings.
    # This first-install template is unused and may contain private user values.
    $preserve = @('config/server.example.json')
    $conflicts = @()
    $payloadCurrent = $true
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        foreach ($property in $targetState.files.PSObject.Properties) {
            $name = $property.Name
            if ($name -in $preserve) { continue }
            $path = Join-Path $root $name
            $inPayload = $manifest.files.PSObject.Properties.Name -contains $name
            if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
                if (Test-Path -LiteralPath $path) { $conflicts += "Geen bestand: $name"; continue }
                if ($inPayload) { $payloadCurrent = $false }
                elseif ($name -notin $documentation) { $conflicts += "Ontbreekt: $name" }
                continue
            }
            $raw = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            if ($inPayload -and $raw -ne $manifest.files.PSObject.Properties[$name].Value) { $payloadCurrent = $false }
            if ($name -in $documentation) { continue }
            $textHash = ''
            try {
                $encoding = New-Object Text.UTF8Encoding($false, $true)
                $content = $encoding.GetString([IO.File]::ReadAllBytes($path))
                if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }
                $content = $content.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char]10)
                $textHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($content)))).Replace('-', '')
            } catch { } # Unknown/non-text bytes must still match a raw published hash.
            $recognized = $false
            foreach ($state in $manifest.states) {
                $published = $state.files.PSObject.Properties[$name]
                if ($null -ne $published -and $published.Value -eq $raw) { $recognized = $true; break }
                if ($state.PSObject.Properties.Name -contains 'text') {
                    $normalized = $state.text.PSObject.Properties[$name]
                    if ($textHash -and $null -ne $normalized -and $normalized.Value -eq $textHash) { $recognized = $true; break }
                }
            }
            if (!$recognized) { $conflicts += "Onbekende inhoud: $name" }
        }
    } finally { $sha.Dispose() }
    $versionPath = Join-Path $root '.local/package-version.txt'
    $recorded = ''
    if (Test-Path -LiteralPath $versionPath) {
        $recorded = (Get-Content -LiteralPath $versionPath -Raw).Trim()
        if ([version]$recorded.TrimStart('v') -gt [version]$manifest.version.TrimStart('v')) {
            throw 'Een nieuwere update is al geinstalleerd. Terugzetten is geblokkeerd.'
        }
    }
    if ($conflicts.Count -gt 0) {
        $diagnostic = Join-Path $root ('.local/UpdateDiagnostics/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.txt')
        New-Item -ItemType Directory -Path (Split-Path $diagnostic -Parent) -Force | Out-Null
        [IO.File]::WriteAllLines($diagnostic, [string[]]$conflicts, (New-Object Text.UTF8Encoding($false)))
        foreach ($conflict in $conflicts) { Write-Host $conflict }
        throw "Eigen pakketwijzigingen of ontbrekende basisbestanden gevonden. Er is niets vervangen. Alleen bestandsnamen staan in $diagnostic; deel geen server.local.json of wachtwoorden."
    }
    if ($payloadCurrent -and $recorded -eq $manifest.version) { Write-Host "Update $recorded is al toegepast."; exit 0 }
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
        if ($property.Name -in $preserve) { continue }
        $original = Join-Path $root $property.Name
        if (Test-Path -LiteralPath $original) {
            $saved = Join-Path (Join-Path $backup 'package') $property.Name
            New-Item -ItemType Directory -Path (Split-Path $saved -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $original -Destination $saved
        }
    }
    foreach ($property in $manifest.files.PSObject.Properties) {
        if ($property.Name -in $preserve) { continue }
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
