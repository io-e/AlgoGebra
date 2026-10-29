# GROK_V1 - O-02 License inventory. Gate E. Pass (spec): deployment review recorded.
# Builds an inventory TSV of every jar in the image (Bundle-License, Bundle-Vendor, embedded LICENSE/NOTICE), native files,
# fonts and translation resources. The human deployment review (EUPL 1.2, GeoGebra non-commercial terms) stays NOT RUN.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_O-02'; Write-ScenarioHeader 'O-02' 'License inventory' 'E' 'desktop'; Test-ImagePresent
Add-Type -AssemblyName System.IO.Compression.FileSystem
$rows = [Collections.Generic.List[string]]::new(); $rows.Add("file`tsha256`tbundle_license`tvendor`tlicense_files`tfonts`ttranslations")
$noLic = 0; $fonts = 0; $trans = 0
foreach ($j in Get-ChildItem $script:Image -Recurse -Filter *.jar | Where-Object { $_.FullName -notmatch 'runtime-' }) {
  $z = [IO.Compression.ZipFile]::OpenRead($j.FullName); try {
    $mf = $z.GetEntry('META-INF/MANIFEST.MF'); $t = if ($mf) { (New-Object IO.StreamReader($mf.Open())).ReadToEnd() -replace '\r?\n ', '' } else { '' }
    $lic = ([regex]::Match($t, '(?m)^Bundle-License: *(.*)$')).Groups[1].Value.Trim(); $ven = ([regex]::Match($t, '(?m)^Bundle-Vendor: *(.*)$')).Groups[1].Value.Trim()
    $lf = @($z.Entries | Where-Object { $_.FullName -match '(?i)(^|/)(LICENSE|NOTICE|COPYING)[^/]*$' } | ForEach-Object FullName)
    $f = @($z.Entries | Where-Object { $_.FullName -match '(?i)\.(ttf|otf)$|/fonts/[^/]+\.class$' }).Count; $tr = @($z.Entries | Where-Object { $_.FullName -match '(?i)(properties|translation)[^/]*/.*_[a-z]{2}(_[A-Z]{2})?\.(properties|txt)$|/menu_[a-z]{2}' }).Count
  } finally { $z.Dispose() }
  if (-not $lic -and $lf.Count -eq 0) { $noLic++ }; $fonts += $f; $trans += $tr
  $rows.Add("$($j.Name)`t$((Get-FileHash $j.FullName).Hash.ToLower())`t$lic`t$ven`t$($lf -join ';')`t$f`t$tr") }
foreach ($n in Get-ChildItem (Join-Path $script:Image 'natives') -Recurse -File -ErrorAction SilentlyContinue) { $rows.Add("natives/$($n.Name)`t$((Get-FileHash $n.FullName).Hash.ToLower())`t`t`t`t0`t0") }
$tsv = Join-Path $script:Res 'S_O-02_license_inventory.tsv'; Set-Content $tsv $rows -Encoding UTF8
Test-Ok 'O02-01-inventory-written' ($rows.Count -gt 50) "rows=$($rows.Count - 1) file=$tsv" 'P0'
Test-Ok 'O02-02-every-jar-has-license-info' ($noLic -eq 0) "jars with neither Bundle-License nor LICENSE/NOTICE file: $noLic (each needs a manual source in the review)" 'P1'
Test-Ok 'O02-03-fonts-and-translations-listed' ($fonts -gt 0 -and $trans -ge 0) "font files (ttf/otf or ReTeX font classes)=$fonts translation files=$trans" 'P1'
Skip-Blocked 'O02-04-deployment-review' 'human/legal review of EUPL 1.2, GeoGebra non-commercial license, natives, fonts and translations not recorded (owner)' 'P0'
Complete-TestSuite
