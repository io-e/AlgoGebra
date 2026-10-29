[CmdletBinding()]
param(
    [string]$JavaHome
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Build = Join-Path $Root 'build.ps1'
& $Build -JavaHome $JavaHome
if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed with exit code $LASTEXITCODE" }

if (-not $JavaHome) {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin\javac.exe'))) {
        $JavaHome = $env:JAVA_HOME
    } else {
        $JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
    }
}
$Javac = Join-Path $JavaHome 'bin\javac.exe'
$Java = Join-Path $JavaHome 'bin\java.exe'
if (-not (Test-Path -LiteralPath $Javac) -or -not (Test-Path -LiteralPath $Java)) {
    throw "JDK 21 javac/java not found under $JavaHome"
}

$OutputDir = Join-Path $Root 'host\build'
$ApiJar = Get-ChildItem -LiteralPath $OutputDir -Filter 'org.geogebra.plus.compute.api_*.jar' -File | Select-Object -First 1
$RuntimeJar = Get-ChildItem -LiteralPath $OutputDir -Filter 'org.geogebra.plus.compute.runtime_*.jar' -File | Select-Object -First 1
$PariJar = Get-ChildItem -LiteralPath $OutputDir -Filter 'org.geogebra.plus.engine.pari_*.jar' -File | Select-Object -First 1
$MaximaJar = Get-ChildItem -LiteralPath $OutputDir -Filter 'org.geogebra.plus.engine.maxima_*.jar' -File | Select-Object -First 1
$GnuplotJar = Get-ChildItem -LiteralPath $OutputDir -Filter 'org.geogebra.plus.engine.gnuplot_*.jar' -File | Select-Object -First 1
if (-not $ApiJar -or -not $RuntimeJar -or -not $PariJar -or -not $MaximaJar -or -not $GnuplotJar) {
    throw 'One or more external compute engine bundles were not produced by build.ps1.'
}

$Tests = @(Get-ChildItem -LiteralPath (Join-Path $Root 'engines') -Filter '*.java' -Recurse -File |
    Where-Object { $_.FullName -match '[\\/]test[\\/]' } | ForEach-Object FullName)
if ($Tests.Count -eq 0) { throw 'No external engine test sources were found.' }
$TestClasses = Join-Path $OutputDir 'engine-test-classes'
New-Item -ItemType Directory -Path $TestClasses -Force | Out-Null
$EngineClasspath = @($ApiJar.FullName, $RuntimeJar.FullName, $PariJar.FullName,
    $MaximaJar.FullName, $GnuplotJar.FullName) -join ';'
& $Javac -encoding UTF-8 --release 21 -cp $EngineClasspath -d $TestClasses @Tests
if ($LASTEXITCODE -ne 0) { throw "External engine test compilation failed with exit code $LASTEXITCODE" }

$TestClasspath = @($TestClasses, $ApiJar.FullName, $RuntimeJar.FullName, $PariJar.FullName,
    $MaximaJar.FullName, $GnuplotJar.FullName) -join ';'
& $Java -cp $TestClasspath org.geogebra.plus.engine.tests.EngineAcceptanceTest
if ($LASTEXITCODE -ne 0) { throw "External engine tests failed with exit code $LASTEXITCODE" }
