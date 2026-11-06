# WA-9 - G-15 (WP7-03) WIMS grade client: contract tests against a loopback mock of OEF cmd=new/reply + JSON hook.
# Needs node >= 18 (SKIP otherwise). No real WIMS server is contacted.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '22_WimsGradeClient'
$repo = Split-Path $script:SpikeDir -Parent
$client = Join-Path $repo 'wims/course-activity-template/wims-grade-client_GROK_V1.js'
$t = Join-Path $PSScriptRoot 'fixtures/wims/grade_client_test_GROK_V1.mjs'
Test-Ok 'WG-00-client-exists' (Test-Path $client) $client 'P0'
$node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $node) { Skip-Test 'WG-node' 'SKIP reason: node not found (need >= 18)' 'P0'; Complete-TestSuite; return }
$v = [int]((& $node.Source -p 'process.versions.node.split(".")[0]') | Out-String).Trim()
if ($v -lt 18) { Skip-Test 'WG-node' "SKIP reason: node $v < 18" 'P0'; Complete-TestSuite; return }
$out = & $node.Source $t 2>&1 | Out-String
foreach ($l in ($out -split "`r?`n")) {
  if ($l -match '^(ok|not ok) \d+ - (\S+)(?: :: (.*))?$') { Test-Ok "WG-$($Matches[2])" ($Matches[1] -eq 'ok') "$($Matches[3])" 'P0' }
}
Test-Ok 'WG-99-summary' ($out -match '# grade client: \d+ PASS, 0 FAIL') (($out -split "`n" | Where-Object { $_ -match '^# grade client' }) -join '') 'P0'
Complete-TestSuite
