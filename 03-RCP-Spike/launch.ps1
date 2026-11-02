# Windows RCP launcher. -Course mirrors the launch.sh contract in PR #8.
# Examples:
#   .\launch.ps1 -NoBuild
#   .\launch.ps1 -Course 'courses\trigonometry_intro.json'
#   .\launch.ps1 -Headless -Course 'C:\courses\intro.json'

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Headless = $false
$ManualNativeFallback = $false
$BootDelegateJogAmp = $false
$CaptureEvidenceScreenshot = $false
$NoBuild = $false
$JavaHome = $null
$CourseInput = $null
$CourseFlagSeen = $false
$DryRun = $env:GGBPLUS_LAUNCH_DRYRUN -eq '1'

function Write-UsageFailure([string]$Message) {
    [Console]::Error.WriteLine("Usage error: $Message")
    exit 64
}

function Get-CanonicalFileSystemPath([string]$Path, [switch]$Directory) {
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $full = [IO.Path]::GetFullPath($resolved.ProviderPath)
    $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
    if ($Directory -and -not $item.PSIsContainer) {
        throw "Not a directory: $Path"
    }
    if (-not $Directory -and $item.PSIsContainer) {
        throw "Not a file: $Path"
    }
    # Resolve a file symlink when present. The Java host repeats the security
    # check with Path.toRealPath(), which is authoritative for course loading.
    $target = $item.ResolveLinkTarget($true)
    if ($target) {
        $full = [IO.Path]::GetFullPath($target.FullName)
    }
    return $full
}

function Resolve-CoursePath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-UsageFailure '-Course requires a path.'
    }
    if ($Path -match '(?i)^[a-z][a-z0-9+.-]*://') {
        Write-UsageFailure 'Desktop course paths must be local, not URLs.'
    }
    try {
        $full = Get-CanonicalFileSystemPath -Path $Path
    } catch {
        [Console]::Error.WriteLine("Course file is missing or unreadable (66): $Path")
        exit 66
    }
    if (-not $full.EndsWith('.json', [StringComparison]::OrdinalIgnoreCase)) {
        [Console]::Error.WriteLine("Course file must have a .json extension (65): $full")
        exit 65
    }
    $file = Get-Item -LiteralPath $full -Force -ErrorAction SilentlyContinue
    if (-not $file -or $file.PSIsContainer) {
        [Console]::Error.WriteLine("Course path is not a regular file (66): $full")
        exit 66
    }
    if ($file.Length -gt 1MB) {
        [Console]::Error.WriteLine("Course file exceeds the 1 MiB limit (65): $($file.Length) bytes")
        exit 65
    }
    $allowedRootRaw = $env:GGBPLUS_COURSE_ROOT
    if (-not [string]::IsNullOrWhiteSpace($allowedRootRaw)) {
        try {
            $allowedRoot = Get-CanonicalFileSystemPath -Path $allowedRootRaw -Directory
        } catch {
            [Console]::Error.WriteLine("GGBPLUS_COURSE_ROOT is unavailable (77): $allowedRootRaw")
            exit 77
        }
        $rootWithSeparator = $allowedRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        $inside = $full.Equals($allowedRoot, [StringComparison]::OrdinalIgnoreCase) -or
            $full.StartsWith($rootWithSeparator, [StringComparison]::OrdinalIgnoreCase)
        if (-not $inside) {
            [Console]::Error.WriteLine("Course is outside GGBPLUS_COURSE_ROOT (77): $full")
            exit 77
        }
    }
    return $full
}

# Parse raw arguments so a missing/repeated -Course can return the same stable
# sysexits-style codes as the Linux launcher, without PowerShell's binder
# pre-empting the script with a generic exit code.
for ($i = 0; $i -lt $args.Count; $i++) {
    $argument = [string]$args[$i]
    switch -Regex ($argument) {
        '^(?:-Headless|--headless)$' { $Headless = $true; continue }
        '^(?:-ManualNativeFallback|--manual-native-fallback)$' { $ManualNativeFallback = $true; continue }
        '^(?:-BootDelegateJogAmp|--boot-delegate-jogamp)$' { $BootDelegateJogAmp = $true; continue }
        '^(?:-CaptureEvidenceScreenshot|--capture-evidence-screenshot)$' { $CaptureEvidenceScreenshot = $true; continue }
        '^(?:-NoBuild|--no-build)$' { $NoBuild = $true; continue }
        '^(?:-JavaHome|--java-home)$' {
            if ($i + 1 -ge $args.Count -or ([string]$args[$i + 1]) -match '^(?:-[A-Za-z]|--[A-Za-z])') {
                Write-UsageFailure "$argument requires a path."
            }
            $i++
            $JavaHome = [string]$args[$i]
            continue
        }
        '^(?:-Course|--course)$' {
            if ($CourseFlagSeen) { Write-UsageFailure '-Course may be specified only once.' }
            $CourseFlagSeen = $true
            if ($i + 1 -ge $args.Count -or ([string]$args[$i + 1]) -match '^(?:-[A-Za-z]|--[A-Za-z])') {
                Write-UsageFailure "$argument requires a path."
            }
            $i++
            $CourseInput = [string]$args[$i]
            continue
        }
        '^--course=(.*)$' {
            if ($CourseFlagSeen) { Write-UsageFailure '-Course may be specified only once.' }
            $CourseFlagSeen = $true
            $CourseInput = $Matches[1]
            # pwsh's Windows native-argument parser may split --course=C:\path
            # at the drive colon into --course=C and \path. Rejoin only that
            # unambiguous drive-root form; the JVM receives one property value.
            if ($CourseInput -match '^[A-Za-z]$' -and $i + 1 -lt $args.Count -and
                    ([string]$args[$i + 1]) -match '^[\\/].*') {
                $CourseInput = $CourseInput + ':' + [string]$args[$i + 1]
                $i++
            }
            if ([string]::IsNullOrWhiteSpace($CourseInput)) { Write-UsageFailure '--course= requires a path.' }
            continue
        }
        default {
            [Console]::Error.WriteLine("Warning: ignoring unknown argument '$argument'.")
        }
    }
}

if (-not $CourseFlagSeen -and -not [string]::IsNullOrWhiteSpace($env:GGBPLUS_COURSE)) {
    $CourseInput = $env:GGBPLUS_COURSE
}
$CourseRealPath = $null
if ($CourseInput) {
    $CourseRealPath = Resolve-CoursePath $CourseInput
}

if ($JavaHome -and (Test-Path -LiteralPath (Join-Path $JavaHome 'bin\java.exe'))) {
    $Java = Join-Path $JavaHome 'bin\java.exe'
} elseif ($env:JAVA -and (Test-Path -LiteralPath $env:JAVA -PathType Leaf)) {
    $Java = $env:JAVA
} else {
    $BundledJava = Join-Path $Root 'jre\bin\java.exe'
    if (Test-Path -LiteralPath $BundledJava -PathType Leaf) {
        $Java = $BundledJava
    } else {
        $EclipseHome = 'D:\ALF_ZGit\G2_Eclipse\01_src\eclipse'
        $JrePlugins = Join-Path $EclipseHome 'plugins'
        $JrePlugin = if (Test-Path -LiteralPath $JrePlugins) {
            Get-ChildItem $JrePlugins -Directory -Filter 'org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_25.0.4*' |
                Select-Object -First 1
        }
        if ($JrePlugin) {
            $Java = Join-Path $JrePlugin.FullName 'jre\bin\java.exe'
        }
    }
}
if (-not $Java -or -not (Test-Path -LiteralPath $Java -PathType Leaf)) {
    [Console]::Error.WriteLine('No usable Java runtime found (69).')
    exit 69
}

if (-not $NoBuild -and -not $DryRun) {
    $BuildScript = Join-Path $Root 'build.ps1'
    if (Test-Path -LiteralPath $BuildScript) {
        if ($JavaHome) { & $BuildScript -JavaHome $JavaHome } else { & $BuildScript }
        if ($LASTEXITCODE -ne 0) { throw "build.ps1 failed with exit code $LASTEXITCODE" }
    } else {
        Write-Host 'No build script is present; using the prebuilt installed product image.'
    }
}

$Framework = Get-ChildItem (Join-Path $Root 'bundles') -Filter 'org.eclipse.osgi_*.jar' -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
$Launcher = Get-ChildItem (Join-Path $Root 'launcher') -Filter 'org.eclipse.equinox.launcher_*.jar' -File -ErrorAction SilentlyContinue |
    Select-Object -First 1
if (-not $Framework -or -not $Launcher) { throw 'Missing staged Equinox framework or launcher jar.' }

$RunId = '{0}-{1}-{2}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $PID, ([guid]::NewGuid().ToString('N').Substring(0,8))
$Workspace = Join-Path $Root "workspace\$RunId"
$BaseConfiguration = Join-Path $Root 'configuration'
$Configuration = Join-Path $BaseConfiguration "runtime-$RunId"
$LogDir = Join-Path $Root 'logs'
$Log = Join-Path $LogDir "rcp-$RunId.log"
$Natives = (Get-ChildItem (Join-Path $Root 'natives') -Filter '*.jar' -File | ForEach-Object FullName) -join ';'
$Classpath = @($Framework.FullName, $Launcher.FullName, $Natives) -join ';'
$InstallUrl = 'file:/' + ($Root.Replace('\','/').TrimEnd('/')) + '/'
$HeadlessValue = if ($Headless) { 'true' } else { 'false' }
$NativeExtractDir = if ($ManualNativeFallback) {
    Join-Path $Root "natives\extract-$RunId"
} else {
    $null
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
if ($CourseRealPath) { $JvmArgs += "-Dggbplus.course=$CourseRealPath" }
if ($CaptureEvidenceScreenshot) { $JvmArgs += '-Dggbplus.captureEvidenceScreenshot=true' }
if ($ManualNativeFallback) {
    $JvmArgs += "-Djava.library.path=$NativeExtractDir"
    $JvmArgs += '-Djogamp.gluegen.UseTempJarCache=false'
}
if ($BootDelegateJogAmp) {
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
if ($CourseRealPath) {
    $CourseHash = (Get-FileHash -LiteralPath $CourseRealPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Host "Course: $CourseRealPath"
    Write-Host "Course SHA-256: $CourseHash"
}
Write-Host 'Existing framework storage and build outputs will not be removed.'

if ($DryRun) {
    Write-Host 'GGBPLUS_LAUNCH_DRYRUN=1; final Java argv (no build or process launch):'
    @($JvmArgs + $LauncherArgs) | ForEach-Object { Write-Host "  $_" }
    exit 0
}

New-Item -ItemType Directory -Path $Configuration,$Workspace,$LogDir -Force | Out-Null
Copy-Item (Join-Path $BaseConfiguration 'config.ini') $Configuration
New-Item -ItemType Directory -Path (Join-Path $Configuration 'org.eclipse.equinox.simpleconfigurator') -Force | Out-Null
Copy-Item (Join-Path $BaseConfiguration 'org.eclipse.equinox.simpleconfigurator\bundles.info') `
    (Join-Path $Configuration 'org.eclipse.equinox.simpleconfigurator\bundles.info')
if ($ManualNativeFallback) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
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

Push-Location $Root
try {
    & $Java @JvmArgs @LauncherArgs 2>&1 | Tee-Object -FilePath $Log
    $ExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
Write-Host "Equinox exit code: $ExitCode"
if ($ExitCode -ne 0) { exit $ExitCode }
