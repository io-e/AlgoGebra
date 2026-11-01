# GROK_V1 - unit-ish test of the foreground-window guard (lib/UiDriver_GROK_V1.ps1 Assert-GgbForeground).
# In every negative case the driver must record BLOCKED and dispatch NO input ($script:UiInputCount stays 0).
# G-01..03 run everywhere. G-04 (foreign window foreground + fake ggbplus.runId java process): Linux = private Xvfb + xmessage;
# Windows = a WinForms window created by this test in its own pwsh process (never a user app). G-05/G-06 (real image accepted,
# screenshot = window rect): Linux = private Xvfb; Windows = only with -AllowForegroundInput (launches $env:IMAGE / -Image).
# Cleanup kills only the processes this test started.
param([switch]$AllowForegroundInput, [string]$Image)
if ($Image) { $env:IMAGE = $Image }
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'); . (Join-Path $PSScriptRoot 'lib/UiDriver_GROK_V1.ps1')
Initialize-TestSuite '14_UiGuard'
$savedEnv = $env:GGB_UI_ALLOW_FOREGROUND
$optIn = $AllowForegroundInput -or $env:GGB_UI_ALLOW_FOREGROUND -eq '1'
Write-Host "# image=$script:Image optIn=$optIn os=$(if ($IsWindows) { 'windows' } else { 'linux' })"
$script:Started = @()   # processes started by this test (only these are killed)
function Stop-Mine { foreach ($p in $script:Started) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }; $script:Started = @() }
function Start-FakeGgb { # java process whose command line has ggbplus.runId but owns no window (PID-mismatch case)
    $src = Join-Path $script:Tmp "GrokGuardSleep$PID.java"; Set-Content $src 'public class GrokGuardSleep { public static void main(String[] a) throws Exception { Thread.sleep(120000); } }' -Encoding ascii
    $sp = @{ FilePath = (Get-JavaTool 'java'); ArgumentList = @('-Dggbplus.runId=guardtest', $src); PassThru = $true }; if ($IsWindows) { $sp['WindowStyle'] = 'Hidden' }
    $p = Start-Process @sp; $script:Started += $p
    for ($i = 0; $i -lt 20 -and @(Get-GgbPids).Count -eq 0; $i++) { Start-Sleep -Milliseconds 500 }; return $p }
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
if (@(Get-GgbPids).Count -gt 0) { Skip-Test 'G-03-optin-no-ggb-process' 'SKIP reason: a GeoGebraPlus process is running on this host; not touching it' }
else { $shot = Invoke-AllPrimitives; $g = Get-GuardState
    Test-Ok 'G-03-optin-no-ggb-process-blocked' ($g.Blocked -match 'no GeoGebraPlus process' -and $g.Count -eq 0) "blocked='$($g.Blocked)' inputs=$($g.Count)" 'P0' }
$env:GGB_UI_ALLOW_FOREGROUND = $null

if (@(Get-GgbPids).Count -gt 0) { Skip-Test 'G-04-foreign-window' 'SKIP reason: a GeoGebraPlus process is already running on this host; not touching it'; Skip-Test 'G-05-real-ggb-allowed' 'SKIP reason: GeoGebraPlus already running' }
elseif ($IsWindows) {
    # 4. Windows: own WinForms window (known title) made foreground + fake ggbplus.runId java -> BLOCKED, 0 inputs
    $env:GGB_UI_ALLOW_FOREGROUND = '1'; $fake = Start-FakeGgb; $title = "GROK guard foreign window $PID"
    $formCmd = "Add-Type -AssemblyName System.Windows.Forms; `$f = New-Object Windows.Forms.Form; `$f.Text = '$title'; `$f.TopMost = `$true; `$f.Width = 400; `$f.Height = 200; `$t = New-Object Windows.Forms.Timer; `$t.Interval = 60000; `$t.add_Tick({ `$f.Close() }); `$t.Start(); `$f.add_Shown({ `$f.Activate() }); [void]`$f.ShowDialog()"
    $form = Start-Process pwsh -ArgumentList '-NoProfile', '-Command', $formCmd -PassThru; $script:Started += $form
    $h = $null; for ($i = 0; $i -lt 40 -and -not $h; $i++) { Start-Sleep -Milliseconds 250; $form.Refresh(); $pp = Get-Process -Id $form.Id -ErrorAction SilentlyContinue; if ($pp -and $pp.MainWindowTitle -eq $title) { $h = $pp.MainWindowHandle } }
    if ($h) { [void][GrokUi.User32]::SetForegroundWindow($h); Start-Sleep -Milliseconds 500 }
    $fg = Get-UiForeground; $shot = Invoke-AllPrimitives; $g = Get-GuardState
    Test-Ok 'G-04-foreign-window-blocked-no-input' ($fake -and $g.Blocked -match 'foreground title=' -and $g.Blocked -match 'no input sent' -and $g.Count -eq 0) "own window='$title' found=$([bool]$h); foreground='$($fg.Title)' pid=$($fg.Pid); blocked='$($g.Blocked)' inputs=$($g.Count)" 'P0'
    Stop-Mine; $env:GGB_UI_ALLOW_FOREGROUND = $null
    # 5/6. Windows: real image, only with explicit opt-in
    $launcher = Join-Path $script:Image 'launch.ps1'
    if (-not $optIn) { Skip-Test 'G-05-real-ggb-allowed' 'SKIP reason: Windows real-window check needs -AllowForegroundInput (it brings GeoGebraPlus to the front; no keys are typed)'; Skip-Test 'G-06-shot-is-window-rect' 'SKIP reason: needs -AllowForegroundInput' }
    elseif (-not (Test-Path $launcher)) { Skip-Test 'G-05-real-ggb-allowed' "SKIP reason: image not found: $script:Image (set IMAGE or -Image)"; Skip-Test 'G-06-shot-is-window-rect' 'SKIP reason: image not found' }
    else { $env:GGB_UI_ALLOW_FOREGROUND = '1'; $log = Start-UiApp '14_guard_ggb'; $mine = @(Get-GgbPids)
        $sh = $null; for ($i = 0; $i -lt 30 -and -not $sh; $i++) { $sh = Get-GgbShellRect; if (-not $sh) { Start-Sleep 1 } }
        if ($sh) { [void][GrokUi.User32]::SetForegroundWindow([IntPtr]$sh.Id); Start-Sleep -Milliseconds 800 }
        $ok = Assert-GgbForeground 'positive probe'; $fg = Get-UiForeground; $shot = if ($ok) { Save-UiShot '14_guard_ggb' } else { '' }
        $dims = ''; if ($shot -and (Test-Path $shot)) { Add-Type -AssemblyName System.Drawing; $im = [Drawing.Image]::FromFile($shot); $dims = "($($im.Width), $($im.Height))"; $im.Dispose() }; $g = Get-GuardState
        Test-Ok 'G-05-real-ggb-allowed' ($ok -and -not $g.Blocked) "image=$script:Image foreground='$($fg.Title)' pid=$($fg.Pid) ggb=[$($mine -join ',')] blocked='$($g.Blocked)' log=$log" 'P1'
        Test-Ok 'G-06-shot-is-window-rect' ($ok -and $sh -and $dims -eq "($($sh.W), $($sh.H))") "shot=$shot size=$dims window=$($sh.W)x$($sh.H)" 'P1'
        foreach ($q in $mine) { Stop-Process -Id $q -Force -ErrorAction SilentlyContinue }; $env:GGB_UI_ALLOW_FOREGROUND = $null }
}
else {
    $why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
    $script:UiDisplay = ':88'; Start-UiDisplay '1280x800x24'
    # 4. foreign window focused + a fake ggbplus.runId process (PID mismatch): one activation attempt, then BLOCKED, no input
    $fake = Start-FakeGgb
    $xm = Start-Process xmessage -ArgumentList '-title', 'Browser editor (unsaved)', 'not GeoGebra' -PassThru; $script:Started += $xm; Start-Sleep 2
    $w = "$(& xdotool search --name 'Browser editor' 2>$null | Select-Object -First 1)"; if ($w) { & xdotool windowfocus --sync $w 2>$null }
    $fg = Get-UiForeground; $shot = Invoke-AllPrimitives; $g = Get-GuardState
    Test-Ok 'G-04-foreign-window-blocked-no-input' ($fake -and $g.Blocked -match 'foreground title=' -and $g.Blocked -match 'no input sent' -and $g.Count -eq 0) "focused='$($fg.Title)' pid=$($fg.Pid); blocked='$($g.Blocked)' inputs=$($g.Count)" 'P0'
    Stop-Mine
    # 5. positive: the real image on the private display is accepted
    $launcher = Join-Path $script:Image 'launch.sh'
    if (-not (Test-Path $launcher)) { Skip-Test 'G-05-real-ggb-allowed' "SKIP reason: image not found: $script:Image (set IMAGE or -Image)" }
    else { $log = Start-UiApp '14_guard_ggb'; $sh = Get-GgbShellRect; if ($sh) { & xdotool windowactivate --sync $sh.Id 2>$null; & xdotool windowfocus --sync $sh.Id 2>$null }
        $ok = Assert-GgbForeground 'positive probe'; $fg = Get-UiForeground; $shot = if ($ok) { Save-UiShot '14_guard_ggb' } else { '' }
        $dims = if ($shot -and (Test-Path $shot)) { "$(& python3 -c "from PIL import Image; print(Image.open('$shot').size)")" } else { '' }; $g = Get-GuardState
        Test-Ok 'G-05-real-ggb-allowed' ($ok -and -not $g.Blocked) "foreground='$($fg.Title)' pid=$($fg.Pid) ggb=[$((Get-GgbPids) -join ',')] blocked='$($g.Blocked)' log=$log" 'P1'
        Test-Ok 'G-06-shot-is-window-rect' ($ok -and $sh -and $dims -eq "($($sh.W), $($sh.H))") "shot=$shot size=$dims shell=$($sh.W)x$($sh.H) (display 1280x800)" 'P1' }
    Stop-UiDisplay
}
Stop-Mine; $env:GGB_UI_ALLOW_FOREGROUND = $savedEnv
Complete-TestSuite
