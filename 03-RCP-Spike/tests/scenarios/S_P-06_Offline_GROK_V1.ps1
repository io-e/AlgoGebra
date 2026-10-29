# GROK_V1 - P-06 Offline mode (desktop). Pass (spec): the mandatory runtime needs no network.
# Linux: run the product in a user+network namespace without any interface (unshare -rn), do core work (CAS, 3D, save).
# Windows: needs an admin firewall rule or a disconnected VM -> NOT RUN (blocked).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-06'; Write-ScenarioHeader 'P-06' 'Offline mode' '-' 'desktop'; Test-ImagePresent
if ($IsWindows) { Skip-Blocked 'P06-offline-run' 'Windows offline run needs an admin firewall rule or a disconnected VM (not available unattended)' 'P0'; Complete-TestSuite; exit 0 }
$u = Get-Command unshare -ErrorAction SilentlyContinue; if (-not $u) { Exit-Bail 'unshare not found (util-linux)' }
$chk = & unshare -rn sh -c 'tail -n +3 /proc/net/dev | cut -d: -f1 | tr -d " " | tr "\n" " "' 2>&1
Test-Ok 'P06-01-namespace-has-no-network' ("$chk".Trim() -eq 'lo') "interfaces in namespace: $chk" 'P0'
$why = Test-UiPrerequisites; if ($why) { Exit-Bail $why }
$ggb = Join-Path $script:Res 'S_P-06_offline.ggb'; Remove-Item $ggb -ErrorAction SilentlyContinue
$script:UiDisplay = ':91'; Start-UiDisplay
$r = Invoke-ProductScenario 'S_P-06_offline' "CMD`tO-1`tP = (1, 2)`nCAS`tO-2`tFactor(x^2 - 1)`nCMD3`tO-3`ts = Sphere(A, 1)`nVAL3`tO-3v`ts`nSAVE`tO-4`t$ggb`nOPEN`tO-5`t$ggb`nNAMES`tO-6" 180 @{} @('unshare', '-rn')
Stop-UiDisplay; $t = $r.Text
Test-Ok 'P06-02-started-offline' ($t -match 'D-02 PASS' -and $r.Scn.Contains('_END')) "log=$($r.Log)" 'P0'
Test-Ok 'P06-03-core-work-offline' ($r.Scn['O-2'].Val -match '\(x\s*[-+]\s*1\)' -and $r.Scn['O-3v'].St -eq 'OK' -and $r.Scn['O-6'].Val -eq 'P') "CAS='$($r.Scn['O-2'].Val)' 3D='$($r.Scn['O-3v'].Val)' reopen names='$($r.Scn['O-6'].Val)'" 'P0'
$net = [regex]::Matches($t, '(UnknownHostException|ConnectException|SocketTimeoutException|NoRouteToHost|Network is unreachable)[^\r\n]*') | ForEach-Object Value | Select-Object -Unique
Test-Ok 'P06-04-no-network-error' ($net.Count -eq 0) "network errors: [$($net -join ' | ')]" 'P1'
Complete-TestSuite
