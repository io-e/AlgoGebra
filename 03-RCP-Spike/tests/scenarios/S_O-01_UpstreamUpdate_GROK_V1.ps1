# GROK_V1 - O-01 Newer upstream commit, still no edit in common. Pass (spec): adapter-only diff, or a written refusal.
# Checks at the pin: product repo carries no copy/patch of upstream common; upstream tree clean. With GGB_NEXT_COMMIT set
# (a newer upstream commit already fetched in GGB_SOURCE), lists the files changed upstream that the adapters touch.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_O-01'; Write-ScenarioHeader 'O-01' 'Newer upstream commit, no edit in common' '-' 'infra'
$copies = @(Get-ChildItem $script:Repo -Recurse -Filter *.java -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '[\\/](geogebra|\.git|build)[\\/]' } | Select-String -Pattern '^package org\.geogebra\.common\.' -List)
Test-Ok 'O01-01-no-patched-common-class-in-product' ($copies.Count -eq 0) "product sources declaring org.geogebra.common.*: $(($copies | ForEach-Object Path) -join ', ')" 'P0'
if ((Test-Path $script:GgbSource) -and (& git -C $script:GgbSource rev-parse --git-dir 2>$null)) {
  $d = @(& git -C $script:GgbSource status --porcelain -- shared/common 2>&1 | Where-Object { $_ -notmatch "^\?\?" })
  Test-Ok 'O01-02-upstream-common-clean' ($d.Count -eq 0) "tracked modifications in shared/common (untracked build output ignored): $($d.Count)" 'P0'
  if ($env:GGB_NEXT_COMMIT) { $ch = @(& git -C $script:GgbSource diff --name-only $script:Pin $env:GGB_NEXT_COMMIT -- shared/common/src/main/java/org/geogebra/common/plugin shared/common/src/main/java/org/geogebra/common/main 2>&1)
    Test-Ok 'O01-03-next-commit-adapter-surface' $true "$script:Pin..$($env:GGB_NEXT_COMMIT): $($ch.Count) changed files on the GgbAPI/App surface used by the host" 'P1'
    Skip-Blocked 'O01-04-rebuild-on-next-commit' 'rebuild + D-02..D-05 + P-02 on the newer commit not automated yet (needs bundle regeneration, 02-Cdc/Bnd_Equinox_Resolution_Win64)' 'P0' }
  else { Skip-Blocked 'O01-03-next-commit' 'no newer upstream commit selected (set GGB_NEXT_COMMIT after fetching it into GGB_SOURCE)' 'P0' }
} else { Skip-Blocked 'O01-02-upstream-common-clean' "upstream source not found at $script:GgbSource" 'P0' }
Complete-TestSuite
