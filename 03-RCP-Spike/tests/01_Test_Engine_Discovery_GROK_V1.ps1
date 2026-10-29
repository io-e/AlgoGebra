# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib/TestFramework_GROK_V1.ps1")
Initialize-TestSuite '01_Engine_Discovery'; Initialize-Tools
$missing = @()
foreach ($e in 'pari', 'maxima', 'gnuplot') { $c = Find-EngineBinary $e
    if ($c) { Test-Ok "DISC-$e-path" $true "path=$($c.Source)" 'P0' } else { Skip-Test "DISC-$e-path" "binary not on PATH ($($script:EngineBinaries[$e] -join ', '))" 'P0'; $missing += $e } }
$v = & (Get-JavaTool 'java') -version 2>&1 | Select-Object -First 1; Test-Ok 'DISC-java-21' ("$v" -match '"21\.') "$v" 'P0'
foreach ($e in @(@('pari','2+3'), @('maxima','2+3'), @('gnuplot','plot x')) | Where-Object { $missing -notcontains $_[0] }) { $r = Invoke-Engine $e[0] 30 $e[1]; Test-Ok "DISC-engine-$($e[0])-spawn" ($r.kind -ne 'ERR') "kind=$($r.kind) $($r.ms)ms" 'P0' }
if ($missing) { Write-Host ''; Write-Host "PASS: $script:TF_Pass FAIL: $script:TF_Fail SKIP: $script:TF_Skip"; Write-Host "BAIL OUT - missing engine binaries: $($missing -join ', ')"; exit 2 }
Complete-TestSuite
