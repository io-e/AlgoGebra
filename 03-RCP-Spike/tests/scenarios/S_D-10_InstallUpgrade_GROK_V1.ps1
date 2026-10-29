# GROK_V1 - D-10 Install, upgrade, rollback (clean Windows). Pass (spec): no rights, Java or path problem.
# Precheck: the image is self-contained (bundled Java 25, natives, launcher) and does not depend on a system Java.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-10'; Write-ScenarioHeader 'D-10' 'Install, upgrade, rollback' '-' 'desktop'; Test-ImagePresent
$jre = Get-ChildItem $script:Image -Recurse -Filter ('java' + $script:Exe) -ErrorAction SilentlyContinue | Where-Object { $_.Directory.Name -eq 'bin' } | Select-Object -First 1
$ver = if ($jre) { (& $jre.FullName -version 2>&1 | Select-Object -First 1) } else { '' }
Test-Ok 'D10-01-bundled-java-25' ($jre -and "$ver" -match '"25') "java=$($jre.FullName) version=$ver" 'P0'
$nat = @(Get-ChildItem (Join-Path $script:Image 'natives') -Recurse -File -ErrorAction SilentlyContinue)
Test-Ok 'D10-02-natives-present' ($nat.Count -gt 0) "native files=$($nat.Count)" 'P0'
$l = Get-Content $script:Launcher -Raw
$jl = ([regex]::Match($l, '(?m)^.*(JAVA=|java\.exe|\$java\s*=).*$')).Value.Trim()
Test-Ok 'D10-03-launcher-uses-bundled-java' ($jl -and $jl -notmatch '/workspace/|ALF_ZGit|JAVA_HOME') "launcher Java line: $jl" 'P1'
$cfg = @(Get-ChildItem (Join-Path $script:Image 'configuration') -Recurse -File | Where-Object { $_.FullName -notmatch 'runtime-' } | ForEach-Object { Get-Content $_.FullName })
$abs = @($cfg | Where-Object { $_ -match '(/workspace/|/home/|[A-Z]:\\)' -and $_ -notmatch [regex]::Escape($script:Image) })
Test-Ok 'D10-04-relocatable-configuration' ($abs.Count -eq 0) "static configuration lines with an absolute path outside the image: $($abs.Count) $(($abs | Select-Object -First 2) -join ' | ')" 'P1'
Skip-Blocked 'D10-05-install-upgrade-rollback' 'no installer (MSI/MSIX/zip+script contract) and no clean Windows VM; install-product.ps1 is a developer helper only' 'P0'
Complete-TestSuite
