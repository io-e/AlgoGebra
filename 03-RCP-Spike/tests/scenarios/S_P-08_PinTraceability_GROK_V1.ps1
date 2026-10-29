# GROK_V1 - P-08 Upstream version and pin. Pass (spec): each report cites the commit and the tag.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_P-08'; Write-ScenarioHeader 'P-08' 'Upstream version and pin' '-' 'infra'
if ((Test-Path $script:GgbSource) -and (& git -C $script:GgbSource rev-parse --git-dir 2>$null)) { $head = (& git -C $script:GgbSource rev-parse HEAD 2>&1).Trim(); $dirty = @(& git -C $script:GgbSource status --porcelain 2>&1 | Where-Object { $_ -notmatch '^\?\?' }).Count
  Test-Ok 'P08-01-source-at-pin' ($head -eq $script:Pin) "source HEAD=$head pin=$script:Pin" 'P0'
  Test-Ok 'P08-02-source-common-unmodified' ($dirty -eq 0) "tracked modifications in upstream source: $dirty" 'P0' } else { Skip-Blocked 'P08-01-source-at-pin' "upstream source not found at $script:GgbSource (set GGB_SOURCE)" 'P0' }
$vs = Get-ChildItem (Join-Path $script:Image 'bundles') -Filter 'org.geogebra.migration.shared.common-*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
Test-Ok 'P08-03-image-version-string' ($vs -and $vs.Name -match [regex]::Escape($script:PinVersion)) "common bundle=$($vs.Name) expected VERSION_STRING=$script:PinVersion" 'P0'
$st = Get-Content (Join-Path $script:Repo 'states.yaml') -Raw
Test-Ok 'P08-04-states-cites-pin' ($st -match $script:Pin -and $st -match [regex]::Escape($script:PinVersion)) 'states.yaml cites commit and VERSION_STRING' 'P1'
$ev = Get-ChildItem (Join-Path $script:SpikeDir 'evidence') -Directory -ErrorAction SilentlyContinue
$noPin = @($ev | Where-Object { -not (Select-String -Path (Join-Path $_.FullName '*') -Pattern $script:Pin -SimpleMatch -List -ErrorAction SilentlyContinue) } | ForEach-Object Name)
Test-Ok 'P08-05-evidence-cites-pin' ($noPin.Count -eq 0) "evidence runs=$($ev.Count) without pin: [$($noPin -join ', ')]" 'P1'
Skip-Blocked 'P08-06-acceptance-tag' 'owner decision: the upstream acceptance tag is not chosen yet (commit pin known, tag open)' 'P0'
Complete-TestSuite
