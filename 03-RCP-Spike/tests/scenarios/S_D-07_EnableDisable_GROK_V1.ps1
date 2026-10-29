# GROK_V1 - D-07 Enable/disable an extension by restart. Gate B. Pass (spec): open work kept, state clear.
# Precheck: the product starts with an extra bundle added to the set and again with it removed (state from bundles.info);
# work kept across the restart is checked with a saved .ggb. Product enable/disable UI and state file do not exist.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-07'; Write-ScenarioHeader 'D-07' 'Enable/disable an extension by restart' 'B' 'desktop'; Test-ImagePresent
$a = Invoke-ResolveProbe 'S_D-07_on' { param($d) New-TestBundle $d 'org.geogebra.plus.test.ext' '1.0.0' @('Import-Package: org.geogebra.common.kernel') | Out-Null }
$b = Invoke-ResolveProbe 'S_D-07_off' { param($d) }
Test-Ok 'D07-01-enabled-set-resolves' ($a.States['org.geogebra.plus.test.ext'] -eq 'RESOLVED' -and (Get-CoreResolvedCount $a) -eq (Get-CoreResolvedCount $b)) "on: ext=$($a.States['org.geogebra.plus.test.ext']) core=$(Get-CoreResolvedCount $a)" 'P1'
Test-Ok 'D07-02-disabled-set-resolves' (-not $b.States.Contains('org.geogebra.plus.test.ext') -and (Get-CoreResolvedCount $b) -gt 40) "off: core=$(Get-CoreResolvedCount $b)" 'P1'
$why = Test-UiPrerequisites
if ($why) { Skip-Blocked 'D07-03-work-kept-across-restart' $why } else {
  $ggb = Join-Path $script:Res 'S_D-07_work.ggb'; $script:UiDisplay = ':91'; Start-UiDisplay
  $r1 = Invoke-ProductScenario 'S_D-07_s1' "CMD`tW1`tP = (3, 4)`nCMD`tW2`td = Distance(P, (0, 0))`nSAVE`tW3`t$ggb"
  $r2 = Invoke-ProductScenario 'S_D-07_s2' "OPEN`tW4`t$ggb`nVAL`tW5`td"; Stop-UiDisplay
  Test-Ok 'D07-03-work-kept-across-restart' ($r2.Scn['W5'].Val -eq 'd = 5') "after restart d='$($r2.Scn['W5'].Val)'" 'P1' }
Skip-Blocked 'D07-04-product-enable-disable' 'product extension manager (enable/disable UI, persisted state, restart prompt, autosave of open work) not implemented yet' 'P0'
Complete-TestSuite
