# GROK_V1 - P-02 Algebra, CAS, spreadsheet, 2D, 3D (desktop part). Gate A.
# Pass (spec): same results as the pinned baseline, within a written tolerance.
# Tolerance (written here): identical value strings after whitespace normalisation; numeric "name = x" values |diff| <= 1e-9.
# Baseline = pinned upstream desktop distribution (no OSGi) running the same directives (fixtures/p02_core_GROK_V1.tsv).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-02'; Write-ScenarioHeader 'P-02' 'Algebra, CAS, spreadsheet, 2D, 3D vs pinned baseline' 'A' 'desktop (web deferred)'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
if (-not (Test-Path $script:BaselineLib)) { Exit-Bail "baseline distribution not found: $script:BaselineLib (extract source/desktop/desktop/build/distributions/desktop.tar; set GGB_BASELINE_LIB)" }
$d = Get-Content (Join-Path $script:ScnFix 'p02_core_GROK_V1.tsv') -Raw; Write-Host "# fixture sha256=$((Get-FileHash (Join-Path $script:ScnFix 'p02_core_GROK_V1.tsv')).Hash.ToLower())"
$script:UiDisplay = ':91'; Start-UiDisplay
$p = Invoke-ProductScenario 'S_P-02_product' $d; $b = Invoke-BaselineScenario 'S_P-02' $d; Stop-UiDisplay
Test-Ok 'P02-00-both-ran' ($p.Scn.Contains('_END') -and $b -and $b.Scn.Contains('_END')) "product=$($p.Scn.Count) lines ($($p.Log)); baseline=$($b.Scn.Count) lines ($($b.Log))" 'P0'
$errs = @($p.Scn.Keys | Where-Object { $p.Scn[$_].St -eq 'ERR' }); Test-Ok 'P02-01-no-directive-error' ($errs.Count -eq 0) "ERR: $($errs -join ', ')" 'P0'
Compare-Scn $p.Scn $b.Scn 'P02'
Skip-Blocked 'P02-W-web-gwt-war' 'deferred: web phase (GWT war baseline, W-02)'
Complete-TestSuite
