# GROK_V1 - D-04 UI suite (cross-platform pwsh; Linux = Xvfb + xdotool, Windows = SendKeys/user32/System.Drawing).
# Keyboard input in the algebra input bar, exact sequences raising "Please check your input" (window "GeoGebra - Error"),
# SWT_AWT focus switching 2D<->3D panes, clipboard copy/paste between panes, ctrl+a NPE, LaTeX font errors, HiDPI startup.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'); . (Join-Path $PSScriptRoot 'lib/UiDriver_GROK_V1.ps1')
Initialize-TestSuite '09_D04_UI'
$launcher = if ($IsWindows) { 'launch.ps1' } else { 'launch.sh' }
if (-not (Test-Path (Join-Path $script:Image $launcher))) { Exit-Bail "image not found: $script:Image" }
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
function Clear-Bar { Send-UiKeys @('End', 'shift+Home', 'BackSpace') }
function Invoke-Input($Pane, [string]$Text) { # -> {Dialog; Lost; Changed}
    $av0 = (Get-UiRegion @($Pane.Av)).Sig; Invoke-UiClick $Pane.InX $Pane.InY; Clear-Bar; $b = (Get-UiRegion @($Pane.Bar)).Sig
    Send-UiText $Text; $lost = ((Get-UiRegion @($Pane.Bar)).Sig -eq $b)
    if ($lost) { Invoke-UiClick $Pane.InX $Pane.InY; Start-Sleep -Milliseconds 300; Clear-Bar; Send-UiText $Text }
    Send-UiKeys @('Return'); Start-Sleep -Milliseconds 1500
    return [pscustomobject]@{ Dialog = (Test-UiErrorDialog); Lost = $lost; Changed = ((Get-UiRegion @($Pane.Av)).Sig -ne $av0) } }
Start-UiDisplay '1600x1000x24'
$log = Start-UiApp '09_ui_session1'
Test-Ok 'D04-00-ui-started' ((Get-Content $log -Raw) -match '3D view initialized=true') "log=$log" 'P0'
$panes = Get-PaneLayout; if (-not $panes) { Stop-UiDisplay; Exit-Bail 'SWT_AWT panes not found' }
$p2 = $panes[0]; $p3 = $panes[1]; Write-Host "# 2D pane $($p2.X),$($p2.Y) $($p2.W)x$($p2.H) input=($($p2.InX),$($p2.InY)); 3D pane $($p3.X),$($p3.Y) $($p3.W)x$($p3.H)"
Save-UiShot '09_00_start' | Out-Null
$seq = @()
foreach ($row in Read-Fixture 'd04_inputs_GROK_V1.tsv') { $id, $txt, $exp = $row
    $r = Invoke-Input $p2 $txt; $shot = Save-UiShot "09_$id"
    $seq += "[$txt => lostFirstBurst=$($r.Lost) dialog=$($r.Dialog) algebraChanged=$($r.Changed)]"
    if ($exp -eq 'OK') { Test-Ok "$id-[$txt]" (-not $r.Dialog) "lostFirstBurst=$($r.Lost) dialog=$($r.Dialog) algebraViewChanged=$($r.Changed) keystrokes: click bar; End,shift+Home,BackSpace; type '$txt'; Return; shot=$shot" 'P0' }
    else { Test-Ok "$id-[$txt]-error-dialog" $r.Dialog "dialog=$($r.Dialog) (invalid input must be reported) shot=$shot" 'P1' }
    if ($r.Lost) { Test-Ok "$id-keys-reach-input" $false 'first click+keystrokes after the previous Return/dialog did not reach the AWT input bar; retyped after a 2nd click' 'P1' }
    Close-UiErrorDialog }
Write-Host "# D-04 session-1 sequence: $($seq -join ' ')"
$uilog = Get-Content $log -Raw
$n0 = ([regex]::Matches($uilog, 'Log\.logger" is null')).Count; Invoke-UiClick $p2.InX $p2.InY; Send-UiKeys @('ctrl+a'); Start-Sleep 1; Send-UiKeys @('End')
$n1 = ([regex]::Matches((Get-Content $log -Raw), 'Log\.logger" is null')).Count
Test-Ok 'D04-CTRLA-01-no-npe' ($n1 -eq $n0) "ctrl+a in 2D input bar: NPE 'Log.logger is null' (ScreenReaderAdapterD.readText -> Log.read) count $n0 -> $n1" 'P1'
$f0 = ([regex]::Matches((Get-Content $log -Raw), "jlm_cmr10\.ttf'\. Error message: Problem reading font data")).Count
Test-Ok 'D04-FONT-01-latex-fonts' ($f0 -eq 0) "ReTeX FontLoaderD fonts/latin/jlm_cmr10.ttf 'Problem reading font data': $f0 occurrence(s)" 'P1'
$r = Invoke-Input $p3 'E=(1,1,1)'; $shot = Save-UiShot '09_focus_3d'
Test-Ok 'D04-FOCUS-01-2d-to-3d' ((-not $r.Dialog) -and $r.Changed) "3D bar E=(1,1,1): lost=$($r.Lost) dialog=$($r.Dialog) algebra3DChanged=$($r.Changed) shot=$shot" 'P0'; Close-UiErrorDialog
$r = Invoke-Input $p2 'P=(2,3)'; $shot = Save-UiShot '09_focus_back_2d'
Test-Ok 'D04-FOCUS-02-3d-to-2d' ((-not $r.Dialog) -and $r.Changed) "back to 2D bar P=(2,3): lost=$($r.Lost) dialog=$($r.Dialog) algebra2DChanged=$($r.Changed) shot=$shot" 'P0'; Close-UiErrorDialog
# clipboard: type in 2D bar, select + copy, paste into 3D bar
Invoke-UiClick $p2.InX $p2.InY; Clear-Bar; Send-UiText 'Q=(4,1)'; Send-UiKeys @('End', 'shift+Home', 'ctrl+c'); Start-Sleep 1
$clip = if ($IsWindows) { [Windows.Forms.Clipboard]::GetText() } elseif (Get-Command xclip -CommandType Application -ErrorAction SilentlyContinue) { (& xclip -o -selection clipboard 2>$null) -join '' } else { '(xclip not installed)' }
Send-UiKeys @('Escape'); $av0 = (Get-UiRegion @($p3.Av)).Sig; Invoke-UiClick $p3.InX $p3.InY; Clear-Bar; Send-UiKeys @('ctrl+v'); $s1 = Save-UiShot '09_clip_pasted'; Send-UiKeys @('Return'); Start-Sleep 1.5
$dlg = Test-UiErrorDialog; $chg = ((Get-UiRegion @($p3.Av)).Sig -ne $av0); $s2 = Save-UiShot '09_clip_after_enter'
Test-Ok 'D04-CLIP-01-copy-2d-paste-3d' ((-not $dlg) -and $chg) "ctrl+c in 2D bar (system clipboard='$clip'), ctrl+v in 3D bar, Return: dialog=$dlg algebra3DChanged=$chg shots=$s1,$s2" 'P1'
Close-UiErrorDialog; Stop-UiApp
# session 2: fresh start, function as first input; then 3D function; then 2D after 3D
$log2 = Start-UiApp '09_ui_session2'; $panes = Get-PaneLayout; $p2 = $panes[0]; $p3 = $panes[1]
$r = Invoke-Input $p2 'f(x)=x^2'; Test-Ok 'D04-ORDER-01-fx-first-input' (-not $r.Dialog) "fresh session, first input f(x)=x^2: dialog=$($r.Dialog) shot=$(Save-UiShot '09_session2_fx_first')" 'P0'; Close-UiErrorDialog
$r = Invoke-Input $p2 'A=(1,2)'; Test-Ok 'D04-ORDER-02-point-second-input' (-not $r.Dialog) "second input A=(1,2): lost=$($r.Lost) dialog=$($r.Dialog) changed=$($r.Changed) shot=$(Save-UiShot '09_session2_A_second')" 'P0'; Close-UiErrorDialog
$r = Invoke-Input $p3 'h(x)=x^2'; Test-Ok 'D04-ORDER-03-function-in-3d-pane' (-not $r.Dialog) "3D input h(x)=x^2: lost=$($r.Lost) dialog=$($r.Dialog) shot=$(Save-UiShot '09_session2_fx_3d')" 'P1'; Close-UiErrorDialog
$r = Invoke-Input $p2 'k(x)=x+1'; Test-Ok 'D04-ORDER-04-function-2d-after-3d' (-not $r.Dialog) "2D input k(x)=x+1 after 3D: lost=$($r.Lost) dialog=$($r.Dialog) shot=$(Save-UiShot '09_session2_fx_2d_after_3d')" 'P1'; Close-UiErrorDialog
Stop-UiDisplay
# HiDPI
if ($IsWindows) { Skip-Test 'D04-HIDPI-01-startup' 'Windows HiDPI = display scaling of the desktop session; run manually at 200 % and use Save-UiShot' }
else { $script:UiDisplay = ':96'; Start-UiDisplay '3200x2000x24'
    $log3 = Start-UiApp '09_ui_hidpi' @{ GDK_SCALE = '2'; JAVA_TOOL_OPTIONS = '-Dswt.autoScale=200 -Dsun.java2d.uiScale=2' }
    $t = Get-Content $log3 -Raw; Test-Ok 'D04-HIDPI-01-startup' (($t -match 'D-02 PASS') -and ($t -match '3D view initialized=true')) "GDK_SCALE=2 swt.autoScale=200 uiScale=2 shot=$(Save-UiShot '09_hidpi_start')" 'P1'
    $s = Get-UiWindows 'GeoGebraPlus' | Select-Object -First 1; Test-Ok 'D04-HIDPI-02-window-scaled' ($s.W -gt 1600) "shell geometry $($s.W)x$($s.H) on 3200x2000" 'P1'; Stop-UiDisplay }
Complete-TestSuite
