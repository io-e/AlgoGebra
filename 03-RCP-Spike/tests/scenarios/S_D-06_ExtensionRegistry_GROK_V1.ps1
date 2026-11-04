# D-06 product proof: only opt-in, headless bundle installation is exercised.
# It never opens GeoGebra UI or sends desktop input.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1')
Initialize-TestSuite 'S_D-06'
Write-ScenarioHeader 'D-06' 'Extension bundle lifecycle and allowlist' 'B' 'desktop/headless'
Test-ImagePresent

$fixturePaths = @{
    Extension = Join-Path $script:Image 'test-extension/build/org.geogebra.plus.test.extension_1.0.0.jar'
    Unresolved = Join-Path $script:Image 'test-extension/build/org.geogebra.plus.test.extension.bad-import_1.0.1.jar'
    Unapproved = Join-Path $script:Image 'test-extension/build/org.geogebra.plus.test.unauthorized_1.0.0.jar'
}
$missing = @($fixturePaths.GetEnumerator() | Where-Object { -not (Test-Path -LiteralPath $_.Value -PathType Leaf) })
if ($missing.Count -gt 0) {
    Skip-Test 'D06-product-proof' "image lacks D-06 fixture(s): $($missing.Key -join ', '); rebuild the image" 'P0'
    Complete-TestSuite
}

if ($IsWindows) {
    $pwsh = (Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $probe = Invoke-Process $pwsh @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:Launcher,
        '-NoBuild', '-Headless', '-D06') '' 180000
} else {
    $probe = Invoke-Process 'bash' @($script:Launcher, '--headless', '--d06') '' 180000
}
$log = Join-Path $script:Res 'S_D-06.product-headless.log'
Set-Content -LiteralPath $log -Value $probe.out -Encoding UTF8
$text = $probe.out
Test-Ok 'D06-01-product-starts-and-runs-lifecycle' ($probe.rc -eq 0 -and $text -match 'D-06 PASS: install/start/ServiceTracker/stop/uninstall') `
    "exit=$($probe.rc); log=$log" 'P0'
Test-Ok 'D06-02-allowlisted-bundle-installed-and-started' `
    ($text -match 'D-06 allowlisted bundle installed: org\.geogebra\.plus\.test\.extension' -and
     $text -match '\[TEST-EXT\] D-06 extension started and service registered') `
    'allowlisted test extension reached ACTIVE and registered its service' 'P0'
Test-Ok 'D06-03-ServiceTracker-discovers-service' `
    ($text -match 'D-06-02 ServiceTracker discovered the allowlisted extension service' -and
     $text -match '\[TEST-EXT\] D-06 Runnable service invoked') `
    'host discovered and called the extension Runnable through ServiceTracker' 'P0'
Test-Ok 'D06-04-stop-removes-service-and-uninstall-completes' `
    ($text -match 'D-06-03 ServiceTracker confirmed service removal after stop' -and
     $text -match 'D-06-04 allowlisted extension uninstalled without framework restart') `
    'service disappeared on stop; extension reached UNINSTALLED' 'P0'
Test-Ok 'D06-05-unapproved-bundle-rejected-before-install' `
    ($text -match 'D-06 REJECTED bundle before installation: not allowlisted: org\.geogebra\.plus\.test\.unauthorized' -and
     $text -match 'D-06-05 unapproved extension rejected before install') `
    'allowlist rejected the unapproved bundle before BundleContext.installBundle' 'P0'
Test-Ok 'D06-06-unresolved-bundle-isolated-and-rejected' `
    ($text -match 'D-06-06 unresolved allowlisted extension rejected at resolve/start: org\.geogebra\.plus\.test\.extension' -and
     $text -match 'D-06 core integrity after D-06: resolved-or-active=50/50') `
    'bad fixture remained INSTALLED and all 50 D-03 core bundles stayed usable' 'P0'
Test-Ok 'D06-07-core-bundle-set-unchanged' `
    ($text -match 'D-06 core integrity before D-06: resolved-or-active=50/50' -and
     $text -match 'D-06 core integrity after D-06: resolved-or-active=50/50') `
    'the existing 50-bundle D-03 set remained resolved/active before and after the proof' 'P0'

Complete-TestSuite
