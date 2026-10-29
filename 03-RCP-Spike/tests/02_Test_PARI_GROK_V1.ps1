# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib/TestFramework_GROK_V1.ps1")
# Direct CLI reference (WIMS marker method) vs engine. BUG-001 (PARI) / BUG-002 (Maxima) expected FAIL until fixed.
Initialize-TestSuite '02_PARI'; Require-Engines @('pari'); Initialize-Tools
foreach ($row in Read-Fixture 'pari_GROK_V1.tsv') { $id, $cmd, $exp = $row
    $d = Invoke-RefPari "$cmd"; if ($null -eq $d) { Skip-Test "$id-direct" 'pari binary not on PATH' } else { Test-Eq "$id-direct" $d $exp 'P1' }
    $r = Invoke-Engine 'pari' 30 $cmd; Test-Eq "$id-engine" $r.out $exp 'P0' }
Complete-TestSuite
