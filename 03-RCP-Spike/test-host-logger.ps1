[CmdletBinding()]
param(
    [string]$JavaHome,
    [string]$Image = 'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12'
)

$ErrorActionPreference = 'Stop'
$SpikeRoot = $PSScriptRoot

if (-not $JavaHome) {
    $JavaHome = $env:JAVA_HOME
}
if (-not $JavaHome) {
    $JavaHome = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
}
$ExeSuffix = if ($IsWindows) { '.exe' } else { '' }
$Javac = Join-Path $JavaHome "bin\javac$ExeSuffix"
$Java = Join-Path $JavaHome "bin\java$ExeSuffix"
if (-not (Test-Path -LiteralPath $Javac) -or -not (Test-Path -LiteralPath $Java)) {
    throw "JDK tools were not found under '$JavaHome'."
}

$JarRoots = @(
    (Join-Path $Image 'bundles'),
    (Join-Path $Image 'platform'),
    (Join-Path $Image 'natives')
)
$Jars = @($JarRoots | Where-Object { Test-Path -LiteralPath $_ } |
    ForEach-Object { Get-ChildItem -LiteralPath $_ -Filter '*.jar' -File })
if ($Jars.Count -eq 0) {
    throw "GeoGebra/Eclipse image JARs were not found under '$Image'."
}

$Sources = @(
    Get-ChildItem -LiteralPath (Join-Path $SpikeRoot 'host\src') -Filter '*.java' -File -Recurse |
        ForEach-Object FullName
    (Join-Path $SpikeRoot 'host\test\org\geogebra\plus\host\GeoGebraLoggerBootstrapTest.java')
)
foreach ($Source in $Sources) {
    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Logger test source not found: $Source"
    }
}

$TempRoot = Join-Path ([IO.Path]::GetTempPath()) 'GeoGebraPlus-LoggerBootstrapTests'
$OutputDir = Join-Path $TempRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
try {
    $Classpath = ($Jars.FullName -join [IO.Path]::PathSeparator)
    & $Javac '--release' '21' '-encoding' 'UTF-8' '-cp' $Classpath '-d' $OutputDir @Sources
    if ($LASTEXITCODE -ne 0) {
        throw "javac failed with exit code $LASTEXITCODE."
    }

    $RuntimeClasspath = $OutputDir + [IO.Path]::PathSeparator + $Classpath
    & $Java '-ea' '-cp' $RuntimeClasspath 'org.geogebra.plus.host.GeoGebraLoggerBootstrapTest'
    if ($LASTEXITCODE -ne 0) {
        throw "GeoGebraLoggerBootstrapTest failed with exit code $LASTEXITCODE."
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
