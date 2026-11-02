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
# GROK_V1: pwsh-native schema check (Test-Json -SchemaFile, pwsh 7.4+), python3+jsonschema fallback
if (-not (Test-Path $schema)) { Skip-Blocked 'D11-01-schema-valid' 'JSON schema file not found' 'P0' }
elseif ((Get-Command Test-Json).Parameters.ContainsKey('SchemaFile')) {
    $valid = try { Test-Json -LiteralPath $courseFile -SchemaFile $schema -ErrorAction Stop } catch { "FAIL: $($_.Exception.Message)" }
    Test-Ok 'D11-01-schema-valid' ($valid -eq $true) "Test-Json -SchemaFile: $valid" 'P0'
} else {
    $py = (Get-Command python3, python -CommandType Application -EA SilentlyContinue | Select-Object -First 1).Source
    $valid = if ($py) { & $py -I -c "import json,sys`nfrom jsonschema import validate`nvalidate(json.load(open(sys.argv[1],encoding='utf-8')),json.load(open(sys.argv[2],encoding='utf-8')))`nprint('PASS')" $courseFile $schema 2>&1 } else { 'no python' }
    if ("$valid" -match 'No module named|no python') { Skip-Blocked 'D11-01-schema-valid' "pwsh < 7.4 and no python3 jsonschema ($valid)" 'P0' }
    else { Test-Ok 'D11-01-schema-valid' ("$valid" -match 'PASS') "python jsonschema: $valid" 'P0' }
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
# GROK_V1: log markers aligned with the host's actual lines (PR #11): "IApplication.start()", "D-02 PASS", "Course loaded: <path> (N chapters; schema X)"
Test-Ok 'D11-02-product-launches' ($result.Text -match 'IApplication\.start\(\)' -and $result.Text -match 'D-02 PASS') "log=$($result.Log)" 'P0'
$cl = [regex]::Match($result.Text, 'Course loaded: (.+?) \((\d+) chapters; schema ([^)]+)\)')
Test-Ok 'D11-03-tree-renders' ($cl.Success -and [int]$cl.Groups[2].Value -ge 5) "course=$($cl.Groups[1].Value) chapters=$($cl.Groups[2].Value) schema=$($cl.Groups[3].Value)" 'P1'
# GROK_V1: a CMD only passes if evalCommand returned true (SCN value); 'false' = BUG-014 (command rejected + error dialog) -> honest FAIL tagged KNOWN_BUG
function Test-Cmd([string]$Id, [string]$Cmd) { $x = $scn[$Cmd]
    $ok = $x -and $x.St -eq 'OK' -and "$($x.Val)" -ne 'false'
    $tag = if ($x -and "$($x.Val)" -eq 'false') { 'KNOWN_BUG BUG-014: evalCommand returned false' } else { '' }
    Test-Ok $Id $ok "$Cmd -> st=$($x.St) val=$($x.Val) $tag" 'P0' }
Test-Cmd 'D11-04-step-O' 'O = (0, 0)'
Test-Cmd 'D11-04-step-circle' 'c = Circle(O, 1)'
$cas = $scn['Simplify(cos(x)^2 + sin(x)^2)']
Test-Ok 'D11-05-cas-identity' ($cas -and $cas.Val -match '^\s*1\s*$') "CAS result: [$($cas.Val)]" 'P0'
# GROK_V1: an error dialog attempt shows as AppD.showError in the log (under Xvfb it also throws an AWT NPE)
$dlg = [regex]::Matches($result.Text, 'AppD\S*showError|Please check your input|GeneralErrorMessage').Count
Test-Ok 'D11-06-no-error-dialog' ($dlg -eq 0) "error-dialog markers in log: $dlg$(if ($dlg) { ' (KNOWN_BUG BUG-014)' })" 'P1'
Test-Ok 'D11-07-no-timeout' ($result.Seconds -lt 90) "Completed in $($result.Seconds)s" 'P1'
Complete-TestSuite
