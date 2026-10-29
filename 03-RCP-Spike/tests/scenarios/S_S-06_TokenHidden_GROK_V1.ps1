# GROK_V1 - S-06 Token not visible to the extension. Gate -. Pass (spec): confirmed in logs.
# Precheck: no Wims activity/submission contract exists in the product yet (searched below); the scenario stays NOT RUN.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_S-06'; Write-ScenarioHeader 'S-06' 'Token not visible to the extension' '-' 'both (desktop first)'
$hits = @(Get-ChildItem (Join-Path $script:SpikeDir 'host/src'), (Join-Path $script:SpikeDir 'engines') -Recurse -Filter *.java -ErrorAction SilentlyContinue | Select-String -Pattern '(?i)wims(Submission|Activity|Schema|Client)|idempotency' -List)
Test-Ok 'S-06-00-precheck-wims-contract-absent' ($hits.Count -eq 0) "Wims submission/activity code found in product sources: $($hits.Count) (a non-zero count means this script must be extended)" 'P2'
Skip-Blocked 'S-06-01' 'no Wims activity/submission contract, client or test server yet (section 4 contracts not written); no token handling exists' 'P0'
Complete-TestSuite
