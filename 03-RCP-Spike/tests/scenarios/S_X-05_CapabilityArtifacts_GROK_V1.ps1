# GROK_V1 - X-05 Same capability id, two artifacts. Gate D. Pass (spec): desktop jar and web module stay distinct.
# Desktop half: the capability ids are declared in the API and each engine bundle is a separate desktop jar.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-05'; Write-ScenarioHeader 'X-05' 'Same capability id, two artifacts' 'D' 'both'
$api = Join-Path $script:SpikeDir 'engines/api/src/org/geogebra/plus/compute/api'; $src = (Get-ChildItem $api -Filter *.java | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
Test-Ok 'X05-01-capability-type-in-api' ($src -match '(enum|class|record)\s+ComputeCapability') 'ComputeCapability declared in compute.api' 'P1'
$info = Join-Path $script:Image 'configuration/org.eclipse.equinox.simpleconfigurator/bundles.info'
$eng = @(Get-Content $info -ErrorAction SilentlyContinue | Where-Object { $_ -match '^org\.geogebra\.plus\.(engine|compute)' } | ForEach-Object { ($_ -split ',')[0] })
Test-Ok 'X05-02-desktop-artifacts-distinct' ($eng.Count -ge 1 -and ($eng | Select-Object -Unique).Count -eq $eng.Count) "desktop compute bundles: $($eng -join ', ')" 'P1'
Skip-Blocked 'X05-03-web-module-distinct' 'deferred: web phase (no web module exists)' 'P0'
Complete-TestSuite
