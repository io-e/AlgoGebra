[CmdletBinding()]
param(
    [string]$JavaHome,
    [string]$BundleRoot
)

$ErrorActionPreference = 'Stop'
$SpikeRoot = $PSScriptRoot
$CourseSource = Join-Path $SpikeRoot 'host\src\org\geogebra\plus\course'
$CourseTests = Join-Path $SpikeRoot 'host\test\org\geogebra\plus\course\CourseModelTest.java'
$PolicyTests = Join-Path $SpikeRoot 'host\test\org\geogebra\plus\course\StepValidatorPolicyTest.java'
$BundleRoot = if ($BundleRoot) { $BundleRoot } else { $SpikeRoot }
$JarRoots = @((Join-Path $BundleRoot 'bundles'), (Join-Path $BundleRoot 'platform'))

if (-not $JavaHome) {
    $JavaHome = $env:JAVA_HOME
}

if ($JavaHome) {
    $IsWindowsPlatform = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $ExeSuffix = if ($IsWindowsPlatform) { '.exe' } else { '' }
    $Javac = Join-Path $JavaHome "bin\javac$ExeSuffix"
    $Java = Join-Path $JavaHome "bin\java$ExeSuffix"
    if (-not (Test-Path -LiteralPath $Javac) -or -not (Test-Path -LiteralPath $Java)) {
        throw "Java tools were not found under JavaHome '$JavaHome'."
    }
} else {
    $JavacCommand = Get-Command javac -ErrorAction Stop
    $JavaCommand = Get-Command java -ErrorAction Stop
    $Javac = $JavacCommand.Source
    $Java = $JavaCommand.Source
}

if (-not (Test-Path -LiteralPath $CourseTests) -or -not (Test-Path -LiteralPath $PolicyTests)) {
    throw "Course tests not found: $CourseTests / $PolicyTests"
}
$Sources = @(Get-ChildItem -LiteralPath $CourseSource -Filter '*.java' -File)
if ($Sources.Count -eq 0) {
    throw "No course model sources found in '$CourseSource'."
}

$TempRoot = Join-Path ([IO.Path]::GetTempPath()) 'GeoGebraPlus-CourseModelTests'
$OutputDir = Join-Path $TempRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

try {
    $Jars = @($JarRoots | Where-Object { Test-Path -LiteralPath $_ } |
        ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter '*.jar' -File })
    if ($Jars.Count -eq 0) {
        throw 'GeoGebra/Eclipse bundle JARs were not found; course policy tests cannot compile.'
    }
    $Classpath = ($Jars.FullName -join [IO.Path]::PathSeparator)
    $CompileArgs = @('--release', '21', '-Xlint:all', '-encoding', 'UTF-8', '-cp', $Classpath, '-d', $OutputDir)
    $CompileArgs += @($Sources | ForEach-Object FullName)
    $CompileArgs += @($CourseTests, $PolicyTests)
    & $Javac @CompileArgs
    if ($LASTEXITCODE -ne 0) {
        throw "javac failed with exit code $LASTEXITCODE."
    }

    $RuntimeClasspath = $OutputDir + [IO.Path]::PathSeparator + $Classpath
    $SmokeFixture = Join-Path $SpikeRoot 'tests\fixtures\course-tree-trig-smoke.json'
    & $Java '-ea' '-cp' $RuntimeClasspath 'org.geogebra.plus.course.CourseModelTest' $SmokeFixture
    if ($LASTEXITCODE -ne 0) {
        throw "CourseModelTest failed with exit code $LASTEXITCODE."
    }
    & $Java '-ea' '-cp' $RuntimeClasspath 'org.geogebra.plus.course.StepValidatorPolicyTest'
    if ($LASTEXITCODE -ne 0) {
        throw "StepValidatorPolicyTest failed with exit code $LASTEXITCODE."
    }
} finally {
    if (Test-Path -LiteralPath $OutputDir) {
        $TempRootFull = [IO.Path]::GetFullPath($TempRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $OutputFull = [IO.Path]::GetFullPath($OutputDir)
        $SafePrefix = $TempRootFull + [IO.Path]::DirectorySeparatorChar
        if (-not $OutputFull.StartsWith($SafePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete temporary path outside the test directory: $OutputFull"
        }
        Remove-Item -LiteralPath $OutputFull -Recurse -Force
    }
}
