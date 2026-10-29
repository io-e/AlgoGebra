# GROK_V1 - P-07 Screens and input (desktop). Pass (spec): no blocking UI fault.
# One product session: UI actions (resize small/large/tiny, keyboard input in the 2D bar via xdotool) run first, then the
# delayed scenario hook reads the object list through GgbAPI, so typed input is verified by the model, not by pixels.
# Second session: HiDPI start (GDK_SCALE=2). Known: BUG-010 (input dialog, lost keystrokes) -> keyboard check FAILs until fixed.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-07'; Write-ScenarioHeader 'P-07' 'Screens and input' '-' 'desktop (narrow browser deferred)'; Test-ImagePresent
if ($IsWindows) { Skip-Blocked 'P07-all' 'UI suites are not run on the shared Windows PC (syntax check only); run on a Windows test VM' 'P0'; Complete-TestSuite; exit 0 }
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$tsv = Join-Path $script:Res 'S_P-07_ui.directives.tsv'; Set-Content $tsv "NAMES`tN-after-ui`nVAL`tV-K`tK" -Encoding UTF8
$script:UiDisplay = ':91'; Start-UiDisplay
$log = Start-UiApp 'S_P-07_ui' @{ 'JAVA_TOOL_OPTIONS' = "-Dggbplus.scenario=$tsv -Dggbplus.scenarioDelayMs=40000 -Dggbplus.scenarioExit=true" }
Test-Ok 'P07-01-start' ((Get-Content $log -Raw) -match '3D view initialized=true') "log=$log" 'P0'
$shell = Get-UiWindows 'GeoGebraPlus' | Select-Object -First 1
if ($shell) { & xdotool windowmove $shell.Id 0 0 2>&1 | Out-Null }
foreach ($sz in @(@(1024, 700), @(1400, 900), @(800, 560))) {
  if ($shell) { & xdotool windowsize $shell.Id $sz[0] $sz[1] 2>&1 | Out-Null }; Start-Sleep 2
  $fr = Get-UiWindows '^JavaEmbeddedFrame$'; $shot = Save-UiShot "S_P-07_$($sz[0])x$($sz[1])"
  Test-Ok "P07-02-resize-$($sz[0])x$($sz[1])" ($shell -and $fr.Count -ge 2 -and -not (Test-UiErrorDialog)) "embedded frames=$($fr.Count) sizes=[$(($fr | ForEach-Object { "$($_.W)x$($_.H)" }) -join ' ')] shot=$shot" 'P1' }
if ($shell) { & xdotool windowmove $shell.Id 0 0 2>&1 | Out-Null; & xdotool windowsize $shell.Id 1500 900 2>&1 | Out-Null; Start-Sleep 3 }
$p = (Get-PaneLayout)
if ($p) { Invoke-UiClick $p[0].InX $p[0].InY; Start-Sleep -Milliseconds 500; Send-UiText 'K=(4,4)'; Send-UiKeys @('Return'); Start-Sleep 2 }
$dlg = Test-UiErrorDialog; $shotK = Save-UiShot 'S_P-07_keyboard'; if ($dlg) { Close-UiErrorDialog }
for ($i = 0; $i -lt 90 -and -not ((Get-Content $log -Raw) -match 'SCN\t_END'); $i++) { Start-Sleep 1 }
$s = Parse-Scn ((Get-Content $log -Raw))
Test-Ok 'P07-03-keyboard-input-2d' ($s['V-K'].Val -eq 'K = (4, 4)' -and -not $dlg) "typed 'K=(4,4)'+Return in the 2D input bar; model value='$($s['V-K'].Val)' names=[$($s['N-after-ui'].Val)] error dialog=$dlg shot=$shotK (see BUG-010)" 'P0'
Stop-UiDisplay
$script:UiDisplay = ':92'; Start-UiDisplay '3200x2000x24'
$r2 = Invoke-ProductScenario 'S_P-07_hidpi' "NAMES3`tH-1" 150 @{ 'GDK_SCALE' = '2' }
Test-Ok 'P07-04-hidpi-start' ($r2.Scn['H-1'].St -eq 'OK' -and $r2.Text -match '3D view initialized=true') "GDK_SCALE=2 on 3200x2000; 3D names=[$($r2.Scn['H-1'].Val)] log=$($r2.Log)" 'P1'
Stop-UiDisplay
Skip-Blocked 'P07-05-touch' 'no touch device on the test host'
Skip-Blocked 'P07-W-narrow-browser' 'deferred: web phase'
Complete-TestSuite
