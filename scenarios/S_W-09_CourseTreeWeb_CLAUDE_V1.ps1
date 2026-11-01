# CLAUDE_V1 - W-09 Course tree renders in HTML tree (web). No gate. Pass (spec): tree renders
# in browser, steps execute via JS API, checks return pass/fail, security allowlist blocks Execute.
# Requires: self-hosted GWT WAR (PR #5), course-host.html + course-tree.js/css.
. (Join-Path $PSScriptRoot '../03-RCP-Spike/tests/scenarios/lib/Scenario_GROK_V1.ps1')
Initialize-TestSuite 'S_W-09'; Write-ScenarioHeader 'W-09' 'Course tree renders in HTML tree' '-' 'web'

$webHost = Join-Path (Split-Path $PSScriptRoot -Parent) 'web-host'
$courseHost = Join-Path $webHost 'course-host.html'
$courseJs = Join-Path $webHost 'course-tree.js'
$courseCss = Join-Path $webHost 'course-tree.css'
$courseFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'courses/trigonometry_intro.json'

# --- Pre-checks: files exist ---
Test-Ok 'W09-01-host-html' (Test-Path $courseHost) "course-host.html exists: $(Test-Path $courseHost)" 'P0'
Test-Ok 'W09-02-course-js' (Test-Path $courseJs) "course-tree.js exists: $(Test-Path $courseJs)" 'P0'
Test-Ok 'W09-03-course-css' (Test-Path $courseCss) "course-tree.css exists: $(Test-Path $courseCss)" 'P0'
Test-Ok 'W09-04-course-json' (Test-Path $courseFile) "trigonometry_intro.json exists: $(Test-Path $courseFile)" 'P0'

# --- Static analysis of course-tree.js ---
$jsContent = if (Test-Path $courseJs) { Get-Content $courseJs -Raw } else { '' }

# W09-05: security — BLOCKED_COMMANDS list present
Test-Ok 'W09-05-blocklist-present' ($jsContent -match 'BLOCKED_COMMANDS') "BLOCKED_COMMANDS array found in JS" 'P0'

# W09-06: blocked commands include Execute
Test-Ok 'W09-06-execute-blocked' ($jsContent -match "'Execute'") "Execute in BLOCKED_COMMANDS" 'P0'

# W09-07: setErrorDialogsActive called
Test-Ok 'W09-07-error-dialog-guard' ($jsContent -match 'setErrorDialogsActive\(false\)' -and $jsContent -match 'setErrorDialogsActive\(true\)') "setErrorDialogsActive(false/true) present" 'P0'

# W09-08: CAS readiness uses evalCommandCAS, not evalCommand
Test-Ok 'W09-08-cas-readiness' ($jsContent -match 'evalCommandCAS.*1\+1' -and $jsContent -notmatch 'evalCommand\s*\(\s*[''"]1\+1') "CAS readiness via evalCommandCAS only" 'P0'

# W09-09: html5codebase points to local WAR, not geogebra.org
$htmlContent = if (Test-Path $courseHost) { Get-Content $courseHost -Raw } else { '' }
Test-Ok 'W09-09-local-codebase' ($htmlContent -match 'html5codebase.*GeoGebra/HTML5' -and $htmlContent -notmatch 'geogebra\.org') "html5codebase is local, not geogebra.org" 'P0'

# W09-10: single applet injection (no duplicate)
$injectCount = ([regex]::Matches($htmlContent, 'applet\.inject')).Count
Test-Ok 'W09-10-single-inject' ($injectCount -eq 1) "applet.inject count: $injectCount (expected 1)" 'P0'

# W09-11: ARIA roles present
Test-Ok 'W09-11-aria-tree' ($htmlContent -match 'role="tree"') "role=tree in HTML" 'P0'
Test-Ok 'W09-11-aria-label' ($htmlContent -match 'aria-label') "aria-label present" 'P0'

# W09-12: mobile toggle button present
Test-Ok 'W09-12-mobile-toggle' ($htmlContent -match 'mobile-tree-toggle') "mobile toggle button in HTML" 'P0'

# W09-13: Sequence limit check in JS (V1_1 security fix)
Test-Ok 'W09-13-sequence-limit' ($jsContent -match 'MAX_SEQUENCE_ITER|Sequence.*limit|10000') "Sequence iteration limit enforced" 'P0'

# W09-14: OPEN path validation
Test-Ok 'W09-14-open-path-check' ($jsContent -match 'isOpenPathSafe' -and $jsContent -match 'PATH_REJECT_RE') "OPEN path validation present" 'P0'

# --- Browser test (requires Chrome/Firefox + server) ---
# These are deferred until the GWT WAR is deployed alongside the web-host files.
Skip-Blocked 'W09-20-browser-load' 'Requires self-hosted WAR + HTTP server; run manually or with Grok suite 15' 'P1'
Skip-Blocked 'W09-21-browser-tree' 'depends on W09-20' 'P1'
Skip-Blocked 'W09-22-browser-step' 'depends on W09-20' 'P1'
Skip-Blocked 'W09-23-browser-check' 'depends on W09-20' 'P1'

Complete-TestSuite
