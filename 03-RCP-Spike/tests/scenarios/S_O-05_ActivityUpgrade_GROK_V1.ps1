# GROK_V1 - O-05 One activity upgrade. Pass (spec): old file still opens.
# Precheck: a .ggb written in an older XML format (format 4.0, hand-built fixture) opens in the product with its values,
# same as the pinned baseline. The activity manifest/upgrade path does not exist yet.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_O-05'; Write-ScenarioHeader 'O-05' 'One activity upgrade' '-' 'desktop'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$old = Join-Path $script:Res 'S_O-05_format40.ggb'; Remove-Item $old -ErrorAction SilentlyContinue
$xml = '<?xml version="1.0" encoding="utf-8"?><geogebra format="4.0" version="4.0.0.0"><kernel><decimals val="2"/></kernel><construction title="old"><element type="point" label="P"><coords x="2" y="3" z="1"/></element><element type="numeric" label="k"><value val="1.5"/></element><expression label="g" exp="g(x) = k x"/><element type="function" label="g"></element></construction></geogebra>'
$z = [IO.Compression.ZipFile]::Open($old, 'Create'); $e = $z.CreateEntry('geogebra.xml'); $w = New-Object IO.StreamWriter($e.Open()); $w.Write($xml); $w.Close(); $z.Dispose()
$d = "OPEN`tA1`t$old`nNAMES`tA2`nVAL`tA3`tP`nVAL`tA4`tk`nVAL`tA5`tg"
$script:UiDisplay = ':91'; Start-UiDisplay; $p = Invoke-ProductScenario 'S_O-05_product' $d; $b = Invoke-BaselineScenario 'S_O-05' $d; Stop-UiDisplay
Test-Ok 'O05-01-old-format-opens' ($p.Scn['A1'].St -eq 'OK' -and $p.Scn['A3'].Val -eq 'P = (2, 3)') "names=[$($p.Scn['A2'].Val)] P='$($p.Scn['A3'].Val)' k='$($p.Scn['A4'].Val)' g='$($p.Scn['A5'].Val)'" 'P0'
Test-Ok 'O05-02-same-as-baseline' ($b -and (@('A2','A3','A4','A5') | Where-Object { $p.Scn[$_].Val -ne $b.Scn[$_].Val }).Count -eq 0) "baseline names=[$($b.Scn['A2'].Val)] g='$($b.Scn['A5'].Val)'" 'P0'
Skip-Blocked 'O05-03-activity-manifest-upgrade' 'no activity manifest / versioned activity format yet' 'P0'
Complete-TestSuite
