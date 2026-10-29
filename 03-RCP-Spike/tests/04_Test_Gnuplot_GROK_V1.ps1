# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib/TestFramework_GROK_V1.ps1")
Initialize-TestSuite '04_Gnuplot'; Require-Engines @('gnuplot'); Initialize-Tools
foreach ($c in @('plot sin(x)', 'plot sin(x), cos(x)', 'splot x*y')) { $r = Invoke-Engine 'gnuplot' 30 $c; $p, $n, $dim, $del = "$($r.out)" -split "`t"
    Test-Ok "GNU-engine-[$c]" ($r.kind -eq 'ART' -and $dim -eq '800x600' -and [int64]$n -gt 1000) "kind=$($r.kind) size=$n dim=$dim" 'P0'
    Test-Ok "GNU-cleanup-[$c]" ($del -eq 'true' -and -not (Test-Path $p)) "deletedAfterClose=$del path=$p" 'P1' }
Complete-TestSuite
