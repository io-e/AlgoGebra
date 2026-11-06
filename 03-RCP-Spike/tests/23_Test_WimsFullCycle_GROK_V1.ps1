# WA-9 - G-16 (WP7-04) full WIMS exercise cycle in Firefox (Playwright) against the loopback OEF hook mock.
# Template (G-14) + grade client (G-15) + web-host course tree + self-hosted GeoGebra WAR, all same-origin on 127.0.0.1.
# Env: GGB_WAR_DIR (WAR dir with deployggb.js + web3d/), PLAYWRIGHT_NODE_MODULES (node_modules containing playwright; default
#      tests/playwright/node_modules), Playwright Firefox installed (npx playwright install firefox). SKIP when missing.
# Optional: G16_OUT (evidence dir for screenshots + mock request log; default tests/results/g16).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '23_WimsFullCycle'
$node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$pw = if ($env:PLAYWRIGHT_NODE_MODULES) { $env:PLAYWRIGHT_NODE_MODULES } else { Join-Path $PSScriptRoot 'playwright/node_modules' }
$war = $env:GGB_WAR_DIR
if (-not $node) { Skip-Test 'FC-env' 'SKIP reason: node not found' 'P0'; Complete-TestSuite; return }
if (-not (Test-Path (Join-Path $pw 'playwright'))) { Skip-Test 'FC-env' "SKIP reason: playwright not found under $pw (set PLAYWRIGHT_NODE_MODULES)" 'P0'; Complete-TestSuite; return }
if (-not $war -or -not (Test-Path (Join-Path $war 'deployggb.js'))) { Skip-Test 'FC-env' "SKIP reason: GGB_WAR_DIR not set or has no deployggb.js ($war)" 'P0'; Complete-TestSuite; return }
$out = if ($env:G16_OUT) { $env:G16_OUT } else { Join-Path $PSScriptRoot 'results/g16' }
$env:OUT_DIR = $out; $env:PLAYWRIGHT_NODE_MODULES = $pw
$o = & $node.Source (Join-Path $PSScriptRoot 'fixtures/wims/full_cycle_firefox_GROK_V1.mjs') 2>&1 | Out-String
foreach ($l in ($o -split "`r?`n")) { if ($l -match '^(ok|not ok) \d+ - (\S+)(?: :: (.*))?$') { Test-Ok $Matches[2] ($Matches[1] -eq 'ok') "$($Matches[3])" 'P0' } }
Test-Ok 'FC-99-summary' ($o -match '# full cycle: \d+ PASS, 0 FAIL') (($o -split "`n" | Where-Object { $_ -match '^# full cycle' }) -join '') 'P0'
Complete-TestSuite
