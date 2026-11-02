# GROK_V1 - suite 19 (G-06 / WP7-02, planning name S_WP7-02_OefConverter): OEF -> course.json converter
# 03-RCP-Spike/tools/oef2course_GROK_V1.py, validated with Test-Json -SchemaFile against 02-Cdc/Schema_Course_JSON_CLAUDE_V1.json.
# Env: OEF_CORPUS = optional dir/list of real .oef files for a robustness sweep (not committed; SKIP if unset).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '19_OefConverter'
$repo = Split-Path $script:SpikeDir -Parent
$tool = Join-Path (Join-Path $script:SpikeDir 'tools') 'oef2course_GROK_V1.py'
$schema = Join-Path (Join-Path $repo '02-Cdc') 'Schema_Course_JSON_CLAUDE_V1.json'
$fx = Join-Path (Join-Path $PSScriptRoot 'fixtures') 'oef'
$py = (Get-Command python3, python -CommandType Application -EA SilentlyContinue | Select-Object -First 1).Source
if (-not $py) { Exit-Bail 'python3 not found' }
if (-not (Get-Command Test-Json).Parameters.ContainsKey('SchemaFile')) { Exit-Bail 'pwsh 7.4+ needed (Test-Json -SchemaFile)' }
$w = Join-Path ([IO.Path]::GetTempPath()) "grok19-$PID"; New-Item -ItemType Directory -Force $w | Out-Null
function Conv([string[]]$A) { $o = (& $py $tool @A 2>&1 | Out-String).Trim(); [pscustomobject]@{ Rc = $LASTEXITCODE; Out = $o } }
function Valid([string]$p) { try { Test-Json -LiteralPath $p -SchemaFile $schema -EA Stop } catch { $false } }
$n1 = Join-Path $w 'n1.json'; $r = Conv @((Join-Path $fx 'numeric_GROK_V1.oef'), '-o', $n1, '--seed', '7')
Test-Ok 'OC-01-numeric-converts' ($r.Rc -eq 0 -and (Test-Path $n1)) "rc=$($r.Rc) $($r.Out)" 'P0'
Test-Ok 'OC-02-schema-valid' (Valid $n1) $n1 'P0'
$j = Get-Content $n1 -Raw | ConvertFrom-Json
Test-Ok 'OC-03-metadata' ($j.course -eq 'Line through two points' -and $j.locale -eq 'en' -and $j.author -eq 'Grok Bot fixture') "course=$($j.course) locale=$($j.locale)" 'P1'
$st = $j.tree[0].children; $chk = $st[1].check
$aa = [regex]::Match($st[0].description, 'a=(\d+) and b=(-?\d+)'); $exp = 2 * [int]$aa.Groups[1].Value + [int]$aa.Groups[2].Value
Test-Ok 'OC-04-numeric-check-matches-random-params' ($aa.Success -and $chk.type -eq 'value_equals' -and $chk.variable -eq 'ans1' -and [double]$chk.expected -eq $exp -and $chk.tolerance -eq 0.001) "statement a,b=$($aa.Groups[1].Value),$($aa.Groups[2].Value) expected=$($chk.expected) want=$exp" 'P0'
Test-Ok 'OC-05-hint-in-description' ($st[1].description -match 'Hint: Multiply first') $st[1].description 'P2'
$cm = @($st[0].actions | ForEach-Object value)
Test-Ok 'OC-06-draw-to-safe-cmds' ($cm.Count -eq 3 -and $cm[0] -eq 'd1 = Segment((0, -5), (0, 5))' -and $cm[2] -like 'd3 = Point(*') "cmds=$($cm -join ' ; ')" 'P1'
$n2 = Join-Path $w 'n2.json'; $null = Conv @((Join-Path $fx 'numeric_GROK_V1.oef'), '-o', $n2, '--seed', '7')
Test-Ok 'OC-07-deterministic-seed' ((Get-FileHash $n1).Hash -eq (Get-FileHash $n2).Hash) 'same seed -> identical bytes' 'P0'
$m = Join-Path $w 'm.json'; $r = Conv @((Join-Path $fx 'nonnumeric_GROK_V1.oef'), '-o', $m)
$mj = Get-Content $m -Raw | ConvertFrom-Json
Test-Ok 'OC-08-nonnumeric-object-exists-warned' ((Valid $m) -and $mj.tree[0].children[1].check.type -eq 'object_exists' -and $r.Out -match 'not numeric' -and $mj.locale -eq 'fr') "out=$($r.Out)" 'P1'
$x = Join-Path $w 'x.json'; $r = Conv @((Join-Path $fx 'malicious_GROK_V1.oef'), '-o', $x); $xt = Get-Content $x -Raw; $xj = $xt | ConvertFrom-Json
$emitted = @($xj.tree[0].children | ForEach-Object { $_.actions } | Where-Object { $_ } | ForEach-Object value)
Test-Ok 'OC-09-no-scripting-emitted' ((Valid $x) -and $emitted.Count -eq 1 -and $emitted[0] -like 'd1 = Segment(*' -and $xt -notmatch '<script') "actions=$($emitted -join ';')" 'P0'
$c = Join-Path $w 'c.json'; $r = Conv @($fx, '-o', $c, '--title', 'Fixture course'); $cj = Get-Content $c -Raw | ConvertFrom-Json
Test-Ok 'OC-10-directory-input-multi-chapter' ($r.Rc -eq 0 -and (Valid $c) -and $cj.tree.Count -eq 3 -and $cj.course -eq 'Fixture course' -and -not $cj.locale -and $r.Out -match 'broken_GROK_V1.oef: skipped') "chapters=$($cj.tree.Count) out=$($r.Out -replace "`n",' | ')" 'P0'
$r = Conv @((Join-Path $fx 'broken_GROK_V1.oef')); Test-Ok 'OC-11-broken-65' ($r.Rc -eq 65 -and $r.Out -match 'unbalanced') "rc=$($r.Rc)" 'P1'
$r = Conv @((Join-Path $fx 'empty_GROK_V1.oef')); Test-Ok 'OC-12-empty-65' ($r.Rc -eq 65) "rc=$($r.Rc)" 'P1'
$r = Conv @((Join-Path $w 'nope.oef')); Test-Ok 'OC-13-missing-66' ($r.Rc -eq 66) "rc=$($r.Rc)" 'P1'
$r = Conv @(); Test-Ok 'OC-14-usage-64' ($r.Rc -eq 64) "rc=$($r.Rc)" 'P1'
$cp = Join-Path $w 'cp.oef'; [IO.File]::WriteAllBytes($cp, [Text.Encoding]::GetEncoding('latin1').GetBytes("\title{Équation}`n\language{fr}`n\author{Frédéric}`n\statement{x}`n\answer{y}{3}{type=numeric}`n"))
$cpj = Join-Path $w 'cp.json'; $null = Conv @($cp, '-o', $cpj); $cpo = Get-Content $cpj -Raw -Encoding utf8 | ConvertFrom-Json
Test-Ok 'OC-15-latin1-decoded' ($cpo.course -eq 'Équation' -and $cpo.author -eq 'Frédéric') "course=$($cpo.course)" 'P2'
# OC-16 robustness sweep over real WIMS OEF (box only)
if (-not $env:OEF_CORPUS) { Skip-Test 'OC-16-corpus-schema-valid' 'SKIP reason: set OEF_CORPUS=<dir or .txt list> to sweep real OEF files' 'P2' }
else { $files = if ((Get-Item $env:OEF_CORPUS).PSIsContainer) { @(Get-ChildItem $env:OEF_CORPUS -Recurse -Filter *.oef | Select-Object -First 300 -ExpandProperty FullName) } else { @(Get-Content $env:OEF_CORPUS | Select-Object -First 300) }
    $okc = 0; $val = 0; $i = 0
    foreach ($f in $files) { $i++; $o = Join-Path $w "corp$i.json"; & $py $tool $f -o $o 2>$null; if ($LASTEXITCODE -eq 0) { $okc++; if (Valid $o) { $val++ } } }
    Test-Ok 'OC-16-corpus-schema-valid' ($okc -gt 0 -and $val -eq $okc -and $okc -ge [math]::Floor(0.95 * $files.Count)) "files=$($files.Count) converted=$okc schema-valid=$val" 'P1' }
Remove-Item $w -Recurse -Force -EA SilentlyContinue
Complete-TestSuite
