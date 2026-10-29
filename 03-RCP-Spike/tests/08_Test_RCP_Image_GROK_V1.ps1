# GROK_V1 - AlgoGebra test pack, cross-platform (pwsh 7). Installed image: launch.sh (Linux, under Xvfb) / launch.ps1 (Windows).
# Headless run for D-02 + engines, UI run for GIAC/JOGL. Parses the console log.
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'); . (Join-Path $PSScriptRoot 'lib/UiDriver_GROK_V1.ps1')
Initialize-TestSuite '08_RCP_Image'
if (-not (Test-Path (Join-Path $script:Image ($IsWindows ? 'launch.ps1' : 'launch.sh')))) { Exit-Bail "image not found: $script:Image" }
if (-not $IsWindows -and -not (Get-Command Xvfb -CommandType Application -ErrorAction SilentlyContinue)) { Exit-Bail 'Xvfb missing' }
$script:UiDisplay = ':95'; Start-UiDisplay
$L = Start-UiApp '08_headless' @{} @($IsWindows ? '-Headless' : '--headless'); for ($i = 0; $i -lt 60 -and -not ((Get-Content $L -Raw) -match 'D-02 (PASS|FAIL)'); $i++) { Start-Sleep 1 }
Stop-UiApp; $t = Get-Content $L -Raw
Test-Ok 'RCP-01-d02-50-resolved' ($t -match 'found=50, ACTIVE=0, RESOLVED=50, unresolved/other=0' -and $t -match 'D-02 PASS') '50/50' 'P0'
foreach ($e in 'pari', 'maxima', 'gnuplot') { Test-Ok "RCP-02-$e-available" ($t -match "external engine $e; available=true") (([regex]::Match($t, "external engine $e; available=\w+")).Value) 'P0' }
$U = Start-UiApp '08_ui'; Stop-UiApp; $u = Get-Content $U -Raw; Stop-UiDisplay
Test-Ok 'RCP-03-giac-native' ($u -match 'D-05 GIAC native loaded=true') '' 'P0'
Test-Ok 'RCP-04-giac-expand' ($u -match 'D-05 CAS ASSERTION PASS') (([regex]::Match($u, 'D-05 CAS result: .*')).Value) 'P0'
Test-Ok 'RCP-05-jogl-3d' ($u -match '3D view initialized=true') '' 'P1'
Complete-TestSuite
