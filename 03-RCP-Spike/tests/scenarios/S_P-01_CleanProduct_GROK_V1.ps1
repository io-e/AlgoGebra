# GROK_V1 - P-01 Clean product, no optional extension (desktop part; web: deferred). Gate A context.
# Pass (spec): views open, no missing mandatory bundle.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-01'; Write-ScenarioHeader 'P-01' 'Clean product, no optional extension' 'A' 'desktop (web deferred)'; Test-ImagePresent
$info = Get-ChildItem (Join-Path $script:Image 'configuration') -Recurse -Filter 'bundles.info' | Select-Object -First 1
$lines = @(Get-Content $info.FullName | Where-Object { $_ -and -not $_.StartsWith('#') })
# Optional extensions = external engine bundles and any non-core extension; the shipped image enables the engines by default.
$optRx = '^(org\.geogebra\.plus\.engine\.|org\.geogebra\.plus\.compute\.runtime|.*(wims|lean|extension))'
$opt = @($lines | Where-Object { $_ -match $optRx } | ForEach-Object { ($_ -split ',')[0] })
Write-Host "# shipped image optional bundles (removed for the clean profile): $($opt -join ', ')"
$clean = New-ImageCopy 'P01-clean' $optRx; Use-Image $clean
$left = @(Get-Content (Join-Path $clean 'configuration/org.eclipse.equinox.simpleconfigurator/bundles.info') | Where-Object { $_ -match $optRx })
Test-Ok 'P01-01-clean-profile-has-no-optional-extension' ($left.Count -eq 0) "clean profile copy=$clean; removed=[$($opt -join ', ')]; left=[$($left -join '; ')]" 'P0'
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$script:UiDisplay = ':91'; Start-UiDisplay
$r = Invoke-ProductScenario 'S_P-01_ui' "NAMES`tP01-names2d`nNAMES3`tP01-names3d`nTOOLS`tP01-tools`nJAVA`tP01-env"
$t = $r.Text
Test-Ok 'P01-02-d02-all-mandatory-resolved' ($t -match 'found=50, ACTIVE=0, RESOLVED=50, unresolved/other=0' -and $t -match 'D-02 PASS' -and $t -notmatch 'UNRESOLVED ') (([regex]::Match($t, 'D-02 D-03-set check:[^\r\n]*')).Value) 'P0'
Test-Ok 'P01-03-2d-view-open' ($t -match 'D-04 GeoGebraPanel embedded in SWT_AWT shell' -and $t -notmatch 'EMBEDDING FAILED') 'GeoGebraPanel (algebra + graphics + input) embedded' 'P0'
Test-Ok 'P01-04-3d-view-open' ($t -match '3D view initialized=true') (([regex]::Match($t, '3D view initialized=\w+')).Value) 'P0'
Test-Ok 'P01-05-cas-available' ($t -match 'D-05 CAS ASSERTION PASS') (([regex]::Match($t, 'D-05 CAS result: [^\r\n]*')).Value) 'P0'
Test-Ok 'P01-06-ui-api-reachable' ($r.Scn['P01-names3d'].St -eq 'OK' -and $r.Scn['P01-tools'].St -eq 'OK') "3D objects=[$($r.Scn['P01-names3d'].Val)] toolbar chars=$("$($r.Scn['P01-tools'].Val)".Length) env=$($r.Scn['P01-env'].Val)" 'P0'
$miss = [regex]::Matches($t, '(ClassNotFoundException|NoClassDefFoundError|MissingResourceException)[^\r\n]*') | ForEach-Object Value | Select-Object -Unique
Test-Ok 'P01-07-no-missing-class-or-resource' ($miss.Count -eq 0) "[$($miss -join ' | ')] log=$($r.Log)" 'P1'
Save-UiShot 'S_P-01_views' | Out-Null; Stop-UiDisplay; Remove-Item $clean -Recurse -Force -ErrorAction SilentlyContinue
Skip-Blocked 'P01-W-web-client' 'deferred: web phase (Gate C, W-01/W-02)'
Complete-TestSuite
