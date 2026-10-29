# GROK_V1 - Run_All aggregator, single cross-platform runner (pwsh 7 on Windows and Linux; cf. Claude Run_All_Tests_CLAUDE_V1.ps1).
# Suites 01-13. -SkipRcp skips 08; -SkipUi skips 09/10 (they drive the desktop); 11 (bnd build) and 13 (GeoGebra Gradle baseline) are heavy: opt-in -WithBuild / -WithBaseline.
# Output: results/<runid>/ (git-ignored, runid = yyyyMMdd_HHmmss-<host>). -ExportEvidence <name> copies the run to
# ../evidence/<yyyyMMdd>-<os>-<name>-<runid>/ with MANIFEST_GROK_V1.tsv (commit, date, OS, path/bytes/sha256) for reviewed runs.
param([switch]$SkipRcp, [switch]$SkipUi, [switch]$WithBuild, [switch]$WithBaseline, [string]$ExportEvidence)
$here = $PSScriptRoot; $ts = Get-Date -Format 'yyyyMMdd_HHmmss'; $runId = "$ts-$([Environment]::MachineName)"
$res = Join-Path (Join-Path $here 'results') $runId; New-Item -ItemType Directory -Force $res | Out-Null; $env:RESULTS_DIR = $res; Write-Host "# run id: $runId -> $res"
 $rows = @(); $tp = 0; $tf = 0; $tk = 0; $tb = 0
$suites = @(Get-ChildItem $here -File | Where-Object { $_.Name -match '^\d\d_Test_.*_GROK_V1\.ps1$' } | Sort-Object Name)
if ($suites.Count -eq 0) { Write-Error 'No GROK_V1 test suites found; refusing to report an empty run as passing.'; exit 2 }
foreach ($s in $suites) {
    $n = $s.BaseName -replace '_GROK_V1$', ''; if (($SkipRcp -and $n -like '08_*') -or ($SkipUi -and $n -match '^(09|10)_') -or (-not $WithBuild -and $n -like '11_*') -or (-not $WithBaseline -and $n -like '13_*')) { Write-Host "SKIP $n (not selected)"; continue }
    $log = Join-Path $res "${n}_GROK_V1.log"; & pwsh -NoProfile -ExecutionPolicy Bypass -File $s.FullName *> $log; $rc = $LASTEXITCODE
    $p = 0; $f = 0; $k = 0; $summary = Get-Content $log -Raw
    if ($summary -match 'PASS:\s*(\d+)\s+FAIL:\s*(\d+)\s+SKIP:\s*(\d+)') { $p = [int]$Matches[1]; $f = [int]$Matches[2]; $k = [int]$Matches[3] }
    else { $f = 1; Write-Warning "No test summary in $log (suite crashed or did not complete)." }
    if ($rc -ne 0 -and $rc -ne 2 -and $f -eq 0) { $f = 1 }
    if ($rc -eq 2) { $st = 'BAIL'; $tb++ } elseif ($rc -ne 0 -or $f -gt 0) { $st = 'FAIL' } else { $st = 'PASS' }
    $tp += $p; $tf += $f; $tk += $k
    $rows += [pscustomobject]@{ suite = $n; pass = $p; fail = $f; skip = $k; rc = $rc; status = $st; log = (Split-Path $log -Leaf) }
    Write-Host ("  [{0}] {1,-28} {2,3} pass {3,3} fail {4,3} skip (rc={5})" -f $st, $n, $p, $f, $k, $rc) }
$rows | Export-Csv (Join-Path $res "Run_All_${ts}_GROK_V1.csv") -NoTypeInformation -Encoding UTF8
$gate = if ($tf -eq 0 -and $tb -eq 0) { 'MET' } else { 'NOT MET' }; Write-Host "TOTAL: $tp pass, $tf fail, $tk skip, $tb bail"; Write-Host "GATE: $gate"
if ($ExportEvidence) {
    $os = if ($IsWindows) { 'windows' } elseif ($IsLinux) { 'linux' } else { 'other' }; $commit = (& git -C $here rev-parse --short HEAD 2>$null)
    $ev = Join-Path (Split-Path $here -Parent) "evidence/$($ts.Substring(0, 8))-$os-$ExportEvidence-$runId"
    if (Test-Path $ev) { Write-Error "evidence folder exists (immutable): $ev"; exit 2 }
    Copy-Item $res $ev -Recurse
    $lines = @("# GROK_V1 evidence MANIFEST - immutable", "# run: $runId commit=$commit date=$(Get-Date -Format o) os=$([Environment]::OSVersion.VersionString) pwsh=$($PSVersionTable.PSVersion)",
        "# totals: $tp pass, $tf fail, $tk skip, $tb bail; gate=$gate", "# columns: path<TAB>bytes<TAB>sha256")
    $lines += Get-ChildItem $ev -Recurse -File | Sort-Object FullName | ForEach-Object { "{0}`t{1}`t{2}" -f [IO.Path]::GetRelativePath($ev, $_.FullName).Replace('\', '/'), $_.Length, (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower() }
    $lines | Set-Content (Join-Path $ev 'MANIFEST_GROK_V1.tsv') -Encoding UTF8; Write-Host "# evidence exported: $ev (commit it; logs are force-included by .gitignore rules)" }
exit $(if ($tf -gt 0) { 1 } elseif ($tb -gt 0) { 2 } else { 0 })
