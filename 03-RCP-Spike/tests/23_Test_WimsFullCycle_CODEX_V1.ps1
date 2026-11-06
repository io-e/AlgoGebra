. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
$script:ArtifactSuffix = 'CODEX_V1'
Initialize-TestSuite '23_WimsFullCycle'
$runner = Join-Path $script:SpikeDir 'host/test-wims-client.ps1'
if (-not (Test-Path -LiteralPath $runner)) {
    Test-Ok 'W1-cycle-runner-exists' $false $runner 'P0'
    Complete-TestSuite
}
$out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -Mode cycle 2>&1 | Out-String
$rc = $LASTEXITCODE
foreach ($line in ($out -split "`r?`n")) {
    if ($line -match '^ok \d+ - (.+)$') { Test-Ok "W7-cycle-$($Matches[1])" $true $Matches[1] 'P0' }
    elseif ($line -match '^not ok \d+ - (.+)$') { Test-Ok "W7-cycle-$($Matches[1])" $false $Matches[1] 'P0' }
}
Test-Ok 'W1-cycle-process-exit' ($rc -eq 0) "test-wims-client.ps1 exit=$rc" 'P0'
Test-Ok 'W1-cycle-summary' ($out -match '# WIMS client tests: \d+ PASS, 0 FAIL') 'fixture-backed WIMS transaction cycle completed' 'P0'
if ($env:GGB_WIMS_LIVE_ENDPOINT) {
    $liveRunner = Join-Path $script:SpikeDir 'host/test-wims-live.ps1'
    $module = if ($env:GGB_WIMS_LIVE_MODULE) { $env:GGB_WIMS_LIVE_MODULE } else { 'H6/test/oef2html.fr' }
    $exercise = if ($env:GGB_WIMS_LIVE_EXERCISE) { $env:GGB_WIMS_LIVE_EXERCISE } else { '00006' }
    $field = if ($env:GGB_WIMS_LIVE_FIELD) { $env:GGB_WIMS_LIVE_FIELD } else { 'reply1' }
    $answer = if ($env:GGB_WIMS_LIVE_ANSWER) { $env:GGB_WIMS_LIVE_ANSWER } else { '2' }
    $expected = if ($env:GGB_WIMS_LIVE_EXPECTED_GRADE) { $env:GGB_WIMS_LIVE_EXPECTED_GRADE } else { '1' }
    $language = if ($env:GGB_WIMS_LIVE_LANGUAGE) { $env:GGB_WIMS_LIVE_LANGUAGE } else { 'fr' }
    $liveOut = & pwsh -NoProfile -ExecutionPolicy Bypass -File $liveRunner `
        -Endpoint $env:GGB_WIMS_LIVE_ENDPOINT -Module $module -Exercise $exercise `
        -Field $field -Answer $answer -ExpectedGrade $expected -Language $language 2>&1 | Out-String
    $liveRc = $LASTEXITCODE
    foreach ($line in ($liveOut -split "`r?`n")) {
        if ($line -match '^ok \d+ - (.+)$') { Test-Ok "W4-live-$($Matches[1])" $true $Matches[1] 'P0' }
        elseif ($line -match '^not ok \d+ - (.+)$') { Test-Ok "W4-live-$($Matches[1])" $false $Matches[1] 'P0' }
    }
    Test-Ok 'W4-live-smoke-exit' ($liveRc -eq 0) "live smoke exit=$liveRc" 'P0'
} else {
    Skip-Test 'W4-live-smoke' 'SKIP reason: GGB_WIMS_LIVE_ENDPOINT not configured; fixture replay is not live-server evidence' 'P0'
}
Complete-TestSuite
