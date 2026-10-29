# GROK_V1 - P-03 Standard tools (desktop part). Gate A. Pass (spec): no missing tool against the pin.
# Compares the 2D toolbar definition (mode ids) of the RCP product with the pinned upstream desktop build, and checks
# that each tool mode can be activated (setMode via evalCommand SetActiveView is not public: mode list comparison only).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-03'; Write-ScenarioHeader 'P-03' 'Standard tools vs pin' 'A' 'desktop (web deferred)'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }; if (-not (Test-Path $script:BaselineLib)) { Exit-Bail "baseline not found: $script:BaselineLib" }
$d = "TOOLS`tTOOLS-2D"; $script:UiDisplay = ':91'; Start-UiDisplay
$p = Invoke-ProductScenario 'S_P-03_product' $d; $b = Invoke-BaselineScenario 'S_P-03' $d; Stop-UiDisplay
function Get-Modes([string]$def) { @([regex]::Matches("$def", '\d+') | ForEach-Object { [int]$_.Value } | Sort-Object -Unique) }
$pm = Get-Modes $p.Scn['TOOLS-2D'].Val; $bm = Get-Modes $b.Scn['TOOLS-2D'].Val
Test-Ok 'P03-01-toolbar-read' ($pm.Count -gt 0 -and $bm.Count -gt 0) "product modes=$($pm.Count) baseline modes=$($bm.Count)" 'P0'
$missing = @($bm | Where-Object { $_ -notin $pm }); $extra = @($pm | Where-Object { $_ -notin $bm })
Test-Ok 'P03-02-no-missing-tool' ($missing.Count -eq 0) "missing mode ids=[$($missing -join ',')] extra=[$($extra -join ',')]" 'P0'
Test-Ok 'P03-03-toolbar-identical' ((Norm-Val $p.Scn['TOOLS-2D'].Val) -eq (Norm-Val $b.Scn['TOOLS-2D'].Val)) "product='$($p.Scn['TOOLS-2D'].Val)'" 'P1'
Skip-Blocked 'P03-04-3d-toolbar' 'not automated: App3D toolbar comparison needs a 3D GuiManager directive (gap, listed)'
Skip-Blocked 'P03-W-web' 'deferred: web phase'
Complete-TestSuite
