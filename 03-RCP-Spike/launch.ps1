[CmdletBinding()]
param(
    [switch]$Headless,
    [switch]$ManualNativeFallback,
    [switch]$BootDelegateJogAmp,
    [switch]$CaptureEvidenceScreenshot,
    [switch]$NoBuild,
    [string]$JavaHome
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
if (-not $NoBuild) {
    $BuildScript = Join-Path $Root 'build.ps1'
    if (Test-Path $BuildScript) {
        & $BuildScript -JavaHome $JavaHome
        if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed with exit code $LASTEXITCODE" }
    } else {
        Write-Host 'No build script is present; using the prebuilt installed product image.'
    }
}

$BundledJava = Join-Path $Root 'jre\bin\java.exe'
if (Test-Path $BundledJava) {
    $Java = $BundledJava
} else {
    # Development fallback only. Installed images prefer their bundled JRE
    # and do not depend on launching through the Eclipse IDE installation.
    $EclipseHome = 'D:\ALF_ZGit\G2_Eclipse\01_src\eclipse'
    $JrePlugin = Get-ChildItem (Join-Path $EclipseHome 'plugins') -Directory -Filter 'org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4*' | Select-Object -First 1
    if (-not $JrePlugin) { throw "Java 25 JustJ runtime was not found under $EclipseHome\plugins" }
    $Java = Join-Path $JrePlugin.FullName 'jre\bin\java.exe'
}
if (-not (Test-Path $Java)) { throw "java.exe was not found at $Java" }

$Framework = Get-ChildItem (Join-Path $Root 'bundles') -Filter 'org.eclipse.osgi_*.jar' -File | Select-Object -First 1
$Launcher = Get-ChildItem (Join-Path $Root 'launcher') -Filter 'org.eclipse.equinox.launcher_*.jar' -File | Select-Object -First 1
if (-not $Framework -or -not $Launcher) { throw 'Missing staged Equinox framework or launcher jar.' }

$RunId = '{0}-{1}-{2}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID, ([guid]::NewGuid().ToString('N').Substring(0,8))
$Workspace = Join-Path $Root "workspace\$RunId"
$BaseConfiguration = Join-Path $Root 'configuration'
$Configuration = Join-Path $BaseConfiguration "runtime-$RunId"
$LogDir = Join-Path $Root 'logs'
New-Item -ItemType Directory -Path $Configuration,$Workspace,$LogDir -Force | Out-Null
Copy-Item (Join-Path $BaseConfiguration 'config.ini') $Configuration
New-Item -ItemType Directory -Path (Join-Path $Configuration 'org.eclipse.equinox.simpleconfigurator') -Force | Out-Null
Copy-Item (Join-Path $BaseConfiguration 'org.eclipse.equinox.simpleconfigurator\bundles.info') (Join-Path $Configuration 'org.eclipse.equinox.simpleconfigurator\bundles.info')
$Log = Join-Path $LogDir "rcp-$RunId.log"
$Natives = (Get-ChildItem (Join-Path $Root 'natives') -Filter '*.jar' -File | ForEach-Object FullName) -join ';'
$Classpath = @($Framework.FullName, $Launcher.FullName, $Natives) -join ';'
$InstallUrl = 'file:/' + ($Root.Replace('\','/').TrimEnd('/')) + '/'
$HeadlessValue = if ($Headless.IsPresent) { 'true' } else { 'false' }
$NativeExtractDir = $null
if ($ManualNativeFallback) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $NativeExtractDir = Join-Path $Root "natives\extract-$RunId"
    New-Item -ItemType Directory -Path $NativeExtractDir | Out-Null
    $dllCount = 0
    foreach ($nativeJar in Get-ChildItem (Join-Path $Root 'natives') -Filter '*-natives-windows-amd64.jar' -File) {
        $archive = [System.IO.Compression.ZipFile]::OpenRead($nativeJar.FullName)
        try {
            foreach ($entry in $archive.Entries | Where-Object FullName -match '\.dll$') {
                $target = Join-Path $NativeExtractDir ([IO.Path]::GetFileName($entry.FullName))
                $inputStream = $entry.Open()
                $outputStream = [IO.File]::Open($target, [IO.FileMode]::CreateNew)
                try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
                $dllCount++
            }
        } finally { $archive.Dispose() }
    }
    Write-Host "Manual native fallback extracted $dllCount DLLs to $NativeExtractDir; no existing output was removed."
}

$JvmArgs = @(
    '--add-exports', 'java.base/java.lang=ALL-UNNAMED',
    '--add-exports', 'java.desktop/sun.awt=ALL-UNNAMED',
    '--add-exports', 'java.desktop/sun.java2d=ALL-UNNAMED',
    '--enable-native-access=ALL-UNNAMED',
    '--add-modules=ALL-SYSTEM',
    '-cp', $Classpath,
    "-Dosgi.install.area=$InstallUrl",
    '-Declipse.application=org.geogebra.plus.host.geogebraplusApp',
    '-Declipse.product=org.geogebra.plus.host.geogebraplus',
    "-Dggbplus.runId=$RunId",
    "-Dggbplus.headless=$HeadlessValue"
)
if ($CaptureEvidenceScreenshot) {
    $JvmArgs += '-Dggbplus.captureEvidenceScreenshot=true'
}
if ($ManualNativeFallback) {
    $JvmArgs += "-Djava.library.path=$NativeExtractDir"
    $JvmArgs += '-Djogamp.gluegen.UseTempJarCache=false'
}
if ($BootDelegateJogAmp) {
    # Diagnostic mode: load all JogAmp API classes from the app loader where
    # the native JARs live, avoiding sibling OSGi class-loader ownership for
    # JNI symbols. This is an explicit test switch, not the default policy.
    $JvmArgs += '-Dorg.osgi.framework.bootdelegation=com.jogamp.*,jogamp.*'
    $JvmArgs += '-Dosgi.parentClassloader=app'
    $JvmArgs += '-Dggbplus.jogampBootDelegation=true'
}
$LauncherArgs = @(
    'org.eclipse.equinox.launcher.Main',
    '-configuration', $Configuration,
    '-data', $Workspace,
    '-application', 'org.geogebra.plus.host.geogebraplusApp',
    '-consoleLog',
    '-noSplash'
)

Write-Host "Launching GeoGebraPlus RCP spike; Java: $Java"
Write-Host "Run id: $RunId"
Write-Host "Log: $Log"
Write-Host "Unique, persistent Equinox configuration/storage: $Configuration"
Write-Host "Native mode: $(if ($ManualNativeFallback) { 'manual java.library.path fallback' } else { 'product classpath loaders / no native-path override' })"
Write-Host 'Existing framework storage and build outputs will not be removed.'
Push-Location $Root
try {
    & $Java @JvmArgs @LauncherArgs 2>&1 | Tee-Object -FilePath $Log
    $ExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
Write-Host "Equinox exit code: $ExitCode"
if ($ExitCode -ne 0) { exit $ExitCode }
