# GROK_V1 - suite 20: GeoGebra-backed Java corpus test (host/test/.../CourseCorpusRealValidatorTest_GROK_V1.java).
# Compiles host/src/org/geogebra/plus/course + the test against the image jars (same convention as test-course-model.ps1:
# plain javac/java, no Gradle/JUnit in the RCP spike) and runs the WP9-03 corpus through the REAL StepValidator with a
# headless GeoGebra kernel (AppDNoGui). XFAIL cases (tracked issues, e.g. #21) are reported as TODO, not failures.
# Env: IMAGE (image with bundles/ + platform/), JAVA_HOME or J25 (JDK >= 21).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '20_CourseValidatorJava'
$jh = if ($env:J25) { $env:J25 } elseif ($env:JAVA_HOME) { $env:JAVA_HOME } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-25*' -EA SilentlyContinue | Select-Object -First 1).FullName }
$x = if ($IsWindows) { '.exe' } else { '' }; $javac = Join-Path $jh "bin/javac$x"; $java = Join-Path $jh "bin/java$x"
# Run_All auto-discovers this suite; without a JDK or image jars it SKIPs (not BAIL) so plain runs stay green. GGB_SKIP_JAVA_CORPUS=1 opts out.
if ($env:GGB_SKIP_JAVA_CORPUS -eq '1') { Skip-Test 'JV-00-compile' 'SKIP reason: GGB_SKIP_JAVA_CORPUS=1' 'P1'; Complete-TestSuite; return }
if (-not (Test-Path $javac)) { Skip-Test 'JV-00-compile' "SKIP reason: no javac under '$jh' (set J25 or JAVA_HOME)" 'P1'; Complete-TestSuite; return }
$jars = @('bundles', 'platform') | ForEach-Object { Get-ChildItem (Join-Path $script:Image $_) -Filter '*.jar' -EA SilentlyContinue } | Where-Object Name -notlike 'org.geogebra.plus.host*'
if (-not $jars -or -not ($jars | Where-Object Name -like 'org.geogebra.migration.desktop-*')) { Skip-Test 'JV-00-compile' "SKIP reason: no GeoGebra image jars under $($script:Image) (set IMAGE)" 'P1'; Complete-TestSuite; return }
$cp = ($jars.FullName -join [IO.Path]::PathSeparator); $out = Join-Path $script:Tmp "grok20-$PID"; New-Item -ItemType Directory -Force $out | Out-Null
$src = @(Get-ChildItem (Join-Path $script:SpikeDir 'host/src/org/geogebra/plus/course') -Filter '*.java').FullName + (Join-Path $script:SpikeDir 'host/test/org/geogebra/plus/course/CourseCorpusRealValidatorTest_GROK_V1.java')
$c = (& $javac --release 21 -encoding UTF-8 -cp $cp -d $out @src 2>&1 | Out-String); Test-Ok 'JV-00-compile' ($LASTEXITCODE -eq 0) "javac rc=$LASTEXITCODE $($c.Trim())" 'P0'
if ($LASTEXITCODE -ne 0) { Complete-TestSuite; return }
$lines = @(& $java -cp ($out + [IO.Path]::PathSeparator + $cp) org.geogebra.plus.course.CourseCorpusRealValidatorTest_GROK_V1 (Join-Path $script:Fix 'course-security') 2>&1 | ForEach-Object { "$_" })
foreach ($l in $lines) {
    if ($l -match '^(not ok|ok) \d+ - (\S+) # TODO XFAIL (.*)$') { Skip-Test "JV-$($Matches[2])" "XFAIL $($Matches[3])" 'P0' }
    elseif ($l -match '^ok \d+ - (\S+) # XPASS (.*)$') { Test-Ok "JV-$($Matches[1])" $true "XPASS (remove from XFAIL): $($Matches[2])" 'P0' }
    elseif ($l -match '^ok \d+ - (\S+) :: (.*)$') { Test-Ok "JV-$($Matches[1])" $true $Matches[2] 'P0' }
    elseif ($l -match '^not ok \d+ - (\S+) :: (.*)$') { Test-Ok "JV-$($Matches[1])" $false $Matches[2] 'P0' }
    elseif ($l -match 'CourseCorpusRealValidatorTest_GROK_V1: ') { Write-Host "# $l" } }
Test-Ok 'JV-99-summary' (@($lines | Where-Object { $_ -match 'CourseCorpusRealValidatorTest_GROK_V1: \d+ PASS, 0 FAIL' }).Count -eq 1) ($lines | Select-Object -Last 1) 'P0'
Remove-Item $out -Recurse -Force -EA SilentlyContinue
Complete-TestSuite
