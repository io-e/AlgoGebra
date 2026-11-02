# Windows implementation of PR #8 launch course contract (Codex handoff).
[CmdletBinding()]
param([string]$Launcher = (Join-Path $PSScriptRoot '..\launch.ps1'))

$ErrorActionPreference = 'Stop'
$passes = 0
$failures = 0
$skips = 0
$spikeRoot = Split-Path $PSScriptRoot -Parent
$fixture = Join-Path $PSScriptRoot 'fixtures\course-tree-trig-smoke.json'
$Launcher = (Resolve-Path -LiteralPath $Launcher).ProviderPath
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) "GeoGebraPlus-CourseLauncher-$([guid]::NewGuid().ToString('N'))"
$previousDryRun = $env:GGBPLUS_LAUNCH_DRYRUN
$previousCourse = $env:GGBPLUS_COURSE
$previousCourseRoot = $env:GGBPLUS_COURSE_ROOT

function Assert-Case([string]$Name, [bool]$Condition, [string]$Detail) {
    if ($Condition) {
        $script:passes++
        Write-Output "PASS: $Name"
    } else {
        $script:failures++
        Write-Output "FAIL: $Name — $Detail"
    }
}

function Invoke-Launcher([string[]]$Arguments) {
    Push-Location $script:spikeRoot
    try {
        $lines = & pwsh -NoProfile -File $script:Launcher @Arguments 2>&1
        $code = $LASTEXITCODE
        return [pscustomobject]@{ ExitCode = $code; Output = ($lines | Out-String) }
    } finally {
        Pop-Location
    }
}

try {
    $env:GGBPLUS_LAUNCH_DRYRUN = '1'
    $env:GGBPLUS_COURSE = $null
    $env:GGBPLUS_COURSE_ROOT = $null
    $assetsReady = (Test-Path (Join-Path $spikeRoot 'bundles')) -and
        (Test-Path (Join-Path $spikeRoot 'launcher')) -and
        (Test-Path (Join-Path $spikeRoot 'natives')) -and
        (Test-Path $fixture) -and (Test-Path $Launcher)
    if (-not $assetsReady -or -not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        $skips++
        Write-Output 'SKIP: launch dry-run needs staged RCP jars, pwsh, and the course fixture.'
    } else {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $spaceDir = Join-Path $tempRoot 'course folder with spaces'
        New-Item -ItemType Directory -Path $spaceDir | Out-Null
        $spaceCourse = Join-Path $spaceDir 'course fixture.json'
        Copy-Item -LiteralPath $fixture -Destination $spaceCourse
        $badExtension = Join-Path $tempRoot 'not-a-course.txt'
        Set-Content -LiteralPath $badExtension -Value 'not json' -Encoding UTF8
        $oversize = Join-Path $tempRoot 'oversize.json'
        [IO.File]::WriteAllBytes($oversize, [byte[]]::new(1MB + 1))
        $directoryJson = Join-Path $tempRoot 'directory.json'
        New-Item -ItemType Directory -Path $directoryJson | Out-Null
        $outsideRoot = Join-Path $tempRoot 'outside-root'
        New-Item -ItemType Directory -Path $outsideRoot | Out-Null

        $result = Invoke-Launcher @('-NoBuild', '-Headless')
        Assert-Case 'no course keeps course property absent' ($result.ExitCode -eq 0 -and $result.Output -notmatch '-Dggbplus\.course=') $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', 'tests\fixtures\course-tree-trig-smoke.json')
        Assert-Case 'relative -Course resolves to absolute path' ($result.ExitCode -eq 0 -and $result.Output -match [regex]::Escape("-Dggbplus.course=$fixture")) $result.Output

        $result = Invoke-Launcher @('-NoBuild', "--course=$fixture")
        Assert-Case '--course=<absolute-path> alias' ($result.ExitCode -eq 0 -and $result.Output -match [regex]::Escape("-Dggbplus.course=$fixture")) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', $spaceCourse)
        Assert-Case 'path with spaces remains one Java property argument' ($result.ExitCode -eq 0 -and $result.Output -match [regex]::Escape("-Dggbplus.course=$spaceCourse")) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course')
        Assert-Case 'missing -Course value returns 64' ($result.ExitCode -eq 64) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', $fixture, '-Course', $fixture)
        Assert-Case 'repeated -Course returns 64' ($result.ExitCode -eq 64) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', (Join-Path $tempRoot 'missing.json'))
        Assert-Case 'missing course returns 66' ($result.ExitCode -eq 66) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', $directoryJson)
        Assert-Case 'directory course path returns 66' ($result.ExitCode -eq 66) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', $badExtension)
        Assert-Case 'non-JSON extension returns 65' ($result.ExitCode -eq 65) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', $oversize)
        Assert-Case 'course above 1 MiB returns 65' ($result.ExitCode -eq 65) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Course', 'https://example.org/course.json')
        Assert-Case 'remote URL returns 64' ($result.ExitCode -eq 64) $result.Output

        $env:GGBPLUS_COURSE_ROOT = $outsideRoot
        $result = Invoke-Launcher @('-NoBuild', '-Course', $spaceCourse)
        Assert-Case 'course outside configured root returns 77' ($result.ExitCode -eq 77) $result.Output

        $env:GGBPLUS_COURSE_ROOT = $spaceDir
        $result = Invoke-Launcher @('-NoBuild', '-Course', $spaceCourse)
        Assert-Case 'course inside configured root is accepted' ($result.ExitCode -eq 0) $result.Output

        $env:GGBPLUS_COURSE_ROOT = $null
        $env:GGBPLUS_COURSE = $fixture
        $result = Invoke-Launcher @('-NoBuild')
        Assert-Case 'GGBPLUS_COURSE environment fallback' ($result.ExitCode -eq 0 -and $result.Output -match [regex]::Escape("-Dggbplus.course=$fixture")) $result.Output

        $env:GGBPLUS_COURSE = Join-Path $tempRoot 'missing-env.json'
        $result = Invoke-Launcher @('-NoBuild', '-Course', $fixture)
        Assert-Case '-Course flag takes precedence over environment fallback' ($result.ExitCode -eq 0 -and $result.Output -match [regex]::Escape("-Dggbplus.course=$fixture")) $result.Output

        $result = Invoke-Launcher @('-NoBuild', '-Headless', '-Course', $fixture)
        $firstOrder = $result.ExitCode -eq 0 -and $result.Output -match 'ggbplus\.headless=true' -and $result.Output -match [regex]::Escape("-Dggbplus.course=$fixture")
        $result2 = Invoke-Launcher @('-NoBuild', '-Course', $fixture, '-Headless')
        $secondOrder = $result2.ExitCode -eq 0 -and $result2.Output -match 'ggbplus\.headless=true' -and $result2.Output -match [regex]::Escape("-Dggbplus.course=$fixture")
        Assert-Case 'Headless and Course can appear in either order' ($firstOrder -and $secondOrder) ($result.Output + $result2.Output)
    }
} finally {
    $env:GGBPLUS_LAUNCH_DRYRUN = $previousDryRun
    $env:GGBPLUS_COURSE = $previousCourse
    $env:GGBPLUS_COURSE_ROOT = $previousCourseRoot
    if (Test-Path -LiteralPath $tempRoot) {
        $tempFull = [IO.Path]::GetFullPath($tempRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
        $safeBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
        if (-not $tempFull.StartsWith($safeBase, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to delete temporary test data outside temp: $tempFull"
        }
        Remove-Item -LiteralPath $tempFull -Recurse -Force
    }
}

Write-Output "PASS: $passes FAIL: $failures SKIP: $skips"
if ($failures -gt 0) { exit 1 }
if ($skips -gt 0 -and $passes -eq 0) { exit 2 }
