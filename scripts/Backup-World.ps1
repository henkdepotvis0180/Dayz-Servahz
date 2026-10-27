#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Servahz.psm1') -Force
Assert-ServerStopped
$settings = Read-ServerSettings
$layout = Get-ServerLayout $settings
$dest = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $dest) { throw 'Kies een nieuwe, nog niet bestaande backupmap.' }
foreach ($source in @($layout.Mission, $layout.Runtime)) {
    if ($dest.StartsWith($source.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'De backupmap moet buiten de missie en de Servahz-runtime staan.'
    }
}
New-Item -ItemType Directory -Path $dest | Out-Null
Copy-Item -LiteralPath $layout.Mission -Destination (Join-Path $dest 'mission') -Recurse
Copy-Item -LiteralPath $layout.Profiles -Destination (Join-Path $dest 'Profiles') -Recurse
Copy-Item -LiteralPath $layout.Config -Destination $dest
Copy-Item -LiteralPath (Join-Path (Split-Path $PSScriptRoot -Parent) 'config/server.local.json') -Destination $dest
Write-Host "Wereld, spelers, profielen en configuratie opgeslagen in $dest. Backup bevat je lokale wachtwoorden; houd hem prive."
