# Windows Gate A Desktop Corpus — P-02 to P-05

**Run date:** 2026-11-04 (Europe/Paris)  
**Host:** Shadow PC, Windows build 26100, PowerShell 7.6.9  
**Upstream pin:** `375db7faf5407390bb322165f2414415da8faeda` (`5.4.934.0`)  
**Product image:** `D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12`  
**Product Java:** Temurin 25.0.4.1+1-LTS; **test/build JDK:** Temurin 21.0.12.1+1-LTS.  
**Test scripts:** checkout `feat/d06-extension-mgmt` at base `9d67b57`; P-02..P-05 scripts were unmodified by the D-06 work.

## Results

| Scenario | PASS | FAIL | SKIP | Result details |
|---|---:|---:|---:|---|
| P-02 | 50 | 0 | 1 | Algebra, CAS, spreadsheet, 2D and 3D directives matched the pinned desktop baseline. The one skip is web/GWT parity. |
| P-03 | 3 | 0 | 2 | All 71 2D toolbar mode IDs matched. Skips: 3D toolbar comparison not automated; web parity deferred. |
| P-04 | 15 | 0 | 1 | Build/save/new/reopen/fresh-session and baseline reopen checks passed. One web skip. |
| P-05 | 7 | 0 | 5 | Script effects/values matched; PNG and SVG exports passed format/content checks. Four desktop automation gaps and web parity were skipped with reasons. |
| **Total** | **75** | **0** | **9** | Windows desktop portion only. |

The scenarios drove GeoGebra through the existing `ScenarioScript` API; no keyboard or mouse input was sent. Product and baseline windows were opened for the automated run and closed by the runners. Full per-scenario CSVs, directives, and logs are in this folder. No screenshot was used as acceptance evidence.

## Reproduction inputs

- Upstream checkout: `D:\ALF_ZGit\G1_Geogebra_Migration`, verified `HEAD` = the pin above.
- Baseline archive: `source\desktop\desktop\build\distributions\desktop.tar`; SHA-256 `b3c69aadeaa70159143d782e2ef893c530e8fc262cf17091087e157784f20833`.
- Extracted baseline `lib`: `D:\ALF_Agents\_worktrees\gate-a-baseline-staging-20261104\desktop\lib` (59 JARs; staging copy only).
- r12 host JAR SHA-256: `d678f2aefb54a9a72489a928e8bf28f009b5478be18d25f8278e143b353e59b8`.
- r12 D-03 input-set SHA-256: `f5113da0e22d00c08c596793aacfb05aa1af05436e18f8b6ee62e3cf8a1750f4`.
- P-02 fixture SHA-256: `0cbce87514fadab2b7cd4a7c2fb99a9b8ad22996646b499a09a0ee0b330fa91e`.
- P-04 fixture SHA-256: `c2de41f59833dba3a195895b652ef13b44ff5c12300fa1537a3308023d9b0042`.
- Script hashes and every result-artifact hash are recorded in `MANIFEST_GROK_V1.tsv`.

Each script was run with:

```powershell
$env:IMAGE = 'D:\ALF_ZGit\G1_Geogebra_Migration\bin\GeoGebraPlus-RCP-0.1.0-win32-x86_64-r12'
$env:GGB_BASELINE_LIB = 'D:\ALF_Agents\_worktrees\gate-a-baseline-staging-20261104\desktop\lib'
$env:GGB_SOURCE = 'D:\ALF_ZGit\G1_Geogebra_Migration\source'
$env:RESULTS_DIR = 'D:\ALF_Agents\_worktrees\codex-d06-extension-mgmt\03-RCP-Spike\tests\results\gate-a-20261104'
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_P-02_CoreFeatures_GROK_V1.ps1
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_P-03_StandardTools_GROK_V1.ps1
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_P-04_SaveReopen_GROK_V1.ps1
pwsh -NoProfile -File .\03-RCP-Spike\tests\scenarios\S_P-05_ScriptsMacrosExport_GROK_V1.ps1
```

## Caveats / gate status

1. These are Windows r12 results only. The existing Debian P-02/P-04 failures have not been rerun against the newer Linux image in this evidence run. The overall scenario statuses are therefore not changed here.
2. The P-04 text object created from `Text("é à ü € α")` is logged as replacement characters (`U+FFFD`) by both the product and the upstream baseline. The current P-04 assertion checks save/reopen equality, not equality to the intended literal. This is a test/harness-or-runtime encoding gap requiring separate diagnosis; do not interpret the P-04 PASS as proof of Unicode text fidelity.
3. P-05 `Execute`/`SetValue` directives return `false` in both product and baseline, while the subsequent values match. This run records baseline parity, not a new conclusion about those return booleans.
4. Gate A is not fully closed: web/GWT parity and the listed automation gaps remain outside this desktop run. Grok's web-side validation and Debian recheck are still needed before Gate C is considered unblocked.

