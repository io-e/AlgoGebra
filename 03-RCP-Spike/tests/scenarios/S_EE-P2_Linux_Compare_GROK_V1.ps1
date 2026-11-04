# GROK_V1 — EE-P2a..d (CDC External Engines V1_2 §Phase 2): Debian comparison of WIMS C interfaces
# (src/Interfaces pari/maxima/gap; gnuplot piped directly as WIMS exec.c does) vs AlgoGebra Java SubprocessEngine.
# v2 (2026-11-04): fixture-driven (tests/fixtures/ee_fixture_set_F_GROK_V1.json) and D-WIMS-T01 soft parity
# (same normalized values; Java rejects at least as strictly as WIMS) instead of byte-identical. Read-only on production code.
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$WimsInterfaces,
    [Parameter(Mandatory)] [string]$JavaHome,
    [Parameter(Mandatory)] [string]$EngineClasses,
    [Parameter(Mandatory)] [string]$OutDir,
    [string]$ExtraPath = '',
    [string]$Fixtures = (Join-Path $PSScriptRoot '../fixtures/ee_fixture_set_F_GROK_V1.json'),
    [int]$WimsTimeoutSec = 20
)
$ErrorActionPreference = 'Stop'
if ($ExtraPath) { $env:PATH = "$ExtraPath`:$env:PATH" }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$tmp = Join-Path $OutDir 'wims_tmp'; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$env:tmp_dir = $tmp
$Driver = Join-Path $PSScriptRoot '../tools/EeP2Driver_GROK_V1.java'
$Java = Join-Path $JavaHome 'bin/java'
$F = Get-Content -Raw $Fixtures | ConvertFrom-Json

function Norm([string]$s, [string]$rule = 'ws-collapse') {
  if ($null -eq $s) { return '' }
  $n = ($s -replace '\\n', '' -replace '\s', '')
  if ($rule -eq 'numeric') { $n = $n -replace '(?<![0-9.])0\.E-\d+', '0.0' }
  return $n
}
function Lines($items) {  # stdout+stderr as text; pwsh wraps empty stderr lines as RemoteException records
  $items | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.Message } else { "$_" } } |
    Where-Object { $_ -ne 'System.Management.Automation.RemoteException' -and $_.Trim() -ne '' -and
                   $_ -notmatch '^(SIMPLE-WARNING: Maxima is unable|\(Details: CL-INFO)' -and
                   $_ -notmatch "^Error, PrintTo: cannot open '/nodir/\.gap_hist'" }  # gap.c sets HOME=/nodir (history noise)
}

function Invoke-Wims($engine, $cmd) {
  $c = $cmd -replace '\\n', "`n"
  if ($engine -eq 'gnuplot') {
    # WIMS has no src/Interfaces gnuplot wrapper; exec.c pipes the script to gnuplot directly (no filter).
    $png = Join-Path $tmp 'wims_plot.png'; Remove-Item $png -ErrorAction SilentlyContinue
    $script = "set terminal pngcairo size 800,600`nset output '$png'`n$c`nunset output`n"
    $o = ((Lines ($script | & timeout $WimsTimeoutSec gnuplot 2>&1)) -join "`n").Trim()
    if ((Test-Path $png) -and (Get-Item $png).Length -gt 24) {
      $b = [IO.File]::ReadAllBytes($png)
      if ($b[0] -eq 0x89 -and $b[1] -eq 0x50 -and $b[2] -eq 0x4E -and $b[3] -eq 0x47) {
        $w = ([int]$b[16] -shl 24) -bor ([int]$b[17] -shl 16) -bor ([int]$b[18] -shl 8) -bor [int]$b[19]
        $h = ([int]$b[20] -shl 24) -bor ([int]$b[21] -shl 16) -bor ([int]$b[22] -shl 8) -bor [int]$b[23]
        return "PNG ${w}x${h}" + $(if ($o) { " | " + ($o -replace "`r?`n", '\n') } else { '' })
      }
    }
    return ($o -replace "`r?`n", '\n')
  }
  $env:wims_exec_parm = $c
  $o = ((Lines (& timeout $WimsTimeoutSec (Join-Path $WimsInterfaces $engine) 2>&1)) -join "`n") -replace "$([char]27)\[[0-9;]*m", ''
  if ($LASTEXITCODE -eq 124) { $o = "TIMEOUT $o" }
  return ($o.Trim() -replace "`r?`n", '\n')
}
function Test-Executed($out, $sentinel) { return ($out -match 'uid=\d+') -or ([bool]$sentinel -and (Test-Path $sentinel)) }
function Test-WimsError($w) { return ($w -match '\*\*\*|error|incorrect syntax|TIMEOUT|not a function|premature|Variable:|must have a value') -or ($w.Trim() -eq '') }

$rows = @()
foreach ($t in $F.cases) {
  $s = $t.sentinel
  if ($s) { Remove-Item $s -ErrorAction SilentlyContinue }
  $w = Invoke-Wims $t.engine $t.input
  $wExec = Test-Executed $w $s
  if ($s) { Remove-Item $s -ErrorAction SilentlyContinue }
  $j = ((Lines (& $Java -cp $EngineClasses $Driver $t.engine $t.input 2>&1)) -join "`n").Trim()
  $jstat,$jval = $j -split '\|',2
  $jExec = Test-Executed $jval $s
  if ($s) { Remove-Item $s -ErrorAction SilentlyContinue }
  $wBlocked = (-not $wExec) -and (Test-WimsError $w)
  $exp = $t.expected.value
  $note = ''
  if ($jstat -eq 'NA') {
    $side = 'wims-only'
    switch ($t.kind) {
      'value'  { $ok = (Norm $w) -eq (Norm $exp) }
      'error'  { $ok = Test-WimsError $w }
      default  { $ok = -not $wExec; $note = "wims_blocked=$wBlocked" }
    }
    $verdict = $(if ($ok) {'REF-PASS'} else {'REF-FAIL'})
  } else {
    $side = 'both'
    switch ($t.kind) {
      'value'  { $r = $t.expected.normalization
                 $ok = ($jstat -eq 'OK') -and ((Norm $jval $r) -eq (Norm $w $r)) -and ((-not $exp) -or (Norm $jval $r) -eq (Norm $exp $r))
                 if ($jstat -eq 'OK' -and (Norm $jval $r) -ne (Norm $w $r)) { $note = 'VALUE MISMATCH' }
                 elseif ($jstat -eq 'OK' -and $jval -ne $w) { $note = "equal under $r (text differs)" }
                 elseif ($jstat -ne 'OK') { $note = "Java $jval on valid input" } }
      'error'  { $ok = ($jstat -eq 'ERR'); $note = "wims_error=$(Test-WimsError $w)" }
      'png'    { $ok = ($jstat -eq 'OK') -and ($jval -eq 'PNG 800x600') -and ($w -like 'PNG 800x600*') }
      'reject' { $ok = ($jstat -eq 'ERR') -and -not $jExec
                 $note = $(if (-not $ok -and $wBlocked) {'JAVA LESS STRICT'} elseif ($wExec) {'Java stricter (WIMS executed)'} elseif ($wBlocked) {'both block'} else {'WIMS neutralised (token mangled / no effect)'}) }
      'strict' { $ok = (-not $jExec) -and ((-not $wBlocked) -or $jstat -eq 'ERR')
                 $note = "wims_blocked=$wBlocked wims_executed=$wExec java=$jstat" }
    }
    $verdict = $(if ($ok) {'PASS'} else {'FAIL'})
  }
  $rows += [pscustomobject]@{ id=$t.id; engine=$t.engine; kind=$t.kind; side=$side; input=$t.input; expected=$exp;
    wims=$w; java=$j; wims_executed=$wExec; wims_blocked=$wBlocked; java_executed=$jExec; verdict=$verdict; note=$note }
  Write-Host ("{0,-5} {1,-7} {2,-6} {3,-8} {4}" -f $t.id,$t.engine,$t.kind,$verdict,$note)
}
$rows | ConvertTo-Json -Depth 3 | Set-Content -Encoding utf8 (Join-Path $OutDir 'results.json')
$rows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $OutDir 'results.csv')
foreach ($g in ($rows | Group-Object engine)) {
  $p = @($g.Group | Where-Object verdict -like '*PASS').Count
  Write-Host ("ENGINE {0,-7} cases {1} pass {2} fail {3}" -f $g.Name,$g.Count,$p,($g.Count-$p))
}
$f = @($rows | Where-Object verdict -like '*FAIL').Count
Write-Host "TOTAL $($rows.Count) PASS $($rows.Count-$f) FAIL $f"
Remove-Item -Recurse -Force $tmp
exit $(if ($f) {1} else {0})
