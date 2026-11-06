[CmdletBinding()]
param(
    [Parameter(Mandatory)][uri]$Endpoint,
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][string]$Exercise,
    [Parameter(Mandatory)][string]$Field,
    [Parameter(Mandatory)][string]$Answer,
    [string]$ExpectedGrade = '1',
    [string]$Language = 'fr',
    [string]$JavaHome
)

$ErrorActionPreference = 'Stop'
$SpikeRoot = Split-Path -Parent $PSScriptRoot
$SourceDir = Join-Path $PSScriptRoot 'src\org\geogebra\plus\wims'
$TestRoot = Join-Path $PSScriptRoot 'test'
$LiveTest = Join-Path $TestRoot 'org\geogebra\plus\wims\WimsLiveSmokeTest.java'
if (-not $JavaHome) { $JavaHome = $env:JAVA_HOME }
if ($JavaHome) {
    $suffix = if ($IsWindows) { '.exe' } else { '' }
    $Javac = Join-Path $JavaHome "bin\javac$suffix"
    $Java = Join-Path $JavaHome "bin\java$suffix"
} else {
    $Javac = (Get-Command javac -CommandType Application -ErrorAction Stop).Source
    $Java = (Get-Command java -CommandType Application -ErrorAction Stop).Source
}
if (-not (Test-Path -LiteralPath $LiveTest)) { throw "Live smoke source not found: $LiveTest" }
$Sources = @(Get-ChildItem -LiteralPath $SourceDir -Filter '*.java' -File | ForEach-Object FullName)
$OutputDir = Join-Path ([IO.Path]::GetTempPath()) ('GeoGebraPlus-WimsLive-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
try {
    & $Javac '--release' '21' '-Xlint:all' '-encoding' 'UTF-8' '-d' $OutputDir @Sources $LiveTest
    if ($LASTEXITCODE -ne 0) { throw "WIMS live smoke javac failed with exit code $LASTEXITCODE." }
    $JavaArgs = @('-cp', $OutputDir, 'org.geogebra.plus.wims.WimsLiveSmokeTest',
        $Endpoint.AbsoluteUri, $Module, $Exercise, $Field, $Answer, $ExpectedGrade, $Language)
    & $Java @JavaArgs
    if ($LASTEXITCODE -ne 0) { throw "WIMS live smoke failed with exit code $LASTEXITCODE." }
} finally {
    if (Test-Path -LiteralPath $OutputDir) {
        $OutputFull = [IO.Path]::GetFullPath($OutputDir)
        $TempRootFull = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
            [IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        if (-not $OutputFull.StartsWith($TempRootFull + [IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete a live-smoke output path outside temp: $OutputFull"
        }
        Remove-Item -LiteralPath $OutputFull -Recurse -Force
    }
}
