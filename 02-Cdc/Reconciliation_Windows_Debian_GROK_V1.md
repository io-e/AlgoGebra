# Windows ↔ Debian reconciliation (GROK_V1, G-17)

| Field | Value |
|---|---|
| Date | 2026-11-02 (Europe/Paris) |
| Tip | `8395e0f` (feat/external-engines) |
| Sources | committed evidence under `03-RCP-Spike/evidence/` + `states.yaml`; no new Windows run (Shadow PC in maintenance) |
| Debian reference | `20261102-linux-final-tip-suites-*` (image built from the tip), PR #23/#24/#25 runs |

## 1. Paired results
| Suite / item | Windows (evidence) | Debian (evidence) | Verdict |
|---|---|---|---|
| 18 LaunchCourse (unified) | **17/0/5** at `6c32896`, `20261102-062900-suite18-unified-windows-SHADOW-TB64BO9R` | **21/0/1** final tip | Same verdict; 4 skips are platform-expected, see §2 |
| 01 Engine discovery | 7/0/0 (`20261029-windows-codex-689d4b4`, `-r9-e3e8a82`) | 7/0/0 | match |
| 02 PARI | 10/0/0 | 10/0/0 | match |
| 03 Maxima | 14/0/0 | 14/0/0 | match |
| 04 Gnuplot | 6/0/0 | 6/0/0 | match |
| 05 Sandbox | 14/0/0 (10-29) | 20/0/0 | **harness gap**: SBX-14..19 added after the Windows run, and SBX-02 renamed noexec→reject. Windows rerun needed |
| 06 Encoding | 9/0/0 | 9/0/0 | match |
| 07 CAS equivalence | 15/0/3 | 15/0/3 | match (same 3 PARI "not applicable" skips) |
| 08 RCP image | 7/0/0 (r9) | 7/0/0 | match (Windows image is r9; rerun on the current image) |
| 12 Engine robustness | 13/0/0 (r9) | 13/0/0 | match |
| 13 GeoGebra baseline | blocked: Gradle lock (BUG-020); desktop CallJavaScriptTest locale fail (BUG-018) | opt-in, not in the tip run | Windows-only bugs |
| Codex course tests (Q2–Q4) | CourseModel 9/0 + policy 18/0 (`20261102-course-security-q2-q4-windows`, JDK 21) | 9/0 + 18/0 (JDK 25) | match |
| GWT WAR | built (`20261101-windows-x-t8-gwt-war`) | built (PR #5/#12) | sha256 differ: GWT output isn't reproducible; functionally same (suite 15 15/0/0 Debian) |
| Renderer fonts / BUG-014 | r12 suite 11: all 46 renderer TTFs load (states.yaml BUG-011) | Linux image renderer has **0 TTF**; P-02 46/4/1, 50/0/1 with fonts (PR #24) | **real bug on Debian** (#27); Windows needs the BUG-014 recheck on r12 |
| BUG-010 dialog on valid input | D-04 "keyboard input/focus issues"; suite 09 NOT RUN on Windows | suite 09 7/17/0, product dialog (PR #23, #28) | real bug, Windows unconfirmed |
| D-11 course tree | attended SWT run pending | 8/0/0 (PR #24) | Windows run needed |
| X-02 / X-07 / O-02 scenarios | X-02 FAIL, X-07 PASS, O-02 FAIL (r11) | same | match (product gaps, not platform) |
| 14 UI guard | G-04/G-05 SKIP on Windows (unproven) | 6/0/1 | Windows rerun needed |
| 10 D-05 strict 3D screenshot | NOT RUN | 5/0/0 (llvmpipe) | Windows rerun needed (real GPU) |

## 2. Suite 18 divergences (per test)
| Test | Windows | Debian | Class | Explanation |
|---|---|---|---|---|
| LC-12 symlink resolved | SKIP | PASS | platform-expected | symlink creation needs Developer Mode/admin |
| LC-13b symlink escape 77 | SKIP | PASS | platform-expected | same |
| LC-17b no-JDK = 69 | SKIP | PASS | harness gap (by design) | JustJ JRE present; `launch.ps1` can't be forced to no-JDK without a change (Codex contract unchanged). Owner Q1 contract is met by launch.sh; launch.ps1 already returns 69 in code |
| LC-18 Xvfb trig course | SKIP | PASS | platform-expected | Linux/Xvfb only; attended SWT stays Windows |
| LC-19 T-27 layering | SKIP | SKIP | harness gap | Java OPEN rejection not yet observable in the product log |
| all exit codes 64/65/66/77 | same | same | match | — |
No real bug found in suite 18.

## 3. Windows reruns needed (when the Shadow PC is back)
Use the clean worktree from Q8. Never use the owner's dirty checkout. In pwsh:
```powershell
cd D:\ALF_Agents\G1_wt_grok_suite18
git status --porcelain            # must be empty; stop if not
git fetch origin
git switch --detach origin/feat/external-engines   # updated tip (8395e0f or newer)
# stage image parts from the owner's built 03-RCP-Spike as for the 2026-11-02 run (bundles/, launcher/, natives/)
pwsh -NoProfile -File 03-RCP-Spike\tests\18_Test_LaunchCourse_GROK_V1.ps1            # expect 17/0/5
pwsh -NoProfile -File 03-RCP-Spike\tests\05_Test_Sandbox_GROK_V1.ps1                 # expect 20/0/0 (new SBX-14..19)
pwsh -NoProfile -File 03-RCP-Spike\tests\20_Test_CourseValidatorJava_GROK_V1.ps1     # expect 54/0/2 (set IMAGE + J25/JAVA_HOME)
pwsh -NoProfile -File 03-RCP-Spike\tests\Run_All_GROK_V1.ps1 -ExportEvidence windows-tip   # non-UI suites
# attended, desktop free, browsers/editors closed:
pwsh -NoProfile -File 03-RCP-Spike\tests\Run_All_GROK_V1.ps1 -AllowForegroundInput -Only 'D-04','D-05','D-11','P-02' -ExportEvidence windows-attended
pwsh -NoProfile -File 03-RCP-Spike\tests\Verify_Issues_27_28_GROK_V1.ps1 -Image <win image dir>   # after Codex fixes #27/#28
```
Then commit the exported evidence folders on a fresh branch and open a PR. Clean up the way Codex recommends, **without `--force`**:
```powershell
cd D:\ALF_Agents\G1_Geogebra_Migration     # main checkout (not modified)
git worktree remove D:\ALF_Agents\G1_wt_grok_suite18   # refuses if untracked/modified files remain: copy them out, don't force
git worktree prune
```
Priority: (1) suite 18 + 05 + 20 (non-UI, 10 min); (2) P-02 on the r12 image, to confirm BUG-014 = fonts on Windows; (3) attended D-04/D-11/D-05; (4) suite 14 G-04/G-05.

## 4. Summary
- **No platform-specific product divergence** in the non-UI suites (engines, sandbox, CAS, launcher contract, course model).
- Divergences are **platform-expected skips** (symlinks, Xvfb-only), **harness drift** (suite 05 grew; Windows evidence is from 10-29/r9), and **open UI work on Windows** (09/10/14/D-11 not run).
- **Real bugs:** BUG-014 on Debian = missing renderer fonts (#27), probably fixed by r12 on Windows (needs a P-02 rerun). BUG-010 dialog (#28) on Debian, unconfirmed on Windows. BUG-018/BUG-020 are Windows-only (suite 13).
