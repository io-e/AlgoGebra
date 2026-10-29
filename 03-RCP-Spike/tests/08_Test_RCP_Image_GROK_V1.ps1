# GROK_V1 - AlgoGebra test pack (Windows twin of the .sh suite; same fixtures). Modelled on Claude *_CLAUDE_V1.ps1.
. (Join-Path $PSScriptRoot "lib\TestFramework_GROK_V1.ps1")
# Uses the installed image's launch.ps1 (-Headless for D-02/engines; UI run for GIAC). Parses the consoleLog.
Initialize-TestSuite '08_RCP_Image'
$launch = Join-Path $script:Image 'launch.ps1'; if (-not (Test-Path $launch)) { Exit-Bail "image not found: $script:Image" }
$L = Join-Path $script:Res '08_headless.log'; & pwsh -NoProfile -File $launch -Headless *> $L; $t = Get-Content $L -Raw
Test-Ok 'RCP-01-d02-50-resolved' ($t -match 'found=50, ACTIVE=0, RESOLVED=50, unresolved/other=0' -and $t -match 'D-02 PASS') '50/50' 'P0'
foreach ($e in 'pari','maxima','gnuplot') { Test-Ok "RCP-02-$e-available" ($t -match "external engine $e; available=true") (([regex]::Match($t, "external engine $e; available=\w+")).Value) 'P0' }
$U = Join-Path $script:Res '08_ui.log'; $job = Start-Job { param($l, $u) & pwsh -NoProfile -File $l *> $u } -ArgumentList $launch, $U
for ($i = 0; $i -lt 110; $i++) { Start-Sleep 1; if ((Test-Path $U) -and ((Get-Content $U -Raw) -match '3D view initialized|CAS FAILED')) { break } }
Get-CimInstance Win32_Process -Filter "Name='java.exe'" | Where-Object CommandLine -match 'ggbplus.runId' | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
$job | Stop-Job -PassThru | Remove-Job -Force; $u = Get-Content $U -Raw
Test-Ok 'RCP-03-giac-native' ($u -match 'D-05 GIAC native loaded=true') '' 'P0'
Test-Ok 'RCP-04-giac-expand' ($u -match 'D-05 CAS ASSERTION PASS') (([regex]::Match($u, 'D-05 CAS result: .*')).Value) 'P0'
Test-Ok 'RCP-05-jogl-3d' ($u -match '3D view initialized=true') '' 'P1'
Complete-TestSuite
