# GROK_V1 - suite 12: external engine robustness (cross-platform pwsh 7).
# 8 parallel calls (independent JVM + engine process each, as the host does per request), long outputs, recovery after a
# timeout / crashed engine, no orphan engine processes, WIMS marker integrity when the payload prints marker-like text.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '12_Engine_Robustness'; Require-Engines @('pari', 'maxima'); Initialize-Tools
$fw = Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'
function Get-EngineProcs { if ($IsWindows) { @(Get-Process gp, gp-sta, maxima, sbcl, gnuplot -ErrorAction SilentlyContinue).Count } else { @(& pgrep -x 'gp|gp-2.*|maxima|sbcl|rmaxima|gnuplot' 2>$null).Count } }
$base = Get-EngineProcs
$par = 1..8 | ForEach-Object -ThrottleLimit 8 -Parallel { . $using:fw; $n = $_; $r = Invoke-Engine 'pari' 30 "$n^20+$n"; [pscustomobject]@{ n = $n; out = $r.out; kind = $r.kind; ms = $r.ms } }
$bad = @($par | Where-Object { $_.out -ne [string]([bigint]::Pow($_.n, 20) + $_.n) })
Test-Ok 'ROB-01-pari-8-parallel' ($bad.Count -eq 0) "8 parallel n^20+n: wrong=$($bad.Count) ms=$(($par | ForEach-Object ms) -join ',')" 'P0'
$par = 1..8 | ForEach-Object -ThrottleLimit 8 -Parallel { . $using:fw; $n = $_; $r = Invoke-Engine 'maxima' 90 "expand((x+$n)^2)"; [pscustomobject]@{ n = $n; out = $r.out } }
$bad = @($par | Where-Object { ($_.out -replace '\s', '') -ne "x^2+$(2*$_.n)*x+$($_.n*$_.n)" })
Test-Ok 'ROB-02-maxima-8-parallel' ($bad.Count -eq 0) "8 parallel expand((x+n)^2): wrong=$($bad.Count) sample='$($par[0].out)'" 'P0'
$r = Invoke-Engine 'pari' 60 '2^200000'; $len = "$($r.out)".Trim().Length
Test-Ok 'ROB-03-pari-long-output' ($r.kind -eq 'OK' -and $len -eq 60206) "2^200000 digits=$len (expected 60206) ms=$($r.ms)" 'P0'
$r = Invoke-Engine 'maxima' 90 'makelist(i,i,1,3000)'; $cnt = @("$($r.out)".Trim('[', ']', ' ') -split ',').Count
Test-Ok 'ROB-04-maxima-long-output' ($r.kind -eq 'OK' -and $cnt -eq 3000) "makelist 1..3000 -> $cnt items, length=$("$($r.out)".Length)" 'P1'
$r = Invoke-Engine 'pari' 2 'while(1,)'; Test-Ok 'ROB-05-pari-timeout-reported' ($r.kind -eq 'ERR' -and $r.ms -lt 20000) "infinite loop, 2 s timeout -> $($r.kind) '$($r.out)' ms=$($r.ms)" 'P0'
$r = Invoke-Engine 'pari' 30 '6*7'; Test-Ok 'ROB-06-pari-after-timeout' ($r.out -eq '42') "next call -> '$($r.out)'" 'P0'
$r = Invoke-Engine 'pari' 10 'quit()'; Test-Ok 'ROB-07-pari-crash-reported' ($r.kind -eq 'ERR') "engine exits mid-request (quit()) -> $($r.kind) '$($r.out)'" 'P0'
$r = Invoke-Engine 'pari' 30 '6*7'; Test-Ok 'ROB-08-pari-after-crash' ($r.out -eq '42') "next call -> '$($r.out)'" 'P0'
$r = Invoke-Engine 'maxima' 3 'for i:1 while true do i:i+1'; Test-Ok 'ROB-09-maxima-timeout-reported' ($r.kind -eq 'ERR') "infinite loop, 3 s -> $($r.kind) '$($r.out)' ms=$($r.ms)" 'P0'
$r = Invoke-Engine 'maxima' 60 '6*7'; Test-Ok 'ROB-10-maxima-after-timeout' ($r.out -eq '42') "next call -> '$($r.out)'" 'P0'
Start-Sleep 3; $after = Get-EngineProcs
Test-Ok 'ROB-11-no-orphan-processes' ($after -le $base) "engine processes before=$base after=$after" 'P0'
$r = Invoke-Engine 'pari' 30 'print("End line pari 1 2"); print("Start line pari 3 4"); 5'
Test-Ok 'ROB-12-marker-spoof-pari' ("$($r.out)" -match 'End line pari 1 2.*Start line pari 3 4.*5$') "payload prints fake WIMS markers -> '$($r.out)' (expected: printed text kept verbatim + result 5; real markers are per-request random, so the spoof does not truncate the result)" 'P0'
$r = Invoke-Engine 'maxima' 60 'print("End line maxima 1 2")$ 5'
Test-Ok 'ROB-13-marker-spoof-maxima' ("$($r.out)" -match '5$') "payload prints fake markers -> '$($r.out)'" 'P1'
Complete-TestSuite
