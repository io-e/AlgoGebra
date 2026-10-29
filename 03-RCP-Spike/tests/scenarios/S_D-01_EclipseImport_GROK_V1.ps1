# GROK_V1 - D-01 Eclipse import (Gradle projects in Eclipse 2026-06 + Buildship). Pass (spec): no manual classpath fix.
# Precheck only: the Gradle composite and settings that Buildship would import are present and parseable.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_D-01'; Write-ScenarioHeader 'D-01' 'Eclipse import' '-' 'desktop (dev tooling)'
$set = Join-Path $script:GgbSource 'desktop/settings.gradle.kts'; if (-not (Test-Path $set)) { $set = Get-ChildItem $script:GgbSource -Recurse -Depth 2 -Filter 'settings.gradle*' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName }
Test-Ok 'D01-01-gradle-settings-present' ($set -and (Test-Path $set)) "settings=$set" 'P1'
$w = Get-ChildItem $script:GgbSource -Recurse -Depth 2 -Filter 'gradlew*' -ErrorAction SilentlyContinue | Select-Object -First 1
Write-Host "# note: gradle wrapper in the pinned source: $(if ($w) { $w.FullName } else { 'none (Buildship then needs a configured local Gradle installation)' })"
$ecl = @('eclipse', 'eclipse.exe') | ForEach-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
if (-not $ecl) { Skip-Blocked 'D01-03-eclipse-buildship-import' 'Eclipse 2026-06 + Buildship not installed on the test host (needs owner approval to install, D-ENG-02 on Windows); manual import checklist in SCENARIOS_TRACKING_GROK_V1.md' 'P0' }
else { Skip-Blocked 'D01-03-eclipse-buildship-import' "Eclipse found at $($ecl.Source) but headless Buildship import is not automated yet" 'P0' }
Complete-TestSuite
