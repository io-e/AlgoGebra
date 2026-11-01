# CLAUDE_V1 — Sync course-tree cheat sheets into T1 Eclipse plugin repo
# Copies D-11.xml and W-09.xml into the T1 repo and updates plugin.xml
[CmdletBinding()]
param(
    [string]$T1Repo = 'D:\ALF_ZGit\T1_Cheat_Sheets',
    [string]$SourceDir = (Join-Path $PSScriptRoot 'scenarios')
)
$ErrorActionPreference = 'Stop'

$newSheets = @(
    @{ Id = 'D-11'; Name = 'D-11 — Course tree renders in SWT Tree (desktop)'; File = 'D-11.xml' },
    @{ Id = 'W-09'; Name = 'W-09 — Course tree renders in HTML tree (web)'; File = 'W-09.xml' }
)

if (-not (Test-Path $T1Repo)) { throw "T1 repo not found: $T1Repo" }
if (-not (Test-Path $SourceDir)) { throw "Source dir not found: $SourceDir" }

$targets = @(
    (Join-Path $T1Repo 'cheatsheets\scenarios'),
    (Join-Path $T1Repo 'eclipse-plugin\cheatsheets\scenarios')
)

$copied = 0
foreach ($sheet in $newSheets) {
    $src = Join-Path $SourceDir $sheet.File
    if (-not (Test-Path $src)) { Write-Warning "Missing: $src"; continue }
    foreach ($tgt in $targets) {
        $dest = Join-Path $tgt $sheet.File
        Copy-Item -LiteralPath $src -Destination $dest -Force
        Write-Host "  Copied $($sheet.File) -> $dest"
    }
    $copied++
}

$pluginXml = Join-Path $T1Repo 'eclipse-plugin\plugin.xml'
$content = Get-Content -LiteralPath $pluginXml -Raw
$needsUpdate = $false
foreach ($sheet in $newSheets) {
    $entryId = "org.geogebra.plus.cheatsheets.$($sheet.Id)"
    if ($content -notmatch [regex]::Escape($entryId)) {
        $entry = "    <cheatsheet id=`"$entryId`" name=`"$($sheet.Name)`" category=`"org.geogebra.plus.cheatsheets.category`" contentFile=`"cheatsheets/scenarios/$($sheet.File)`"/>"
        $content = $content -replace '(</extension>)', "$entry`n  `$1"
        $needsUpdate = $true
        Write-Host "  Added plugin.xml entry: $($sheet.Id)"
    } else {
        Write-Host "  Already in plugin.xml: $($sheet.Id)"
    }
}

if ($needsUpdate) {
    [IO.File]::WriteAllText($pluginXml, $content, [Text.UTF8Encoding]::new($false))
    Write-Host "  Updated $pluginXml"
}

Write-Host "`nDone: $copied sheet(s) synced. Run T1's Install_CheatSheets.ps1 to rebuild the JAR."
