# GROK_V1 - unit-ish test of the foreground-window guard (lib/UiDriver_GROK_V1.ps1 Assert-GgbForeground).
# Safe on any desktop: in every negative case the driver must record BLOCKED and dispatch NO input ($script:UiInputCount stays 0).
# Windows: only cases that cannot send input (no opt-in; opt-in but no GeoGebraPlus process). Linux: same on a private Xvfb,
# plus a foreign window (xmessage) focused and a fake ggbplus.runId process, plus a positive check with the real image if present.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'); . (Join-Path $PSScriptRoot 'lib/UiDriver_GROK_V1.ps1')
Initialize-TestSuite '14_UiGuard'
$savedEnv = $env:GGB_UI_ALLOW_FOREGROUND
function Invoke-AllPrimitives { $null = Invoke-UiClick 10 10; $null = Send-UiText 'GUARD'; $null = Send-UiKeys @('Return', 'ctrl+v'); $shot = Save-UiShot '14_guard_probe'; $null = Get-UiRegion 0 0 4 4; $null = Close-UiErrorDialog; return $shot }
function Get-GuardState { $b = $script:UiGuardBlocked; $n = $script:UiInputCount; $script:UiGuardBlocked = $null; $script:UiInputCount = 0; return [pscustomobject]@{ Blocked = $b; Count = $n } }

# 1. no opt-in, no private display: everything refused
$env:GGB_UI_ALLOW_FOREGROUND = $null; $script:XvfbProc = $null; $script:UiGuardBlocked = $null; $script:UiInputCount = 0
$shot = Invoke-AllPrimitives; $g = Get-GuardState
Test-Ok 'G-01-no-optin-blocked-no-input' ($g.Blocked -match 'AllowForegroundInput' -and $g.Count -eq 0 -and $shot -like '(not captured*') "blocked='$($g.Blocked)' inputs=$($g.Count) shot=$shot" 'P0'
# 2. BLOCKED is sticky and turns a later Test-Ok into a BLOCKED row (never PASS/FAIL from a wrong window)
$null = Invoke-UiClick 1 1; $before = $script:TestSkipCount; Test-Ok 'G-02-probe-must-be-BLOCKED' $true 'expected BLOCKED row' 'P2'
$row = (Get-Content $script:Csv | Select-Object -Last 1); $g = Get-GuardState
Test-Ok 'G-02-test-ok-recorded-as-blocked' ($row -match ',BLOCKED,' -and $script:TestSkipCount -eq $before + 1 -and $g.Count -eq 0) "csv row: $row" 'P0'
# 3. opt-in but no GeoGebraPlus process under test
& { if ($IsWindows) { } else { & pkill -f 'ggbplus\.runId' 2>$null } }
$env:GGB_UI_ALLOW_FOREGROUND = '1'
if (@(Get-GgbPids).Count -gt 0) { Skip-Test 'G-03-optin-no-ggb-process' 'a GeoGebraPlus process is running on this host; not touching it' }
else { $shot = Invoke-AllPrimitives; $g = Get-GuardState
    Test-Ok 'G-03-optin-no-ggb-process-blocked' ($g.Blocked -match 'no GeoGebraPlus process' -and $g.Count -eq 0) "blocked='$($g.Blocked)' inputs=$($g.Count)" 'P0' }
$env:GGB_UI_ALLOW_FOREGROUND = $null

if ($IsWindows) { Skip-Test 'G-04-foreign-window' 'Linux/Xvfb only (on Windows it would need a foreground window of another app)'; Skip-Test 'G-05-real-ggb-allowed' 'Linux/Xvfb only' }
else {
    $why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
    $script:UiDisplay = ':88'; Start-UiDisplay '1280x800x24'
    # 4. foreign window focused + a fake ggbplus.runId process (PID mismatch): one activation attempt, then BLOCKED, no input
    $fake = Start-Process python3 -ArgumentList '-c "import time;time.sleep(120)" ggbplus.runId=guardtest' -PassThru; Start-Sleep 1
    $xm = Start-Process xmessage -ArgumentList '-title', 'Browser editor (unsaved)', 'not GeoGebra' -PassThru; Start-Sleep 2
    $w = "$(& xdotool search --name 'Browser editor' 2>$null | Select-Object -First 1)"; if ($w) { & xdotool windowfocus --sync $w 2>$null }
    $fg = Get-UiForeground; $shot = Invoke-AllPrimitives; $g = Get-GuardState
    Test-Ok 'G-04-foreign-window-blocked-no-input' ($g.Blocked -match 'foreground title=' -and $g.Blocked -match 'no input sent' -and $g.Count -eq 0) "focused='$($fg.Title)' pid=$($fg.Pid); blocked='$($g.Blocked)' inputs=$($g.Count)" 'P0'
    Stop-Process -Id $fake.Id, $xm.Id -Force -ErrorAction SilentlyContinue
    # 5. positive: the real image on the private display is accepted
    $launcher = Join-Path $script:Image 'launch.sh'
    if (-not (Test-Path $launcher)) { Skip-Test 'G-05-real-ggb-allowed' "image not found: $script:Image" }
    else { $log = Start-UiApp '14_guard_ggb'; $sh = Get-GgbShellRect; if ($sh) { & xdotool windowactivate --sync $sh.Id 2>$null; & xdotool windowfocus --sync $sh.Id 2>$null }
        $ok = Assert-GgbForeground 'positive probe'; $fg = Get-UiForeground; $shot = if ($ok) { Save-UiShot '14_guard_ggb' } else { '' }
        $dims = if ($shot -and (Test-Path $shot)) { "$(& python3 -c "from PIL import Image; print(Image.open('$shot').size)")" } else { '' }; $g = Get-GuardState
        Test-Ok 'G-05-real-ggb-allowed' ($ok -and -not $g.Blocked) "foreground='$($fg.Title)' pid=$($fg.Pid) ggb=[$((Get-GgbPids) -join ',')] blocked='$($g.Blocked)' log=$log" 'P1'
        Test-Ok 'G-06-shot-is-window-rect' ($ok -and $sh -and $dims -eq "($($sh.W), $($sh.H))") "shot=$shot size=$dims shell=$($sh.W)x$($sh.H) (display 1280x800)" 'P1' }
    Stop-UiDisplay
}
$env:GGB_UI_ALLOW_FOREGROUND = $savedEnv
Complete-TestSuite
