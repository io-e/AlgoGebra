# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib\TestFramework_GROK_V1.ps1")
Initialize-TestSuite '07_CAS_Equivalence'; Require-Engines @('pari','maxima'); Initialize-Tools
foreach ($row in Read-Fixture 'equiv_GROK_V1.tsv') { $id, $g, $p, $m, $exp = $row
    $gr = Invoke-RefGiac $g; if ($null -eq $gr) { Skip-Test "$id-giac" 'GIAC JNI unavailable' } else { Test-Eq "$id-giac" $gr $exp }
    if ($p -eq '-') { Skip-Test "$id-pari" 'not applicable' } else { Test-Eq "$id-pari" (Invoke-Engine 'pari' 30 $p).out $exp }
    if ($m -eq '-') { Skip-Test "$id-maxima" 'not applicable' } else { Test-Eq "$id-maxima" (Invoke-Engine 'maxima' 60 $m).out $exp } }
Complete-TestSuite
