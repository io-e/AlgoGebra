# GROK_V1 - D-08 Incompatible extension. Gate B. Pass (spec): clear refusal; status at most PARTIAL here (resolver level only).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-08'; Write-ScenarioHeader 'D-08' 'Incompatible extension' 'B' 'desktop'; Test-ImagePresent
$p = Invoke-ResolveProbe 'S_D-08' { param($d)
  New-TestBundle $d 'org.geogebra.plus.test.future' '1.0.0' @('Require-Bundle: org.geogebra.migration.shared.common;bundle-version="[9.0.0,10.0.0)"') | Out-Null
  New-TestBundle $d 'org.geogebra.plus.test.dependent' '1.0.0' @('Require-Bundle: org.geogebra.plus.test.future') | Out-Null }
Test-Ok 'D08-01-incompatible-range-refused' ($p.States['org.geogebra.plus.test.future'] -eq 'INSTALLED') "future (needs common [9,10))=$($p.States['org.geogebra.plus.test.future'])" 'P0'
Test-Ok 'D08-02-dependent-not-resolved' ($p.States['org.geogebra.plus.test.dependent'] -eq 'INSTALLED') "dependent=$($p.States['org.geogebra.plus.test.dependent'])" 'P0'
Test-Ok 'D08-03-reason-reported' ($p.Text -match 'org.geogebra.plus.test.future') "harness output names the refused bundle; log=$($p.Log)" 'P1'
Test-Ok 'D08-04-core-unaffected' ((Get-CoreResolvedCount $p) -gt 40) "core resolved=$(Get-CoreResolvedCount $p)" 'P0'
Skip-Blocked 'D08-05-user-facing-refusal' 'product message to the user (which extension, why, what version is needed) not implemented yet' 'P0'
Complete-TestSuite
