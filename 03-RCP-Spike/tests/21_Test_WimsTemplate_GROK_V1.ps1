# WA-9 - G-14 WIMS course activity template (WP7-01), static protocol contract checks.
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
Test-Ok 'WT-05-placeholders' ($h -match '\{\{WIMS_CGI_URL\}\}' -and $h -match '\{\{WIMS_MODULE_ID\}\}' -and $h -match '\{\{WIMS_EXO_ID\}\}' -and $h -match '\{\{COURSE_JSON_URL\}\}') 'CGI / OEF module / exercise / course URL placeholders' 'P0'
Test-Ok 'WT-06-default-endpoint' ($h -match "'/wims/wims\.cgi'") 'default endpoint /wims/wims.cgi' 'P0'
Test-Ok 'WT-07-local-codebase' ($h -match "html5codebase'\s*:\s*'GeoGebra/web3d/'" -and $h -notmatch 'geogebra\.org') 'self-hosted WAR, no geogebra.org' 'P0'
Test-Ok 'WT-16-local-tube-url' ($h -match "tubeurl'\s*:\s*'GeoGebra/'") 'GeoGebra material/tube API requests stay on the self-hosted origin' 'P0'
Test-Ok 'WT-17-self-origin-connections' ($h -match 'http-equiv="Content-Security-Policy"\s+content="connect-src ''self''"') 'browser connections are restricted to the activity origin' 'P0'
$ext = [regex]::Matches($h, '(?:src|href)="(https?:)?//[^"]+"').Count
Test-Ok 'WT-08-no-external-assets' ($ext -eq 0) "external src/href count: $ext" 'P0'
$inj = [regex]::Matches($h, 'applet\.inject').Count
Test-Ok 'WT-09-single-inject' ($inj -eq 1) "applet.inject count: $inj" 'P0'
Test-Ok 'WT-10-submit-a11y' ($h -match 'id="btn-wims-submit"[^>]*disabled[^>]*aria-label=' -and $h -match 'id="wims-result"[^>]*aria-live="polite"') 'submit button disabled until attached, aria-label; result region aria-live' 'P1'
Test-Ok 'WT-11-formative-note' ($h -match 'formative only' -and $h -match 'graded by WIMS') 'page states WIMS owns OEF grading' 'P1'
Test-Ok 'WT-12-no-local-grade' ($h -notmatch '(?i)grade\s*=\s*[0-9]|computeGrade') 'template computes no grade' 'P0'
Test-Ok 'WT-13-readme-contract' ($r -match 'cmd=new' -and $r -match 'cmd=reply' -and $r -match 'special_parm=algogebra_json' -and $r -match 'ALGOGEBRA_JSON_BEGIN') 'README documents the real OEF hook protocol' 'P0'
Test-Ok 'WT-14-readme-wire-fields' ($r -match 'replyN' -and $r -match 'choiceN' -and $r -notmatch 'job=getresult') 'README uses OEF reply/choice field names, not D-S01' 'P0'
Test-Ok 'WT-15-answer-provider-required' ($h -match 'GeoGebraWimsAnswerProvider' -and $r -match 'exercise-specific') 'exercise-specific answer mapping is explicit; no guessed construction conversion' 'P1'
Complete-TestSuite
