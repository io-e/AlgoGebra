# GROK_V1 - X-06 Timeout and bad output (desktop). Gate D. Pass (spec): core construction unchanged.
# Precheck: the engine service returns a typed error within the timeout and kills the engine process.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_X-06'; Write-ScenarioHeader 'X-06' 'Timeout and bad output' 'D' 'desktop'
if (-not (Find-EngineBinary 'pari')) { Exit-Bail 'gp not on PATH' }; Initialize-Tools
$r = Invoke-Engine 'pari' 2 'while(1,)'
Test-Ok 'X06-01-timeout-error-in-time' ($r.kind -eq 'ERR' -and $r.ms -lt 20000) "while(1,) timeout 2 s -> $($r.kind) '$($r.out)' ms=$($r.ms)" 'P0'
Start-Sleep 1; $orph = if ($IsWindows) { @(Get-Process gp -ErrorAction SilentlyContinue).Count } else { @(& pgrep -x gp 2>$null).Count }
Test-Ok 'X06-02-engine-process-killed' ($orph -eq 0) "gp processes left=$orph" 'P0'
$r2 = Invoke-Engine 'pari' 30 '2+2'; Test-Ok 'X06-03-next-call-works' ($r2.out -eq '4') "after timeout 2+2 -> '$($r2.out)'" 'P1'
$r3 = Invoke-Engine 'pari' 30 'factor(('; Test-Ok 'X06-04-bad-output-typed-error' ($r3.kind -eq 'ERR') "malformed input -> $($r3.kind) '$($r3.out)'" 'P0'
Skip-Blocked 'X06-05-core-construction-unchanged' 'no product path writes engine output into the construction yet (host integration of the compute service missing)' 'P0'
Complete-TestSuite
