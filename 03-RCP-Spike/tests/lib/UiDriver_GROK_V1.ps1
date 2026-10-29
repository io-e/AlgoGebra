# GROK_V1 - cross-platform UI driver for suites 08-10 (pwsh 7).
# Linux: Xvfb + xdotool + python3-PIL (ImageGrab xdisplay). Windows: user32 (SetCursorPos/mouse_event),
# System.Windows.Forms.SendKeys, System.Windows.Forms.Clipboard, System.Drawing CopyFromScreen.
$script:UiDisplay = if ($env:UI_DISPLAY) { $env:UI_DISPLAY } else { ':97' }
$script:Shots = Join-Path $script:Res 'screenshots'; New-Item -ItemType Directory -Force $script:Shots | Out-Null
$script:XvfbProc = $null
if ($IsWindows) {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    Add-Type -Namespace GrokUi -Name User32 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
[DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, System.UIntPtr e);
[DllImport("user32.dll")] public static extern bool GetWindowRect(System.IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr h, out uint pid);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h);
[DllImport("user32.dll")] public static extern System.IntPtr GetAncestor(System.IntPtr h, uint flags);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(System.IntPtr h, System.Text.StringBuilder s, int n);
public struct RECT { public int Left, Top, Right, Bottom; }
'@
}
function Test-UiPrerequisites {
    if ($IsWindows) { return $null }
    foreach ($b in 'Xvfb', 'xdotool', 'python3') { if (-not (Get-Command $b -CommandType Application -ErrorAction SilentlyContinue)) { return "$b missing" } }
    & python3 -c 'from PIL import ImageGrab' 2>$null; if ($LASTEXITCODE -ne 0) { return 'python3-PIL missing' }
    return $null
}
function Start-UiDisplay([string]$Geometry = '1600x1000x24') {
    if ($IsWindows) { return }
    $script:XvfbProc = Start-Process Xvfb -ArgumentList $script:UiDisplay, '-screen', '0', $Geometry, '+extension', 'GLX' -PassThru -RedirectStandardError ([IO.Path]::Combine($script:Tmp, "xvfb-$PID.err"))
    $sock = "/tmp/.X11-unix/X$($script:UiDisplay.TrimStart(':'))"
    for ($i = 0; $i -lt 40 -and -not (Test-Path $sock); $i++) { Start-Sleep -Milliseconds 250 }; Start-Sleep 1; $env:DISPLAY = $script:UiDisplay
}
function Stop-UiApp { if ($IsWindows) { Get-CimInstance Win32_Process -Filter "Name='java.exe'" | Where-Object CommandLine -match 'ggbplus.runId' | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }
    else { & pkill -f 'ggbplus.runId' 2>$null }; Start-Sleep 1 }
function Stop-UiDisplay { Stop-UiApp; if ($script:XvfbProc) { Stop-Process -Id $script:XvfbProc.Id -Force -ErrorAction SilentlyContinue; $script:XvfbProc.WaitForExit(10000) | Out-Null; $script:XvfbProc = $null
        $sock = "/tmp/.X11-unix/X$($script:UiDisplay.TrimStart(':'))"; for ($i = 0; $i -lt 20 -and (Test-Path $sock); $i++) { Start-Sleep -Milliseconds 250 } } }
# ---- Foreground-window guard (GROK_V1, after Codex r11 P-01: a screenshot captured the user's browser editor) ----------
# Every click, keystroke, paste, screenshot and pixel read goes through Assert-GgbForeground first. It checks that the
# foreground window belongs to the GeoGebraPlus process under test (a java/javaw whose command line has ggbplus.runId, or a
# child of it) AND that its title contains GeoGebra (Linux: or a JavaEmbeddedFrame of that same PID). If not, it tries ONE
# activation (SetForegroundWindow / xdotool windowactivate), re-checks, and otherwise sends NO input: the driver sets
# $script:UiGuardBlocked, every later driver action is a no-op and every later Test-Ok is recorded as BLOCKED (sticky for the suite).
# Input-driven UI also needs an explicit opt-in on a real desktop: Run_All -AllowForegroundInput (env GGB_UI_ALLOW_FOREGROUND=1).
# On Linux the private Xvfb display started by Start-UiDisplay counts as opt-in (nobody else's windows live there).
$script:UiInputCount = 0   # real input/capture actions dispatched (the guard unit test asserts it stays 0 when blocked)
function Test-UiInputAllowed { if ($env:GGB_UI_ALLOW_FOREGROUND -eq '1') { return $true }; return ((-not $IsWindows) -and $null -ne $script:XvfbProc) }
function Get-GgbPids { # java/javaw processes of the image under test (+ their children)
    if ($IsWindows) { $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
        $root = @($all | Where-Object { $_.Name -match '^javaw?\.exe$' -and $_.CommandLine -match 'ggbplus\.runId' } | ForEach-Object { [int]$_.ProcessId })
        $kids = @($all | Where-Object { [int]$_.ParentProcessId -in $root } | ForEach-Object { [int]$_.ProcessId }); return @($root + $kids) }
    $root = @(& pgrep -f 'ggbplus\.runId' 2>$null | ForEach-Object { [int]$_ })
    $kids = @(foreach ($r in $root) { & pgrep -P $r 2>$null | ForEach-Object { [int]$_ } }); return @($root + $kids)
}
function Get-UiForeground { # -> {Handle; Pid; Title; Top (title of the top-level window)}
    if ($IsWindows) { $h = [GrokUi.User32]::GetForegroundWindow(); $fp = [uint32]0; [void][GrokUi.User32]::GetWindowThreadProcessId($h, [ref]$fp)
        $top = [GrokUi.User32]::GetAncestor($h, 2); $sb = [Text.StringBuilder]::new(512); [void][GrokUi.User32]::GetWindowText($top, $sb, 512)
        return [pscustomobject]@{ Handle = $top; Pid = [int]$fp; Title = $sb.ToString(); Top = $sb.ToString() } }
    $w = "$(& xdotool getactivewindow 2>$null)".Trim(); if (-not $w) { $w = "$(& xdotool getwindowfocus -f 2>$null)".Trim() }
    if (-not $w -or $w -eq '0' -or $w -eq '1') { return [pscustomobject]@{ Handle = $null; Pid = 0; Title = '(no focused window)'; Top = '' } }
    $t = "$(& xdotool getwindowname $w 2>$null)"; $cur = [string]$w; $fp = ''
    # AWT focuses internal child windows (FocusProxy, JavaEmbeddedFrame) without _NET_WM_PID: walk up to the first ancestor that has one.
    for ($i = 0; $i -lt 8 -and $cur; $i++) { $fp = "$(& xdotool getwindowpid $cur 2>$null)".Trim(); if ($fp -match '^\d+$') { break }
        $par = "$(& xwininfo -tree -id $cur 2>$null | Select-String 'Parent window id: (0x[0-9a-f]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })"
        $root = "$(& xwininfo -tree -id $cur 2>$null | Select-String 'Root window id: (0x[0-9a-f]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })"
        if (-not $par -or $par -eq $root) { break }; $cur = [string][Convert]::ToInt64($par, 16) }
    $top = if ($cur -ne [string]$w) { "$(& xdotool getwindowname $cur 2>$null)" } else { $t }
    return [pscustomobject]@{ Handle = $w; Pid = $(if ($fp -match '^\d+$') { [int]$fp } else { 0 }); Title = $(if ($top -match 'GeoGebra') { $top } else { $t }); Top = $top }
}
function Test-GgbForegroundOnce([int[]]$Pids) { $f = Get-UiForeground
    $ok = ($f.Pid -gt 0 -and $f.Pid -in $Pids) -and ($f.Title -match 'GeoGebra' -or ((-not $IsWindows) -and $f.Title -eq 'JavaEmbeddedFrame'))
    return [pscustomobject]@{ Ok = $ok; Fg = $f } }
function Assert-GgbForeground([string]$Action = 'ui-action') { # -> $true when input/capture may proceed; otherwise sets BLOCKED and returns $false
    if ($script:UiGuardBlocked) { return $false }
    if (-not (Test-UiInputAllowed)) { $script:UiGuardBlocked = "foreground guard: $Action refused - input-driven UI on a real desktop needs Run_All -AllowForegroundInput (GGB_UI_ALLOW_FOREGROUND=1)"; Write-Host "# $script:UiGuardBlocked" -ForegroundColor Magenta; return $false }
    $pids = @(Get-GgbPids)
    if ($pids.Count -eq 0) { $script:UiGuardBlocked = "foreground guard: $Action refused - no GeoGebraPlus process (ggbplus.runId) under test"; Write-Host "# $script:UiGuardBlocked" -ForegroundColor Magenta; return $false }
    $c = Test-GgbForegroundOnce $pids; if ($c.Ok) { return $true }
    $first = $c.Fg; Write-Host "# foreground guard: $Action - foreground was '$($first.Title)' pid=$($first.Pid); one activation attempt"
    $target = @(Get-UiWindows 'GeoGebraPlus' | Select-Object -First 1)[0]   # one activation attempt
    if ($target) { if ($IsWindows) { [void][GrokUi.User32]::SetForegroundWindow([IntPtr]$target.Id) } else { & xdotool windowactivate --sync $target.Id 2>$null | Out-Null; & xdotool windowfocus --sync $target.Id 2>$null | Out-Null }; Start-Sleep -Milliseconds 600
        $c = Test-GgbForegroundOnce $pids; if ($c.Ok) { return $true } }
    $script:UiGuardBlocked = "foreground guard: $Action refused - foreground title='$($c.Fg.Title)' pid=$($c.Fg.Pid) (first seen '$($first.Title)' pid=$($first.Pid)); GeoGebraPlus pids=[$($pids -join ',')]; no input sent"
    Write-Host "# $script:UiGuardBlocked" -ForegroundColor Magenta; return $false
}
function Get-GgbShellRect { # rect of the GeoGebraPlus top-level window (screenshots are cropped to it)
    $s = @(Get-UiWindows 'GeoGebraPlus' | Sort-Object { $_.W * $_.H } -Descending | Select-Object -First 1)[0]; if ($s -and $s.W -gt 0 -and $s.H -gt 0) { return $s }; return $null }
# Launch the installed image (Linux launch.sh / Windows launch.ps1) and wait until the UI proof lines appear.
function Start-UiApp([string]$Name, [hashtable]$Env = @{}, [string[]]$LaunchArgs = @()) {
    $log = Join-Path $script:Res "$Name.log"; $saved = @{}
    foreach ($k in $Env.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $Env[$k]) }
    if ($IsWindows) { Start-Process pwsh -ArgumentList (@('-NoProfile', '-File', (Join-Path $script:Image 'launch.ps1')) + $LaunchArgs) -RedirectStandardOutput $log -WindowStyle Hidden | Out-Null }
    else { Start-Process bash -ArgumentList (@((Join-Path $script:Image 'launch.sh')) + $LaunchArgs) -RedirectStandardOutput $log -RedirectStandardError "$log.err" | Out-Null }
    foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    for ($i = 0; $i -lt 90; $i++) { Start-Sleep 1; if ((Test-Path $log) -and ((Get-Content $log -Raw) -match '3D view initialized|CAS FAILED|Headless D-02 smoke|Exception in thread "main"')) { break } }
    Start-Sleep 3; return $log
}
function Get-UiWindows([string]$NameRegex) { # -> objects {Id, X, Y, W, H, Name}
    if ($IsWindows) { return @(Get-Process | Where-Object { $_.MainWindowTitle -match $NameRegex } | ForEach-Object { $r = New-Object GrokUi.User32+RECT; [void][GrokUi.User32]::GetWindowRect($_.MainWindowHandle, [ref]$r); [pscustomobject]@{ Id = $_.MainWindowHandle; Name = $_.MainWindowTitle; X = $r.Left; Y = $r.Top; W = $r.Right - $r.Left; H = $r.Bottom - $r.Top } }) }
    $ids = & xdotool search --onlyvisible --name $NameRegex 2>$null
    return @($ids | Where-Object { $_ } | ForEach-Object { $g = (& xdotool getwindowgeometry $_) -join ' '
        if ($g -match 'Position: (\d+),(\d+).*Geometry: (\d+)x(\d+)') { [pscustomobject]@{ Id = $_; Name = (& xdotool getwindowname $_); X = [int]$Matches[1]; Y = [int]$Matches[2]; W = [int]$Matches[3]; H = [int]$Matches[4] } } } | Sort-Object X)
}
function Invoke-UiClick([int]$X, [int]$Y) { if (-not (Assert-GgbForeground "click($X,$Y)")) { return }; $script:UiInputCount++; if ($IsWindows) { [GrokUi.User32]::SetCursorPos($X, $Y) | Out-Null; [GrokUi.User32]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [GrokUi.User32]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero) }
    else { & xdotool mousemove $X $Y click 1 }; Start-Sleep -Milliseconds 400 }
function Send-UiText([string]$Text) { if (-not (Assert-GgbForeground "type '$Text'")) { return }; $script:UiInputCount++; if ($IsWindows) { [Windows.Forms.SendKeys]::SendWait(($Text -replace '([+^%~(){}\[\]])', '{$1}')) } else { & xdotool type --delay 60 $Text }; Start-Sleep -Milliseconds 500 }
# Keys use xdotool names; mapped to SendKeys on Windows.
function Send-UiKeys([string[]]$Keys) { foreach ($k in $Keys) { if (-not (Assert-GgbForeground "key $k")) { return }; $script:UiInputCount++
    if ($IsWindows) { $m = @{ 'Return' = '{ENTER}'; 'End' = '{END}'; 'shift+Home' = '+{HOME}'; 'BackSpace' = '{BACKSPACE}'; 'ctrl+a' = '^a'; 'ctrl+c' = '^c'; 'ctrl+v' = '^v'; 'Escape' = '{ESC}' }; [Windows.Forms.SendKeys]::SendWait($m[$k]) }
    else { & xdotool key $k } }; Start-Sleep -Milliseconds 300 }
function Save-UiShot([string]$Name) { $p = Join-Path $script:Shots "$Name.png"
    if (-not (Assert-GgbForeground "screenshot $Name")) { return "(not captured: $script:UiGuardBlocked)" }; $script:UiInputCount++
    $r = Get-GgbShellRect   # GeoGebraPlus window only, never the full desktop
    if ($IsWindows) { if (-not $r) { return '(not captured: GeoGebraPlus window rect unknown)' }
        $bmp = [Drawing.Bitmap]::new($r.W, $r.H); $g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.X, $r.Y, 0, 0, $bmp.Size); $bmp.Save($p); $g.Dispose(); $bmp.Dispose() }
    else { $crop = if ($r) { ".crop(($($r.X),$($r.Y),$($r.X + $r.W),$($r.Y + $r.H)))" } else { '' }   # private Xvfb: full display is acceptable fallback
        & python3 -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay='$($script:UiDisplay)')$crop.save('$p')" }
    return $p }
# Signature (md5) and statistics of a screen region: used to detect algebra-view changes and blank 3D renders.
function Get-UiRegion([int]$X1, [int]$Y1, [int]$X2, [int]$Y2) { # -> {Sig; Colors; NonDominant}
    if (-not (Assert-GgbForeground "pixel read $X1,$Y1-$X2,$Y2")) { return [pscustomobject]@{ Sig = "blocked-$([guid]::NewGuid())"; Colors = 0; NonDominant = 0 } }
    if ($IsWindows) { $w = $X2 - $X1; $h = $Y2 - $Y1; $bmp = [Drawing.Bitmap]::new($w, $h); $g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($X1, $Y1, 0, 0, $bmp.Size)
        $cnt = @{}; $sb = [Text.StringBuilder]::new(); for ($yy = 0; $yy -lt $h; $yy += 2) { for ($xx = 0; $xx -lt $w; $xx += 2) { $c = $bmp.GetPixel($xx, $yy).ToArgb(); $cnt[$c] = 1 + [int]$cnt[$c]; [void]$sb.Append($c) } }
        $g.Dispose(); $bmp.Dispose(); $tot = ($cnt.Values | Measure-Object -Sum).Sum; $dom = ($cnt.Values | Measure-Object -Maximum).Maximum
        $md5 = [BitConverter]::ToString([Security.Cryptography.MD5]::HashData([Text.Encoding]::ASCII.GetBytes($sb.ToString())))
        return [pscustomobject]@{ Sig = $md5; Colors = $cnt.Count; NonDominant = [math]::Round(1 - $dom / $tot, 4) } }
    $o = & python3 -c @"
from PIL import ImageGrab; import hashlib
im=ImageGrab.grab(xdisplay='$($script:UiDisplay)').crop(($X1,$Y1,$X2,$Y2)).convert('RGB'); c=im.getcolors(1<<24); c.sort(reverse=True); n=sum(k for k,_ in c)
print(hashlib.md5(im.tobytes()).hexdigest(), len(c), round(1-c[0][0]/n,4))
"@
    $a = "$o".Split(' '); return [pscustomobject]@{ Sig = $a[0]; Colors = [int]$a[1]; NonDominant = [double]$a[2] }
}
function Test-UiErrorDialog { (Get-UiWindows 'GeoGebra - Error').Count -gt 0 }
function Close-UiErrorDialog { $w = Get-UiWindows 'GeoGebra - Error'; if ($w) { if (-not (Assert-GgbForeground 'close error dialog')) { return }; $script:UiInputCount++; if (-not $IsWindows) { & xdotool windowactivate --sync $w[0].Id 2>$null; & xdotool key --window $w[0].Id Return } else { [Windows.Forms.SendKeys]::SendWait('{ENTER}') }; Start-Sleep -Milliseconds 700 } }

# Two SWT_AWT panes (2D left, 3D right). Linux: the two JavaEmbeddedFrame X windows. Windows: split of the shell rect.
# Calibrated from the Windows r10 UI screenshot (2026-10-29): divider ~57.5/42.5; both input click centers land inside the bars.
function Get-PaneLayout {
    if ($IsWindows) { $s = Get-UiWindows 'GeoGebraPlus' | Select-Object -First 1; if (-not $s) { return $null }
        $w2 = [int]($s.W * 0.575); $f2 = [pscustomobject]@{ X = $s.X + 8; Y = $s.Y + 31; W = $w2; H = $s.H - 39 }; $f3 = [pscustomobject]@{ X = $s.X + $w2 + 14; Y = $s.Y + 31; W = $s.W - $w2 - 22; H = $s.H - 39 } }
    else { $fr = Get-UiWindows '^JavaEmbeddedFrame$'; if ($fr.Count -lt 2) { return $null }; $f2 = $fr[0]; $f3 = $fr[1] }
    foreach ($f in $f2, $f3) { $f | Add-Member -Force InX ([int]($f.X + $f.W / 2)); $f | Add-Member -Force InY ([int]($f.Y + $f.H - 18))
        $f | Add-Member -Force Av @($f.X, ($f.Y + 60), ($f.X + 200), ($f.Y + $f.H - 60)); $f | Add-Member -Force Bar @(($f.X + 60), ($f.Y + $f.H - 28), ($f.X + $f.W - 60), ($f.Y + $f.H - 8)) }
    return @($f2, $f3)
}
function Get-RegionOf([int[]]$R) { Get-UiRegion $R[0] $R[1] $R[2] $R[3] }
