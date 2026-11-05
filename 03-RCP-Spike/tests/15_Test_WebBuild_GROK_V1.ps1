# GROK_V1 - suite 15 (WP3a-03 / G-03): GeoGebra GWT web build, self-hosted.
# Checks a war built from the pinned upstream clone (see 03-RCP-Spike/docs/Report_WebBuild_GROK_V1.md):
#   ./gradlew -p source/web -Pgmodule=org.geogebra.web.SuperWeb :web:gwtCompile :web:copyHtml :web:mergeDeploy   (JDK 21)
# then serves it with python http.server (runtime only), loads fixtures/web/webbuild_probe_GROK_V1.html in headless
# Chrome/Chromium/Edge (deployggb.js + setHTML5Codebase('war/web3d/')), drives it over CDP (fixtures/web/cdp_probe_GROK_V1.mjs,
# Node >= 20 with --experimental-websocket), checks evalCommand / getValueString / CAS, that no request left localhost, screenshot.
# Env: GGB_WEB_WAR (war dir; default <repo>/../geogebra/source/web/web/war), GGB_WEB_BUILD=1 (run the gradle build first,
#      needs GGB_UPSTREAM = upstream clone root and JAVA_HOME = JDK 21), GGB_BROWSER, GGB_WEB_PORT (default 8765).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '15_WebBuild'
$repo = Split-Path $script:SpikeDir -Parent
$up = if ($env:GGB_UPSTREAM) { $env:GGB_UPSTREAM } else { Join-Path (Split-Path $repo -Parent) 'geogebra' }
$war = if ($env:GGB_WEB_WAR) { $env:GGB_WEB_WAR } else { [IO.Path]::Combine($up, 'source', 'web', 'web', 'war') }
$port = if ($env:GGB_WEB_PORT) { [int]$env:GGB_WEB_PORT } else { 8765 }
$fixWeb = Join-Path $script:Fix 'web'
$out = Join-Path $script:Res 'webbuild'; New-Item -ItemType Directory -Force $out | Out-Null

if ($env:GGB_WEB_BUILD -eq '1') {
    $gw = Join-Path $up $(if ($IsWindows) { 'gradlew.bat' } else { 'gradlew' }); if (-not (Test-Path $gw)) { Exit-Bail "no gradlew in $up" }
    $log = Join-Path $out 'gwt-build.log'; $sw = [Diagnostics.Stopwatch]::StartNew()
    Push-Location $up; try { & $gw -p source/web '-Pgmodule=org.geogebra.web.SuperWeb' ':web:gwtCompile' ':web:copyHtml' ':web:mergeDeploy' --no-daemon --console=plain *> $log; $rc = $LASTEXITCODE } finally { Pop-Location }
    Test-Ok 'WEB-00-build' ($rc -eq 0) "gradle exit=$rc in $([int]$sw.Elapsed.TotalSeconds)s log=$log" 'P0'
}
if (-not (Test-Path $war)) { Exit-Bail "war not found: $war (set GGB_WEB_WAR or GGB_WEB_BUILD=1)" }
$commit = try { (& git -C $up rev-parse --short HEAD 2>$null) } catch { '?' }
Write-Host "# war=$war upstream=$commit"

# --- static artefacts ---
$nocache = [IO.Path]::Combine($war, 'web3d', 'web3d.nocache.js'); $deploy = Join-Path $war 'deployggb.js'
foreach ($f in $nocache, $deploy) { $ok = Test-Path $f; $d = if ($ok) { "size=$((Get-Item $f).Length) sha256=$((Get-FileHash $f -Algorithm SHA256).Hash.ToLower())" } else { 'missing' }
    Test-Ok "WEB-01-$(Split-Path $f -Leaf)" $ok "$f $d" 'P0' }
$perm = @(Get-ChildItem ([IO.Path]::Combine($war, 'web3d', 'deferredjs')) -Directory -ErrorAction SilentlyContinue)
Test-Ok 'WEB-02-permutation' ($perm.Count -ge 1) "deferredjs permutations: $($perm.Name -join ',')" 'P0'
$dtxt = if (Test-Path $deploy) { Get-Content $deploy -Raw } else { '' }
Test-Ok 'WEB-03-deploy-merged' ($dtxt -notmatch '%WEB3D_PERMUTATION%|%MODULE_BASE%' -and $dtxt -match 'setHTML5Codebase' -and ($perm.Count -eq 0 -or $dtxt.Contains($perm[0].Name))) 'template placeholders replaced, permutation id present, setHTML5Codebase exported' 'P0'
$size = (Get-ChildItem $war -Recurse -File | Measure-Object Length -Sum).Sum
Test-Ok 'WEB-04-size' ($size -gt 10MB) "war files=$(@(Get-ChildItem $war -Recurse -File).Count) bytes=$size" 'P2'

# --- runtime tools ---
$py = @('python3', 'python', 'py') | ForEach-Object { Get-Command $_ -CommandType Application -ErrorAction SilentlyContinue } | Select-Object -First 1
$node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$br = if ($env:GGB_BROWSER) { Get-Command $env:GGB_BROWSER -ErrorAction SilentlyContinue } else {
    @('google-chrome', 'chromium', 'chromium-browser', 'chrome', 'msedge',
      "$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe") |
      ForEach-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1 }
if (-not ($py -and $node -and $br)) { Skip-Test 'WEB-10-headless' "needs python + node>=20 + chromium-family browser (python=$([bool]$py) node=$([bool]$node) browser=$([bool]$br))" 'P0'; Complete-TestSuite; return }

# --- serve: temp root = probe page + link to war (junction on Windows, no admin) ---
$root = Join-Path $script:Tmp "grok15-$PID"; New-Item -ItemType Directory -Force $root | Out-Null
Copy-Item (Join-Path $fixWeb 'webbuild_probe_GROK_V1.html') $root
New-Item -ItemType $(if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }) -Path (Join-Path $root 'war') -Target ([IO.Path]::GetFullPath($war)) | Out-Null
$srvLog = Join-Path $out 'http-server.log'; $cdpPort = $port + 1000
$srv = Start-Process $py.Source -ArgumentList @('-m', 'http.server', "$port", '--bind', '127.0.0.1', '--directory', $root) -PassThru -RedirectStandardError $srvLog -RedirectStandardOutput (Join-Path $out 'http-server.out')
$prof = Join-Path $root 'profile'; $bargs = @('--headless=new', '--disable-gpu', "--user-data-dir=$prof", '--window-size=1000,700', "--remote-debugging-port=$cdpPort", 'about:blank')
if (-not $IsWindows) { $bargs = @('--no-sandbox') + $bargs }
$bro = Start-Process $br.Source -ArgumentList $bargs -PassThru -RedirectStandardError (Join-Path $out 'browser.log') -RedirectStandardOutput (Join-Path $out 'browser.out')
try {
    $deadline = (Get-Date).AddSeconds(20); $up1 = $false
    while ((Get-Date) -lt $deadline -and -not $up1) { Start-Sleep -Milliseconds 500
        try { Invoke-WebRequest "http://127.0.0.1:$port/webbuild_probe_GROK_V1.html" -UseBasicParsing -TimeoutSec 2 | Out-Null; Invoke-WebRequest "http://127.0.0.1:$cdpPort/json/version" -UseBasicParsing -TimeoutSec 2 | Out-Null; $up1 = $true } catch { } }
    Test-Ok 'WEB-10-serve' $up1 "http.server :$port + $(Split-Path $br.Source -Leaf) CDP :$cdpPort" 'P0'
    $probeMs = if ($env:GGB_WEB_PROBE_TIMEOUT_MS) { [int]$env:GGB_WEB_PROBE_TIMEOUT_MS } else { 90000 }; $png = Join-Path $out 'webbuild_probe.png'; $sw = [Diagnostics.Stopwatch]::StartNew()
    $raw = & $node.Source --experimental-websocket --no-warnings (Join-Path $fixWeb 'cdp_probe_GROK_V1.mjs') "$cdpPort" "http://127.0.0.1:$port/webbuild_probe_GROK_V1.html" $png $probeMs 2>&1 | Out-String
    $raw | Set-Content (Join-Path $out 'probe-result.txt') -Encoding utf8
    $R = $null; if ($raw -match 'RESULT (\{.*\})') { $R = $Matches[1] | ConvertFrom-Json }
    Test-Ok 'WEB-11-applet-loaded' ($R -and $R.loaded -and -not $R.error) "appletOnLoad fired=$($R.loaded) after $($R.ms) ms (wall $([int]$sw.Elapsed.TotalSeconds)s, probe timeout $probeMs ms) error=$($R.error)" 'P0'
    Test-Ok 'WEB-12-evalCommand' ($R -and $R.evalPoint -and $R.evalFunc -and $R.evalMatrix) "evalCommand A/f/m = $($R.evalPoint)/$($R.evalFunc)/$($R.evalMatrix)" 'P0'
    Test-Eq 'WEB-13-getValueString-point' "$($R.valPoint)" 'A = (1, 2)' 'P0'
    Test-Eq 'WEB-14-getValueString-func' "$($R.valFunc)" 'f(x) = x² - 2x' 'P0'
    Test-Eq 'WEB-15-getValueString-matrix' "$($R.valMatrix)" 'm = {{1, 2}, {3, 4}}' 'P1'
    Test-Ok 'WEB-16-getValue' ($R -and [double]$R.value -eq 1) "getValue('x(A)')=$($R.value)" 'P1'
    Test-Eq 'WEB-17-CAS-giac-js' "$($R.cas)" 'x² + 2x + 1' 'P1'
    Test-Ok 'WEB-18-codebase-local' ($R -and @($R.external).Count -eq 0 -and @($R.resources | Where-Object { $_ -like '*/war/web3d/*' }).Count -ge 2) "resources=$(@($R.resources).Count) external=$(@($R.external) -join ',')" 'P0'
    $pngOk = (Test-Path $png) -and (Get-Item $png).Length -gt 10KB
    Test-Ok 'WEB-19-screenshot' $pngOk "$png $(if ($pngOk) { 'sha256=' + (Get-FileHash $png -Algorithm SHA256).Hash.ToLower() })" 'P1'
} finally {
    foreach ($p in $bro, $srv) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }
    Remove-Item (Join-Path $root 'war') -Force -ErrorAction SilentlyContinue
}
Complete-TestSuite
