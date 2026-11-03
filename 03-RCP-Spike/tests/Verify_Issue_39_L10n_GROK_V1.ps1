# GROK_V1 - G-11-GAP-1 / BUG-013 (#39): embedded GeoGebra panes must show translated labels, not raw keys.
# Debian/Xvfb. Language selected per JVM: JDK_JAVA_OPTIONS='-Duser.language=fr -Duser.country=FR' (box has no fr system locale;
# GeoGebra's LocalizationD follows the JVM default Locale). -Dggbplus.localizationTrace=true adds the host trace (PR #50 only).
# Checks: (a) OCR (rapidocr) of full window + File/Options menus: no raw keys, expected EN/FR labels; (b) trace log labels if present.
# Usage: pwsh -File Verify_Issue_39_L10n_GROK_V1.ps1 -Image <image dir> -Out <dir> -Tag <name> [-Display 231] [-Python <venv python>] [-Langs en,fr]
param([Parameter(Mandatory)][string]$Image, [Parameter(Mandatory)][string]$Out, [Parameter(Mandatory)][string]$Tag,
      [int]$Display = 231, [string]$Python = '/workspace/ocrvenv/bin/python', [string[]]$Langs = @('en','fr'), [int]$Wait = 40)
New-Item -ItemType Directory -Force $Out | Out-Null
$ocr = Join-Path $PSScriptRoot 'tools/ocr_l10n_GROK_V1.py'
$menus = @{ en = @(@{n='File';x=67;y=64}, @{n='Options';x=278;y=64}, @{n='File3D';x=937;y=64}); fr = @(@{n='File';x=67;y=64}, @{n='Options';x=278;y=64}, @{n='File3D';x=937;y=64}) }
$i = 0; $fails = 0
foreach ($lang in $Langs) {
  $n = $Display + $i; $d = ":$n"; $id = "$Tag-$lang"
  if (Test-Path "/tmp/.X11-unix/X$n") { Write-Host "display $d in use"; exit 2 }
  $x = Start-Process Xvfb -ArgumentList $d, '-screen', '0', '1600x1000x24', '-nolisten', 'tcp' -PassThru; Start-Sleep 2
  $env:DISPLAY = $d; $env:LANG = 'C.UTF-8'; $env:LC_ALL = 'C.UTF-8'
  $env:JDK_JAVA_OPTIONS = '-Dggbplus.localizationTrace=true' + ($(if ($lang -eq 'fr') { ' -Duser.language=fr -Duser.country=FR' } else { ' -Duser.language=en -Duser.country=US' }))
  $log = Join-Path $Out "$id.log"
  $p = Start-Process bash -ArgumentList (Join-Path $Image 'launch.sh') -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
  Start-Sleep $Wait
  $shots = @(); $main = Join-Path $Out "$id-main.png"
  & $Python -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay='$d').save('$main')"; $shots += $main
  foreach ($m in $menus[$lang]) {
    & xdotool mousemove $m.x $m.y click 1; Start-Sleep 2
    $png = Join-Path $Out "$id-menu-$($m.n).png"
    & $Python -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay='$d').save('$png')"; $shots += $png
    & xdotool key Escape; Start-Sleep 1
  }
  & pkill -P $p.Id 2>$null; Stop-Process -Id $p.Id -EA SilentlyContinue; Start-Sleep 2; Stop-Process -Id $x.Id -EA SilentlyContinue; Start-Sleep 1
  $r = (& $Python $ocr $lang (Join-Path $Out "$id-ocr.json") @shots) | Select-Object -Last 1
  $trace = @(Get-Content $log -EA SilentlyContinue | Where-Object { $_ -match 'Localization trace' } | ForEach-Object { if ($_ -match 'locale=(\S+);.*labels=\[(.*)\]') { "$($Matches[1]): $($Matches[2])" } })
  $ok = ($r | ConvertFrom-Json).pass
  if (-not $ok) { $fails++ }
  "{0}`t{1}`tocr={2}`ttrace={3}" -f $(if ($ok) {'PASS'} else {'FAIL'}), $id, $r, ($(if ($trace) { $trace -join ' || ' } else { '(none)' })) | Tee-Object -Append (Join-Path $Out 'summary.tsv')
  $i++
}
Remove-Item Env:JDK_JAVA_OPTIONS -EA SilentlyContinue
exit $fails
