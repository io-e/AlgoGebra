# GROK_V1 - X-03 Write an allowlisted number back (desktop). Gate D. Pass (spec): views update.
# Precheck: GgbAPI setValue on free / dependent / fixed objects behaves as the pinned GeoGebra (dependent objects refuse).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-03'; Write-ScenarioHeader 'X-03' 'Write an allowlisted number back' 'D' 'desktop'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$d = "CMD`tA1`ta = 1`nCMD`tA2`tb = 2 a`nCMD`tA3`tc = 5`nCMD`tA4`tSetFixed(c, true)`nSETVAL`tS1`ta=4`nSETVAL`tS2`tb=100`nSETVAL`tS3`tc=9`nVAL`tV1`ta`nVAL`tV2`tb`nVAL`tV3`tc"
$script:UiDisplay = ':91'; Start-UiDisplay; $p = Invoke-ProductScenario 'S_X-03_product' $d; $b = Invoke-BaselineScenario 'S_X-03' $d; Stop-UiDisplay
Test-Ok 'X03-01-free-object-updated' ($p.Scn['V1'].Val -eq 'a = 4' -and $p.Scn['V2'].Val -eq 'b = 8') "a='$($p.Scn['V1'].Val)' b='$($p.Scn['V2'].Val)'" 'P0'
Test-Ok 'X03-02-dependent-object-refused' ($p.Scn['V2'].Val -eq 'b = 8') 'setValue on dependent b ignored' 'P0'
Test-Ok 'X03-03-same-as-baseline' ($b -and (@('V1','V2','V3') | Where-Object { $p.Scn[$_].Val -ne $b.Scn[$_].Val }).Count -eq 0) "product c='$($p.Scn['V3'].Val)' baseline c='$($b.Scn['V3'].Val)'" 'P0'
Skip-Blocked 'X03-04-adapter-allow-list' 'state adapter (allow-list of what an external engine may change) not implemented yet' 'P0'
Complete-TestSuite
