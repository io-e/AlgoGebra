# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib/TestFramework_GROK_V1.ps1")
Initialize-TestSuite '05_Sandbox'; Require-Engines @('pari','maxima','gnuplot'); Initialize-Tools
foreach ($row in Read-Fixture 'sandbox_GROK_V1.tsv') { $id, $e, $cmd, $pol = $row
    $cmd = $cmd -replace '/tmp/', ($script:Tmp.Replace('\','/').TrimEnd('/') + '/'); $r = Invoke-Engine $e 3 $cmd
    switch ($pol) {
        'REJECT'  { Test-Ok "$id-$e-reject" ($r.kind -eq 'ERR' -and $r.out -match 'blocked|forbid|not allowed|rejected') "cmd=$cmd -> $($r.kind) $($r.out)" 'P0' }
        'NOEXEC'  { Test-Ok "$id-$e-noexec" ($r.out -notmatch 'uid=|\\Users\\') "cmd=$cmd -> $($r.kind)" 'P0' }
        'TIMEOUT' { Test-Ok "$id-$e-timeout" ($r.kind -eq 'ERR' -and $r.ms -lt 15000) "budget=3s elapsed=$($r.ms)ms -> $($r.out)" 'P0' } } }
$w = Get-ChildItem $script:Tmp -Filter 'algogebra_sbx_*' -ErrorAction SilentlyContinue; Test-Ok 'SBX-99-no-files-written' (-not $w) "$($w.Name)" 'P0'
Complete-TestSuite
