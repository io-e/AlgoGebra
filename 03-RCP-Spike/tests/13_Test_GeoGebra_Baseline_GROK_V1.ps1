# GROK_V1 - suite 13 (heavy, opt-in via Run_All -WithBaseline): upstream GeoGebra test baseline at the pinned commit
# (Gradle :common-jre:test and :desktop:test), JUnit XML counted here and compared with Audit_E (Windows) numbers.
# Upstream code is never modified. Env: GGB_SOURCE, GGB_SKIP_GRADLE=1 to only count existing XML reports.
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
foreach ($m in @(@{ id = 'common-jre'; proj = 'shared'; task = ':common-jre:test'; dir = 'shared/common-jre'; win = 'n/a' }, @{ id = 'desktop'; proj = 'desktop'; task = ':desktop:test'; dir = 'desktop/desktop'; win = '1090 tests, 1 locale failure (CallJavaScriptTest.testEval), 1 skipped' })) {
    $log = Join-Path $script:Res "13_$($m.id)_gradle.log"
    $project = Join-Path $src $m.proj
    if (-not (Test-Path $project)) { Exit-Bail "Gradle project directory not found: $project" }
    if ($env:GGB_SKIP_GRADLE -ne '1') {
        Push-Location $repo
        try { & $gw -p $project $m.task --continue --console=plain *> $log; $rc = $LASTEXITCODE }
        finally { Pop-Location }
    } else { $rc = $null; Skip-Test "GGB-$($m.id)-gradle-execution" 'GGB_SKIP_GRADLE=1; counting existing XML only, not a fresh run' 'P0' }
    $j = Get-JUnit (Join-Path $src "$($m.dir)/build/test-results")
    if ($null -ne $rc) { Test-Ok "GGB-$($m.id)-ran" ($rc -eq 0 -and $j.Tests -gt 0) "gradle rc=$rc tests=$($j.Tests) log=$log" 'P0' }
    $testRunOk = ($null -eq $rc -or $rc -eq 0)
    Test-Ok "GGB-$($m.id)-no-failures" ($testRunOk -and $j.Tests -gt 0 -and $j.Fail + $j.Err -eq 0) "gradle rc=$rc passed=$($j.Pass) failures=$($j.Fail) errors=$($j.Err) skipped=$($j.Skip) failed=[$($j.Failed -join ', ')] windows Audit_E: $($m.win)" 'P0' }
Complete-TestSuite
