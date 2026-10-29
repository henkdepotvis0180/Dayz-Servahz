@echo off
setlocal
set "SERVAHZ_STORAGE_FILE=%~f0"
set "SERVAHZ_STORAGE_ROOT=%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$lines=[IO.File]::ReadAllLines($env:SERVAHZ_STORAGE_FILE); $i=[Array]::IndexOf($lines,'# SERVAHZ_STORAGE_POWERSHELL'); & ([scriptblock]::Create(($lines[($i+1)..($lines.Length-1)] -join [Environment]::NewLine))) -PackageRoot $env:SERVAHZ_STORAGE_ROOT"
set "SERVAHZ_STORAGE_EXIT=%ERRORLEVEL%"
pause
exit /b %SERVAHZ_STORAGE_EXIT%
# SERVAHZ_STORAGE_POWERSHELL
param([string]$PackageRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LocalAbsolutePath {
    param([string]$Value)
    # Relative process arguments depend on a working directory that CIM does not expose.
    # Do not guess it, follow UNC paths, or echo a private path on failure.
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '^(\\\\|//)' -or ![IO.Path]::IsPathRooted($Value)) { return $null }
    try { return [IO.Path]::GetFullPath($Value).TrimEnd('\', '/') } catch { return $null }
}

function Compare-DiagnosticPath {
    param([string]$Value, [string]$Expected)
    $actual = Get-LocalAbsolutePath $Value
    if (!$actual) { return 'ONBEKEND (relatief, ontbrekend of niet lokaal)' }
    if ([string]::Equals($actual, (Get-LocalAbsolutePath $Expected), [StringComparison]::OrdinalIgnoreCase)) { return 'GELIJK' }
    return 'ANDERS'
}

function Select-UniqueDiagnosticPath {
    param([string[]]$Paths)
    # Windows paths differing only in letter case still identify one installation.
    $seen = @{}
    foreach ($item in $Paths) {
        $path = Get-LocalAbsolutePath $item
        if ($path -and !$seen.ContainsKey($path)) { $seen[$path] = $true; Write-Output $path }
    }
}

function Get-StorageSignalDetail {
    param([string]$Line)
    # Only emit fixed public labels, never fragments of the original message.
    $labels = New-Object 'System.Collections.Generic.List[string]'
    $words = [ordered]@{
        corrupt = '\bcorrupt\w*'; recover = '\brecover\w*'; repair = '\brepair\w*'
        restore = '\brestor\w*'; backup = '\bbackup\w*'; error = '\berror\w*'
        fail = '\bfail\w*'; invalid = '\binvalid\b'; denied = '\bdenied\b'
        empty = '\bempty\b'; delete = '\bdelet\w*'; save = '\bsav(?:e|ed|ing)\b'
        load = '\bload\w*'; warning = '\bwarn\w*'
    }
    foreach ($key in $words.Keys) {
        if ($Line -match ('(?i)' + $words[$key])) { $labels.Add($key) }
    }
    foreach ($tag in @('CE', 'Storage', 'Hive', 'StorageDirs')) {
        if ($Line -match ('(?i)\[' + $tag + '\]')) { $labels.Add('engine:' + $tag) }
    }
    $valid = [regex]::Match($Line, '(?i)\bvalid:\s*(yes|no)\b')
    if ($valid.Success) { $labels.Add('valid:' + $valid.Groups[1].Value.ToLowerInvariant()) }
    # Canonical CE filenames only; no arbitrary filenames, paths or class names.
    $files = [regex]::Matches($Line, '(?i)(?<![\w])(?:dynamic(?:_\d{1,3})?|building|vehicles|types|events|players)\.(?:bin|db|\d{3})(?![\w.])')
    foreach ($file in @($files | ForEach-Object { $_.Value.ToLowerInvariant() } | Sort-Object -Unique | Select-Object -First 4)) { $labels.Add('bestand:' + $file) }
    return $labels -join ','
}

function Read-LaunchSelection {
    param([string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine) -or ([regex]::Matches($CommandLine, '"').Count % 2) -ne 0) { return $null }
    $selection = @{}
    # Handles both "-config=C:\folder with spaces\server.cfg" and -config="C:\folder with spaces\server.cfg".
    foreach ($token in [regex]::Matches($CommandLine, '(?:[^\s"]+|"[^"]*")+')) {
        $value = $token.Value.Replace('"', '')
        if ($value -match '^-(config|profiles|mission|storage|port)=(.*)$') {
            $name = $Matches[1].ToLowerInvariant()
            if (!$selection.ContainsKey($name)) { $selection[$name] = @() }
            $selection[$name] += [string]$Matches[2]
        }
    }
    return $selection
}

function Add-ConfigSummary {
    param([string]$Path, [string]$Label, $Report)
    try {
        $text = [IO.File]::ReadAllText($Path)
        # Text inspection only, never evaluate a server configuration.
        $text = [regex]::Replace($text, '/\*[\s\S]*?\*/', '')
        foreach ($field in @('instanceId', 'storageAutoFix')) {
            $found = [regex]::Matches($text, '(?mi)^\s*' + $field + '\s*=\s*([0-9]{1,9})\s*;')
            $value = 'ontbreekt of niet eenduidig leesbaar'
            if ($found.Count -eq 1) { $value = $found[0].Groups[1].Value }
            $Report.Add($Label + ' ' + $field + '=' + $value)
        }
        $templates = [regex]::Matches($text, '(?mi)^\s*template\s*=\s*"([^"\r\n]*)"\s*;')
        $status = 'ONBEKEND'
        if ($templates.Count -eq 1) {
            $status = 'ANDERS'
            if ($templates[0].Groups[1].Value -eq 'servahz.chernarusplus') { $status = 'GELIJK' }
        }
        $Report.Add($Label + ' missie t.o.v. pakket=' + $status)
        $Report.Add($Label + ' bestand gewijzigd UTC=' + (Get-Item -LiteralPath $Path).LastWriteTimeUtc.ToString('s'))
    } catch { $Report.Add($Label + ' kon niet veilig worden gelezen') }
}

function Add-StorageSummary {
    param([string]$Path, [string]$Label, $Report)
    try {
        if (!(Test-Path -LiteralPath $Path -PathType Container)) { $Report.Add($Label + ': ontbreekt'); return }
        $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction Stop)
        $Report.Add($Label + ': bestanden=' + $files.Count)
        $latest = $files | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($null -ne $latest) { $Report.Add($Label + ': nieuwste bestand UTC=' + $latest.LastWriteTimeUtc.ToString('s')) }
    } catch { $Report.Add($Label + ': niet volledig leesbaar') }
}

function Read-DiagnosticXml {
    param([string]$Path)
    $options = New-Object Xml.XmlReaderSettings
    $options.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $options.XmlResolver = $null
    $reader = [Xml.XmlReader]::Create($Path, $options)
    try {
        $document = New-Object Xml.XmlDocument
        $document.XmlResolver = $null
        $document.Load($reader)
        return ,$document
    } finally { $reader.Dispose() }
}

function Add-MissionSummary {
    param([string]$Path, [string]$Label, $Report)
    try {
        $core = Read-DiagnosticXml (Join-Path $Path 'cfgeconomycore.xml')
        $links = $core.SelectNodes('/economycore/ce[@folder="servahz_ce"]/file[@name="building_types.xml" and @type="types"]')
        $Report.Add($Label + ': koppelingen naar servahz_ce/building_types.xml=' + $links.Count)
        foreach ($rootClass in @('Inventory_Base', 'HouseNoDestruct')) {
            $Report.Add($Label + ': CE-root ' + $rootClass + '=' + $core.SelectNodes('/economycore/classes/rootclass[@name="' + $rootClass + '"]').Count)
        }
    } catch { $Report.Add($Label + ': cfgeconomycore.xml ontbreekt of ongeldig') }
    foreach ($relative in @('db/types.xml', 'servahz_ce/building_types.xml')) {
        try {
            $types = Read-DiagnosticXml (Join-Path $Path $relative)
            if ($null -eq $types.SelectSingleNode('/types')) { throw 'Verkeerde XML-root' }
            $Report.Add($Label + ': ' + $relative + ' XML leesbaar')
            foreach ($class in @('RaG_BB_DoorKit', 'RaG_BB_Low_WallKit', 'RaG_BB_Book')) {
                $entries = $types.SelectNodes('/types/type[@name="' + $class + '"]')
                if ($entries.Count -eq 0) { continue }
                $value = 'niet eenduidig of ongeldig'
                if ($entries.Count -eq 1) {
                    $lifetime = $entries[0].SelectSingleNode('lifetime')
                    if ($null -ne $lifetime -and $lifetime.InnerText -match '^\d{1,10}$') { $value = $lifetime.InnerText }
                }
                $Report.Add($Label + ': ' + $relative + ' ' + $class + ' aantal=' + $entries.Count + ' lifetime=' + $value)
            }
        } catch { $Report.Add($Label + ': ' + $relative + ' ontbreekt of ongeldig') }
    }
    try {
        $ignore = Read-DiagnosticXml (Join-Path $Path 'cfgIgnoreList.xml')
        if ($null -eq $ignore.SelectSingleNode('/ignore')) { throw 'Verkeerde XML-root' }
        $cheatChecks = @($ignore.SelectNodes('/ignore/type') | Where-Object { $_.GetAttribute('cheatCheck') -match '^(1|true)$' })
        $buildingEntries = @($ignore.SelectNodes('/ignore/type') | Where-Object { $_.GetAttribute('name') -match '^(RaG_BB_|Expansion(Wall|Floor|Ramp|Stair|WoodPillar)|Fence$|Watchtower$|BaseBuildingBase$|HouseNoDestruct$|Inventory_Base$)' })
        $Report.Add($Label + ': ignorelijst actieve cheatCheck-regels=' + $cheatChecks.Count + '; bouwgerelateerde regels=' + $buildingEntries.Count)
    } catch { $Report.Add($Label + ': cfgIgnoreList.xml ontbreekt of ongeldig') }
    try {
        $economy = Read-DiagnosticXml (Join-Path $Path 'db/economy.xml')
        foreach ($kind in @('building', 'dynamic', 'vehicles')) {
            $entries = $economy.SelectNodes('/economy/' + $kind)
            foreach ($field in @('load', 'save')) {
                $value = 'ontbreekt of ongeldig'
                if ($entries.Count -eq 1 -and $entries[0].GetAttribute($field) -match '^[01]$') { $value = $entries[0].GetAttribute($field) }
                $Report.Add($Label + ': db/economy.xml ' + $kind + ' ' + $field + '=' + $value)
            }
        }
    } catch { $Report.Add($Label + ': db/economy.xml ontbreekt of ongeldig') }
}

try {
    $PackageRoot = [IO.Path]::GetFullPath($PackageRoot)
    $settings = Get-Content -LiteralPath (Join-Path $PackageRoot 'config/server.local.json') -Raw | ConvertFrom-Json
    $serverRoot = Get-LocalAbsolutePath ([string]$settings.ServerPath)
    if (!$serverRoot -or !(Test-Path -LiteralPath (Join-Path $serverRoot 'Servahz/.servahz-managed'))) { throw 'Geen beheerde installatie' }
    $expectedConfig = Join-Path $serverRoot 'Servahz/serverDZ.cfg'
    $expectedProfiles = Join-Path $serverRoot 'Servahz/Profiles'
    $report = New-Object 'System.Collections.Generic.List[string]'
    $report.Add('Servahz opslagdiagnose 0.18.3')
    $report.Add('Alleen lezen: geen serverstop/start, schrijftest, instelling, herstel of wijziging van saves.')
    $report.Add('Tijd UTC: ' + [DateTime]::UtcNow.ToString('s'))
    $report.Add('Paden, startopdrachten, wachtwoorden en volledige logregels worden niet opgenomen.')
    Add-ConfigSummary $expectedConfig 'Pakketconfig' $report
    $serverRoots = @($serverRoot)
    $profileRoots = @($expectedProfiles)
    $storageRoots = @()
    try {
        $processes = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='DayZServer_x64.exe'" -ErrorAction Stop)
        $report.Add('Draaiende DayZ-serverprocessen=' + $processes.Count)
        if ($processes.Count -eq 0) { $report.Add('Geen actief proces: voer deze controle uit terwijl de bestaande server draait.') }
        if ($processes.Count -gt 1) { $report.Add('Meerdere processen: niet automatisch vast te stellen op welke wereld de speler zit.') }
        $processIndex = 0
        foreach ($process in ($processes | Select-Object -First 4)) {
            $processIndex++
            $label = "Proces #$processIndex"
            $report.Add($label + ' executable t.o.v. pakket=' + (Compare-DiagnosticPath $process.ExecutablePath (Join-Path $serverRoot 'DayZServer_x64.exe')))
            $exe = Get-LocalAbsolutePath $process.ExecutablePath
            if ($exe) { $serverRoots += Split-Path $exe -Parent }
            if ($process.CreationDate -is [DateTime]) { $report.Add($label + ' gestart UTC=' + $process.CreationDate.ToUniversalTime().ToString('s')) }
            $selection = Read-LaunchSelection $process.CommandLine
            if ($null -eq $selection) { $report.Add($label + ' startselectie niet beschikbaar of niet eenduidig leesbaar'); continue }
            foreach ($name in @('config', 'profiles', 'mission', 'storage', 'port')) {
                if (!$selection.ContainsKey($name)) { $report.Add($label + " -${name}=niet opgegeven"); continue }
                if ($selection[$name].Count -ne 1) { $report.Add($label + " -${name}=DUBBEL; geen selectie afgeleid"); continue }
                $value = [string]$selection[$name][0]
                if ($name -eq 'port') {
                    $status = 'ONBEKEND'
                    if ($value -match '^\d{1,5}$') {
                        $status = 'ANDERS'
                        if ([int]$value -eq $settings.GamePort) { $status = 'GELIJK' }
                    }
                    $report.Add($label + ' poort t.o.v. pakket=' + $status)
                    continue
                }
                $path = Get-LocalAbsolutePath $value
                if ($name -eq 'config' -or $name -eq 'profiles') {
                    $expected = $expectedConfig
                    if ($name -eq 'profiles') { $expected = $expectedProfiles }
                    $report.Add($label + " -${name} t.o.v. pakket=" + (Compare-DiagnosticPath $value $expected))
                    if ($path -and $name -eq 'config') { Add-ConfigSummary $path ($label + ' config') $report }
                    if ($path -and $name -eq 'profiles') { $profileRoots += $path }
                } else {
                    $report.Add($label + " -${name}=AANWEZIG; kan de verwachte wereldopslag wijzigen")
                    if (!$path) { $report.Add($label + " -${name}: relatief of niet lokaal; geen opslagpad gegokt") }
                    elseif ($name -eq 'mission') { $storageRoots += [pscustomobject]@{ Path = $path; Label = $label + ' missie-override'; InspectMission = $true } }
                    else { $storageRoots += [pscustomobject]@{ Path = $path; Label = $label + ' opslag-override'; InspectMission = $false } }
                }
            }
        }
    } catch { $report.Add('Procescontrole niet beschikbaar of onvolledig; geen overeenkomst met de actieve server bevestigd.') }

    $expectedMission = Join-Path $serverRoot 'mpmissions/servahz.chernarusplus'
    Add-StorageSummary (Join-Path $expectedMission 'storage_1') 'Verwachte pakketopslag storage_1' $report
    Add-MissionSummary $expectedMission 'Verwachte pakketmissie' $report
    $rootIndex = 0
    foreach ($installation in @(Select-UniqueDiagnosticPath $serverRoots)) {
        $rootIndex++
        try {
            $missions = @(Get-ChildItem -LiteralPath (Join-Path $installation 'mpmissions') -Directory -ErrorAction Stop | Sort-Object Name | Select-Object -First 32)
            $missionIndex = 0
            foreach ($mission in $missions) {
                $missionIndex++
                $storageRoots += [pscustomobject]@{ Path = $mission.FullName; Label = "Installatie #$rootIndex missie #$missionIndex"; InspectMission = $false }
            }
        } catch { $report.Add("Installatie #${rootIndex}: missiemappen niet volledig leesbaar") }
    }
    foreach ($candidate in $storageRoots) {
        try {
            if ($candidate.InspectMission -and (Compare-DiagnosticPath $candidate.Path $expectedMission) -ne 'GELIJK') {
                Add-MissionSummary $candidate.Path $candidate.Label $report
            }
            $slots = @(Get-ChildItem -LiteralPath $candidate.Path -Directory -Filter 'storage_*' -ErrorAction Stop | Where-Object { $_.Name -match '^storage_\d{1,9}$' } | Sort-Object Name | Select-Object -First 16)
            $report.Add($candidate.Label + ': gevonden opslagmappen=' + $slots.Count)
            foreach ($slot in $slots) { Add-StorageSummary $slot.FullName ($candidate.Label + ' ' + $slot.Name) $report }
        } catch { $report.Add($candidate.Label + ': opslagmappen niet volledig leesbaar') }
    }

    $profileIndex = 0
    foreach ($profileRoot in @(Select-UniqueDiagnosticPath $profileRoots)) {
        $profileIndex++
        try {
            $logs = @(Get-ChildItem -LiteralPath $profileRoot -Recurse -File -ErrorAction Stop | Where-Object { $_.Extension -in @('.RPT', '.log', '.ADM') } | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 8)
            $report.Add("Profiel #${profileIndex}: onderzochte logstaarten=" + $logs.Count)
            if ($logs.Count -gt 0) { $report.Add("Profiel #${profileIndex}: nieuwste log UTC=" + $logs[0].LastWriteTimeUtc.ToString('s')) }
            $signals = 0
            $logIndex = 0
            foreach ($log in $logs) {
                $logIndex++
                foreach ($line in @(Get-Content -LiteralPath $log.FullName -Tail 2000 -ErrorAction Stop)) {
                    if ($line -notmatch '(?i)storage|persisten|hive|save|\.bin\b|\.db\b|\bCE\b|economy|types\.xml|cfgIgnoreList') { continue }
                    if ($line -notmatch '(?i)error|fail|corrupt|denied|cannot|can.t|read.only|repair|recover|restor|invalid') { continue }
                    $category = 'mogelijke opslagfout'
                    if ($line -match '(?i)denied|read.only|cannot.*writ|can.t.*writ') { $category = 'toegang/schrijven' }
                    elseif ($line -match '(?i)corrupt|repair|recover|restor') { $category = 'beschadiging/herstel' }
                    $time = [regex]::Match($line, '\b\d{1,2}:\d{2}:\d{2}\b').Value
                    $report.Add("Profiel #$profileIndex log #$logIndex $time | $category | " + (Get-StorageSignalDetail $line))
                    $signals++
                    if ($signals -ge 20) { break }
                }
                if ($signals -ge 20) { break }
            }
            if ($signals -eq 0) { $report.Add("Profiel #${profileIndex}: geen herkende opslagfoutsignalen; dit sluit een fout niet uit") }
        } catch { $report.Add("Profiel #${profileIndex}: logs niet volledig leesbaar") }
    }
    $report.Add('Mappen en schrijftijden zijn aanwijzingen; geen bewijs dat een map de actieve wereld of een verdwenen bouwdeel bevat.')
    $report.Add('Configuratie is tekstinspectie van de huidige bestanden; die kunnen sinds de serverstart zijn veranderd.')
    $report.Add('Logdetails zijn vaste trefwoorden, geen volledige meldingen; recover/restore alleen bewijst geen beschadiging of verwijdering.')
    $report.Add('Geen schrijftest of controle van rechten onder het serveraccount. Geen automatische herstelactie.')
    $destination = Join-Path $PackageRoot ('.local/StorageDiagnostics/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.txt')
    $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
    $output = $report -join [Environment]::NewLine
    [IO.File]::WriteAllText($destination, $output, (New-Object Text.UTF8Encoding($false)))
    Write-Host $output
    Write-Host "Deel alleen dit rapport: $destination"
} catch {
    Write-Error 'Opslagdiagnose gestopt: zet dit bestand naast 01-Instellen.cmd van de bestaande installatie. Geen wereld of instellingen gewijzigd.' -ErrorAction Continue
    exit 1
}
