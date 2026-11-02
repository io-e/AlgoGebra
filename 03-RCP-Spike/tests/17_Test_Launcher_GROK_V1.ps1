# GROK_V1 - suite 17 (G-04 / BUG-017): Java discovery in the Linux launcher 03-RCP-Spike/launch.sh.
# Order: GGB_JAVA (legacy JAVA) > bundled $IMAGE/jre|jdk > JAVA_HOME > mise > /usr/lib/jvm,/opt/java > PATH; major >= GGB_JAVA_MIN (25).
# Uses `launch.sh --print-java` (no product start) with a scratch HOME/PATH and a scratch image dir, then one real headless start.
# Env: J25 / J21 = JDK homes (default: /workspace/AlgoGebra/jdk/jdk-25*, jdk-21*). Windows: SKIP (launch.ps1 is not in scope).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '17_Launcher'
if ($IsWindows) { Skip-Test 'L-all' 'SKIP reason: Linux launcher (launch.sh); Windows uses launch.ps1' 'P0'; Complete-TestSuite }
$launch = Join-Path $script:SpikeDir 'launch.sh'
$j25 = if ($env:J25) { $env:J25 } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-25*' | Select-Object -First 1).FullName }
$j21 = if ($env:J21) { $env:J21 } else { (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-21*' | Select-Object -First 1).FullName }
foreach ($p in $launch, $j25, $j21) { if (-not $p -or -not (Test-Path $p)) { Exit-Bail "missing: $p" } }
$w = Join-Path $script:Tmp "grok17-$PID"; $img = Join-Path $w 'image'; New-Item -ItemType Directory -Force (Join-Path $img 'bundles'), (Join-Path $w 'home'), (Join-Path $w 'pathbin'), (Join-Path $w 'old/bin') | Out-Null
& ln -s (Join-Path $j25 'bin/java') (Join-Path $w 'pathbin/java')
Set-Content (Join-Path $w 'old/bin/java') "#!/bin/sh`necho '    java.specification.version = 1.8' >&2`n" -Encoding ascii; & chmod +x (Join-Path $w 'old/bin/java')
function Invoke-Launch([hashtable]$Env, [string]$Image = $img, [string[]]$A = @('--print-java')) {
    $base = @{ HOME = (Join-Path $w 'home'); PATH = '/usr/bin:/bin'; IMAGE = $Image; GGB_JAVA = ''; JAVA = ''; JAVA_HOME = ''; GGB_JAVA_MIN = '' }
    foreach ($k in $Env.Keys) { $base[$k] = $Env[$k] }
    $envArgs = @('-i') + @($base.GetEnumerator() | Where-Object { $_.Value -ne '' } | ForEach-Object { "$($_.Key)=$($_.Value)" })
    $o = (& env @envArgs bash $launch @A 2>&1 | Out-String).Trim(); return [pscustomobject]@{ Rc = $LASTEXITCODE; Out = $o } }
$cases = @(
    @{ Id = 'L-01-ggb-java'; Env = @{ GGB_JAVA = "$j25/bin/java" }; Rc = 0; Rx = 'SOURCE=GGB_JAVA MAJOR=25' },
    @{ Id = 'L-02-legacy-JAVA'; Env = @{ JAVA = "$j25/bin/java" }; Rc = 0; Rx = 'SOURCE=GGB_JAVA MAJOR=25' },
    @{ Id = 'L-03-ggb-java-too-old'; Env = @{ GGB_JAVA = "$j21/bin/java" }; Rc = 4; Rx = 'not a usable Java >= 25.*Java 21 < 25' },
    @{ Id = 'L-04-java-home'; Env = @{ JAVA_HOME = $j25 }; Rc = 0; Rx = 'SOURCE=JAVA_HOME MAJOR=25' },
    @{ Id = 'L-05-java-home-too-old-none-else'; Env = @{ JAVA_HOME = $j21 }; Rc = 4; Rx = 'no Java >= 25 found(?s).*JAVA_HOME: .*\(Java 21 < 25\)' },
    @{ Id = 'L-06-path-java'; Env = @{ PATH = "$(Join-Path $w 'pathbin'):/usr/bin:/bin" }; Rc = 0; Rx = 'SOURCE=PATH MAJOR=25' },
    @{ Id = 'L-07-min-override-21'; Env = @{ JAVA_HOME = $j21; GGB_JAVA_MIN = '21' }; Rc = 0; Rx = 'SOURCE=JAVA_HOME MAJOR=21 MIN=21' },
    @{ Id = 'L-08-legacy-1.8-version-parse'; Env = @{ JAVA_HOME = (Join-Path $w 'old') }; Rc = 4; Rx = '\(Java 8 < 25\)' },
    @{ Id = 'L-09-nothing-found-clear-error'; Env = @{}; Rc = 4; Rx = 'no Java >= 25 found\. Set GGB_JAVA' })
foreach ($c in $cases) { $r = Invoke-Launch $c.Env; Test-Ok $c.Id ($r.Rc -eq $c.Rc -and $r.Out -match $c.Rx) "rc=$($r.Rc) (want $($c.Rc)) out=[$($r.Out -replace "`n", ' | ')]" 'P0' }
New-Item -ItemType Directory -Force (Join-Path $img 'jre/bin') | Out-Null; & ln -s (Join-Path $j25 'bin/java') (Join-Path $img 'jre/bin/java')
$r = Invoke-Launch @{ JAVA_HOME = $j21 }; Test-Ok 'L-10-bundled-jre-wins-over-java-home' ($r.Rc -eq 0 -and $r.Out -match 'SOURCE=bundled MAJOR=25') "out=[$($r.Out)]" 'P0'
$r = Invoke-Launch @{} (Join-Path $w 'no-image'); Test-Ok 'L-11-missing-image' ($r.Rc -eq 3 -and $r.Out -match 'no RCP image') "rc=$($r.Rc) out=[$($r.Out)]" 'P1'
# F-1 (GROK_V1): mise cases with a fake `mise` on PATH (prints `mise where java`), so no real mise install is needed
$mb = Join-Path $w 'misebin'; New-Item -ItemType Directory -Force $mb | Out-Null
function Set-FakeMise([string]$JHome) { Set-Content (Join-Path $mb 'mise') "#!/bin/sh`n[ `"`$1 `$2`" = 'where java' ] && echo '$JHome'`n" -Encoding ascii; & chmod +x (Join-Path $mb 'mise') }
Set-FakeMise $j25
New-Item -ItemType Directory -Force (Join-Path $w 'img-mise/bundles') | Out-Null; $r = Invoke-Launch @{ PATH = "${mb}:/usr/bin:/bin" } (Join-Path $w 'img-mise')
Test-Ok 'L-14-mise-java-25' ($r.Rc -eq 0 -and $r.Out -match 'SOURCE=mise MAJOR=25' -and $r.Out -notmatch 'warning') "out=[$($r.Out)]" 'P1'
Set-FakeMise $j21; $r = Invoke-Launch @{ PATH = "${mb}:$(Join-Path $w 'pathbin'):/usr/bin:/bin" } (Join-Path $w 'img-mise')
Test-Ok 'L-15-mise-pin-too-old-warns-and-falls-through' ($r.Rc -eq 0 -and $r.Out -match 'warning: mise-pinned Java at .* is below 25' -and $r.Out -match 'SOURCE=PATH MAJOR=25') "out=[$($r.Out -replace "`n", ' | ')]" 'P1'
$t = Get-Content $launch -Raw; Test-Ok 'L-12-no-hardcoded-workspace-path' ($t -notmatch '/workspace/AlgoGebra') 'launch.sh has no /workspace/AlgoGebra fallback' 'P0'
# real headless start of the installed image with the repo launcher (GGB_JAVA from the test framework / J25)
$realImg = $script:Image
if (-not (Test-Path (Join-Path $realImg 'bundles'))) { Skip-Test 'L-13-headless-start' "SKIP reason: image not found: $realImg" }
else { $log = Join-Path $script:Res '17_headless.log'; $env:IMAGE = $realImg; $env:GGB_JAVA = "$j25/bin/java"
    $p = Start-Process bash -ArgumentList $launch, '--headless' -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
    for ($i = 0; $i -lt 120 -and -not $p.HasExited; $i++) { Start-Sleep 1; if ((Get-Content $log -Raw -ErrorAction SilentlyContinue) -match 'D-02 PASS|Headless D-02 smoke') { break } }
    Start-Sleep 3; if (-not $p.HasExited) { & pkill -f "ggbplus.runId" 2>$null }
    $tx = Get-Content $log -Raw; Test-Ok 'L-13-headless-start' ($tx -match 'D-02 PASS|Headless D-02 smoke') "repo launch.sh --headless, image=$realImg java=$j25 log=$log" 'P1' }
Remove-Item $w -Recurse -Force -ErrorAction SilentlyContinue
Complete-TestSuite
