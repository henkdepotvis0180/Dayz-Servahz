#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory = $true)][ValidatePattern('^7656119[0-9]{10}$')][string]$SteamId64)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
Assert-ServerStopped
$layout = Get-ServerLayout (Read-ServerSettings)
$path = Join-Path $layout.Profiles 'ExpansionMod/Settings/AISettings.json'
if (!(Test-Path -LiteralPath $path)) {
    throw 'Start de server eerst een keer met alle mods, laat de missie laden en stop normaal. Expansion maakt dan AISettings.json aan.'
}
$settings = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
Copy-Item -LiteralPath $path -Destination ($path + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.bak')
$settings.Admins = @(@($settings.Admins) + $SteamId64 | Select-Object -Unique)
Write-Utf8File $path ($settings | ConvertTo-Json -Depth 30)
Write-Host 'AI-admin toegevoegd. Herstart de server. De AI-menutoets is in DayZ > Options > Controls instelbaar (standaard T).'
