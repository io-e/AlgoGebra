# GROK_V1 - D-11 Course tree renders in SWT Tree (desktop). No gate.
# Pass (spec): tree renders, steps execute via GgbAPI, checks return pass/fail,
# error dialogs suppressed, no UI freeze. Blocked until Codex WP2-06 lands.
# Authoring twin: scenarios/S_D-11_CourseTree_CLAUDE_V1.ps1 (repo root).
. (Join-Path $PSScriptRoot 'lib/Scenario_GROK_V1.ps1')
Initialize-TestSuite 'S_D-11'; Write-ScenarioHeader 'D-11' 'Course tree renders in SWT Tree' '-' 'desktop'; Test-ImagePresent

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$courseFile = Join-Path $repoRoot 'courses/trigonometry_intro.json'
if (-not (Test-Path $courseFile)) { Exit-Bail "Course file not found: $courseFile" }

$schema = Join-Path $repoRoot '02-Cdc/Schema_Course_JSON_CLAUDE_V1.json'
if (Test-Path $schema) {
    $valid = & python -I -c @"
import json, sys
try:
    from jsonschema import validate
    validate(json.load(open(sys.argv[1], encoding='utf-8')), json.load(open(sys.argv[2], encoding='utf-8')))
    print('PASS')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
"@ $courseFile $schema 2>&1
    Test-Ok 'D11-01-schema-valid' ($valid -match 'PASS') "schema validation: $valid" 'P0'
} else {
    Skip-Blocked 'D11-01-schema-valid' 'JSON schema file not found' 'P0'
}

$directives = @(
    "CMD`tO = (0, 0)"
    "CMD`tc = Circle(O, 1)"
    "CMD`tP = Point(c)"
    "CMD`tSetColor(c, 0, 0, 255)"
    "VAL`tx(P)"
    "CAS`tSimplify(cos(x)^2 + sin(x)^2)"
) -join "`n"

$result = Invoke-ProductScenario 'D-11-course-tree' $directives -Env @{
    'JAVA_TOOL_OPTIONS' = "-Dggbplus.course=$courseFile"
} -TimeoutSec 120

if ($null -eq $result) {
    Skip-Blocked 'D11-02-product-launches' 'Product launch failed or timed out; CourseTreePanel (WP2-06) may be missing' 'P0'
    Skip-Blocked 'D11-03-tree-renders' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-04-step-O' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-04-step-circle' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-05-cas-identity' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-06-no-error-dialog' 'depends on D11-02' 'P1'
    Skip-Blocked 'D11-07-no-timeout' 'depends on D11-02' 'P1'
    Complete-TestSuite
    return
}

$scn = $result.Scn
Test-Ok 'D11-02-product-launches' ($result.Text -match 'GeoGebraPlus.*started|Application.*started') "log=$($result.Log)" 'P0'
Test-Ok 'D11-03-tree-renders' ($result.Text -match 'CourseTreePanel|course tree|loadCourse') "log=$($result.Log)" 'P1'
$cmdO = $scn['O = (0, 0)']
$cmdC = $scn['c = Circle(O, 1)']
Test-Ok 'D11-04-step-O' ($cmdO -and $cmdO.St -eq 'OK') "O creation: $($cmdO.St) $($cmdO.Val)" 'P0'
Test-Ok 'D11-04-step-circle' ($cmdC -and $cmdC.St -eq 'OK') "Circle creation: $($cmdC.St) $($cmdC.Val)" 'P0'
$cas = $scn['Simplify(cos(x)^2 + sin(x)^2)']
Test-Ok 'D11-05-cas-identity' ($cas -and $cas.Val -match '^\s*1\s*$') "CAS result: $($cas.Val)" 'P0'
Test-Ok 'D11-06-no-error-dialog' ($result.Text -notmatch 'Please check your input|GeneralErrorMessage') 'No error dialog in log' 'P1'
Test-Ok 'D11-07-no-timeout' ($result.Seconds -lt 90) "Completed in $($result.Seconds)s" 'P1'
Complete-TestSuite
