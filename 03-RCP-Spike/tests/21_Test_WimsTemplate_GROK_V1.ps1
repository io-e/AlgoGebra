# GROK_V1 - G-14 WIMS course activity template (WP7-01), static contract checks. Decision D-S01 (02-Cdc/Decision_Open_Points_Sprint3_CLAUDE_V1.md).
# Runs everywhere (no browser); the browser cycle is G-16 (23_Test_WimsFullCycle_GROK_V1.ps1).
. (Join-Path $PSScriptRoot 'lib/TestFramework_GROK_V1.ps1')
Initialize-TestSuite '21_WimsTemplate'
$repo = Split-Path $script:SpikeDir -Parent
$dir = Join-Path $repo 'wims/course-activity-template'
$page = Join-Path $dir 'course-activity_GROK_V1.html'; $readme = Join-Path $dir 'README_GROK_V1.md'
Test-Ok 'WT-01-template-exists' (Test-Path $page) "$page" 'P0'
Test-Ok 'WT-02-readme-exists' (Test-Path $readme) "$readme" 'P1'
$h = if (Test-Path $page) { Get-Content $page -Raw } else { '' }; $r = if (Test-Path $readme) { Get-Content $readme -Raw } else { '' }
Test-Ok 'WT-03-reuses-web-host' ($h -match 'src="course-tree\.js"' -and $h -match 'href="course-tree\.css"' -and $h -match 'id="tree-root"[^>]*role="tree"') 'course-tree.js/.css + role=tree tree root' 'P0'
Test-Ok 'WT-04-grade-client-script' ($h -match 'src="wims-grade-client_GROK_V1\.js"') 'includes the G-15 grade client' 'P0'
Test-Ok 'WT-05-placeholders' ($h -match '\{\{WIMS_CGI_URL\}\}' -and $h -match '\{\{WIMS_EXERCISE_ID\}\}' -and $h -match '\{\{COURSE_JSON_URL\}\}') 'WIMS_CGI_URL / WIMS_EXERCISE_ID / COURSE_JSON_URL placeholders' 'P0'
Test-Ok 'WT-06-default-endpoint-D-S01' ($h -match "'/wims/wims\.cgi'") 'default endpoint /wims/wims.cgi (D-S01)' 'P0'
Test-Ok 'WT-07-local-codebase' ($h -match "html5codebase'\s*:\s*'GeoGebra/web3d/'" -and $h -notmatch 'geogebra\.org') 'self-hosted WAR, no geogebra.org' 'P0'
$ext = [regex]::Matches($h, '(?:src|href)="(https?:)?//[^"]+"').Count
Test-Ok 'WT-08-no-external-assets' ($ext -eq 0) "external src/href count: $ext" 'P0'
$inj = [regex]::Matches($h, 'applet\.inject').Count
Test-Ok 'WT-09-single-inject' ($inj -eq 1) "applet.inject count: $inj" 'P0'
Test-Ok 'WT-10-submit-a11y' ($h -match 'id="btn-wims-submit"[^>]*disabled[^>]*aria-label=' -and $h -match 'id="wims-result"[^>]*aria-live="polite"') 'submit button disabled until attached, aria-label; result region aria-live' 'P1'
Test-Ok 'WT-11-formative-note' ($h -match 'formative only' -and $h -match 'recorded by WIMS') 'page states WIMS owns the grade' 'P1'
Test-Ok 'WT-12-no-local-grade' ($h -notmatch '(?i)grade\s*=\s*[0-9]|computeGrade') 'template computes no grade' 'P0'
Test-Ok 'WT-13-readme-contract' ($r -match 'module=adm/class/sheet&job=getresult&exercise=<id>&ans1=<construction_base64>' -and $r -match 'D-S01') 'README documents the D-S01 request verbatim' 'P1'
Test-Ok 'WT-14-readme-open-points' ($r -match '(?i)session' -and $r -match '(?i)HTML' -and $r -match '(?i)CORS') 'README lists undecided points (session, HTML response, CORS)' 'P1'
Complete-TestSuite
