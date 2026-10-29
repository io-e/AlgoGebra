# GROK_V1 - Run_All aggregator (Windows twin of Run_All_GROK_V1.sh; cf. Claude Run_All_Tests_CLAUDE_V1.ps1).
param([switch]$SkipRcp)
$here = $PSScriptRoot; $res = Join-Path $here 'results'; New-Item -ItemType Directory -Force $res | Out-Null
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'; $rows = @(); $tp = 0; $tf = 0; $tk = 0
foreach ($s in Get-ChildItem $here -Filter '0[1-8]_Test_*_GROK_V1.ps1' | Sort-Object Name) {
    $n = $s.BaseName -replace '_GROK_V1$', ''; if ($SkipRcp -and $n -like '08_*') { Write-Host "SKIP $n"; continue }
    $log = Join-Path $res "${n}_GROK_V1.log"; & pwsh -NoProfile -ExecutionPolicy Bypass -File $s.FullName *> $log; $rc = $LASTEXITCODE
    $p = 0; $f = 0; $k = 0; if ((Get-Content $log -Raw) -match 'PASS:\s*(\d+)\s+FAIL:\s*(\d+)\s+SKIP:\s*(\d+)') { $p = [int]$Matches[1]; $f = [int]$Matches[2]; $k = [int]$Matches[3] }
    $st = if ($rc -eq 2) { 'BAIL' } elseif ($f -gt 0) { 'FAIL' } else { 'PASS' }; $tp += $p; $tf += $f; $tk += $k
    $rows += [pscustomobject]@{ suite = $n; pass = $p; fail = $f; skip = $k; rc = $rc; status = $st; log = (Split-Path $log -Leaf) }
    Write-Host ("  [{0}] {1,-28} {2,3} pass {3,3} fail {4,3} skip (rc={5})" -f $st, $n, $p, $f, $k, $rc) }
$rows | Export-Csv (Join-Path $res "Run_All_${ts}_GROK_V1.csv") -NoTypeInformation -Encoding UTF8
$gate = if ($tf -eq 0) { 'MET' } else { 'NOT MET' }; Write-Host "TOTAL: $tp pass, $tf fail, $tk skip"; Write-Host "GATE: $gate"
exit $(if ($tf -gt 0) { 1 } else { 0 })
