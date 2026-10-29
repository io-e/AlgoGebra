# GROK_V1 - Run_All aggregator, single cross-platform runner (pwsh 7 on Windows and Linux; cf. Claude Run_All_Tests_CLAUDE_V1.ps1).
# Suites 01-13. -SkipRcp skips 08; -SkipUi skips 09/10 (they drive the desktop); 11 (bnd build) and 13 (GeoGebra Gradle baseline) are heavy: opt-in -WithBuild / -WithBaseline.
# Output: results/<runid>/ (git-ignored, runid = yyyyMMdd_HHmmss-<host>). -ExportEvidence <name> copies the run to
# ../evidence/<yyyyMMdd>-<os>-<name>-<runid>/ with MANIFEST_GROK_V1.tsv (commit, date, OS, path/bytes/sha256) for reviewed runs.
# Scenarios (spec section 5): -Scenarios runs scenarios/S_*_GROK_V1.ps1 instead of the suites; -Gate A|B|C|D|E keeps the gate's
# scenarios; -Only 'P-02','D-06' keeps the listed ids. Each scenario gets a verdict: FAIL (any failed check), NOT RUN (a P0
# check is blocked and nothing passed), PARTIAL (a P0 check is blocked), PASS (all P0 checks ran and passed). See
# SCENARIOS_TRACKING_GROK_V1.md.
param([switch]$SkipRcp, [switch]$SkipUi, [switch]$WithBuild, [switch]$WithBaseline, [string]$ExportEvidence,
      [switch]$Scenarios, [ValidateSet('A', 'B', 'C', 'D', 'E')][string]$Gate, [string[]]$Only)
$gates = @{ A = 'P-02', 'P-03', 'P-04', 'P-05'; B = 'D-02', 'D-03', 'D-04', 'D-05', 'D-06'; C = 'W-01', 'W-02'
            D = 'X-01', 'X-02', 'X-03', 'X-04', 'X-05', 'X-06', 'S-01', 'S-02', 'S-03', 'S-04', 'S-05'; E = 'O-02', 'O-03', 'D-09', 'W-04' }
# D-02..D-05 are covered by suites 08/09/10/11 (no duplicate scenario script); a -Gate B run adds them.
$scnSuites = @{ 'D-02' = '08_'; 'D-03' = '11_'; 'D-04' = '09_'; 'D-05' = '10_' }
$here = $PSScriptRoot; $ts = Get-Date -Format 'yyyyMMdd_HHmmss'; $runId = "$ts-$([Environment]::MachineName)"
$res = Join-Path (Join-Path $here 'results') $runId; New-Item -ItemType Directory -Force $res | Out-Null; $env:RESULTS_DIR = $res; Write-Host "# run id: $runId -> $res"
 $rows = @(); $tp = 0; $tf = 0; $tk = 0; $tb = 0
$suites = @(Get-ChildItem $here -File | Where-Object { $_.Name -match '^\d\d_Test_.*_GROK_V1\.ps1$' } | Sort-Object Name)
if ($Scenarios -or $Gate -or $Only) { $Scenarios = $true
    $want = @(if ($Gate) { $gates[$Gate] }) + @($Only | Where-Object { $_ }); if ($want.Count -gt 0) { Write-Host "# scenario filter: $($want -join ', ')" }
    $sc = @(Get-ChildItem (Join-Path $here 'scenarios') -File -Filter 'S_*_GROK_V1.ps1' | Where-Object { $want.Count -eq 0 -or ($_.Name -replace '^S_([A-Z]-\d\d)_.*', '$1') -in $want } | Sort-Object Name)
    $su = @($suites | Where-Object { $p = $_.Name.Substring(0, 3); $want.Count -gt 0 -and @($want | Where-Object { $scnSuites[$_] -eq $p }).Count -gt 0 })
    $suites = $sc + $su; Write-Host "# selected: $($suites.Count) scripts" }
if ($suites.Count -eq 0) { Write-Error 'No GROK_V1 test suites found; refusing to report an empty run as passing.'; exit 2 }
foreach ($s in $suites) {
    $n = $s.BaseName -replace '_GROK_V1$', ''; if (-not $Scenarios -and (($SkipRcp -and $n -like '08_*') -or ($SkipUi -and $n -match '^(09|10)_') -or (-not $WithBuild -and $n -like '11_*') -or (-not $WithBaseline -and $n -like '13_*'))) { Write-Host "SKIP $n (not selected)"; continue }
    $log = Join-Path $res "${n}_GROK_V1.log"; & pwsh -NoProfile -ExecutionPolicy Bypass -File $s.FullName *> $log; $rc = $LASTEXITCODE
    $p = 0; $f = 0; $k = 0; $summary = Get-Content $log -Raw
    if ($summary -match 'PASS:\s*(\d+)\s+FAIL:\s*(\d+)\s+SKIP:\s*(\d+)') { $p = [int]$Matches[1]; $f = [int]$Matches[2]; $k = [int]$Matches[3] }
    else { $f = 1; Write-Warning "No test summary in $log (suite crashed or did not complete)." }
    if ($rc -ne 0 -and $rc -ne 2 -and $f -eq 0) { $f = 1 }
    if ($rc -eq 2) { $st = 'BAIL'; $tb++ } elseif ($rc -ne 0 -or $f -gt 0) { $st = 'FAIL' } else { $st = 'PASS' }
    $tp += $p; $tf += $f; $tk += $k
    $p0skip = ([regex]::Matches($summary, '(?m)^ok \d+ - \[P0\] .*# SKIP')).Count
    $verdict = if ($f -gt 0 -or $st -eq 'FAIL') { 'FAIL' } elseif ($st -eq 'BAIL') { 'NOT RUN' } elseif ($p0skip -gt 0 -and $p -eq 0) { 'NOT RUN' } elseif ($p0skip -gt 0) { 'PARTIAL' } else { 'PASS' }
    $rows += [pscustomobject]@{ suite = $n; pass = $p; fail = $f; skip = $k; rc = $rc; status = $st; scenario_verdict = $verdict; p0_blocked = $p0skip; log = (Split-Path $log -Leaf) }
    Write-Host ("  [{0}] {1,-34} {2,3} pass {3,3} fail {4,3} skip (rc={5}) verdict={6}" -f $st, $n, $p, $f, $k, $rc, $verdict) }
$rows | Export-Csv (Join-Path $res "Run_All_${ts}_GROK_V1.csv") -NoTypeInformation -Encoding UTF8
$gateResult = if ($tf -eq 0 -and $tb -eq 0) { 'MET' } else { 'NOT MET' }; Write-Host "TOTAL: $tp pass, $tf fail, $tk skip, $tb bail"; Write-Host "GATE: $gateResult"
if ($ExportEvidence) {
    $os = if ($IsWindows) { 'windows' } elseif ($IsLinux) { 'linux' } else { 'other' }; $commit = (& git -C $here rev-parse --short HEAD 2>$null)
    $ev = Join-Path (Split-Path $here -Parent) "evidence/$($ts.Substring(0, 8))-$os-$ExportEvidence-$runId"
    if (Test-Path $ev) { Write-Error "evidence folder exists (immutable): $ev"; exit 2 }
    Copy-Item $res $ev -Recurse
    $lines = @("# GROK_V1 evidence MANIFEST - immutable", "# run: $runId commit=$commit date=$(Get-Date -Format o) os=$([Environment]::OSVersion.VersionString) pwsh=$($PSVersionTable.PSVersion)",
        "# totals: $tp pass, $tf fail, $tk skip, $tb bail; gate=$gateResult", "# columns: path<TAB>bytes<TAB>sha256")
    $lines += Get-ChildItem $ev -Recurse -File | Sort-Object FullName | ForEach-Object { "{0}`t{1}`t{2}" -f [IO.Path]::GetRelativePath($ev, $_.FullName).Replace('\', '/'), $_.Length, (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower() }
    $lines | Set-Content (Join-Path $ev 'MANIFEST_GROK_V1.tsv') -Encoding UTF8; Write-Host "# evidence exported: $ev (commit it; logs are force-included by .gitignore rules)" }
exit $(if ($tf -gt 0) { 1 } elseif ($tb -gt 0) { 2 } else { 0 })
