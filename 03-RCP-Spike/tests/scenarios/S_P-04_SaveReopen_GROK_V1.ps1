# GROK_V1 - P-04 Open, save, reopen .ggb (desktop part). Gate A. Pass (spec): no silent loss.
# Build a construction, record names/values/XML hash, SAVE .ggb, NEW, OPEN, compare; reopen in a FRESH product session;
# cross-check: the pinned upstream baseline opens the product's file with the same values.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-04'; Write-ScenarioHeader 'P-04' 'Open, save, reopen .ggb' 'A' 'desktop (web deferred)'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$ggb = Join-Path $script:Res 'S_P-04_saved.ggb'; Remove-Item $ggb -ErrorAction SilentlyContinue
$build = Get-Content (Join-Path $script:ScnFix 'p04_construction_GROK_V1.tsv') -Raw
$labels = 'a', 'f', 'P', 'c', 't', 'A1', 'L', 'sl'
$probe = { param($pfx) ($labels | ForEach-Object { "VAL`t$pfx-$_`t$_" }) -join "`n" }
$d1 = $build + "`nNAMES`tN-before`nXMLSHA`tX-before`n" + (& $probe 'V1') + "`nSAVE`tSAVE`t$ggb`nNEW`tNEW`nNAMES`tN-afternew`nOPEN`tOPEN`t$ggb`nNAMES`tN-reopen`nXMLSHA`tX-reopen`n" + (& $probe 'V2')
$script:UiDisplay = ':91'; Start-UiDisplay
$r1 = Invoke-ProductScenario 'S_P-04_session1' $d1; $s = $r1.Scn
Test-Ok 'P04-01-build' (@('B-01','B-02','B-03','B-04','B-05','B-06','B-07','B-08' | Where-Object { $s[$_].Val -ne 'true' }).Count -eq 0) "build results: $(('B-01','B-02','B-03','B-04','B-05','B-06','B-07','B-08' | ForEach-Object { "$_=$($s[$_].Val)" }) -join ' ')" 'P0'
Test-Ok 'P04-02-save' ($s['SAVE'].St -eq 'OK' -and (Test-Path $ggb) -and (Get-Item $ggb).Length -gt 500) "$($s['SAVE'].Val) file=$ggb" 'P0'
Test-Ok 'P04-03-new-clears' ($s['N-afternew'].Val -eq '') "after NEW names='$($s['N-afternew'].Val)'" 'P1'
Test-Ok 'P04-04-reopen-same-objects' ($s['N-reopen'].Val -eq $s['N-before'].Val) "before=[$($s['N-before'].Val)] reopen=[$($s['N-reopen'].Val)]" 'P0'
foreach ($l in $labels) { Test-Ok "P04-05-value-$l" ($s["V2-$l"].Val -eq $s["V1-$l"].Val -and $s["V1-$l"].St -eq 'OK') "before='$($s["V1-$l"].Val)' reopen='$($s["V2-$l"].Val)'" 'P0' }
Test-Ok 'P04-06-xml-hash-informative' $true "xml sha256 before=$($s['X-before'].Val.Substring(0,12)) reopen=$("$($s['X-reopen'].Val)".Substring(0,[math]::Min(12,"$($s['X-reopen'].Val)".Length))) (informative: XML may legitimately differ in ordering)" 'P1'
$d2 = "OPEN`tOPEN2`t$ggb`nNAMES`tN-fresh`n" + (& $probe 'V3')
$r2 = Invoke-ProductScenario 'S_P-04_session2' $d2
Test-Ok 'P04-07-fresh-session-reopen' ($r2.Scn['N-fresh'].Val -eq $s['N-before'].Val -and @($labels | Where-Object { $r2.Scn["V3-$_"].Val -ne $s["V1-$_"].Val }).Count -eq 0) "fresh session names=[$($r2.Scn['N-fresh'].Val)] diffs=[$(($labels | Where-Object { $r2.Scn["V3-$_"].Val -ne $s["V1-$_"].Val }) -join ',')]" 'P0'
$b = Invoke-BaselineScenario 'S_P-04' $d2; Stop-UiDisplay
if (-not $b) { Skip-Blocked 'P04-08-baseline-opens-product-file' "baseline not found: $script:BaselineLib" }
else { $diff = @($labels | Where-Object { $b.Scn["V3-$_"].Val -ne $s["V1-$_"].Val })
    Test-Ok 'P04-08-baseline-opens-product-file' ($b.Scn['N-fresh'].Val -eq $s['N-before'].Val -and $diff.Count -eq 0) "upstream baseline names=[$($b.Scn['N-fresh'].Val)] diffs=[$($diff -join ',')]" 'P0' }
Skip-Blocked 'P04-W-web' 'deferred: web phase'
Complete-TestSuite
