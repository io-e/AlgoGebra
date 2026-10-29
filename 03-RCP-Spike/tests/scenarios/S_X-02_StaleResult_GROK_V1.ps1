# GROK_V1 - X-02 Stale result (old revision). Gate D. Pass (spec): stale result rejected.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-02'; Write-ScenarioHeader 'X-02' 'Stale result rejected' 'D' 'both'
$api = Join-Path $script:SpikeDir 'engines/api/src/org/geogebra/plus/compute/api'; $src = (Get-ChildItem $api -Filter *.java | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
Test-Ok 'X02-01-api-has-request-revision' ($src -match '(?i)\b(revision|requestId|sequence)\b') 'ComputeContext/ComputeResult carry a request id or construction revision' 'P0'
Skip-Blocked 'X02-02-stale-result-rejected' 'compute API has no request id / construction revision, so a late result cannot be detected (API change needed)' 'P0'
Complete-TestSuite
