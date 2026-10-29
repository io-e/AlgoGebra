# GROK_V1 - O-03 Clean rebuild and hashes. Gate E. Pass (spec): SBOM matches the package.
# Writes an SBOM-like sha256 list of the image, rebuilds into a fresh folder (Linux build.sh with IMAGE override) and
# compares. Windows: build.ps1 rebuild is not run on the shared PC -> NOT RUN there.
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1'); Initialize-TestSuite 'S_O-03'; Write-ScenarioHeader 'O-03' 'Clean rebuild and hashes' 'E' 'desktop'; Test-ImagePresent
function Get-Sbom([string]$Root) { Get-ChildItem $Root -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](runtime-[^\\/]+|logs|workspace-[^\\/]+)[\\/]' } | ForEach-Object { "$((Get-FileHash $_.FullName).Hash.ToLower())  $([IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\', '/'))" } | Sort-Object { $_.Substring(66) } }
$s1 = @(Get-Sbom $script:Image); $sb = Join-Path $script:Res 'S_O-03_sbom.sha256'; Set-Content $sb $s1 -Encoding ascii
Test-Ok 'O03-01-sbom-written' ($s1.Count -gt 60) "files=$($s1.Count) sbom=$sb" 'P0'
$bi = Get-Content (Join-Path $script:Image 'configuration/org.eclipse.equinox.simpleconfigurator/bundles.info') | Where-Object { $_ -and -not $_.StartsWith('#') } | ForEach-Object { ($_ -split ',')[2] }
$missing = @($bi | Where-Object { -not (Test-Path (Join-Path $script:Image $_)) })
Test-Ok 'O03-02-bundles-info-matches-files' ($missing.Count -eq 0) "bundles.info entries=$($bi.Count) missing files=[$($missing -join ', ')]" 'P0'
if ($IsWindows) { Skip-Blocked 'O03-03-clean-rebuild-identical' 'clean rebuild with build.ps1 is not run on the shared Windows PC' 'P0' } else {
  $img2 = Join-Path $script:Tmp "grok-rebuild-$PID"; Remove-Item $img2 -Recurse -Force -ErrorAction SilentlyContinue
  $env:IMAGE = $img2; $out = & bash (Join-Path $script:SpikeDir 'build.sh') 2>&1; $rc = $LASTEXITCODE; Remove-Item Env:IMAGE
  Set-Content (Join-Path $script:Res 'S_O-03_rebuild.log') $out
  $s2 = @(Get-Sbom $img2); $d = @(Compare-Object $s1 $s2 | ForEach-Object { "$($_.SideIndicator) $($_.InputObject.Substring(66))" })
  $dn = @($d | ForEach-Object { $_.Substring(3) } | Select-Object -Unique)
  Set-Content (Join-Path $script:Res 'S_O-03_rebuild_diff.txt') $d
  Test-Ok 'O03-03-clean-rebuild-identical' ($rc -eq 0 -and $d.Count -eq 0) "rc=$rc differing files=$($dn.Count): $(($dn | Select-Object -First 8) -join ', ')" 'P0'
  Remove-Item $img2 -Recurse -Force -ErrorAction SilentlyContinue }
Skip-Blocked 'O03-04-standard-sbom' 'no CycloneDX/SPDX SBOM is produced by the build yet (sha256 list only)' 'P1'
Complete-TestSuite
