# GROK_V1 - D-05 strict 3D: no boot delegation of com.jogamp.*, 3D view must initialise AND render a non-blank image.
# Creates A=(1,2,3) via the 3D input bar and checks the 3D canvas region (colour count / non-dominant pixel fraction).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1'); . (Join-Path $PSScriptRoot 'lib/UiDriver_GROK_V1.ps1')
Initialize-TestSuite '10_D05_Strict3D'
if (-not (Test-Path (Join-Path $script:Image ($IsWindows ? 'launch.ps1' : 'launch.sh')))) { Exit-Bail "image not found: $script:Image" }
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$script:UiDisplay = ':94'; Start-UiDisplay
$log = Start-UiApp '10_strict3d'; $t = Get-Content $log -Raw
Test-Ok 'D05-01-strict-no-boot-delegation' (-not ($t -match 'bootdelegation.*jogamp|boot-delegate-jogamp=true')) 'launched without --boot-delegate-jogamp' 'P0'
Test-Ok 'D05-02-3d-initialized' ($t -match '3D view initialized=true') (([regex]::Match($t, '3D view initialized=\w+')).Value) 'P0'
Test-Ok 'D05-03-no-jogl-linkage-error' (-not ($t -match 'UnsatisfiedLinkError|NoClassDefFoundError: com/jogamp|GLException')) '' 'P0'
$panes = Get-PaneLayout
if (-not $panes) { Skip-Test 'D05-04-3d-pixels' 'panes not found' 'P0' } else { $p3 = $panes[1]
    # 3D canvas = 3D pane minus algebra column (~200 px) and input bar (~60 px)
    $c = @(($p3.X + 210), ($p3.Y + 40), ($p3.X + $p3.W - 10), ($p3.Y + $p3.H - 70))
    $before = Get-UiRegion @c; $s0 = Save-UiShot '10_strict3d_empty'
    Invoke-UiClick $p3.InX $p3.InY; Send-UiText 'A=(1,2,3)'; Send-UiKeys @('Return'); Start-Sleep 3; Close-UiErrorDialog
    $after = Get-UiRegion @c; $s1 = Save-UiShot '10_strict3d_A123'
    Test-Ok 'D05-04-3d-not-blank' (($before.Colors -ge 8) -and ($before.NonDominant -ge 0.01)) "empty 3D scene: colours=$($before.Colors) nonDominant=$($before.NonDominant) region=$($c -join ',') shot=$s0" 'P0'
    Test-Ok 'D05-05-3d-redraw-after-point' ($after.Sig -ne $before.Sig) "after A=(1,2,3): colours=$($after.Colors) nonDominant=$($after.NonDominant) shot=$s1" 'P0' }
if (-not $IsWindows) { $gl = (& python3 -c 'print(1)' 2>$null); Write-Host "# GL: Xvfb GLX (Mesa llvmpipe software rendering), not a hardware GPU" }
Stop-UiDisplay; Complete-TestSuite
