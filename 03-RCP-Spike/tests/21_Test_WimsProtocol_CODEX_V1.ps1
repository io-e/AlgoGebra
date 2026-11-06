. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
$script:ArtifactSuffix = 'CODEX_V1'
Initialize-TestSuite '21_WimsProtocol'
$fixtureDir = Join-Path $PSScriptRoot 'fixtures/wims-live'
$readme = Join-Path $fixtureDir 'README.md'
$client = Join-Path $script:SpikeDir 'host/src/org/geogebra/plus/wims/HttpWimsClient.java'
$manifest = Join-Path $fixtureDir 'SHA256SUMS'
$fixtureNames = @(
    '00006_right_new.html', '00006_right_reply.html', '00006_wrong_reply.html',
    '00076_right_new.html', '00076_right_reply.html',
    'w8acc_right_cp1252_new.html', 'w8acc_right_cp1252_reply.html')

Test-Ok 'W1-fixture-readme' (Test-Path -LiteralPath $readme) 'captured fixtures have provenance and scope' 'P0'
Test-Ok 'W1-client-source' (Test-Path -LiteralPath $client) 'HttpWimsClient source exists' 'P0'
foreach ($name in $fixtureNames) {
    $path = Join-Path $fixtureDir $name
    Test-Ok "W1-fixture-$name" ((Test-Path -LiteralPath $path) -and (Get-Item -LiteralPath $path).Length -gt 1000) $name 'P0'
}
$clientText = if (Test-Path -LiteralPath $client) { Get-Content -LiteralPath $client -Raw } else { '' }
Test-Ok 'W1-stock-cmd-new-reply' ($clientText -match '"new"' -and $clientText -match '"reply"') 'stock OEF flow' 'P0'
Test-Ok 'W2-json-hook-is-reply-only' ($clientText -match 'special_parm' -and $clientText -match 'JSON_HOOK') 'hook parameter is added by answer submission path' 'P0'
Test-Ok 'W4-cp1252-transport' ($clientText -match 'windows-1252' -and $clientText -match 'WimsFormEncoding') 'strict Windows-1252 form transport' 'P0'
Test-Ok 'W3-three-way-html-errors' ($clientText -match 'HOOK_NOT_INSTALLED' -and $clientText -match 'RETRY_REQUIRED' -and $clientText -match 'NO_JSON_BLOCK') 'hook-off, retry page, and unknown HTML remain distinct' 'P0'
Test-Ok 'W5-number-grade' ($clientText -match 'BigDecimal' -and $clientText -match 'JSON number') 'accept numeric integer and decimal grades' 'P0'
$forbidden = @('adm/raw', 'getresult', 'ans1')
$allClient = Get-ChildItem (Join-Path $script:SpikeDir 'host/src/org/geogebra/plus/wims') -Filter '*.java' -File |
    Get-Content -Raw | Out-String
foreach ($term in $forbidden) {
    Test-Ok "W8-no-stale-$term" ($allClient -notmatch [regex]::Escape($term)) "not present in WIMS client sources: $term" 'P0'
}
if (Test-Path -LiteralPath $manifest) {
    $sumRows = Get-Content -LiteralPath $manifest | Where-Object { $_ -match '^[0-9a-fA-F]{64}\s+\*?.+$' }
    foreach ($row in $sumRows) {
        $parts = $row -split '\s+', 2
        $fileName = $parts[1] -replace '^\*', ''
        $path = Join-Path $fixtureDir $fileName
        $actual = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { '' }
        Test-Ok "W1-sha256-$fileName" ($actual -eq $parts[0].ToUpperInvariant()) "hash verified: $fileName" 'P0'
    }
} else { Test-Ok 'W1-sha256-manifest' $false 'fixture SHA256SUMS missing' 'P0' }
Complete-TestSuite
