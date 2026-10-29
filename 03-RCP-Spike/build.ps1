[CmdletBinding()]
param(
    [string]$JavaHome,
    [string]$GeoGebraSourceRoot = 'D:\ALF_ZGit\G1_Geogebra_Migration\source'
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$HostDir = Join-Path $Root 'host'
$BundleDir = Join-Path $Root 'bundles'
$PlatformDir = Join-Path $Root 'platform'
$NativeDir = Join-Path $Root 'natives'
$ConfigDir = Join-Path $Root 'configuration'
$OutputDir = Join-Path $HostDir 'build'
$ClassesDir = Join-Path $OutputDir 'classes'
$HostJar = Join-Path $OutputDir 'org.geogebra.plus.host_0.1.0.jar'
$HostManifest = Join-Path $HostDir 'META-INF\MANIFEST.MF'
$ResourceManifest = Join-Path $HostDir 'resources\META-INF\MANIFEST.MF'
$DesktopResources = Join-Path $GeoGebraSourceRoot 'desktop\desktop\src\main\resources'
$CommonResources = Join-Path $GeoGebraSourceRoot 'shared\common\src\main\resources'
$ResourceFragmentJar = Join-Path $OutputDir 'org.geogebra.plus.desktop.resources_0.1.0.jar'
$GiacFragmentSource = Join-Path $HostDir 'giac-native'
$GiacFragmentClasses = Join-Path $OutputDir 'giac-native-classes'
$GiacFragmentJar = Join-Path $OutputDir 'org.geogebra.plus.giac.native_0.1.0.jar'
$GiacFragmentManifest = Join-Path $GiacFragmentSource 'META-INF\MANIFEST.MF'
$GlueGenFragmentSource = Join-Path $HostDir 'gluegen-native'
$GlueGenFragmentClasses = Join-Path $OutputDir 'gluegen-native-classes'
$GlueGenFragmentJar = Join-Path $OutputDir 'org.geogebra.plus.gluegen.native_0.1.0.jar'
$GlueGenFragmentManifest = Join-Path $GlueGenFragmentSource 'META-INF\MANIFEST.MF'
$JoglFragmentSource = Join-Path $HostDir 'jogl-native'
$JoglFragmentClasses = Join-Path $OutputDir 'jogl-native-classes'
$JoglFragmentJar = Join-Path $OutputDir 'org.geogebra.plus.jogl.native_0.1.0.jar'
$JoglFragmentManifest = Join-Path $JoglFragmentSource 'META-INF\MANIFEST.MF'
$EngineRoot = Join-Path $Root 'engines'
$EngineApiJar = Join-Path $OutputDir 'org.geogebra.plus.compute.api_0.1.0.jar'
$EngineRuntimeJar = Join-Path $OutputDir 'org.geogebra.plus.compute.runtime_0.1.0.jar'
$PariEngineJar = Join-Path $OutputDir 'org.geogebra.plus.engine.pari_0.1.0.jar'
$MaximaEngineJar = Join-Path $OutputDir 'org.geogebra.plus.engine.maxima_0.1.0.jar'
$GnuplotEngineJar = Join-Path $OutputDir 'org.geogebra.plus.engine.gnuplot_0.1.0.jar'

if (-not $JavaHome) {
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME 'bin\javac.exe'))) {
        $JavaHome = $env:JAVA_HOME
    } else {
        $candidate = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
        if (Test-Path (Join-Path $candidate 'bin\javac.exe')) {
            $JavaHome = $candidate
        }
    }
}
if (-not $JavaHome -or -not (Test-Path (Join-Path $JavaHome 'bin\javac.exe'))) {
    throw 'JDK 21+ javac.exe not found. Pass -JavaHome or set JAVA_HOME.'
}
$Javac = Join-Path $JavaHome 'bin\javac.exe'
$JarTool = Join-Path $JavaHome 'bin\jar.exe'
if (-not (Test-Path $JarTool)) { throw "jar.exe not found under $JavaHome" }

function Read-BundleMetadata([string]$Path) {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.GetEntry('META-INF/MANIFEST.MF')
        if (-not $entry) { throw "Missing OSGi manifest in $Path" }
        $reader = [System.IO.StreamReader]::new($entry.Open())
        try { $manifest = $reader.ReadToEnd() } finally { $reader.Dispose() }
    } finally { $archive.Dispose() }
    # OSGi manifest continuation lines start with one space.
    $manifest = [regex]::Replace($manifest, "`r?`n ", '')
    $bsnMatch = [regex]::Match($manifest, '(?m)^Bundle-SymbolicName:\s*([^;\r\n]+)')
    $versionMatch = [regex]::Match($manifest, '(?m)^Bundle-Version:\s*([^\r\n]+)')
    $fragmentMatch = [regex]::Match($manifest, '(?m)^Fragment-Host:\s*([^;\r\n]+)')
    if (-not $bsnMatch.Success -or -not $versionMatch.Success) {
        throw "Missing Bundle-SymbolicName or Bundle-Version in $Path"
    }
    [pscustomobject]@{
        Bsn = $bsnMatch.Groups[1].Value.Trim()
        Version = $versionMatch.Groups[1].Value.Trim()
        FragmentHost = if ($fragmentMatch.Success) { $fragmentMatch.Groups[1].Value.Trim() } else { '' }
    }
}

function ConvertTo-FileUrl([string]$Path) {
    $full = [System.IO.Path]::GetFullPath($Path).Replace('\', '/')
    if ($full -match '^[A-Za-z]:/') { return "file:/$full" }
    return "file:$full"
}

New-Item -ItemType Directory -Path $ClassesDir -Force | Out-Null
$CompileJars = @(
    Get-ChildItem $BundleDir -Filter '*.jar' -File
    Get-ChildItem $PlatformDir -Filter '*.jar' -File
    Get-ChildItem $NativeDir -Filter '*.jar' -File
)
$Classpath = ($CompileJars.FullName -join ';')
$Sources = @(Get-ChildItem (Join-Path $HostDir 'src') -Filter '*.java' -Recurse -File | ForEach-Object FullName)
if ($Sources.Count -eq 0) { throw "No Java sources found in $HostDir\src" }
& $Javac -encoding UTF-8 --release 21 -cp $Classpath -d $ClassesDir @Sources
if ($LASTEXITCODE -ne 0) { throw "javac failed with exit code $LASTEXITCODE" }
& $JarTool cfm $HostJar $HostManifest -C $ClassesDir . -C $HostDir plugin.xml
if ($LASTEXITCODE -ne 0) { throw "jar failed with exit code $LASTEXITCODE" }
if (-not (Test-Path $DesktopResources)) { throw "Desktop resource source directory not found: $DesktopResources" }
if (-not (Test-Path $CommonResources)) { throw "Common resource source directory not found: $CommonResources" }
# ImageManagerD uses its own bundle class loader for both desktop and common
# resource paths, so the resource fragment overlays both source resource trees.
& $JarTool cfm $ResourceFragmentJar $ResourceManifest -C $DesktopResources . -C $CommonResources .
if ($LASTEXITCODE -ne 0) { throw "resource-fragment jar failed with exit code $LASTEXITCODE" }

# JNI libraries are associated with the class loader that calls System.load.
# GeoGebra's CASgiacD is in the desktop bundle, while javagiac's SWIG wrapper
# classes are exported by a different OSGi bundle. This spike-only fragment
# adds a loader class to the GIAC JNI host bundle so the native DLL is loaded
# in the same bundle class loader as javagiac.giacJNI. The upstream bundle is
# kept byte-for-byte unchanged.
New-Item -ItemType Directory -Path $GiacFragmentClasses -Force | Out-Null
$GiacFragmentSources = @(Get-ChildItem (Join-Path $GiacFragmentSource 'src') -Filter '*.java' -Recurse -File | ForEach-Object FullName)
if ($GiacFragmentSources.Count -eq 0) { throw "No GIAC native fragment sources found under $GiacFragmentSource\src" }
& $Javac -encoding UTF-8 --release 21 -d $GiacFragmentClasses @GiacFragmentSources
if ($LASTEXITCODE -ne 0) { throw "GIAC fragment javac failed with exit code $LASTEXITCODE" }
& $JarTool cfm $GiacFragmentJar $GiacFragmentManifest -C $GiacFragmentClasses .
if ($LASTEXITCODE -ne 0) { throw "GIAC fragment jar failed with exit code $LASTEXITCODE" }

foreach ($nativeFragment in @(
    @{ Source = $GlueGenFragmentSource; Classes = $GlueGenFragmentClasses; Jar = $GlueGenFragmentJar; Manifest = $GlueGenFragmentManifest; Label = 'GlueGen' },
    @{ Source = $JoglFragmentSource; Classes = $JoglFragmentClasses; Jar = $JoglFragmentJar; Manifest = $JoglFragmentManifest; Label = 'JOGL' }
)) {
    New-Item -ItemType Directory -Path $nativeFragment.Classes -Force | Out-Null
    $fragmentSources = @(Get-ChildItem (Join-Path $nativeFragment.Source 'src') -Filter '*.java' -Recurse -File | ForEach-Object FullName)
    if ($fragmentSources.Count -eq 0) { throw "No $($nativeFragment.Label) native fragment sources found under $($nativeFragment.Source)\src" }
    & $Javac -encoding UTF-8 --release 21 -d $nativeFragment.Classes @fragmentSources
    if ($LASTEXITCODE -ne 0) { throw "$($nativeFragment.Label) fragment javac failed with exit code $LASTEXITCODE" }
    & $JarTool cfm $nativeFragment.Jar $nativeFragment.Manifest -C $nativeFragment.Classes .
    if ($LASTEXITCODE -ne 0) { throw "$($nativeFragment.Label) fragment jar failed with exit code $LASTEXITCODE" }
}

function Build-EngineBundle([string]$Label, [string]$RelativeSource, [string]$RelativeManifest,
        [string]$OutputJar, [string[]]$ClasspathFiles) {
    $sourceDir = Join-Path $EngineRoot $RelativeSource
    $manifest = Join-Path $EngineRoot $RelativeManifest
    $classes = Join-Path $OutputDir ($Label + '-classes')
    if (-not (Test-Path -LiteralPath $manifest)) { throw "Missing $Label bundle manifest: $manifest" }
    $sources = @(Get-ChildItem -LiteralPath $sourceDir -Filter '*.java' -Recurse -File |
        ForEach-Object FullName)
    if ($sources.Count -eq 0) { throw "No $Label Java sources found under $sourceDir" }
    New-Item -ItemType Directory -Path $classes -Force | Out-Null
    $javacArgs = @('-encoding', 'UTF-8', '--release', '21')
    if ($ClasspathFiles.Count -gt 0) {
        $javacArgs += @('-cp', ($ClasspathFiles -join ';'))
    }
    $javacArgs += @('-d', $classes)
    $javacArgs += $sources
    & $Javac @javacArgs
    if ($LASTEXITCODE -ne 0) { throw "$Label javac failed with exit code $LASTEXITCODE" }
    & $JarTool cfm $OutputJar $manifest -C $classes .
    if ($LASTEXITCODE -ne 0) { throw "$Label bundle jar failed with exit code $LASTEXITCODE" }
    Write-Host "Built $OutputJar" -ForegroundColor Green
}

# The API and shared process runtime are independent OSGi bundles. PARI and
# Maxima remain separately packaged because their WIMS-derived filters/parsers
# carry GPL-2.0-or-later provenance. Gnuplot does not use a WIMS C interface.
Build-EngineBundle 'compute-api' 'api\src' 'api\META-INF\MANIFEST.MF' $EngineApiJar @()
Build-EngineBundle 'compute-runtime' 'runtime\src' 'runtime\META-INF\MANIFEST.MF' $EngineRuntimeJar @($EngineApiJar)
$EngineCompileClasspath = @($EngineApiJar, $EngineRuntimeJar) + @($CompileJars.FullName)
Build-EngineBundle 'engine-pari' 'pari\src' 'pari\META-INF\MANIFEST.MF' $PariEngineJar $EngineCompileClasspath
Build-EngineBundle 'engine-maxima' 'maxima\src' 'maxima\META-INF\MANIFEST.MF' $MaximaEngineJar $EngineCompileClasspath
Build-EngineBundle 'engine-gnuplot' 'gnuplot\src' 'gnuplot\META-INF\MANIFEST.MF' $GnuplotEngineJar $EngineCompileClasspath

# Preserve the 50 D-03 inputs as-is. The Equinox framework jar is the system
# bundle and the new host jar is a separate spike output, not one of the inputs.
$Installables = @(
    Get-ChildItem $BundleDir -Filter '*.jar' -File |
        Where-Object { $_.Name -notmatch '^org\.eclipse\.osgi_' }
)
if ($Installables.Count -ne 50) {
    throw "Expected the 50 unchanged D-03 installable bundles, found $($Installables.Count)."
}
$PlatformJars = @(Get-ChildItem $PlatformDir -Filter '*.jar' -File)
$SimpleConfigurator = $PlatformJars | Where-Object Name -like 'org.eclipse.equinox.simpleconfigurator_*.jar' | Select-Object -First 1
if (-not $SimpleConfigurator) { throw 'Missing staged org.eclipse.equinox.simpleconfigurator bundle.' }

$Rows = [System.Collections.Generic.List[string]]::new()
$ProductIds = [System.Collections.Generic.List[string]]::new()
$Rows.Add('#encoding=UTF-8')
$Rows.Add('#version=1')
$ProductIds.Add('org.eclipse.osgi')

foreach ($file in $Installables) {
    $meta = Read-BundleMetadata $file.FullName
    $location = 'bundles/' + $file.Name
    $Rows.Add("$($meta.Bsn),$($meta.Version),$location,4,false")
    $ProductIds.Add($meta.Bsn)
}

foreach ($file in $PlatformJars) {
    $meta = Read-BundleMetadata $file.FullName
    if ($meta.Bsn -eq 'org.eclipse.equinox.simpleconfigurator') {
        # The framework installs/starts this bundle through osgi.bundles below.
        $ProductIds.Add($meta.Bsn)
        continue
    }
    $location = 'platform/' + $file.Name
    $autoStart = if ($meta.FragmentHost) { 'false' } else { 'true' }
    $startLevel = if ($meta.Bsn -eq 'org.eclipse.equinox.common') { 2 } else { 4 }
    $Rows.Add("$($meta.Bsn),$($meta.Version),$location,$startLevel,$autoStart")
    $ProductIds.Add($meta.Bsn)
}

$HostMeta = Read-BundleMetadata $HostJar
$Rows.Add("$($HostMeta.Bsn),$($HostMeta.Version),host/build/$([IO.Path]::GetFileName($HostJar)),4,true")
$ProductIds.Add($HostMeta.Bsn)
$ResourceMeta = Read-BundleMetadata $ResourceFragmentJar
$Rows.Add("$($ResourceMeta.Bsn),$($ResourceMeta.Version),host/build/$([IO.Path]::GetFileName($ResourceFragmentJar)),4,false")
$ProductIds.Add($ResourceMeta.Bsn)
$GiacMeta = Read-BundleMetadata $GiacFragmentJar
$Rows.Add("$($GiacMeta.Bsn),$($GiacMeta.Version),host/build/$([IO.Path]::GetFileName($GiacFragmentJar)),4,false")
$ProductIds.Add($GiacMeta.Bsn)
foreach ($nativeFragmentJar in @($GlueGenFragmentJar, $JoglFragmentJar)) {
    $nativeMeta = Read-BundleMetadata $nativeFragmentJar
    $Rows.Add("$($nativeMeta.Bsn),$($nativeMeta.Version),host/build/$([IO.Path]::GetFileName($nativeFragmentJar)),4,false")
    $ProductIds.Add($nativeMeta.Bsn)
}
foreach ($engineJar in @($EngineApiJar, $EngineRuntimeJar, $PariEngineJar, $MaximaEngineJar, $GnuplotEngineJar)) {
    $engineMeta = Read-BundleMetadata $engineJar
    $autoStart = if ($engineMeta.Bsn -match '\.engine\.(pari|maxima|gnuplot)$') { 'true' } else { 'false' }
    $Rows.Add("$($engineMeta.Bsn),$($engineMeta.Version),host/build/$([IO.Path]::GetFileName($engineJar)),4,$autoStart")
    $ProductIds.Add($engineMeta.Bsn)
}

$SimpleMeta = Read-BundleMetadata $SimpleConfigurator.FullName
$ProductConfig = "reference:$(ConvertTo-FileUrl $SimpleConfigurator.FullName)@1:start"
$FrameworkJar = Get-ChildItem $BundleDir -Filter 'org.eclipse.osgi_*.jar' -File | Select-Object -First 1
if (-not $FrameworkJar) { throw 'Missing staged org.eclipse.osgi framework jar.' }
$FrameworkUrl = ConvertTo-FileUrl $FrameworkJar.FullName
$ConfigIni = @"
# Generated by build.ps1. Paths are relative to the spike install area.
eclipse.application=org.geogebra.plus.host.geogebraplusApp
eclipse.product=org.geogebra.plus.host.geogebraplus
org.eclipse.equinox.simpleconfigurator.configUrl=file:org.eclipse.equinox.simpleconfigurator/bundles.info
osgi.bundles=$ProductConfig
osgi.bundles.defaultStartLevel=4
osgi.framework=$FrameworkUrl
"@
New-Item -ItemType Directory -Path (Join-Path $ConfigDir 'org.eclipse.equinox.simpleconfigurator') -Force | Out-Null
Set-Content -Path (Join-Path $ConfigDir 'config.ini') -Value $ConfigIni -Encoding UTF8
Set-Content -Path (Join-Path $ConfigDir 'org.eclipse.equinox.simpleconfigurator\bundles.info') -Value ($Rows -join "`r`n") -Encoding UTF8

# The .product is deliberately metadata for PDE/product tooling only; the
# launch script below tests the exact staged runtime without exporting an IDE.
$PluginXml = [System.Collections.Generic.List[string]]::new()
$PluginXml.Add('<?xml version="1.0" encoding="UTF-8"?>')
$PluginXml.Add('<?pde version="3.5"?>')
$PluginXml.Add('<product name="GeoGebraPlus RCP Spike" uid="org.geogebra.plus.product"')
$PluginXml.Add('         id="org.geogebra.plus.host.geogebraplus"')
$PluginXml.Add('         application="org.geogebra.plus.host.geogebraplusApp"')
$PluginXml.Add('         version="0.1.0" useFeatures="false" includeLaunchers="false">')
$PluginXml.Add('  <configIni use="default"/>')
$PluginXml.Add('  <launcherArgs><vmArgsList>')
$PluginXml.Add('    --add-exports java.base/java.lang=ALL-UNNAMED')
$PluginXml.Add('    --add-exports java.desktop/sun.awt=ALL-UNNAMED')
$PluginXml.Add('    --add-exports java.desktop/sun.java2d=ALL-UNNAMED')
$PluginXml.Add('    --enable-native-access=ALL-UNNAMED')
$PluginXml.Add('    --add-modules=ALL-SYSTEM')
$PluginXml.Add('  </vmArgsList></launcherArgs>')
$PluginXml.Add('  <plugins>')
foreach ($id in ($ProductIds | Sort-Object -Unique)) {
    $PluginXml.Add("    <plugin id=`"$id`"/>")
}
$PluginXml.Add('  </plugins>')
$PluginXml.Add('</product>')
Set-Content -Path (Join-Path $Root 'product\geogebraplus.product') -Value ($PluginXml -join "`r`n") -Encoding UTF8

# Bundle-set checksum for evidence. It covers the original 50 D-03 inputs only.
$HashInput = ($Installables | Sort-Object Name | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    "$($_.Name)  $hash"
}) -join "`n"
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $SetHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($HashInput)))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }
Set-Content -Path (Join-Path $Root 'bnd-input-set.sha256') -Value "$SetHash  50 D-03 installable bundle inputs (excluding system framework)" -Encoding UTF8

Write-Host "Built $HostJar" -ForegroundColor Green
Write-Host "Generated bundles.info with 50 unchanged D-03 inputs, $($PlatformJars.Count) platform jars, host/native fragments, and 5 external-engine bundles."
Write-Host "D-03 input-set SHA-256: $SetHash"
