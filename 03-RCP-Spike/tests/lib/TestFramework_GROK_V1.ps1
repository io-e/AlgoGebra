# GROK_V1 - shared PowerShell test framework for the AlgoGebra test pack (Windows twin of tf_GROK_V1.sh).
# Modelled on Claude's lib\TestFramework_CLAUDE_V1.ps1: TAP lines, priorities, PASS/FAIL/SKIP counters,
# "PASS: n FAIL: n SKIP: n" summary, per-suite CSV. Exit 0 = all pass, 1 = FAIL, 2 = BAIL OUT.
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$script:TestsDir = Split-Path -Parent $PSScriptRoot
$script:SpikeDir = Split-Path -Parent $script:TestsDir
$script:Fix = Join-Path $script:TestsDir 'fixtures'
$script:Res = if ($env:RESULTS_DIR) { $env:RESULTS_DIR } else { Join-Path $script:TestsDir 'results' }
New-Item -ItemType Directory -Force $script:Res | Out-Null
# Cross-platform (pwsh 7 on Windows and Linux).
$script:Sep = [IO.Path]::PathSeparator; $script:Exe = if ($IsWindows) { '.exe' } else { '' }
$script:Tmp = [IO.Path]::GetTempPath()
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = if ($IsWindows) { 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot' } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-21*' -ErrorAction SilentlyContinue | Select-Object -First 1).FullName } }
function Get-JavaTool([string]$Name) { Join-Path (Join-Path $env:JAVA_HOME 'bin') ($Name + $script:Exe) }
$script:Image = if ($env:IMAGE) { $env:IMAGE } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8' } else { '/workspace/AlgoGebra/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64' }
$script:ToolsOut = [IO.Path]::Combine($script:SpikeDir, 'host', 'build', 'test-tools-ps1')
$script:TestPassCount = 0; $script:TestFailCount = 0; $script:TestSkipCount = 0; $script:TestNumber = 0
function Initialize-TestSuite([string]$Name) {
    $script:Suite = $Name; $script:Csv = Join-Path $script:Res "${Name}_GROK_V1.csv"
    'suite,num,id,status,priority,detail,ts' | Set-Content $script:Csv -Encoding UTF8
    Write-Host "# Suite: $Name"; Write-Host "# Started: $(Get-Date -Format o)"
    Write-Host "# Host: $([Environment]::MachineName) / $([Runtime.InteropServices.RuntimeInformation]::OSDescription) / pwsh $($PSVersionTable.PSVersion)"; Write-Host ''
}
function Add-Row($id, $st, $pr, $d) { "$script:Suite,$script:TestNumber,$id,$st,$pr,`"$($d -replace '"','""')`",$(Get-Date -Format o)" | Add-Content $script:Csv -Encoding UTF8 }
function Test-Ok([string]$Id, [bool]$Cond, [string]$Detail = '', [string]$Pr = 'P1') {
    $script:TestNumber++
    if ($Cond) { $script:TestPassCount++; Write-Host "ok $script:TestNumber - [$Pr] $Id :: $Detail" -ForegroundColor Green; Add-Row $Id PASS $Pr $Detail }
    else { $script:TestFailCount++; Write-Host "not ok $script:TestNumber - [$Pr] $Id :: $Detail" -ForegroundColor Red; Add-Row $Id FAIL $Pr $Detail }
}
function Skip-Test([string]$Id, [string]$Reason, [string]$Pr = 'P1') { $script:TestNumber++; $script:TestSkipCount++; Write-Host "ok $script:TestNumber - [$Pr] $Id # SKIP $Reason" -ForegroundColor Yellow; Add-Row $Id SKIP $Pr $Reason }
function Exit-Bail([string]$Why) { Write-Host "BAIL OUT - $Why"; Write-Host "PASS: $script:TestPassCount FAIL: $script:TestFailCount SKIP: $script:TestSkipCount"; exit 2 }
function Complete-TestSuite { Write-Host ''; Write-Host "PASS: $script:TestPassCount FAIL: $script:TestFailCount SKIP: $script:TestSkipCount"; Write-Host "# CSV: $script:Csv"; exit $(if ($script:TestFailCount -gt 0) { 1 } else { 0 }) }
function Norm([string]$s) { if ($null -eq $s) { return '' }; $o = $s -replace '\s', ''; if ($s.StartsWith('Mat(') -and $o.EndsWith(')')) { $o = $o.Substring(4, $o.Length - 5) }
    if ($o.StartsWith('[') -and $o.EndsWith(']')) { $o = $o.Substring(1, $o.Length - 2) }; return $o }
function Test-Eq([string]$Id, [string]$Got, [string]$Exp, [string]$Pr = 'P1') {
    if ((Norm $Got) -eq (Norm $Exp)) { Test-Ok $Id $true "got=$Got" $Pr } else { Test-Ok $Id $false "expected=$Exp got=$Got" $Pr } }
function Read-Fixture([string]$Name) { Get-Content (Join-Path $script:Fix $Name) -Encoding UTF8 | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { ,($_ -split "`t") } }
function Get-EngineCp { $b = [IO.Path]::Combine($script:SpikeDir, 'host', 'build')
    (@($script:ToolsOut) + @('compute.api', 'compute.runtime', 'engine.pari', 'engine.maxima', 'engine.gnuplot' | ForEach-Object { Join-Path $b "org.geogebra.plus.${_}_0.1.0.jar" })) -join $script:Sep }
function Initialize-Tools {
    $javac = Get-JavaTool 'javac'; if (-not (Test-Path $javac)) { Exit-Bail "JDK 21 not found ($env:JAVA_HOME)" }
    if (-not (Test-Path ([IO.Path]::Combine($script:SpikeDir, 'host', 'build', 'org.geogebra.plus.engine.pari_0.1.0.jar')))) { Exit-Bail 'engine bundles not built: run 03-RCP-Spike\build.ps1 first (host\build\org.geogebra.plus.engine.*_0.1.0.jar)' }
    New-Item -ItemType Directory -Force $script:ToolsOut | Out-Null
    & $javac -encoding UTF-8 -d $script:ToolsOut -cp (Get-EngineCp) ([IO.Path]::Combine($script:TestsDir, 'tools', 'EngineCli_GROK_V1.java')); if ($LASTEXITCODE -ne 0) { Exit-Bail 'EngineCli compile failed' }
}
function Invoke-Process([string]$Exe, [string[]]$ArgList, [string]$StdIn, [int]$TimeoutMs = 60000) {
    $psi = [Diagnostics.ProcessStartInfo]::new($Exe); foreach ($a in $ArgList) { $psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8; $psi.CreateNoWindow = $true
    $p = [Diagnostics.Process]::Start($psi); $bytes = [Text.UTF8Encoding]::new($false).GetBytes($StdIn)
    $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length); $p.StandardInput.Close()
    $o = $p.StandardOutput.ReadToEndAsync(); $null = $p.StandardError.ReadToEndAsync()
    if (-not $p.WaitForExit($TimeoutMs)) { try { $p.Kill($true) } catch {}; return @{ rc = 124; out = '' } }
    return @{ rc = $p.ExitCode; out = $o.Result }
}
# Engine driver -> @{kind; out; ms}
function Invoke-Engine([string]$Engine, [int]$TimeoutSec, [string]$Command) {
    $sw = [Diagnostics.Stopwatch]::StartNew(); $java = Get-JavaTool 'java'
    $r = Invoke-Process $java @('-Dfile.encoding=UTF-8', '-Dstdout.encoding=UTF-8', '-cp', (Get-EngineCp), 'EngineCli_GROK_V1', $Engine, "$TimeoutSec") $Command (($TimeoutSec + 30) * 1000)
    $line = ($r.out -split "`r?`n" | Where-Object { $_ } | Select-Object -Last 1); $kind, $rest = $line -split "`t", 2
    return @{ kind = $kind; out = $rest; ms = $sw.ElapsedMilliseconds }
}
# Direct references reproducing WIMS src/Interfaces/common.c (header, start marker, command, end marker; keep text after LAST start marker).
function Get-WimsHeader([string]$Rel) { $t = Get-Content ([IO.Path]::Combine($script:SpikeDir, 'engines', $Rel.Replace('\', [IO.Path]::DirectorySeparatorChar))) -Raw
    $m = [regex]::Match($t, 'WIMS_HEADER = [^\r\n]*"""\r?\n(.*?)""";', 'Singleline'); return ($m.Groups[1].Value -split "`r?`n" | ForEach-Object { $_ -replace '^ {12}', '' }) -join "`n" }
function Get-Between([string]$Out, [string]$Start, [string]$End) {
    $lines = $Out -split "`r?`n"; $acc = $null; $res = ''
    foreach ($l in $lines) { $markerLine = $l.Replace('"', '').Trim(); if ($markerLine -eq $Start) { $acc = @(); continue }; if ($markerLine -eq $End) { $res = ($acc | Where-Object { $_ -ne '' }) -join ' '; $acc = $null; continue }; if ($null -ne $acc) { $acc += $l.Trim() } }
    return $res.Trim() }
function Invoke-RefPari([string]$Cmd) { $gp = (Get-Command $script:EngineBinaries['pari'] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source; if (-not $gp) { return $null }
    $m = "Start line pari $PID $(Get-Random)"; $e = "End line pari $PID $(Get-Random)"
    $in = "\p 20`n" + (Get-WimsHeader 'pari\src\org\geogebra\plus\engine\pari\PariGPEngine.java') + "`nprint(`"$m`")`n$Cmd`nprint(`"$e`")`nquit`n"
    return Get-Between (Invoke-Process $gp @('-f', '-q') $in 30000).out $m $e }
function Invoke-RefMaxima([string]$Cmd) { $mx = (Get-Command $script:EngineBinaries['maxima'] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1).Source; if (-not $mx) { return $null }
    $m = "start line maxima $PID $(Get-Random)"; $e = "end line maxima $PID $(Get-Random)"
    $in = "fpprec:20;`n" + (Get-WimsHeader 'maxima\src\org\geogebra\plus\engine\maxima\MaximaEngine.java') + "`ndisplay2d:false`$`n`"$m`";`n$Cmd`n`"$e`";`nquit();`n"
    return Get-Between (Invoke-Process $mx @('--very-quiet') $in 60000).out $m $e }
function Invoke-RefGiac([string]$Expr) { $gj = Get-ChildItem (Join-Path $script:Image 'bundles') -Filter 'org.geogebra.migration.shared.giac.jni-*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
    $nat = if ($IsWindows) { 'windows' } else { 'linux' }; $lib = if ($IsWindows) { 'javagiac64.dll' } else { 'libjavagiac64.so' }
    $nj = Get-ChildItem (Join-Path $script:Image 'natives') -Filter "javagiac-*-natives-$nat-amd64.jar" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $gj -or -not $nj) { return $null }; $gd = Join-Path $script:ToolsOut 'giac'; $dll = Join-Path $gd $lib
    if (-not (Test-Path $dll)) { New-Item -ItemType Directory -Force $gd | Out-Null; Add-Type -AssemblyName System.IO.Compression.FileSystem; [IO.Compression.ZipFile]::ExtractToDirectory($nj.FullName, $gd, $true) }
    if (-not (Test-Path (Join-Path $script:ToolsOut 'GiacCli_GROK_V1.class'))) { & (Get-JavaTool 'javac') -d $script:ToolsOut -cp $gj.FullName ([IO.Path]::Combine($script:TestsDir, 'tools', 'GiacCli_GROK_V1.java')) }
    return (Invoke-Process (Get-JavaTool 'java') @("-Dgiac.lib=$dll", '-cp', "$($script:ToolsOut)$($script:Sep)$($gj.FullName)", 'GiacCli_GROK_V1', $Expr) '' 60000).out.Trim() }

# Missing CAS binary => clean BAIL OUT (exit 2), never a crash or a false FAIL.
$script:EngineBinaries = if ($IsWindows) { @{ pari = @('gp.exe'); maxima = @('maxima.bat', 'maxima.exe'); gnuplot = @('gnuplot.exe') } } else { @{ pari = @('gp'); maxima = @('maxima'); gnuplot = @('gnuplot') } }
function Find-EngineBinary([string]$Engine) { Get-Command $script:EngineBinaries[$Engine] -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 }
function Require-Engines([string[]]$Engines) { foreach ($e in $Engines) { if (-not (Find-EngineBinary $e)) { Exit-Bail "$e binary not on PATH ($($script:EngineBinaries[$e] -join ', ')); install it or extend PATH" } } }
