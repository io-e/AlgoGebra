# GROK_V1 - D-06 Extension registry (good and bad test extension). Gate B. Pass (spec): bad one isolated, core starts.
# Precheck (resolver level): a well-formed test bundle resolves; a bad one (missing mandatory package) stays INSTALLED;
# all core bundles still resolve. The product-level registry (extension points, UI contribution, error report) does not exist.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-06'; Write-ScenarioHeader 'D-06' 'Extension registry' 'B' 'desktop'; Test-ImagePresent
$base = Invoke-ResolveProbe 'S_D-06_base' { param($d) }; $n0 = Get-CoreResolvedCount $base
$p = Invoke-ResolveProbe 'S_D-06_probe' { param($d)
  New-TestBundle $d 'org.geogebra.plus.test.good' '1.0.0' @('Import-Package: org.geogebra.common.kernel') | Out-Null
  New-TestBundle $d 'org.geogebra.plus.test.bad' '1.0.0' @('Import-Package: org.example.does.not.exist;version="[1,2)"') | Out-Null }
Test-Ok 'D06-01-good-extension-resolves' ($p.States['org.geogebra.plus.test.good'] -eq 'RESOLVED') "good=$($p.States['org.geogebra.plus.test.good']) log=$($p.Log)" 'P0'
Test-Ok 'D06-02-bad-extension-isolated' ($p.States['org.geogebra.plus.test.bad'] -eq 'INSTALLED' -and $p.Text -match 'UNRESOLVED_BUNDLE[^\r\n]*org.geogebra.plus.test.bad') "bad=$($p.States['org.geogebra.plus.test.bad'])" 'P0'
Test-Ok 'D06-03-core-still-resolves' ((Get-CoreResolvedCount $p) -eq $n0 -and $n0 -gt 40) "core resolved with probes=$(Get-CoreResolvedCount $p) baseline=$n0" 'P0'
Skip-Blocked 'D06-04-product-registry' 'product extension registry (extension point, contribution, error report to the user) not implemented yet' 'P0'
Complete-TestSuite
