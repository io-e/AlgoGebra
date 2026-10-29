# GROK_V1 - X-07 Lean absent (desktop). Pass (spec): app opens, feature unavailable.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-07'; Write-ScenarioHeader 'X-07' 'Lean absent' '-' 'desktop'; Test-ImagePresent
$lean = Get-Command lean, lake -ErrorAction SilentlyContinue
Test-Ok 'X07-01-lean-absent-on-host' (-not $lean) "lean on PATH: $($lean.Source -join ',')" 'P0'
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$script:UiDisplay = ':91'; Start-UiDisplay; $r = Invoke-ProductScenario 'S_X-07' "NAMES3`tL1`nCAS`tL2`tSimplify(2x + 3x)"; Stop-UiDisplay
Test-Ok 'X07-02-app-opens-without-lean' ($r.Text -match 'D-02 PASS' -and $r.Text -match '3D view initialized=true' -and $r.Scn['L2'].Val -match '5') "CAS='$($r.Scn['L2'].Val)' log=$($r.Log)" 'P0'
$lb = Select-String -Path (Join-Path $script:Image 'configuration/org.eclipse.equinox.simpleconfigurator/bundles.info') -Pattern '(?i)lean' -ErrorAction SilentlyContinue
Test-Ok 'X07-03-no-lean-bundle-required' (-not $lb) 'no mandatory Lean bundle in the product set' 'P0'
Test-Ok 'X07-04-no-lean-error' ($r.Text -notmatch '(?i)lean[^\r\n]*(exception|error)') 'no Lean error in log' 'P1'
Complete-TestSuite
