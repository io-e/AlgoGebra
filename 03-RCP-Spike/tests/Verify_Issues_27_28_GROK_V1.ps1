# GROK_V1 - acceptance harness for issues #27 (BUG-014 renderer fonts) and #28 (BUG-010 dialog on valid input).
# Usage: pwsh -File Verify_Issues_27_28_GROK_V1.ps1 -Image <image dir> [-SkipSuite09]
#   Linux: runs the product scenarios under `xvfb-run -a` (suite 09 starts its own Xvfb). Windows: run attended (desktop free).
# Acceptance (from the issues):
#   #27: renderer bundle contains ReTeX .ttf; P-02 0 FAIL (50/0/1); suite 09 D04-FONT-01-latex-fonts PASS; D-11 8/0/0.
#   #28: suite 09 valid inputs (KBD-01..07, D04-FOCUS-01/02, D04-ORDER-01..04) PASS and no "*-keys-reach-input" failure.
# Prints one line per criterion + "VERDICT #27: PASS|FAIL" / "VERDICT #28: PASS|FAIL"; exit 0 only if both PASS.
param([Parameter(Mandatory)][string]$Image, [switch]$SkipSuite09)
$ErrorActionPreference = 'Continue'; $here = $PSScriptRoot; $img = (Resolve-Path $Image).Path
$env:IMAGE = $img; $c = [ordered]@{}
function Get-Counts([string]$Text) { if ($Text -match 'PASS: (\d+) FAIL: (\d+) SKIP: (\d+)') { return @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3]) }; return $null }
function Tap([string]$Text, [string]$Id) { $l = @($Text -split "`r?`n" | Where-Object { $_ -match "^(not ok|ok) \d+ - \[P\d\] $([regex]::Escape($Id))\b" }); if ($l) { $l[0].StartsWith('ok') } else { $null } }
# 1. renderer fonts
$rj = Get-ChildItem (Join-Path $img 'bundles') -Filter 'org.geogebra.migration.desktop.renderer-*.jar' -EA SilentlyContinue | Select-Object -First 1
$ttf = 0; if ($rj) { Add-Type -AssemblyName System.IO.Compression.FileSystem; $z = [IO.Compression.ZipFile]::OpenRead($rj.FullName); try { $ttf = @($z.Entries | Where-Object Name -like '*.ttf').Count } finally { $z.Dispose() } }
$c['27-renderer-ttf'] = @(($ttf -gt 0), "$($rj.Name): $ttf .ttf")
# 2. scenarios P-02 + D-11 (one Run_All call)
$runAll = Join-Path $here 'Run_All_GROK_V1.ps1'
$cmd = if ($IsWindows) { @('pwsh', '-NoProfile', '-Command', "& '$runAll' -AllowForegroundInput -Only 'P-02','D-11'") } else { @('xvfb-run', '-a', 'pwsh', '-NoProfile', '-Command', "& '$runAll' -Only 'P-02','D-11'") }
$o = (& $cmd[0] @($cmd | Select-Object -Skip 1) 2>&1 | Out-String)
$rd = if ($o -match '# run id: \S+ -> (\S+)') { $Matches[1] } else { $null }
foreach ($s in @(@('P-02', 'S_P-02_CoreFeatures_GROK_V1.log'), @('D-11', 'S_D-11_CourseTree_GROK_V1.log'))) {
    $t = if ($rd -and (Test-Path (Join-Path $rd $s[1]))) { Get-Content (Join-Path $rd $s[1]) -Raw } else { '' }; $n = Get-Counts $t
    $want = if ($s[0] -eq 'P-02') { $n -and $n[1] -eq 0 -and $n[0] -ge 50 } else { $n -and $n[1] -eq 0 -and $n[0] -ge 8 }
    $c["27-$($s[0])"] = @([bool]$want, $(if ($n) { "$($n -join '/')" } else { 'no result' })) }
# 3. suite 09
if ($SkipSuite09) { $c['27-suite09-font'] = @($false, 'SKIPPED (-SkipSuite09)'); $c['28-valid-inputs'] = @($false, 'SKIPPED'); $c['28-no-dead-input'] = @($false, 'SKIPPED') }
else {
    $t9 = (& pwsh -NoProfile -File (Join-Path $here '09_Test_D04_UI_GROK_V1.ps1') 2>&1 | Out-String); $n9 = Get-Counts $t9
    $f = Tap $t9 'D04-FONT-01-latex-fonts'; $c['27-suite09-font'] = @([bool]$f, "D04-FONT-01=$f")
    $ids = @('KBD-01', 'KBD-02', 'KBD-03', 'KBD-04', 'KBD-05', 'KBD-06', 'KBD-07', 'D04-FOCUS-01-2d-to-3d', 'D04-FOCUS-02-3d-to-2d', 'D04-ORDER-01-fx-first-input', 'D04-ORDER-02-point-second-input', 'D04-ORDER-03-function-in-3d-pane', 'D04-ORDER-04-function-2d-after-3d')
    $bad = @(); foreach ($id in $ids) { $l = @($t9 -split "`r?`n" | Where-Object { $_ -match "^(not ok|ok) \d+ - \[P\d\] $([regex]::Escape($id))(-\[|\s|$)" -and $_ -notmatch 'keys-reach-input' }); if (-not $l -or -not $l[0].StartsWith('ok')) { $bad += $id } }
    $c['28-valid-inputs'] = @(($bad.Count -eq 0), "failing: $(if ($bad) { $bad -join ', ' } else { 'none' }) (suite 09 $($n9 -join '/'))")
    $dead = @($t9 -split "`r?`n" | Where-Object { $_ -match '^not ok .*keys-reach-input' }).Count; $c['28-no-dead-input'] = @(($dead -eq 0), "keys-reach-input failures: $dead") }
foreach ($k in $c.Keys) { Write-Host ("{0,-20} {1}  {2}" -f $k, $(if ($c[$k][0]) { 'PASS' } else { 'FAIL' }), $c[$k][1]) }
$v27 = -not ($c.Keys | Where-Object { $_ -like '27-*' -and -not $c[$_][0] }); $v28 = -not ($c.Keys | Where-Object { $_ -like '28-*' -and -not $c[$_][0] })
Write-Host "VERDICT #27: $(if ($v27) { 'PASS' } else { 'FAIL' })"; Write-Host "VERDICT #28: $(if ($v28) { 'PASS' } else { 'FAIL' })"; Write-Host "# image=$img scenarios=$rd"
exit $(if ($v27 -and $v28) { 0 } else { 1 })
