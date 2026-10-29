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
    Start-Sleep 2; $env:DISPLAY = $script:UiDisplay
}
function Stop-UiApp { if ($IsWindows) { Get-CimInstance Win32_Process -Filter "Name='java.exe'" | Where-Object CommandLine -match 'ggbplus.runId' | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }
    else { & pkill -f 'ggbplus.runId' 2>$null }; Start-Sleep 1 }
function Stop-UiDisplay { Stop-UiApp; if ($script:XvfbProc) { Stop-Process -Id $script:XvfbProc.Id -Force -ErrorAction SilentlyContinue; $script:XvfbProc = $null } }
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
function Invoke-UiClick([int]$X, [int]$Y) { if ($IsWindows) { [GrokUi.User32]::SetCursorPos($X, $Y) | Out-Null; [GrokUi.User32]::mouse_event(2, 0, 0, 0, [UIntPtr]::Zero); [GrokUi.User32]::mouse_event(4, 0, 0, 0, [UIntPtr]::Zero) }
    else { & xdotool mousemove $X $Y click 1 }; Start-Sleep -Milliseconds 400 }
function Send-UiText([string]$Text) { if ($IsWindows) { [Windows.Forms.SendKeys]::SendWait(($Text -replace '([+^%~(){}\[\]])', '{$1}')) } else { & xdotool type --delay 60 $Text }; Start-Sleep -Milliseconds 500 }
# Keys use xdotool names; mapped to SendKeys on Windows.
function Send-UiKeys([string[]]$Keys) { foreach ($k in $Keys) {
    if ($IsWindows) { $m = @{ 'Return' = '{ENTER}'; 'End' = '{END}'; 'shift+Home' = '+{HOME}'; 'BackSpace' = '{BACKSPACE}'; 'ctrl+a' = '^a'; 'ctrl+c' = '^c'; 'ctrl+v' = '^v'; 'Escape' = '{ESC}' }; [Windows.Forms.SendKeys]::SendWait($m[$k]) }
    else { & xdotool key $k } }; Start-Sleep -Milliseconds 300 }
function Save-UiShot([string]$Name) { $p = Join-Path $script:Shots "$Name.png"
    if ($IsWindows) { $b = [Windows.Forms.SystemInformation]::VirtualScreen; $bmp = [Drawing.Bitmap]::new($b.Width, $b.Height); $g = [Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size); $bmp.Save($p); $g.Dispose(); $bmp.Dispose() }
    else { & python3 -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay='$($script:UiDisplay)').save('$p')" }
    return $p }
# Signature (md5) and statistics of a screen region: used to detect algebra-view changes and blank 3D renders.
function Get-UiRegion([int]$X1, [int]$Y1, [int]$X2, [int]$Y2) { # -> {Sig; Colors; NonDominant}
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
function Close-UiErrorDialog { $w = Get-UiWindows 'GeoGebra - Error'; if ($w) { if (-not $IsWindows) { & xdotool windowactivate --sync $w[0].Id 2>$null; & xdotool key --window $w[0].Id Return } else { [Windows.Forms.SendKeys]::SendWait('{ENTER}') }; Start-Sleep -Milliseconds 700 } }

# Two SWT_AWT panes (2D left, 3D right). Linux: the two JavaEmbeddedFrame X windows. Windows: split of the shell rect
# (SashForm default ~58/42, measured on Linux 863/625 px) - approximate, verify with the screenshots.
function Get-PaneLayout {
    if ($IsWindows) { $s = Get-UiWindows 'GeoGebraPlus' | Select-Object -First 1; if (-not $s) { return $null }
        $w2 = [int]($s.W * 0.58); $f2 = [pscustomobject]@{ X = $s.X + 8; Y = $s.Y + 31; W = $w2; H = $s.H - 39 }; $f3 = [pscustomobject]@{ X = $s.X + $w2 + 14; Y = $s.Y + 31; W = $s.W - $w2 - 22; H = $s.H - 39 } }
    else { $fr = Get-UiWindows '^JavaEmbeddedFrame$'; if ($fr.Count -lt 2) { return $null }; $f2 = $fr[0]; $f3 = $fr[1] }
    foreach ($f in $f2, $f3) { $f | Add-Member -Force InX ([int]($f.X + $f.W / 2)); $f | Add-Member -Force InY ([int]($f.Y + $f.H - 18))
        $f | Add-Member -Force Av @($f.X, ($f.Y + 60), ($f.X + 200), ($f.Y + $f.H - 60)); $f | Add-Member -Force Bar @(($f.X + 60), ($f.Y + $f.H - 28), ($f.X + $f.W - 60), ($f.Y + $f.H - 8)) }
    return @($f2, $f3)
}
function Get-RegionOf([int[]]$R) { Get-UiRegion $R[0] $R[1] $R[2] $R[3] }
