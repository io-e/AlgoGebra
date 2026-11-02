# GROK_V1 - suite 18: launch -Course contract (design 03-RCP-Spike/docs/Design_LaunchSh_Course_Flag_GROK_V1.md, PR #8).
# ONE cross-platform suite: Linux -> bash launch.sh (PR #9), Windows -> pwsh launch.ps1 -NoBuild (Codex PR #11).
# Merged from Codex's Windows version (PR #11, 16 cases, credit: Codex) and Grok's Debian version (PR #9); Codex cases map to LC-01..LC-15 + LC-20.
# All dry-run cases use GGBPLUS_LAUNCH_DRYRUN=1 (final java argv printed, nothing started).
# Exit codes: 64 usage | 65 not .json / > 1 MiB | 66 missing / not a file | 77 outside GGBPLUS_COURSE_ROOT.
# No usable JDK = 69 (EX_UNAVAILABLE) on both launchers (owner Q1, issue #17, 2026-11-02).
# Platform-only: LC-12/13-symlink need symlink privilege on Windows (else SKIP); LC-17b no-JDK code, LC-18/19 Xvfb = Linux only.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '18_LaunchCourse'
$spike = $script:SpikeDir
$launcher = Join-Path $spike $(if ($IsWindows) { 'launch.ps1' } else { 'launch.sh' })
$fixture = Join-Path (Join-Path (Join-Path $PSScriptRoot 'fixtures') '.') 'course-tree-trig-smoke.json'
if (-not (Test-Path $fixture)) { $fixture = Join-Path (Split-Path $spike -Parent) (Join-Path 'courses' 'trigonometry_intro.json') }
foreach ($p in $launcher, $fixture) { if (-not (Test-Path $p)) { Exit-Bail "missing: $p" } }
if ($IsWindows) {
    $ready = (Test-Path (Join-Path $spike 'bundles')) -and (Test-Path (Join-Path $spike 'launcher')) -and (Test-Path (Join-Path $spike 'natives'))
    if (-not $ready) { Skip-Test 'LC-all' 'SKIP reason: launch.ps1 dry-run needs staged RCP jars (bundles/launcher/natives) in 03-RCP-Spike' 'P0'; Complete-TestSuite }
    $j25 = $null
} else {
    $j25 = if ($env:J25) { $env:J25 } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-25*' -EA SilentlyContinue | Select-Object -First 1).FullName }
    if (-not $j25) { Exit-Bail 'no JDK 25 (set J25)' }
}
$w = Join-Path ([IO.Path]::GetTempPath()) "grok18-$PID"; $img = Join-Path $w 'image'; $c = Join-Path $w 'courses'; $out = Join-Path $w 'outside'
New-Item -ItemType Directory -Force (Join-Path $img 'bundles'), $c, $out, (Join-Path $w 'home'), (Join-Path $c 'a dir') | Out-Null
$ok = Join-Path $c 'ok.json'; Copy-Item -LiteralPath $fixture $ok; $sp = Join-Path (Join-Path $c 'a dir') 'my course.json'; Copy-Item -LiteralPath $fixture $sp
$ext = Join-Path $out 'ext.json'; Copy-Item -LiteralPath $fixture $ext; Set-Content (Join-Path $c 'c.ggb') 'x'; Set-Content (Join-Path $c 'c.txt') 'x'
$big = Join-Path $c 'big.json'; [IO.File]::WriteAllBytes($big, [byte[]]::new(1MB + 1))
$dirJson = Join-Path $c 'directory.json'; New-Item -ItemType Directory -Force $dirJson | Out-Null
$canLink = $true
foreach ($l in @(@('link.json', $ok), @('esc.json', $ext))) {
    try { New-Item -ItemType SymbolicLink -Path (Join-Path $c $l[0]) -Target $l[1] -EA Stop | Out-Null } catch { $canLink = $false } }
$evil = Join-Path $c 'x$(touch PWNED);y.json'; Copy-Item -LiteralPath $fixture -Destination $evil
function Invoke-L([string[]]$A, [hashtable]$Env = @{}) {
    $base = @{ GGBPLUS_LAUNCH_DRYRUN = '1'; GGBPLUS_COURSE = ''; GGBPLUS_COURSE_ROOT = '' }
    if (-not $IsWindows) { $base += @{ HOME = (Join-Path $w 'home'); PATH = '/usr/bin:/bin'; IMAGE = $img; GGB_JAVA = "$j25/bin/java" } }
    foreach ($k in $Env.Keys) { $base[$k] = $Env[$k] }
    Push-Location $w
    try {
        if ($IsWindows) {
            $saved = @{}; foreach ($k in $base.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $(if ($base[$k] -eq '') { $null } else { $base[$k] })) }
            try { $o = (& pwsh -NoProfile -File $launcher -NoBuild @A 2>&1 | Out-String); $rc = $LASTEXITCODE }
            finally { foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) } }
        } else {
            $ea = @('-i') + @($base.GetEnumerator() | Where-Object { $_.Value -ne '' } | ForEach-Object { "$($_.Key)=$($_.Value)" })
            $o = (& env @ea bash $launcher @A 2>&1 | Out-String); $rc = $LASTEXITCODE
        }
    } finally { Pop-Location }
    # launch.sh prints "ARG <x>" lines, launch.ps1 prints "  <x>" lines after the dry-run banner
    $argv = @($o -split "`r?`n" | ForEach-Object { if ($_ -like 'ARG *') { $_.Substring(4) } elseif ($_ -match '^  (-\S.*)$') { $Matches[1] } })
    $cp = @($argv | Where-Object { $_ -like '-Dggbplus.course=*' })
    [pscustomobject]@{ Rc = $rc; Out = $o.Trim(); Course = $(if ($cp.Count) { $cp[0].Substring(17) } else { $null }); NCourse = $cp.Count; Args = $argv } }
function Real([string]$p) { $i = Get-Item -LiteralPath $p -Force; $t = $i.ResolveLinkTarget($true); [IO.Path]::GetFullPath($(if ($t) { $t.FullName } else { $i.FullName })) }
function Same([string]$a, [string]$b) { if ($IsWindows) { $a -ieq $b } else { $a -ceq $b } }
function T([string]$Id, $r, [bool]$Cond, [string]$Pr = 'P0') { Test-Ok $Id $Cond "rc=$($r.Rc) course=[$($r.Course)] out=[$((($r.Out -split "`r?`n") | Where-Object { $_ -notlike 'ARG *' -and $_ -notmatch '^  -' } | Select-Object -Last 3) -join ' | ')]" $Pr }
$okR = Real $ok; $spR = Real $sp; $hl = if ($IsWindows) { '-Headless' } else { '--headless' }
$r = Invoke-L @(); T 'LC-01-no-flag-no-property' $r ($r.Rc -eq 0 -and $r.NCourse -eq 0)
$r = Invoke-L @('-Course', (Join-Path 'courses' 'ok.json')); T 'LC-02-relative-to-abs-realpath' $r ($r.Rc -eq 0 -and (Same $r.Course $okR))
$r = Invoke-L @("--course=$ok"); T 'LC-03-long-eq-form' $r ($r.Rc -eq 0 -and (Same $r.Course $okR))
$r = Invoke-L @('--course', $sp); T 'LC-04-path-with-spaces-one-arg' $r ($r.Rc -eq 0 -and (Same $r.Course $spR))
$r = Invoke-L @('-Course'); T 'LC-05-missing-value-64' $r ($r.Rc -eq 64)
$r = Invoke-L @('-Course', $ok, '--course', $ok); T 'LC-06-repeated-flag-64' $r ($r.Rc -eq 64)
$r = Invoke-L @('-Course', (Join-Path $c 'nope.json')); T 'LC-07-missing-file-66' $r ($r.Rc -eq 66)
$r1 = Invoke-L @('-Course', $c); $r2 = Invoke-L @('-Course', $dirJson); T 'LC-08-directory-66' $r1 ($r1.Rc -eq 66 -and $r2.Rc -eq 66)
$r1 = Invoke-L @('-Course', (Join-Path $c 'c.ggb')); $r2 = Invoke-L @('-Course', (Join-Path $c 'c.txt')); T 'LC-09-wrong-extension-65' $r1 ($r1.Rc -eq 65 -and $r2.Rc -eq 65)
$r = Invoke-L @('-Course', $big); T 'LC-10-over-1MiB-65' $r ($r.Rc -eq 65)
$r = Invoke-L @('-Course', 'https://example.org/course.json'); T 'LC-11-url-64' $r ($r.Rc -eq 64)
if ($canLink) { $r = Invoke-L @('-Course', (Join-Path $c 'link.json')); T 'LC-12-symlink-resolved' $r ($r.Rc -eq 0 -and (Same $r.Course $okR)) }
else { Skip-Test 'LC-12-symlink-resolved' 'SKIP reason: cannot create symlinks (Windows needs Developer Mode or admin)' 'P1' }
$e = @{ GGBPLUS_COURSE_ROOT = $c }
$ra = Invoke-L @('-Course', $ext) $e; $rb = Invoke-L @('-Course', (Join-Path (Join-Path $c '..') (Join-Path 'outside' 'ext.json'))) $e; $rin = Invoke-L @('-Course', $ok) $e
$rr = Invoke-L @('-Course', $ok) @{ GGBPLUS_COURSE_ROOT = $out }
T 'LC-13-root-abs-dotdot-escape-77-inside-ok' $ra ($ra.Rc -eq 77 -and $rb.Rc -eq 77 -and $rr.Rc -eq 77 -and $rin.Rc -eq 0)
if ($canLink) { $r = Invoke-L @('-Course', (Join-Path $c 'esc.json')) $e; T 'LC-13b-root-symlink-escape-77' $r ($r.Rc -eq 77) }
else { Skip-Test 'LC-13b-root-symlink-escape-77' 'SKIP reason: cannot create symlinks' 'P1' }
$ra = Invoke-L @() @{ GGBPLUS_COURSE = $ok }; $rb = Invoke-L @('-Course', $sp) @{ GGBPLUS_COURSE = $ok }
T 'LC-14-env-fallback-flag-wins' $ra ((Same $ra.Course $okR) -and (Same $rb.Course $spR))
$ra = Invoke-L @($hl, '-Course', $ok); $rb = Invoke-L @('-Course', $ok, $hl)
T 'LC-15-flag-order' $ra ((Same $ra.Course $okR) -and (Same $rb.Course $okR) -and ($ra.Args -contains '-Dggbplus.headless=true') -and ($rb.Args -contains '-Dggbplus.headless=true'))
$r = Invoke-L @('-Course', $evil); T 'LC-16-metachars-literal' $r ($r.Rc -eq 0 -and (Same $r.Course (Real $evil)) -and -not (Test-Path (Join-Path $w 'PWNED')) -and -not (Test-Path (Join-Path $c 'PWNED')))
if ($IsWindows) {
    $r = Invoke-L @('-JavaHome', (Join-Path $w 'nojdk'), '-Course', (Join-Path $c 'nope.json')); T 'LC-17-course-error-before-java' $r ($r.Rc -eq 66)
    # launch.ps1 can only be forced to "no JDK" when neither <image>\jre nor the hard-coded Eclipse JustJ plugin exists (no launch.ps1 change).
    $bundled = Join-Path $script:Image 'jre\bin\java.exe'; $justj = 'D:\ALF_ZGit\G2_Eclipse\01_src\eclipse\plugins'
    $hasJustj = (Test-Path -LiteralPath $justj) -and @(Get-ChildItem $justj -Directory -Filter 'org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4*' -EA SilentlyContinue).Count -gt 0
    if ((Test-Path -LiteralPath $bundled) -or $hasJustj) {
        Skip-Test 'LC-17b-no-jdk-exit-code-69' 'SKIP reason: launch.ps1 falls back to bundled jre or Eclipse JustJ JRE present on this host; cannot force no-JDK without changing launch.ps1' 'P1'
    } else {
        $rb = Invoke-L @('-JavaHome', (Join-Path $w 'nojdk'), '-Course', $ok) @{ JAVA = '' }
        T 'LC-17b-no-jdk-exit-code-69' $rb ($rb.Rc -eq 69) 'P1'
    }
} else {
    $nj = @{ GGB_JAVA = '' }; $ra = Invoke-L @('-Course', (Join-Path $c 'nope.json')) $nj; $rb = Invoke-L @('-Course', $ok) $nj
    T 'LC-17-course-error-before-java' $ra ($ra.Rc -eq 66)
    T 'LC-17b-no-jdk-exit-code-69' $rb ($rb.Rc -eq 69 -and $rb.Out -match 'no Java >= 25') 'P1'
}
if ($IsWindows) {
    Skip-Test 'LC-18-xvfb-trig-course-3-panes' 'SKIP reason: Linux/Xvfb only; attended SWT tree UI stays Windows/owner' 'P1'
    Skip-Test 'LC-19-xvfb-T27-symlink-escape-layering' 'SKIP reason: Linux/Xvfb only' 'P1'
} else {
    $hasPanel = $false
    foreach ($j in (@('bundles', 'host/build') | ForEach-Object { Get-ChildItem (Join-Path $script:Image $_) -Filter 'org.geogebra.plus.host*.jar' -EA SilentlyContinue })) { if ((& unzip -l $j.FullName 2>$null) -match 'CourseTreePanel') { $hasPanel = $true } }
    if (-not $hasPanel) { Skip-Test 'LC-18-xvfb-trig-course-3-panes' "SKIP reason: image has no CourseTreePanel ($($script:Image))" 'P1'
        Skip-Test 'LC-19-xvfb-T27-symlink-escape-layering' 'SKIP reason: needs CourseTreePanel + Java OPEN validator' 'P1' }
    else { $log = Join-Path $script:Res '18_xvfb.log'
        $p = Start-Process xvfb-run -ArgumentList @('-a', '-s', '"-screen 0 1600x1000x24"', 'env', "IMAGE=$($script:Image)", "GGB_JAVA=$j25/bin/java", 'bash', $launcher, '-Course', $fixture) -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
        for ($i = 0; $i -lt 90 -and -not $p.HasExited; $i++) { Start-Sleep 1; if ("$(Get-Content $log -Raw -EA SilentlyContinue)" -match 'Course loaded') { break } }
        & pkill -f 'ggbplus.runId' 2>$null
        Test-Ok 'LC-18-xvfb-trig-course-3-panes' ("$(Get-Content $log -Raw)" -match 'Course loaded: .*\(\d+ chapters') "log=$log" 'P1'
        Skip-Test 'LC-19-xvfb-T27-symlink-escape-layering' 'SKIP reason: Java OPEN validator rejection not yet observable in the product log' 'P1' }
}
# LC-20 (Codex): env points to a MISSING file but the flag wins (env is not validated when -Course is given)
$r = Invoke-L @('-Course', $ok) @{ GGBPLUS_COURSE = (Join-Path $w 'missing-env.json') }; T 'LC-20-flag-wins-over-invalid-env' $r ($r.Rc -eq 0 -and (Same $r.Course $okR))
Remove-Item $w -Recurse -Force -ErrorAction SilentlyContinue
Complete-TestSuite
