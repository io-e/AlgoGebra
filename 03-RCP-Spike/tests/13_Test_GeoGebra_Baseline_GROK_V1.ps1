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
$gw = if ($IsWindows) { Join-Path $src 'gradlew.bat' } else { Join-Path $src 'gradlew' }
foreach ($m in @(@{ id = 'common-jre'; proj = 'shared'; task = ':common-jre:test'; dir = 'shared/common-jre'; win = 'n/a' }, @{ id = 'desktop'; proj = 'desktop'; task = ':desktop:test'; dir = 'desktop/desktop'; win = '1090 tests, 1 locale failure (CallJavaScriptTest.testEval), 1 skipped' })) {
    $log = Join-Path $script:Res "13_$($m.id)_gradle.log"
    if ($env:GGB_SKIP_GRADLE -ne '1') { Push-Location (Join-Path $src $m.proj); & $gw $m.task --continue --console=plain *> $log; $rc = $LASTEXITCODE; Pop-Location } else { $rc = 'skipped' }
    $j = Get-JUnit (Join-Path $src "$($m.dir)/build/test-results")
    Test-Ok "GGB-$($m.id)-ran" ($j.Tests -gt 0) "gradle rc=$rc tests=$($j.Tests) log=$log" 'P0'
    Test-Ok "GGB-$($m.id)-no-failures" ($j.Tests -gt 0 -and $j.Fail + $j.Err -eq 0) "passed=$($j.Pass) failures=$($j.Fail) errors=$($j.Err) skipped=$($j.Skip) failed=[$($j.Failed -join ', ')] windows Audit_E: $($m.win)" 'P0' }
Complete-TestSuite
