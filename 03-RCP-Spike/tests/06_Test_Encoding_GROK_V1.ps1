# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib\TestFramework_GROK_V1.ps1")
Initialize-TestSuite '06_Encoding'; Initialize-Tools
foreach ($row in Read-Fixture 'encoding_GROK_V1.tsv') { $id, $e, $cmd, $exp = $row
    $d = if ($e -eq 'pari') { Invoke-RefPari $cmd } else { Invoke-RefMaxima "$cmd;" }
    if ($null -eq $d) { Skip-Test "$id-$e-direct" 'binary not on PATH' } else { Test-Eq "$id-$e-direct" $d $exp }
    $r = Invoke-Engine $e 60 $cmd; Test-Eq "$id-$e-engine" $r.out $exp 'P0' }
$r = Invoke-Engine 'gnuplot' 30 'plot sin(x) title "sinus é à ü €"'; $p, $n, $dim, $del = "$($r.out)" -split "`t"
Test-Ok 'ENC-10-gnuplot-accented-title' ($r.kind -eq 'ART' -and $dim -eq '800x600') "kind=$($r.kind) dim=$dim"
Complete-TestSuite
