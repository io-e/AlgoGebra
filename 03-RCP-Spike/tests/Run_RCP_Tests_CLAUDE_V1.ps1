# CLAUDE_V1 — Hybrid RCP test orchestrator: SWTBot (JUnit/Tycho) + RCPTT (AUT CLI)
# Integrates with Run_All_GROK_V1.ps1 via TAP output, per-suite CSV, evidence export.
# See: 02-Cdc/Plan_RCP_Testing_SWTBot_RCPTT_CLAUDE_V1.md
#
# Usage:
#   pwsh -File Run_RCP_Tests_CLAUDE_V1.ps1 -Phase SWTBot     # JUnit only
#   pwsh -File Run_RCP_Tests_CLAUDE_V1.ps1 -Phase RCPTT      # E2E only
#   pwsh -File Run_RCP_Tests_CLAUDE_V1.ps1 -Phase All         # both sequential
#   pwsh -File Run_RCP_Tests_CLAUDE_V1.ps1 -Phase All -DryRun # validate setup only
param(
    [ValidateSet('SWTBot', 'RCPTT', 'All')]
    [string]$Phase = 'All',
    [string]$Image,
    [string]$RcpttRunner,
    [string]$MavenProject,
    [switch]$DryRun,
    [int]$TimeoutSec = 600
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

$here = $PSScriptRoot
$spikeDir = Split-Path $here -Parent
$repoRoot = Split-Path $spikeDir -Parent

# Reuse framework for TAP output
. (Join-Path $here 'lib/TestFramework_GROK_V1.ps1')

$runId = "rcp-$(Get-Date -Format 'yyyyMMdd_HHmmss')-$([Environment]::MachineName)"
$resDir = if ($env:RESULTS_DIR) { $env:RESULTS_DIR } else { Join-Path $here "results/$runId" }
New-Item -ItemType Directory -Force $resDir | Out-Null
$env:RESULTS_DIR = $resDir

# --- Defaults ---
if (-not $Image) {
    $Image = if ($IsWindows) {
        'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r8'
    } else {
        '/workspace/AlgoGebra/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64'
    }
}
if (-not $RcpttRunner) {
    $RcpttRunner = if ($IsWindows) {
        Join-Path $spikeDir 'tools/rcptt-runner/rcptt.runner.exe'
    } else {
        Join-Path $spikeDir 'tools/rcptt-runner/rcptt.runner'
    }
}
if (-not $MavenProject) {
    $MavenProject = Join-Path $spikeDir 'host/tests/org.geogebraplus.tests.swtbot'
}

$javaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } elseif ($IsWindows) {
    'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
} else {
    (Get-ChildItem '/workspace/AlgoGebra/jdk' -Directory -Filter 'jdk-21*' -ErrorAction SilentlyContinue |
        Select-Object -First 1).FullName
}

$commit = (& git -C $repoRoot rev-parse --short HEAD 2>$null)
Write-Host "# RCP Test Orchestrator — CLAUDE_V1"
Write-Host "# run: $runId"
Write-Host "# commit: $commit"
Write-Host "# image: $Image"
Write-Host "# phase: $Phase"
Write-Host "# java: $javaHome"

# ============================================================
# Phase 1: SWTBot (JUnit via Maven/Tycho)
# ============================================================
function Invoke-SWTBot {
    Initialize-TestSuite 'RCP-SWTBot'
    Write-Host "`n# === Phase 1: SWTBot (JUnit/Tycho) ==="

    # Prerequisite checks
    $mvnCmd = if ($IsWindows) { 'mvn.cmd' } else { 'mvn' }
    $hasMaven = $null -ne (Get-Command $mvnCmd -ErrorAction SilentlyContinue)
    $hasPom = Test-Path (Join-Path $MavenProject 'pom.xml')

    Test-Ok 'SWTBOT-PRE-01' $hasMaven "Maven available: $hasMaven" 'P0'
    Test-Ok 'SWTBOT-PRE-02' $hasPom "SWTBot pom.xml exists: $MavenProject" 'P0'
    Test-Ok 'SWTBOT-PRE-03' (Test-Path $Image) "RCP image exists: $Image" 'P0'

    if (-not $hasMaven -or -not $hasPom) {
        Skip-Test 'SWTBOT-RUN' 'Prerequisites not met (Maven or pom.xml missing)' 'P0'
        Complete-TestSuite
        return $false
    }

    if ($DryRun) {
        Skip-Test 'SWTBOT-RUN' 'DryRun mode — skipping execution' 'P1'
        Complete-TestSuite
        return $true
    }

    # Run SWTBot tests via Tycho
    $swtbotLog = Join-Path $resDir 'swtbot-maven.log'
    $swtbotResultDir = Join-Path $resDir 'swtbot'
    New-Item -ItemType Directory -Force $swtbotResultDir | Out-Null

    $mvnArgs = @(
        'verify',
        "-pl", "org.geogebraplus.tests.swtbot",
        "-Dproduct.image=$Image",
        "-DfailIfNoTests=false",
        "-DforkCount=1",
        "-Dosgi.locking=none"
    )

    Write-Host "# Running: $mvnCmd $($mvnArgs -join ' ')"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process $mvnCmd -ArgumentList $mvnArgs -WorkingDirectory (Split-Path $MavenProject -Parent) `
        -RedirectStandardOutput $swtbotLog -RedirectStandardError "$swtbotLog.err" -PassThru -WindowStyle Hidden
    $exited = $proc.WaitForExit($TimeoutSec * 1000)
    $elapsed = [int]$sw.Elapsed.TotalSeconds

    if (-not $exited) {
        try { $proc.Kill() } catch {}
        Test-Ok 'SWTBOT-RUN' $false "Timed out after ${TimeoutSec}s" 'P0'
        Complete-TestSuite
        return $false
    }

    $mvnRc = $proc.ExitCode
    Test-Ok 'SWTBOT-RUN' ($mvnRc -eq 0) "Maven exit=$mvnRc elapsed=${elapsed}s log=$swtbotLog" 'P0'

    # Parse JUnit XML results if they exist
    $junitXmlDir = Join-Path $MavenProject 'target/surefire-reports'
    if (Test-Path $junitXmlDir) {
        $xmlFiles = Get-ChildItem $junitXmlDir -Filter 'TEST-*.xml'
        foreach ($xf in $xmlFiles) {
            $parsed = ConvertFrom-JUnitXml $xf.FullName
            foreach ($tc in $parsed) {
                $id = "SWTBOT-$($tc.Class)-$($tc.Name)"
                Test-Ok $id $tc.Pass "$($tc.Class).$($tc.Name): $($tc.Message)" 'P0'
            }
        }
        Copy-Item $junitXmlDir "$swtbotResultDir/surefire-reports" -Recurse -ErrorAction SilentlyContinue
    }

    Complete-TestSuite
    return ($mvnRc -eq 0)
}

# ============================================================
# Phase 2: RCPTT (AUT CLI)
# ============================================================
function Invoke-RCPTT {
    Initialize-TestSuite 'RCP-RCPTT'
    Write-Host "`n# === Phase 2: RCPTT (Application Under Test) ==="

    $rcpttTestDir = Join-Path $here 'rcptt'
    $hasRunner = Test-Path $RcpttRunner
    $hasTests = Test-Path $rcpttTestDir

    Test-Ok 'RCPTT-PRE-01' $hasRunner "RCPTT runner exists: $RcpttRunner" 'P0'
    Test-Ok 'RCPTT-PRE-02' $hasTests "RCPTT test dir exists: $rcpttTestDir" 'P0'
    Test-Ok 'RCPTT-PRE-03' (Test-Path $Image) "RCP image exists: $Image" 'P0'

    if (-not $hasRunner -or -not $hasTests) {
        Skip-Test 'RCPTT-RUN' 'Prerequisites not met (runner or tests missing)' 'P0'
        Complete-TestSuite
        return $false
    }

    if ($DryRun) {
        Skip-Test 'RCPTT-RUN' 'DryRun mode — skipping execution' 'P1'
        Complete-TestSuite
        return $true
    }

    # Run RCPTT
    $rcpttResultDir = Join-Path $resDir 'rcptt'
    New-Item -ItemType Directory -Force $rcpttResultDir | Out-Null
    $rcpttLog = Join-Path $resDir 'rcptt-runner.log'

    $rcpttArgs = @(
        '-autWsPrefix', (Join-Path $env:TEMP "rcptt-ws-$PID"),
        '-aut', $Image,
        '-autConsolePrefix', (Join-Path $rcpttResultDir 'aut-console'),
        '-import', $rcpttTestDir,
        '-report', $rcpttResultDir
    )

    # Add course flag for D-11 tests
    $courseFile = Join-Path $repoRoot 'courses/trigonometry_intro.json'
    if (Test-Path $courseFile) {
        $rcpttArgs += @('-autArgs', "-Dggbplus.course=$courseFile")
    }

    Write-Host "# Running: $RcpttRunner $($rcpttArgs -join ' ')"
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process $RcpttRunner -ArgumentList $rcpttArgs `
        -RedirectStandardOutput $rcpttLog -RedirectStandardError "$rcpttLog.err" -PassThru -WindowStyle Hidden
    $exited = $proc.WaitForExit($TimeoutSec * 1000)
    $elapsed = [int]$sw.Elapsed.TotalSeconds

    if (-not $exited) {
        try { $proc.Kill() } catch {}
        Test-Ok 'RCPTT-RUN' $false "Timed out after ${TimeoutSec}s" 'P0'
        Complete-TestSuite
        return $false
    }

    $rcpttRc = $proc.ExitCode
    Test-Ok 'RCPTT-RUN' ($rcpttRc -eq 0) "RCPTT exit=$rcpttRc elapsed=${elapsed}s log=$rcpttLog" 'P0'

    # Parse RCPTT report XML
    $reportXml = Join-Path $rcpttResultDir 'results.xml'
    if (Test-Path $reportXml) {
        $parsed = ConvertFrom-RcpttXml $reportXml
        foreach ($tc in $parsed) {
            $id = "RCPTT-$($tc.Name)"
            Test-Ok $id $tc.Pass "$($tc.Name): $($tc.Message)" 'P0'
        }
    }

    Complete-TestSuite
    return ($rcpttRc -eq 0)
}

# ============================================================
# XML parsers
# ============================================================
function ConvertFrom-JUnitXml([string]$Path) {
    $results = @()
    try {
        [xml]$doc = Get-Content $Path -Raw
        foreach ($tc in $doc.testsuite.testcase) {
            $pass = $true; $msg = 'PASS'
            if ($tc.failure) { $pass = $false; $msg = $tc.failure.message }
            elseif ($tc.error) { $pass = $false; $msg = $tc.error.message }
            elseif ($tc.skipped) { $msg = 'SKIPPED' }
            $results += [pscustomobject]@{
                Class   = $tc.classname
                Name    = $tc.name
                Pass    = $pass
                Message = ($msg -replace "`r?`n", ' ').Substring(0, [Math]::Min($msg.Length, 200))
            }
        }
    } catch {
        $results += [pscustomobject]@{ Class = 'parse'; Name = 'error'; Pass = $false; Message = $_.Exception.Message }
    }
    return $results
}

function ConvertFrom-RcpttXml([string]$Path) {
    $results = @()
    try {
        [xml]$doc = Get-Content $Path -Raw
        $tests = $doc.SelectNodes('//testcase')
        if (-not $tests) { $tests = $doc.SelectNodes('//*[local-name()="testcase"]') }
        foreach ($tc in $tests) {
            $pass = $true; $msg = 'PASS'
            if ($tc.failure) { $pass = $false; $msg = $tc.failure.'#text' ?? $tc.failure.message ?? 'FAIL' }
            elseif ($tc.error) { $pass = $false; $msg = $tc.error.'#text' ?? $tc.error.message ?? 'ERROR' }
            $results += [pscustomobject]@{
                Name    = $tc.name ?? $tc.GetAttribute('name')
                Pass    = $pass
                Message = ($msg -replace "`r?`n", ' ').Substring(0, [Math]::Min($msg.Length, 200))
            }
        }
    } catch {
        $results += [pscustomobject]@{ Name = 'parse-error'; Pass = $false; Message = $_.Exception.Message }
    }
    return $results
}

# ============================================================
# Main
# ============================================================
$swtbotOk = $true; $rcpttOk = $true

if ($Phase -in 'SWTBot', 'All') {
    $swtbotOk = Invoke-SWTBot
}

if ($Phase -in 'RCPTT', 'All') {
    if ($Phase -eq 'All' -and -not $swtbotOk) {
        Write-Warning "SWTBot failed — skipping RCPTT (use -Phase RCPTT to run independently)"
    } else {
        $rcpttOk = Invoke-RCPTT
    }
}

# Summary
Write-Host "`n# === RCP Test Summary ==="
Write-Host "# SWTBot: $(if ($Phase -in 'SWTBot','All') { if ($swtbotOk) { 'PASS' } else { 'FAIL' } } else { 'SKIPPED' })"
Write-Host "# RCPTT:  $(if ($Phase -in 'RCPTT','All') { if ($rcpttOk) { 'PASS' } else { 'FAIL' } } else { 'SKIPPED' })"
Write-Host "# Results: $resDir"

exit $(if ($swtbotOk -and $rcpttOk) { 0 } else { 1 })
