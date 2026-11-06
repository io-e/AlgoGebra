[CmdletBinding()]
param(
    [string]$JavaHome,
    [ValidateSet('all', 'unit', 'cycle')]
    [string]$Mode = 'all'
)

$ErrorActionPreference = 'Stop'
$SpikeRoot = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $SpikeRoot 'host\src\org\geogebra\plus\wims'
$TestSource = Join-Path $SpikeRoot 'host\test\org\geogebra\plus\wims\HttpWimsClientTest.java'
$Fixtures = Join-Path $SpikeRoot 'tests\fixtures\wims-live'

if (-not $JavaHome) { $JavaHome = $env:JAVA_HOME }
if ($JavaHome) {
    $suffix = if ($IsWindows) { '.exe' } else { '' }
    $Javac = Join-Path $JavaHome "bin\javac$suffix"
    $Java = Join-Path $JavaHome "bin\java$suffix"
    if (-not (Test-Path -LiteralPath $Javac) -or -not (Test-Path -LiteralPath $Java)) {
        throw "Java tools were not found under JavaHome '$JavaHome'."
    }
} else {
    $Javac = (Get-Command javac -CommandType Application -ErrorAction Stop).Source
    $Java = (Get-Command java -CommandType Application -ErrorAction Stop).Source
}

if (-not (Test-Path -LiteralPath $TestSource)) { throw "WIMS client test source not found: $TestSource" }
if (-not (Test-Path -LiteralPath $Fixtures)) { throw "WIMS fixture directory not found: $Fixtures" }
$Sources = @(Get-ChildItem -LiteralPath $SourceDir -Filter '*.java' -File |
    ForEach-Object FullName)
if ($Sources.Count -eq 0) { throw "No WIMS Java sources found under '$SourceDir'." }

$TempRoot = Join-Path ([IO.Path]::GetTempPath()) 'GeoGebraPlus-WimsClientTests'
$OutputDir = Join-Path $TempRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
try {
    $CompileArgs = @('--release', '21', '-Xlint:all', '-encoding', 'UTF-8',
        '--add-modules', 'jdk.httpserver', '-d', $OutputDir)
    $CompileArgs += $Sources
    $CompileArgs += $TestSource
    & $Javac @CompileArgs
    if ($LASTEXITCODE -ne 0) { throw "WIMS client javac failed with exit code $LASTEXITCODE." }

    & $Java '--add-modules' 'jdk.httpserver' '-ea' '-cp' $OutputDir `
        'org.geogebra.plus.wims.HttpWimsClientTest' $Fixtures $Mode
    if ($LASTEXITCODE -ne 0) { throw "WIMS client tests failed with exit code $LASTEXITCODE." }
} finally {
    if (Test-Path -LiteralPath $OutputDir) {
        $TempRootFull = [IO.Path]::GetFullPath($TempRoot).TrimEnd(
            [IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $OutputFull = [IO.Path]::GetFullPath($OutputDir)
        $SafePrefix = $TempRootFull + [IO.Path]::DirectorySeparatorChar
        if (-not $OutputFull.StartsWith($SafePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete temporary path outside the test directory: $OutputFull"
        }
        Remove-Item -LiteralPath $OutputFull -Recurse -Force
    }
}
