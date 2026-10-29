# GROK_V1 - suite 11 (heavy, opt-in via Run_All -WithBuild): rebuild the GeoGebra production bundles with the bnd CLI from the
# 02-Cdc/osgi-manifest-drafts recipes on the current OS, compare them with the reference image bundles (r8), then resolve the
# full set (new production bundles + reference external bundles) in Equinox with 02-Cdc/Bnd_Equinox_Resolution_Win64/EquinoxResolveHarness.java.
# Env: GGB_SOURCE (GeoGebra source/ dir, jars built by 'gradlew :desktop:assemble'), BND_JAR, REF_BUNDLES (default <image>/bundles),
#      GGB_ASSEMBLE=1 to run Gradle assemble first. The recipes contain Windows paths; they are rewritten into a temp copy (never edited in place).
# External (third-party) bundles have no wrap recipe in the repo: they are reused from the reference image, not rebuilt.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '11_Bundle_Build'
$src = if ($env:GGB_SOURCE) { $env:GGB_SOURCE } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\source' } else { '/workspace/AlgoGebra/geogebra/source' }
$bnd = if ($env:BND_JAR) { $env:BND_JAR } elseif ($IsWindows) { 'D:\ALF_ZGit\G1_Geogebra_Migration\tools\biz.aQute.bnd-7.1.0.jar' } else { '/workspace/AlgoGebra/bnd/biz.aQute.bnd-7.1.0.jar' }
$ref = if ($env:REF_BUNDLES) { $env:REF_BUNDLES } else { Join-Path $script:Image 'bundles' }
$repo = Split-Path $script:SpikeDir -Parent; $drafts = Join-Path $repo '02-Cdc/osgi-manifest-drafts'; $harness = Join-Path $repo '02-Cdc/Bnd_Equinox_Resolution_Win64/EquinoxResolveHarness.java'
foreach ($p in $src, $bnd, $ref, $drafts) { if (-not (Test-Path $p)) { Exit-Bail "missing: $p" } }
$java = Get-JavaTool 'java'; $javac = Get-JavaTool 'javac'
if ($env:GGB_ASSEMBLE -eq '1') { Push-Location $src; $gw = if ($IsWindows) { '.\gradlew.bat' } else { './gradlew' }; & $gw ':desktop:assemble' --console=plain *> (Join-Path $script:Res '11_gradle_assemble.log'); $rc = $LASTEXITCODE; Pop-Location
    Test-Ok 'BLD-00-gradle-assemble' ($rc -eq 0) "rc=$rc (build success is a prerequisite, not evidence)" 'P0' }
$work = Join-Path $script:Tmp "grok11-$PID"; $out = Join-Path $work 'bundles'; New-Item -ItemType Directory -Force $out | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Get-Manifest([string]$Jar) { $z = [IO.Compression.ZipFile]::OpenRead($Jar); try { $e = $z.GetEntry('META-INF/MANIFEST.MF'); $r = [IO.StreamReader]::new($e.Open()); $t = $r.ReadToEnd(); $r.Close() } finally { $z.Dispose() }
    $h = @{}; $cur = $null; foreach ($l in ($t -split "`r?`n")) { if ($l.StartsWith(' ')) { if ($cur) { $h[$cur] += $l.Substring(1) } } elseif ($l -match '^([^:]+): ?(.*)$') { $cur = $Matches[1]; $h[$cur] = $Matches[2] } }; return $h }
function Split-Pkgs([string]$v) { if (-not $v) { return @() }; return @([regex]::Matches($v, '(?:^|,)([A-Za-z_][\w.]*)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique) }
function Get-SetDiff($a, $b) { @(@($a | Where-Object { $_ -notin $b } | ForEach-Object { [pscustomobject]@{ SideIndicator = '<='; InputObject = $_ } }) + @($b | Where-Object { $_ -notin $a } | ForEach-Object { [pscustomobject]@{ SideIndicator = '=>'; InputObject = $_ } })) }
function Get-Classes([string]$Jar) { $z = [IO.Compression.ZipFile]::OpenRead($Jar); try { return @($z.Entries | Where-Object FullName -like '*.class' | ForEach-Object FullName | Sort-Object) } finally { $z.Dispose() } }
foreach ($recipe in Get-ChildItem $drafts -Filter '*.bnd' | Sort-Object Name) {
    $t = Get-Content $recipe.FullName -Raw; $bsn = ([regex]::Match($t, 'Bundle-SymbolicName:\s*(\S+)')).Groups[1].Value; $ver = ([regex]::Match($t, 'Bundle-Version:\s*(\S+)')).Groups[1].Value
    $id = "BLD-$($recipe.BaseName)"; $refJar = Join-Path $ref "$bsn-$ver.jar"; $newJar = Join-Path $out "$bsn-$ver.jar"
    $t = $t -replace 'D:/ALF_ZGit/G1_Geogebra_Migration/source', ($src -replace '\\', '/') -replace '(?m)^-output:.*$', "-output: $($newJar -replace '\\','/')"
    $cp = ([regex]::Match($t, '(?m)^-classpath:\s*(.+)$')).Groups[1].Value.Split(',') | ForEach-Object { $_.Trim() }
    $miss = @($cp | Where-Object { -not (Test-Path $_) }); if ($miss) { Skip-Test "$id-build" "input jar not built: $($miss -join ', ')" 'P1'; continue }
    $tmpBnd = Join-Path $work $recipe.Name; Set-Content $tmpBnd $t -Encoding UTF8
    $o = & $java -jar $bnd bnd $tmpBnd 2>&1; $rc = $LASTEXITCODE; ($o | Out-String) | Set-Content (Join-Path $work "$($recipe.BaseName).bnd.log")
    Test-Ok "$id-build" (($rc -eq 0) -and (Test-Path $newJar)) "bnd rc=$rc warnings=$(@($o | Select-String -Pattern 'Warning' ).Count) out=$newJar" 'P0'
    if (-not (Test-Path $newJar)) { continue }
    if (-not (Test-Path $refJar)) { Skip-Test "$id-vs-r8" "no reference bundle $bsn-$ver.jar in $ref (not part of r8)" 'P1'; continue }
    $mn = Get-Manifest $newJar; $mr = Get-Manifest $refJar
    Test-Ok "$id-bsn-version" (($mn['Bundle-SymbolicName'] -split ';')[0] -eq ($mr['Bundle-SymbolicName'] -split ';')[0] -and $mn['Bundle-Version'] -eq $mr['Bundle-Version']) "$($mn['Bundle-SymbolicName']) $($mn['Bundle-Version']) vs r8 $($mr['Bundle-SymbolicName']) $($mr['Bundle-Version'])" 'P0'
    $en = Split-Pkgs $mn['Export-Package']; $er = Split-Pkgs $mr['Export-Package']; $d = Get-SetDiff $en $er
    Test-Ok "$id-exports-eq-r8" (-not $d) "exports new=$($en.Count) r8=$($er.Count) diff=$(($d | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ' ')" 'P0'
    $in = Split-Pkgs $mn['Import-Package']; $ir = Split-Pkgs $mr['Import-Package']; $d = Get-SetDiff $in $ir
    Test-Ok "$id-imports-eq-r8" (-not $d) "imports new=$($in.Count) r8=$($ir.Count) diff=$(($d | Select-Object -First 12 | ForEach-Object { $_.SideIndicator + $_.InputObject }) -join ' ')" 'P1'
    $cn = Get-Classes $newJar; $cr = Get-Classes $refJar; $d = Compare-Object $cn $cr -SyncWindow 100000
    Test-Ok "$id-class-list-eq-r8" (-not $d) "classes new=$($cn.Count) r8=$($cr.Count) diff=$(@($d).Count) (bytecode differs by toolchain; entry list compared, hash not expected equal)" 'P1' }
$built = @(Get-ChildItem $out -Filter '*.jar').Name
Get-ChildItem $ref -Filter '*.jar' | Where-Object { $built -notcontains $_.Name } | Copy-Item -Destination $out
$osgi = Get-ChildItem $ref -Filter 'org.eclipse.osgi_*.jar' | Select-Object -First 1
if (-not $osgi) { Skip-Test 'BLD-RES-01-equinox-resolution' "no org.eclipse.osgi jar in $ref" 'P0' } else {
    $hc = Join-Path $work 'harness'; New-Item -ItemType Directory -Force $hc | Out-Null
    & $javac -d $hc -cp $osgi.FullName $harness 2>&1 | Out-Null
    $o = (& $java -cp "$hc$($script:Sep)$($osgi.FullName)" EquinoxResolveHarness $out (Join-Path $work 'storage') 2>&1) | Out-String; $o | Set-Content (Join-Path $script:Res '11_equinox_resolution.log')
    $n = @(Get-ChildItem $out -Filter '*.jar' | Where-Object Name -notlike 'org.eclipse.osgi_*').Count
    Test-Ok 'BLD-RES-01-equinox-resolution' ($o -match 'allResolved=true') "$(([regex]::Match($o, 'Equinox=.*allResolved=\w+')).Value) staged=$n (rebuilt=$($built.Count) + r8 externals) log=$(Join-Path $script:Res '11_equinox_resolution.log')" 'P0' }
Complete-TestSuite
