. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
$script:ArtifactSuffix = 'CODEX_V1'
Initialize-TestSuite '22_WimsClient'
$runner = Join-Path $script:SpikeDir 'host/test-wims-client.ps1'
if (-not (Test-Path -LiteralPath $runner)) {
    Test-Ok 'W2-unit-runner-exists' $false $runner 'P0'
    Complete-TestSuite
}
$out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Mode unit 2>&1 | Out-String
$rc = $LASTEXITCODE
foreach ($line in ($out -split "`r?`n")) {
    if ($line -match '^ok \d+ - (.+)$') { Test-Ok "W7-unit-$($Matches[1])" $true $Matches[1] 'P0' }
    elseif ($line -match '^not ok \d+ - (.+)$') { Test-Ok "W7-unit-$($Matches[1])" $false $Matches[1] 'P0' }
}
Test-Ok 'W2-unit-process-exit' ($rc -eq 0) "test-wims-client.ps1 exit=$rc" 'P0'
Test-Ok 'W2-unit-summary' ($out -match '# WIMS client tests: \d+ PASS, 0 FAIL') 'unit/mock contract suite completed' 'P0'
Complete-TestSuite
