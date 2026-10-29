# GROK_V1 - X-04 Save and undo (desktop). Gate D. Pass (spec): UI does not call the output a native dependent object.
# Precheck: with an undo point after each command (GgbAPI.setUndoPoint, as the input bar does), GgbAPI undo removes exactly the last command in the product, same as the baseline.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-04'; Write-ScenarioHeader 'X-04' 'Save and undo' 'D' 'desktop'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$d = "UNDOPOINT`tU0`nCMD`tU1`tP = (1, 1)`nUNDOPOINT`tUP1`nCMD`tU2`tQ = (2, 3)`nUNDOPOINT`tUP2`nCMD`tU3`tr = Line(P, Q)`nUNDOPOINT`tUP3`nNAMES`tN1`nUNDO`tU4`nNAMES`tN2`nUNDO`tU5`nNAMES`tN3"
$script:UiDisplay = ':91'; Start-UiDisplay; $p = Invoke-ProductScenario 'S_X-04_product' $d; $b = Invoke-BaselineScenario 'S_X-04' $d; Stop-UiDisplay
Test-Ok 'X04-01-undo-one-step' ($p.Scn['N1'].Val -eq 'P,Q,r' -and $p.Scn['N2'].Val -eq 'P,Q') "N1=[$($p.Scn['N1'].Val)] after undo=[$($p.Scn['N2'].Val)] after 2nd undo=[$($p.Scn['N3'].Val)]" 'P0'
Test-Ok 'X04-02-same-as-baseline' ($b -and (@('N1','N2','N3') | Where-Object { $p.Scn[$_].Val -ne $b.Scn[$_].Val }).Count -eq 0) "baseline N2=[$($b.Scn['N2'].Val)] N3=[$($b.Scn['N3'].Val)]" 'P0'
Skip-Blocked 'X04-03-external-output-not-native-dependent' 'host does not yet insert external engine results into the construction (no adapter), so save+undo of an external output and its labelling cannot be tested' 'P0'
Complete-TestSuite
