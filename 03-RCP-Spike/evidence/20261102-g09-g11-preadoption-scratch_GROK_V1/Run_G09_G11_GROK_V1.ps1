# GROK_V1 - G-09 (SWT course tree renders on GTK, screenshot) + G-11 (font/locale in course tree), Debian/Xvfb.
# PRE-ADOPTION, SCRATCH PATCHES: image = feat/external-engines tip + #27 font diff (PR #36) + #28 logger diff (PR #32).
# Usage: pwsh -File Run_G09_G11_GROK_V1.ps1 -Image <image dir> -Repo <repo root> -Out <evidence dir> [-Fixture <locale course json>]
param([Parameter(Mandatory)][string]$Image, [Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)][string]$Out, [string]$Fixture = (Join-Path $PSScriptRoot 'course_locale_fixture_GROK_V1.json'), [int]$Wait = 35, [string[]]$Only)
New-Item -ItemType Directory -Force $Out | Out-Null
$cases = @(
  @{ id = 'G09-trig-en-CUTF8'; course = (Join-Path $Repo 'courses/trigonometry_intro.json'); lang = 'C.UTF-8'; jopt = '' },
  @{ id = 'G11-fixture-CUTF8-en'; course = $Fixture; lang = 'C.UTF-8'; jopt = '' },
  @{ id = 'G11-fixture-CUTF8-fr'; course = $Fixture; lang = 'C.UTF-8'; jopt = '-Duser.language=fr -Duser.country=FR' },
  @{ id = 'G11-fixture-POSIX'; course = $Fixture; lang = 'C'; jopt = '' })
$n = 0; $disp = 140
foreach ($c in $cases) { if ($Only -and $c.id -notin $Only) { continue }
  $d = ":$($disp + $n)"; $n++
  $x = Start-Process Xvfb -ArgumentList $d, '-screen', '0', '1600x1000x24', '-nolisten', 'tcp' -PassThru
  Start-Sleep 2
  $env:DISPLAY = $d; $env:LANG = $c.lang; $env:LC_ALL = $c.lang; $env:JDK_JAVA_OPTIONS = $c.jopt
  $log = Join-Path $Out "$($c.id).log"
  $p = Start-Process bash -ArgumentList (Join-Path $Image 'launch.sh'), '-Course', $c.course -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
  Start-Sleep $Wait
  $png = Join-Path $Out "$($c.id).png"
  & python3 -c "from PIL import ImageGrab; ImageGrab.grab(xdisplay='$d').save('$png')"
  $win = (& xdotool search --name '.' getwindowname %@ 2>$null) -join ' | '
  Get-Process -Id $p.Id -EA SilentlyContinue | Out-Null; & pkill -P $p.Id 2>$null; Stop-Process -Id $p.Id -EA SilentlyContinue; Start-Sleep 2
  Stop-Process -Id $x.Id -EA SilentlyContinue
  $t = (Get-Content $log, "$log.err" -Raw -EA SilentlyContinue) -join ''
  $course = ($t -split "`n" | Where-Object { $_ -match '(?i)course' } | Select-Object -First 4) -join ' / '
  $err = @($t -split "`n" | Where-Object { $_ -match '(?i)exception|MalformedInput|unmappable|\?\?\?' }).Count
  "{0}`tLANG={1}`tJOPT={2}`tpng={3}`terrors={4}`twindows={5}`tcourse-log={6}" -f $c.id, $c.lang, $c.jopt, (Test-Path $png), $err, $win, $course | Tee-Object -Append (Join-Path $Out 'summary.tsv')
}
Remove-Item Env:JDK_JAVA_OPTIONS -EA SilentlyContinue
