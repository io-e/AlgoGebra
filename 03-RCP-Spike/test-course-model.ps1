[CmdletBinding()]
param(
    [string]$JavaHome
)

$ErrorActionPreference = 'Stop'
$SpikeRoot = $PSScriptRoot
$CourseSource = Join-Path $SpikeRoot 'host\src\org\geogebra\plus\course'
$CourseTests = Join-Path $SpikeRoot 'host\test\org\geogebra\plus\course\CourseModelTest.java'

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

if (-not (Test-Path -LiteralPath $CourseTests)) {
    throw "Course model tests not found: $CourseTests"
}
$Sources = @(Get-ChildItem -LiteralPath $CourseSource -Filter '*.java' -File)
if ($Sources.Count -eq 0) {
    throw "No course model sources found in '$CourseSource'."
}

$TempRoot = Join-Path ([IO.Path]::GetTempPath()) 'GeoGebraPlus-CourseModelTests'
$OutputDir = Join-Path $TempRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

try {
    $CompileArgs = @('--release', '21', '-Xlint:all', '-encoding', 'UTF-8', '-d', $OutputDir)
    $CompileArgs += @($Sources | ForEach-Object FullName)
    $CompileArgs += $CourseTests
    & $Javac @CompileArgs
    if ($LASTEXITCODE -ne 0) {
        throw "javac failed with exit code $LASTEXITCODE."
    }

    & $Java '-ea' '-cp' $OutputDir 'org.geogebra.plus.course.CourseModelTest'
    if ($LASTEXITCODE -ne 0) {
        throw "CourseModelTest failed with exit code $LASTEXITCODE."
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
