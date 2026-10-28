#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force

function Format-DiagnosticNumber {
    param($Object, [string]$Name)
    if ($null -eq $Object -or $Object.PSObject.Properties.Name -notcontains $Name) { return 'ontbreekt' }
    $value = $Object.$Name
    if ($value -isnot [ValueType]) { return 'ongeldig' }
    $number = [double]$value
    if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) { return 'ongeldig' }
    return $number.ToString([Globalization.CultureInfo]::InvariantCulture)
}

function Get-DiagnosticPboMap {
    param([string]$Path)
    $map = @{}
    if (Test-Path -LiteralPath $Path -PathType Container) {
        foreach ($file in (Get-ChildItem -LiteralPath $Path -Recurse -File -Filter '*.pbo')) {
            $relative = $file.FullName.Substring($Path.TrimEnd('\', '/').Length + 1).Replace('\', '/')
            $map[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return $map
}

try {
    $root = Split-Path $PSScriptRoot -Parent
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    if (!(Test-Path -LiteralPath $layout.Marker)) { throw 'Geen beheerde installatie.' }
    $report = New-Object 'System.Collections.Generic.List[string]'
    $report.Add('Servahz bouwdiagnose 0.18.1')
    $report.Add('Alleen lezen: geen herstelactie, installatie, serverherstart of wijziging aan wereld/profielen.')
    $report.Add('Tijd UTC: ' + [DateTime]::UtcNow.ToString('s'))
    $version = (Get-Item -LiteralPath (Join-Path $layout.Server 'DayZServer_x64.exe')).VersionInfo.FileVersion
    $match = [regex]::Match([string]$version, '\b\d+\.\d+\.\d+(?:\.\d+)?\b')
    if ($match.Success) { $report.Add('DayZ Server-bestandsversie: ' + $match.Value) }
    else { $report.Add('DayZ Server-bestandsversie: niet beschikbaar') }

    foreach ($mod in (Get-ModManifest | Where-Object { $_.Id -in @('3556131153', '3157695626') })) {
        try {
            $download = Get-DiagnosticPboMap (Join-Path $settings.WorkshopPath ($mod.Id + '/Addons'))
            $installed = Get-DiagnosticPboMap (Join-Path $layout.Runtime ('Mods/' + $mod.Folder + '/Addons'))
            $names = @(@($download.Keys) + @($installed.Keys) | Sort-Object -Unique)
            $different = @($names | Where-Object { !$download.ContainsKey($_) -or !$installed.ContainsKey($_) -or $download[$_] -ne $installed[$_] })
            if ($download.Count -eq 0 -or $installed.Count -eq 0) { $status = 'ONVOLLEDIG' }
            elseif ($different.Count -gt 0) { $status = 'WIJKT AF' }
            else { $status = 'GELIJK aan lokale Workshop-download' }
            $report.Add("$($mod.Name): $status; server=$($installed.Count), Workshop=$($download.Count), afwijkende PBOs=$($different.Count)")
        } catch { $report.Add("$($mod.Name): PBO-vergelijking kon niet worden uitgevoerd") }
    }
    $report.Add('GELIJK bevestigt geen actuele Steam-versie en geen overeenkomst met de mods van spelers.')

    try {
        $rag = Get-Content -LiteralPath (Join-Path $layout.Profiles 'RaG_Core/Configs/RaG_BaseBuilding/RaG_BaseBuilding.json') -Raw | ConvertFrom-Json
        foreach ($name in @('Version', 'BaseInfiniteLifetime', 'DisableAllDamage', 'DisableDismantle', 'EnableBookKitCrafting', 'PlanksPerKitCraft', 'NailsPerKitCraft')) {
            $report.Add('RaG ' + $name + '=' + (Format-DiagnosticNumber $rag $name))
        }
        foreach ($part in @('DoorFrame', 'Door', 'SingleDoorFrame', 'SingleDoor', 'MetalDoor')) {
            $stage = @($rag.PartCosts | Where-Object { $_.Part -eq $part })
            if ($stage.Count -ne 1) { $report.Add("RaG $part : ontbrekende of dubbele bouwstap"); continue }
            $costs = @('PLANKS', 'NAILS', 'LOGS', 'METALSHEETS') | ForEach-Object { $_ + '=' + (Format-DiagnosticNumber $stage[0] $_) }
            $report.Add("RaG $part : " + ($costs -join ', '))
        }
    } catch { $report.Add('RaG-profiel: ontbreekt of kan niet veilig worden gelezen') }
    $report.Add('BaseInfiniteLifetime=1 betekent volgens RaG 45 dagen na opslag laden; dit bewijst geen oorzaak of herstel.')

    $storage = Join-Path $layout.Mission 'storage_1'
    if (Test-Path -LiteralPath $storage -PathType Container) {
        $files = @(Get-ChildItem -LiteralPath $storage -Recurse -File)
        $latest = $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        $report.Add('Wereldopslag aanwezig; bestanden=' + $files.Count)
        if ($null -ne $latest) { $report.Add('Laatste wereldschrijftijd UTC: ' + $latest.LastWriteTimeUtc.ToString('s')) }
    } else { $report.Add('Wereldopslag storage_1: niet gevonden') }
    $report.Add('Wereldbestanden zijn niet ontleed: deze controle kan geen deur of hangslot lokaliseren.')
    $backupRoot = Join-Path $root '.local/Backups'
    $backupCount = 0
    if (Test-Path -LiteralPath $backupRoot) {
        foreach ($directory in (Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object LastWriteTimeUtc -Descending)) {
            $hasWorld = (Test-Path -LiteralPath (Join-Path $directory.FullName 'world/mission/storage_1')) -or (Test-Path -LiteralPath (Join-Path $directory.FullName 'mission/storage_1'))
            if ($hasWorld) {
                $backupCount++
                $report.Add('Wereldbackup #' + $backupCount + ': mapdatum UTC=' + $directory.LastWriteTimeUtc.ToString('s'))
                if ($backupCount -ge 5) { break }
            }
        }
    }
    if ($backupCount -eq 0) { $report.Add('Geen wereldbackup met storage_1 gevonden in de pakket-backupmap.') }
    $report.Add('Een aanwezige backup is niet gecontroleerd op inhoud of herstelbaarheid; er wordt niets teruggezet.')

    # Never echo log lines. Emit only fixed categories, times and public code/class tokens.
    $codePattern = '\b(?:RaG_BB_[A-Za-z0-9_]+|CombinationLock4?|Action[A-Za-z0-9_]*CombinationLock[A-Za-z0-9_]*|UnlockOnServer|UnlockServer|SetNextDial|DialNextNumber|GetDialIndex(?:Inside)?|GetLockSideByComponentIndex|GetCombinationLockSide|SetCombinationLockSide|OnStoreLoad|OnStoreSave)\b'
    $signalCount = 0
    try {
        $logs = @(Get-ChildItem -LiteralPath $layout.Profiles -Recurse -File | Where-Object { $_.Extension -in @('.RPT', '.log', '.ADM') } | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 8)
        $logIndex = 0
        foreach ($log in $logs) {
            $logIndex++
            $lines = @(Get-Content -LiteralPath $log.FullName -Tail 2000)
            for ($index = 0; $index -lt $lines.Count; $index++) {
                $line = $lines[$index]
                $kind = ''
                if ($line -match '(?i)NULL pointer|NULL instance') { $kind = 'NULL-pointer' }
                elseif ($line -match '(?i)Undefined function') { $kind = 'onbekende functie' }
                elseif ($line -match '(?i)SCRIPT\s*\(E\)|ErrorMessage|Exception|\bERROR\b') { $kind = 'scriptfout' }
                elseif ($line -match '(?i)dismantl|destroyed|deleted|removed') { $kind = 'afbraak/verwijderingsmelding' }
                elseif ($line -match '(?i)built|placed') { $kind = 'bouwmelding' }
                if (!$kind) { continue }
                $context = $line
                if ($kind -in @('NULL-pointer', 'onbekende functie', 'scriptfout')) {
                    $end = [Math]::Min($index + 10, $lines.Count - 1)
                    $context = $lines[$index..$end] -join ' '
                }
                $tokens = @([regex]::Matches($context, $codePattern) | ForEach-Object { $_.Value } | Sort-Object -Unique | Select-Object -First 12)
                if ($tokens.Count -eq 0) { continue }
                $time = [regex]::Match($line, '\b\d{1,2}:\d{2}:\d{2}\b').Value
                $report.Add("Log #$logIndex $time | $kind | " + ($tokens -join ', '))
                $signalCount++
                if ($signalCount -ge 30) { break }
            }
            if ($signalCount -ge 30) { break }
        }
    } catch { $report.Add('Een of meer logbestanden konden niet worden gelezen.') }
    if ($signalCount -eq 0) { $report.Add('Geen herkende bouw-/slotfoutsignalen in de onderzochte logstaarten; dit sluit een fout niet uit.') }
    $report.Add('Logsignalen bewijzen geen verwijdering van jouw deur. Alleen geanonimiseerde samenvattingen, geen volledige logregels.')
    $path = Join-Path $root ('.local/BuildDiagnostics/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.txt')
    $text = $report -join [Environment]::NewLine
    Write-Utf8File $path $text
    Write-Host $text
    Write-Host "Deel alleen dit diagnoserapport: $path"
} catch {
    Write-Error 'Bouwdiagnose gestopt: controleer of 01-Instellen eerder is uitgevoerd en de lokale serverpaden bereikbaar zijn. Er is geen wereld of profiel gewijzigd.' -ErrorAction Continue
    exit 1
}
