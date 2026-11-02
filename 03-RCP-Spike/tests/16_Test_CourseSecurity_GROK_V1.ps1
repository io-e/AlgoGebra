# GROK_V1 - suite 16 (WP9-03 / G-05): malicious course corpus for 02-Cdc/Spec_Course_Security_CLAUDE_V1.md.
# Corpus: fixtures/course-security/ (courses/*.json, ggb-src/<name>/ -> <name>.ggb built at run time, corpus_manifest_GROK_V1.tsv
# with the expected verdict per case). Layers:
#   schema    - checked now with Test-Json against 02-Cdc/Schema_Course_JSON_CLAUDE_V1.json (every case, valid or invalid as declared)
#   validator - Codex WP9-02 (allow-list after parse, OPEN path rules, limits)   } SKIP 'pending WP9-02/04' unless
#   scanner   - Codex WP9-04 (GgbScriptScanner)                                   } COURSE_VALIDATOR is set
# Contract for Codex: COURSE_VALIDATOR = executable (or 'java -cp ... Main') called as `<cmd> <course.json>` with the course dir
# prepared by this suite; first stdout token ACCEPT | ACCEPT_WITH_WARNING | REJECT (rest = reason/warnings). Exit code is ignored.
# Owner Q4 (issue #17): structured result; a warning never overrides a REJECT; any other first token = CONTRACT_VIOLATION (FAIL).
# Reference oracles below (OPEN path rules, archive scan) are test-side only: they check the corpus expectations, not the product.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '16_CourseSecurity'
$corpus = Join-Path $script:Fix 'course-security'; $repo = Split-Path $script:SpikeDir -Parent
$schema = if ($env:COURSE_SCHEMA) { $env:COURSE_SCHEMA } else { Join-Path $repo '02-Cdc/Schema_Course_JSON_CLAUDE_V1.json' }
foreach ($p in $corpus, $schema) { if (-not (Test-Path $p)) { Exit-Bail "missing: $p" } }
Write-Host "# schema sha256=$((Get-FileHash $schema -Algorithm SHA256).Hash.ToLower()) $schema"
$rows = @(Get-Content (Join-Path $corpus 'corpus_manifest_GROK_V1.tsv') -Encoding UTF8 | Where-Object { $_ -and -not $_.StartsWith('#') } | Select-Object -Skip 1 | ForEach-Object { $f = $_ -split "`t"
    [pscustomobject]@{ Id = $f[0]; File = $f[1]; Layer = $f[2]; Schema = $f[3]; Expected = $f[4]; Reason = $f[5]; Ref = $f[6]; Note = $f[7] } })
Test-Ok 'SEC-00-manifest' ($rows.Count -ge 40 -and @($rows | Group-Object Id | Where-Object Count -gt 1).Count -eq 0) "cases=$($rows.Count) (unique ids)" 'P0'

# --- prepare the course directory: courses + built .ggb archives + symlink escaping the dir ---
$work = Join-Path $script:Tmp "grok16-$PID"; $cdir = Join-Path $work 'course'; New-Item -ItemType Directory -Force $cdir | Out-Null
Copy-Item (Join-Path $corpus 'courses/*') $cdir
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
foreach ($d in Get-ChildItem (Join-Path $corpus 'ggb-src') -Directory) { $g = Join-Path $cdir "$($d.Name).ggb"
    $z = [IO.Compression.ZipFile]::Open($g, 'Create'); try { foreach ($f in Get-ChildItem $d.FullName -File) { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $f.FullName, $f.Name) } } finally { $z.Dispose() } }
Set-Content (Join-Path $work 'outside.ggb') 'outside the course directory' -Encoding ascii
$linkOk = $true; try { New-Item -ItemType SymbolicLink -Path (Join-Path $cdir 'link_outside.ggb') -Target (Join-Path $work 'outside.ggb') -ErrorAction Stop | Out-Null } catch { $linkOk = $false; Write-Host "# symlink not created ($($_.Exception.Message)); T-27 needs Developer Mode/admin on Windows" }
# T-10: > 1 MB, schema-valid
$steps = 1..100 | ForEach-Object { @{ title = ('S' * 200) } }; $big = @{ schemaVersion = '1.0'; course = 'T-10 big'; tree = @(1..50 | ForEach-Object { @{ title = "C$_"; children = $steps } }) }
$bigPath = Join-Path $cdir 'T-10_big_GROK_V1.json'; ($big | ConvertTo-Json -Depth 6 -Compress) | Set-Content $bigPath -Encoding utf8
Test-Ok 'SEC-01-T-10-size' ((Get-Item $bigPath).Length -gt 1MB) "T-10 size=$((Get-Item $bigPath).Length) bytes" 'P1'
$ggbNames = @(Get-ChildItem $cdir -Filter '*.ggb' | ForEach-Object Name)
Test-Ok 'SEC-02-archives-built' ((@('clean.ggb', 'script_js.ggb', 'script_ggbscript.ggb', 'macro_execute.ggb') | Where-Object { $_ -notin $ggbNames }).Count -eq 0) "built: $($ggbNames -join ', ')" 'P0'

# --- schema layer (runs now) ---
function Get-CasePath($r) { if ($r.Id -eq 'T-10') { return $bigPath }; Join-Path $cdir (Split-Path $r.File -Leaf) }
foreach ($r in $rows) { $p = Get-CasePath $r
    $valid = $false; try { $valid = Test-Json -Path $p -SchemaFile $schema -ErrorAction Stop } catch { $valid = $false }
    $want = $r.Schema -eq 'SCHEMA_VALID'
    Test-Ok "SCH-$($r.Id)" ($valid -eq $want) "schema valid=$valid expected=$($r.Schema) ($($r.Reason)) sha256=$((Get-FileHash $p -Algorithm SHA256).Hash.Substring(0,16).ToLower())" $(if ($r.Layer -eq 'schema') { 'P0' } else { 'P1' }) }

# --- reference oracles (test-side): OPEN path rules incl. symlink realpath; archive scan incl. <ggbscript> ---
function Test-RefOpenPath([string]$Value) { # -> $null if allowed, else reason
    if ($Value -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $Value.StartsWith('//') -or $Value.StartsWith('\\')) { return 'url-or-drive' }
    if ([IO.Path]::IsPathRooted($Value) -or $Value.StartsWith('/')) { return 'absolute' }
    if ($Value -notmatch '\.ggb$') { return 'extension' }
    $full = [IO.Path]::GetFullPath((Join-Path $cdir $Value)); $root = [IO.Path]::GetFullPath($cdir).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($root)) { return 'traversal' }
    $it = Get-Item $full -ErrorAction SilentlyContinue; if (-not $it) { return 'missing' }
    if ($it.LinkType) { $t = [IO.Path]::GetFullPath($it.ResolveLinkTarget($true).FullName); if (-not $t.StartsWith($root)) { return 'symlink-escape' } }
    return $null }
function Get-RefScan([string]$Ggb) { # -> list of findings
    $f = @(); $z = [IO.Compression.ZipFile]::OpenRead($Ggb)
    try { foreach ($e in $z.Entries) { $t = [IO.StreamReader]::new($e.Open()).ReadToEnd()
            if ($e.Name -eq 'geogebra_javascript.js' -and $t.Trim()) { $f += 'global-js' }
            if ($e.Name -like '*.xml') { if ($t -match '<(ggbscript|javascript)\b') { $f += "object-script:$($Matches[1])" }
                if ($t -match '<command\s+name="(Execute|RunClickScript|RunUpdateScript|Delete|SetValue|Rename|Repeat|PlaySound|ExportImage|UpdateConstruction)"') { $f += "blocked-command:$($Matches[1]):$($e.Name)" } } } }
    finally { $z.Dispose() }; return $f }
function Test-SpecNaiveScan([string]$Ggb) { # Spec 3.1 containsScriptElements() as written
    $z = [IO.Compression.ZipFile]::OpenRead($Ggb); try { $e = $z.GetEntry('geogebra.xml'); $x = [IO.StreamReader]::new($e.Open()).ReadToEnd() } finally { $z.Dispose() }
    return ($x.Contains('<javascript') -or $x.Contains('<script') -or $x -match '(?s)on(Update|Click|MouseDown)\s*=') }

foreach ($r in $rows | Where-Object { $_.Layer -ne 'schema' }) { $c = Get-Content (Get-CasePath $r) -Raw | ConvertFrom-Json -Depth 20
    $acts = @($c.tree | ForEach-Object { $_.children } | ForEach-Object { $_.actions }) | Where-Object { $_ }
    $open = @($acts | Where-Object directive -eq 'OPEN')
    if ($r.Note -like 'OPEN path*') { $v = $open[0].value; $why = Test-RefOpenPath $v
        if ($r.Id -eq 'T-27' -and -not $linkOk) { Skip-Test "REF-$($r.Id)" 'symlink could not be created on this host'; continue }
        # prescan-fail-closed (owner Q2): path rules allow the file, the verdict is REJECT only because untrusted OPEN is blocked until the scanner
        $wantPath = if ($r.Note -like '*prescan-fail-closed*') { 'ACCEPT' } else { $r.Expected }
        $got = if ($why) { 'REJECT' } else { 'ACCEPT' }; Test-Ok "REF-$($r.Id)-open-path" ($got -eq $wantPath) "OPEN '$v' -> path rules $got ($why) expected $wantPath; case verdict $($r.Expected)" 'P1' }
    elseif ($r.Note -eq 'ggb') { $g = Join-Path $cdir $open[0].value; $fs = @(Get-RefScan $g)
        $got = if ($fs.Count -eq 0) { 'ACCEPT' } elseif ($open[0].trustedGgb) { 'ACCEPT_WITH_WARNING' } else { 'REJECT' }
        Test-Ok "REF-$($r.Id)-scan" ($got -eq $r.Expected) "$($open[0].value): findings=[$($fs -join ', ')] -> $got expected $($r.Expected)" 'P1' } }
$naive = Test-SpecNaiveScan (Join-Path $cdir 'script_ggbscript.ggb')
if (-not $naive) { Skip-Test 'SPEC-GAP-1-naive-scan-misses-ggbscript' "FINDING: spec 3.1 containsScriptElements() returns false for <ggbscript val=`"Execute(...)`"/> (T-29); the scanner must match '<ggbscript' (GeoGebra ScriptType xml name) - report to Claude/Codex" 'P1' }
else { Test-Ok 'SPEC-GAP-1-naive-scan-misses-ggbscript' $true 'spec scan catches <ggbscript> (gap closed)' 'P1' }

# --- product layers: validator (WP9-02) and scanner (WP9-04) ---
foreach ($r in $rows | Where-Object { $_.Layer -in 'validator', 'scanner' }) { $p = Get-CasePath $r
    if (-not $env:COURSE_VALIDATOR) { Skip-Test "VAL-$($r.Id)" "pending WP9-02/04 (Codex): expected $($r.Expected) - $($r.Reason) [$($r.Ref)]" $(if ($r.Ref -like 'SPEC-GAP*') { 'P1' } else { 'P0' }); continue }
    $parts = $env:COURSE_VALIDATOR -split ' '; $o = (& $parts[0] @($parts | Select-Object -Skip 1) $p 2>&1 | Out-String).Trim()
    # owner Q4: first token is exactly ACCEPT | ACCEPT_WITH_WARNING | REJECT; anything else is a contract violation (FAIL)
    $first = (($o -split "`r?`n") | Where-Object { $_.Trim() } | Select-Object -First 1); $got = if ($first -match '^\s*(ACCEPT_WITH_WARNING|ACCEPT|REJECT)(\s|$)') { $Matches[1] } else { 'CONTRACT_VIOLATION' }
    Test-Ok "VAL-$($r.Id)" ($got -eq $r.Expected) "validator: '$o' -> $got expected $($r.Expected) ($($r.Reason))" 'P0' }
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
Complete-TestSuite
