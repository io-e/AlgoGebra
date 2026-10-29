# GROK_V1 - O-04 Missing bundle, bad .ggb, Wims down. Pass (spec): safe message, redacted log.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_O-04'; Write-ScenarioHeader 'O-04' 'Missing bundle, bad .ggb, Wims down' '-' 'desktop'; Test-ImagePresent
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$orig = $script:Image; $script:UiDisplay = ':91'; Start-UiDisplay
$cp = New-ImageCopy 'O04-missing' '^org\.geogebra\.migration\.desktop\.editor,'; Remove-Item (Join-Path $cp 'bundles/org.geogebra.migration.desktop.editor-*.jar') -Force; Use-Image $cp
$r = Invoke-ProductScenario 'S_O-04_missing_bundle' "NAMES`tM1" 120; Use-Image $orig
$msg = ([regex]::Match($r.Text, 'D-02[^\r\n]*(FAIL|unresolved)[^\r\n]*')).Value
Test-Ok 'O04-01-missing-bundle-reported' ($r.Text -match 'D-02 FAIL|unresolved/other=[1-9]|UNRESOLVED') "message: $msg log=$($r.Log)" 'P0'
Test-Ok 'O04-02-missing-bundle-no-hang' ($r.Seconds -lt 120) "run time $($r.Seconds) s" 'P1'
Remove-Item $cp -Recurse -Force -ErrorAction SilentlyContinue
$bad1 = Join-Path $script:Res 'S_O-04_garbage.ggb'; [IO.File]::WriteAllBytes($bad1, [byte[]](1..2000 | ForEach-Object { Get-Random -Maximum 256 -SetSeed $_ }))
$bad2 = Join-Path $script:Res 'S_O-04_badxml.ggb'; Add-Type -AssemblyName System.IO.Compression.FileSystem; Remove-Item $bad2 -ErrorAction SilentlyContinue
$z = [IO.Compression.ZipFile]::Open($bad2, 'Create'); $e = $z.CreateEntry('geogebra.xml'); $w = New-Object IO.StreamWriter($e.Open()); $w.Write('<geogebra format="5.0"><construction><element type="point" label="Z"><coords x="1" y=</construction>'); $w.Close(); $z.Dispose()
$r2 = Invoke-ProductScenario 'S_O-04_bad_ggb' "CMD`tG0`tKeep = 7`nOPENRAW`tG1`t$bad1`nOPENRAW`tG2`t$bad2`nNAMES`tG3`nCMD`tG4`tAfter = 1`nVAL`tG5`tAfter" 150
Stop-UiDisplay
Test-Ok 'O04-03-bad-ggb-app-survives' ($r2.Scn['G5'].Val -eq 'After = 1') "garbage open: $($r2.Scn['G1'].St) '$($r2.Scn['G1'].Val)'; bad xml: $($r2.Scn['G2'].St) '$($r2.Scn['G2'].Val)'; names after=[$($r2.Scn['G3'].Val)]" 'P0'
$dlg = @($r2.Scn.Keys | Where-Object { $_ -like '_DIALOG*' }); Write-Host "# dialogs: $(($r2.Text -split "`n" | Select-String '_DIALOG') -join ' | ')"
$leak = [regex]::Matches($r.Text + $r2.Text, '(?i)(password|token|secret)=\S+') | ForEach-Object Value
Test-Ok 'O04-04-log-redacted' ($leak.Count -eq 0) "secret-like values in logs: $($leak.Count)" 'P1'
Skip-Blocked 'O04-05-wims-down' 'no Wims client yet (S-xx contracts); cannot simulate Wims down' 'P0'
Skip-Blocked 'O04-06-user-facing-safe-message' 'missing-bundle message is only in the console log; no user dialog/report designed yet' 'P1'
Complete-TestSuite
