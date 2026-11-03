# GROK_V1 probe: X/AWT focus trace for #48 bridge (Debian Xvfb, no WM)
$t='/workspace/AlgoGebra/wt-v48/03-RCP-Spike/tests'
. "$t/lib/TestFramework_GROK_V1.ps1"; . "$t/lib/UiDriver_GROK_V1.ps1"
Initialize-TestSuite 'probe_focus'
Start-UiDisplay '1600x1000x24'
$log = Start-UiApp 'probe' @{ JAVA_TOOL_OPTIONS = '-Dggbplus.focusTrace=true' }
$panes = Get-PaneLayout; $p2=$panes[0]; $p3=$panes[1]
function F($tag){ $w="$(& xdotool getwindowfocus 2>$null)".Trim(); Write-Host "# $tag xfocus=$w name=$(& xdotool getwindowname $w 2>$null)" }
F 'start'
Invoke-UiClick $p2.InX $p2.InY; F 'after-click-2D'; Send-UiText 'a=1'; Send-UiKeys @('Return'); Start-Sleep 1
Invoke-UiClick $p3.InX $p3.InY; F 'after-click-3D'; Start-Sleep 1; F 'after-click-3D+1s'
$b=(Get-RegionOf $p3.Bar).Sig; Send-UiText 'E=(1,1,1)'; Write-Host "# 3D lost=$((Get-RegionOf $p3.Bar).Sig -eq $b)"
Save-UiShot 'probe_3d' | Out-Null
Invoke-UiClick $p3.InX $p3.InY; F 'second-click-3D'; $b=(Get-RegionOf $p3.Bar).Sig; Send-UiText 'Q'; Write-Host "# 3D 2nd-click lost=$((Get-RegionOf $p3.Bar).Sig -eq $b)"
Start-Sleep 1; Stop-UiDisplay
Get-Content $log | Select-String 'focus bridge|D-04'
