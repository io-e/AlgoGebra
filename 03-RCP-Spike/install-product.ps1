[CmdletBinding()]
param(
    [string]$DestinationRoot = 'D:\ALF_ZGit\G1_Geogebra_Migration\bin',
    [string]$ProductDirectoryName = 'GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8',
    [string]$JavaPluginPattern = 'org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4*',
    [switch]$IncludeD06Fixtures
)

$ErrorActionPreference = 'Stop'
$SourceRoot = $PSScriptRoot
$DestinationRoot = [IO.Path]::GetFullPath($DestinationRoot)
$Target = [IO.Path]::GetFullPath((Join-Path $DestinationRoot $ProductDirectoryName))
$RootPrefix = $DestinationRoot.TrimEnd('\') + '\'
if (-not $Target.StartsWith($RootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Product target must be a child of DestinationRoot: $Target"
}
if (Test-Path -LiteralPath $Target) {
    throw "Refusing to overwrite an existing product installation: $Target"
}
if (-not (Test-Path -LiteralPath $DestinationRoot)) {
    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
}

$EclipseHome = 'D:\ALF_ZGit\G2_Eclipse\01_src\eclipse'
$JrePlugin = Get-ChildItem (Join-Path $EclipseHome 'plugins') -Directory -Filter $JavaPluginPattern |
    Sort-Object Name -Descending | Select-Object -First 1
if (-not $JrePlugin) { throw "Bundled Java 25 runtime was not found under $EclipseHome\plugins" }
$JreSource = Join-Path $JrePlugin.FullName 'jre'
if (-not (Test-Path (Join-Path $JreSource 'bin\java.exe'))) {
    throw "Bundled Java runtime is incomplete: $JreSource"
}

$RequiredDirectories = @(
    'bundles', 'platform', 'launcher', 'natives', 'host\build',
    'configuration\org.eclipse.equinox.simpleconfigurator', 'product'
)
foreach ($relative in $RequiredDirectories) {
    $source = Join-Path $SourceRoot $relative
    if (-not (Test-Path -LiteralPath $source)) { throw "Required spike directory missing: $source" }
}

# The target path is fresh. This script never removes or resets existing files.
New-Item -ItemType Directory -Path $Target | Out-Null
foreach ($relative in $RequiredDirectories) {
    New-Item -ItemType Directory -Path (Join-Path $Target $relative) -Force | Out-Null
}
New-Item -ItemType Directory -Path (Join-Path $Target 'configuration') -Force | Out-Null
$LicenseTarget = Join-Path $Target 'licenses'
New-Item -ItemType Directory -Path $LicenseTarget -Force | Out-Null
foreach ($licenseFile in @('WIMS-INTERFACES.md', 'GPL-2.0.txt')) {
    $licenseSource = Join-Path $SourceRoot ("engines\licenses\" + $licenseFile)
    if (-not (Test-Path -LiteralPath $licenseSource)) { throw "Missing engine license notice: $licenseSource" }
    Copy-Item -LiteralPath $licenseSource -Destination $LicenseTarget
}
$ProductJre = Join-Path $Target 'jre'
New-Item -ItemType Directory -Path $ProductJre -Force | Out-Null

function Copy-Jars([string]$RelativeSource, [string]$RelativeTarget) {
    $source = Join-Path $SourceRoot $RelativeSource
    $destination = Join-Path $Target $RelativeTarget
    # Test extensions never ride in the product host payload; the opt-in
    # -IncludeD06Fixtures path copies them into a separate directory below.
    $jars = @(Get-ChildItem -LiteralPath $source -Filter '*.jar' -File |
        Where-Object Name -notlike 'org.geogebra.plus.test.*')
    if ($jars.Count -eq 0) { throw "No JAR files found in $source" }
    foreach ($jar in $jars) { Copy-Item -LiteralPath $jar.FullName -Destination $destination }
    return $jars.Count
}

$BundleJarCount = Copy-Jars 'bundles' 'bundles'
$PlatformJarCount = Copy-Jars 'platform' 'platform'
$LauncherJarCount = Copy-Jars 'launcher' 'launcher'
$HostJarCount = Copy-Jars 'host\build' 'host\build'
$NativeJarCount = Copy-Jars 'natives' 'natives'
$D06FixtureJarCount = 0
if ($IncludeD06Fixtures) {
    $D06Source = Join-Path $SourceRoot 'test-extension\build'
    $D06Target = Join-Path $Target 'test-extension\build'
    $RequiredD06Fixtures = @(
        'org.geogebra.plus.test.extension_1.0.0.jar',
        'org.geogebra.plus.test.extension.bad-import_1.0.1.jar',
        'org.geogebra.plus.test.unauthorized_1.0.0.jar'
    )
    foreach ($fixture in $RequiredD06Fixtures) {
        if (-not (Test-Path -LiteralPath (Join-Path $D06Source $fixture) -PathType Leaf)) {
            throw "Requested D-06 fixture is missing; run build.ps1 first: $(Join-Path $D06Source $fixture)"
        }
    }
    New-Item -ItemType Directory -Path $D06Target -Force | Out-Null
    foreach ($fixture in $RequiredD06Fixtures) {
        Copy-Item -LiteralPath (Join-Path $D06Source $fixture) -Destination $D06Target
    }
    $D06FixtureJarCount = $RequiredD06Fixtures.Count
}
Copy-Item -LiteralPath (Join-Path $SourceRoot 'configuration\config.ini') -Destination (Join-Path $Target 'configuration\config.ini')
Copy-Item -LiteralPath (Join-Path $SourceRoot 'configuration\org.eclipse.equinox.simpleconfigurator\bundles.info') `
    -Destination (Join-Path $Target 'configuration\org.eclipse.equinox.simpleconfigurator\bundles.info')
Copy-Item -LiteralPath (Join-Path $SourceRoot 'product\geogebraplus.product') -Destination (Join-Path $Target 'product\geogebraplus.product')
Copy-Item -LiteralPath (Join-Path $SourceRoot 'bnd-input-set.sha256') -Destination (Join-Path $Target 'bnd-input-set.sha256')
Copy-Item -LiteralPath (Join-Path $SourceRoot 'launch.ps1') -Destination (Join-Path $Target 'launch.ps1')
Get-ChildItem -LiteralPath $JreSource -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $ProductJre -Recurse
}

$FrameworkJar = Get-ChildItem (Join-Path $Target 'bundles') -Filter 'org.eclipse.osgi_*.jar' -File | Select-Object -First 1
$SimpleConfiguratorJar = Get-ChildItem (Join-Path $Target 'platform') -Filter 'org.eclipse.equinox.simpleconfigurator_*.jar' -File | Select-Object -First 1
if (-not $FrameworkJar -or -not $SimpleConfiguratorJar) {
    throw 'The installed framework or Simple Configurator JAR was not staged.'
}
function ConvertTo-FileUrl([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path).Replace('\', '/')
    return 'file:/' + $full
}
$FrameworkUrl = ConvertTo-FileUrl $FrameworkJar.FullName
$SimpleConfiguratorUrl = ConvertTo-FileUrl $SimpleConfiguratorJar.FullName
$ConfigFile = Join-Path $Target 'configuration\config.ini'
$ConfigText = [IO.File]::ReadAllText($ConfigFile)
$ConfigText = [regex]::Replace($ConfigText, '(?m)^# Generated by build\.ps1\..*$', '# Generated by install-product.ps1. Installed paths are absolute.')
$ConfigText = [regex]::Replace($ConfigText, '(?m)^osgi.framework=.*$', "osgi.framework=$FrameworkUrl")
$ConfigText = [regex]::Replace($ConfigText, '(?m)^osgi.bundles=.*$', "osgi.bundles=reference:$SimpleConfiguratorUrl@1:start")
[IO.File]::WriteAllText($ConfigFile, $ConfigText, [Text.UTF8Encoding]::new($false))

$StrictLauncher = @'
@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch.ps1" %*
exit /b %ERRORLEVEL%
'@
$WorkaroundLauncher = @'
@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch.ps1" -ManualNativeFallback -BootDelegateJogAmp %*
exit /b %ERRORLEVEL%
'@
[IO.File]::WriteAllText((Join-Path $Target 'Launch-Strict-Native-Gate.cmd'), $StrictLauncher, [Text.Encoding]::ASCII)
[IO.File]::WriteAllText((Join-Path $Target 'Launch-GeoGebraPlus-Workaround.cmd'), $WorkaroundLauncher, [Text.Encoding]::ASCII)

$Readme = @"
# GeoGebraPlus RCP — installed Windows x86_64 image

This is a runnable, prebuilt Equinox install image staged from the D-03 validated bundle set. It is not a PDE-exported EXE installer. It includes a local Java 25 runtime and does not require launching through the Eclipse IDE.

## Launch modes

- **Strict native-gate check:** run ``Launch-Strict-Native-Gate.cmd`` (or ``launch.ps1``). This adds no manual native extraction and no JogAmp boot delegation. It is the mode to use when evaluating the D-05 gate.
- **Functional Windows workaround:** run ``Launch-GeoGebraPlus-Workaround.cmd``. This selects manual DLL extraction and application-loader boot delegation, the combination that has worked in the spike. It is a diagnostic fallback, not a D-05 gate pass.
- Evidence screenshots are disabled by default. Pass ``-CaptureEvidenceScreenshot`` to ``launch.ps1`` only when you intend to capture the product window.

Run logs, per-run Equinox configurations/workspaces, and the diagnostic workaround's extracted DLLs are written under this installation directory. Strict-mode helper DLLs are extracted to unique folders under the operating system temporary directory. Existing files are never removed by the launch script.

## Installed payload

- GeoGebra version: `5.4.934.0`; source pin: `375db7faf540`.
- D-03 inputs: $BundleJarCount bundle JARs including the system framework; D-03 installable set is 50 bundles.
- Eclipse platform JARs: $PlatformJarCount; launcher JARs: $LauncherJarCount; host/native-fragment/external-engine JARs: $HostJarCount.
- Native classifier/API JARs: $NativeJarCount (Windows x86_64 payload).
- D-06 test fixtures: $D06FixtureJarCount (development-only; opt in with ``-IncludeD06Fixtures``; never in ``bundles.info``).
- Local Java: $($JrePlugin.Name).
- D-03 installable-bundle SHA-256: $((Get-Content (Join-Path $Target 'bnd-input-set.sha256') -Raw).Trim()).
- Pari/Maxima/Gnuplot executables are not bundled; each is discovered on PATH. Missing executables raise an explicit unavailable-engine error (no CAS fallback).
- WIMS-derived Pari/Maxima material is GPL-2.0-or-later; see ``licenses/WIMS-INTERFACES.md`` and ``licenses/GPL-2.0.txt``.

The latest strict-mode run loaded GIAC, GlueGen, and JOGL natives without manual extraction flags or boot delegation; CAS and 3D initialization assertions passed. D-05 remains PARTIAL pending owner review of the GIAC product-local loader replacement and any required strict-mode visual 3D evidence. See the validation report in the study project. External-engine runtime acceptance needs the corresponding executable installed on PATH.
"@
[IO.File]::WriteAllText((Join-Path $Target 'INSTALLATION.md'), $Readme, [Text.UTF8Encoding]::new($false))

$ManifestFiles = @(
    Get-ChildItem (Join-Path $Target 'bundles') -Filter '*.jar' -File
    Get-ChildItem (Join-Path $Target 'platform') -Filter '*.jar' -File
    Get-ChildItem (Join-Path $Target 'launcher') -Filter '*.jar' -File
    Get-ChildItem (Join-Path $Target 'host\build') -Filter '*.jar' -File
    Get-ChildItem (Join-Path $Target 'natives') -Filter '*.jar' -File
    Get-Item (Join-Path $Target 'jre\bin\java.exe')
)
if ($IncludeD06Fixtures) {
    $ManifestFiles += @(Get-ChildItem (Join-Path $Target 'test-extension\build') -Filter '*.jar' -File)
}
$ManifestRows = foreach ($file in $ManifestFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $relative = $file.FullName.Substring($Target.Length + 1).Replace('\', '/')
    "$hash  $relative"
}
Set-Content -LiteralPath (Join-Path $Target 'install-manifest.sha256') -Value ($ManifestRows -join "`r`n") -Encoding UTF8

Write-Host "Installed prebuilt GeoGebraPlus image: $Target" -ForegroundColor Green
Write-Host "JAR counts: bundles=$BundleJarCount platform=$PlatformJarCount launcher=$LauncherJarCount host/native-fragment/engine=$HostJarCount natives=$NativeJarCount"
Write-Host "Bundled runtime: $((Join-Path $Target 'jre\bin\java.exe'))"
Write-Host 'No pre-existing destination files were overwritten or deleted.'
