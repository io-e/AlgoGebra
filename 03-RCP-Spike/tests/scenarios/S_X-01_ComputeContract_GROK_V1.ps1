# GROK_V1 - X-01 Same compute contract (desktop part). Gate D. Pass (spec): same typed result or documented gap.
# Checks: typed result fields exist in the API; repeated engine calls give the same result (deterministic contract);
# GeoGebra CAS in the product gives the same result in two sessions. Web side: deferred.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-01'; Write-ScenarioHeader 'X-01' 'Same compute contract' 'D' 'both (desktop part)'
$api = Join-Path $script:SpikeDir 'engines/api/src/org/geogebra/plus/compute/api'; $src = (Get-ChildItem $api -Filter *.java | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
foreach ($m in 'engineId', 'text', 'artifact', 'mediaType', 'elapsed') { Test-Ok "X01-01-result-field-$m" ($src -match "public \S+ $m\(\)") "ComputeResult.$m()" 'P1' }
Test-Ok 'X01-02-result-kind-typed' ($src -match 'enum\s+\w*(Kind|Type)') 'typed result kind (text/number/matrix/image/error) as an enum in the API' 'P1'
if (Find-EngineBinary 'pari') { Initialize-Tools
  $o = 1..3 | ForEach-Object { (Invoke-Engine 'pari' 30 'factor(2^64+1)').out }
  Test-Ok 'X01-03-pari-deterministic' (($o | Select-Object -Unique).Count -eq 1 -and $o[0]) "3 runs factor(2^64+1) -> '$($o[0])'" 'P0' } else { Skip-Blocked 'X01-03-pari-deterministic' 'gp not on PATH' }
$why = Test-UiPrerequisites
if (-not $why) { $script:UiDisplay = ':91'; Start-UiDisplay; $d = "CAS`tC1`tExpand((x + 1)^5)`nCAS`tC2`tIntegral(x sin(x))`nCAS`tC3`tSolve(x^2 = 2, x)"
  $a = Invoke-ProductScenario 'S_X-01_s1' $d; $b = Invoke-ProductScenario 'S_X-01_s2' $d; Stop-UiDisplay
  Test-Ok 'X01-04-cas-same-across-sessions' ((@('C1','C2','C3') | Where-Object { $a.Scn[$_].Val -ne $b.Scn[$_].Val -or $a.Scn[$_].St -ne 'OK' }).Count -eq 0) "C1='$($a.Scn['C1'].Val)' C2='$($a.Scn['C2'].Val)' C3='$($a.Scn['C3'].Val)'" 'P0' } else { Skip-Blocked 'X01-04-cas-same-across-sessions' $why }
Skip-Blocked 'X01-05-typed-contract-shared-with-web' 'shared typed request/result contract (kind enum, error codes) not designed yet; web client deferred: web phase' 'P0'
Complete-TestSuite
