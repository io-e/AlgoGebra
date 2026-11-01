# GROK_V1 - suite 18 (P0 / G-T1): launch.sh -Course flag, per 03-RCP-Spike/docs/Design_LaunchSh_Course_Flag_GROK_V1.md (PR #8).
# LC-01..17 use GGBPLUS_LAUNCH_DRYRUN=1 (prints final java argv, starts nothing) on a scratch image dir.
# LC-18/19 = real Xvfb launches; SKIP until the product image contains CourseTreePanel (Codex X-T4 / WP2-06).
# Exit codes: 64 usage, 65 not .json / > 1 MB, 66 missing/not a file, 77 outside GGBPLUS_COURSE_ROOT, 4 no Java (BUG-017, PR #4).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '18_LaunchCourse'
if ($IsWindows) { Skip-Test 'LC-all' 'SKIP reason: Linux launcher; Windows twin is launch.ps1 -Course (Codex X-T5)' 'P0'; Complete-TestSuite }
$launch = Join-Path $script:SpikeDir 'launch.sh'
$j25 = if ($env:J25) { $env:J25 } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-25*' | Select-Object -First 1).FullName }
foreach ($p in $launch, $j25) { if (-not $p -or -not (Test-Path $p)) { Exit-Bail "missing: $p" } }
$repo = Split-Path $script:SpikeDir -Parent; $trig = Join-Path $repo 'courses/trigonometry_intro.json'
$w = Join-Path $script:Tmp "grok18-$PID"; $img = Join-Path $w 'image'; $c = Join-Path $w 'courses'; $out = Join-Path $w 'outside'
New-Item -ItemType Directory -Force (Join-Path $img 'bundles'), $c, $out, (Join-Path $w 'home'), (Join-Path $c 'a dir') | Out-Null
$ok = Join-Path $c 'ok.json'; Copy-Item $trig $ok; $sp = Join-Path $c 'a dir/my course.json'; Copy-Item $trig $sp
$ext = Join-Path $out 'ext.json'; Copy-Item $trig $ext; Set-Content (Join-Path $c 'c.ggb') 'x'; Set-Content (Join-Path $c 'c.txt') 'x'
$big = Join-Path $c 'big.json'; [IO.File]::WriteAllBytes($big, [byte[]]::new(1048577))
& ln -s $ok (Join-Path $c 'link.json'); & ln -s $ext (Join-Path $c 'esc.json')
$evil = Join-Path $c 'x$(touch PWNED);y.json'; Copy-Item -LiteralPath $trig -Destination $evil
function Invoke-L([string[]]$A, [hashtable]$Env = @{}, [string]$Cwd = $w) {
    $base = @{ HOME = (Join-Path $w 'home'); PATH = '/usr/bin:/bin'; IMAGE = $img; GGB_JAVA = "$j25/bin/java"; GGBPLUS_LAUNCH_DRYRUN = '1' }
    foreach ($k in $Env.Keys) { $base[$k] = $Env[$k] }
    $ea = @('-i') + @($base.GetEnumerator() | Where-Object { $_.Value -ne '' } | ForEach-Object { "$($_.Key)=$($_.Value)" })
    Push-Location $Cwd; try { $o = (& env @ea bash $launch @A 2>&1 | Out-String).Trim(); $rc = $LASTEXITCODE } finally { Pop-Location }
    $args1 = @($o -split "`n" | Where-Object { $_ -like 'ARG *' } | ForEach-Object { $_.Substring(4) })
    $cp = @($args1 | Where-Object { $_ -like '-Dggbplus.course=*' })
    [pscustomobject]@{ Rc = $rc; Out = $o; Course = $(if ($cp.Count) { $cp[0].Substring(17) } else { $null }); NCourse = $cp.Count; Args = $args1 } }
function T([string]$Id, $r, [bool]$Cond, [string]$Pr = 'P0') { Test-Ok $Id $Cond "rc=$($r.Rc) course=[$($r.Course)] out=[$((($r.Out -split "`n") | Where-Object { $_ -notlike 'ARG *' }) -join ' | ')]" $Pr }
$okR = (& realpath $ok).Trim()
$r = Invoke-L @(); T 'LC-01-no-flag-no-property' $r ($r.Rc -eq 0 -and $r.NCourse -eq 0)
$r = Invoke-L @('-Course', 'courses/ok.json'); T 'LC-02-relative-to-abs-realpath' $r ($r.Rc -eq 0 -and $r.Course -eq $okR)
$r = Invoke-L @("--course=$ok"); T 'LC-03-long-eq-form' $r ($r.Rc -eq 0 -and $r.Course -eq $okR)
$r = Invoke-L @('--course', $sp); T 'LC-04-path-with-spaces-one-arg' $r ($r.Rc -eq 0 -and $r.Course -eq $sp -and ($r.Args -ccontains "-Dggbplus.course=$sp"))
$r = Invoke-L @('-Course'); T 'LC-05-missing-value' $r ($r.Rc -eq 64)
$r = Invoke-L @('-Course', $ok, '--course', $ok); T 'LC-06-repeated-flag' $r ($r.Rc -eq 64)
$r = Invoke-L @('-Course', (Join-Path $c 'nope.json')); T 'LC-07-missing-file' $r ($r.Rc -eq 66)
$r = Invoke-L @('-Course', $c); T 'LC-08-directory' $r ($r.Rc -eq 66)
$r1 = Invoke-L @('-Course', (Join-Path $c 'c.ggb')); $r2 = Invoke-L @('-Course', (Join-Path $c 'c.txt')); T 'LC-09-wrong-extension' $r1 ($r1.Rc -eq 65 -and $r2.Rc -eq 65)
$r = Invoke-L @('-Course', $big); T 'LC-10-over-1MB' $r ($r.Rc -eq 65)
$r = Invoke-L @('-Course', 'https://x.example/c.json'); T 'LC-11-url-rejected' $r ($r.Rc -eq 64)
$r = Invoke-L @('-Course', (Join-Path $c 'link.json')); T 'LC-12-symlink-resolved' $r ($r.Rc -eq 0 -and $r.Course -eq $okR)
$e = @{ GGBPLUS_COURSE_ROOT = $c }
$ra = Invoke-L @('-Course', $ext) $e; $rb = Invoke-L @('-Course', "$c/../outside/ext.json") $e; $rc_ = Invoke-L @('-Course', (Join-Path $c 'esc.json')) $e; $rin = Invoke-L @('-Course', $ok) $e
T 'LC-13-root-abs-dotdot-symlink-escape' $ra ($ra.Rc -eq 77 -and $rb.Rc -eq 77 -and $rc_.Rc -eq 77 -and $rin.Rc -eq 0)
$ra = Invoke-L @() @{ GGBPLUS_COURSE = $ok }; $rb = Invoke-L @('-Course', $sp) @{ GGBPLUS_COURSE = $ok }
T 'LC-14-env-fallback-flag-wins' $ra ($ra.Course -eq $okR -and $rb.Course -eq $sp)
$ra = Invoke-L @('--headless', '-Course', $ok); $rb = Invoke-L @('-Course', $ok, '--headless')
T 'LC-15-flag-order' $ra ($ra.Course -eq $okR -and $rb.Course -eq $okR -and ($ra.Args -contains '-Dggbplus.headless=true') -and ($rb.Args -contains '-Dggbplus.headless=true'))
$r = Invoke-L @('-Course', $evil); T 'LC-16-metachars-literal' $r ($r.Rc -eq 0 -and $r.Course -eq $evil -and -not (Test-Path (Join-Path $w 'PWNED')) -and -not (Test-Path (Join-Path $c 'PWNED')))
$nj = @{ GGB_JAVA = ''; JAVA_HOME = '' }; $ra = Invoke-L @('-Course', (Join-Path $c 'nope.json')) $nj; $rb = Invoke-L @('-Course', $ok) $nj
T 'LC-17-course-error-before-java' $ra ($ra.Rc -eq 66 -and $rb.Rc -eq 4 -and $rb.Out -match 'no Java >= 25')
# real launches under Xvfb
$hasPanel = $false; $hb = Get-ChildItem (Join-Path $script:Image 'bundles') -Filter 'org.geogebra.plus.host*.jar' -ErrorAction SilentlyContinue
foreach ($j in $hb) { if ((& unzip -l $j.FullName 2>$null) -match 'CourseTreePanel') { $hasPanel = $true } }
if (-not $hasPanel) { Skip-Test 'LC-18-xvfb-trig-course-3-panes' 'SKIP reason: image has no CourseTreePanel (Codex X-T4/WP2-06); re-run after image rebuild' 'P1'
    Skip-Test 'LC-19-xvfb-T27-symlink-escape-layering' 'SKIP reason: needs CourseTreePanel + Java OPEN validator (X-T3/X-T4)' 'P1' }
else { $log = Join-Path $script:Res '18_xvfb.log'
    $p = Start-Process xvfb-run -ArgumentList '-a', '-s', '-screen 0 1600x1000x24', 'bash', $launch, '-Course', $trig -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
    for ($i = 0; $i -lt 90 -and -not $p.HasExited; $i++) { Start-Sleep 1; if ((Get-Content $log -Raw -EA SilentlyContinue) -match 'CourseTreePanel') { break } }
    & pkill -f 'ggbplus.runId' 2>$null; Test-Ok 'LC-18-xvfb-trig-course-3-panes' ((Get-Content $log -Raw) -match 'CourseTreePanel') "log=$log" 'P1'
    Skip-Test 'LC-19-xvfb-T27-symlink-escape-layering' 'SKIP reason: Java OPEN validator (X-T3) not yet observable in log' 'P1' }
Remove-Item $w -Recurse -Force -ErrorAction SilentlyContinue
Complete-TestSuite
