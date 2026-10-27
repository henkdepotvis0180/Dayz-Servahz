#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
try {
    Assert-ServerStopped
    $settings = Read-ServerSettings
    $layout = Get-ServerLayout $settings
    & (Join-Path $PSScriptRoot 'Test-Server.ps1') -StaticOnly
    if ($LASTEXITCODE -ne 0) { throw 'Configuratiecontrole mislukt.' }
    $arguments = Get-LaunchArguments $settings $layout
    Write-Host "Server starten. Lokaal verbinden: 127.0.0.1:$($settings.GamePort)"
    Write-Host 'Stop in-game met #login (je AdminPassword) en daarna #shutdown. Wacht tot het serverproces afsluit.'
    $process = Start-Process -FilePath (Join-Path $layout.Server 'DayZServer_x64.exe') -WorkingDirectory $layout.Server -ArgumentList $arguments -PassThru
    # Do not promise readiness from a PID: the separate checker queries A2S_INFO.
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "DayZ stopte met exitcode $($process.ExitCode). Bekijk Servahz/Profiles/*.RPT en crash*.log." }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
