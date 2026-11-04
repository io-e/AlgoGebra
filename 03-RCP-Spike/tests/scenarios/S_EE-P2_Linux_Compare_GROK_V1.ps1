# GROK_V1 — EE-P2a..d (mapped to CDC External Engines V1_1 Phase 2 steps 2a-2d): Debian comparison of
# WIMS C interfaces (src/Interfaces pari/maxima/gap, gnuplot called directly as WIMS exec.c does) vs
# AlgoGebra Java SubprocessEngine adapters. Read-only on production code.
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WimsInterfaces,   # dir with built pari, maxima, gap
    [Parameter(Mandatory)] [string]$JavaHome,
    [Parameter(Mandatory)] [string]$EngineClasses,    # javac output of 03-RCP-Spike/engines (Activators excluded)
    [Parameter(Mandatory)] [string]$OutDir,
    [string]$ExtraPath = ''                           # e.g. dir holding gap.sh
)
$ErrorActionPreference = 'Stop'
if ($ExtraPath) { $env:PATH = "$ExtraPath`:$env:PATH" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$tmp = Join-Path $OutDir 'wims_tmp'; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$env:tmp_dir = $tmp
$Driver = Join-Path $PSScriptRoot '../tools/EeP2Driver_GROK_V1.java'
$Java = Join-Path $JavaHome 'bin/java'

# id | engine | command | kind (pos = must produce same value; neg = must be blocked on Java side; info = record only)
$cases = @(
  @('P-01','pari','factor(2^64-1)','pos'),
  @('P-02','pari','factor((','err'),
  @('P-03','pari','nextprime(10^20)','pos'),
  @('P-04','pari','plot(sin(x))','neg'),
  @('P-05','pari','system("id")','neg'),
  @('P-06','pari','extern("id")','neg'),
  @('P-07','pari','externstr("id")','neg'),
  @('P-08','pari','install("getpid","l")','neg'),
  @('P-09','pari','alias(s,system); s("id")','neg'),
  @('P-10','pari','2+2\n\quit','neg'),
  @('P-11','pari','write("/tmp/ee_p2_x",1)','neg'),
  @('P-12','pari','1.2300','pos'),
  @('M-01','maxima','diff(sin(x^2), x)','pos'),
  @('M-02','maxima','integrate(x^2, x)','pos'),
  @('M-03','maxima','system("id")','neg'),
  @('M-04','maxima','load("foo")','neg'),
  @('M-05','maxima','plot2d(sin(x),[x,0,1])','neg'),
  @('M-06','maxima','with_stdout("/tmp/ee_p2_y", print(1))','neg'),
  @('G-01','gap','Size(SymmetricGroup(5))','pos'),
  @('G-02','gap','Exec("id")','neg'),
  @('G-03','gap','Process(DirectoryCurrent(), Filename(DirectoriesSystemPrograms(),"id"), InputTextNone(), OutputTextUser(), [])','neg'),
  @('N-01','gnuplot','plot sin(x)','png'),
  @('N-02','gnuplot','!echo nope','neg'),
  @('N-03','gnuplot','plot system("id")','neg'),
  @('N-04','gnuplot','plot sin(x); set output "other.png"','neg'),
  @('N-05','gnuplot','plot sin(x); call "evil.gp"','neg'),
  @('N-06','gnuplot','plot `id`','neg')
)

function Invoke-Wims($engine, $cmd) {
  $c = $cmd -replace '\\n', "`n"
  if ($engine -eq 'gnuplot') {
    # WIMS has no src/Interfaces gnuplot wrapper; exec.c pipes the script to gnuplot directly (no filter).
    $png = Join-Path $tmp 'wims_plot.png'; Remove-Item $png -ErrorAction SilentlyContinue
    $script = "set terminal pngcairo size 800,600`nset output '$png'`n$c`nunset output`n"
    $o = ($script | & gnuplot 2>&1 | Out-String).Trim()
    if (Test-Path $png) {
      $b = [IO.File]::ReadAllBytes($png)
      $w = ([int]$b[16] -shl 24) -bor ([int]$b[17] -shl 16) -bor ([int]$b[18] -shl 8) -bor [int]$b[19]
      $h = ([int]$b[20] -shl 24) -bor ([int]$b[21] -shl 16) -bor ([int]$b[22] -shl 8) -bor [int]$b[23]
      return "PNG ${w}x${h}" + $(if ($o) { " | $o" } else { '' })
    }
    return $o
  }
  $env:wims_exec_parm = $c
  # stdout+stderr as WIMS sees them; drop Maxima help-index warnings and ANSI colour codes (GAP).
  $lines = & (Join-Path $WimsInterfaces $engine) 2>&1 | ForEach-Object { "$_" } |
    Where-Object { $_ -notmatch '^(SIMPLE-WARNING: Maxima is unable|\(Details: CL-INFO)' -and $_.Trim() -ne '' }
  $o = ($lines -join "`n") -replace "$([char]27)\[[0-9;]*m", ''
  return ($o.Trim() -replace "`r?`n", '\n')
}

$rows = @()
foreach ($t in $cases) {
  $id,$eng,$cmd,$kind = $t
  $w = Invoke-Wims $eng $cmd
  $j = (& $Java -cp $EngineClasses $Driver $eng $cmd 2>&1 | Out-String).Trim()
  $jstat,$jval = $j -split '\|',2
  $wimsExecuted = $w -match 'uid='
  $javaExecuted = $jval -match 'uid='
  if ($jstat -eq 'NA') {
    # No Java adapter (V1_1 step 1f GAPEngine is optional, not implemented): WIMS-side reference only.
    $match = if ($kind -eq 'pos') { ($w -split '\\n') -contains '120' } else { -not $wimsExecuted }
    $rows += [pscustomobject]@{ id=$id; engine=$eng; kind="$kind/wims-only"; command=$cmd; wims=$w; java=$j;
      wims_executed=$wimsExecuted; match=$match }
    Write-Host ("{0,-5} {1,-7} {2,-4} {3} (WIMS only)" -f $id,$eng,$kind,$(if($match){'PASS'}else{'FAIL'}))
    continue
  }
  switch ($kind) {
    'pos' { $match = ($jstat -eq 'OK' -and $jval -eq $w) }
    'png' { $match = ($jstat -eq 'OK' -and $jval -eq 'PNG 800x600' -and $w -like 'PNG 800x600*') }
    'err' { $match = ($jstat -eq 'ERR' -and $w -match '\*\*\*') }
    'neg' { $match = ($jstat -eq 'ERR' -and -not $javaExecuted) }
  }
  $rows += [pscustomobject]@{ id=$id; engine=$eng; kind=$kind; command=$cmd; wims=$w; java=$j;
    wims_executed=$wimsExecuted; match=$match }
  Write-Host ("{0,-5} {1,-7} {2,-4} {3}" -f $id,$eng,$kind,$(if($match){'PASS'}else{'FAIL'}))
}
$rows | ConvertTo-Json -Depth 3 | Set-Content -Encoding utf8 (Join-Path $OutDir 'results.json')
$rows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $OutDir 'results.csv')
$f = @($rows | Where-Object { -not $_.match }).Count
Write-Host "TOTAL $($rows.Count) PASS $($rows.Count-$f) FAIL $f"
Remove-Item -Recurse -Force $tmp
exit $(if ($f) {1} else {0})
