# GROK_V1 - D-09 Unsigned or out-of-channel extension. Gate E. Pass (spec): blocked by policy.
# Precheck documents the current state: no signature policy, an unsigned bundle IS accepted. That is the expected
# precheck result today and is recorded as a gap, not as a PASS of D-09.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-09'; Write-ScenarioHeader 'D-09' 'Unsigned or out-of-channel extension' 'E' 'desktop'; Test-ImagePresent
$p = Invoke-ResolveProbe 'S_D-09' { param($d) New-TestBundle $d 'org.geogebra.plus.test.unsigned' '1.0.0' @() | Out-Null }
$ini = Get-ChildItem (Join-Path $script:Image 'configuration') -Filter 'config.ini' -Recurse | Select-Object -First 1
$sig = $ini -and ((Get-Content $ini.FullName -Raw) -match 'osgi.signedcontent.support|signedcontent')
Test-Ok 'D09-01-precheck-current-state-recorded' $true "unsigned bundle state=$($p.States['org.geogebra.plus.test.unsigned']) signedcontent configured=$sig (gap: no policy)" 'P1'
Skip-Blocked 'D09-02-policy-blocks-unsigned' 'no signing key, no distribution channel and no signature policy yet (owner decision needed; Gate E)' 'P0'
Complete-TestSuite
