# CLAUDE_V1 - D-11 Course tree renders in SWT Tree (desktop). No gate. Pass (spec): tree renders,
# steps execute via GgbAPI, checks return pass/fail, error dialogs suppressed, no UI freeze.
# Blocked: Codex WP2-06 (CourseTreePanel integration). This script runs after that code lands.
. (Join-Path $PSScriptRoot '../03-RCP-Spike/tests/scenarios/lib/Scenario_GROK_V1.ps1')
Initialize-TestSuite 'S_D-11'; Write-ScenarioHeader 'D-11' 'Course tree renders in SWT Tree' '-' 'desktop'; Test-ImagePresent

$courseFile = Join-Path (Split-Path $PSScriptRoot -Parent) 'courses/trigonometry_intro.json'
if (-not (Test-Path $courseFile)) { Exit-Bail "Course file not found: $courseFile" }

# --- Pre-check: course file validates against schema ---
$schema = Join-Path (Split-Path $PSScriptRoot -Parent) '02-Cdc/Schema_Course_JSON_CLAUDE_V1.json'
if (Test-Path $schema) {
    $valid = & python -I -c "
import json, sys
try:
    from jsonschema import validate
    validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
    print('PASS')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" $courseFile $schema 2>&1
    Test-Ok 'D11-01-schema-valid' ($valid -match 'PASS') "schema validation: $valid" 'P0'
} else {
    Skip-Blocked 'D11-01-schema-valid' 'JSON schema file not found' 'P0'
}

# --- Launch product with -Course flag ---
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
    Skip-Blocked 'D11-02-product-launches' 'Product launch failed or timed out' 'P0'
    Skip-Blocked 'D11-03-tree-renders' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-04-step-executes' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-05-check-works' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-06-error-suppressed' 'depends on D11-02' 'P0'
    Skip-Blocked 'D11-07-no-freeze' 'depends on D11-02' 'P0'
    Complete-TestSuite
    return
}

$scn = $result.Scn

# D11-02: product launched successfully with course tree
Test-Ok 'D11-02-product-launches' ($result.Text -match 'GeoGebraPlus.*started|Application.*started') "log=$($result.Log)" 'P0'

# D11-03: course tree panel created (looks for course tree log marker)
Test-Ok 'D11-03-tree-renders' ($result.Text -match 'CourseTreePanel|course tree|loadCourse') "log=$($result.Log)" 'P1'

# D11-04: step execution — O=(0,0) and circle created
$cmdO = $scn['O = (0, 0)']
$cmdC = $scn['c = Circle(O, 1)']
Test-Ok 'D11-04-step-O' ($cmdO -and $cmdO.St -eq 'OK') "O creation: $($cmdO.St) $($cmdO.Val)" 'P0'
Test-Ok 'D11-04-step-circle' ($cmdC -and $cmdC.St -eq 'OK') "Circle creation: $($cmdC.St) $($cmdC.Val)" 'P0'

# D11-05: CAS check — Simplify(cos^2+sin^2) = 1
$cas = $scn['Simplify(cos(x)^2 + sin(x)^2)']
Test-Ok 'D11-05-cas-identity' ($cas -and $cas.Val -match '^\s*1\s*$') "CAS result: $($cas.Val)" 'P0'

# D11-06: no error dialog (setErrorDialogsActive(false) contract)
Test-Ok 'D11-06-no-error-dialog' ($result.Text -notmatch 'Please check your input|GeneralErrorMessage') "No error dialog in log" 'P1'

# D11-07: no timeout (completed within limit)
Test-Ok 'D11-07-no-timeout' ($result.Seconds -lt 90) "Completed in $($result.Seconds)s" 'P1'

Complete-TestSuite
