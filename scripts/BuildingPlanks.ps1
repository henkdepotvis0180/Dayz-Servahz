# Bundled client/server config addon. Workshop copies remain untouched.
function Get-PlanksAddonSource {
    Join-Path $script:PackageRoot 'config/local-mods/@ServahzPlanks'
}

function Assert-PlanksAddon {
    param([string]$Path = (Get-PlanksAddonSource))
    $manifest = Get-Content -LiteralPath (Join-Path (Get-PlanksAddonSource) 'files.json') -Raw | ConvertFrom-Json
    foreach ($name in @('Addons/servahz_planks.pbo', 'Addons/servahz_planks.pbo.ServahzPlanks01814.bisign', 'Keys/ServahzPlanks01814.bikey')) {
        $expected = $manifest.PSObject.Properties[$name]
        $file = Join-Path $Path $name
        if ($null -eq $expected -or !(Test-Path -LiteralPath $file -PathType Leaf) -or
            (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $expected.Value) {
            throw 'Servahz Planken-aanvulling ontbreekt of wijkt af. Voer de volledige laatste updater opnieuw uit; wijzig geen Workshop-PBOs.'
        }
    }
}

function Install-PlanksAddon {
    param($Layout)
    $source = Get-PlanksAddonSource
    $target = Join-Path $Layout.Runtime 'Mods/@ServahzPlanks'
    $stage = $target + '.staging'
    if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
    Copy-Item -LiteralPath $source -Destination $stage -Recurse
    Assert-PlanksAddon $stage
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    Move-Item -LiteralPath $stage -Destination $target
    Copy-Item -LiteralPath (Join-Path $target 'Keys/ServahzPlanks01814.bikey') -Destination (Join-Path $Layout.Server 'keys') -Force
}
