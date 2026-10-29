# GROK_V1 - suite 13 (heavy, opt-in via Run_All -WithBaseline): upstream GeoGebra test baseline at the pinned commit
# (Gradle :common-jre:test and :desktop:test), JUnit XML counted here and compared with Audit_E (Windows) numbers.
# Upstream code is never modified. Env: GGB_SOURCE, GGB_SKIP_GRADLE=1 to only count existing XML reports,
# GGB_RERUN_TASKS=1 forces only the test task to execute again (Gradle task option --rerun: build-logic outputs are reused, not
# deleted); GGB_RERUN_TASKS=all uses --rerun-tasks (rebuilds build-logic too). GGB_PROJECT_CACHE_DIR=<dir> -> --project-cache-dir.
# Pre-flight (BUG-020): files under build-logic/**/build and the module build dirs that cannot be opened exclusively are listed
# with the java processes whose command line mentions the clone; nothing is killed. GGB_LOCK_IGNORE=1 runs Gradle anyway.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '13_GeoGebra_Baseline'
$src = if ($env:GGB_SOURCE) { $env:GGB_SOURCE } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\source' } else { '/workspace/AlgoGebra/geogebra/source' }
if (-not (Test-Path $src)) { Exit-Bail "GeoGebra source not found: $src" }
$pin = '375db7faf5407390bb322165f2414415da8faeda'; $head = (& git -C $src rev-parse HEAD 2>$null)
Test-Ok 'GGB-00-pinned-commit' ($head -eq $pin) "HEAD=$head pin=$pin" 'P0'
function Get-JUnit([string]$Dir) { $t = 0; $f = 0; $e = 0; $s = 0; $failed = @()
    foreach ($x in Get-ChildItem $Dir -Filter 'TEST-*.xml' -Recurse -ErrorAction SilentlyContinue) { [xml]$d = Get-Content $x.FullName -Raw; $ts = $d.testsuite
        $t += [int]$ts.tests; $f += [int]$ts.failures; $e += [int]$ts.errors; $s += [int]$ts.skipped
        foreach ($c in $ts.testcase) { if ($c.failure -or $c.error) { $failed += "$($c.classname).$($c.name)" } } }
    return [pscustomobject]@{ Tests = $t; Fail = $f; Err = $e; Skip = $s; Pass = $t - $f - $e - $s; Failed = $failed } }
$repo = Split-Path $src -Parent
$gwName = if ($IsWindows) { 'gradlew.bat' } else { 'gradlew' }
$gw = Join-Path $src $gwName
if (-not (Test-Path $gw)) { $gw = Join-Path $repo $gwName }
if (-not (Test-Path $gw)) { Exit-Bail "Gradle wrapper not found under source or repository root: $gw" }
# ---- pre-flight: locked build outputs (BUG-020) ----
function Find-LockedFiles([string[]]$Dirs, [int]$Max = 15) { $hits = @()
    foreach ($d in $Dirs) { if (-not (Test-Path $d)) { continue }
        foreach ($f in Get-ChildItem $d -Recurse -File -Force -ErrorAction SilentlyContinue) {
            try { $fs = [IO.File]::Open($f.FullName, 'Open', 'ReadWrite', 'None'); $fs.Dispose() } catch { $hits += "$($f.FullName) [$($_.Exception.InnerException.Message ?? $_.Exception.Message)]"; if ($hits.Count -ge $Max) { return $hits } } } }
    return $hits }
$lockDirs = @(Get-ChildItem (Join-Path $src 'build-logic') -Directory -Recurse -Filter build -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/]src[\\/]' } | ForEach-Object FullName) + @((Join-Path $src 'shared/common-jre/build'), (Join-Path $src 'desktop/desktop/build'))
$locked = @(if ($IsWindows) { Find-LockedFiles $lockDirs } else { @() })
$javaProcs = @(if ($IsWindows) { Get-CimInstance Win32_Process -Filter "Name='java.exe' or Name='javaw.exe'" -ErrorAction SilentlyContinue | ForEach-Object { $cl = "$($_.CommandLine)"; [pscustomobject]@{ Pid = $_.ProcessId; Mentions = ($cl -like "*$repo*" -or $cl -like "*$($repo.Replace('\','/'))*"); Cmd = $(if ($cl.Length -gt 160) { $cl.Substring(0, 160) + '...' } else { $cl }) } } }
    else { & pgrep -a java 2>$null | ForEach-Object { $pp, $cl = "$_" -split ' ', 2; [pscustomobject]@{ Pid = $pp; Mentions = ($cl -like "*$repo*"); Cmd = $(if ($cl.Length -gt 160) { $cl.Substring(0, 160) + '...' } else { $cl }) } } })
foreach ($j in $javaProcs) { Write-Host "# java pid=$($j.Pid) mentionsClone=$($j.Mentions) cmd=$($j.Cmd)" }
$suspects = @($javaProcs | Where-Object Mentions | ForEach-Object { "pid $($_.Pid)" })
if ($locked.Count -gt 0) { foreach ($l in $locked) { Write-Host "# LOCKED: $l" -ForegroundColor Yellow }
    $msg = "locked build outputs: $($locked.Count)+ (first: $($locked[0])); java processes mentioning the clone: [$($suspects -join ', ')] (others listed above, e.g. IDE language servers; nothing killed). Close them / exclude the folder from Defender or indexer, or GGB_LOCK_IGNORE=1"
    if ($env:GGB_LOCK_IGNORE -ne '1') { Block-Test 'GGB-00b-build-dir-not-locked' $msg 'P0'; Complete-TestSuite }
    Write-Host "# GGB_LOCK_IGNORE=1: $msg" }
else { Test-Ok 'GGB-00b-build-dir-not-locked' $true "checked $($lockDirs.Count) build dirs$(if (-not $IsWindows) { ' (Linux: no mandatory locks; check informational)' }); java mentioning clone: [$($suspects -join ', ')]" 'P1' }
foreach ($m in @(@{ id = 'common-jre'; proj = 'shared'; task = ':common-jre:test'; dir = 'shared/common-jre'; win = 'n/a' }, @{ id = 'desktop'; proj = 'desktop'; task = ':desktop:test'; dir = 'desktop/desktop'; win = '1090 tests, 1 locale failure (CallJavaScriptTest.testEval), 1 skipped' })) {
    $log = Join-Path $script:Res "13_$($m.id)_gradle.log"
    $project = Join-Path $src $m.proj
    if (-not (Test-Path $project)) { Exit-Bail "Gradle project directory not found: $project" }
    if ($env:GGB_SKIP_GRADLE -ne '1') {
        $gradleArgs = @()
        $taskArgs = @($m.task); if ($env:GGB_RERUN_TASKS -eq '1') { $taskArgs += '--rerun' } elseif ($env:GGB_RERUN_TASKS -eq 'all') { $gradleArgs += '--rerun-tasks' }
        if ($env:GGB_PROJECT_CACHE_DIR) { $gradleArgs += @('--project-cache-dir', $env:GGB_PROJECT_CACHE_DIR) }
        Write-Host "# gradle -p $project $($taskArgs -join ' ') $($gradleArgs -join ' ')"
        Push-Location $repo
        try { & $gw -p $project @taskArgs @gradleArgs --continue --console=plain *> $log; $rc = $LASTEXITCODE }
        finally { Pop-Location }
    } else { $rc = $null; Skip-Test "GGB-$($m.id)-gradle-execution" 'GGB_SKIP_GRADLE=1; counting existing XML only, not a fresh run' 'P0' }
    $j = Get-JUnit (Join-Path $src "$($m.dir)/build/test-results")
    if ($null -ne $rc) { Test-Ok "GGB-$($m.id)-ran" ($rc -eq 0 -and $j.Tests -gt 0) "gradle rc=$rc tests=$($j.Tests) log=$log" 'P0' }
    $testRunOk = ($null -eq $rc -or $rc -eq 0)
    Test-Ok "GGB-$($m.id)-no-failures" ($testRunOk -and $j.Tests -gt 0 -and $j.Fail + $j.Err -eq 0) "gradle rc=$rc passed=$($j.Pass) failures=$($j.Fail) errors=$($j.Err) skipped=$($j.Skip) failed=[$($j.Failed -join ', ')] windows Audit_E: $($m.win)" 'P0' }
Complete-TestSuite
