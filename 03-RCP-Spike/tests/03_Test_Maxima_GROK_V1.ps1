# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib\TestFramework_GROK_V1.ps1")
# Direct CLI reference (WIMS marker method) vs engine. BUG-001 (PARI) / BUG-002 (Maxima) expected FAIL until fixed.
Initialize-TestSuite '03_Maxima'; Require-Engines @('maxima'); Initialize-Tools
foreach ($row in Read-Fixture 'maxima_GROK_V1.tsv') { $id, $cmd, $exp = $row
    $d = Invoke-RefMaxima "$cmd;"; if ($null -eq $d) { Skip-Test "$id-direct" 'maxima binary not on PATH' } else { Test-Eq "$id-direct" $d $exp 'P1' }
    $r = Invoke-Engine 'maxima' 60 $cmd; Test-Eq "$id-engine" $r.out $exp 'P0' }
Complete-TestSuite
