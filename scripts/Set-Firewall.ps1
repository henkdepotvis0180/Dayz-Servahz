#requires -Version 5.1
#requires -RunAsAdministrator
[CmdletBinding()]
param([ValidateSet('LAN', 'Friends')][string]$Mode = 'LAN', [switch]$Remove)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
$settings = Read-ServerSettings
$layout = Get-ServerLayout $settings
$ruleName = 'DayZ-Servahz-UDP'
if ($Remove) {
    Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    Write-Host 'Servahz-firewallregel verwijderd.'
    exit 0
}
if ($Mode -eq 'Friends' -and [string]::IsNullOrWhiteSpace($settings.ServerPassword)) {
    throw 'Stel eerst ServerPassword in en voer 01-Instellen.cmd opnieuw uit.'
}
if ($Mode -eq 'Friends') {
    $expected = 'password = "' + $settings.ServerPassword + '";'
    if (!(Test-Path -LiteralPath $layout.Config) -or !(Get-Content -LiteralPath $layout.Config | Where-Object { $_ -ceq $expected })) {
        throw 'Het serverwachtwoord is nog niet toegepast. Voer 01-Instellen.cmd opnieuw uit voordat je de firewall opent.'
    }
}
$scope = 'LocalSubnet'
if ($Mode -eq 'Friends') { $scope = 'Any' }
Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name $ruleName -DisplayName 'DayZ Servahz UDP' -Direction Inbound -Action Allow -Protocol UDP `
    -LocalPort @("$($settings.GamePort)-$($settings.GamePort + 3)", [string]$settings.QueryPort) `
    -Program (Join-Path $layout.Server 'DayZServer_x64.exe') -Profile Private -RemoteAddress $scope | Out-Null
Write-Host "Firewallregel ingesteld: $Mode, alleen op het particuliere netwerkprofiel. Routerinstellingen veranderen niet."
