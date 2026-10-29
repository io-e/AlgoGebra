# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib\TestFramework_GROK_V1.ps1")
Initialize-TestSuite '01_Engine_Discovery'; Initialize-Tools
foreach ($b in @(@('gp','gp.exe'), @('maxima','maxima.bat'), @('gnuplot','gnuplot.exe'))) { $c = Get-Command $b -ErrorAction SilentlyContinue | Select-Object -First 1
    Test-Ok "DISC-$($b[0])-path" ([bool]$c) "path=$(if ($c) { $c.Source } else { 'absent' })" 'P0' }
$v = & (Join-Path $env:JAVA_HOME 'bin\java.exe') -version 2>&1 | Select-Object -First 1; Test-Ok 'DISC-java-21' ("$v" -match '"21\.') "$v" 'P0'
foreach ($e in @(@('pari','2+3'), @('maxima','2+3'), @('gnuplot','plot x'))) { $r = Invoke-Engine $e[0] 30 $e[1]; Test-Ok "DISC-engine-$($e[0])-spawn" ($r.kind -ne 'ERR') "kind=$($r.kind) $($r.ms)ms" 'P0' }
Complete-TestSuite
