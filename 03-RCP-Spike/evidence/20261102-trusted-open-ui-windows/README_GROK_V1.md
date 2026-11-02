<!-- GROK_V1 -->
# Trusted OPEN SWT dialog — attended Windows check

| Field | Value |
|---|---|
| Date | 2026-11-02 (Europe/Paris) |
| Tip | feat/external-engines (host rebuilt from tip; CourseTreePanel present) |
| Note on r11 | Stock r11 image (2026-10-29) **predates** course UI; check run on tip `03-RCP-Spike` build + `launch.ps1 -Course` |
| Course | `C:\Users\Shadow\AppData\Local\Temp\trusted-open-ui-check\trusted_open_T33.json` (T-33 corpus; `trustedGgb: true` → `script_js.ggb`) |
| Log | `03-RCP-Spike/logs/rcp-20261102-200900-12032-8d2711e8.log` |
| Course SHA-256 | ec90c055f06a3855069cd0da0f702cde0d751c9df5a2caac6f87ed5abf05fe8c |

## Result: **PASS**

Owner confirmed the SWT `MessageBox` appears on **Run** of the trusted-OPEN step, with message starting `This course explicitly trusts...` (OK/Cancel; unscanned scripts warning). Course tree was visible; the `.ggb` name is shown in the dialog, not as a tree node.

## How to reproduce
```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
cd D:\ALF_Agents\G1_Geogebra_Migration\03-RCP-Spike
# prepare course dir with T-33 json + zipped script_js.ggb from fixtures/course-security/ggb-src
$env:GGBPLUS_COURSE_ROOT = '<course-dir>'
pwsh -File .\launch.ps1 -NoBuild -Course '<course-dir>\trusted_open_T33.json'
# Expand Ch → select Step → Run
```
