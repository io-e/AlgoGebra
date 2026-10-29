# GROK_V1 - helpers for scenario scripts S_<ID>_*.ps1 (cross-platform pwsh 7; heavy client = RCP image).
# Product driving: the host's opt-in test hook (-Dggbplus.scenario=<tsv>, -Dggbplus.scenarioExit=true, passed via
# JAVA_TOOL_OPTIONS) runs ScenarioScript directives and prints "[GeoGebraPlus] SCN<TAB>id<TAB>OK|ERR<TAB>value".
# Baseline: tests/tools/ScenarioBaseline_GROK_V1.java runs the same directives against the pinned upstream desktop
# distribution (plain classpath, no OSGi). Env: GGB_BASELINE_LIB (upstream lib dir), BASELINE_JAVA (Java 25).
$script:ScnDir = Split-Path $PSScriptRoot -Parent
. (Join-Path (Split-Path $script:ScnDir -Parent) 'lib/TestFramework_GROK_V1.ps1')
. (Join-Path (Split-Path $script:ScnDir -Parent) 'lib/UiDriver_GROK_V1.ps1')
$script:ScnFix = Join-Path $script:ScnDir 'fixtures'
$script:Repo = Split-Path $script:SpikeDir -Parent
$script:GgbSource = if ($env:GGB_SOURCE) { $env:GGB_SOURCE } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\source' } else { '/workspace/AlgoGebra/geogebra/source' }
$script:BaselineLib = if ($env:GGB_BASELINE_LIB) { $env:GGB_BASELINE_LIB } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\ggb-baseline\desktop\lib' } else { '/workspace/AlgoGebra/ggb-baseline/desktop/lib' }
$script:Pin = '375db7faf5407390bb322165f2414415da8faeda'; $script:PinVersion = '5.4.934.0'
$script:Launcher = Join-Path $script:Image ($IsWindows ? 'launch.ps1' : 'launch.sh')
$script:HostJar = Join-Path $script:Image 'host/build/org.geogebra.plus.host_0.1.0.jar'

function Write-ScenarioHeader([string]$Id, [string]$Title, [string]$Gate, [string]$Client) {
    $c = (& git -C $script:Repo rev-parse --short HEAD 2>$null)
    Write-Host "# Scenario: $Id - $Title | gate $Gate | client $Client"
    Write-Host "# Evidence: commit=$c image=$script:Image pin=$script:Pin version=$script:PinVersion os=$([Environment]::OSVersion.VersionString) pwsh=$($PSVersionTable.PSVersion)" }
function Skip-Blocked([string]$Id, [string]$BlockedBy, [string]$Pr = 'P1') { Skip-Test $Id "NOT RUN - blocked by: $BlockedBy" $Pr }
function Test-ImagePresent { if (-not (Test-Path $script:Launcher)) { Exit-Bail "RCP image not found: $script:Image (set IMAGE)" } }
function Parse-Scn([string]$Text) { $h = [ordered]@{}
    foreach ($l in ($Text -split "`r?`n")) { if ($l -match '\[GeoGebraPlus\] SCN\t([^\t]*)\t(OK|ERR)\t(.*)$') { $h[$Matches[1]] = [pscustomobject]@{ St = $Matches[2]; Val = $Matches[3] } } }; return $h }
# Runs a directive file in the RCP product (UI, Xvfb on Linux). Returns @{ Scn; Log; Text }.
function Invoke-ProductScenario([string]$Name, [string]$Directives, [int]$TimeoutSec = 180, [hashtable]$Env = @{}, [string[]]$Wrapper = @()) {
    $tsv = Join-Path $script:Res "$Name.directives.tsv"; Set-Content $tsv $Directives -Encoding UTF8
    $props = "-Dggbplus.scenario=$tsv -Dggbplus.scenarioExit=true"; if ($Env['JAVA_TOOL_OPTIONS']) { $props = "$($Env['JAVA_TOOL_OPTIONS']) $props" }
    $e = @{} + $Env; $e['JAVA_TOOL_OPTIONS'] = $props
    $log = Join-Path $script:Res "$Name.log"; $saved = @{}
    foreach ($k in $e.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k); [Environment]::SetEnvironmentVariable($k, $e[$k]) }
    if ($IsWindows) { $p = Start-Process pwsh -ArgumentList @('-NoProfile', '-File', $script:Launcher) -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru -WindowStyle Hidden }
    else { $cmd = @($Wrapper) + @('bash', $script:Launcher); $p = Start-Process $cmd[0] -ArgumentList ($cmd | Select-Object -Skip 1) -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru }
    foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k]) }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec -and -not $p.HasExited) { Start-Sleep 1; if ((Test-Path $log) -and ((Get-Content $log -Raw) -match 'SCN\t_(END|FATAL)')) { break } }
    for ($i = 0; $i -lt 15 -and -not $p.HasExited; $i++) { Start-Sleep 1 }
    if (-not $p.HasExited) { Stop-UiApp }
    $t = (Get-Content $log -Raw) + "`n" + ((Test-Path "$log.err") ? (Get-Content "$log.err" -Raw) : '')
    return @{ Scn = (Parse-Scn $t); Log = $log; Text = $t; Seconds = [int]$sw.Elapsed.TotalSeconds } }
function Get-BaselineJava { if ($env:BASELINE_JAVA) { return $env:BASELINE_JAVA }
    $j = if ($IsWindows) { Join-Path $script:Image 'jre/bin/java.exe' } else { '/workspace/AlgoGebra/jdk/jdk-25.0.5+8/bin/java' }; return $j }
function Invoke-BaselineScenario([string]$Name, [string]$Directives, [int]$TimeoutSec = 180) {
    if (-not (Test-Path $script:BaselineLib)) { return $null }
    $out = Join-Path $script:Tmp "grok-baseline-tools"; New-Item -ItemType Directory -Force $out | Out-Null
    $cp = "$(Join-Path $script:BaselineLib '*')$($script:Sep)$script:HostJar"
    & (Get-JavaTool 'javac') -d $out -cp $cp (Join-Path (Split-Path $script:ScnDir -Parent) 'tools/ScenarioBaseline_GROK_V1.java') 2>&1 | Out-Null
    $tsv = Join-Path $script:Res "$Name.baseline.directives.tsv"; Set-Content $tsv $Directives -Encoding UTF8; $log = Join-Path $script:Res "$Name.baseline.log"
    $jargs = @('--add-exports', 'java.base/java.lang=ALL-UNNAMED', '--add-exports', 'java.desktop/sun.awt=ALL-UNNAMED', '--add-exports', 'java.desktop/sun.java2d=ALL-UNNAMED', '--enable-native-access=ALL-UNNAMED', '-cp', "$cp$($script:Sep)$out", 'ScenarioBaseline_GROK_V1', $tsv)
    $r = Invoke-Process (Get-BaselineJava) $jargs '' ($TimeoutSec * 1000); Set-Content $log $r.out
    return @{ Scn = (Parse-Scn $r.out); Log = $log; Text = $r.out } }
function Norm-Val([string]$v) { ($v -replace '\s+', ' ').Trim() }
# Compare product vs baseline for each directive id (ENV excluded); numeric tolerance 1e-9 on "name = number" values.
function Compare-Scn($Prod, $Base, [string]$Prefix, [string[]]$Skip = @('ENV', '_BEGIN', '_END'), [string]$Pr = 'P0') {
    foreach ($k in $Base.Keys) { if ($Skip -contains $k) { continue }
        $b = $Base[$k]; $p = $Prod[$k]
        if (-not $p) { Test-Ok "$Prefix-$k" $false "missing in product; baseline=$($b.St) '$($b.Val)'" $Pr; continue }
        $eq = ($p.St -eq $b.St) -and ((Norm-Val $p.Val) -eq (Norm-Val $b.Val))
        if (-not $eq -and $p.Val -match '=\s*(-?[\d.E+-]+)$') { $pv = [double]$Matches[1]; if ($b.Val -match '=\s*(-?[\d.E+-]+)$') { $eq = ($p.St -eq $b.St) -and [math]::Abs($pv - [double]$Matches[1]) -le 1e-9 } }
        Test-Ok "$Prefix-$k" $eq "product=$($p.St) '$($p.Val)' baseline=$($b.St) '$($b.Val)'" $Pr } }
# Equinox resolution probe (02-Cdc harness) on the image's 50 GeoGebra bundles + extra test bundles. Returns @{ States; Text }.
function New-TestBundle([string]$Dir, [string]$Bsn, [string]$Version, [string[]]$Headers) {
    $w = Join-Path $script:Tmp "grok-tb-$Bsn-$PID"; New-Item -ItemType Directory -Force (Join-Path $w 'META-INF') | Out-Null
    $mf = @('Manifest-Version: 1.0', 'Bundle-ManifestVersion: 2', "Bundle-SymbolicName: $Bsn", "Bundle-Version: $Version") + $Headers + @('')
    Set-Content (Join-Path $w 'META-INF/MANIFEST.MF') ($mf -join "`n") -NoNewline -Encoding ascii; Add-Content (Join-Path $w 'META-INF/MANIFEST.MF') "`n"
    & (Get-JavaTool 'jar') cfm (Join-Path $Dir "$Bsn-$Version.jar") (Join-Path $w 'META-INF/MANIFEST.MF') -C $w META-INF/MANIFEST.MF 2>&1 | Out-Null
    return (Join-Path $Dir "$Bsn-$Version.jar") }
function Invoke-ResolveProbe([string]$Name, [scriptblock]$AddBundles) {
    $stage = Join-Path $script:Tmp "grok-probe-$Name-$PID"; Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force $stage | Out-Null
    Get-ChildItem (Join-Path $script:Image 'bundles') -Filter '*.jar' | Where-Object Name -notlike 'org.eclipse.osgi_*' | Copy-Item -Destination $stage
    & $AddBundles $stage
    $osgi = (Get-ChildItem (Join-Path $script:Image 'bundles') -Filter 'org.eclipse.osgi_*.jar' | Select-Object -First 1).FullName
    $hc = Join-Path $script:Tmp 'grok-harness'; New-Item -ItemType Directory -Force $hc | Out-Null
    if (-not (Test-Path (Join-Path $hc 'EquinoxResolveHarness.class'))) { & (Get-JavaTool 'javac') -d $hc -cp $osgi (Join-Path $script:Repo '02-Cdc/Bnd_Equinox_Resolution_Win64/EquinoxResolveHarness.java') 2>&1 | Out-Null }
    $r = Invoke-Process (Get-JavaTool 'java') @('-cp', "$hc$($script:Sep)$osgi", 'EquinoxResolveHarness', $stage, (Join-Path $stage '.storage')) '' 120000
    $log = Join-Path $script:Res "$Name.resolve.log"; Set-Content $log $r.out
    $st = @{}; foreach ($l in ($r.out -split "`r?`n")) { $f = $l -split "`t"; if ($f.Count -ge 4 -and $f[2] -match '^(INSTALLED|RESOLVED|ACTIVE|STARTING)$') { $st[$f[0]] = $f[2] } }
    return @{ States = $st; Text = $r.out; Log = $log; Core = @($st.Keys | Where-Object { $_ -like 'org.geogebra.migration.*' -or $_ -in 'com.sun.jna', 'org.jspecify.jspecify', 'org.jsr-305', 'spotbugs-annotations' }) } }
function Get-CoreResolvedCount($Probe) { @($Probe.Core | Where-Object { $Probe.States[$_] -eq 'RESOLVED' }).Count }
# Copy the image to a temp folder (without runtime-*/logs/workspace-*) and drop bundles.info lines matching $DropRegex.
# Returns the copy path; use Use-Image to point Invoke-ProductScenario at it.
function New-ImageCopy([string]$Name, [string]$DropRegex = '') {
    $dst = Join-Path $script:Tmp "grok-img-$Name-$PID"; Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $dst | Out-Null
    Get-ChildItem $script:Image | Where-Object { $_.Name -notmatch '^(logs|workspace-.*)$' } | Copy-Item -Destination $dst -Recurse
    Get-ChildItem (Join-Path $dst 'configuration') -Directory -Filter 'runtime-*' | Remove-Item -Recurse -Force
    if ($DropRegex) { $bi = Join-Path $dst 'configuration/org.eclipse.equinox.simpleconfigurator/bundles.info'
        $keep = @(Get-Content $bi | Where-Object { -not ($_ -match $DropRegex) }); Set-Content $bi $keep -Encoding ascii }
    return $dst }
function Use-Image([string]$Path) { $script:Image = $Path; $script:Launcher = Join-Path $Path ($IsWindows ? 'launch.ps1' : 'launch.sh'); $script:HostJar = Join-Path $Path 'host/build/org.geogebra.plus.host_0.1.0.jar' }
